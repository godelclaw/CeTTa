#define _GNU_SOURCE
#include "grounded.h"
#include "eval.h"
#include "match.h"
#include "parser.h"
#include "space.h"
#if CETTA_BUILD_WITH_GMP
#include <gmp.h>
#endif
#include <inttypes.h>
#include <string.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#if defined(__GNUC__)
__attribute__((weak))
#endif
bool eval_current_prefer_rationals(void) {
    return false;
}

#if defined(__GNUC__)
__attribute__((weak))
#endif
bool eval_current_uses_rust_he_compat_semantics(void) {
    return false;
}

typedef struct {
    char *buf;
    size_t len;
    size_t cap;
} StringBuf;

typedef struct {
    SymbolId spelling;
    Atom *mapped;
} FoldVarMapEntry;

typedef struct {
    FoldVarMapEntry *items;
    uint32_t len;
    uint32_t cap;
} FoldVarMap;

static void sb_init(StringBuf *sb) {
    sb->buf = NULL;
    sb->len = 0;
    sb->cap = 0;
}

static void sb_ensure(StringBuf *sb, size_t extra) {
    size_t need = sb->len + extra + 1;
    if (need <= sb->cap) return;
    size_t next = sb->cap ? sb->cap * 2 : 64;
    while (next < need) next *= 2;
    sb->buf = cetta_realloc(sb->buf, next);
    sb->cap = next;
}

static void sb_append_n(StringBuf *sb, const char *s, size_t n) {
    sb_ensure(sb, n);
    memcpy(sb->buf + sb->len, s, n);
    sb->len += n;
    sb->buf[sb->len] = '\0';
}

static void sb_append(StringBuf *sb, const char *s) {
    sb_append_n(sb, s, strlen(s));
}

static void sb_free(StringBuf *sb) {
    free(sb->buf);
    sb->buf = NULL;
    sb->len = 0;
    sb->cap = 0;
}

static uint32_t next_pow2_u32(uint32_t n) {
    uint32_t cap = 1;
    while (cap < n && cap < (UINT32_MAX >> 1))
        cap <<= 1;
    return cap;
}

static void fold_var_map_init(FoldVarMap *map) {
    map->items = NULL;
    map->len = 0;
    map->cap = 0;
}

static void fold_var_map_free(FoldVarMap *map) {
    free(map->items);
    map->items = NULL;
    map->len = 0;
    map->cap = 0;
}

static Atom *fold_var_map_lookup(FoldVarMap *map, SymbolId spelling) {
    for (uint32_t i = 0; i < map->len; i++) {
        if (map->items[i].spelling == spelling)
            return map->items[i].mapped;
    }
    return NULL;
}

static Atom *fold_var_map_add_fresh(FoldVarMap *map, Arena *a, SymbolId spelling) {
    Atom *fresh = atom_var_with_spelling(a, spelling, fresh_var_id());
    if (map->len >= map->cap) {
        map->cap = map->cap ? map->cap * 2 : 8;
        map->items = cetta_realloc(map->items, sizeof(FoldVarMapEntry) * map->cap);
    }
    map->items[map->len].spelling = spelling;
    map->items[map->len].mapped = fresh;
    map->len++;
    return fresh;
}

static Atom *grounded_call_expr(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    Atom **elems = arena_alloc(a, sizeof(Atom *) * (nargs + 1));
    elems[0] = head;
    for (uint32_t i = 0; i < nargs; i++)
        elems[i + 1] = args[i];
    return atom_expr(a, elems, nargs + 1);
}

static Atom *foldl_bind_step_atom_impl(Arena *a, Atom *atom,
                                       SymbolId acc_spelling, Atom *acc_val,
                                       SymbolId item_spelling, Atom *item_val,
                                       FoldVarMap *fresh_vars) {
    switch (atom->kind) {
    case ATOM_VAR:
        if (atom->sym_id == acc_spelling)
            return acc_val;
        if (atom->sym_id == item_spelling)
            return item_val;
        {
            Atom *mapped = fold_var_map_lookup(fresh_vars, atom->sym_id);
            if (mapped)
                return mapped;
            return fold_var_map_add_fresh(fresh_vars, a, atom->sym_id);
        }
    case ATOM_EXPR: {
        Atom **elems = arena_alloc(a, sizeof(Atom *) * atom->expr.len);
        bool changed = false;
        for (CettaExprIndex i = 0; i < atom->expr.len; i++) {
            elems[i] = foldl_bind_step_atom_impl(a, atom->expr.elems[i],
                                                 acc_spelling, acc_val,
                                                 item_spelling, item_val,
                                                 fresh_vars);
            if (elems[i] != atom->expr.elems[i])
                changed = true;
        }
        if (!changed)
            return atom;
        return atom_expr(a, elems, atom->expr.len);
    }
    default:
        return atom;
    }
}

Atom *cetta_fold_bind_step_atom(Arena *a, Atom *atom,
                                SymbolId acc_spelling, Atom *acc_val,
                                SymbolId item_spelling, Atom *item_val) {
    FoldVarMap fresh_vars;
    fold_var_map_init(&fresh_vars);
    Atom *bound = foldl_bind_step_atom_impl(a, atom,
                                            acc_spelling, acc_val,
                                            item_spelling, item_val,
                                            &fresh_vars);
    fold_var_map_free(&fresh_vars);
    return bound;
}

static Atom *grounded_bad_arg_type(Arena *a, Atom *head, Atom **args, uint32_t nargs,
                                   int bad_idx, Atom *expected_type, Atom *actual_atom) {
    Atom *actual_type = (actual_atom && actual_atom->kind == ATOM_GROUNDED)
        ? get_grounded_type(a, actual_atom)
        : get_meta_type(a, actual_atom);
    Atom *reason = atom_expr(a, (Atom*[]){
        atom_symbol(a, "BadArgType"),
        atom_int(a, bad_idx),
        expected_type,
        actual_type
    }, 4);
    return atom_error(a, grounded_call_expr(a, head, args, nargs), reason);
}

static Atom *grounded_string_error(Arena *a, Atom *head, Atom **args, uint32_t nargs,
                                   const char *message) {
    return atom_error(a, grounded_call_expr(a, head, args, nargs),
                      atom_symbol(a, message));
}

static Atom *grounded_incorrect_arity(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    return atom_error(a, grounded_call_expr(a, head, args, nargs),
                      atom_symbol(a, "IncorrectNumberOfArguments"));
}

static Atom *grounded_expr_message_error(Arena *a, Atom *head, Atom **args, uint32_t nargs,
                                         const char *prefix, Atom *expr) {
    char buf[1024];
    int pos = snprintf(buf, sizeof(buf), "%s", prefix);
    if (pos < 0) pos = 0;
    if ((size_t)pos < sizeof(buf)) {
        FILE *tmp = fmemopen(buf + pos, sizeof(buf) - (size_t)pos, "w");
        if (tmp) {
            atom_print(expr, tmp);
            fclose(tmp);
        }
    }
    buf[sizeof(buf) - 1] = '\0';
    return atom_error(a, grounded_call_expr(a, head, args, nargs),
                      atom_symbol(a, buf));
}

static bool find_unused_alpha_equal_atom(Atom **elems, bool *used,
                                         CettaExprLen len, Atom *candidate,
                                         CettaExprIndex *out_index) {
    for (CettaExprIndex i = 0; i < len; i++) {
        if (!used[i] && atom_alpha_eq(elems[i], candidate)) {
            if (out_index)
                *out_index = i;
            return true;
        }
    }
    return false;
}

bool is_grounded_op(SymbolId id) {
    if (id == SYMBOL_ID_NONE) return false;
    /* Check __cetta_lib_ prefix via string lookup */
    const char *name = symbol_bytes(g_symbols, id);
    if (name && strncmp(name, "__cetta_lib_", 12) == 0)
        return true;
    if (id == g_builtin_syms.mork_add_atoms ||
        id == g_builtin_syms.mork_add_atom ||
        id == g_builtin_syms.mork_remove_atom)
        return true;
    if (id == g_builtin_syms.add_atom ||
        id == g_builtin_syms.remove_atom)
        return true;
    return id == g_builtin_syms.op_plus || id == g_builtin_syms.op_minus ||
           id == g_builtin_syms.op_mul || id == g_builtin_syms.op_div ||
           id == g_builtin_syms.op_floor_div || id == g_builtin_syms.op_mod ||
           id == g_builtin_syms.op_lt ||
           id == g_builtin_syms.op_gt || id == g_builtin_syms.op_le ||
           id == g_builtin_syms.op_ge || id == g_builtin_syms.op_eq ||
           id == g_builtin_syms.numeric_eq ||
           id == g_builtin_syms.alpha_eq ||
           id == g_builtin_syms.if_equal ||
           id == g_builtin_syms.sealed_text ||
           id == g_builtin_syms.minimal_foldl_atom ||
           id == g_builtin_syms.minimal_foldl_until_atom ||
           id == g_builtin_syms.minimal_foldl_llist ||
           id == g_builtin_syms.minimal_space_contains_exact ||
           id == g_builtin_syms.collapse_add_next ||
           id == g_builtin_syms.foldl_atom_in_space ||
           id == g_builtin_syms.op_and || id == g_builtin_syms.op_or ||
           id == g_builtin_syms.op_not || id == g_builtin_syms.op_xor ||
           id == g_builtin_syms.println_bang ||
           id == g_builtin_syms.trace_bang ||
           id == g_builtin_syms.format_args ||
           id == g_builtin_syms.repr ||
           id == g_builtin_syms.parse ||
           id == g_builtin_syms.parse_first ||
           id == g_builtin_syms.py_atom ||
           id == g_builtin_syms.py_dot ||
           id == g_builtin_syms.py_call ||
           id == g_builtin_syms.sort_strings ||
           id == g_builtin_syms.print_alternatives_bang ||
           id == g_builtin_syms.unique_atom ||
           id == g_builtin_syms.intersection_atom ||
           id == g_builtin_syms.subtraction_atom ||
           id == g_builtin_syms.member_atom_q ||
           id == g_builtin_syms.subset_atom_q ||
           id == g_builtin_syms.same_set_atom_q ||
           id == g_builtin_syms.galois_closure_atom ||
           id == g_builtin_syms.galois_intents_atom ||
           id == g_builtin_syms.galois_canonical_basis_atom ||
           id == g_builtin_syms.galois_canonical_basis_next_atom ||
           id == g_builtin_syms.wm_fca_index_columns_atom ||
           id == g_builtin_syms.wm_fca_binary_rows_columns_atom ||
           id == g_builtin_syms.wm_fca_binary_cell_status_atom ||
           id == g_builtin_syms.wm_fca_binary_query_batch_atom ||
           id == g_builtin_syms.wm_fca_binary_event_columns_atom ||
           id == g_builtin_syms.wm_fca_binary_event_cell_evidence_atom ||
           id == g_builtin_syms.wm_fca_binary_event_query_batch_atom ||
           id == g_builtin_syms.wm_fca_binary_event_observation_count_atom ||
           id == g_builtin_syms.wm_fca_evidence_layer_columns_atom ||
           id == g_builtin_syms.wm_fca_evidence_layer_cell_evidence_atom ||
           id == g_builtin_syms.wm_fca_evidence_layer_query_batch_atom ||
           id == g_builtin_syms.wm_fca_evidence_layer_observation_count_atom ||
           id == g_builtin_syms.subset_cover_relations_atom ||
           id == g_builtin_syms.max_atom ||
           id == g_builtin_syms.min_atom ||
           id == g_builtin_syms.pow_math ||
           id == g_builtin_syms.sqrt_math ||
           id == g_builtin_syms.abs_math ||
           id == g_builtin_syms.log_math ||
           id == g_builtin_syms.trunc_math ||
           id == g_builtin_syms.ceil_math ||
           id == g_builtin_syms.floor_math ||
           id == g_builtin_syms.round_math ||
           id == g_builtin_syms.sin_math ||
           id == g_builtin_syms.asin_math ||
           id == g_builtin_syms.cos_math ||
           id == g_builtin_syms.acos_math ||
           id == g_builtin_syms.tan_math ||
           id == g_builtin_syms.atan_math ||
           id == g_builtin_syms.isnan_math ||
           id == g_builtin_syms.isinf_math ||
           id == g_builtin_syms.size ||
           id == g_builtin_syms.size_atom || id == g_builtin_syms.index_atom ||
           id == g_builtin_syms.range_atom || id == g_builtin_syms.repeat_atom;
}

/* ── Numeric arg extraction (int or float, promote to double) ──────────── */

typedef struct {
    double val;
    int64_t ival;
    Atom *bigint;
    Atom *rational;
    bool is_float;
    bool is_bigint;
    bool is_rational;
} NumArg;

static bool get_numeric_arg(Atom *a, NumArg *out) {
    if (a->kind != ATOM_GROUNDED) return false;
    if (a->ground.gkind == GV_INT) {
        out->val = (double)a->ground.ival;
        out->ival = a->ground.ival;
        out->bigint = NULL;
        out->rational = NULL;
        out->is_float = false;
        out->is_bigint = false;
        out->is_rational = false;
        return true;
    }
    if (a->ground.gkind == GV_BIGINT) {
        out->val = strtod(atom_bigint_cstr(a), NULL);
        out->ival = 0;
        out->bigint = a;
        out->rational = NULL;
        out->is_float = false;
        out->is_bigint = true;
        out->is_rational = false;
        return true;
    }
    if (a->ground.gkind == GV_RATIONAL) {
#if CETTA_BUILD_WITH_GMP
        mpq_t q;
        mpq_init(q);
        bool ok = atom_rational_get_mpq(a, q);
        out->val = ok ? mpq_get_d(q) : 0.0;
        mpq_clear(q);
#else
        out->val = 0.0;
#endif
        out->ival = 0;
        out->bigint = NULL;
        out->rational = a;
        out->is_float = false;
        out->is_bigint = false;
        out->is_rational = true;
        return true;
    }
    if (a->ground.gkind == GV_FLOAT) {
        out->val = a->ground.fval;
        out->ival = 0;
        out->bigint = NULL;
        out->rational = NULL;
        out->is_float = true;
        out->is_bigint = false;
        out->is_rational = false;
        return true;
    }
    return false;
}

static bool get_numeric_arg_for_math(Atom *a, NumArg *out) {
    if (!get_numeric_arg(a, out))
        return false;
    if (eval_current_uses_rust_he_compat_semantics() && out->is_rational)
        return false;
    return true;
}

#if CETTA_BUILD_WITH_GMP
static bool num_arg_to_mpz(const NumArg *arg, mpz_t out) {
    if (!arg || arg->is_float || arg->is_rational)
        return false;
    if (arg->is_bigint)
        return atom_bigint_get_mpz(arg->bigint, out);
    uint64_t magnitude = arg->ival < 0
        ? (uint64_t)(-(arg->ival + 1)) + 1u
        : (uint64_t)arg->ival;
    mpz_import(out, 1, -1, sizeof(magnitude), 0, 0, &magnitude);
    if (arg->ival < 0)
        mpz_neg(out, out);
    return true;
}

static Atom *atom_from_mpz(Arena *a, const mpz_t value) {
    return atom_bigint_from_mpz(a, value);
}

static bool num_arg_to_mpq(const NumArg *arg, mpq_t out) {
    if (!arg || arg->is_float)
        return false;
    if (arg->is_rational)
        return atom_rational_get_mpq(arg->rational, out);
    mpz_t z;
    mpz_init(z);
    bool ok = num_arg_to_mpz(arg, z);
    if (ok)
        mpq_set_z(out, z);
    mpz_clear(z);
    return ok;
}

static Atom *atom_from_mpq(Arena *a, const mpq_t value) {
    return atom_rational_from_mpq(a, value);
}

static Atom *grounded_atom_from_mpq(Arena *a, Atom *head, Atom **args,
                                    uint32_t nargs, const mpq_t value) {
    (void)head;
    (void)args;
    (void)nargs;
    return atom_from_mpq(a, value);
}

static Atom *atom_from_floor_div_mpq(Arena *a, const mpq_t lhs,
                                     const mpq_t rhs) {
    if (mpq_sgn(rhs) == 0)
        return NULL;
    mpq_t q;
    mpz_t z;
    mpq_init(q);
    mpz_init(z);
    mpq_div(q, lhs, rhs);
    mpz_fdiv_q(z, mpq_numref(q), mpq_denref(q));
    Atom *out = atom_from_mpz(a, z);
    mpz_clear(z);
    mpq_clear(q);
    return out;
}

static Atom *atom_from_rational_abs(Arena *a, Atom *head, Atom **args,
                                    uint32_t nargs, const NumArg *arg) {
    mpq_t q;
    mpq_init(q);
    bool ok = num_arg_to_mpq(arg, q);
    if (ok && mpq_sgn(q) < 0)
        mpq_neg(q, q);
    Atom *out = ok ? grounded_atom_from_mpq(a, head, args, nargs, q) : NULL;
    mpq_clear(q);
    return out;
}

static Atom *atom_from_rational_integer_part(Arena *a, const NumArg *arg,
                                             SymbolId op) {
    mpq_t q;
    mpz_t z;
    mpq_init(q);
    mpz_init(z);
    bool ok = num_arg_to_mpq(arg, q);
    if (ok) {
        if (op == g_builtin_syms.trunc_math)
            mpz_tdiv_q(z, mpq_numref(q), mpq_denref(q));
        else if (op == g_builtin_syms.floor_math)
            mpz_fdiv_q(z, mpq_numref(q), mpq_denref(q));
        else
            mpz_cdiv_q(z, mpq_numref(q), mpq_denref(q));
    }
    Atom *out = ok ? atom_from_mpz(a, z) : NULL;
    mpz_clear(z);
    mpq_clear(q);
    return out;
}

static Atom *atom_from_rational_round(Arena *a, const NumArg *arg) {
    mpq_t q;
    mpz_t abs_num, quotient, remainder, twice_remainder;
    mpq_init(q);
    mpz_inits(abs_num, quotient, remainder, twice_remainder, NULL);
    bool ok = num_arg_to_mpq(arg, q);
    if (ok) {
        int sign = mpq_sgn(q);
        mpz_abs(abs_num, mpq_numref(q));
        mpz_tdiv_qr(quotient, remainder, abs_num, mpq_denref(q));
        mpz_mul_ui(twice_remainder, remainder, 2u);
        if (mpz_cmp(twice_remainder, mpq_denref(q)) >= 0)
            mpz_add_ui(quotient, quotient, 1u);
        if (sign < 0)
            mpz_neg(quotient, quotient);
    }
    Atom *out = ok ? atom_from_mpz(a, quotient) : NULL;
    mpz_clears(abs_num, quotient, remainder, twice_remainder, NULL);
    mpq_clear(q);
    return out;
}

static Atom *atom_from_rational_square_root(Arena *a, Atom *head, Atom **args,
                                            uint32_t nargs, const NumArg *arg,
                                            bool *was_exact) {
    mpq_t q;
    mpz_t num_root, den_root;
    mpq_init(q);
    mpz_inits(num_root, den_root, NULL);
    *was_exact = false;
    bool ok = num_arg_to_mpq(arg, q);
    Atom *out = NULL;
    if (ok && mpq_sgn(q) >= 0 &&
        mpz_perfect_square_p(mpq_numref(q)) &&
        mpz_perfect_square_p(mpq_denref(q))) {
        mpq_t root;
        mpq_init(root);
        mpz_sqrt(num_root, mpq_numref(q));
        mpz_sqrt(den_root, mpq_denref(q));
        mpq_set_num(root, num_root);
        mpq_set_den(root, den_root);
        mpq_canonicalize(root);
        out = grounded_atom_from_mpq(a, head, args, nargs, root);
        *was_exact = true;
        mpq_clear(root);
    }
    mpz_clears(num_root, den_root, NULL);
    mpq_clear(q);
    return out;
}
#endif

static Atom *grounded_division_by_zero(Arena *a, Atom *head, Atom **args,
                                       uint32_t nargs);

static Atom *grounded_rational_unavailable(Arena *a, Atom *head,
                                           Atom **args, uint32_t nargs)
    __attribute__((unused));
static Atom *grounded_rational_unavailable(Arena *a, Atom *head,
                                           Atom **args, uint32_t nargs) {
    return atom_error(a, grounded_call_expr(a, head, args, nargs),
                      atom_symbol(a, "RationalArithmeticUnavailable"));
}

