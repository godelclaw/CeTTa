#ifndef CETTA_ATOM_FRAGMENT_H
#define CETTA_ATOM_FRAGMENT_H
#include "atom.h"
#include "byte_fragment.h"

/* A string atom's bytes as an immutable fragment that outlives every arena:
 * a large string's retained storage is shared, a small string is copied.
 * NULL for anything but a string, or when out of memory. */
CettaByteFragment *atom_string_fragment(const Atom *atom);

#endif
