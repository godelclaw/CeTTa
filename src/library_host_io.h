#ifndef CETTA_LIBRARY_HOST_IO_H
#define CETTA_LIBRARY_HOST_IO_H
#include "call_outcome.h"
struct CettaLibraryContext;
bool cetta_host_io_call(struct CettaLibraryContext *ctx, Arena *arena,
    Atom *head, Atom **args, uint32_t nargs, CettaCallOutcome *out);
#endif