#if CETTA_BUILD_WITH_GMP
static Atom *eval_integer_binary_gmp(Arena *a, Atom *head, SymbolId head_id,
                                     Atom **args, uint32_t nargs,
                                     const NumArg *na, const NumArg *nb,
                                     bool prefer_rationals,
                                     bool rust_compat) {
    bool wants_rational = na->is_rational || nb->is_rational ||
                          (prefer_rationals && head_id == g_builtin_syms.op_div);
    if (wants_rational) {
        mpq_t ai, bi, ri;
        mpq_inits(ai, bi, ri, NULL);
        bool ok = num_arg_to_mpq(na, ai) && num_arg_to_mpq(nb, bi);
        if (!ok) {
            mpq_clears(ai, bi, ri, NULL);
            return NULL;
        }
        Atom *result = NULL;
        if (head_id == g_builtin_syms.op_plus) {
            mpq_add(ri, ai, bi);
            result = grounded_atom_from_mpq(a, head, args, nargs, ri);
        } else if (head_id == g_builtin_syms.op_minus) {
            mpq_sub(ri, ai, bi);
            result = grounded_atom_from_mpq(a, head, args, nargs, ri);
        } else if (head_id == g_builtin_syms.op_mul) {
            mpq_mul(ri, ai, bi);
            result = grounded_atom_from_mpq(a, head, args, nargs, ri);
        } else if (head_id == g_builtin_syms.op_div) {
            if (mpq_sgn(bi) == 0)
                result = grounded_division_by_zero(a, head, args, nargs);
            else {
                mpq_div(ri, ai, bi);
                result = grounded_atom_from_mpq(a, head, args, nargs, ri);
            }
        } else if (head_id == g_builtin_syms.op_floor_div) {
            if (mpq_sgn(bi) == 0)
                result = grounded_division_by_zero(a, head, args, nargs);
            else
                result = atom_from_floor_div_mpq(a, ai, bi);
        } else if (head_id == g_builtin_syms.op_mod) {
            if (mpq_sgn(bi) == 0)
                result = grounded_division_by_zero(a, head, args, nargs);
            else {
                int bad_idx = na->is_rational ? 1 : 2;
                result = grounded_bad_arg_type(a, head, args, nargs,
                                               bad_idx, atom_symbol(a, "Number"),
                                               args[bad_idx - 1]);
            }
        } else {
            int cmp = mpq_cmp(ai, bi);
            if (head_id == g_builtin_syms.op_lt)
                result = cmp < 0 ? atom_true(a) : atom_false(a);
            else if (head_id == g_builtin_syms.op_gt)
                result = cmp > 0 ? atom_true(a) : atom_false(a);
            else if (head_id == g_builtin_syms.op_le)
                result = cmp <= 0 ? atom_true(a) : atom_false(a);
            else if (head_id == g_builtin_syms.op_ge)
                result = cmp >= 0 ? atom_true(a) : atom_false(a);
        }
        mpq_clears(ai, bi, ri, NULL);
        return result;
    }

    mpz_t ai, bi, ri;
    mpz_inits(ai, bi, ri, NULL);
    bool ok = num_arg_to_mpz(na, ai) && num_arg_to_mpz(nb, bi);
    if (!ok) {
        mpz_clears(ai, bi, ri, NULL);
        return NULL;
    }

    Atom *result = NULL;
    if (head_id == g_builtin_syms.op_plus) {
        mpz_add(ri, ai, bi);
        result = atom_from_mpz(a, ri);
    } else if (head_id == g_builtin_syms.op_minus) {
        mpz_sub(ri, ai, bi);
        result = atom_from_mpz(a, ri);
    } else if (head_id == g_builtin_syms.op_mul) {
        mpz_mul(ri, ai, bi);
        result = atom_from_mpz(a, ri);
    } else if (head_id == g_builtin_syms.op_div) {
        if (mpz_sgn(bi) == 0) {
            result = grounded_division_by_zero(a, head, args, nargs);
        } else if (rust_compat) {
            mpz_tdiv_q(ri, ai, bi);
            result = atom_from_mpz(a, ri);
        } else if (mpz_divisible_p(ai, bi)) {
            mpz_tdiv_q(ri, ai, bi);
            result = atom_from_mpz(a, ri);
        } else {
            result = atom_float(a, mpz_get_d(ai) / mpz_get_d(bi));
        }
    } else if (head_id == g_builtin_syms.op_floor_div) {
        if (mpz_sgn(bi) == 0) {
            result = grounded_division_by_zero(a, head, args, nargs);
        } else {
            mpz_fdiv_q(ri, ai, bi);
            result = atom_from_mpz(a, ri);
        }
    } else if (head_id == g_builtin_syms.op_mod) {
        if (mpz_sgn(bi) == 0) {
            result = grounded_division_by_zero(a, head, args, nargs);
        } else {
            mpz_tdiv_r(ri, ai, bi);
            result = atom_from_mpz(a, ri);
        }
    } else {
        int cmp = mpz_cmp(ai, bi);
        if (head_id == g_builtin_syms.op_lt)
            result = cmp < 0 ? atom_true(a) : atom_false(a);
        else if (head_id == g_builtin_syms.op_gt)
            result = cmp > 0 ? atom_true(a) : atom_false(a);
        else if (head_id == g_builtin_syms.op_le)
            result = cmp <= 0 ? atom_true(a) : atom_false(a);
        else if (head_id == g_builtin_syms.op_ge)
            result = cmp >= 0 ? atom_true(a) : atom_false(a);
    }
    mpz_clears(ai, bi, ri, NULL);
    return result;
}
#else
static Atom *grounded_bigint_unavailable(Arena *a, Atom *head, Atom **args,
                                         uint32_t nargs) {
    return atom_error(a, grounded_call_expr(a, head, args, nargs),
                      atom_symbol(a, "BigintArithmeticUnavailable"));
}

static Atom *eval_integer_binary_gmp(Arena *a, Atom *head, SymbolId head_id,
                                     Atom **args, uint32_t nargs,
                                     const NumArg *na, const NumArg *nb,
                                     bool prefer_rationals,
                                     bool rust_compat) {
    (void)na;
    (void)nb;
    (void)rust_compat;
    if (prefer_rationals && head_id == g_builtin_syms.op_div)
        return grounded_rational_unavailable(a, head, args, nargs);
    (void)head_id;
    return grounded_bigint_unavailable(a, head, args, nargs);
}
#endif

/* Return int if both inputs were int and result is exact, otherwise float */
static Atom *make_numeric(Arena *a, double val, bool any_float) {
    if (any_float)
        return atom_float(a, val);
    if (!isfinite(val))
        return atom_float(a, val);
    if (val < (double)INT64_MIN || val > (double)INT64_MAX)
        return atom_float(a, val);
    int64_t lv = (int64_t)val;
    if ((double)lv == val)
        return atom_int(a, lv);
    return atom_float(a, val);
}

static Atom *grounded_division_by_zero(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    return atom_error(a, grounded_call_expr(a, head, args, nargs),
                      atom_symbol(a, "DivisionByZero"));
}

static Atom *grounded_math_domain_error(Arena *a, Atom *head, Atom **args,
                                        uint32_t nargs, int bad_idx,
                                        const char *constraint) {
    Atom *reason = atom_expr(a, (Atom *[]){
        atom_symbol(a, "MathDomainError"),
        atom_int(a, bad_idx),
        atom_symbol(a, constraint)
    }, 3);
    return atom_error(a, grounded_call_expr(a, head, args, nargs), reason);
}

static bool numeric_arg_is_integral(const NumArg *arg) {
    if (!arg->is_float) return true;
    if (!isfinite(arg->val)) return false;
    double whole = 0.0;
    return modf(arg->val, &whole) == 0.0;
}

static int64_t floor_div_i64(int64_t lhs, int64_t rhs) {
    int64_t q = lhs / rhs;
    int64_t r = lhs % rhs;
    if (r != 0 && ((r > 0) != (rhs > 0)))
        q -= 1;
    return q;
}

/* ── Boolean arg extraction (True/False symbols) ──────────────────────── */

static bool get_bool_arg(Atom *a, bool *out) {
    if (atom_is_symbol_id(a, g_builtin_syms.true_text))  { *out = true;  return true; }
    if (atom_is_symbol_id(a, g_builtin_syms.false_text)) { *out = false; return true; }
    if (a->kind == ATOM_GROUNDED && a->ground.gkind == GV_BOOL) {
        *out = a->ground.bval; return true;
    }
    return false;
}

static Atom *grounded_bool_bad_arg(Arena *a, Atom *head, Atom **args, uint32_t nargs,
                                   int bad_idx, Atom *actual) {
    return grounded_bad_arg_type(a, head, args, nargs, bad_idx, atom_symbol(a, "Bool"), actual);
}

static Atom *grounded_format_args(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    if (nargs != 2)
        return grounded_incorrect_arity(a, head, args, nargs);
    if (!(args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_STRING))
        return grounded_string_error(a, head, args, nargs,
                                     "format-args expects format string as a first argument and expression as a second argument");
    if (args[1]->kind != ATOM_EXPR)
        return grounded_string_error(a, head, args, nargs, "Atom is not an ExpressionAtom");

    const char *fmt = args[0]->ground.sval;
    Atom *arg_list = args[1];
    StringBuf sb;
    sb_init(&sb);
    uint32_t argi = 0;
    for (const char *p = fmt; *p; ) {
        if (p[0] == '{' && p[1] == '}') {
            if (argi < arg_list->expr.len) {
                char *rendered = atom_to_string(a, arg_list->expr.elems[argi++]);
                sb_append(&sb, rendered);
            }
            p += 2;
            continue;
        }
        sb_append_n(&sb, p, 1);
        p++;
    }
    Atom *out = atom_string(a, sb.buf ? sb.buf : "");
    sb_free(&sb);
    return out;
}

static int grounded_sort_strings_cmp(const void *lhs, const void *rhs) {
    const char *const *a = lhs;
    const char *const *b = rhs;
    return strcmp(*a, *b);
}

static Atom *grounded_sort_strings(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    if (nargs != 1)
        return grounded_incorrect_arity(a, head, args, nargs);
    if (args[0]->kind != ATOM_EXPR)
        return grounded_string_error(a, head, args, nargs,
                                     "sort-strings expects expression with strings as a first argument");

    Atom *list = args[0];
    const char **strings = arena_alloc(a, sizeof(const char *) * list->expr.len);
    Atom **sorted = arena_alloc(a, sizeof(Atom *) * list->expr.len);
    for (CettaExprIndex i = 0; i < list->expr.len; i++) {
        Atom *elem = list->expr.elems[i];
        if (!(elem->kind == ATOM_GROUNDED && elem->ground.gkind == GV_STRING)) {
            return grounded_string_error(a, head, args, nargs,
                                         "sort-strings expects expression with strings as a first argument");
        }
        strings[i] = elem->ground.sval;
    }

    qsort(strings, list->expr.len, sizeof(const char *), grounded_sort_strings_cmp);
    for (CettaExprIndex i = 0; i < list->expr.len; i++)
        sorted[i] = atom_string(a, strings[i]);
    return atom_expr(a, sorted, list->expr.len);
}

static Atom *grounded_repr(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    if (nargs != 1)
        return grounded_incorrect_arity(a, head, args, nargs);
    return atom_string(a, atom_to_parseable_string(a, args[0]));
}

/* Text parsing deliberately has two surfaces:
   - parse is strict: the string must contain exactly one atom, with only
     whitespace/comments around it. This is the safer PeTTa-style default.
   - parse-first is stream-like: it returns the first parsed atom and ignores
     all remaining text, including malformed trailing text. */
static Atom *grounded_parse_text(Arena *a, Atom *head, Atom **args,
                                uint32_t nargs, bool require_all_input) {
    if (nargs != 1)
        return grounded_incorrect_arity(a, head, args, nargs);
    if (!(args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_STRING)) {
        if (args[0]->kind != ATOM_GROUNDED)
            return NULL;
        return grounded_bad_arg_type(a, head, args, nargs, 1,
                                     atom_symbol(a, "String"), args[0]);
    }

    if (require_all_input && !parser_text_well_formed(args[0]->ground.sval))
        return atom_error(a, grounded_call_expr(a, head, args, nargs),
                          atom_symbol(a, "ParseFailed"));

    bool old_rational_literals = parser_set_rational_literals_enabled(
        !eval_current_uses_rust_he_compat_semantics());
    size_t pos = 0;
    Atom *parsed = parse_sexpr(a, args[0]->ground.sval, &pos);
    parser_set_rational_literals_enabled(old_rational_literals);
    if (!parsed)
        return atom_error(a, grounded_call_expr(a, head, args, nargs),
                          atom_symbol(a, "ParseFailed"));
    if (require_all_input && !parser_rest_is_delimiters(args[0]->ground.sval, &pos))
        return atom_error(a, grounded_call_expr(a, head, args, nargs),
                          atom_symbol(a, "ParseFailed"));
    return parsed;
}

static Atom *grounded_collapse_add_next(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    if (nargs != 2)
        return grounded_incorrect_arity(a, head, args, nargs);
    if (args[0]->kind != ATOM_EXPR)
        return grounded_bad_arg_type(a, head, args, nargs, 1,
                                     atom_expression_type(a), args[0]);

    Atom *pair = args[1];
    if (pair->kind != ATOM_EXPR || pair->expr.len != 2)
        return grounded_string_error(a, head, args, nargs,
                                     "(Atom Bindings) pair is expected as a second argument");

    Bindings bindings;
    if (!bindings_from_atom(pair->expr.elems[1], &bindings))
        return grounded_string_error(a, head, args, nargs,
                                     "(Atom Bindings) pair is expected as a second argument");

    Atom *next_atom = bindings_apply(&bindings, a, pair->expr.elems[0]);
    bindings_free(&bindings);

    Atom *list = args[0];
    Atom **elems = arena_alloc(a, sizeof(Atom *) * (list->expr.len + 1));
    for (CettaExprIndex i = 0; i < list->expr.len; i++)
        elems[i] = list->expr.elems[i];
    elems[list->expr.len] = next_atom;
    return atom_expr(a, elems, list->expr.len + 1);
}

static Atom *grounded_space_contains_exact(Arena *a, Atom *head,
                                           Atom **args, uint32_t nargs) {
    if (nargs != 2)
        return grounded_incorrect_arity(a, head, args, nargs);
    if (!(args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_SPACE))
        return grounded_bad_arg_type(a, head, args, nargs, 1,
                                     atom_symbol(a, "SpaceType"), args[0]);
    return atom_bool(a, space_contains_exact((Space *)args[0]->ground.ptr, args[1]));
}

static Atom *grounded_foldl_in_space(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    if (nargs != 6)
        return grounded_incorrect_arity(a, head, args, nargs);
    if (args[0]->kind != ATOM_EXPR)
        return grounded_bad_arg_type(a, head, args, nargs, 1,
                                     atom_expression_type(a), args[0]);
    if (args[2]->kind != ATOM_VAR)
        return grounded_bad_arg_type(a, head, args, nargs, 3,
                                     atom_variable_type(a), args[2]);
    if (args[3]->kind != ATOM_VAR)
        return grounded_bad_arg_type(a, head, args, nargs, 4,
                                     atom_variable_type(a), args[3]);
    if (!(args[5]->kind == ATOM_GROUNDED && args[5]->ground.gkind == GV_SPACE))
        return grounded_bad_arg_type(a, head, args, nargs, 6,
                                     atom_symbol(a, "SpaceType"), args[5]);

    Atom *list = args[0];
    Atom *init = args[1];
    Atom *acc_var = args[2];
    Atom *item_var = args[3];
    Atom *op_expr = args[4];
    Atom *space = args[5];

    bool stop_aware = head->kind == ATOM_SYMBOL &&
                      head->sym_id == g_builtin_syms.minimal_foldl_until_atom;
    if (stop_aware) {
        if (init->kind != ATOM_EXPR || init->expr.len != 2 ||
            init->expr.elems[0]->kind != ATOM_SYMBOL ||
            (init->expr.elems[0]->sym_id != g_builtin_syms.fold_continue &&
             init->expr.elems[0]->sym_id != g_builtin_syms.fold_stop)) {
            return grounded_string_error(
                a, head, args, nargs,
                "_minimal-foldl-until-atom expects FoldContinue/FoldStop accumulator state");
        }
        Atom *control = init->expr.elems[0];
        init = init->expr.elems[1];
        if (control->sym_id == g_builtin_syms.fold_stop)
            return atom_expr2(a, atom_symbol(a, "return"), init);
    }

    Atom *head_item;
    Atom *tail;
    if (list->expr.len == 0)
        return atom_expr2(a, atom_symbol(a, "return"), init);
    head_item = list->expr.elems[0];
    tail = atom_expr(a, list->expr.elems + 1, list->expr.len - 1);

    Atom *step_op = cetta_fold_bind_step_atom(a, op_expr,
                                              acc_var->sym_id, init,
                                              item_var->sym_id, head_item);


    char tmp_name[256];
    snprintf(tmp_name, sizeof(tmp_name), "$__foldl_step#%u", fresh_var_suffix());
    Atom *tmp = atom_var(a, tmp_name);

    Atom *metta_args[4] = {
        atom_symbol(a, "metta"),
        step_op,
        atom_undefined_type(a),
        space
    };
    Atom *recur_args[7] = {
        head,
        tail,
        tmp,
        acc_var,
        item_var,
        op_expr,
        space
    };
    Atom *chain_args[4] = {
        atom_symbol(a, "chain"),
        atom_expr(a, metta_args, 4),
        tmp,
        atom_expr2(a, atom_symbol(a, "eval"), atom_expr(a, recur_args, 7))
    };
    return atom_expr(a, chain_args, 4);
}

static Atom *grounded_range_atom(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    int64_t start = 0;
    int64_t end = 0;

    if (nargs != 1 && nargs != 2)
        return grounded_incorrect_arity(a, head, args, nargs);

    if (nargs == 1) {
        if (args[0]->kind != ATOM_GROUNDED || args[0]->ground.gkind != GV_INT) {
            if (args[0]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 1,
                                             atom_symbol(a, "Number"), args[0]);
            return NULL;
        }
        end = args[0]->ground.ival;
    } else {
        if (args[0]->kind != ATOM_GROUNDED || args[0]->ground.gkind != GV_INT) {
            if (args[0]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 1,
                                             atom_symbol(a, "Number"), args[0]);
            return NULL;
        }
        if (args[1]->kind != ATOM_GROUNDED || args[1]->ground.gkind != GV_INT) {
            if (args[1]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 2,
                                             atom_symbol(a, "Number"), args[1]);
            return NULL;
        }
        start = args[0]->ground.ival;
        end = args[1]->ground.ival;
    }

    if (end <= start)
        return atom_expr(a, NULL, 0);

    CettaExprLen len = (CettaExprLen)(end - start);
    if (!cetta_expr_len_mul_fits_size(len, sizeof(Atom *))) {
        return atom_error(a, grounded_call_expr(a, head, args, nargs),
                          atom_symbol(a, "RangeTooLarge"));
    }

    Atom **elems = arena_alloc(a, sizeof(Atom *) * (size_t)len);
    for (CettaExprIndex i = 0; i < len; i++)
        elems[i] = atom_int(a, start + (int64_t)i);
    return atom_expr(a, elems, len);
}

static Atom *grounded_repeat_atom(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    if (nargs != 2)
        return grounded_incorrect_arity(a, head, args, nargs);

    if (args[0]->kind != ATOM_GROUNDED || args[0]->ground.gkind != GV_INT) {
        if (args[0]->kind == ATOM_GROUNDED)
            return grounded_bad_arg_type(a, head, args, nargs, 1,
                                         atom_symbol(a, "Number"), args[0]);
        return NULL;
    }

    int64_t count = args[0]->ground.ival;
    if (count <= 0)
        return atom_expr(a, NULL, 0);
    if (!cetta_expr_len_mul_fits_size((CettaExprLen)count, sizeof(Atom *))) {
        return atom_error(a, grounded_call_expr(a, head, args, nargs),
                          atom_symbol(a, "RepeatTooLarge"));
    }

    CettaExprLen len = (CettaExprLen)count;
    Atom **elems = arena_alloc(a, sizeof(Atom *) * (size_t)len);
    for (CettaExprIndex i = 0; i < len; i++)
        elems[i] = args[1];
    return atom_expr(a, elems, len);
}

static void galois_boolean_closure(
    CettaExprLen object_count,
    CettaExprLen attribute_count,
    const bool *incidence,
    const bool *query,
    bool *extent,
    bool *closure) {
    for (CettaExprIndex object = 0; object < object_count; object++)
        extent[object] = true;
    for (CettaExprIndex attribute = 0;
         attribute < attribute_count; attribute++) {
        if (!query[attribute])
            continue;
        for (CettaExprIndex object = 0; object < object_count; object++) {
            if (!incidence[attribute * object_count + object])
                extent[object] = false;
        }
    }
    for (CettaExprIndex attribute = 0;
         attribute < attribute_count; attribute++) {
        closure[attribute] = true;
        for (CettaExprIndex object = 0; object < object_count; object++) {
            if (extent[object] &&
                !incidence[attribute * object_count + object]) {
                closure[attribute] = false;
                break;
            }
        }
    }
}

static bool *galois_boolean_incidence(
    Arena *a,
    Atom *objects,
    Atom *columns) {
    CettaExprLen object_count = objects->expr.len;
    CettaExprLen attribute_count = columns->expr.len;
    bool *incidence = arena_alloc(
        a, sizeof(bool) * attribute_count * object_count);
    memset(incidence, 0,
           sizeof(bool) * attribute_count * object_count);
    for (CettaExprIndex attribute = 0;
         attribute < attribute_count; attribute++) {
        Atom *column = columns->expr.elems[attribute];
        for (CettaExprIndex object = 0; object < object_count; object++) {
            for (CettaExprIndex member = 0;
                 member < column->expr.len; member++) {
                if (atom_alpha_eq(objects->expr.elems[object],
                                  column->expr.elems[member])) {
                    incidence[attribute * object_count + object] = true;
                    break;
                }
            }
        }
    }
    return incidence;
}

static bool galois_boolean_subset(
    CettaExprLen attribute_count,
    const bool *left,
    const bool *right) {
    for (CettaExprIndex attribute = 0;
         attribute < attribute_count; attribute++) {
        if (left[attribute] && !right[attribute])
            return false;
    }
    return true;
}

static bool galois_boolean_equal(
    CettaExprLen attribute_count,
    const bool *left,
    const bool *right) {
    return memcmp(left, right, sizeof(bool) * attribute_count) == 0;
}

typedef struct {
    bool *antecedent;
    bool *closure;
    Atom *pair;
} GaloisBasisRecord;

