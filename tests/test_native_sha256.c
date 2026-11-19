/* SHA-256: the FIPS 180-4 examples in both implementations, and the SHA
 * extensions against the portable rounds on random input split at random. */
#include "native_sha256.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void hex_of(const uint8_t *bytes, size_t len, char out[65]) {
    cetta_native_sha256_hex(bytes, len, out);
}

static void hex_in_pieces(const uint8_t *bytes, size_t len, uint64_t *seed, char out[65]) {
    CettaNativeSha256 sha;
    cetta_native_sha256_init(&sha);
    size_t at = 0;
    while (at < len) {
        *seed ^= *seed << 13;
        *seed ^= *seed >> 7;
        *seed ^= *seed << 17;
        size_t n = (size_t)(*seed % 200u);
        if (n > len - at)
            n = len - at;
        cetta_native_sha256_update(&sha, bytes + at, n);
        at += n;
    }
    cetta_native_sha256_finish_hex(&sha, out);
}

static void examples(void) {
    static const struct { const char *text; size_t repeat; const char *digest; } cases[] = {
        {"", 1u, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"},
        {"abc", 1u, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"},
        {"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", 1u,
         "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"},
        {"a", 1000000u, "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"},
    };
    for (size_t i = 0; i < sizeof cases / sizeof cases[0]; ++i) {
        size_t n = strlen(cases[i].text) * cases[i].repeat;
        uint8_t *bytes = malloc(n ? n : 1u);
        assert(bytes);
        for (size_t r = 0; r < cases[i].repeat; ++r)
            memcpy(bytes + r * strlen(cases[i].text), cases[i].text, strlen(cases[i].text));
        char got[65];
        hex_of(bytes, n, got);
        assert(strcmp(got, cases[i].digest) == 0);
        free(bytes);
    }
}

int main(void) {
    bool hardware = cetta_native_sha256_use_hardware(true);
    examples();
    assert(!cetta_native_sha256_use_hardware(false) && !cetta_native_sha256_hardware());
    examples();
    if (hardware) {
        size_t size = 1u << 20;
        uint8_t *bytes = malloc(size);
        assert(bytes);
        uint64_t seed = 20261119u;
        for (size_t i = 0; i < size; ++i) {
            seed ^= seed << 13;
            seed ^= seed >> 7;
            seed ^= seed << 17;
            bytes[i] = (uint8_t)seed;
        }
        for (size_t len = 0; len <= size; len = len < 300u ? len + 1u : len * 3u + 1u) {
            char portable[65], extended[65], pieces[65];
            uint64_t split = len + 1u;
            cetta_native_sha256_use_hardware(false);
            hex_of(bytes, len, portable);
            assert(cetta_native_sha256_use_hardware(true));
            hex_of(bytes, len, extended);
            hex_in_pieces(bytes, len, &split, pieces);
            assert(strcmp(portable, extended) == 0 && strcmp(portable, pieces) == 0);
        }
        free(bytes);
    }
    printf("PASS: SHA-256 examples, %s\n",
           hardware ? "and the SHA extensions equal the portable rounds" : "portable rounds only");
    return 0;
}
