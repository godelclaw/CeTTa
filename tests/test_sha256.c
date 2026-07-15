#include "sha256.h"

#include <stdio.h>
#include <string.h>

static int check_vector(const char *message, const char *expected) {
    CettaSha256 sha;
    uint8_t digest[32];
    char actual[65];
    cetta_sha256_init(&sha);
    cetta_sha256_update(&sha, message, strlen(message));
    cetta_sha256_final(&sha, digest);
    cetta_sha256_hex(digest, actual);
    if (strcmp(actual, expected) == 0)
        return 0;
    fprintf(stderr, "sha256 mismatch for '%s': %s != %s\n",
            message, actual, expected);
    return 1;
}

int main(void) {
    int failures = 0;
    failures += check_vector(
        "",
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
    failures += check_vector(
        "abc",
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    failures += check_vector(
        "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
        "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1");
    return failures == 0 ? 0 : 1;
}
