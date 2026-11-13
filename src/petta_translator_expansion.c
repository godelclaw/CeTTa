/* petta_translator_expansion.c — see petta_translator_expansion.h. */
#include "petta_translator_expansion.h"

#include <stdlib.h>
#include <string.h>

#include "petta_semantics.h"
#include "symbol.h"

enum {
    /* Steps of the rule's own computation; the library's rules take a few
     * dozen per call. */
    EXPAND_STEP_BUDGET = 1u << 14,
    EXPAND_DEPTH_LIMIT = 512u,
    /* Nodes a single expansion may build. */
    EXPAND_NODE_BUDGET = 1u << 18,
};

typedef enum { TRI_NO = 0, TRI_YES, TRI_UNKNOWN } Tri;

typedef struct {
    VarId id;
    Atom *value;
} ExpandBinding;

typedef struct {
    VarId from;
    Atom *to;
} ExpandRenaming;

typedef struct {
    const PettaTranslatorOracle *oracle;
    Arena *arena;
    ExpandBinding *bindings;
    size_t binding_len, binding_cap;
    ExpandRenaming *renamings;
    size_t renaming_len, renaming_cap;
    uint32_t steps;
    uint32_t nodes;
    PettaTranslatorOutcome outcome;
} Expansion;

static bool expand_reserve(void **items, size_t *cap, size_t need,
                           size_t width) {
    if (need <= *cap)
        return true;
    size_t next = *cap ? *cap * 2u : 16u;
    while (next < need)
        next *= 2u;
    if (next > SIZE_MAX / width)
        return false;
    void *grown = realloc(*items, next * width);
    if (!grown)
        return false;
    *items = grown;
    *cap = next;
    return true;
}

static Atom *expand_decline(Expansion *x, PettaTranslatorOutcome outcome) {
    if (x->outcome == PETTA_TRANSLATOR_EXPANDED)
        x->outcome = outcome;
    return NULL;
}

static Atom *expand_lookup(const Expansion *x, VarId id) {
    for (size_t index = x->binding_len; index > 0u; index--) {
        if (var_id_eq(x->bindings[index - 1u].id, id))
            return x->bindings[index - 1u].value;
    }
    return NULL;
}

static bool expand_bind(Expansion *x, VarId id, Atom *value) {
    if (!expand_reserve((void **)&x->bindings, &x->binding_cap,
                        x->binding_len + 1u, sizeof(*x->bindings))) {
        expand_decline(x, PETTA_TRANSLATOR_CAPACITY);
        return false;
    }
    x->bindings[x->binding_len++] = (ExpandBinding){id, value};
    return true;
}

static bool expand_node(Expansion *x) {
    if (++x->nodes > EXPAND_NODE_BUDGET) {
        expand_decline(x, PETTA_TRANSLATOR_DECLINED_BUDGET);
        return false;
    }
    return true;
}

/* The row with each of its variables replaced by a fresh one. */
static Atom *expand_rename(Expansion *x, Atom *atom, uint32_t depth) {
    if (!atom || !atom_has_vars(atom))
        return atom;
    if (depth > EXPAND_DEPTH_LIMIT)
        return expand_decline(x, PETTA_TRANSLATOR_DECLINED_BUDGET);
    if (atom->kind == ATOM_VAR) {
        for (size_t index = 0u; index < x->renaming_len; index++) {
            if (var_id_eq(x->renamings[index].from, atom->var_id))
                return x->renamings[index].to;
        }
        VarId fresh = VAR_ID_NONE;
        if (!fresh_var_id_try(&fresh))
            return expand_decline(x, PETTA_TRANSLATOR_CAPACITY);
        Atom *renamed = atom_var_like(x->arena, atom, fresh);
        if (!renamed ||
            !expand_reserve((void **)&x->renamings, &x->renaming_cap,
                            x->renaming_len + 1u, sizeof(*x->renamings)))
            return expand_decline(x, PETTA_TRANSLATOR_CAPACITY);
        x->renamings[x->renaming_len++] =
            (ExpandRenaming){atom->var_id, renamed};
        return renamed;
    }
    if (atom->kind != ATOM_EXPR)
        return atom;
    CettaExprLen len = atom->expr.len;
    Atom **children = NULL;
    for (CettaExprIndex index = 0u; index < len; index++) {
        Atom *child = expand_rename(x, atom->expr.elems[index], depth + 1u);
        if (!child) {
            free(children);
            return NULL;
        }
        if (child != atom->expr.elems[index] && !children) {
            children = malloc(sizeof(*children) * len);
            if (!children)
                return expand_decline(x, PETTA_TRANSLATOR_CAPACITY);
            memcpy(children, atom->expr.elems, sizeof(*children) * index);
        }
        if (children)
            children[index] = child;
    }
    if (!children)
        return atom;
    Atom *rebuilt = expand_node(x) ? atom_expr(x->arena, children, len) : NULL;
    free(children);
    return rebuilt;
}