/* Logical pseudo-closure for the canonical-basis NextClosure algorithm.
 * An implication P -> P'' fires only when P is a proper subset of the
 * current set.  This strictness is what leaves each pseudo-intent itself
 * closed while making every proper extension respect its implication. */
static void galois_boolean_pseudo_closure(
    CettaExprLen attribute_count,
    const GaloisBasisRecord *basis,
    CettaExprLen basis_count,
    const bool *seed,
    bool *result) {
    memcpy(result, seed, sizeof(bool) * attribute_count);
    bool changed;
    do {
        changed = false;
        for (CettaExprIndex implication = 0;
             implication < basis_count; implication++) {
            if (!galois_boolean_subset(
                    attribute_count,
                    basis[implication].antecedent,
                    result) ||
                galois_boolean_equal(
                    attribute_count,
                    basis[implication].antecedent,
                    result))
                continue;
            for (CettaExprIndex attribute = 0;
                 attribute < attribute_count; attribute++) {
                if (basis[implication].closure[attribute] &&
                    !result[attribute]) {
                    result[attribute] = true;
                    changed = true;
                }
            }
        }
    } while (changed);
}

static Atom *galois_attribute_set_atom(
    Arena *a,
    Atom *attributes,
    const bool *selected) {
    Atom **items = arena_alloc(
        a, sizeof(Atom *) * attributes->expr.len);
    CettaExprLen len = 0;
    for (CettaExprIndex attribute = 0;
         attribute < attributes->expr.len; attribute++) {
        if (selected[attribute])
            items[len++] = attributes->expr.elems[attribute];
    }
    return atom_expr(a, items, len);
}

static bool expression_set_subset(const Atom *left, const Atom *right) {
    for (CettaExprIndex i = 0; i < left->expr.len; i++) {
        bool found = false;
        for (CettaExprIndex j = 0; j < right->expr.len; j++) {
            if (atom_alpha_eq(left->expr.elems[i], right->expr.elems[j])) {
                found = true;
                break;
            }
        }
        if (!found)
            return false;
    }
    return true;
}

static bool expression_set_equal(const Atom *left, const Atom *right) {
    return expression_set_subset(left, right) &&
           expression_set_subset(right, left);
}

typedef enum {
    WM_FCA_GATE_EXACT_STATUS,
    WM_FCA_GATE_POSITIVE_OBSERVATIONS,
    WM_FCA_GATE_POSITIVE_SOURCES,
    WM_FCA_GATE_POSITIVE_GROUPS
} WmFcaNativeGateKind;

typedef struct {
    size_t positive_count;
    size_t negative_count;
    size_t unknown_count;
    Atom **positive_sources;
    size_t positive_source_count;
    size_t positive_source_capacity;
    Atom **positive_groups;
    size_t positive_group_count;
    size_t positive_group_capacity;
} WmFcaNativeCellEvidence;

static void wm_fca_native_evidence_free(
    WmFcaNativeCellEvidence *cells,
    size_t cell_count) {
    if (!cells)
        return;
    for (size_t cell = 0; cell < cell_count; cell++) {
        free(cells[cell].positive_sources);
        free(cells[cell].positive_groups);
    }
    free(cells);
}

static bool wm_fca_native_add_unique(
    Atom ***items,
    size_t *len,
    size_t *capacity,
    Atom *candidate) {
    for (size_t i = 0; i < *len; i++) {
        if (atom_alpha_eq((*items)[i], candidate))
            return true;
    }
    if (*len == *capacity) {
        size_t next = *capacity == 0 ? 2 : *capacity * 2;
        if (next < *capacity || next > SIZE_MAX / sizeof(Atom *))
            return false;
        *items = *capacity == 0
            ? cetta_malloc(sizeof(Atom *) * next)
            : cetta_realloc(*items, sizeof(Atom *) * next);
        *capacity = next;
    }
    (*items)[(*len)++] = candidate;
    return true;
}

static CettaExprIndex wm_fca_native_universe_index(
    Atom *universe,
    Atom *candidate) {
    for (CettaExprIndex i = 0; i < universe->expr.len; i++) {
        if (atom_alpha_eq(universe->expr.elems[i], candidate))
            return i;
    }
    return universe->expr.len;
}

static bool wm_fca_native_count_at_least(
    size_t count,
    const NumArg *threshold) {
    if (threshold->is_float)
        return (double)count >= threshold->val;
#if CETTA_BUILD_WITH_GMP
    if (threshold->is_bigint || threshold->is_rational) {
        mpq_t count_value, threshold_value;
        mpq_inits(count_value, threshold_value, NULL);
        mpq_set_ui(count_value, count, 1);
        bool converted = num_arg_to_mpq(threshold, threshold_value);
        bool result = converted && mpq_cmp(count_value, threshold_value) >= 0;
        mpq_clears(count_value, threshold_value, NULL);
        return result;
    }
#else
    if (threshold->is_bigint || threshold->is_rational)
        return (double)count >= threshold->val;
#endif
    if (threshold->ival < 0)
        return true;
    return count >= (uint64_t)threshold->ival;
}

static bool wm_fca_native_gate_accepts(
    const WmFcaNativeCellEvidence *evidence,
    WmFcaNativeGateKind gate_kind,
    const NumArg *threshold) {
    switch (gate_kind) {
    case WM_FCA_GATE_EXACT_STATUS:
        return evidence->positive_count > 0 &&
               evidence->negative_count == 0 &&
               evidence->unknown_count == 0;
    case WM_FCA_GATE_POSITIVE_OBSERVATIONS:
        return wm_fca_native_count_at_least(
            evidence->positive_count, threshold);
    case WM_FCA_GATE_POSITIVE_SOURCES:
        return wm_fca_native_count_at_least(
            evidence->positive_source_count, threshold);
    case WM_FCA_GATE_POSITIVE_GROUPS:
        return wm_fca_native_count_at_least(
            evidence->positive_group_count, threshold);
    }
    return false;
}

static bool wm_fca_native_parse_gate(
    Arena *a,
    Atom *call,
    Atom *gate,
    WmFcaNativeGateKind *gate_kind,
    NumArg *threshold,
    Atom **error_out) {
    *gate_kind = WM_FCA_GATE_EXACT_STATUS;
    memset(threshold, 0, sizeof(*threshold));
    *error_out = NULL;
    if (atom_is_symbol(gate, "WMFCAExactStatusGate"))
        return true;
    if (gate->kind != ATOM_EXPR || gate->expr.len != 2 ||
        gate->expr.elems[0]->kind != ATOM_SYMBOL) {
        *error_out = atom_error(
            a, call, atom_symbol(a, "UnsupportedWMFCAExtractionGate"));
        return false;
    }

    Atom *gate_head = gate->expr.elems[0];
    if (atom_is_symbol(gate_head, "WMFCAPositiveObservationThreshold")) {
        *gate_kind = WM_FCA_GATE_POSITIVE_OBSERVATIONS;
    } else if (atom_is_symbol(gate_head, "WMFCAPositiveSourceThreshold")) {
        *gate_kind = WM_FCA_GATE_POSITIVE_SOURCES;
    } else if (atom_is_symbol(
                   gate_head,
                   "WMFCAPositiveDependenceGroupThreshold")) {
        *gate_kind = WM_FCA_GATE_POSITIVE_GROUPS;
    } else {
        *error_out = atom_error(
            a, call, atom_symbol(a, "UnsupportedWMFCAExtractionGate"));
        return false;
    }
    if (!get_numeric_arg(gate->expr.elems[1], threshold)) {
        *error_out = atom_error(
            a, call, atom_symbol(a, "NumericWMFCAThresholdExpected"));
        return false;
    }
    return true;
}

static bool wm_fca_native_validate_binary_rows(
    Arena *a,
    Atom *call,
    Atom *objects,
    Atom *attributes,
    Atom *rows,
    Atom **error_out) {
    *error_out = NULL;
    if (rows->expr.len != objects->expr.len) {
        *error_out = atom_error(
            a, call, atom_symbol(a, "WMFCABinaryRowCountMismatch"));
        return false;
    }
    for (CettaExprIndex i = 0; i < rows->expr.len; i++) {
        Atom *row = rows->expr.elems[i];
        if (row->kind != ATOM_EXPR || row->expr.len != 3 ||
            !atom_is_symbol(row->expr.elems[0], "WMFCABinaryRow") ||
            row->expr.elems[2]->kind != ATOM_GROUNDED ||
            row->expr.elems[2]->ground.gkind != GV_STRING) {
            *error_out = atom_error(
                a, call, atom_symbol(a, "MalformedWMFCABinaryRow"));
            return false;
        }
        if (!atom_alpha_eq(row->expr.elems[1], objects->expr.elems[i])) {
            *error_out = atom_error(
                a, call, atom_symbol(a, "WMFCABinaryRowObjectMismatch"));
            return false;
        }
        const char *bits = row->expr.elems[2]->ground.sval;
        if (strlen(bits) != (size_t)attributes->expr.len) {
            *error_out = atom_error(
                a, call, atom_symbol(a, "WMFCABinaryRowWidthMismatch"));
            return false;
        }
        for (CettaExprIndex attribute = 0;
             attribute < attributes->expr.len; attribute++) {
            if (bits[attribute] != '0' && bits[attribute] != '1') {
                *error_out = atom_error(
                    a, call, atom_symbol(a, "InvalidWMFCABinaryCell"));
                return false;
            }
        }
    }
    return true;
}

static bool *wm_fca_native_binary_incidence(
    Arena *a,
    Atom *objects,
    Atom *attributes,
    Atom *rows,
    bool same_context,
    WmFcaNativeGateKind gate_kind,
    const NumArg *threshold) {
    size_t object_count = objects->expr.len;
    size_t attribute_count = attributes->expr.len;
    size_t cell_count = object_count * attribute_count;
    bool *incidence = arena_alloc(
        a, sizeof(bool) * (cell_count == 0 ? 1 : cell_count));
    for (CettaExprIndex attribute = 0;
         attribute < attributes->expr.len; attribute++) {
        for (CettaExprIndex object = 0;
             object < objects->expr.len; object++) {
            WmFcaNativeCellEvidence evidence = {0};
            if (same_context) {
                const char *bits =
                    rows->expr.elems[object]->expr.elems[2]->ground.sval;
                if (bits[attribute] == '1') {
                    evidence.positive_count = 1;
                    evidence.positive_source_count = 1;
                    evidence.positive_group_count = 1;
                } else {
                    evidence.negative_count = 1;
                }
            }
            incidence[(size_t)attribute * object_count + object] =
                wm_fca_native_gate_accepts(
                    &evidence, gate_kind, threshold);
        }
    }
    return incidence;
}

typedef struct {
    bool *base_active;
    size_t base_cell_count;
    Atom **additions;
    size_t addition_count;
    size_t addition_capacity;
} WmFcaNativeEventSnapshot;

static void wm_fca_native_event_snapshot_free(
    WmFcaNativeEventSnapshot *snapshot) {
    if (!snapshot)
        return;
    free(snapshot->base_active);
    free(snapshot->additions);
    memset(snapshot, 0, sizeof(*snapshot));
}

static bool wm_fca_native_observation_valid(Atom *observation) {
    if (observation->kind != ATOM_EXPR || observation->expr.len != 8 ||
        !atom_is_symbol(
            observation->expr.elems[0], "WMFCAObservation"))
        return false;
    Atom *status = observation->expr.elems[4];
    return atom_is_symbol(status, "WMTrue") ||
           atom_is_symbol(status, "WMFalse") ||
           atom_is_symbol(status, "WMUnknown");
}

static bool wm_fca_native_packed_stamp_equal(
    Atom *stamp,
    Atom *context,
    Atom *object,
    Atom *attribute) {
    return stamp->kind == ATOM_EXPR && stamp->expr.len == 4 &&
           atom_is_symbol(stamp->expr.elems[0], "WMFCAPackedStamp") &&
           atom_alpha_eq(stamp->expr.elems[1], context) &&
           atom_alpha_eq(stamp->expr.elems[2], object) &&
           atom_alpha_eq(stamp->expr.elems[3], attribute);
}

static bool wm_fca_native_base_observation_equal(
    Atom *objects,
    Atom *attributes,
    Atom *rows,
    Atom *base_context,
    Atom *base_source,
    Atom *base_group,
    CettaExprIndex object,
    CettaExprIndex attribute,
    Atom *observation) {
    if (!wm_fca_native_observation_valid(observation))
        return false;
    const char *bits =
        rows->expr.elems[object]->expr.elems[2]->ground.sval;
    const char *status = bits[attribute] == '1' ? "WMTrue" : "WMFalse";
    return atom_alpha_eq(observation->expr.elems[1], base_context) &&
           atom_alpha_eq(
               observation->expr.elems[2], objects->expr.elems[object]) &&
           atom_alpha_eq(
               observation->expr.elems[3], attributes->expr.elems[attribute]) &&
           atom_is_symbol(observation->expr.elems[4], status) &&
           wm_fca_native_packed_stamp_equal(
               observation->expr.elems[5], base_context,
               objects->expr.elems[object],
               attributes->expr.elems[attribute]) &&
           atom_alpha_eq(observation->expr.elems[6], base_source) &&
           atom_alpha_eq(observation->expr.elems[7], base_group);
}

static Atom *wm_fca_native_base_observation(
    Arena *a,
    Atom *objects,
    Atom *attributes,
    Atom *rows,
    Atom *base_context,
    Atom *base_source,
    Atom *base_group,
    CettaExprIndex object,
    CettaExprIndex attribute) {
    Atom *object_atom = objects->expr.elems[object];
    Atom *attribute_atom = attributes->expr.elems[attribute];
    Atom *stamp_items[4] = {
        atom_symbol(a, "WMFCAPackedStamp"),
        base_context,
        object_atom,
        attribute_atom,
    };
    Atom *stamp = atom_expr(a, stamp_items, 4);
    const char *bits =
        rows->expr.elems[object]->expr.elems[2]->ground.sval;
    Atom *observation_items[8] = {
        atom_symbol(a, "WMFCAObservation"),
        base_context,
        object_atom,
        attribute_atom,
        atom_symbol(a, bits[attribute] == '1' ? "WMTrue" : "WMFalse"),
        stamp,
        base_source,
        base_group,
    };
    return atom_expr(a, observation_items, 8);
}

static bool wm_fca_native_scope_valid(Atom *scope) {
    if (scope->kind != ATOM_EXPR || scope->expr.len < 2 ||
        scope->expr.elems[0]->kind != ATOM_SYMBOL)
        return false;
    Atom *head = scope->expr.elems[0];
    if (atom_is_symbol(head, "WMFCAScopeCell"))
        return scope->expr.len == 4;
    return scope->expr.len == 2 &&
           (atom_is_symbol(head, "WMFCAScopeStamp") ||
            atom_is_symbol(head, "WMFCAScopeSource") ||
            atom_is_symbol(head, "WMFCAScopeDependenceGroup") ||
            atom_is_symbol(head, "WMFCAScopeContext"));
}

static bool wm_fca_native_scope_matches_observation(
    Atom *scope,
    Atom *observation) {
    Atom *head = scope->expr.elems[0];
    if (atom_is_symbol(head, "WMFCAScopeStamp"))
        return atom_alpha_eq(
            scope->expr.elems[1], observation->expr.elems[5]);
    if (atom_is_symbol(head, "WMFCAScopeSource"))
        return atom_alpha_eq(
            scope->expr.elems[1], observation->expr.elems[6]);
    if (atom_is_symbol(head, "WMFCAScopeDependenceGroup"))
        return atom_alpha_eq(
            scope->expr.elems[1], observation->expr.elems[7]);
    if (atom_is_symbol(head, "WMFCAScopeContext"))
        return atom_alpha_eq(
            scope->expr.elems[1], observation->expr.elems[1]);
    return atom_alpha_eq(scope->expr.elems[1], observation->expr.elems[1]) &&
           atom_alpha_eq(scope->expr.elems[2], observation->expr.elems[2]) &&
           atom_alpha_eq(scope->expr.elems[3], observation->expr.elems[3]);
}

static bool wm_fca_native_scope_matches_base(
    Atom *scope,
    Atom *objects,
    Atom *attributes,
    Atom *base_context,
    Atom *base_source,
    Atom *base_group,
    CettaExprIndex object,
    CettaExprIndex attribute) {
    Atom *head = scope->expr.elems[0];
    if (atom_is_symbol(head, "WMFCAScopeStamp"))
        return wm_fca_native_packed_stamp_equal(
            scope->expr.elems[1], base_context,
            objects->expr.elems[object],
            attributes->expr.elems[attribute]);
    if (atom_is_symbol(head, "WMFCAScopeSource"))
        return atom_alpha_eq(scope->expr.elems[1], base_source);
    if (atom_is_symbol(head, "WMFCAScopeDependenceGroup"))
        return atom_alpha_eq(scope->expr.elems[1], base_group);
    if (atom_is_symbol(head, "WMFCAScopeContext"))
        return atom_alpha_eq(scope->expr.elems[1], base_context);
    return atom_alpha_eq(scope->expr.elems[1], base_context) &&
           atom_alpha_eq(
               scope->expr.elems[2], objects->expr.elems[object]) &&
           atom_alpha_eq(
               scope->expr.elems[3], attributes->expr.elems[attribute]);
}

static bool wm_fca_native_event_remember(
    Atom *objects,
    Atom *attributes,
    Atom *rows,
    Atom *base_context,
    Atom *base_source,
    Atom *base_group,
    WmFcaNativeEventSnapshot *snapshot,
    Atom *observation) {
    if (!wm_fca_native_observation_valid(observation))
        return false;
    CettaExprIndex object = wm_fca_native_universe_index(
        objects, observation->expr.elems[2]);
    CettaExprIndex attribute = wm_fca_native_universe_index(
        attributes, observation->expr.elems[3]);
    if (object < objects->expr.len && attribute < attributes->expr.len &&
        snapshot->base_active[
            (size_t)attribute * objects->expr.len + object] &&
        wm_fca_native_base_observation_equal(
            objects, attributes, rows, base_context, base_source, base_group,
            object, attribute, observation))
        return true;
    return wm_fca_native_add_unique(
        &snapshot->additions,
        &snapshot->addition_count,
        &snapshot->addition_capacity,
        observation);
}

static bool wm_fca_native_event_forget(
    Atom *objects,
    Atom *attributes,
    Atom *base_context,
    Atom *base_source,
    Atom *base_group,
    WmFcaNativeEventSnapshot *snapshot,
    Atom *scope) {
    if (!wm_fca_native_scope_valid(scope))
        return false;
    for (CettaExprIndex attribute = 0;
         attribute < attributes->expr.len; attribute++) {
        for (CettaExprIndex object = 0;
             object < objects->expr.len; object++) {
            size_t cell =
                (size_t)attribute * objects->expr.len + object;
            if (snapshot->base_active[cell] &&
                wm_fca_native_scope_matches_base(
                    scope, objects, attributes, base_context,
                    base_source, base_group, object, attribute))
                snapshot->base_active[cell] = false;
        }
    }
    size_t kept = 0;
    for (size_t i = 0; i < snapshot->addition_count; i++) {
        Atom *observation = snapshot->additions[i];
        if (!wm_fca_native_scope_matches_observation(scope, observation))
            snapshot->additions[kept++] = observation;
    }
    snapshot->addition_count = kept;
    return true;
}

static bool wm_fca_native_replay_binary_events(
    Arena *a,
    Atom *call,
    Atom *objects,
    Atom *attributes,
    Atom *rows,
    Atom *base_context,
    Atom *base_source,
    Atom *base_group,
    Atom *events,
    WmFcaNativeEventSnapshot *snapshot,
    Atom **error_out) {
    memset(snapshot, 0, sizeof(*snapshot));
    *error_out = NULL;
    size_t object_count = objects->expr.len;
    size_t attribute_count = attributes->expr.len;
    if (attribute_count != 0 && object_count > SIZE_MAX / attribute_count) {
        *error_out = atom_error(
            a, call, atom_symbol(a, "WMFCAIndexDimensionsTooLarge"));
        return false;
    }
    snapshot->base_cell_count = object_count * attribute_count;
    size_t active_count = snapshot->base_cell_count == 0
        ? 1 : snapshot->base_cell_count;
    if (active_count > SIZE_MAX / sizeof(bool)) {
        *error_out = atom_error(
            a, call, atom_symbol(a, "WMFCAIndexDimensionsTooLarge"));
        return false;
    }
    snapshot->base_active = cetta_malloc(sizeof(bool) * active_count);
    memset(snapshot->base_active, 1, sizeof(bool) * snapshot->base_cell_count);

    for (CettaExprIndex reverse = events->expr.len;
         reverse > 0; reverse--) {
        Atom *event = events->expr.elems[reverse - 1];
        if (event->kind != ATOM_EXPR || event->expr.len != 2 ||
            event->expr.elems[0]->kind != ATOM_SYMBOL) {
            *error_out = atom_error(
                a, call, atom_symbol(a, "MalformedWMFCAEvent"));
            wm_fca_native_event_snapshot_free(snapshot);
            return false;
        }
        Atom *event_head = event->expr.elems[0];
        if (atom_is_symbol(event_head, "WMFCAForgetEvent")) {
            if (!wm_fca_native_event_forget(
                    objects, attributes, base_context, base_source, base_group,
                    snapshot, event->expr.elems[1])) {
                *error_out = atom_error(
                    a, call, atom_symbol(a, "MalformedWMFCAScope"));
                wm_fca_native_event_snapshot_free(snapshot);
                return false;
            }
            continue;
        }
        if (atom_is_symbol(event_head, "WMFCARememberEvent")) {
            if (!wm_fca_native_event_remember(
                    objects, attributes, rows, base_context,
                    base_source, base_group, snapshot,
                    event->expr.elems[1])) {
                *error_out = atom_error(
                    a, call, atom_symbol(a, "MalformedWMFCAObservation"));
                wm_fca_native_event_snapshot_free(snapshot);
                return false;
            }
            continue;
        }
        if (atom_is_symbol(event_head, "WMFCAReviseEvent") &&
            event->expr.elems[1]->kind == ATOM_EXPR) {
            Atom *observations = event->expr.elems[1];
            for (CettaExprIndex i = 0; i < observations->expr.len; i++) {
                if (!wm_fca_native_event_remember(
                        objects, attributes, rows, base_context,
                        base_source, base_group, snapshot,
                        observations->expr.elems[i])) {
                    *error_out = atom_error(
                        a, call,
                        atom_symbol(a, "MalformedWMFCAObservation"));
                    wm_fca_native_event_snapshot_free(snapshot);
                    return false;
                }
            }
            continue;
        }
        *error_out = atom_error(
            a, call, atom_symbol(a, "MalformedWMFCAEvent"));
        wm_fca_native_event_snapshot_free(snapshot);
        return false;
    }
    return true;
}

