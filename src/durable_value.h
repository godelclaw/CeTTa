#ifndef CETTA_DURABLE_VALUE_H
#define CETTA_DURABLE_VALUE_H
#include "atom.h"
#include "durable_store.h"

/* CDV1 is a bounded, closed-data format. Symbols, strings, booleans, integers,
 * floats (including their bits), exact numbers, and expressions are retained.
 * Variables, capabilities, native handles, spaces, and mutable state are not
 * serializable. Continuations must use ground data, not captured heap state.
 * Sharing is not part of this format; cyclic values fail the depth bound. */
CettaDurableStatus cetta_durable_value_encode(const Atom *value,
    unsigned char **bytes, size_t *length);
CettaDurableStatus cetta_durable_value_decode(Arena *arena,
    const unsigned char *bytes, size_t length, Atom **value);
#endif