static bool expand_numeric(const Atom *atom) {
    return atom->kind == ATOM_GROUNDED &&
        (atom->ground.gkind == GV_INT || atom->ground.gkind == GV_FLOAT ||
         atom->ground.gkind == GV_BIGINT || atom->ground.gkind == GV_RATIONAL);
}

/* PeTTa's == between two values as the expander knows them.  A variable is
 * a value decided when the program runs: it is equal to itself and
 * undecided against anything else.  Numbers compare by value in PeTTa, so
 * two unequal spellings of a number stay undecided. */
static Tri expand_compare(Atom *left, Atom *right, uint32_t depth) {
    if (left == right)
        return TRI_YES;
    if (!left || !right || depth > EXPAND_DEPTH_LIMIT)
        return TRI_UNKNOWN;
    if (left->kind == ATOM_VAR || right->kind == ATOM_VAR) {
        return left->kind == ATOM_VAR && right->kind == ATOM_VAR &&
                var_id_eq(left->var_id, right->var_id)
            ? TRI_YES : TRI_UNKNOWN;
    }
    if (left->kind == ATOM_EXPR || right->kind == ATOM_EXPR) {
        if (left->kind != right->kind ||
            left->expr.len != right->expr.len)
            return TRI_NO;
        Tri result = TRI_YES;
        for (CettaExprIndex index = 0u; index < left->expr.len; index++) {
            Tri child = expand_compare(left->expr.elems[index],
                                       right->expr.elems[index], depth + 1u);
            if (child == TRI_NO)
                return TRI_NO;
            if (child == TRI_UNKNOWN)
                result = TRI_UNKNOWN;
        }
        return result;
    }
    if (left->kind == ATOM_SYMBOL && right->kind == ATOM_SYMBOL)
        return atom_symbol_current_id(left) == atom_symbol_current_id(right)
            ? TRI_YES : TRI_NO;
    if (left->kind == ATOM_GROUNDED && right->kind == ATOM_GROUNDED &&
        left->ground.gkind == right->ground.gkind &&
        (left->ground.gkind == GV_INT || left->ground.gkind == GV_BOOL ||
         left->ground.gkind == GV_STRING)) {
        return atom_eq(left, right) ? TRI_YES : TRI_NO;
    }
    if (expand_numeric(left) && expand_numeric(right) &&
        atom_eq(left, right))
        return TRI_YES;
    return TRI_UNKNOWN;
}

/* Unify a pattern of the rule's own syntax with a value: each of the rule's
 * variables binds or is compared with its binding; a variable inside the
 * value is decided when the program runs, so structure meeting it is
 * undecided. */
static Tri expand_match(Expansion *x, Atom *pattern, Atom *value,
                        uint32_t depth) {
    if (depth > EXPAND_DEPTH_LIMIT)
        return TRI_UNKNOWN;
    if (pattern->kind == ATOM_VAR) {
        Atom *bound = expand_lookup(x, pattern->var_id);
        if (bound)
            return expand_compare(bound, value, depth);
        return expand_bind(x, pattern->var_id, value) ? TRI_YES : TRI_UNKNOWN;
    }
    if (value->kind == ATOM_VAR)
        return TRI_UNKNOWN;
    if (pattern->kind != ATOM_EXPR || value->kind != ATOM_EXPR) {
        if (pattern->kind == ATOM_EXPR || value->kind == ATOM_EXPR)
            return TRI_NO;
        return expand_compare(pattern, value, depth);
    }
    if (pattern->expr.len != value->expr.len)
        return TRI_NO;
    Tri result = TRI_YES;
    for (CettaExprIndex index = 0u; index < pattern->expr.len; index++) {
        Tri child = expand_match(x, pattern->expr.elems[index],
                                 value->expr.elems[index], depth + 1u);
        if (child == TRI_NO)
            return TRI_NO;
        if (child == TRI_UNKNOWN)
            result = TRI_UNKNOWN;
    }
    return result;
}

