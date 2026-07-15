#ifndef CETTA_SHA256_H
#define CETTA_SHA256_H

#include <stddef.h>
#include <stdint.h>

typedef struct {
    uint32_t state[8];
    uint64_t bit_count;
    uint8_t block[64];
    size_t block_len;
} CettaSha256;

static inline uint32_t cetta_sha256_rotr(uint32_t value, unsigned count) {
    return (value >> count) | (value << (32u - count));
}

static inline uint32_t cetta_sha256_load_be32(const uint8_t *bytes) {
    return ((uint32_t)bytes[0] << 24) |
           ((uint32_t)bytes[1] << 16) |
           ((uint32_t)bytes[2] << 8) |
           (uint32_t)bytes[3];
}

static inline void cetta_sha256_store_be32(uint8_t *bytes, uint32_t value) {
    bytes[0] = (uint8_t)(value >> 24);
    bytes[1] = (uint8_t)(value >> 16);
    bytes[2] = (uint8_t)(value >> 8);
    bytes[3] = (uint8_t)value;
}

static inline void cetta_sha256_transform(CettaSha256 *sha,
                                          const uint8_t block[64]) {
    static const uint32_t round_constants[64] = {
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
    uint32_t words[64];
    for (unsigned i = 0; i < 16; i++)
        words[i] = cetta_sha256_load_be32(block + i * 4u);
    for (unsigned i = 16; i < 64; i++) {
        uint32_t s0 = cetta_sha256_rotr(words[i - 15], 7) ^
                      cetta_sha256_rotr(words[i - 15], 18) ^
                      (words[i - 15] >> 3);
        uint32_t s1 = cetta_sha256_rotr(words[i - 2], 17) ^
                      cetta_sha256_rotr(words[i - 2], 19) ^
                      (words[i - 2] >> 10);
        words[i] = words[i - 16] + s0 + words[i - 7] + s1;
    }

    uint32_t a = sha->state[0];
    uint32_t b = sha->state[1];
    uint32_t c = sha->state[2];
    uint32_t d = sha->state[3];
    uint32_t e = sha->state[4];
    uint32_t f = sha->state[5];
    uint32_t g = sha->state[6];
    uint32_t h = sha->state[7];
    for (unsigned i = 0; i < 64; i++) {
        uint32_t sum1 = cetta_sha256_rotr(e, 6) ^
                        cetta_sha256_rotr(e, 11) ^
                        cetta_sha256_rotr(e, 25);
        uint32_t choose = (e & f) ^ ((~e) & g);
        uint32_t temp1 = h + sum1 + choose + round_constants[i] + words[i];
        uint32_t sum0 = cetta_sha256_rotr(a, 2) ^
                        cetta_sha256_rotr(a, 13) ^
                        cetta_sha256_rotr(a, 22);
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
    sha->state[0] += a;
    sha->state[1] += b;
    sha->state[2] += c;
    sha->state[3] += d;
    sha->state[4] += e;
    sha->state[5] += f;
    sha->state[6] += g;
    sha->state[7] += h;
}

static inline void cetta_sha256_init(CettaSha256 *sha) {
    sha->state[0] = 0x6a09e667u;
    sha->state[1] = 0xbb67ae85u;
    sha->state[2] = 0x3c6ef372u;
    sha->state[3] = 0xa54ff53au;
    sha->state[4] = 0x510e527fu;
    sha->state[5] = 0x9b05688cu;
    sha->state[6] = 0x1f83d9abu;
    sha->state[7] = 0x5be0cd19u;
    sha->bit_count = 0;
    sha->block_len = 0;
}

static inline void cetta_sha256_update(CettaSha256 *sha,
                                       const void *data,
                                       size_t len) {
    const uint8_t *bytes = data;
    sha->bit_count += (uint64_t)len * 8u;
    while (len > 0) {
        size_t available = 64u - sha->block_len;
        size_t take = len < available ? len : available;
        for (size_t i = 0; i < take; i++)
            sha->block[sha->block_len + i] = bytes[i];
        sha->block_len += take;
        bytes += take;
        len -= take;
        if (sha->block_len == 64u) {
            cetta_sha256_transform(sha, sha->block);
            sha->block_len = 0;
        }
    }
}

static inline void cetta_sha256_final(CettaSha256 *sha, uint8_t digest[32]) {
    uint64_t original_bits = sha->bit_count;
    uint8_t one = 0x80u;
    uint8_t zero = 0;
    cetta_sha256_update(sha, &one, 1);
    while (sha->block_len != 56u)
        cetta_sha256_update(sha, &zero, 1);
    uint8_t length[8];
    for (unsigned i = 0; i < 8; i++)
        length[7u - i] = (uint8_t)(original_bits >> (i * 8u));
    cetta_sha256_update(sha, length, sizeof(length));
    for (unsigned i = 0; i < 8; i++)
        cetta_sha256_store_be32(digest + i * 4u, sha->state[i]);
}

static inline void cetta_sha256_hex(const uint8_t digest[32], char hex[65]) {
    static const char digits[] = "0123456789abcdef";
    for (unsigned i = 0; i < 32; i++) {
        hex[i * 2u] = digits[digest[i] >> 4];
        hex[i * 2u + 1u] = digits[digest[i] & 0x0fu];
    }
    hex[64] = '\0';
}

#endif
