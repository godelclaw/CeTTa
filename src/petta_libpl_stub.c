#include "petta_libpl.h"
#include "match.h"

#include <stdlib.h>
#include <string.h>

struct CettaLibPrologRuntime {
    bool unavailable;
};

CettaLibPrologRuntime *cetta_lib_prolog_runtime_new(void) {
    CettaLibPrologRuntime *runtime =
        malloc(sizeof(*runtime));
    if (!runtime) return NULL;
    runtime->unavailable = true;
    return runtime;
}

void cetta_lib_prolog_runtime_free(
    CettaLibPrologRuntime *runtime) {
    free(runtime);
}

bool cetta_lib_prolog_runtime_set_working_dir(
    CettaLibPrologRuntime *runtime, const char *path) {
    return runtime && path && path[0] != '\0';
}

bool cetta_lib_prolog_global_shutdown(void) {
    return true;
}

bool cetta_lib_prolog_runtime_available(
    CettaLibPrologRuntime *runtime) {
    return runtime && !runtime->unavailable;
}

CettaLibPrologReadToken cetta_lib_prolog_read_token(
    CettaLibPrologRuntime *runtime) {
    (void)runtime;
    return (CettaLibPrologReadToken){0};
}

uint64_t petta_libpl_capability_revision(
    const CettaLibPrologRuntime *runtime) {
    (void)runtime;
    return 0u;
}

uint64_t petta_libpl_eval_states_live(void) {
    return 0u;
}

CettaLibPrologQueryStatus cetta_lib_prolog_query(
    CettaLibPrologRuntime *runtime, Arena *arena,
    Atom *goal, Atom *projection, Atom **answers) {
    (void)runtime;
    (void)arena;
    (void)goal;
    (void)projection;
    if (answers)
        *answers = NULL;
    return CETTA_LIB_PROLOG_QUERY_UNAVAILABLE;
}

/* The reference prelude's functions that read only their arguments, which
 * the Prolog build registers at these arities: here they are answered
 * natively, so both builds agree. exp/1, implies/2 and =?/2 follow the
 * prelude's clauses; the CLP(FD) functions and relations decide on bound
 * integers, and raise where they would need the solver (petta_libpl_clpfd). */
typedef enum { CORE_EXP, CORE_IMPLIES, CORE_UNIFIABLE, CORE_FD, CORE_FD_RELATION } CoreKind;
typedef struct { const char *name, *operation; CoreKind kind; } CoreFunction;
static const CoreFunction core_functions[] = {
    {"exp", "exp", CORE_EXP}, {"implies", NULL, CORE_IMPLIES}, {"=?", NULL, CORE_UNIFIABLE},
    {"#+", "+", CORE_FD}, {"#-", "-", CORE_FD}, {"#*", "*", CORE_FD},
    {"#div", "div", CORE_FD}, {"#//", "//", CORE_FD}, {"#mod", "mod", CORE_FD},
    {"#min", "min", CORE_FD}, {"#max", "max", CORE_FD},
    {"#<", "<", CORE_FD_RELATION}, {"#>", ">", CORE_FD_RELATION},
    {"#=", "=:=", CORE_FD_RELATION}, {"#\\=", "=\\=", CORE_FD_RELATION},
};

static const CoreFunction *core_function(SymbolId head) {
    if (!g_symbols || head == SYMBOL_ID_NONE)
        return NULL;
    SymbolSpelling spelling = symbol_spelling(g_symbols, head);
    for (size_t index = 0u; index < sizeof(core_functions) / sizeof(core_functions[0]); index++) {
        const char *name = core_functions[index].name;
        if (strlen(name) == spelling.len && memcmp(name, spelling.bytes, spelling.len) == 0)
            return &core_functions[index];
    }
    return NULL;
}

static size_t core_arity(const CoreFunction *function) {
    return function->kind == CORE_EXP ? 1u : 2u;
}