/* `(quote X)`: X with each bound variable of the rule replaced by its
 * value.  A substituted value is not read again. */
static Atom *expand_substitute(Expansion *x, Atom *atom, uint32_t depth) {
    if (!atom_has_vars(atom))
        return atom;
    if (depth > EXPAND_DEPTH_LIMIT)
        return expand_decline(x, PETTA_TRANSLATOR_DECLINED_BUDGET);
    if (atom->kind == ATOM_VAR) {
        Atom *bound = expand_lookup(x, atom->var_id);
        return bound ? bound : atom;
    }
    if (atom->kind != ATOM_EXPR)
        return atom;
    CettaExprLen len = atom->expr.len;
    Atom **children = NULL;
    for (CettaExprIndex index = 0u; index < len; index++) {
        Atom *child =
            expand_substitute(x, atom->expr.elems[index], depth + 1u);
        if (!child) {
            free(children);
            return NULL;
        }
        if (child != atom->expr.elems[index] && !children) {
            children = malloc(sizeof(*children) * len);
            if (!children)
                return expand_decline(x, PETTA_TRANSLATOR_CAPACITY);
            memcpy(children, atom->expr.elems, sizeof(*children) * index);
        }
        if (children)
            children[index] = child;
    }
    if (!children)
        return atom;
    Atom *rebuilt = expand_node(x) ? atom_expr(x->arena, children, len) : NULL;
    free(children);
    return rebuilt;
}

static bool expand_form_free(Expansion *x, SymbolId head) {
    if (x->oracle->defines && x->oracle->defines(x->oracle->context, head)) {
        expand_decline(x, PETTA_TRANSLATOR_DECLINED_SHADOWED);
        return false;
    }
    return true;
}

static Atom *expand_eval(Expansion *x, Atom *term, uint32_t depth);

static bool expand_bind_pattern(Expansion *x, Atom *pattern, Atom *source,
                                uint32_t depth) {
    Atom *value = expand_eval(x, source, depth + 1u);
    if (!value)
        return false;
    Tri matched = expand_match(x, pattern, value, depth + 1u);
    if (matched == TRI_YES)
        return true;
    /* A pattern that does not match leaves the rule no answer; the call
     * keeps its translation at each call. */
    expand_decline(x, matched == TRI_NO
        ? PETTA_TRANSLATOR_DECLINED_SELECTION
        : PETTA_TRANSLATOR_DECLINED_UNDECIDED);
    return false;
}

