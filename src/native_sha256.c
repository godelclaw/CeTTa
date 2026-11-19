#include "native_sha256.h"

#include <stdatomic.h>
#include <string.h>

#if (defined(__x86_64__) || defined(__i386__)) && defined(__GNUC__)
#include <cpuid.h>
#include <immintrin.h>
#define NATIVE_SHA_X86 1
#endif

static uint32_t native_sha_rotr(uint32_t value, uint32_t amount) {
    return (value >> amount) | (value << (32u - amount));
}

static const uint32_t constants[64] = {
        0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u,
        0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u,
        0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u,
        0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u,
        0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu,
        0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
        0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
        0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u,
        0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u,
        0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,
        0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u,
        0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u,
        0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
        0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
        0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u,
        0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u,
};

static void native_sha_transform(uint32_t state[8], const uint8_t block[64]) {
    uint32_t words[64];
    uint32_t a, b, c, d, e, f, g, h;

    for (uint32_t i = 0; i < 16u; i++) {
        words[i] = ((uint32_t)block[i * 4u] << 24u) |
                   ((uint32_t)block[i * 4u + 1u] << 16u) |
                   ((uint32_t)block[i * 4u + 2u] << 8u) |
                   (uint32_t)block[i * 4u + 3u];
    }
    for (uint32_t i = 16u; i < 64u; i++) {
        uint32_t s0 = native_sha_rotr(words[i - 15u], 7u) ^
                      native_sha_rotr(words[i - 15u], 18u) ^
                      (words[i - 15u] >> 3u);
        uint32_t s1 = native_sha_rotr(words[i - 2u], 17u) ^
                      native_sha_rotr(words[i - 2u], 19u) ^
                      (words[i - 2u] >> 10u);
        words[i] = words[i - 16u] + s0 + words[i - 7u] + s1;
    }
    a = state[0];
    b = state[1];
    c = state[2];
    d = state[3];
    e = state[4];
    f = state[5];
    g = state[6];
    h = state[7];
    for (uint32_t i = 0; i < 64u; i++) {
        uint32_t sum1 = native_sha_rotr(e, 6u) ^
                        native_sha_rotr(e, 11u) ^
                        native_sha_rotr(e, 25u);
        uint32_t choose = (e & f) ^ ((~e) & g);
        uint32_t temp1 = h + sum1 + choose + constants[i] + words[i];
        uint32_t sum0 = native_sha_rotr(a, 2u) ^
                        native_sha_rotr(a, 13u) ^
                        native_sha_rotr(a, 22u);
        uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
        uint32_t temp2 = sum0 + majority;
        h = g;
        g = f;
        f = e;
        e = d + temp1;
        d = c;
        c = b;
        b = a;
        a = temp1 + temp2;
    }
    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
    state[5] += f;
    state[6] += g;
    state[7] += h;
}

#if NATIVE_SHA_X86
/* The SHA extensions, which x86 processors have had since 2016 (AMD) and
 * 2019 (Intel cores): two rounds per instruction, the message schedule in
 * two more. The state is held as (ABEF, CDGH), as sha256rnds2 takes it. */
__attribute__((target("sha,sse4.1")))
static void native_sha_blocks_x86(uint32_t state[8], const uint8_t *data, size_t blocks) {
    const __m128i order = _mm_set_epi64x(0x0c0d0e0f08090a0bLL, 0x0405060700010203LL);
    __m128i swapped = _mm_shuffle_epi32(_mm_loadu_si128((const __m128i *)&state[0]), 0xB1);
    __m128i cdgh = _mm_shuffle_epi32(_mm_loadu_si128((const __m128i *)&state[4]), 0x1B);
    __m128i abef = _mm_alignr_epi8(swapped, cdgh, 8);
    cdgh = _mm_blend_epi16(cdgh, swapped, 0xF0);
    for (; blocks; --blocks, data += 64) {
        __m128i saved_abef = abef, saved_cdgh = cdgh, w[4];
        for (unsigned g = 0; g < 4u; ++g)
            w[g] = _mm_shuffle_epi8(_mm_loadu_si128((const __m128i *)(data + 16u * g)), order);
        for (unsigned g = 0; g < 16u; ++g) {
            /* Rounds 4g to 4g + 3, then words 4g + 16 to 4g + 19. */
            __m128i message = _mm_add_epi32(w[g & 3u], _mm_loadu_si128((const __m128i *)&constants[4u * g]));
            cdgh = _mm_sha256rnds2_epu32(cdgh, abef, message);
            abef = _mm_sha256rnds2_epu32(abef, cdgh, _mm_shuffle_epi32(message, 0x0E));
            if (g < 12u) {
                __m128i next = _mm_sha256msg1_epu32(w[g & 3u], w[(g + 1u) & 3u]);
                next = _mm_add_epi32(next, _mm_alignr_epi8(w[(g + 3u) & 3u], w[(g + 2u) & 3u], 4));
                w[g & 3u] = _mm_sha256msg2_epu32(next, w[(g + 3u) & 3u]);
            }
        }
        abef = _mm_add_epi32(abef, saved_abef);
        cdgh = _mm_add_epi32(cdgh, saved_cdgh);
    }
    swapped = _mm_shuffle_epi32(abef, 0x1B);
    cdgh = _mm_shuffle_epi32(cdgh, 0xB1);
    _mm_storeu_si128((__m128i *)&state[0], _mm_blend_epi16(swapped, cdgh, 0xF0));
    _mm_storeu_si128((__m128i *)&state[4], _mm_alignr_epi8(cdgh, swapped, 8));
}
#endif