static PeTTaNamedArity core_named_arity(SymbolId head, CettaExprLen supplied) {
    const CoreFunction *function = core_function(head);
    if (!function)
        return (PeTTaNamedArity){0};
    size_t arity = core_arity(function);
    return (PeTTaNamedArity){.known = true, .exact = arity == (size_t)supplied,
        .larger = arity > (size_t)supplied, .smaller = arity < (size_t)supplied};
}

PeTTaNamedArity petta_libpl_named_arity(
    CettaLibPrologRuntime *runtime, SymbolId head,
    CettaExprLen supplied) {
    (void)runtime;
    return core_named_arity(head, supplied);
}

PeTTaNamedArity petta_libpl_effect_free_named_arity(
    CettaLibPrologRuntime *runtime, SymbolId head,
    CettaExprLen supplied) {
    (void)runtime;
    return core_named_arity(head, supplied);
}

PeTTaNamedArity petta_libpl_named_arity_including_resolved(
    CettaLibPrologRuntime *runtime, SymbolId head,
    CettaExprLen supplied) {
    (void)runtime;
    return core_named_arity(head, supplied);
}

bool petta_libpl_static_import(
    CettaLibPrologRuntime *runtime, Arena *arena, SymbolId space,
    const char *file, PettaLibplStaticPredicateVisit visit, void *context,
    CettaCallOutcome *end) {
    (void)runtime;
    (void)arena;
    (void)space;
    (void)file;
    (void)visit;
    (void)context;
    if (end)
        *end = cetta_call_failure();
    return false;
}

void petta_libpl_warn_redefined(
    CettaLibPrologRuntime *runtime, SymbolId name, size_t arity) {
    (void)runtime;
    (void)name;
    (void)arity;
}

bool petta_libpl_predicate_defined(
    CettaLibPrologRuntime *runtime, SymbolId name, size_t arity) {
    (void)runtime;
    (void)name;
    (void)arity;
    return false;
}

bool petta_libpl_standard_function_current(
    CettaLibPrologRuntime *runtime, SymbolId name, size_t arity) {
    (void)runtime;
    (void)name;
    (void)arity;
    return false;
}

PeTTaNamedArity petta_libpl_named_arity_resolving(
    CettaLibPrologRuntime *runtime, SymbolId head,
    CettaExprLen supplied) {
    (void)runtime;
    return core_named_arity(head, supplied);
}

static Atom *core_truth(Arena *arena, bool value) {
    return value ? atom_symbol_data_n(arena, "true", 4u) : atom_symbol_data_n(arena, "false", 5u);
}

/* bool/1 of the prelude: true or false, else no answer. */
static bool core_boolean(Atom *atom, bool *value) {
    if (atom->kind == ATOM_GROUNDED && atom->ground.gkind == GV_BOOL) {
        *value = atom->ground.bval;
        return true;
    }
    if (atom->kind != ATOM_SYMBOL)
        return false;
    uint32_t length = atom_symbol_length(atom);
    const char *name = atom_symbol_bytes(atom);
    if (!name)
        return false;
    *value = length == 4u && memcmp(name, "true", 4u) == 0;
    return *value || (length == 5u && memcmp(name, "false", 5u) == 0);
}

static bool core_answer(OutcomeSet *outcomes, Atom *value, const Bindings *bindings) {
    CettaCount before = outcomes->len;
    outcome_set_add(outcomes, value, bindings);
    return outcomes->len == before + 1u;
}

/* implies(A, B, C) :- bool(A), bool(B), (A == true -> (B == true -> C = true
 * ; C = false) ; C = true): an unbound A or B is enumerated true, then false. */
static bool core_implies(Arena *arena, Atom **args, OutcomeSet *outcomes) {
    bool fixed[2] = {false, false}, value[2] = {false, false};
    for (unsigned index = 0u; index < 2u; index++) {
        if (args[index]->kind != ATOM_VAR && !core_boolean(args[index], &value[index]))
            return true;
        fixed[index] = args[index]->kind != ATOM_VAR;
    }
    for (unsigned a = 0u; a < 2u; a++) {
        if (fixed[0] && a != (value[0] ? 0u : 1u))
            continue;
        for (unsigned b = 0u; b < 2u; b++) {
            if (fixed[1] && b != (value[1] ? 0u : 1u))
                continue;
            Bindings bindings;
            bindings_init(&bindings);
            bool ok = (fixed[0] || match_atoms(args[0], core_truth(arena, a == 0u), &bindings, arena)) &&
                      (fixed[1] || match_atoms(args[1], core_truth(arena, b == 0u), &bindings, arena)) &&
                      core_answer(outcomes, core_truth(arena, a == 1u || b == 0u), &bindings);
            bindings_free(&bindings);
            if (!ok)
                return false;
        }
    }
    return true;
}

