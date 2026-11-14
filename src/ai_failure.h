#ifndef CETTA_AI_FAILURE_H
#define CETTA_AI_FAILURE_H

#include "atom.h"

/* Activation changes the selected occurrence's root from value to code.
 * Its children retain their own roles; source syntax is never mutated. */
static inline Atom *cetta_ai_code_reading(Arena *arena, Atom *value) {
    return value && value->kind == ATOM_EXPR && value->expr.len &&
            atom_is_he_evaluated(value)
        ? atom_expr(arena, value->expr.elems, value->expr.len) : value;
}

/* A strict constructor receives value children. Only a newly constructed
 * diagnostic root needs protection; walking every prefix would make cons
 * quadratic and would change the roles of already-admitted children. */
static inline Atom *cetta_ai_constructed_value(Arena *arena, Atom *value) {
    return value && atom_is_error(value) ? atom_he_evaluated_copy(arena, value) : value;
}

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
