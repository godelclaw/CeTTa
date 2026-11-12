#ifndef CETTA_BYTE_FRAGMENT_H
#define CETTA_BYTE_FRAGMENT_H
#include <stdatomic.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* An immutable, reference-counted run of bytes. Its bytes never change after
 * creation, and the last release frees them, so any thread may hold one
 * without copying: a retained string's storage is shared rather than copied,
 * and the HTTP worker streams a request body from its fragments in order.
 *
 * A fragment either carries its bytes inline or borrows them from an owner,
 * which it holds one reference to and releases with it. Header-only, so
 * every unit that compiles the HTTP worker standalone gets it unchanged. */
typedef struct CettaByteFragment {
    _Atomic(size_t) references;
    size_t size;
    const unsigned char *bytes;
    void *owner;
    void (*release_owner)(void *owner);
    unsigned char inline_bytes[];
} CettaByteFragment;

/* A fragment of a copy of size bytes; NULL when out of memory. */
static inline CettaByteFragment *cetta_fragment_copy(const void *bytes, size_t size) {
    if (size > SIZE_MAX - sizeof(CettaByteFragment) - 1u || (size && !bytes)) return NULL;
    CettaByteFragment *fragment = malloc(sizeof(*fragment) + size + 1u);
    if (!fragment) return NULL;
    atomic_init(&fragment->references, 1u);
    fragment->size = size;
    if (size) memcpy(fragment->inline_bytes, bytes, size);
    fragment->inline_bytes[size] = 0;
    fragment->bytes = fragment->inline_bytes;
    fragment->owner = NULL;
    fragment->release_owner = NULL;
    return fragment;
}

/* A fragment over bytes an owner keeps alive. It takes over one reference the
 * caller holds on owner, released through release_owner with the fragment,
 * also when this returns NULL. */
static inline CettaByteFragment *cetta_fragment_borrow(const void *bytes, size_t size,
        void *owner, void (*release_owner)(void *owner)) {
    CettaByteFragment *fragment = (size && !bytes) ? NULL : malloc(sizeof(*fragment));
    if (!fragment) {
        if (release_owner) release_owner(owner);
        return NULL;
    }
    atomic_init(&fragment->references, 1u);
    fragment->size = size;
    fragment->bytes = size ? bytes : (const unsigned char *)"";
    fragment->owner = owner;
    fragment->release_owner = release_owner;
    return fragment;
}

static inline CettaByteFragment *cetta_fragment_retain(CettaByteFragment *fragment) {
    if (fragment && atomic_fetch_add_explicit(&fragment->references, 1u,
                                              memory_order_relaxed) == SIZE_MAX)
        abort();
    return fragment;
}

static inline void cetta_fragment_release(CettaByteFragment *fragment) {
    if (!fragment || atomic_fetch_sub_explicit(&fragment->references, 1u,
                                               memory_order_acq_rel) != 1u)
        return;
    if (fragment->release_owner) fragment->release_owner(fragment->owner);
    free(fragment);
}

static inline size_t cetta_fragment_references(const CettaByteFragment *fragment) {
    return fragment ? atomic_load_explicit(&((CettaByteFragment *)fragment)->references,
                                           memory_order_acquire) : 0u;
}

#endif