static Atom *expand_eval(Expansion *x, Atom *term, uint32_t depth) {
    if (!term)
        return expand_decline(x, PETTA_TRANSLATOR_DECLINED_FORM);
    if (++x->steps > EXPAND_STEP_BUDGET || depth > EXPAND_DEPTH_LIMIT)
        return expand_decline(x, PETTA_TRANSLATOR_DECLINED_BUDGET);
    switch (term->kind) {
    case ATOM_VAR: {
        Atom *bound = expand_lookup(x, term->var_id);
        return bound ? bound
                     : expand_decline(x, PETTA_TRANSLATOR_DECLINED_FORM);
    }
    case ATOM_SYMBOL:
    case ATOM_GROUNDED:
        return term;
    case ATOM_EXPR:
        break;
    }
    CettaExprLen len = term->expr.len;
    if (len == 0u)
        return term;
    Atom *head = term->expr.elems[0];
    if (!head || head->kind != ATOM_SYMBOL)
        return expand_decline(x, PETTA_TRANSLATOR_DECLINED_FORM);
    SymbolId id = atom_symbol_current_id(head);
    Atom **elems = term->expr.elems;
    if (id == g_builtin_syms.quote && len == 2u) {
        if (!expand_form_free(x, id))
            return NULL;
        return expand_substitute(x, elems[1], depth + 1u);
    }
    if (id == g_builtin_syms.if_text && len == 4u) {
        if (!expand_form_free(x, id))
            return NULL;
        Atom *condition = expand_eval(x, elems[1], depth + 1u);
        if (!condition)
            return NULL;
        if (condition->kind == ATOM_GROUNDED &&
            condition->ground.gkind == GV_BOOL)
            return expand_eval(x, condition->ground.bval ? elems[2] : elems[3],
                               depth + 1u);
        return expand_decline(x, condition->kind == ATOM_VAR
            ? PETTA_TRANSLATOR_DECLINED_UNDECIDED
            : PETTA_TRANSLATOR_DECLINED_FORM);
    }
    if (id == g_builtin_syms.op_eq && len == 3u) {
        if (!expand_form_free(x, id))
            return NULL;
        Atom *left = expand_eval(x, elems[1], depth + 1u);
        Atom *right = left ? expand_eval(x, elems[2], depth + 1u) : NULL;
        if (!right)
            return NULL;
        Tri equal = expand_compare(left, right, 0u);
        if (equal == TRI_UNKNOWN)
            return expand_decline(x, PETTA_TRANSLATOR_DECLINED_UNDECIDED);
        Atom *answer = atom_bool(x->arena, equal == TRI_YES);
        return answer ? answer
                      : expand_decline(x, PETTA_TRANSLATOR_CAPACITY);
    }
    if ((id == g_builtin_syms.car_atom || id == g_builtin_syms.cdr_atom) &&
        len == 2u) {
        if (!expand_form_free(x, id))
            return NULL;
        Atom *value = expand_eval(x, elems[1], depth + 1u);
        if (!value)
            return NULL;
        if (value->kind == ATOM_VAR)
            return expand_decline(x, PETTA_TRANSLATOR_DECLINED_UNDECIDED);
        if (value->kind != ATOM_EXPR || value->expr.len == 0u)
            return expand_decline(x, PETTA_TRANSLATOR_DECLINED_FORM);
        if (id == g_builtin_syms.car_atom)
            return value->expr.elems[0];
        if (!expand_node(x))
            return NULL;
        Atom *rest = atom_expr(x->arena, value->expr.elems + 1u,
                               value->expr.len - 1u);
        return rest ? rest : expand_decline(x, PETTA_TRANSLATOR_CAPACITY);
    }
    if (id == g_builtin_syms.cons_atom && len == 3u) {
        if (!expand_form_free(x, id))
            return NULL;
        Atom *first = expand_eval(x, elems[1], depth + 1u);
        Atom *rest = first ? expand_eval(x, elems[2], depth + 1u) : NULL;
        if (!rest)
            return NULL;
        if (rest->kind == ATOM_VAR)
            return expand_decline(x, PETTA_TRANSLATOR_DECLINED_UNDECIDED);
        if (rest->kind != ATOM_EXPR || !expand_node(x))
            return expand_decline(x, PETTA_TRANSLATOR_DECLINED_FORM);
        Atom *joined = atom_expr_prepend(x->arena, first, rest);
        return joined ? joined : expand_decline(x, PETTA_TRANSLATOR_CAPACITY);
    }
    if (id == g_builtin_syms.let && len == 4u) {
        if (!expand_form_free(x, id) ||
            !expand_bind_pattern(x, elems[1], elems[2], depth))
            return NULL;
        return expand_eval(x, elems[3], depth + 1u);
    }
    if (id == g_builtin_syms.let_star && len == 3u) {
        if (!expand_form_free(x, id))
            return NULL;
        Atom *bindings = elems[1];
        if (bindings->kind != ATOM_EXPR)
            return expand_decline(x, PETTA_TRANSLATOR_DECLINED_FORM);
        for (CettaExprIndex index = 0u; index < bindings->expr.len; index++) {
            Atom *binding = bindings->expr.elems[index];
            if (binding->kind != ATOM_EXPR || binding->expr.len != 2u)
                return expand_decline(x, PETTA_TRANSLATOR_DECLINED_FORM);
            if (!expand_bind_pattern(x, binding->expr.elems[0],
                                     binding->expr.elems[1], depth))
                return NULL;
        }
        return expand_eval(x, elems[2], depth + 1u);
    }
    return expand_decline(x, PETTA_TRANSLATOR_DECLINED_FORM);
}