static WmFcaNativeCellEvidence *wm_fca_native_event_evidence(
    Arena *a,
    Atom *call,
    Atom *objects,
    Atom *attributes,
    Atom *rows,
    Atom *base_context,
    Atom *base_source,
    Atom *base_group,
    Atom *query_context,
    const WmFcaNativeEventSnapshot *snapshot,
    Atom **error_out) {
    *error_out = NULL;
    size_t object_count = objects->expr.len;
    size_t cell_count = snapshot->base_cell_count;
    if (cell_count > SIZE_MAX / sizeof(WmFcaNativeCellEvidence)) {
        *error_out = atom_error(
            a, call, atom_symbol(a, "WMFCAIndexDimensionsTooLarge"));
        return NULL;
    }
    WmFcaNativeCellEvidence *cells = cell_count == 0
        ? NULL
        : cetta_malloc(sizeof(WmFcaNativeCellEvidence) * cell_count);
    if (cells)
        memset(cells, 0, sizeof(WmFcaNativeCellEvidence) * cell_count);

    if (atom_alpha_eq(base_context, query_context)) {
        for (CettaExprIndex attribute = 0;
             attribute < attributes->expr.len; attribute++) {
            for (CettaExprIndex object = 0;
                 object < objects->expr.len; object++) {
                size_t cell = (size_t)attribute * object_count + object;
                if (!snapshot->base_active[cell])
                    continue;
                const char *bits =
                    rows->expr.elems[object]->expr.elems[2]->ground.sval;
                WmFcaNativeCellEvidence *evidence = &cells[cell];
                if (bits[attribute] == '1') {
                    evidence->positive_count = 1;
                    if (!wm_fca_native_add_unique(
                            &evidence->positive_sources,
                            &evidence->positive_source_count,
                            &evidence->positive_source_capacity,
                            base_source) ||
                        !wm_fca_native_add_unique(
                            &evidence->positive_groups,
                            &evidence->positive_group_count,
                            &evidence->positive_group_capacity,
                            base_group)) {
                        wm_fca_native_evidence_free(cells, cell_count);
                        *error_out = atom_error(
                            a, call,
                            atom_symbol(a, "WMFCAEvidenceIndexTooLarge"));
                        return NULL;
                    }
                } else {
                    evidence->negative_count = 1;
                }
            }
        }
    }

    for (size_t i = 0; i < snapshot->addition_count; i++) {
        Atom *observation = snapshot->additions[i];
        if (!atom_alpha_eq(observation->expr.elems[1], query_context))
            continue;
        CettaExprIndex object = wm_fca_native_universe_index(
            objects, observation->expr.elems[2]);
        CettaExprIndex attribute = wm_fca_native_universe_index(
            attributes, observation->expr.elems[3]);
        if (object == objects->expr.len || attribute == attributes->expr.len)
            continue;
        WmFcaNativeCellEvidence *evidence =
            &cells[(size_t)attribute * object_count + object];
        Atom *status = observation->expr.elems[4];
        if (atom_is_symbol(status, "WMTrue")) {
            if (evidence->positive_count == SIZE_MAX) {
                wm_fca_native_evidence_free(cells, cell_count);
                *error_out = atom_error(
                    a, call,
                    atom_symbol(a, "WMFCAEvidenceIndexTooLarge"));
                return NULL;
            }
            evidence->positive_count++;
            if (!wm_fca_native_add_unique(
                    &evidence->positive_sources,
                    &evidence->positive_source_count,
                    &evidence->positive_source_capacity,
                    observation->expr.elems[6]) ||
                !wm_fca_native_add_unique(
                    &evidence->positive_groups,
                    &evidence->positive_group_count,
                    &evidence->positive_group_capacity,
                    observation->expr.elems[7])) {
                wm_fca_native_evidence_free(cells, cell_count);
                *error_out = atom_error(
                    a, call, atom_symbol(a, "WMFCAEvidenceIndexTooLarge"));
                return NULL;
            }
        } else if (atom_is_symbol(status, "WMFalse")) {
            if (evidence->negative_count == SIZE_MAX) {
                wm_fca_native_evidence_free(cells, cell_count);
                *error_out = atom_error(
                    a, call,
                    atom_symbol(a, "WMFCAEvidenceIndexTooLarge"));
                return NULL;
            }
            evidence->negative_count++;
        } else {
            if (evidence->unknown_count == SIZE_MAX) {
                wm_fca_native_evidence_free(cells, cell_count);
                *error_out = atom_error(
                    a, call,
                    atom_symbol(a, "WMFCAEvidenceIndexTooLarge"));
                return NULL;
            }
            evidence->unknown_count++;
        }
    }
    return cells;
}

static bool *wm_fca_native_event_incidence(
    Arena *a,
    Atom *call,
    Atom *objects,
    Atom *attributes,
    Atom *rows,
    Atom *base_context,
    Atom *base_source,
    Atom *base_group,
    Atom *query_context,
    const WmFcaNativeEventSnapshot *snapshot,
    WmFcaNativeGateKind gate_kind,
    const NumArg *threshold,
    Atom **error_out) {
    WmFcaNativeCellEvidence *cells = wm_fca_native_event_evidence(
        a, call, objects, attributes, rows, base_context,
        base_source, base_group, query_context, snapshot, error_out);
    if (*error_out)
        return NULL;
    size_t object_count = objects->expr.len;
    size_t cell_count = snapshot->base_cell_count;
    bool *incidence = arena_alloc(
        a, sizeof(bool) * (cell_count == 0 ? 1 : cell_count));
    for (CettaExprIndex attribute = 0;
         attribute < attributes->expr.len; attribute++) {
        for (CettaExprIndex object = 0;
             object < objects->expr.len; object++) {
            size_t cell = (size_t)attribute * object_count + object;
            incidence[cell] = wm_fca_native_gate_accepts(
                &cells[cell], gate_kind, threshold);
        }
    }
    wm_fca_native_evidence_free(cells, cell_count);
    return incidence;
}

/* Packed four-valued evidence layers.  A layer identity names one provenance
 * chunk: repeating an alpha-identical layer is idempotent, while reusing the
 * identity for different content is an explicit error. */
static bool wm_fca_native_validate_evidence_layers(
    Arena *a,
    Atom *call,
    Atom *objects,
    Atom *attributes,
    Atom *layers,
    Atom **error_out) {
    *error_out = NULL;
    for (CettaExprIndex layer_index = 0;
         layer_index < layers->expr.len; layer_index++) {
        Atom *layer = layers->expr.elems[layer_index];
        if (layer->kind != ATOM_EXPR || layer->expr.len != 6 ||
            !atom_is_symbol(layer->expr.elems[0], "WMFCAEvidenceLayer") ||
            layer->expr.elems[5]->kind != ATOM_EXPR) {
            *error_out = atom_error(
                a, call, atom_symbol(a, "MalformedWMFCAEvidenceLayer"));
            return false;
        }
        bool duplicate = false;
        for (CettaExprIndex prior = 0; prior < layer_index; prior++) {
            Atom *prior_layer = layers->expr.elems[prior];
            if (prior_layer->kind != ATOM_EXPR || prior_layer->expr.len != 6)
                continue;
            if (!atom_alpha_eq(
                    prior_layer->expr.elems[1], layer->expr.elems[1]))
                continue;
            if (!atom_alpha_eq(prior_layer, layer)) {
                *error_out = atom_error(
                    a, call,
                    atom_symbol(a,
                                "WMFCAConflictingEvidenceLayerIdentity"));
                return false;
            }
            duplicate = true;
            break;
        }
        if (duplicate)
            continue;
        Atom *rows = layer->expr.elems[5];
        if (rows->expr.len != objects->expr.len) {
            *error_out = atom_error(
                a, call,
                atom_symbol(a, "WMFCAEvidenceLayerRowCountMismatch"));
            return false;
        }
        for (CettaExprIndex object = 0;
             object < rows->expr.len; object++) {
            Atom *row = rows->expr.elems[object];
            if (row->kind != ATOM_EXPR || row->expr.len != 3 ||
                !atom_is_symbol(row->expr.elems[0], "WMFCAStatusRow") ||
                row->expr.elems[2]->kind != ATOM_GROUNDED ||
                row->expr.elems[2]->ground.gkind != GV_STRING) {
                *error_out = atom_error(
                    a, call, atom_symbol(a, "MalformedWMFCAStatusRow"));
                return false;
            }
            if (!atom_alpha_eq(
                    row->expr.elems[1], objects->expr.elems[object])) {
                *error_out = atom_error(
                    a, call,
                    atom_symbol(a, "WMFCAStatusRowObjectMismatch"));
                return false;
            }
            const char *statuses = row->expr.elems[2]->ground.sval;
            if (strlen(statuses) != (size_t)attributes->expr.len) {
                *error_out = atom_error(
                    a, call,
                    atom_symbol(a, "WMFCAStatusRowWidthMismatch"));
                return false;
            }
            for (CettaExprIndex attribute = 0;
                 attribute < attributes->expr.len; attribute++) {
                char status = statuses[attribute];
                if (status != '1' && status != '0' &&
                    status != 'u' && status != '.') {
                    *error_out = atom_error(
                        a, call,
                        atom_symbol(a, "InvalidWMFCAStatusCell"));
                    return false;
                }
            }
        }
    }
    return true;
}

static bool wm_fca_native_evidence_layer_is_duplicate(
    Atom *layers,
    CettaExprIndex layer_index) {
    Atom *layer = layers->expr.elems[layer_index];
    for (CettaExprIndex prior = 0; prior < layer_index; prior++) {
        Atom *prior_layer = layers->expr.elems[prior];
        if (atom_alpha_eq(
                prior_layer->expr.elems[1], layer->expr.elems[1]))
            return true;
    }
    return false;
}

static const char *wm_fca_native_status_symbol(char status) {
    switch (status) {
    case '1': return "WMTrue";
    case '0': return "WMFalse";
    case 'u': return "WMUnknown";
    case '.': return NULL;
    }
    return NULL;
}

static Atom *wm_fca_native_evidence_layer_observation(
    Arena *a,
    Atom *objects,
    Atom *attributes,
    Atom *layer,
    CettaExprIndex object,
    CettaExprIndex attribute) {
    Atom *object_atom = objects->expr.elems[object];
    Atom *attribute_atom = attributes->expr.elems[attribute];
    Atom *stamp_items[4] = {
        atom_symbol(a, "WMFCALayerStamp"),
        layer->expr.elems[1],
        object_atom,
        attribute_atom,
    };
    Atom *stamp = atom_expr(a, stamp_items, 4);
    const char *statuses =
        layer->expr.elems[5]->expr.elems[object]->expr.elems[2]->ground.sval;
    Atom *observation_items[8] = {
        atom_symbol(a, "WMFCAObservation"),
        layer->expr.elems[2],
        object_atom,
        attribute_atom,
        atom_symbol(a, wm_fca_native_status_symbol(statuses[attribute])),
        stamp,
        layer->expr.elems[3],
        layer->expr.elems[4],
    };
    return atom_expr(a, observation_items, 8);
}

static WmFcaNativeCellEvidence *wm_fca_native_evidence_layer_evidence(
    Arena *a,
    Atom *call,
    Atom *objects,
    Atom *attributes,
    Atom *layers,
    Atom *query_context,
    Atom **error_out) {
    *error_out = NULL;
    size_t object_count = objects->expr.len;
    size_t attribute_count = attributes->expr.len;
    if (attribute_count != 0 && object_count > SIZE_MAX / attribute_count) {
        *error_out = atom_error(
            a, call, atom_symbol(a, "WMFCAIndexDimensionsTooLarge"));
        return NULL;
    }
    size_t cell_count = object_count * attribute_count;
    if (cell_count > SIZE_MAX / sizeof(WmFcaNativeCellEvidence)) {
        *error_out = atom_error(
            a, call, atom_symbol(a, "WMFCAIndexDimensionsTooLarge"));
        return NULL;
    }
    WmFcaNativeCellEvidence *cells = cell_count == 0
        ? NULL
        : cetta_malloc(sizeof(WmFcaNativeCellEvidence) * cell_count);
    if (cells)
        memset(cells, 0, sizeof(WmFcaNativeCellEvidence) * cell_count);

    for (CettaExprIndex layer_index = 0;
         layer_index < layers->expr.len; layer_index++) {
        if (wm_fca_native_evidence_layer_is_duplicate(layers, layer_index))
            continue;
        Atom *layer = layers->expr.elems[layer_index];
        if (!atom_alpha_eq(layer->expr.elems[2], query_context))
            continue;
        Atom *rows = layer->expr.elems[5];
        for (CettaExprIndex object = 0;
             object < objects->expr.len; object++) {
            const char *statuses =
                rows->expr.elems[object]->expr.elems[2]->ground.sval;
            for (CettaExprIndex attribute = 0;
                 attribute < attributes->expr.len; attribute++) {
                char status = statuses[attribute];
                if (status == '.')
                    continue;
                WmFcaNativeCellEvidence *evidence =
                    &cells[(size_t)attribute * object_count + object];
                size_t *count = status == '1'
                    ? &evidence->positive_count
                    : status == '0'
                        ? &evidence->negative_count
                        : &evidence->unknown_count;
                if (*count == SIZE_MAX) {
                    wm_fca_native_evidence_free(cells, cell_count);
                    *error_out = atom_error(
                        a, call,
                        atom_symbol(a, "WMFCAEvidenceIndexTooLarge"));
                    return NULL;
                }
                (*count)++;
                if (status == '1' &&
                    (!wm_fca_native_add_unique(
                         &evidence->positive_sources,
                         &evidence->positive_source_count,
                         &evidence->positive_source_capacity,
                         layer->expr.elems[3]) ||
                     !wm_fca_native_add_unique(
                         &evidence->positive_groups,
                         &evidence->positive_group_count,
                         &evidence->positive_group_capacity,
                         layer->expr.elems[4]))) {
                    wm_fca_native_evidence_free(cells, cell_count);
                    *error_out = atom_error(
                        a, call,
                        atom_symbol(a, "WMFCAEvidenceIndexTooLarge"));
                    return NULL;
                }
            }
        }
    }
    return cells;
}

static bool *wm_fca_native_evidence_layer_incidence(
    Arena *a,
    Atom *call,
    Atom *objects,
    Atom *attributes,
    Atom *layers,
    Atom *query_context,
    WmFcaNativeGateKind gate_kind,
    const NumArg *threshold,
    Atom **error_out) {
    WmFcaNativeCellEvidence *cells =
        wm_fca_native_evidence_layer_evidence(
            a, call, objects, attributes, layers, query_context, error_out);
    if (*error_out)
        return NULL;
    size_t object_count = objects->expr.len;
    size_t cell_count = object_count * attributes->expr.len;
    bool *incidence = arena_alloc(
        a, sizeof(bool) * (cell_count == 0 ? 1 : cell_count));
    for (CettaExprIndex attribute = 0;
         attribute < attributes->expr.len; attribute++) {
        for (CettaExprIndex object = 0;
             object < objects->expr.len; object++) {
            size_t cell = (size_t)attribute * object_count + object;
            incidence[cell] = wm_fca_native_gate_accepts(
                &cells[cell], gate_kind, threshold);
        }
    }
    wm_fca_native_evidence_free(cells, cell_count);
    return incidence;
}

static Atom *wm_fca_native_columns_from_incidence(
    Arena *a,
    Atom *objects,
    Atom *attributes,
    const bool *incidence) {
    size_t object_count = objects->expr.len;
    Atom **columns = arena_alloc(a, sizeof(Atom *) * attributes->expr.len);
    for (CettaExprIndex attribute = 0;
         attribute < attributes->expr.len; attribute++) {
        Atom **members = arena_alloc(a, sizeof(Atom *) * object_count);
        CettaExprLen member_count = 0;
        for (CettaExprIndex object = 0;
             object < objects->expr.len; object++) {
            if (incidence[(size_t)attribute * object_count + object])
                members[member_count++] = objects->expr.elems[object];
        }
        columns[attribute] = atom_expr3(
            a, atom_symbol(a, "WMFCAColumn"),
            attributes->expr.elems[attribute],
            atom_expr(a, members, member_count));
    }
    return atom_expr(a, columns, attributes->expr.len);
}

static Atom *wm_fca_native_batch_from_incidence(
    Arena *a,
    Atom *call,
    Atom *objects,
    Atom *attributes,
    const bool *incidence,
    Atom *queries) {
    size_t object_count = objects->expr.len;
    size_t attribute_count = attributes->expr.len;
    Atom **results = arena_alloc(a, sizeof(Atom *) * queries->expr.len);
    for (CettaExprIndex query_index = 0;
         query_index < queries->expr.len; query_index++) {
        Atom *query = queries->expr.elems[query_index];
        if (query->kind != ATOM_EXPR)
            return atom_error(
                a, call, atom_symbol(a, "MalformedWMFCABatchQuery"));
        bool *selected = arena_alloc(
            a, sizeof(bool) * (attribute_count == 0 ? 1 : attribute_count));
        memset(selected, 0, sizeof(bool) * attribute_count);
        for (CettaExprIndex item = 0; item < query->expr.len; item++) {
            CettaExprIndex attribute = wm_fca_native_universe_index(
                attributes, query->expr.elems[item]);
            if (attribute < attributes->expr.len)
                selected[attribute] = true;
        }
        bool *extent = arena_alloc(
            a, sizeof(bool) * (object_count == 0 ? 1 : object_count));
        bool *closure = arena_alloc(
            a, sizeof(bool) * (attribute_count == 0 ? 1 : attribute_count));
        galois_boolean_closure(
            objects->expr.len, attributes->expr.len,
            incidence, selected, extent, closure);
        Atom **extent_items = arena_alloc(a, sizeof(Atom *) * object_count);
        CettaExprLen extent_len = 0;
        for (CettaExprIndex object = 0;
             object < objects->expr.len; object++) {
            if (extent[object])
                extent_items[extent_len++] = objects->expr.elems[object];
        }
        Atom *result_items[4] = {
            atom_symbol(a, "WMFCABatchQueryResult"),
            query,
            atom_expr(a, extent_items, extent_len),
            galois_attribute_set_atom(a, attributes, closure),
        };
        results[query_index] = atom_expr(a, result_items, 4);
    }
    return atom_expr(a, results, queries->expr.len);
}

/* ── Dispatch ──────────────────────────────────────────────────────────── */