bool petta_libpl_call(
    CettaLibPrologRuntime *runtime, Arena *arena,
    Atom *expression, Atom *expected,
    const Bindings *environment, OutcomeSet *outcomes,
    bool *recognized, CettaCallOutcome *end,
    const CettaDelayView *delay) {
    (void)runtime;
    (void)delay;
    if (end)
        *end = cetta_call_failure();
    if (recognized)
        *recognized = false;
    if (!arena || !expression || !expected || !environment || !outcomes || !recognized ||
        expression->kind != ATOM_EXPR || expression->expr.len == 0u ||
        expression->expr.elems[0]->kind != ATOM_SYMBOL)
        return recognized != NULL;
    /* The machine's native #+ hands an unfinished sum to the reference
     * predicate as (translatePredicate (#+ A B R)): R is its value. */
    Atom *goal = NULL;
    if (expression->expr.len == 2u && expression->expr.elems[1]->kind == ATOM_EXPR &&
        atom_is_symbol(expression->expr.elems[0], "translatePredicate")) {
        goal = expression->expr.elems[1];
        if (goal->expr.len != 4u || goal->expr.elems[0]->kind != ATOM_SYMBOL)
            return true;
        const CoreFunction *predicate = core_function(atom_symbol_current_id(goal->expr.elems[0]));
        if (!predicate || (predicate->kind != CORE_FD && predicate->kind != CORE_FD_RELATION))
            return true;
        expression = goal;
    }
    const CoreFunction *function = core_function(atom_symbol_current_id(expression->expr.elems[0]));
    if (!function || (size_t)expression->expr.len - 1u != core_arity(function) + (goal ? 1u : 0u))
        return true;
    Atom *resolved = bindings_apply_if_vars((Bindings *)environment, arena, expression);
    if (!resolved || resolved->kind != ATOM_EXPR || resolved->expr.len != expression->expr.len)
        return false;
    Atom **args = resolved->expr.elems + 1u;
    CettaCallOutcome outcome = cetta_call_failure();
    Bindings none;
    bindings_init(&none);
    bool ok = true;
    switch (function->kind) {
    case CORE_EXP:
        ok = petta_libpl_evaluate_arithmetic(arena, "exp", args, 1u, &outcome);
        break;
    case CORE_IMPLIES:
        *recognized = true;
        return core_implies(arena, args, outcomes);
    case CORE_UNIFIABLE: {
        /* '=?'(A, B, R) :- (\+ \+ A = B -> R = true ; R = false) */
        Bindings trial;
        bindings_init(&trial);
        bool unifiable = match_atoms(args[0], args[1], &trial, arena);
        bindings_free(&trial);
        outcome = cetta_call_value(core_truth(arena, unifiable));
        break;
    }
    case CORE_FD:
    case CORE_FD_RELATION:
        ok = petta_libpl_clpfd(arena, function->name, function->operation,
                               function->kind == CORE_FD_RELATION, args, &outcome);
        break;
    }
    if (!ok)
        return true;
    *recognized = true;
    if (outcome.kind == CETTA_CALL_RAISED) {
        if (end)
            *end = outcome;
        return true;
    }
    if (outcome.kind != CETTA_CALL_VALUE)
        return true;
    if (!goal)
        return core_answer(outcomes, outcome.term, &none);
    Bindings result;
    bindings_init(&result);
    bool answered = !match_atoms(args[2], outcome.term, &result, arena) ||
                    core_answer(outcomes, core_truth(arena, true), &result);
    bindings_free(&result);
    return answered;
}