/* An evaluated argument the expander can pass: one whose value is itself. */
static bool expand_argument_is_value(const Atom *argument) {
    return argument->kind == ATOM_VAR || argument->kind == ATOM_SYMBOL ||
        argument->kind == ATOM_GROUNDED ||
        (argument->kind == ATOM_EXPR && argument->expr.len == 0u);
}

/* Select the one row the call decides.  On success the expansion holds the
 * row's bindings and *rhs its renamed body. */
static PettaTranslatorOutcome expand_select(
    Expansion *x, Atom *call, Atom *const *arguments, Atom **rows,
    size_t row_len, Atom **rhs) {
    size_t decided = 0u;
    Atom *selected_rhs = NULL;
    ExpandBinding *selected = NULL;
    size_t selected_len = 0u;
    bool undecided = false;
    CettaExprLen arity = call->expr.len - 1u;
    for (size_t row = 0u; row < row_len; row++) {
        Atom *source = rows[row];
        if (!source || source->kind != ATOM_EXPR || source->expr.len != 3u ||
            !atom_is_symbol_id(source->expr.elems[0], g_builtin_syms.equals))
            return PETTA_TRANSLATOR_DECLINED_ROWS;
        Atom *lhs = source->expr.elems[1];
        if (!lhs || lhs->kind != ATOM_EXPR || lhs->expr.len != call->expr.len)
            continue;
        if (petta_semantics_contains_cons_constraint(lhs))
            return PETTA_TRANSLATOR_DECLINED_ROWS;
        x->renaming_len = 0u;
        Atom *renamed = expand_rename(x, source, 0u);
        if (!renamed)
            return x->outcome;
        Atom *renamed_lhs = renamed->expr.elems[1];
        x->binding_len = 0u;
        Tri head = renamed_lhs->expr.elems[0]->kind == ATOM_VAR
            ? expand_match(x, renamed_lhs->expr.elems[0],
                           call->expr.elems[0], 0u)
            : expand_compare(renamed_lhs->expr.elems[0],
                             call->expr.elems[0], 0u);
        Tri matched = head;
        for (CettaExprIndex index = 0u;
             matched != TRI_NO && index < arity; index++) {
            Tri argument = expand_match(x, renamed_lhs->expr.elems[index + 1u],
                                        arguments[index], 0u);
            if (argument == TRI_NO)
                matched = TRI_NO;
            else if (argument == TRI_UNKNOWN)
                matched = TRI_UNKNOWN;
        }
        if (x->outcome != PETTA_TRANSLATOR_EXPANDED)
            return x->outcome;
        if (matched == TRI_NO)
            continue;
        if (matched == TRI_UNKNOWN) {
            undecided = true;
            continue;
        }
        if (++decided > 1u)
            break;
        selected_rhs = renamed->expr.elems[2];
        free(selected);
        selected = NULL;
        selected_len = x->binding_len;
        if (selected_len) {
            selected = malloc(sizeof(*selected) * selected_len);
            if (!selected)
                return PETTA_TRANSLATOR_CAPACITY;
            memcpy(selected, x->bindings, sizeof(*selected) * selected_len);
        }
    }
    if (undecided || decided != 1u) {
        free(selected);
        return undecided ? PETTA_TRANSLATOR_DECLINED_UNDECIDED
                         : PETTA_TRANSLATOR_DECLINED_SELECTION;
    }
    x->binding_len = 0u;
    if (selected_len &&
        !expand_reserve((void **)&x->bindings, &x->binding_cap, selected_len,
                        sizeof(*x->bindings))) {
        free(selected);
        return PETTA_TRANSLATOR_CAPACITY;
    }
    if (selected_len)
        memcpy(x->bindings, selected, sizeof(*selected) * selected_len);
    x->binding_len = selected_len;
    free(selected);
    *rhs = selected_rhs;
    return PETTA_TRANSLATOR_EXPANDED;
}