Atom *grounded_dispatch(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;

    if (head_id == g_builtin_syms.println_bang) {
        if (nargs != 1)
            return grounded_incorrect_arity(a, head, args, nargs);
        if (args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_STRING)
            fputs(args[0]->ground.sval, stdout);
        else
            atom_print(args[0], stdout);
        fputc('\n', stdout);
        fflush(stdout);
        return atom_unit(a);
    }

    if (head_id == g_builtin_syms.trace_bang) {
        if (nargs != 2)
            return grounded_incorrect_arity(a, head, args, nargs);
        atom_print(args[0], stderr);
        fputc('\n', stderr);
        fflush(stderr);
        return args[1];
    }

    if (head_id == g_builtin_syms.format_args)
        return grounded_format_args(a, head, args, nargs);

    if (head_id == g_builtin_syms.sort_strings)
        return grounded_sort_strings(a, head, args, nargs);

    if (head_id == g_builtin_syms.repr)
        return grounded_repr(a, head, args, nargs);

    if (head_id == g_builtin_syms.parse)
        return grounded_parse_text(a, head, args, nargs,
                                   !eval_current_uses_rust_he_compat_semantics());

    if (head_id == g_builtin_syms.parse_first)
        return grounded_parse_text(a, head, args, nargs, false);

    if (head_id == g_builtin_syms.collapse_add_next)
        return grounded_collapse_add_next(a, head, args, nargs);

    if (head_id == g_builtin_syms.minimal_space_contains_exact)
        return grounded_space_contains_exact(a, head, args, nargs);

    if (head_id == g_builtin_syms.minimal_foldl_atom ||
        head_id == g_builtin_syms.minimal_foldl_until_atom ||
        head_id == g_builtin_syms.foldl_atom_in_space)
        return grounded_foldl_in_space(a, head, args, nargs);

    if (head_id == g_builtin_syms.range_atom)
        return grounded_range_atom(a, head, args, nargs);

    if (head_id == g_builtin_syms.repeat_atom)
        return grounded_repeat_atom(a, head, args, nargs);

    if (head_id == g_builtin_syms.alpha_eq) {
        if (nargs != 2)
            return grounded_incorrect_arity(a, head, args, nargs);
        return atom_alpha_eq(args[0], args[1]) ? atom_true(a) : atom_false(a);
    }

    if (head_id == g_builtin_syms.if_equal) {
        if (nargs != 4)
            return grounded_incorrect_arity(a, head, args, nargs);
        return atom_alpha_eq(args[0], args[1]) ? args[2] : args[3];
    }

    if (head_id == g_builtin_syms.sealed_text) {
        if (nargs != 2)
            return grounded_incorrect_arity(a, head, args, nargs);
        return rename_vars_except(a, args[1], args[0]);
    }

    if (head_id == g_builtin_syms.print_alternatives_bang) {
        if (nargs != 2)
            return grounded_incorrect_arity(a, head, args, nargs);
        if (args[1]->kind != ATOM_EXPR)
            return grounded_string_error(a, head, args, nargs, "Atom is not an ExpressionAtom");
        char *label = atom_to_string(a, args[0]);
        printf("%" PRIu64 " %s:\n", (uint64_t)args[1]->expr.len, label);
        for (CettaExprIndex i = 0; i < args[1]->expr.len; i++) {
            char *rendered = atom_to_string(a, args[1]->expr.elems[i]);
            printf("    %s\n", rendered);
        }
        fflush(stdout);
        return atom_unit(a);
    }

    if (head_id == g_builtin_syms.pow_math) {
        if (nargs != 2)
            return grounded_incorrect_arity(a, head, args, nargs);
        NumArg base;
        if (!get_numeric_arg_for_math(args[0], &base))
            return grounded_string_error(a, head, args, nargs,
                                         "pow-math expects two arguments: number (base) and number (power)");
        NumArg power;
        double power_val;
        if (args[1]->kind == ATOM_GROUNDED && args[1]->ground.gkind == GV_INT) {
            int64_t n = args[1]->ground.ival;
            if (n > INT32_MAX || n < INT32_MIN)
                return grounded_string_error(a, head, args, nargs,
                                             "power argument is too big, try using float value");
            power.ival = n;
            power.val = (double)n;
            power.is_float = false;
            power_val = (double)n;
        } else {
            if (!get_numeric_arg_for_math(args[1], &power))
                return grounded_string_error(a, head, args, nargs,
                                             "pow-math expects two arguments: number (base) and number (power)");
            power_val = power.val;
        }
        bool rust_compat = eval_current_uses_rust_he_compat_semantics();
        if (!rust_compat && base.val == 0.0 && power.val < 0.0)
            return grounded_math_domain_error(a, head, args, nargs, 1,
                                              "NonZeroBaseWhenExponentNegative");
        if (!rust_compat && base.val < 0.0 && !numeric_arg_is_integral(&power))
            return grounded_math_domain_error(a, head, args, nargs, 2,
                                              "IntegralExponentWhenBaseNegative");
        double res = pow(base.val, power_val);
        return atom_float(a, res);
    }

    if (head_id == g_builtin_syms.log_math) {
        if (nargs != 2)
            return grounded_incorrect_arity(a, head, args, nargs);
        NumArg base, input;
        if (!get_numeric_arg_for_math(args[0], &base) ||
            !get_numeric_arg_for_math(args[1], &input))
            return grounded_string_error(a, head, args, nargs,
                                         "log-math expects two arguments: base (number) and input value (number)");
        bool rust_compat = eval_current_uses_rust_he_compat_semantics();
        if (!rust_compat && (!(base.val > 0.0) || base.val == 1.0))
            return grounded_math_domain_error(a, head, args, nargs, 1,
                                              "PositiveRealNotOne");
        if (!rust_compat && !(input.val > 0.0))
            return grounded_math_domain_error(a, head, args, nargs, 2,
                                              "PositiveReal");
        return atom_float(a, log(input.val) / log(base.val));
    }

    if (head_id == g_builtin_syms.sqrt_math || head_id == g_builtin_syms.abs_math ||
        head_id == g_builtin_syms.trunc_math || head_id == g_builtin_syms.ceil_math ||
        head_id == g_builtin_syms.floor_math || head_id == g_builtin_syms.round_math ||
        head_id == g_builtin_syms.sin_math || head_id == g_builtin_syms.asin_math ||
        head_id == g_builtin_syms.cos_math || head_id == g_builtin_syms.acos_math ||
        head_id == g_builtin_syms.tan_math || head_id == g_builtin_syms.atan_math ||
        head_id == g_builtin_syms.isnan_math || head_id == g_builtin_syms.isinf_math) {
        if (nargs != 1)
            return grounded_incorrect_arity(a, head, args, nargs);
        NumArg input;
        if (!get_numeric_arg_for_math(args[0], &input)) {
            const char *msg = NULL;
            if (head_id == g_builtin_syms.sqrt_math)
                msg = "sqrt-math expects one argument: number";
            else if (head_id == g_builtin_syms.abs_math)
                msg = "abs-math expects one argument: number";
            else if (head_id == g_builtin_syms.trunc_math)
                msg = "trunc-math expects one argument: input number";
            else if (head_id == g_builtin_syms.ceil_math)
                msg = "ceil-math expects one argument: input number";
            else if (head_id == g_builtin_syms.floor_math)
                msg = "floor-math expects one argument: input number";
            else if (head_id == g_builtin_syms.round_math)
                msg = "round-math expects one argument: input number";
            else if (head_id == g_builtin_syms.sin_math)
                msg = "sin-math expects one argument: input number";
            else if (head_id == g_builtin_syms.asin_math)
                msg = "asin-math expects one argument: input number";
            else if (head_id == g_builtin_syms.cos_math)
                msg = "cos-math expects one argument: input number";
            else if (head_id == g_builtin_syms.acos_math)
                msg = "acos-math expects one argument: input number";
            else if (head_id == g_builtin_syms.tan_math)
                msg = "tan-math expects one argument: input number";
            else if (head_id == g_builtin_syms.atan_math)
                msg = "atan-math expects one argument: input number";
            else if (head_id == g_builtin_syms.isnan_math)
                msg = "isnan-math expects one argument: input number";
            else
                msg = "isinf-math expects one argument: input number";
            return grounded_string_error(a, head, args, nargs, msg);
        }

        if (head_id == g_builtin_syms.sqrt_math) {
            bool rust_compat = eval_current_uses_rust_he_compat_semantics();
            if (!rust_compat && input.val < 0.0)
                return grounded_math_domain_error(a, head, args, nargs, 1,
                                                  "NonNegativeReal");
#if CETTA_BUILD_WITH_GMP
            if (input.is_rational) {
                bool was_exact = false;
                Atom *exact = atom_from_rational_square_root(a, head, args, nargs,
                                                             &input, &was_exact);
                if (was_exact)
                    return exact;
            }
#endif
            return atom_float(a, sqrt(input.val));
        }
        if (head_id == g_builtin_syms.abs_math) {
            if (args[0]->kind == ATOM_GROUNDED &&
                args[0]->ground.gkind == GV_INT) {
                if (args[0]->ground.ival == INT64_MIN) {
#if CETTA_BUILD_WITH_GMP
                    mpz_t z;
                    mpz_init(z);
                    NumArg min_arg = {
                        .ival = args[0]->ground.ival,
                        .bigint = NULL,
                        .is_float = false,
                        .is_bigint = false,
                    };
                    num_arg_to_mpz(&min_arg, z);
                    mpz_abs(z, z);
                    Atom *out = atom_from_mpz(a, z);
                    mpz_clear(z);
                    return out;
#else
                    return atom_bigint(a, "9223372036854775808");
#endif
                }
                return atom_int(a, llabs(args[0]->ground.ival));
            }
            if (args[0]->kind == ATOM_GROUNDED &&
                args[0]->ground.gkind == GV_BIGINT) {
#if CETTA_BUILD_WITH_GMP
                mpz_t z;
                mpz_init(z);
                atom_bigint_get_mpz(args[0], z);
                mpz_abs(z, z);
                Atom *out = atom_from_mpz(a, z);
                mpz_clear(z);
                return out;
#else
                const char *text = atom_bigint_cstr(args[0]);
                return atom_bigint(a, text && text[0] == '-' ? text + 1 : text);
#endif
            }
#if CETTA_BUILD_WITH_GMP
            if (input.is_rational)
                return atom_from_rational_abs(a, head, args, nargs, &input);
#endif
            return atom_float(a, fabs(input.val));
        }
        if (head_id == g_builtin_syms.trunc_math) {
            if (args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_INT)
                return atom_int(a, args[0]->ground.ival);
            if (args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_BIGINT)
                return atom_bigint(a, atom_bigint_cstr(args[0]));
#if CETTA_BUILD_WITH_GMP
            if (input.is_rational)
                return atom_from_rational_integer_part(a, &input,
                                                       g_builtin_syms.trunc_math);
#endif
            return atom_float(a, trunc(input.val));
        }
        if (head_id == g_builtin_syms.ceil_math) {
            if (args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_INT)
                return atom_int(a, args[0]->ground.ival);
            if (args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_BIGINT)
                return atom_bigint(a, atom_bigint_cstr(args[0]));
#if CETTA_BUILD_WITH_GMP
            if (input.is_rational)
                return atom_from_rational_integer_part(a, &input,
                                                       g_builtin_syms.ceil_math);
#endif
            return atom_float(a, ceil(input.val));
        }
        if (head_id == g_builtin_syms.floor_math) {
            if (args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_INT)
                return atom_int(a, args[0]->ground.ival);
            if (args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_BIGINT)
                return atom_bigint(a, atom_bigint_cstr(args[0]));
#if CETTA_BUILD_WITH_GMP
            if (input.is_rational)
                return atom_from_rational_integer_part(a, &input,
                                                       g_builtin_syms.floor_math);
#endif
            return atom_float(a, floor(input.val));
        }
        if (head_id == g_builtin_syms.round_math) {
            if (args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_INT)
                return atom_int(a, args[0]->ground.ival);
            if (args[0]->kind == ATOM_GROUNDED && args[0]->ground.gkind == GV_BIGINT)
                return atom_bigint(a, atom_bigint_cstr(args[0]));
#if CETTA_BUILD_WITH_GMP
            if (input.is_rational)
                return atom_from_rational_round(a, &input);
#endif
            return atom_float(a, round(input.val));
        }
        if (head_id == g_builtin_syms.sin_math)
            return atom_float(a, sin(input.val));
        if (head_id == g_builtin_syms.asin_math) {
            bool rust_compat = eval_current_uses_rust_he_compat_semantics();
            if (!rust_compat && (input.val < -1.0 || input.val > 1.0))
                return grounded_math_domain_error(a, head, args, nargs, 1,
                                                  "ClosedUnitInterval");
            return atom_float(a, asin(input.val));
        }
        if (head_id == g_builtin_syms.cos_math)
            return atom_float(a, cos(input.val));
        if (head_id == g_builtin_syms.acos_math) {
            bool rust_compat = eval_current_uses_rust_he_compat_semantics();
            if (!rust_compat && (input.val < -1.0 || input.val > 1.0))
                return grounded_math_domain_error(a, head, args, nargs, 1,
                                                  "ClosedUnitInterval");
            return atom_float(a, acos(input.val));
        }
        if (head_id == g_builtin_syms.tan_math)
            return atom_float(a, tan(input.val));
        if (head_id == g_builtin_syms.atan_math)
            return atom_float(a, atan(input.val));
        if (head_id == g_builtin_syms.isnan_math)
            return isnan(input.val) ? atom_true(a) : atom_false(a);
        return isinf(input.val) ? atom_true(a) : atom_false(a);
    }

    if (head_id == g_builtin_syms.max_atom || head_id == g_builtin_syms.min_atom) {
        bool want_max = head_id == g_builtin_syms.max_atom;
        bool rust_compat = eval_current_uses_rust_he_compat_semantics();
        if (nargs != 1)
            return grounded_incorrect_arity(a, head, args, nargs);
        if (args[0]->kind != ATOM_EXPR)
            return grounded_string_error(a, head, args, nargs,
                                         "Atom is not an ExpressionAtom");
        if (args[0]->expr.len == 0)
            return grounded_string_error(a, head, args, nargs, "Empty expression");

        bool has_float = false;
        bool has_exact_extended = false;
        for (CettaExprIndex i = 0; i < args[0]->expr.len; i++) {
            NumArg n;
            if (!get_numeric_arg(args[0]->expr.elems[i], &n) ||
                (rust_compat && n.is_rational))
                return grounded_expr_message_error(
                    a, head, args, nargs,
                    "Only numbers are allowed in expression: ",
                    args[0]);
            has_float = has_float || n.is_float;
            has_exact_extended = has_exact_extended || n.is_bigint || n.is_rational;
        }

#if CETTA_BUILD_WITH_GMP
        if (has_exact_extended && !has_float) {
            mpq_t best_q, cur_q;
            mpq_inits(best_q, cur_q, NULL);
            Atom *best_atom = NULL;
            for (CettaExprIndex i = 0; i < args[0]->expr.len; i++) {
                NumArg n;
                if (!get_numeric_arg(args[0]->expr.elems[i], &n) ||
                    (rust_compat && n.is_rational) ||
                    !num_arg_to_mpq(&n, cur_q)) {
                    mpq_clears(best_q, cur_q, NULL);
                    return grounded_expr_message_error(
                        a, head, args, nargs,
                        "Only numbers are allowed in expression: ",
                        args[0]);
                }
                if (!best_atom ||
                    (want_max ? mpq_cmp(cur_q, best_q) > 0
                              : mpq_cmp(cur_q, best_q) < 0)) {
                    mpq_set(best_q, cur_q);
                    best_atom = args[0]->expr.elems[i];
                }
            }
            mpq_clears(best_q, cur_q, NULL);
            return best_atom;
        }
#else
        (void)has_exact_extended;
#endif

        double acc = want_max ? -INFINITY : INFINITY;
        for (CettaExprIndex i = 0; i < args[0]->expr.len; i++) {
            NumArg n;
            (void)get_numeric_arg(args[0]->expr.elems[i], &n);
            acc = want_max ? fmax(acc, n.val) : fmin(acc, n.val);
        }
        return atom_float(a, acc);
    }

    /* ── Expression introspection ─────────────────────────────────────── */
    if ((head_id == g_builtin_syms.size || head_id == g_builtin_syms.size_atom) && nargs == 1) {
        if (args[0]->kind == ATOM_EXPR)
            return atom_int(a, args[0]->expr.len);
        if (head_id == g_builtin_syms.size &&
            args[0]->kind == ATOM_GROUNDED &&
            args[0]->ground.gkind == GV_SPACE) {
            return atom_int(a, (int64_t)space_length64((Space *)args[0]->ground.ptr));
        }
        if (args[0]->kind == ATOM_GROUNDED) {
            Atom *expected = (head_id == g_builtin_syms.size_atom)
                ? atom_expression_type(a)
                : atom_symbol(a, "ExpressionOrSpace");
            return grounded_bad_arg_type(a, head, args, nargs, 1, expected, args[0]);
        }
        return NULL;
    }

    if (head_id == g_builtin_syms.index_atom && nargs == 2) {
        if (args[0]->kind != ATOM_EXPR) {
            if (args[0]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 1,
                                             atom_expression_type(a), args[0]);
            return NULL;
        }
        if (args[1]->kind != ATOM_GROUNDED || args[1]->ground.gkind != GV_INT) {
            if (args[1]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 2,
                                             atom_symbol(a, "Number"), args[1]);
            return NULL;
        }
        int64_t idx = args[1]->ground.ival;
        if (idx < 0 || (uint64_t)idx >= args[0]->expr.len)
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_string(a, "Index is out of bounds"));
        return args[0]->expr.elems[idx];
    }

    if (head_id == g_builtin_syms.unique_atom && nargs == 1) {
        if (args[0]->kind != ATOM_EXPR) {
            if (args[0]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 1,
                                             atom_expression_type(a), args[0]);
            return NULL;
        }
        if (!cetta_expr_len_fits_u32(args[0]->expr.len))
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "ArityTooLarge"));
        Atom **uniq = arena_alloc(a, sizeof(Atom *) * args[0]->expr.len);
        uint32_t table_cap = next_pow2_u32(args[0]->expr.len > 0
            ? args[0]->expr.len * 2
            : 1);
        uint32_t *ground_slots = arena_alloc(a, sizeof(uint32_t) * table_cap);
        for (uint32_t i = 0; i < table_cap; i++)
            ground_slots[i] = UINT32_MAX;
        CettaExprLen out_len = 0;
        for (CettaExprIndex i = 0; i < args[0]->expr.len; i++) {
            Atom *candidate = args[0]->expr.elems[i];
            bool seen = false;
            bool candidate_has_vars = atom_has_vars(candidate);
            if (!candidate_has_vars) {
                uint32_t mask = table_cap - 1;
                uint32_t slot = atom_hash(candidate) & mask;
                while (true) {
                    uint32_t existing = ground_slots[slot];
                    if (existing == UINT32_MAX)
                        break;
                    if (atom_eq(uniq[existing], candidate)) {
                        seen = true;
                        break;
                    }
                    slot = (slot + 1) & mask;
                }
                if (!seen) {
                    uniq[out_len] = candidate;
                    ground_slots[slot] = (uint32_t)out_len;
                    out_len++;
                }
                continue;
            }
            for (CettaExprIndex j = 0; j < out_len; j++) {
                if (atom_alpha_eq(uniq[j], candidate)) {
                    seen = true;
                    break;
                }
            }
            if (!seen)
                uniq[out_len++] = candidate;
        }
        return atom_expr(a, uniq, out_len);
    }

    if (head_id == g_builtin_syms.intersection_atom && nargs == 2) {
        if (args[0]->kind != ATOM_EXPR || args[1]->kind != ATOM_EXPR) {
            if (args[0]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 1,
                                             atom_expression_type(a), args[0]);
            if (args[1]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 2,
                                             atom_expression_type(a), args[1]);
            return NULL;
        }
        Atom **out = arena_alloc(a, sizeof(Atom *) * args[0]->expr.len);
        bool *rhs_used = arena_alloc(a, sizeof(bool) * args[1]->expr.len);
        memset(rhs_used, 0, sizeof(bool) * args[1]->expr.len);
        CettaExprLen out_len = 0;
        for (CettaExprIndex i = 0; i < args[0]->expr.len; i++) {
            Atom *candidate = args[0]->expr.elems[i];
            CettaExprIndex match_idx = 0;
            if (find_unused_alpha_equal_atom(args[1]->expr.elems, rhs_used,
                                             args[1]->expr.len, candidate,
                                             &match_idx)) {
                rhs_used[match_idx] = true;
                out[out_len++] = candidate;
            }
        }
        return atom_expr(a, out, out_len);
    }

    if (head_id == g_builtin_syms.subtraction_atom && nargs == 2) {
        if (args[0]->kind != ATOM_EXPR || args[1]->kind != ATOM_EXPR) {
            if (args[0]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 1,
                                             atom_expression_type(a), args[0]);
            if (args[1]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 2,
                                             atom_expression_type(a), args[1]);
            return NULL;
        }
        Atom **out = arena_alloc(a, sizeof(Atom *) * args[0]->expr.len);
        bool *rhs_used = arena_alloc(a, sizeof(bool) * args[1]->expr.len);
        memset(rhs_used, 0, sizeof(bool) * args[1]->expr.len);
        CettaExprLen out_len = 0;
        for (CettaExprIndex i = 0; i < args[0]->expr.len; i++) {
            Atom *candidate = args[0]->expr.elems[i];
            CettaExprIndex match_idx = 0;
            if (find_unused_alpha_equal_atom(args[1]->expr.elems, rhs_used,
                                             args[1]->expr.len, candidate,
                                             &match_idx)) {
                rhs_used[match_idx] = true;
                continue;
            }
            out[out_len++] = candidate;
        }
        return atom_expr(a, out, out_len);
    }

    if (head_id == g_builtin_syms.member_atom_q) {
        if (nargs != 2)
            return grounded_incorrect_arity(a, head, args, nargs);
        if (args[1]->kind != ATOM_EXPR) {
            if (args[1]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 2,
                                             atom_expression_type(a), args[1]);
            return NULL;
        }
        for (CettaExprIndex i = 0; i < args[1]->expr.len; i++) {
            if (atom_alpha_eq(args[0], args[1]->expr.elems[i]))
                return atom_bool(a, true);
        }
        return atom_bool(a, false);
    }

    if (head_id == g_builtin_syms.subset_atom_q ||
        head_id == g_builtin_syms.same_set_atom_q) {
        if (nargs != 2)
            return grounded_incorrect_arity(a, head, args, nargs);
        if (args[0]->kind != ATOM_EXPR || args[1]->kind != ATOM_EXPR) {
            if (args[0]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 1,
                                             atom_expression_type(a), args[0]);
            if (args[1]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 2,
                                             atom_expression_type(a), args[1]);
            return NULL;
        }
        bool left_subset = true;
        for (CettaExprIndex i = 0; i < args[0]->expr.len && left_subset; i++) {
            bool found = false;
            for (CettaExprIndex j = 0; j < args[1]->expr.len; j++) {
                if (atom_alpha_eq(args[0]->expr.elems[i],
                                  args[1]->expr.elems[j])) {
                    found = true;
                    break;
                }
            }
            left_subset = found;
        }
        if (head_id == g_builtin_syms.subset_atom_q || !left_subset)
            return atom_bool(a, left_subset);

        for (CettaExprIndex i = 0; i < args[1]->expr.len; i++) {
            bool found = false;
            for (CettaExprIndex j = 0; j < args[0]->expr.len; j++) {
                if (atom_alpha_eq(args[1]->expr.elems[i],
                                  args[0]->expr.elems[j])) {
                    found = true;
                    break;
                }
            }
            if (!found)
                return atom_bool(a, false);
        }
        return atom_bool(a, true);
    }

    if (head_id == g_builtin_syms.wm_fca_index_columns_atom) {
        if (nargs != 5)
            return grounded_incorrect_arity(a, head, args, nargs);
        for (uint32_t i = 0; i < 3; i++) {
            if (args[i]->kind != ATOM_EXPR) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, i + 1,
                        atom_expression_type(a), args[i]);
                return NULL;
            }
        }

        WmFcaNativeGateKind gate_kind;
        NumArg threshold;
        Atom *gate_error = NULL;
        Atom *call = grounded_call_expr(a, head, args, nargs);
        if (!wm_fca_native_parse_gate(
                a, call, args[4], &gate_kind, &threshold, &gate_error))
            return gate_error;

        Atom *objects = args[0];
        Atom *attributes = args[1];
        Atom *observations = args[2];
        Atom *context = args[3];
        size_t object_count = objects->expr.len;
        size_t attribute_count = attributes->expr.len;
        if (!cetta_expr_len_mul_fits_size(
                objects->expr.len, sizeof(Atom *)) ||
            !cetta_expr_len_mul_fits_size(
                attributes->expr.len, sizeof(Atom *)) ||
            (attribute_count != 0 &&
             object_count > SIZE_MAX / attribute_count)) {
            return atom_error(
                a, grounded_call_expr(a, head, args, nargs),
                atom_symbol(a, "WMFCAIndexDimensionsTooLarge"));
        }
        size_t cell_count = object_count * attribute_count;
        if (cell_count > SIZE_MAX / sizeof(WmFcaNativeCellEvidence)) {
            return atom_error(
                a, grounded_call_expr(a, head, args, nargs),
                atom_symbol(a, "WMFCAIndexDimensionsTooLarge"));
        }
        WmFcaNativeCellEvidence *cells = cell_count == 0
            ? NULL
            : cetta_malloc(sizeof(WmFcaNativeCellEvidence) * cell_count);
        if (cells)
            memset(cells, 0,
                   sizeof(WmFcaNativeCellEvidence) * cell_count);

        for (CettaExprIndex i = 0; i < observations->expr.len; i++) {
            Atom *observation = observations->expr.elems[i];
            if (observation->kind != ATOM_EXPR ||
                observation->expr.len != 8 ||
                !atom_is_symbol(
                    observation->expr.elems[0], "WMFCAObservation")) {
                wm_fca_native_evidence_free(cells, cell_count);
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_symbol(a, "MalformedWMFCAObservation"));
            }
            Atom *status = observation->expr.elems[4];
            bool positive = atom_is_symbol(status, "WMTrue");
            bool negative = atom_is_symbol(status, "WMFalse");
            bool unknown = atom_is_symbol(status, "WMUnknown");
            if (!positive && !negative && !unknown) {
                wm_fca_native_evidence_free(cells, cell_count);
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_symbol(a, "InvalidWMFCAObservationStatus"));
            }
            if (!atom_alpha_eq(observation->expr.elems[1], context))
                continue;
            CettaExprIndex object = wm_fca_native_universe_index(
                objects, observation->expr.elems[2]);
            CettaExprIndex attribute = wm_fca_native_universe_index(
                attributes, observation->expr.elems[3]);
            if (object == objects->expr.len ||
                attribute == attributes->expr.len)
                continue;
            WmFcaNativeCellEvidence *evidence =
                &cells[(size_t)attribute * object_count + object];
            if (positive) {
                evidence->positive_count++;
                if (!wm_fca_native_add_unique(
                        &evidence->positive_sources,
                        &evidence->positive_source_count,
                        &evidence->positive_source_capacity,
                        observation->expr.elems[6]) ||
                    !wm_fca_native_add_unique(
                        &evidence->positive_groups,
                        &evidence->positive_group_count,
                        &evidence->positive_group_capacity,
                        observation->expr.elems[7])) {
                    wm_fca_native_evidence_free(cells, cell_count);
                    return atom_error(
                        a, grounded_call_expr(a, head, args, nargs),
                        atom_symbol(a, "WMFCAEvidenceIndexTooLarge"));
                }
            } else if (negative) {
                evidence->negative_count++;
            } else {
                evidence->unknown_count++;
            }
        }

        Atom **columns = arena_alloc(
            a, sizeof(Atom *) * attribute_count);
        for (CettaExprIndex attribute = 0;
             attribute < attributes->expr.len; attribute++) {
            Atom **members = arena_alloc(
                a, sizeof(Atom *) * object_count);
            CettaExprLen member_count = 0;
            for (CettaExprIndex object = 0;
                 object < objects->expr.len; object++) {
                const WmFcaNativeCellEvidence *evidence =
                    &cells[(size_t)attribute * object_count + object];
                if (wm_fca_native_gate_accepts(
                        evidence, gate_kind, &threshold)) {
                    members[member_count++] = objects->expr.elems[object];
                }
            }
            columns[attribute] = atom_expr3(
                a, atom_symbol(a, "WMFCAColumn"),
                attributes->expr.elems[attribute],
                atom_expr(a, members, member_count));
        }
        Atom *result = atom_expr(a, columns, attributes->expr.len);
        wm_fca_native_evidence_free(cells, cell_count);
        return result;
    }

    if (head_id == g_builtin_syms.wm_fca_binary_rows_columns_atom) {
        if (nargs != 6)
            return grounded_incorrect_arity(a, head, args, nargs);
        for (uint32_t i = 0; i < 3; i++) {
            if (args[i]->kind != ATOM_EXPR) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, i + 1,
                        atom_expression_type(a), args[i]);
                return NULL;
            }
        }

        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *objects = args[0];
        Atom *attributes = args[1];
        Atom *rows = args[2];
        Atom *row_error = NULL;
        if (!wm_fca_native_validate_binary_rows(
                a, call, objects, attributes, rows, &row_error))
            return row_error;

        WmFcaNativeGateKind gate_kind;
        NumArg threshold;
        Atom *gate_error = NULL;
        if (!wm_fca_native_parse_gate(
                a, call, args[5], &gate_kind, &threshold, &gate_error))
            return gate_error;

        size_t object_count = objects->expr.len;
        size_t attribute_count = attributes->expr.len;
        if (!cetta_expr_len_mul_fits_size(
                objects->expr.len, sizeof(Atom *)) ||
            !cetta_expr_len_mul_fits_size(
                attributes->expr.len, sizeof(Atom *)) ||
            (attribute_count != 0 &&
             object_count > SIZE_MAX / attribute_count)) {
            return atom_error(
                a, call, atom_symbol(a, "WMFCAIndexDimensionsTooLarge"));
        }

        bool same_context = atom_alpha_eq(args[3], args[4]);
        bool *incidence = wm_fca_native_binary_incidence(
            a, objects, attributes, rows, same_context,
            gate_kind, &threshold);
        Atom **columns = arena_alloc(a, sizeof(Atom *) * attribute_count);
        for (CettaExprIndex attribute = 0;
             attribute < attributes->expr.len; attribute++) {
            Atom **members = arena_alloc(a, sizeof(Atom *) * object_count);
            CettaExprLen member_count = 0;
            for (CettaExprIndex object = 0;
                 object < objects->expr.len; object++) {
                if (incidence[(size_t)attribute * object_count + object]) {
                    members[member_count++] = objects->expr.elems[object];
                }
            }
            columns[attribute] = atom_expr3(
                a, atom_symbol(a, "WMFCAColumn"),
                attributes->expr.elems[attribute],
                atom_expr(a, members, member_count));
        }
        return atom_expr(a, columns, attributes->expr.len);
    }

    if (head_id == g_builtin_syms.wm_fca_binary_cell_status_atom) {
        if (nargs != 7)
            return grounded_incorrect_arity(a, head, args, nargs);
        for (uint32_t i = 0; i < 3; i++) {
            if (args[i]->kind != ATOM_EXPR) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, i + 1,
                        atom_expression_type(a), args[i]);
                return NULL;
            }
        }

        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *objects = args[0];
        Atom *attributes = args[1];
        Atom *rows = args[2];
        Atom *row_error = NULL;
        if (!wm_fca_native_validate_binary_rows(
                a, call, objects, attributes, rows, &row_error))
            return row_error;
        if (!atom_alpha_eq(args[3], args[4]))
            return atom_symbol(a, "WMMissing");

        CettaExprIndex object = wm_fca_native_universe_index(objects, args[5]);
        CettaExprIndex attribute =
            wm_fca_native_universe_index(attributes, args[6]);
        if (object == objects->expr.len || attribute == attributes->expr.len)
            return atom_symbol(a, "WMMissing");
        const char *bits = rows->expr.elems[object]->expr.elems[2]->ground.sval;
        return atom_symbol(a, bits[attribute] == '1' ? "WMTrue" : "WMFalse");
    }

    if (head_id == g_builtin_syms.wm_fca_binary_query_batch_atom) {
        if (nargs != 7)
            return grounded_incorrect_arity(a, head, args, nargs);
        for (uint32_t i = 0; i < 3; i++) {
            if (args[i]->kind != ATOM_EXPR) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, i + 1,
                        atom_expression_type(a), args[i]);
                return NULL;
            }
        }
        if (args[6]->kind != ATOM_EXPR) {
            if (args[6]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(
                    a, head, args, nargs, 7,
                    atom_expression_type(a), args[6]);
            return NULL;
        }

        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *objects = args[0];
        Atom *attributes = args[1];
        Atom *rows = args[2];
        Atom *row_error = NULL;
        if (!wm_fca_native_validate_binary_rows(
                a, call, objects, attributes, rows, &row_error))
            return row_error;

        WmFcaNativeGateKind gate_kind;
        NumArg threshold;
        Atom *gate_error = NULL;
        if (!wm_fca_native_parse_gate(
                a, call, args[5], &gate_kind, &threshold, &gate_error))
            return gate_error;

        size_t object_count = objects->expr.len;
        size_t attribute_count = attributes->expr.len;
        if (!cetta_expr_len_mul_fits_size(
                objects->expr.len, sizeof(bool)) ||
            !cetta_expr_len_mul_fits_size(
                attributes->expr.len, sizeof(bool)) ||
            (attribute_count != 0 &&
             object_count > SIZE_MAX / attribute_count)) {
            return atom_error(
                a, call, atom_symbol(a, "WMFCAIndexDimensionsTooLarge"));
        }

        bool *incidence = wm_fca_native_binary_incidence(
            a, objects, attributes, rows,
            atom_alpha_eq(args[3], args[4]), gate_kind, &threshold);
        Atom *queries = args[6];
        Atom **results = arena_alloc(
            a, sizeof(Atom *) * queries->expr.len);
        for (CettaExprIndex query_index = 0;
             query_index < queries->expr.len; query_index++) {
            Atom *query = queries->expr.elems[query_index];
            if (query->kind != ATOM_EXPR) {
                return atom_error(
                    a, call, atom_symbol(a, "MalformedWMFCABatchQuery"));
            }
            bool *selected = arena_alloc(
                a, sizeof(bool) * (attribute_count == 0 ? 1 : attribute_count));
            memset(selected, 0, sizeof(bool) * attribute_count);
            for (CettaExprIndex item = 0; item < query->expr.len; item++) {
                CettaExprIndex attribute = wm_fca_native_universe_index(
                    attributes, query->expr.elems[item]);
                if (attribute < attributes->expr.len)
                    selected[attribute] = true;
            }

            bool *extent = arena_alloc(
                a, sizeof(bool) * (object_count == 0 ? 1 : object_count));
            bool *closure = arena_alloc(
                a, sizeof(bool) * (attribute_count == 0 ? 1 : attribute_count));
            galois_boolean_closure(
                objects->expr.len, attributes->expr.len,
                incidence, selected, extent, closure);

            Atom **extent_items = arena_alloc(
                a, sizeof(Atom *) * object_count);
            CettaExprLen extent_len = 0;
            for (CettaExprIndex object = 0;
                 object < objects->expr.len; object++) {
                if (extent[object])
                    extent_items[extent_len++] = objects->expr.elems[object];
            }
            Atom *extent_atom = atom_expr(a, extent_items, extent_len);
            Atom *closure_atom =
                galois_attribute_set_atom(a, attributes, closure);
            Atom *result_items[4] = {
                atom_symbol(a, "WMFCABatchQueryResult"),
                query,
                extent_atom,
                closure_atom,
            };
            results[query_index] = atom_expr(a, result_items, 4);
        }
        return atom_expr(a, results, queries->expr.len);
    }

    if (head_id == g_builtin_syms.wm_fca_binary_event_columns_atom) {
        if (nargs != 9)
            return grounded_incorrect_arity(a, head, args, nargs);
        const uint32_t expression_args[] = {0, 1, 2, 6};
        for (size_t i = 0;
             i < sizeof(expression_args) / sizeof(expression_args[0]); i++) {
            uint32_t arg = expression_args[i];
            if (args[arg]->kind != ATOM_EXPR) {
                if (args[arg]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, arg + 1,
                        atom_expression_type(a), args[arg]);
                return NULL;
            }
        }

        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *row_error = NULL;
        if (!wm_fca_native_validate_binary_rows(
                a, call, args[0], args[1], args[2], &row_error))
            return row_error;
        WmFcaNativeGateKind gate_kind;
        NumArg threshold;
        Atom *gate_error = NULL;
        if (!wm_fca_native_parse_gate(
                a, call, args[8], &gate_kind, &threshold, &gate_error))
            return gate_error;

        WmFcaNativeEventSnapshot snapshot;
        Atom *event_error = NULL;
        if (!wm_fca_native_replay_binary_events(
                a, call, args[0], args[1], args[2], args[3],
                args[4], args[5], args[6], &snapshot, &event_error))
            return event_error;
        Atom *evidence_error = NULL;
        bool *incidence = wm_fca_native_event_incidence(
            a, call, args[0], args[1], args[2], args[3],
            args[4], args[5], args[7], &snapshot,
            gate_kind, &threshold, &evidence_error);
        if (evidence_error) {
            wm_fca_native_event_snapshot_free(&snapshot);
            return evidence_error;
        }

        size_t object_count = args[0]->expr.len;
        size_t attribute_count = args[1]->expr.len;
        Atom **columns = arena_alloc(a, sizeof(Atom *) * attribute_count);
        for (CettaExprIndex attribute = 0;
             attribute < args[1]->expr.len; attribute++) {
            Atom **members = arena_alloc(a, sizeof(Atom *) * object_count);
            CettaExprLen member_count = 0;
            for (CettaExprIndex object = 0;
                 object < args[0]->expr.len; object++) {
                if (incidence[(size_t)attribute * object_count + object])
                    members[member_count++] = args[0]->expr.elems[object];
            }
            columns[attribute] = atom_expr3(
                a, atom_symbol(a, "WMFCAColumn"),
                args[1]->expr.elems[attribute],
                atom_expr(a, members, member_count));
        }
        Atom *result = atom_expr(a, columns, args[1]->expr.len);
        wm_fca_native_event_snapshot_free(&snapshot);
        return result;
    }

    if (head_id ==
        g_builtin_syms.wm_fca_binary_event_cell_evidence_atom) {
        if (nargs != 10)
            return grounded_incorrect_arity(a, head, args, nargs);
        const uint32_t expression_args[] = {0, 1, 2, 6};
        for (size_t i = 0;
             i < sizeof(expression_args) / sizeof(expression_args[0]); i++) {
            uint32_t arg = expression_args[i];
            if (args[arg]->kind != ATOM_EXPR) {
                if (args[arg]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, arg + 1,
                        atom_expression_type(a), args[arg]);
                return NULL;
            }
        }
        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *row_error = NULL;
        if (!wm_fca_native_validate_binary_rows(
                a, call, args[0], args[1], args[2], &row_error))
            return row_error;
        WmFcaNativeEventSnapshot snapshot;
        Atom *event_error = NULL;
        if (!wm_fca_native_replay_binary_events(
                a, call, args[0], args[1], args[2], args[3],
                args[4], args[5], args[6], &snapshot, &event_error))
            return event_error;

        if (snapshot.addition_count == SIZE_MAX) {
            wm_fca_native_event_snapshot_free(&snapshot);
            return atom_error(
                a, call, atom_symbol(a, "WMFCAEvidenceIndexTooLarge"));
        }
        Atom **items = arena_alloc(
            a, sizeof(Atom *) * (snapshot.addition_count + 1));
        CettaExprLen len = 0;
        CettaExprIndex object = wm_fca_native_universe_index(args[0], args[8]);
        CettaExprIndex attribute =
            wm_fca_native_universe_index(args[1], args[9]);
        if (atom_alpha_eq(args[3], args[7]) &&
            object < args[0]->expr.len && attribute < args[1]->expr.len &&
            snapshot.base_active[
                (size_t)attribute * args[0]->expr.len + object]) {
            items[len++] = wm_fca_native_base_observation(
                a, args[0], args[1], args[2], args[3], args[4], args[5],
                object, attribute);
        }
        for (size_t i = 0; i < snapshot.addition_count; i++) {
            Atom *observation = snapshot.additions[i];
            if (atom_alpha_eq(observation->expr.elems[1], args[7]) &&
                atom_alpha_eq(observation->expr.elems[2], args[8]) &&
                atom_alpha_eq(observation->expr.elems[3], args[9]))
                items[len++] = observation;
        }
        Atom *result = atom_expr(a, items, len);
        wm_fca_native_event_snapshot_free(&snapshot);
        return result;
    }

    if (head_id ==
        g_builtin_syms.wm_fca_binary_event_observation_count_atom) {
        if (nargs != 7)
            return grounded_incorrect_arity(a, head, args, nargs);
        const uint32_t expression_args[] = {0, 1, 2, 6};
        for (size_t i = 0;
             i < sizeof(expression_args) / sizeof(expression_args[0]); i++) {
            uint32_t arg = expression_args[i];
            if (args[arg]->kind != ATOM_EXPR) {
                if (args[arg]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, arg + 1,
                        atom_expression_type(a), args[arg]);
                return NULL;
            }
        }
        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *row_error = NULL;
        if (!wm_fca_native_validate_binary_rows(
                a, call, args[0], args[1], args[2], &row_error))
            return row_error;
        WmFcaNativeEventSnapshot snapshot;
        Atom *event_error = NULL;
        if (!wm_fca_native_replay_binary_events(
                a, call, args[0], args[1], args[2], args[3],
                args[4], args[5], args[6], &snapshot, &event_error))
            return event_error;
        if ((uint64_t)snapshot.addition_count > (uint64_t)INT64_MAX) {
            wm_fca_native_event_snapshot_free(&snapshot);
            return atom_error(
                a, call,
                atom_symbol(a, "WMFCAObservationCountTooLarge"));
        }
        uint64_t active = (uint64_t)snapshot.addition_count;
        for (size_t cell = 0; cell < snapshot.base_cell_count; cell++) {
            if (snapshot.base_active[cell]) {
                if (active == (uint64_t)INT64_MAX) {
                    wm_fca_native_event_snapshot_free(&snapshot);
                    return atom_error(
                        a, call,
                        atom_symbol(a, "WMFCAObservationCountTooLarge"));
                }
                active++;
            }
        }
        wm_fca_native_event_snapshot_free(&snapshot);
        return atom_int(a, (int64_t)active);
    }

    if (head_id ==
        g_builtin_syms.wm_fca_binary_event_query_batch_atom) {
        if (nargs != 10)
            return grounded_incorrect_arity(a, head, args, nargs);
        const uint32_t expression_args[] = {0, 1, 2, 6, 9};
        for (size_t i = 0;
             i < sizeof(expression_args) / sizeof(expression_args[0]); i++) {
            uint32_t arg = expression_args[i];
            if (args[arg]->kind != ATOM_EXPR) {
                if (args[arg]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, arg + 1,
                        atom_expression_type(a), args[arg]);
                return NULL;
            }
        }
        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *row_error = NULL;
        if (!wm_fca_native_validate_binary_rows(
                a, call, args[0], args[1], args[2], &row_error))
            return row_error;
        WmFcaNativeGateKind gate_kind;
        NumArg threshold;
        Atom *gate_error = NULL;
        if (!wm_fca_native_parse_gate(
                a, call, args[8], &gate_kind, &threshold, &gate_error))
            return gate_error;
        WmFcaNativeEventSnapshot snapshot;
        Atom *event_error = NULL;
        if (!wm_fca_native_replay_binary_events(
                a, call, args[0], args[1], args[2], args[3],
                args[4], args[5], args[6], &snapshot, &event_error))
            return event_error;
        Atom *evidence_error = NULL;
        bool *incidence = wm_fca_native_event_incidence(
            a, call, args[0], args[1], args[2], args[3],
            args[4], args[5], args[7], &snapshot,
            gate_kind, &threshold, &evidence_error);
        if (evidence_error) {
            wm_fca_native_event_snapshot_free(&snapshot);
            return evidence_error;
        }

        size_t object_count = args[0]->expr.len;
        size_t attribute_count = args[1]->expr.len;
        Atom *queries = args[9];
        Atom **results = arena_alloc(a, sizeof(Atom *) * queries->expr.len);
        for (CettaExprIndex query_index = 0;
             query_index < queries->expr.len; query_index++) {
            Atom *query = queries->expr.elems[query_index];
            if (query->kind != ATOM_EXPR) {
                wm_fca_native_event_snapshot_free(&snapshot);
                return atom_error(
                    a, call, atom_symbol(a, "MalformedWMFCABatchQuery"));
            }
            bool *selected = arena_alloc(
                a, sizeof(bool) * (attribute_count == 0 ? 1 : attribute_count));
            memset(selected, 0, sizeof(bool) * attribute_count);
            for (CettaExprIndex item = 0; item < query->expr.len; item++) {
                CettaExprIndex attribute = wm_fca_native_universe_index(
                    args[1], query->expr.elems[item]);
                if (attribute < args[1]->expr.len)
                    selected[attribute] = true;
            }
            bool *extent = arena_alloc(
                a, sizeof(bool) * (object_count == 0 ? 1 : object_count));
            bool *closure = arena_alloc(
                a, sizeof(bool) * (attribute_count == 0 ? 1 : attribute_count));
            galois_boolean_closure(
                args[0]->expr.len, args[1]->expr.len,
                incidence, selected, extent, closure);

            Atom **extent_items = arena_alloc(a, sizeof(Atom *) * object_count);
            CettaExprLen extent_len = 0;
            for (CettaExprIndex item = 0;
                 item < args[0]->expr.len; item++) {
                if (extent[item])
                    extent_items[extent_len++] = args[0]->expr.elems[item];
            }
            Atom *result_items[4] = {
                atom_symbol(a, "WMFCABatchQueryResult"),
                query,
                atom_expr(a, extent_items, extent_len),
                galois_attribute_set_atom(a, args[1], closure),
            };
            results[query_index] = atom_expr(a, result_items, 4);
        }
        Atom *result = atom_expr(a, results, queries->expr.len);
        wm_fca_native_event_snapshot_free(&snapshot);
        return result;
    }

    if (head_id == g_builtin_syms.wm_fca_evidence_layer_columns_atom) {
        if (nargs != 5)
            return grounded_incorrect_arity(a, head, args, nargs);
        const uint32_t expression_args[] = {0, 1, 2};
        for (size_t i = 0;
             i < sizeof(expression_args) / sizeof(expression_args[0]); i++) {
            uint32_t arg = expression_args[i];
            if (args[arg]->kind != ATOM_EXPR) {
                if (args[arg]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, arg + 1,
                        atom_expression_type(a), args[arg]);
                return NULL;
            }
        }
        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *layer_error = NULL;
        if (!wm_fca_native_validate_evidence_layers(
                a, call, args[0], args[1], args[2], &layer_error))
            return layer_error;
        WmFcaNativeGateKind gate_kind;
        NumArg threshold;
        Atom *gate_error = NULL;
        if (!wm_fca_native_parse_gate(
                a, call, args[4], &gate_kind, &threshold, &gate_error))
            return gate_error;
        Atom *evidence_error = NULL;
        bool *incidence = wm_fca_native_evidence_layer_incidence(
            a, call, args[0], args[1], args[2], args[3],
            gate_kind, &threshold, &evidence_error);
        if (evidence_error)
            return evidence_error;
        return wm_fca_native_columns_from_incidence(
            a, args[0], args[1], incidence);
    }

    if (head_id ==
        g_builtin_syms.wm_fca_evidence_layer_cell_evidence_atom) {
        if (nargs != 6)
            return grounded_incorrect_arity(a, head, args, nargs);
        const uint32_t expression_args[] = {0, 1, 2};
        for (size_t i = 0;
             i < sizeof(expression_args) / sizeof(expression_args[0]); i++) {
            uint32_t arg = expression_args[i];
            if (args[arg]->kind != ATOM_EXPR) {
                if (args[arg]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, arg + 1,
                        atom_expression_type(a), args[arg]);
                return NULL;
            }
        }
        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *layer_error = NULL;
        if (!wm_fca_native_validate_evidence_layers(
                a, call, args[0], args[1], args[2], &layer_error))
            return layer_error;
        Atom **items = arena_alloc(a, sizeof(Atom *) * args[2]->expr.len);
        CettaExprLen len = 0;
        CettaExprIndex object = wm_fca_native_universe_index(args[0], args[4]);
        CettaExprIndex attribute =
            wm_fca_native_universe_index(args[1], args[5]);
        if (object < args[0]->expr.len && attribute < args[1]->expr.len) {
            for (CettaExprIndex layer_index = 0;
                 layer_index < args[2]->expr.len; layer_index++) {
                if (wm_fca_native_evidence_layer_is_duplicate(
                        args[2], layer_index))
                    continue;
                Atom *layer = args[2]->expr.elems[layer_index];
                if (!atom_alpha_eq(layer->expr.elems[2], args[3]))
                    continue;
                const char *statuses = layer->expr.elems[5]
                    ->expr.elems[object]->expr.elems[2]->ground.sval;
                if (statuses[attribute] == '.')
                    continue;
                items[len++] = wm_fca_native_evidence_layer_observation(
                    a, args[0], args[1], layer, object, attribute);
            }
        }
        return atom_expr(a, items, len);
    }

    if (head_id ==
        g_builtin_syms.wm_fca_evidence_layer_observation_count_atom) {
        if (nargs != 3)
            return grounded_incorrect_arity(a, head, args, nargs);
        for (uint32_t arg = 0; arg < nargs; arg++) {
            if (args[arg]->kind != ATOM_EXPR) {
                if (args[arg]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, arg + 1,
                        atom_expression_type(a), args[arg]);
                return NULL;
            }
        }
        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *layer_error = NULL;
        if (!wm_fca_native_validate_evidence_layers(
                a, call, args[0], args[1], args[2], &layer_error))
            return layer_error;
        uint64_t count = 0;
        for (CettaExprIndex layer_index = 0;
             layer_index < args[2]->expr.len; layer_index++) {
            if (wm_fca_native_evidence_layer_is_duplicate(
                    args[2], layer_index))
                continue;
            Atom *rows = args[2]->expr.elems[layer_index]->expr.elems[5];
            for (CettaExprIndex object = 0;
                 object < rows->expr.len; object++) {
                const char *statuses =
                    rows->expr.elems[object]->expr.elems[2]->ground.sval;
                for (CettaExprIndex attribute = 0;
                     attribute < args[1]->expr.len; attribute++) {
                    if (statuses[attribute] == '.')
                        continue;
                    if (count == (uint64_t)INT64_MAX)
                        return atom_error(
                            a, call,
                            atom_symbol(a,
                                        "WMFCAObservationCountTooLarge"));
                    count++;
                }
            }
        }
        return atom_int(a, (int64_t)count);
    }

    if (head_id ==
        g_builtin_syms.wm_fca_evidence_layer_query_batch_atom) {
        if (nargs != 6)
            return grounded_incorrect_arity(a, head, args, nargs);
        const uint32_t expression_args[] = {0, 1, 2, 5};
        for (size_t i = 0;
             i < sizeof(expression_args) / sizeof(expression_args[0]); i++) {
            uint32_t arg = expression_args[i];
            if (args[arg]->kind != ATOM_EXPR) {
                if (args[arg]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(
                        a, head, args, nargs, arg + 1,
                        atom_expression_type(a), args[arg]);
                return NULL;
            }
        }
        Atom *call = grounded_call_expr(a, head, args, nargs);
        Atom *layer_error = NULL;
        if (!wm_fca_native_validate_evidence_layers(
                a, call, args[0], args[1], args[2], &layer_error))
            return layer_error;
        WmFcaNativeGateKind gate_kind;
        NumArg threshold;
        Atom *gate_error = NULL;
        if (!wm_fca_native_parse_gate(
                a, call, args[4], &gate_kind, &threshold, &gate_error))
            return gate_error;
        Atom *evidence_error = NULL;
        bool *incidence = wm_fca_native_evidence_layer_incidence(
            a, call, args[0], args[1], args[2], args[3],
            gate_kind, &threshold, &evidence_error);
        if (evidence_error)
            return evidence_error;
        return wm_fca_native_batch_from_incidence(
            a, call, args[0], args[1], incidence, args[5]);
    }

    if (head_id == g_builtin_syms.galois_closure_atom) {
        if (nargs != 4)
            return grounded_incorrect_arity(a, head, args, nargs);
        for (uint32_t i = 0; i < nargs; i++) {
            if (args[i]->kind != ATOM_EXPR) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(a, head, args, nargs, i + 1,
                                                 atom_expression_type(a),
                                                 args[i]);
                return NULL;
            }
        }
        Atom *objects = args[0];
        Atom *attributes = args[1];
        Atom *columns = args[2];
        Atom *query = args[3];
        if (attributes->expr.len != columns->expr.len) {
            return atom_error(
                a, grounded_call_expr(a, head, args, nargs),
                atom_string(
                    a,
                    "galois-closure-atom expects one object column per attribute"));
        }
        for (CettaExprIndex i = 0; i < columns->expr.len; i++) {
            if (columns->expr.elems[i]->kind != ATOM_EXPR) {
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_string(
                        a,
                        "galois-closure-atom expects every column to be an expression"));
            }
        }

        bool *extent = arena_alloc(a, sizeof(bool) * objects->expr.len);
        for (CettaExprIndex i = 0; i < objects->expr.len; i++)
            extent[i] = true;

        for (CettaExprIndex q = 0; q < query->expr.len; q++) {
            CettaExprIndex column_index = attributes->expr.len;
            for (CettaExprIndex i = 0; i < attributes->expr.len; i++) {
                if (atom_alpha_eq(query->expr.elems[q],
                                  attributes->expr.elems[i])) {
                    column_index = i;
                    break;
                }
            }
            /* Match the MeTTa indexed semantics: out-of-domain attributes do
             * not select a column and therefore do not change the extent. */
            if (column_index == attributes->expr.len)
                continue;
            Atom *column = columns->expr.elems[column_index];
            for (CettaExprIndex i = 0; i < objects->expr.len; i++) {
                if (!extent[i])
                    continue;
                bool present = false;
                for (CettaExprIndex j = 0; j < column->expr.len; j++) {
                    if (atom_alpha_eq(objects->expr.elems[i],
                                      column->expr.elems[j])) {
                        present = true;
                        break;
                    }
                }
                extent[i] = present;
            }
        }

        Atom **closure = arena_alloc(
            a, sizeof(Atom *) * attributes->expr.len);
        CettaExprLen closure_len = 0;
        for (CettaExprIndex c = 0; c < columns->expr.len; c++) {
            Atom *column = columns->expr.elems[c];
            bool contains_extent = true;
            for (CettaExprIndex i = 0;
                 i < objects->expr.len && contains_extent; i++) {
                if (!extent[i])
                    continue;
                bool present = false;
                for (CettaExprIndex j = 0; j < column->expr.len; j++) {
                    if (atom_alpha_eq(objects->expr.elems[i],
                                      column->expr.elems[j])) {
                        present = true;
                        break;
                    }
                }
                contains_extent = present;
            }
            if (contains_extent)
                closure[closure_len++] = attributes->expr.elems[c];
        }
        return atom_expr(a, closure, closure_len);
    }

    if (head_id == g_builtin_syms.galois_intents_atom) {
        if (nargs != 4)
            return grounded_incorrect_arity(a, head, args, nargs);
        for (uint32_t i = 0; i < 3; i++) {
            if (args[i]->kind != ATOM_EXPR) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(a, head, args, nargs, i + 1,
                                                 atom_expression_type(a),
                                                 args[i]);
                return NULL;
            }
        }
        if (args[3]->kind != ATOM_GROUNDED ||
            args[3]->ground.gkind != GV_INT) {
            if (args[3]->kind == ATOM_GROUNDED)
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_symbol(a, "IntegerEnumerationLimitExpected"));
            return NULL;
        }
        Atom *objects = args[0];
        Atom *attributes = args[1];
        Atom *columns = args[2];
        int64_t limit_value = args[3]->ground.ival;
        if (limit_value <= 0) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "PositiveIntegerIsExpected"));
        }
        if (attributes->expr.len != columns->expr.len) {
            return atom_error(
                a, grounded_call_expr(a, head, args, nargs),
                atom_string(
                    a,
                    "galois-intents-atom expects one object column per attribute"));
        }
        for (CettaExprIndex i = 0; i < columns->expr.len; i++) {
            if (columns->expr.elems[i]->kind != ATOM_EXPR) {
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_string(
                        a,
                        "galois-intents-atom expects every column to be an expression"));
            }
        }

        CettaExprLen object_count = objects->expr.len;
        CettaExprLen attribute_count = attributes->expr.len;
        CettaExprLen limit = (CettaExprLen)limit_value;
        if ((int64_t)limit != limit_value ||
            !cetta_expr_len_mul_fits_size(limit, sizeof(Atom *)) ||
            (object_count != 0 &&
             attribute_count > (CettaExprLen)(SIZE_MAX / object_count))) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "EnumerationLimitTooLarge"));
        }

        bool *incidence = galois_boolean_incidence(a, objects, columns);

        bool *current = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *seed = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *candidate = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *extent = arena_alloc(a, sizeof(bool) * object_count);
        CettaExprLen intent_capacity = limit < 16 ? limit : 16;
        Atom **intents = cetta_malloc(
            sizeof(Atom *) * (size_t)intent_capacity);
        memset(seed, 0, sizeof(bool) * attribute_count);
        galois_boolean_closure(object_count, attribute_count, incidence,
                               seed, extent, current);

        CettaExprLen intent_count = 0;
        for (;;) {
            if (intent_count == intent_capacity) {
                CettaExprLen remaining = limit - intent_capacity;
                CettaExprLen growth =
                    intent_capacity < remaining ? intent_capacity : remaining;
                intent_capacity += growth;
                intents = cetta_realloc(
                    intents, sizeof(Atom *) * (size_t)intent_capacity);
            }
            intents[intent_count++] =
                galois_attribute_set_atom(a, attributes, current);

            bool found = false;
            for (CettaExprIndex reverse = attribute_count;
                 reverse > 0 && !found; reverse--) {
                CettaExprIndex pivot = reverse - 1;
                if (current[pivot])
                    continue;
                for (CettaExprIndex attribute = 0;
                     attribute < attribute_count; attribute++) {
                    seed[attribute] =
                        attribute < pivot ? current[attribute] : false;
                }
                seed[pivot] = true;
                galois_boolean_closure(
                    object_count, attribute_count, incidence,
                    seed, extent, candidate);
                bool lectic = true;
                for (CettaExprIndex attribute = 0;
                     attribute < pivot; attribute++) {
                    if (candidate[attribute] && !current[attribute]) {
                        lectic = false;
                        break;
                    }
                }
                if (lectic)
                    found = true;
            }
            if (!found)
                break;
            if (intent_count >= limit) {
                free(intents);
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_symbol(a, "GaloisEnumerationLimitExceeded"));
            }
            memcpy(current, candidate, sizeof(bool) * attribute_count);
        }
        Atom *result = atom_expr(a, intents, intent_count);
        free(intents);
        return result;
    }

    if (head_id == g_builtin_syms.galois_canonical_basis_atom) {
        if (nargs != 5)
            return grounded_incorrect_arity(a, head, args, nargs);
        for (uint32_t i = 0; i < 3; i++) {
            if (args[i]->kind != ATOM_EXPR) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(a, head, args, nargs, i + 1,
                                                 atom_expression_type(a),
                                                 args[i]);
                return NULL;
            }
        }
        for (uint32_t i = 3; i < 5; i++) {
            if (args[i]->kind != ATOM_GROUNDED ||
                args[i]->ground.gkind != GV_INT) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return atom_error(
                        a, grounded_call_expr(a, head, args, nargs),
                        atom_symbol(a, "IntegerEnumerationLimitExpected"));
                return NULL;
            }
        }

        Atom *objects = args[0];
        Atom *attributes = args[1];
        Atom *columns = args[2];
        int64_t candidate_limit_value = args[3]->ground.ival;
        int64_t basis_limit_value = args[4]->ground.ival;
        if (candidate_limit_value <= 0) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "PositiveCandidateLimitExpected"));
        }
        if (basis_limit_value < 0) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "NonnegativeBasisLimitExpected"));
        }
        if (attributes->expr.len != columns->expr.len) {
            return atom_error(
                a, grounded_call_expr(a, head, args, nargs),
                atom_string(
                    a,
                    "galois-canonical-basis-atom expects one object column per attribute"));
        }
        for (CettaExprIndex i = 0; i < columns->expr.len; i++) {
            if (columns->expr.elems[i]->kind != ATOM_EXPR) {
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_string(
                        a,
                        "galois-canonical-basis-atom expects every column to be an expression"));
            }
        }

        CettaExprLen object_count = objects->expr.len;
        CettaExprLen attribute_count = attributes->expr.len;
        CettaExprLen candidate_limit =
            (CettaExprLen)candidate_limit_value;
        CettaExprLen basis_limit = (CettaExprLen)basis_limit_value;
        if ((int64_t)candidate_limit != candidate_limit_value ||
            (int64_t)basis_limit != basis_limit_value ||
            !cetta_expr_len_mul_fits_size(attribute_count, sizeof(bool)) ||
            (object_count != 0 &&
             attribute_count > (CettaExprLen)(SIZE_MAX / object_count))) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "GaloisEnumerationLimitTooLarge"));
        }

        bool *incidence = galois_boolean_incidence(a, objects, columns);
        bool *candidate = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *closure = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *difference = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *extent = arena_alloc(a, sizeof(bool) * object_count);
        memset(candidate, 0, sizeof(bool) * attribute_count);

        GaloisBasisRecord *basis = NULL;
        CettaExprLen basis_count = 0;
        CettaExprLen basis_capacity = 0;
        CettaExprLen candidate_count = 0;

        for (;;) {
            if (candidate_count >= candidate_limit) {
                free(basis);
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_symbol(a, "GaloisCandidateLimitExceeded"));
            }
            candidate_count++;

            galois_boolean_closure(
                object_count, attribute_count, incidence,
                candidate, extent, closure);
            if (!galois_boolean_equal(
                    attribute_count, candidate, closure)) {
                bool respects_prior_basis = true;
                for (CettaExprIndex prior = 0;
                     prior < basis_count && respects_prior_basis; prior++) {
                    bool proper_subset =
                        galois_boolean_subset(
                            attribute_count,
                            basis[prior].antecedent, candidate) &&
                        !galois_boolean_equal(
                            attribute_count,
                            basis[prior].antecedent, candidate);
                    if (proper_subset &&
                        !galois_boolean_subset(
                            attribute_count,
                            basis[prior].closure, candidate))
                        respects_prior_basis = false;
                }

                if (respects_prior_basis) {
                    if (basis_count >= basis_limit) {
                        free(basis);
                        return atom_error(
                            a, grounded_call_expr(a, head, args, nargs),
                            atom_symbol(a, "GaloisBasisLimitExceeded"));
                    }
                    if (basis_count == basis_capacity) {
                        CettaExprLen remaining =
                            basis_limit - basis_capacity;
                        CettaExprLen growth = basis_capacity == 0
                            ? (remaining < 8 ? remaining : 8)
                            : (basis_capacity < remaining
                                ? basis_capacity : remaining);
                        CettaExprLen next_capacity =
                            basis_capacity + growth;
                        if (!cetta_expr_len_mul_fits_size(
                                next_capacity,
                                sizeof(GaloisBasisRecord))) {
                            free(basis);
                            return atom_error(
                                a, grounded_call_expr(a, head, args, nargs),
                                atom_symbol(
                                    a, "GaloisEnumerationLimitTooLarge"));
                        }
                        basis = basis_capacity == 0
                            ? cetta_malloc(
                                sizeof(GaloisBasisRecord) *
                                (size_t)next_capacity)
                            : cetta_realloc(
                                basis,
                                sizeof(GaloisBasisRecord) *
                                (size_t)next_capacity);
                        basis_capacity = next_capacity;
                    }

                    bool *stored_antecedent = arena_alloc(
                        a, sizeof(bool) * attribute_count);
                    bool *stored_closure = arena_alloc(
                        a, sizeof(bool) * attribute_count);
                    memcpy(stored_antecedent, candidate,
                           sizeof(bool) * attribute_count);
                    memcpy(stored_closure, closure,
                           sizeof(bool) * attribute_count);
                    for (CettaExprIndex attribute = 0;
                         attribute < attribute_count; attribute++) {
                        difference[attribute] =
                            closure[attribute] && !candidate[attribute];
                    }
                    Atom *antecedent_atom = galois_attribute_set_atom(
                        a, attributes, candidate);
                    Atom *consequent_atom = galois_attribute_set_atom(
                        a, attributes, difference);
                    basis[basis_count++] = (GaloisBasisRecord){
                        .antecedent = stored_antecedent,
                        .closure = stored_closure,
                        .pair = atom_expr2(
                            a, antecedent_atom, consequent_atom),
                    };
                }
            }

            bool has_next = false;
            for (CettaExprIndex attribute = 0;
                 attribute < attribute_count; attribute++) {
                if (!candidate[attribute]) {
                    candidate[attribute] = true;
                    has_next = true;
                    break;
                }
                candidate[attribute] = false;
            }
            if (!has_next)
                break;
        }

        Atom **pairs = arena_alloc(a, sizeof(Atom *) * basis_count);
        for (CettaExprIndex i = 0; i < basis_count; i++)
            pairs[i] = basis[i].pair;
        Atom *result = atom_expr(a, pairs, basis_count);
        free(basis);
        return result;
    }

    if (head_id == g_builtin_syms.galois_canonical_basis_next_atom) {
        if (nargs != 5)
            return grounded_incorrect_arity(a, head, args, nargs);
        for (uint32_t i = 0; i < 3; i++) {
            if (args[i]->kind != ATOM_EXPR) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return grounded_bad_arg_type(a, head, args, nargs, i + 1,
                                                 atom_expression_type(a),
                                                 args[i]);
                return NULL;
            }
        }
        for (uint32_t i = 3; i < 5; i++) {
            if (args[i]->kind != ATOM_GROUNDED ||
                args[i]->ground.gkind != GV_INT) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return atom_error(
                        a, grounded_call_expr(a, head, args, nargs),
                        atom_symbol(a, "IntegerEnumerationLimitExpected"));
                return NULL;
            }
        }

        Atom *objects = args[0];
        Atom *attributes = args[1];
        Atom *columns = args[2];
        int64_t logical_limit_value = args[3]->ground.ival;
        int64_t basis_limit_value = args[4]->ground.ival;
        if (logical_limit_value <= 0) {
            return atom_error(
                a, grounded_call_expr(a, head, args, nargs),
                atom_symbol(a, "PositiveLogicalClosureLimitExpected"));
        }
        if (basis_limit_value < 0) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "NonnegativeBasisLimitExpected"));
        }
        if (attributes->expr.len != columns->expr.len) {
            return atom_error(
                a, grounded_call_expr(a, head, args, nargs),
                atom_string(
                    a,
                    "galois-canonical-basis-next-atom expects one object column per attribute"));
        }
        for (CettaExprIndex i = 0; i < columns->expr.len; i++) {
            if (columns->expr.elems[i]->kind != ATOM_EXPR) {
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_string(
                        a,
                        "galois-canonical-basis-next-atom expects every column to be an expression"));
            }
        }

        CettaExprLen object_count = objects->expr.len;
        CettaExprLen attribute_count = attributes->expr.len;
        CettaExprLen logical_limit = (CettaExprLen)logical_limit_value;
        CettaExprLen basis_limit = (CettaExprLen)basis_limit_value;
        if ((int64_t)logical_limit != logical_limit_value ||
            (int64_t)basis_limit != basis_limit_value ||
            !cetta_expr_len_mul_fits_size(attribute_count, sizeof(bool)) ||
            (object_count != 0 &&
             attribute_count > (CettaExprLen)(SIZE_MAX / object_count))) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "GaloisEnumerationLimitTooLarge"));
        }

        bool *incidence = galois_boolean_incidence(a, objects, columns);
        bool *current = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *seed = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *candidate = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *closure = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *difference = arena_alloc(a, sizeof(bool) * attribute_count);
        bool *extent = arena_alloc(a, sizeof(bool) * object_count);
        memset(current, 0, sizeof(bool) * attribute_count);

        GaloisBasisRecord *basis = NULL;
        CettaExprLen basis_count = 0;
        CettaExprLen basis_capacity = 0;
        CettaExprLen logical_count = 0;

        for (;;) {
            if (logical_count >= logical_limit) {
                free(basis);
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_symbol(a, "GaloisLogicalClosureLimitExceeded"));
            }
            logical_count++;

            galois_boolean_closure(
                object_count, attribute_count, incidence,
                current, extent, closure);
            if (!galois_boolean_equal(
                    attribute_count, current, closure)) {
                if (basis_count >= basis_limit) {
                    free(basis);
                    return atom_error(
                        a, grounded_call_expr(a, head, args, nargs),
                        atom_symbol(a, "GaloisBasisLimitExceeded"));
                }
                if (basis_count == basis_capacity) {
                    CettaExprLen remaining = basis_limit - basis_capacity;
                    CettaExprLen growth = basis_capacity == 0
                        ? (remaining < 8 ? remaining : 8)
                        : (basis_capacity < remaining
                            ? basis_capacity : remaining);
                    CettaExprLen next_capacity = basis_capacity + growth;
                    if (!cetta_expr_len_mul_fits_size(
                            next_capacity, sizeof(GaloisBasisRecord))) {
                        free(basis);
                        return atom_error(
                            a, grounded_call_expr(a, head, args, nargs),
                            atom_symbol(a, "GaloisEnumerationLimitTooLarge"));
                    }
                    basis = basis_capacity == 0
                        ? cetta_malloc(
                            sizeof(GaloisBasisRecord) *
                            (size_t)next_capacity)
                        : cetta_realloc(
                            basis,
                            sizeof(GaloisBasisRecord) *
                            (size_t)next_capacity);
                    basis_capacity = next_capacity;
                }

                bool *stored_antecedent = arena_alloc(
                    a, sizeof(bool) * attribute_count);
                bool *stored_closure = arena_alloc(
                    a, sizeof(bool) * attribute_count);
                memcpy(stored_antecedent, current,
                       sizeof(bool) * attribute_count);
                memcpy(stored_closure, closure,
                       sizeof(bool) * attribute_count);
                for (CettaExprIndex attribute = 0;
                     attribute < attribute_count; attribute++) {
                    difference[attribute] =
                        closure[attribute] && !current[attribute];
                }
                Atom *antecedent_atom = galois_attribute_set_atom(
                    a, attributes, current);
                Atom *consequent_atom = galois_attribute_set_atom(
                    a, attributes, difference);
                basis[basis_count++] = (GaloisBasisRecord){
                    .antecedent = stored_antecedent,
                    .closure = stored_closure,
                    .pair = atom_expr2(
                        a, antecedent_atom, consequent_atom),
                };
            }

            bool found = false;
            for (CettaExprIndex reverse = attribute_count;
                 reverse > 0 && !found; reverse--) {
                CettaExprIndex pivot = reverse - 1;
                if (current[pivot])
                    continue;
                for (CettaExprIndex attribute = 0;
                     attribute < attribute_count; attribute++) {
                    seed[attribute] =
                        attribute < pivot ? current[attribute] : false;
                }
                seed[pivot] = true;
                galois_boolean_pseudo_closure(
                    attribute_count, basis, basis_count, seed, candidate);
                bool lectic = true;
                for (CettaExprIndex attribute = 0;
                     attribute < pivot; attribute++) {
                    if (candidate[attribute] && !current[attribute]) {
                        lectic = false;
                        break;
                    }
                }
                if (lectic)
                    found = true;
            }
            if (!found)
                break;
            memcpy(current, candidate, sizeof(bool) * attribute_count);
        }

        Atom **pairs = arena_alloc(a, sizeof(Atom *) * basis_count);
        for (CettaExprIndex i = 0; i < basis_count; i++)
            pairs[i] = basis[i].pair;
        Atom *result = atom_expr(a, pairs, basis_count);
        free(basis);
        return result;
    }

    if (head_id == g_builtin_syms.subset_cover_relations_atom) {
        if (nargs != 3)
            return grounded_incorrect_arity(a, head, args, nargs);
        if (args[0]->kind != ATOM_EXPR) {
            if (args[0]->kind == ATOM_GROUNDED)
                return grounded_bad_arg_type(a, head, args, nargs, 1,
                                             atom_expression_type(a), args[0]);
            return NULL;
        }
        for (uint32_t i = 1; i < 3; i++) {
            if (args[i]->kind != ATOM_GROUNDED ||
                args[i]->ground.gkind != GV_INT) {
                if (args[i]->kind == ATOM_GROUNDED)
                    return atom_error(
                        a, grounded_call_expr(a, head, args, nargs),
                        atom_symbol(a, "IntegerEnumerationLimitExpected"));
                return NULL;
            }
        }

        int64_t family_limit_value = args[1]->ground.ival;
        int64_t cover_limit_value = args[2]->ground.ival;
        if (family_limit_value <= 0) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "PositiveFamilyLimitExpected"));
        }
        if (cover_limit_value < 0) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "NonnegativeCoverLimitExpected"));
        }

        CettaExprLen family_limit = (CettaExprLen)family_limit_value;
        CettaExprLen cover_limit = (CettaExprLen)cover_limit_value;
        if ((int64_t)family_limit != family_limit_value ||
            (int64_t)cover_limit != cover_limit_value ||
            !cetta_expr_len_mul_fits_size(cover_limit, sizeof(Atom *))) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "SubsetCoverLimitTooLarge"));
        }

        Atom *family = args[0];
        if (family->expr.len > family_limit) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "SubsetCoverFamilyLimitExceeded"));
        }
        for (CettaExprIndex i = 0; i < family->expr.len; i++) {
            if (family->expr.elems[i]->kind != ATOM_EXPR) {
                return atom_error(
                    a, grounded_call_expr(a, head, args, nargs),
                    atom_string(
                        a,
                        "subset-cover-relations-atom expects a family of expressions"));
            }
        }

        Atom **sets = arena_alloc(
            a, sizeof(Atom *) * (size_t)family->expr.len);
        CettaExprLen set_count = 0;
        for (CettaExprIndex i = 0; i < family->expr.len; i++) {
            Atom *candidate = family->expr.elems[i];
            bool duplicate = false;
            for (CettaExprIndex j = 0; j < set_count; j++) {
                if (expression_set_equal(candidate, sets[j])) {
                    duplicate = true;
                    break;
                }
            }
            if (!duplicate)
                sets[set_count++] = candidate;
        }

        if (set_count != 0 &&
            (size_t)set_count > SIZE_MAX / (size_t)set_count) {
            return atom_error(a, grounded_call_expr(a, head, args, nargs),
                              atom_symbol(a, "SubsetCoverLimitTooLarge"));
        }
        size_t relation_cells = (size_t)set_count * (size_t)set_count;
        bool *strict_subset = cetta_malloc(
            relation_cells == 0 ? 1 : relation_cells * sizeof(bool));
        memset(strict_subset, 0, relation_cells * sizeof(bool));
        for (CettaExprIndex left = 0; left < set_count; left++) {
            for (CettaExprIndex right = 0; right < set_count; right++) {
                if (left == right)
                    continue;
                bool left_subset = expression_set_subset(sets[left], sets[right]);
                strict_subset[(size_t)left * set_count + right] =
                    left_subset && !expression_set_subset(sets[right], sets[left]);
            }
        }

        Atom **covers = NULL;
        CettaExprLen cover_count = 0;
        CettaExprLen cover_capacity = 0;
        for (CettaExprIndex general = 0; general < set_count; general++) {
            for (CettaExprIndex specific = 0; specific < set_count; specific++) {
                if (!strict_subset[(size_t)general * set_count + specific])
                    continue;
                bool has_middle = false;
                for (CettaExprIndex middle = 0;
                     middle < set_count && !has_middle; middle++) {
                    has_middle =
                        strict_subset[(size_t)general * set_count + middle] &&
                        strict_subset[(size_t)middle * set_count + specific];
                }
                if (has_middle)
                    continue;
                if (cover_count >= cover_limit) {
                    free(strict_subset);
                    free(covers);
                    return atom_error(
                        a, grounded_call_expr(a, head, args, nargs),
                        atom_symbol(a, "SubsetCoverLimitExceeded"));
                }
                if (cover_count == cover_capacity) {
                    CettaExprLen remaining = cover_limit - cover_capacity;
                    CettaExprLen growth = cover_capacity == 0
                        ? (remaining < 8 ? remaining : 8)
                        : (cover_capacity < remaining
                            ? cover_capacity : remaining);
                    CettaExprLen next_capacity = cover_capacity + growth;
                    covers = cover_capacity == 0
                        ? cetta_malloc(sizeof(Atom *) * (size_t)next_capacity)
                        : cetta_realloc(
                            covers, sizeof(Atom *) * (size_t)next_capacity);
                    cover_capacity = next_capacity;
                }
                covers[cover_count++] =
                    atom_expr2(a, sets[general], sets[specific]);
            }
        }

        Atom **result_items = arena_alloc(
            a, sizeof(Atom *) * (size_t)cover_count);
        for (CettaExprIndex i = 0; i < cover_count; i++)
            result_items[i] = covers[i];
        Atom *result = atom_expr(a, result_items, cover_count);
        free(strict_subset);
        free(covers);
        return result;
    }

    /* ── Structural equality (any atom type) ───────────────────────────── */
    if (head_id == g_builtin_syms.op_eq && nargs == 2) {
        return atom_eq(args[0], args[1]) ? atom_true(a) : atom_false(a);
    }

    /* ── Boolean ops ───────────────────────────────────────────────────── */
    if (head_id == g_builtin_syms.op_not) {
        if (nargs != 1)
            return grounded_incorrect_arity(a, head, args, nargs);
        bool bv;
        if (get_bool_arg(args[0], &bv))
            return bv ? atom_false(a) : atom_true(a);
        if (args[0]->kind == ATOM_GROUNDED)
            return grounded_bool_bad_arg(a, head, args, nargs, 1, args[0]);
        return NULL;
    }
    if ((head_id == g_builtin_syms.op_and || head_id == g_builtin_syms.op_or || head_id == g_builtin_syms.op_xor) && nargs != 2)
        return grounded_incorrect_arity(a, head, args, nargs);
    if (nargs == 2) {
        bool bx, by;
        if (head_id == g_builtin_syms.op_and || head_id == g_builtin_syms.op_or || head_id == g_builtin_syms.op_xor) {
            bool okx = get_bool_arg(args[0], &bx);
            bool oky = get_bool_arg(args[1], &by);
            if (okx && oky) {
                if (head_id == g_builtin_syms.op_and)
                    return (bx && by) ? atom_true(a) : atom_false(a);
                if (head_id == g_builtin_syms.op_or)
                    return (bx || by) ? atom_true(a) : atom_false(a);
                return (bx != by) ? atom_true(a) : atom_false(a);
            }
            if (!okx && args[0]->kind == ATOM_GROUNDED)
                return grounded_bool_bad_arg(a, head, args, nargs, 1, args[0]);
            if (!oky && args[1]->kind == ATOM_GROUNDED)
                return grounded_bool_bad_arg(a, head, args, nargs, 2, args[1]);
            return NULL;
        }
    }

    /* ── Numeric ops ───────────────────────────────────────────────────── */
    if (nargs != 2) return NULL;

    /* Check if this is an arithmetic op that expects numeric args */
    bool is_arith = (head_id == g_builtin_syms.op_plus || head_id == g_builtin_syms.op_minus ||
                     head_id == g_builtin_syms.op_mul || head_id == g_builtin_syms.op_div ||
                     head_id == g_builtin_syms.op_floor_div ||
                     head_id == g_builtin_syms.op_mod || head_id == g_builtin_syms.op_lt ||
                     head_id == g_builtin_syms.op_gt || head_id == g_builtin_syms.op_le ||
                     head_id == g_builtin_syms.op_ge ||
                     head_id == g_builtin_syms.numeric_eq);
    bool rust_compat = eval_current_uses_rust_he_compat_semantics();
    if (rust_compat && head_id == g_builtin_syms.op_floor_div)
        return NULL;
    NumArg na = {0}, nb = {0};
    bool na_ok = get_numeric_arg(args[0], &na);
    bool nb_ok = get_numeric_arg(args[1], &nb);
    if (is_arith && (!na_ok || !nb_ok)) {
        /* Only produce BadArgType for grounded non-numeric args (like strings).
           For symbols and variables, return NULL (expression unchanged) —
           matches HE behavior where type-checker handles symbols. */
        Atom *bad_arg = !na_ok ? args[0] : args[1];
        if (bad_arg->kind == ATOM_GROUNDED) {
            return grounded_bad_arg_type(a, head, args, nargs,
                                         !na_ok ? 1 : 2,
                                         atom_symbol(a, "Number"),
                                         bad_arg);
        }
        return NULL; /* Symbol/variable args → return unchanged */
    }
    if (!na_ok || !nb_ok)
        return NULL;
    if (rust_compat && (na.is_rational || nb.is_rational))
        return NULL;
    /* Both args are numeric from here */
    if (head_id == g_builtin_syms.numeric_eq) {
        if (na.is_float || nb.is_float)
            return na.val == nb.val ? atom_true(a) : atom_false(a);
#if CETTA_BUILD_WITH_GMP
        if (na.is_bigint || nb.is_bigint ||
            na.is_rational || nb.is_rational) {
            mpq_t ai, bi;
            mpq_inits(ai, bi, NULL);
            bool ok = num_arg_to_mpq(&na, ai) && num_arg_to_mpq(&nb, bi);
            bool eq = ok && mpq_cmp(ai, bi) == 0;
            mpq_clears(ai, bi, NULL);
            return eq ? atom_true(a) : atom_false(a);
        }
#else
        if (na.is_bigint || nb.is_bigint || na.is_rational || nb.is_rational)
            return atom_eq(args[0], args[1]) ? atom_true(a) : atom_false(a);
#endif
        return na.ival == nb.ival ? atom_true(a) : atom_false(a);
    }
    if (head_id == g_builtin_syms.op_mod &&
        (na.is_rational || nb.is_rational)) {
        int bad_idx = na.is_rational ? 1 : 2;
        return grounded_bad_arg_type(a, head, args, nargs,
                                     bad_idx, atom_symbol(a, "Number"),
                                     args[bad_idx - 1]);
    }
    bool fl = na.is_float || nb.is_float;
    bool prefer_rationals = eval_current_prefer_rationals();

    if (!fl && (na.is_bigint || nb.is_bigint ||
                na.is_rational || nb.is_rational)) {
        return eval_integer_binary_gmp(a, head, head_id, args, nargs, &na, &nb,
                                       prefer_rationals, rust_compat);
    }

    if (!fl) {
        int64_t ai = na.ival;
        int64_t bi = nb.ival;

        if (head_id == g_builtin_syms.op_plus) {
            __int128 sum = (__int128)ai + (__int128)bi;
            if (sum >= INT64_MIN && sum <= INT64_MAX)
                return atom_int(a, (int64_t)sum);
            return eval_integer_binary_gmp(a, head, head_id, args, nargs, &na, &nb,
                                           prefer_rationals, rust_compat);
        }
        if (head_id == g_builtin_syms.op_minus) {
            __int128 diff = (__int128)ai - (__int128)bi;
            if (diff >= INT64_MIN && diff <= INT64_MAX)
                return atom_int(a, (int64_t)diff);
            return eval_integer_binary_gmp(a, head, head_id, args, nargs, &na, &nb,
                                           prefer_rationals, rust_compat);
        }
        if (head_id == g_builtin_syms.op_mul) {
            __int128 prod = (__int128)ai * (__int128)bi;
            if (prod >= INT64_MIN && prod <= INT64_MAX)
                return atom_int(a, (int64_t)prod);
            return eval_integer_binary_gmp(a, head, head_id, args, nargs, &na, &nb,
                                           prefer_rationals, rust_compat);
        }
        if (head_id == g_builtin_syms.op_div) {
            if (bi == 0)
                return grounded_division_by_zero(a, head, args, nargs);
            if (ai == INT64_MIN && bi == -1)
                return eval_integer_binary_gmp(a, head, head_id, args, nargs, &na, &nb,
                                               prefer_rationals, rust_compat);
            if (rust_compat)
                return atom_int(a, ai / bi);
            if (ai % bi == 0)
                return atom_int(a, ai / bi);
            if (prefer_rationals)
                return eval_integer_binary_gmp(a, head, head_id, args, nargs, &na, &nb,
                                               prefer_rationals, rust_compat);
            return atom_float(a, (double)ai / (double)bi);
        }
        if (head_id == g_builtin_syms.op_floor_div) {
            if (bi == 0)
                return grounded_division_by_zero(a, head, args, nargs);
            if (ai == INT64_MIN && bi == -1)
                return eval_integer_binary_gmp(a, head, head_id, args, nargs, &na, &nb,
                                               prefer_rationals, rust_compat);
            return atom_int(a, floor_div_i64(ai, bi));
        }
        if (head_id == g_builtin_syms.op_mod) {
            if (bi == 0)
                return grounded_division_by_zero(a, head, args, nargs);
            if (ai == INT64_MIN && bi == -1)
                return atom_int(a, 0);
            return atom_int(a, ai % bi);
        }
        if (head_id == g_builtin_syms.op_lt)  return ai < bi  ? atom_true(a) : atom_false(a);
        if (head_id == g_builtin_syms.op_gt)  return ai > bi  ? atom_true(a) : atom_false(a);
        if (head_id == g_builtin_syms.op_le) return ai <= bi ? atom_true(a) : atom_false(a);
        if (head_id == g_builtin_syms.op_ge) return ai >= bi ? atom_true(a) : atom_false(a);
    }

    if (head_id == g_builtin_syms.op_plus) return make_numeric(a, na.val + nb.val, fl);
    if (head_id == g_builtin_syms.op_minus) return make_numeric(a, na.val - nb.val, fl);
    if (head_id == g_builtin_syms.op_mul) return make_numeric(a, na.val * nb.val, fl);
    /* Keep IEEE float division semantics so `isnan-math` / `isinf-math`
       remain usable on direct arithmetic results. */
    if (head_id == g_builtin_syms.op_div) return nb.val != 0 ? make_numeric(a, na.val / nb.val, fl)
                                                              : atom_float(a, na.val / nb.val);
    if (head_id == g_builtin_syms.op_floor_div) return nb.val != 0 ? atom_float(a, floor(na.val / nb.val))
                                                                   : grounded_division_by_zero(a, head, args, nargs);
    if (head_id == g_builtin_syms.op_mod) return nb.val != 0 ? make_numeric(a, fmod(na.val, nb.val), fl)
                                                              : grounded_division_by_zero(a, head, args, nargs);
    if (head_id == g_builtin_syms.op_lt)  return na.val < nb.val  ? atom_true(a) : atom_false(a);
    if (head_id == g_builtin_syms.op_gt)  return na.val > nb.val  ? atom_true(a) : atom_false(a);
    if (head_id == g_builtin_syms.op_le) return na.val <= nb.val ? atom_true(a) : atom_false(a);
    if (head_id == g_builtin_syms.op_ge) return na.val >= nb.val ? atom_true(a) : atom_false(a);

    return NULL;
}