/* -1 unknown, 0 portable, 1 the SHA extensions. */
static _Atomic int native_sha_hardware = -1;

static int native_sha_hardware_available(void) {
#if NATIVE_SHA_X86
    unsigned a, b, c, d;
    return __get_cpuid(1u, &a, &b, &c, &d) && (c & bit_SSE4_1) && (c & bit_SSSE3) &&
           __get_cpuid_count(7u, 0u, &a, &b, &c, &d) && (b & bit_SHA);
#else
    return 0;
#endif
}

bool cetta_native_sha256_hardware(void) {
    int known = atomic_load_explicit(&native_sha_hardware, memory_order_relaxed);
    if (known < 0) {
        known = native_sha_hardware_available();
        atomic_store_explicit(&native_sha_hardware, known, memory_order_relaxed);
    }
    return known > 0;
}

bool cetta_native_sha256_use_hardware(bool use) {
    bool available = native_sha_hardware_available();
    atomic_store_explicit(&native_sha_hardware, use && available, memory_order_relaxed);
    return use && available;
}

static void native_sha_blocks(uint32_t state[8], const uint8_t *data, size_t blocks) {
#if NATIVE_SHA_X86
    if (cetta_native_sha256_hardware()) {
        native_sha_blocks_x86(state, data, blocks);
        return;
    }
#endif
    for (; blocks; --blocks, data += 64)
        native_sha_transform(state, data);
}

void cetta_native_sha256_init(CettaNativeSha256 *sha) {
    static const uint32_t initial[8] = {
        0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u, 0xa54ff53au,
        0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u,
    };
    memset(sha, 0, sizeof(*sha));
    memcpy(sha->state, initial, sizeof(initial));
}

/* Whole blocks are hashed where they lie; only a partial one is copied. */
void cetta_native_sha256_update(CettaNativeSha256 *sha,
                                const uint8_t *bytes,
                                size_t len) {
    if (sha->block_len) {
        size_t take = 64u - sha->block_len;
        if (take > len)
            take = len;
        memcpy(sha->block + sha->block_len, bytes, take);
        sha->block_len += (uint32_t)take;
        bytes += take;
        len -= take;
        if (sha->block_len < 64u)
            return;
        native_sha_blocks(sha->state, sha->block, 1u);
        sha->bit_len += UINT64_C(512);
        sha->block_len = 0;
    }
    size_t blocks = len / 64u;
    if (blocks) {
        native_sha_blocks(sha->state, bytes, blocks);
        sha->bit_len += (uint64_t)blocks * UINT64_C(512);
        bytes += blocks * 64u;
        len -= blocks * 64u;
    }
    if (len) {
        memcpy(sha->block, bytes, len);
        sha->block_len = (uint32_t)len;
    }
}

static void native_sha_finish(CettaNativeSha256 *sha, uint8_t digest[32]) {
    uint64_t total_bits =
        sha->bit_len + (uint64_t)sha->block_len * UINT64_C(8);

    sha->block[sha->block_len++] = 0x80u;
    if (sha->block_len > 56u) {
        while (sha->block_len < 64u)
            sha->block[sha->block_len++] = 0;
        native_sha_blocks(sha->state, sha->block, 1u);
        sha->block_len = 0;
    }
    while (sha->block_len < 56u)
        sha->block[sha->block_len++] = 0;
    for (uint32_t i = 0; i < 8u; i++)
        sha->block[63u - i] = (uint8_t)(total_bits >> (i * 8u));
    native_sha_blocks(sha->state, sha->block, 1u);
    for (uint32_t i = 0; i < 8u; i++) {
        digest[i * 4u] = (uint8_t)(sha->state[i] >> 24u);
        digest[i * 4u + 1u] = (uint8_t)(sha->state[i] >> 16u);
        digest[i * 4u + 2u] = (uint8_t)(sha->state[i] >> 8u);
        digest[i * 4u + 3u] = (uint8_t)sha->state[i];
    }
}

static void native_sha_hex(const uint8_t digest[32], char out[65]) {
    static const char digits[] = "0123456789abcdef";

    for (uint32_t i = 0; i < 32u; i++) {
        out[i * 2u] = digits[digest[i] >> 4u];
        out[i * 2u + 1u] = digits[digest[i] & 0x0fu];
    }
    out[64] = '\0';
}

void cetta_native_sha256_finish(CettaNativeSha256 *sha, uint8_t out[32]) {
    native_sha_finish(sha, out);
}

void cetta_native_sha256_finish_hex(CettaNativeSha256 *sha, char out[65]) {
    uint8_t digest[32];

    native_sha_finish(sha, digest);
    native_sha_hex(digest, out);
}

void cetta_native_sha256_hex(const uint8_t *bytes, size_t len, char out[65]) {
    CettaNativeSha256 sha;

    cetta_native_sha256_init(&sha);
    cetta_native_sha256_update(&sha, bytes, len);
    cetta_native_sha256_finish_hex(&sha, out);
}
