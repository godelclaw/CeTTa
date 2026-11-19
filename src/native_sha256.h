#ifndef CETTA_NATIVE_SHA256_H
#define CETTA_NATIVE_SHA256_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct {
    uint32_t state[8];
    uint64_t bit_len;
    uint8_t block[64];
    uint32_t block_len;
} CettaNativeSha256;

void cetta_native_sha256_init(CettaNativeSha256 *sha);
void cetta_native_sha256_update(CettaNativeSha256 *sha,
                                const uint8_t *bytes,
                                size_t len);
void cetta_native_sha256_finish(CettaNativeSha256 *sha, uint8_t out[32]);
void cetta_native_sha256_finish_hex(CettaNativeSha256 *sha, char out[65]);
void cetta_native_sha256_hex(const uint8_t *bytes, size_t len, char out[65]);
/* Whether hashing uses the processor's SHA extensions, which it does when
 * the processor has them. use_hardware(false) selects the portable rounds,
 * as a test compares them; it answers whether the extensions are in use. */
bool cetta_native_sha256_hardware(void);
bool cetta_native_sha256_use_hardware(bool use);

#endif /* CETTA_NATIVE_SHA256_H */