PettaTranslatorOutcome petta_translator_expand_call(
    const PettaTranslatorOracle *oracle, Arena *arena, Atom *call,
    Atom **generated) {
    if (generated)
        *generated = NULL;
    if (!oracle || !oracle->rows || !oracle->arguments || !arena || !call ||
        !generated || call->kind != ATOM_EXPR || call->expr.len == 0u ||
        call->expr.elems[0]->kind != ATOM_SYMBOL)
        return PETTA_TRANSLATOR_DECLINED_FORM;
    CettaExprLen arity = call->expr.len - 1u;
    PettaTranslatorArgument *modes =
        arity ? calloc(arity, sizeof(*modes)) : NULL;
    Atom **arguments = arity ? calloc(arity, sizeof(*arguments)) : NULL;
    if (arity && (!modes || !arguments)) {
        free(modes);
        free(arguments);
        return PETTA_TRANSLATOR_CAPACITY;
    }
    PettaTranslatorOutcome outcome = PETTA_TRANSLATOR_EXPANDED;
    if (!oracle->arguments(oracle->context, call, modes, arity))
        outcome = PETTA_TRANSLATOR_DECLINED_SIGNATURE;
    for (CettaExprIndex index = 0u;
         outcome == PETTA_TRANSLATOR_EXPANDED && index < arity; index++) {
        Atom *argument = call->expr.elems[index + 1u];
        if (modes[index] == PETTA_TRANSLATOR_ARGUMENT_VALUE &&
            !expand_argument_is_value(argument))
            outcome = PETTA_TRANSLATOR_DECLINED_ARGUMENT;
        arguments[index] = argument;
    }
    free(modes);
    Atom **rows = NULL;
    size_t row_len = 0u;
    if (outcome == PETTA_TRANSLATOR_EXPANDED &&
        !oracle->rows(oracle->context, call, &rows, &row_len))
        outcome = PETTA_TRANSLATOR_DECLINED_ROWS;
    Expansion x = {
        .oracle = oracle,
        .arena = arena,
        .outcome = PETTA_TRANSLATOR_EXPANDED,
    };
    Atom *rhs = NULL;
    if (outcome == PETTA_TRANSLATOR_EXPANDED)
        outcome = expand_select(&x, call, arguments, rows, row_len, &rhs);
    free(rows);
    free(arguments);
    Atom *answer = NULL;
    if (outcome == PETTA_TRANSLATOR_EXPANDED) {
        answer = expand_eval(&x, rhs, 0u);
        if (!answer)
            outcome = x.outcome != PETTA_TRANSLATOR_EXPANDED
                ? x.outcome : PETTA_TRANSLATOR_DECLINED_FORM;
    }
    free(x.bindings);
    free(x.renamings);
    if (outcome == PETTA_TRANSLATOR_EXPANDED)
        *generated = answer;
    return outcome;
}

const char *petta_translator_outcome_name(PettaTranslatorOutcome outcome) {
    switch (outcome) {
    case PETTA_TRANSLATOR_EXPANDED: return "expanded";
    case PETTA_TRANSLATOR_DECLINED_ROWS: return "declined-rows";
    case PETTA_TRANSLATOR_DECLINED_SIGNATURE: return "declined-signature";
    case PETTA_TRANSLATOR_DECLINED_ARGUMENT: return "declined-argument";
    case PETTA_TRANSLATOR_DECLINED_SELECTION: return "declined-selection";
    case PETTA_TRANSLATOR_DECLINED_FORM: return "declined-form";
    case PETTA_TRANSLATOR_DECLINED_UNDECIDED: return "declined-undecided";
    case PETTA_TRANSLATOR_DECLINED_SHADOWED: return "declined-shadowed";
    case PETTA_TRANSLATOR_DECLINED_BUDGET: return "declined-budget";
    case PETTA_TRANSLATOR_CAPACITY: return "capacity";
    case PETTA_TRANSLATOR_OUTCOME_COUNT: break;
    }
    return "unknown";
}
