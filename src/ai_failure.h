#ifndef CETTA_AI_FAILURE_H
#define CETTA_AI_FAILURE_H

#include "atom.h"

/* Only a producer's RAISED channel calls this projection. Error-shaped
 * completed values do not become control by passing through this helper. */
static inline Atom *cetta_ai_failure_value(Arena *arena, Atom *error) {
    if (error && error->kind == ATOM_EXPR && error->expr.len == 3u &&
        atom_is_symbol(error->expr.elems[0], "Error")) {
        Atom *reason = error->expr.elems[2];
        if (reason && reason->kind == ATOM_EXPR && reason->expr.len == 2u &&
            (atom_is_symbol(reason->expr.elems[0], "Unsolvable") ||
             atom_is_symbol(reason->expr.elems[0], "Forbidden") ||
             atom_is_symbol(reason->expr.elems[0], "Incomplete") ||
             atom_is_symbol(reason->expr.elems[0], "Fault")))
            return atom_he_evaluated_deep_copy(arena, error);
        Atom *diagnostic = atom_expr3(arena, atom_symbol(arena, "Error"),
            error->expr.elems[1],
            atom_expr2(arena, atom_symbol(arena, "Fault"), reason));
        return diagnostic ? atom_he_evaluated_deep_copy(arena, diagnostic) : NULL;
    }
    Atom *diagnostic = atom_expr3(arena, atom_symbol(arena, "Error"),
        atom_symbol(arena, "evaluation"),
        atom_expr2(arena, atom_symbol(arena, "Fault"), error));
    return diagnostic ? atom_he_evaluated_deep_copy(arena, diagnostic) : NULL;
}

#endif
