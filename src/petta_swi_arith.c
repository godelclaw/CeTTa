/*
 * SWI-Prolog's arithmetic for PeTTa, natively, in a build with no embedded
 * Prolog.
 *
 * PeTTa arithmetic that CeTTa's native fast path does not finish (an operand
 * that is not a number, a zero divisor, an exceptional float, mod of a
 * non-integer, a function outside its domain, a rational in a mixed float
 * comparison) is SWI-Prolog's is/2 or comparison, as in the reference.  A
 * build with SWI asks the embedded engine (petta_libpl.c); this file answers
 * the same questions without one, with the same values and the same errors,
 * so a program answers alike in both builds.
 *
 * It follows SWI-Prolog 10's pl-arith.c and pl-gmp.c under the reference's
 * flags: prefer_rationals and iso false; float_overflow, float_zero_div and
 * float_undefined error; float_underflow ignore; max_rational_size
 * unlimited; rounding to nearest.  Errors are the terms SWI raises, as the
 * Prolog build carries them back: (Error Formal Context), compounds kept as
 * Prolog compounds.
 */
#define _GNU_SOURCE
#include "petta_libpl.h"

#include <float.h>
#include <math.h>
#include <string.h>
#include <sys/random.h>
#include <time.h>

#if CETTA_BUILD_WITH_GMP

typedef enum {
    SWI_INTEGER = 0,
    SWI_MPZ,
    SWI_MPQ,
    SWI_FLOAT,
} SwiNumType;

/* SWI's number: the types are ordered as promotion goes. */
typedef struct {
    SwiNumType type;
    union {
        int64_t i;
        mpz_t mpz;
        mpq_t mpq;
        double f;
    } value;
} SwiNum;

typedef struct {
    Arena *arena;
    /* The predicate an error raised outside a named function reports:
     * is, or the comparison. */
    const char *predicate;
    Atom *raised;
    bool declined;
} SwiEval;

typedef enum {
    SWI_CMP_LESS = -1,
    SWI_CMP_EQUAL = 0,
    SWI_CMP_GREATER = 1,
    SWI_CMP_NOTEQ = 2,
} SwiOrder;

static void swi_clear(SwiNum *n) {
    if (n->type == SWI_MPZ)
        mpz_clear(n->value.mpz);
    else if (n->type == SWI_MPQ)
        mpq_clear(n->value.mpq);
    n->type = SWI_INTEGER;
    n->value.i = 0;
}

static void swi_copy(SwiNum *to, const SwiNum *from) {
    to->type = from->type;
    switch (from->type) {
    case SWI_INTEGER:
        to->value.i = from->value.i;
        break;
    case SWI_MPZ:
        mpz_init_set(to->value.mpz, from->value.mpz);
        break;
    case SWI_MPQ:
        mpq_init(to->value.mpq);
        mpq_set(to->value.mpq, from->value.mpq);
        break;
    case SWI_FLOAT:
        to->value.f = from->value.f;
        break;
    }
}

/* ── Errors, as the Prolog build carries SWI's back ───────────────────── */

static Atom *swi_compound(Arena *arena, Atom **items, CettaExprLen count) {
    for (CettaExprLen index = 0u; index < count; index++) {
        if (!items[index])
            return NULL;
    }
    Atom *body = atom_expr(arena, items, count);
    return body ? atom_petta_prolog_compound(arena, body) : NULL;
}

static Atom *swi_data(Arena *arena, const char *name) {
    return atom_symbol_data_n(arena, name, (uint32_t)strlen(name));
}

/* Name/Arity, the name a Prolog atom. */
static Atom *swi_indicator(Arena *arena, Atom *name, int64_t arity) {
    return swi_compound(arena, (Atom *[]){
        atom_symbol(arena, "/"), name, atom_int(arena, arity)}, 3u);
}

/* error(Formal, context(Where, _)).  Where is FUNCTION/ARITY for an error a
 * named function raises, else system:PREDICATE/2. */
static bool swi_raise(SwiEval *eval, Atom *formal, const char *function,
                      int64_t arity) {
    Arena *arena = eval->arena;
    Atom *where = function
        ? swi_indicator(arena, swi_data(arena, function), arity)
        : swi_compound(arena, (Atom *[]){
              atom_symbol(arena, ":"), swi_data(arena, "system"),
              swi_indicator(arena, swi_data(arena, eval->predicate), 2)},
              3u);
    Atom *context = swi_compound(arena, (Atom *[]){
        atom_symbol(arena, "context"), where,
        atom_var_with_id(arena, "$foreign", fresh_var_id())}, 3u);
    Atom *head = atom_symbol(arena, "Error");
    eval->raised = formal && context && head
        ? atom_expr3(arena, head, formal, context) : NULL;
    if (!eval->raised)
        eval->declined = true;
    return false;
}

static bool swi_raise_evaluation(SwiEval *eval, const char *which,
                                 const char *function, int64_t arity) {
    Arena *arena = eval->arena;
    return swi_raise(eval, swi_compound(arena, (Atom *[]){
        atom_symbol(arena, "evaluation_error"), swi_data(arena, which)}, 2u),
        function, arity);
}

static Atom *swi_number_atom(Arena *arena, const SwiNum *n);

static bool swi_raise_type_integer(SwiEval *eval, const SwiNum *culprit,
                                   const char *function) {
    Arena *arena = eval->arena;
    return swi_raise(eval, swi_compound(arena, (Atom *[]){
        atom_symbol(arena, "type_error"), swi_data(arena, "integer"),
        swi_number_atom(arena, culprit)}, 3u), function, 2);
}

/* check_float: NaN is undefined, an infinity an overflow; a subnormal
 * underflows, which the reference ignores. */
static bool swi_check_float(SwiEval *eval, SwiNum *n) {
    switch (fpclassify(n->value.f)) {
    case FP_NAN:
        n->value.f = NAN;
        return swi_raise_evaluation(eval, "undefined", NULL, 0);
    case FP_INFINITE:
        return swi_raise_evaluation(eval, "float_overflow", NULL, 0);
    default:
        return true;
    }
}

/* check_zero_div, with float_zero_div and float_undefined both error. */
static bool swi_zero_div(SwiEval *eval, const char *function, int64_t arity) {
    return swi_raise_evaluation(eval, "zero_divisor", function, arity);
}

/* ── Conversion, rounding to nearest (pl-gmp.c) ───────────────────────── */

static double swi_mpz_fdiv(const mpz_t a, const mpz_t b) {
    size_t sa = mpz_sizeinbase(a, 2);
    size_t sb = mpz_sizeinbase(b, 2);
    if (sa <= 53u && sb <= 53u)
        return mpz_get_d(a) / mpz_get_d(b);
    size_t na = sa - mpz_scan1(a, 0);
    size_t nb = sb - mpz_scan1(b, 0);
    if (sa <= 1024u && na <= 53u && sb <= 1024u && nb <= 53u)
        return mpz_get_d(a) / mpz_get_d(b);
    mpz_t aa, bb;
    mpz_init(aa);
    mpz_init(bb);
    if (sa >= sb) {
        mpz_set(aa, a);
        mpz_mul_2exp(bb, b, sa - sb);
    } else {
        mpz_mul_2exp(aa, a, sb - sa);
        mpz_set(bb, b);
    }
    if (mpz_cmpabs(aa, bb) >= 0) {
        mpz_mul_2exp(bb, bb, 1);
        sa++;
    }
    mpz_mul_2exp(aa, aa, 54);
    sb += 54u;
    mpz_tdiv_qr(aa, bb, aa, bb);
    /* aa has 54 bits: round its last to nearest, ties to even. */
    if (mpz_tstbit(aa, 0) == 0) {
    } else if (mpz_sgn(bb) != 0) {
        if (mpz_sgn(aa) > 0)
            mpz_add_ui(aa, aa, 1);
        else
            mpz_sub_ui(aa, aa, 1);
    } else if (mpz_tstbit(aa, 1) == 0) {
        if (mpz_sgn(aa) > 0)
            mpz_sub_ui(aa, aa, 1);
        else
            mpz_add_ui(aa, aa, 1);
    } else {
        if (mpz_sgn(aa) > 0)
            mpz_add_ui(aa, aa, 1);
        else
            mpz_sub_ui(aa, aa, 1);
    }
    double d = mpz_get_d(aa);
    mpz_clear(aa);
    mpz_clear(bb);
    return ldexp(d, (int)((long)sa - (long)sb));
}

static double swi_mpz_to_double(const mpz_t a) {
    double d = mpz_get_d(a);
    size_t sa = mpz_sizeinbase(a, 2);
    size_t na = mpz_scan1(a, 0);
    if (isinf(d) || sa - na <= 53u)
        return d;
    int bit54 = mpz_tstbit(a, sa - 54u);
    bool trailing_zeros = na >= sa - 54u;
    if (d > 0) {
        if (!bit54) {
        } else if (!trailing_zeros || mpz_tstbit(a, sa - 53u) == 1) {
            d = nexttoward(d, INFINITY);
        }
    } else {
        if (bit54 && !trailing_zeros) {
        } else if (!trailing_zeros || mpz_tstbit(a, sa - 53u) == 0) {
            d = nexttoward(d, -INFINITY);
        }
    }
    return d;
}

static bool swi_promote_to_float(SwiEval *eval, SwiNum *n) {
    double value;
    switch (n->type) {
    case SWI_INTEGER:
        value = (double)n->value.i;
        break;
    case SWI_MPZ:
        value = swi_mpz_to_double(n->value.mpz);
        break;
    case SWI_MPQ:
        value = swi_mpz_fdiv(mpq_numref(n->value.mpq),
                             mpq_denref(n->value.mpq));
        break;
    case SWI_FLOAT:
    default:
        return true;
    }
    swi_clear(n);
    n->type = SWI_FLOAT;
    n->value.f = value;
    return swi_check_float(eval, n);
}

static void swi_promote_to_mpz(SwiNum *n) {
    if (n->type == SWI_INTEGER) {
        int64_t value = n->value.i;
        mpz_init_set_si(n->value.mpz, (long)value);
        n->type = SWI_MPZ;
    }
}

static void swi_promote_to_mpq(SwiNum *n) {
    if (n->type == SWI_INTEGER) {
        int64_t value = n->value.i;
        mpq_init(n->value.mpq);
        mpq_set_si(n->value.mpq, (long)value, 1u);
        n->type = SWI_MPQ;
    } else if (n->type == SWI_MPZ) {
        mpz_t value;
        mpz_init_set(value, n->value.mpz);
        mpz_clear(n->value.mpz);
        mpq_init(n->value.mpq);
        mpq_set_z(n->value.mpq, value);
        mpz_clear(value);
        n->type = SWI_MPQ;
    }
}

static bool swi_promote(SwiEval *eval, SwiNum *n, SwiNumType type) {
    switch (type) {
    case SWI_INTEGER:
        return true;
    case SWI_MPZ:
        swi_promote_to_mpz(n);
        return true;
    case SWI_MPQ:
        swi_promote_to_mpq(n);
        return true;
    case SWI_FLOAT:
        return swi_promote_to_float(eval, n);
    }
    return false;
}

static bool swi_same_type(SwiEval *eval, SwiNum *n1, SwiNum *n2) {
    if (n1->type == n2->type)
        return true;
    return n1->type > n2->type ? swi_promote(eval, n2, n1->type)
                               : swi_promote(eval, n1, n2->type);
}

/* An MPZ or MPQ result as SWI keeps it: an integer in range is small, a
 * rational with denominator 1 an integer. */
static void swi_normalize(SwiNum *n) {
    if (n->type == SWI_MPQ) {
        mpq_canonicalize(n->value.mpq);
        if (mpz_cmp_ui(mpq_denref(n->value.mpq), 1u) != 0)
            return;
        mpz_t value;
        mpz_init_set(value, mpq_numref(n->value.mpq));
        mpq_clear(n->value.mpq);
        mpz_init_set(n->value.mpz, value);
        mpz_clear(value);
        n->type = SWI_MPZ;
    }
    if (n->type == SWI_MPZ && mpz_fits_slong_p(n->value.mpz)) {
        int64_t value = (int64_t)mpz_get_si(n->value.mpz);
        mpz_clear(n->value.mpz);
        n->type = SWI_INTEGER;
        n->value.i = value;
    }
}

static Atom *swi_number_atom(Arena *arena, const SwiNum *n) {
    switch (n->type) {
    case SWI_INTEGER:
        return atom_int(arena, n->value.i);
    case SWI_MPZ:
        return atom_bigint_from_mpz(arena, n->value.mpz);
    case SWI_MPQ:
        return atom_rational_from_mpq(arena, n->value.mpq);
    case SWI_FLOAT:
        return atom_float(arena, n->value.f);
    }
    return NULL;
}

/* ── Operands ──────────────────────────────────────────────────────────── */

static double swi_random_float(void) {
    double value = 0.0;
    while (value == 0.0) {
        uint64_t bits = 0u;
        if (getrandom(&bits, sizeof(bits), 0) != (ssize_t)sizeof(bits))
            bits = (uint64_t)time(NULL) * UINT64_C(0x9e3779b97f4a7c15);
        value = (double)(bits >> 11u) * 0x1.0p-53;
    }
    return value;
}

/* SWI's arithmetic constants: the atoms its is/2 evaluates. */
static bool swi_constant(const char *name, uint32_t length, double *value) {
    struct timespec now;
    if (length == 2u && memcmp(name, "pi", 2u) == 0) {
        *value = M_PI;
    } else if (length == 1u && name[0] == 'e') {
        *value = M_E;
    } else if (length == 7u && memcmp(name, "epsilon", 7u) == 0) {
        *value = DBL_EPSILON;
    } else if (length == 3u && memcmp(name, "inf", 3u) == 0) {
        *value = INFINITY;
    } else if (length == 3u && memcmp(name, "nan", 3u) == 0) {
        *value = NAN;
    } else if (length == 7u && memcmp(name, "cputime", 7u) == 0) {
        *value = clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &now) == 0
            ? (double)now.tv_sec + (double)now.tv_nsec / 1e9 : 0.0;
    } else if (length == 12u && memcmp(name, "random_float", 12u) == 0) {
        *value = swi_random_float();
    } else {
        return false;
    }
    return true;
}

static bool swi_raise_not_evaluable(SwiEval *eval, Atom *name) {
    Arena *arena = eval->arena;
    return swi_raise(eval, swi_compound(arena, (Atom *[]){
        atom_symbol(arena, "type_error"), swi_data(arena, "evaluable"),
        swi_indicator(arena, name, 0)}, 3u), NULL, 0);
}

/* The value SWI evaluates an argument to, as the Prolog build passes it: a
 * symbol is an atom, a Boolean the atom true or false, an unbound variable
 * a variable.  Other grounded values do not cross; the bridge declines. */
static bool swi_operand(SwiEval *eval, Atom *operand, SwiNum *out) {
    Arena *arena = eval->arena;
    out->type = SWI_INTEGER;
    out->value.i = 0;
    switch (operand->kind) {
    case ATOM_VAR:
        return swi_raise(eval, swi_data(arena, "instantiation_error"),
                         NULL, 0);
    case ATOM_SYMBOL: {
        const char *name = atom_symbol_bytes(operand);
        uint32_t length = atom_symbol_length(operand);
        double value = 0.0;
        if (name && swi_constant(name, length, &value)) {
            out->type = SWI_FLOAT;
            out->value.f = value;
            return true;
        }
        return swi_raise_not_evaluable(
            eval, name ? atom_symbol_data_n(arena, name, length) : NULL);
    }
    case ATOM_GROUNDED:
        switch (operand->ground.gkind) {
        case GV_INT:
            out->value.i = operand->ground.ival;
            return true;
        case GV_FLOAT:
            out->type = SWI_FLOAT;
            out->value.f = operand->ground.fval;
            return true;
        case GV_BIGINT:
            mpz_init(out->value.mpz);
            out->type = SWI_MPZ;
            if (!atom_bigint_get_mpz(operand, out->value.mpz)) {
                swi_clear(out);
                eval->declined = true;
                return false;
            }
            swi_normalize(out);
            return true;
        case GV_RATIONAL:
            mpq_init(out->value.mpq);
            out->type = SWI_MPQ;
            if (!atom_rational_get_mpq(operand, out->value.mpq)) {
                swi_clear(out);
                eval->declined = true;
                return false;
            }
            swi_normalize(out);
            return true;
        case GV_BOOL:
            return swi_raise_not_evaluable(
                eval, swi_data(arena, operand->ground.bval ? "true" : "false"));
        default:
            break;
        }
        break;
    case ATOM_EXPR:
        break;
    }
    eval->declined = true;
    return false;
}

/* ── Functions (pl-arith.c) ────────────────────────────────────────────── */

static bool swi_add(SwiEval *eval, SwiNum *n1, SwiNum *n2, SwiNum *r) {
    if (!swi_same_type(eval, n1, n2))
        return false;
    switch (n1->type) {
    case SWI_INTEGER:
        if (!__builtin_add_overflow(n1->value.i, n2->value.i, &r->value.i)) {
            r->type = SWI_INTEGER;
            return true;
        }
        swi_promote_to_mpz(n1);
        swi_promote_to_mpz(n2);
        /* FALLTHROUGH */
    case SWI_MPZ:
        r->type = SWI_MPZ;
        mpz_init(r->value.mpz);
        mpz_add(r->value.mpz, n1->value.mpz, n2->value.mpz);
        return true;
    case SWI_MPQ:
        r->type = SWI_MPQ;
        mpq_init(r->value.mpq);
        mpq_add(r->value.mpq, n1->value.mpq, n2->value.mpq);
        return true;
    case SWI_FLOAT:
        r->type = SWI_FLOAT;
        r->value.f = n1->value.f + n2->value.f;
        return swi_check_float(eval, r);
    }
    return false;
}

static bool swi_minus(SwiEval *eval, SwiNum *n1, SwiNum *n2, SwiNum *r) {
    if (!swi_same_type(eval, n1, n2))
        return false;
    switch (n1->type) {
    case SWI_INTEGER:
        if (!__builtin_sub_overflow(n1->value.i, n2->value.i, &r->value.i)) {
            r->type = SWI_INTEGER;
            return true;
        }
        swi_promote_to_mpz(n1);
        swi_promote_to_mpz(n2);
        /* FALLTHROUGH */
    case SWI_MPZ:
        r->type = SWI_MPZ;
        mpz_init(r->value.mpz);
        mpz_sub(r->value.mpz, n1->value.mpz, n2->value.mpz);
        return true;
    case SWI_MPQ:
        r->type = SWI_MPQ;
        mpq_init(r->value.mpq);
        mpq_sub(r->value.mpq, n1->value.mpq, n2->value.mpq);
        return true;
    case SWI_FLOAT:
        r->type = SWI_FLOAT;
        r->value.f = n1->value.f - n2->value.f;
        return swi_check_float(eval, r);
    }
    return false;
}

static bool swi_mul(SwiEval *eval, SwiNum *n1, SwiNum *n2, SwiNum *r) {
    if (!swi_same_type(eval, n1, n2))
        return false;
    switch (n1->type) {
    case SWI_INTEGER:
        if (!__builtin_mul_overflow(n1->value.i, n2->value.i, &r->value.i)) {
            r->type = SWI_INTEGER;
            return true;
        }
        swi_promote_to_mpz(n1);
        swi_promote_to_mpz(n2);
        /* FALLTHROUGH */
    case SWI_MPZ:
        r->type = SWI_MPZ;
        mpz_init(r->value.mpz);
        mpz_mul(r->value.mpz, n1->value.mpz, n2->value.mpz);
        return true;
    case SWI_MPQ:
        r->type = SWI_MPQ;
        mpq_init(r->value.mpq);
        mpq_mul(r->value.mpq, n1->value.mpq, n2->value.mpq);
        return true;
    case SWI_FLOAT:
        r->type = SWI_FLOAT;
        r->value.f = n1->value.f * n2->value.f;
        return swi_check_float(eval, r);
    }
    return false;
}

static int swi_sign_f(double f) {
    return f < 0 ? -1 : f > 0 ? 1 : 0;
}

static int swi_sign_i(const SwiNum *n) {
    switch (n->type) {
    case SWI_INTEGER:
        return n->value.i < 0 ? -1 : n->value.i > 0 ? 1 : 0;
    case SWI_MPZ:
        return mpz_sgn(n->value.mpz);
    case SWI_MPQ:
        return mpq_sgn(n->value.mpq);
    case SWI_FLOAT:
        return swi_sign_f(n->value.f);
    }
    return 0;
}

static bool swi_divide(SwiEval *eval, SwiNum *n1, SwiNum *n2, SwiNum *r) {
    if (n2->type == SWI_FLOAT && isinf(n2->value.f)) {
        if (n1->type == SWI_FLOAT) {
            r->type = SWI_FLOAT;
            r->value.f = isfinite(n1->value.f)
                ? 0.0 * swi_sign_f(n1->value.f) * swi_sign_f(n2->value.f)
                : NAN;
            return swi_check_float(eval, r);
        }
        r->type = SWI_INTEGER;
        r->value.i = 0;
        return true;
    }
    if (!swi_same_type(eval, n1, n2))
        return false;
    switch (n1->type) {
    case SWI_INTEGER:
        if (n2->value.i == 0)
            return swi_zero_div(eval, "/", 2);
        if (n2->value.i == -1 && n1->value.i == INT64_MIN) {
            r->type = SWI_MPZ;
            mpz_init_set_si(r->value.mpz, (long)n1->value.i);
            mpz_neg(r->value.mpz, r->value.mpz);
            return true;
        }
        if (n1->value.i % n2->value.i == 0) {
            r->type = SWI_INTEGER;
            r->value.i = n1->value.i / n2->value.i;
            return true;
        }
        break;
    case SWI_MPZ:
        if (mpz_sgn(n2->value.mpz) == 0)
            return swi_zero_div(eval, "/", 2);
        if (mpz_divisible_p(n1->value.mpz, n2->value.mpz)) {
            r->type = SWI_MPZ;
            mpz_init(r->value.mpz);
            mpz_divexact(r->value.mpz, n1->value.mpz, n2->value.mpz);
            return true;
        }
        break;
    case SWI_MPQ:
        if (mpq_sgn(n2->value.mpq) == 0)
            return swi_zero_div(eval, "/", 2);
        r->type = SWI_MPQ;
        mpq_init(r->value.mpq);
        mpq_div(r->value.mpq, n1->value.mpq, n2->value.mpq);
        return true;
    case SWI_FLOAT:
        break;
    }
    if (!swi_promote_to_float(eval, n1) || !swi_promote_to_float(eval, n2))
        return false;
    if (n2->value.f == 0.0 && swi_sign_f(n1->value.f) != 0)
        return swi_zero_div(eval, "/", 2);
    r->type = SWI_FLOAT;
    r->value.f = n1->value.f / n2->value.f;
    return swi_check_float(eval, r);
}

/* toIntegerNumber(n, 0): an integer, or a rational that is one.  A float
 * is checked first, so a NaN or an infinity raises as such. */
static bool swi_to_integer(SwiEval *eval, SwiNum *n, bool *raised) {
    *raised = false;
    switch (n->type) {
    case SWI_INTEGER:
    case SWI_MPZ:
        return true;
    case SWI_MPQ:
        if (mpz_cmp_ui(mpq_denref(n->value.mpq), 1u) == 0) {
            swi_normalize(n);
            return true;
        }
        return false;
    case SWI_FLOAT:
        *raised = !swi_check_float(eval, n);
        return false;
    }
    return false;
}

static bool swi_mod(SwiEval *eval, SwiNum *n1, SwiNum *n2, SwiNum *r) {
    bool raised = false;
    if (!swi_to_integer(eval, n1, &raised))
        return raised ? false : swi_raise_type_integer(eval, n1, "mod");
    if (!swi_to_integer(eval, n2, &raised))
        return raised ? false : swi_raise_type_integer(eval, n2, "mod");
    if (!swi_same_type(eval, n1, n2))
        return false;
    if (n1->type == SWI_INTEGER) {
        if (n2->value.i == 0)
            return swi_zero_div(eval, "mod", 2);
        r->type = SWI_INTEGER;
        if (n2->value.i == -1 && n1->value.i == INT64_MIN) {
            r->value.i = 0;
        } else {
            int64_t m = n1->value.i % n2->value.i;
            if (m != 0 && (m < 0) != (n2->value.i < 0))
                m += n2->value.i;
            r->value.i = m;
        }
        return true;
    }
    if (mpz_sgn(n2->value.mpz) == 0)
        return swi_zero_div(eval, "mod", 2);
    r->type = SWI_MPZ;
    mpz_init(r->value.mpz);
    mpz_fdiv_r(r->value.mpz, n1->value.mpz, n2->value.mpz);
    return true;
}

static bool swi_is_integer(const SwiNum *n) {
    return n->type == SWI_INTEGER || n->type == SWI_MPZ;
}

static bool swi_even(const SwiNum *n) {
    return n->type == SWI_INTEGER ? n->value.i % 2 == 0
                                  : mpz_fdiv_ui(n->value.mpz, 2) == 0;
}

/* -1, 0 or 1. */
static bool swi_smallint(const SwiNum *n, int *value) {
    if (n->type == SWI_INTEGER) {
        if (n->value.i < -1 || n->value.i > 1)
            return false;
        *value = (int)n->value.i;
        return true;
    }
    if (mpz_cmp_si(n->value.mpz, -1) < 0 || mpz_cmp_si(n->value.mpz, 1) > 0)
        return false;
    *value = (int)mpz_get_si(n->value.mpz);
    return true;
}

/* The absolute exponent, which must fit an unsigned long: a larger one
 * makes an integer no stack holds, and SWI raises a resource error, which
 * this port declines to the native path. */
static bool swi_int_exponent(SwiEval *eval, const SwiNum *n,
                             unsigned long *exponent) {
    int64_t value;
    if (n->type == SWI_INTEGER) {
        value = n->value.i;
    } else if (mpz_fits_slong_p(n->value.mpz)) {
        value = (int64_t)mpz_get_si(n->value.mpz);
    } else {
        eval->declined = true;
        return false;
    }
    if (value < 0) {
        if (value == INT64_MIN) {
            eval->declined = true;
            return false;
        }
        value = -value;
    }
    *exponent = (unsigned long)value;
    return true;
}

/* Whether a power of a `bits`-bit integer to `exponent` is one SWI computes
 * (its result fits the global stack limit); past that it raises a resource
 * error. */
static bool swi_power_small(size_t bits, unsigned long exponent) {
    return (unsigned __int128)bits * exponent <=
           (unsigned __int128)(UINT64_C(1) << 33);
}

static bool swi_power_fits(SwiEval *eval, size_t bits, unsigned long exponent) {
    if (swi_power_small(bits, exponent))
        return true;
    eval->declined = true;
    return false;
}

/* doreal: both as floats; a zero base to a negative power divides by zero. */
static bool swi_pow_real(SwiEval *eval, SwiNum *n1, SwiNum *n2, SwiNum *r,
                         int exp_sign) {
    if (!swi_promote_to_float(eval, n1) || !swi_promote_to_float(eval, n2))
        return false;
    if (n1->value.f == 0.0 && exp_sign == -1)
        return swi_zero_div(eval, "**", 2);
    r->type = SWI_FLOAT;
    r->value.f = n1->value.f == 1.0 ? 1.0 : pow(n1->value.f, n2->value.f);
    return swi_check_float(eval, r);
}

/* doreal_mpq: a float base to a rational exponent, |base| raised and the
 * sign kept where the exponent's numerator is odd.  N2 holds |exponent|. */
static bool swi_pow_real_rational(SwiEval *eval, SwiNum *n1, SwiNum *n2,
                                  SwiNum *r, int exp_sign) {
    bool negative = n1->value.f < 0.0 &&
                    (mpz_get_ui(mpq_numref(n2->value.mpq)) & 1u);
    double base = fabs(n1->value.f);
    if (exp_sign == -1)
        mpq_neg(n2->value.mpq, n2->value.mpq);
    if (!swi_promote_to_float(eval, n2))
        return false;
    r->type = SWI_FLOAT;
    r->value.f = pow(base, n2->value.f);
    if (negative)
        r->value.f = -r->value.f;
    return swi_check_float(eval, r);
}

/* Z to an exact power num/den: Z's den-th root, if exact, to num, inverted
 * for a negative exponent.  False where the root is inexact or the power
 * too large, which SWI computes as floats. */
static bool swi_exact_root_power(mpz_t z, unsigned long den, const mpz_t num) {
    if (!mpz_root(z, z, den) || !mpz_fits_ulong_p(num))
        return false;
    unsigned long power = mpz_get_ui(num);
    if (mpz_cmpabs_ui(z, 1u) > 0 &&
        !swi_power_small(mpz_sizeinbase(z, 2), power))
        return false;
    mpz_pow_ui(z, z, power);
    return true;
}

/* X ** rational. */
static bool swi_pow_rational(SwiEval *eval, SwiNum *n1, SwiNum *n2,
                             SwiNum *r, int exp_sign) {
    if (exp_sign == -1)
        mpz_neg(mpq_numref(n2->value.mpq), mpq_numref(n2->value.mpq));
    bool real = !mpz_fits_ulong_p(mpq_denref(n2->value.mpq));
    unsigned long den = real ? 0u : mpz_get_ui(mpq_denref(n2->value.mpq));
    if (!real && swi_is_integer(n1)) {
        swi_promote_to_mpz(n1);
        if (mpz_sgn(n1->value.mpz) < 0 && !(den & 1u)) {
            r->type = SWI_FLOAT;
            r->value.f = NAN;
            return swi_check_float(eval, r);
        }
        mpz_t z;
        mpz_init_set(z, n1->value.mpz);
        if (swi_exact_root_power(z, den, mpq_numref(n2->value.mpq))) {
            if (exp_sign == -1) {
                r->type = SWI_MPQ;
                mpq_init(r->value.mpq);
                mpq_set_z(r->value.mpq, z);
                mpq_inv(r->value.mpq, r->value.mpq);
            } else {
                r->type = SWI_MPZ;
                mpz_init_set(r->value.mpz, z);
            }
            mpz_clear(z);
            return true;
        }
        mpz_clear(z);
        real = true;
    } else if (!real && n1->type == SWI_MPQ) {
        if (mpq_sgn(n1->value.mpq) < 0 && !(den & 1u)) {
            r->type = SWI_FLOAT;
            r->value.f = NAN;
            return swi_check_float(eval, r);
        }
        mpz_t num, dnm;
        mpz_init_set(num, mpq_numref(n1->value.mpq));
        mpz_init_set(dnm, mpq_denref(n1->value.mpq));
        if (swi_exact_root_power(num, den, mpq_numref(n2->value.mpq)) &&
            swi_exact_root_power(dnm, den, mpq_numref(n2->value.mpq))) {
            r->type = SWI_MPQ;
            mpq_init(r->value.mpq);
            mpz_set(mpq_numref(r->value.mpq), num);
            mpz_set(mpq_denref(r->value.mpq), dnm);
            mpq_canonicalize(r->value.mpq);
            if (exp_sign == -1)
                mpq_inv(r->value.mpq, r->value.mpq);
            mpz_clear(num);
            mpz_clear(dnm);
            return true;
        }
        mpz_clear(num);
        mpz_clear(dnm);
        real = true;
    } else if (!real && n1->type == SWI_FLOAT) {
        if (n1->value.f == 0.0)
            return swi_pow_real(eval, n1, n2, r, exp_sign);
        if (n1->value.f < 0.0 && !(den & 1u)) {
            r->type = SWI_FLOAT;
            r->value.f = NAN;
            return swi_check_float(eval, r);
        }
    }
    /* maybe_real_mpq: the base as a float, then doreal_mpq. */
    if (real && !swi_promote_to_float(eval, n1))
        return false;
    return swi_pow_real_rational(eval, n1, n2, r, exp_sign);
}

static bool swi_pow(SwiEval *eval, SwiNum *n1, SwiNum *n2, SwiNum *r) {
    bool exp_nan = false;
    int exp_sign;
    if (n2->type == SWI_FLOAT) {
        exp_nan = isnan(n2->value.f);
        exp_sign = swi_sign_f(n2->value.f);
    } else {
        exp_sign = swi_sign_i(n2);
    }
    r->type = SWI_INTEGER;
    if (exp_sign == 0 && !exp_nan) {
        r->value.i = 1;
        return true;
    }
    int small = 0;
    if (swi_is_integer(n1) && swi_smallint(n1, &small)) {
        if (small == 1) {
            r->value.i = 1;
            return true;
        }
        if (small == 0 && !exp_nan) {
            if (exp_sign > 0) {
                r->value.i = 0;
                return true;
            }
            return swi_zero_div(eval, "**", 2);
        }
        if (small == -1 && swi_is_integer(n2)) {
            r->value.i = swi_even(n2) ? 1 : -1;
            return true;
        }
    }
    if (swi_is_integer(n1) && swi_is_integer(n2)) {
        unsigned long exponent = 0u;
        if (!swi_int_exponent(eval, n2, &exponent))
            return false;
        if (exp_sign < 0)
            return swi_pow_real(eval, n1, n2, r, exp_sign);
        size_t bits = n1->type == SWI_INTEGER
            ? (size_t)(64 - __builtin_clzll(
                  n1->value.i < 0 ? -(uint64_t)n1->value.i
                                  : (uint64_t)n1->value.i))
            : mpz_sizeinbase(n1->value.mpz, 2);
        if (!swi_power_fits(eval, bits, exponent))
            return false;
        swi_promote_to_mpz(n1);
        r->type = SWI_MPZ;
        mpz_init(r->value.mpz);
        mpz_pow_ui(r->value.mpz, n1->value.mpz, exponent);
        return true;
    }
    if (n1->type == SWI_MPQ && swi_is_integer(n2)) {
        unsigned long exponent = 0u;
        if (!swi_int_exponent(eval, n2, &exponent) ||
            !swi_power_fits(eval, mpz_sizeinbase(mpq_numref(n1->value.mpq), 2) +
                                      mpz_sizeinbase(mpq_denref(n1->value.mpq), 2),
                            exponent))
            return false;
        mpz_t num, den;
        mpz_init(num);
        mpz_init(den);
        mpz_pow_ui(num, mpq_numref(n1->value.mpq), exponent);
        mpz_pow_ui(den, mpq_denref(n1->value.mpq), exponent);
        r->type = SWI_MPQ;
        mpq_init(r->value.mpq);
        if (exp_sign > 0) {
            mpz_set(mpq_numref(r->value.mpq), num);
            mpz_set(mpq_denref(r->value.mpq), den);
        } else {
            mpz_set(mpq_numref(r->value.mpq), den);
            mpz_set(mpq_denref(r->value.mpq), num);
        }
        mpz_clear(num);
        mpz_clear(den);
        mpq_canonicalize(r->value.mpq);
        return true;
    }
    if (n2->type == SWI_MPQ)
        return swi_pow_rational(eval, n1, n2, r, exp_sign);
    return swi_pow_real(eval, n1, n2, r, exp_sign);
}

typedef double (*SwiUnaryFloat)(double);

static bool swi_unary_float(SwiEval *eval, SwiUnaryFloat op, SwiNum *n1,
                            SwiNum *r) {
    if (!swi_promote_to_float(eval, n1))
        return false;
    r->type = SWI_FLOAT;
    r->value.f = op(n1->value.f);
    return swi_check_float(eval, r);
}

static bool swi_abs(SwiNum *n1, SwiNum *r) {
    switch (n1->type) {
    case SWI_INTEGER:
        if (n1->value.i != INT64_MIN) {
            r->type = SWI_INTEGER;
            r->value.i = n1->value.i < 0 ? -n1->value.i : n1->value.i;
            return true;
        }
        swi_promote_to_mpz(n1);
        /* FALLTHROUGH */
    case SWI_MPZ:
        r->type = SWI_MPZ;
        mpz_init(r->value.mpz);
        mpz_abs(r->value.mpz, n1->value.mpz);
        return true;
    case SWI_MPQ:
        r->type = SWI_MPQ;
        mpq_init(r->value.mpq);
        mpq_abs(r->value.mpq, n1->value.mpq);
        return true;
    case SWI_FLOAT:
        r->type = SWI_FLOAT;
        r->value.f = signbit(n1->value.f) ? -n1->value.f : n1->value.f;
        return true;
    }
    return false;
}

static bool swi_double_in_int64_range(double x) {
    int k;
    double y = frexp(x, &k);
    return k < 64 || (y == -0.5 && k == 64);
}

/* A whole float as an integer (toIntegerNumber with CONVERT_FLOAT and
 * TRUNCATE): the float is finite here. */
static bool swi_whole_float(SwiEval *eval, double whole, SwiNum *r) {
    r->type = SWI_FLOAT;
    r->value.f = whole;
    if (!swi_check_float(eval, r))
        return false;
    if (swi_double_in_int64_range(whole)) {
        r->type = SWI_INTEGER;
        r->value.i = (int64_t)whole;
    } else {
        r->type = SWI_MPZ;
        mpz_init_set_d(r->value.mpz, whole);
    }
    return true;
}

static bool swi_floor(SwiEval *eval, SwiNum *n1, SwiNum *r) {
    switch (n1->type) {
    case SWI_INTEGER:
    case SWI_MPZ:
        swi_copy(r, n1);
        return true;
    case SWI_MPQ:
        r->type = SWI_MPZ;
        mpz_init(r->value.mpz);
        mpz_fdiv_q(r->value.mpz, mpq_numref(n1->value.mpq),
                   mpq_denref(n1->value.mpq));
        return true;
    case SWI_FLOAT:
        if (isnan(n1->value.f) || isinf(n1->value.f)) {
            swi_copy(r, n1);
            return true;
        }
        return swi_whole_float(eval, floor(n1->value.f), r);
    }
    return false;
}

static bool swi_ceil(SwiEval *eval, SwiNum *n1, SwiNum *r) {
    switch (n1->type) {
    case SWI_INTEGER:
    case SWI_MPZ:
        swi_copy(r, n1);
        return true;
    case SWI_MPQ:
        r->type = SWI_MPZ;
        mpz_init(r->value.mpz);
        mpz_cdiv_q(r->value.mpz, mpq_numref(n1->value.mpq),
                   mpq_denref(n1->value.mpq));
        return true;
    case SWI_FLOAT:
        if (isnan(n1->value.f) || isinf(n1->value.f)) {
            swi_copy(r, n1);
            return true;
        }
        return swi_whole_float(eval, ceil(n1->value.f), r);
    }
    return false;
}

static bool swi_truncate(SwiEval *eval, SwiNum *n1, SwiNum *r) {
    switch (n1->type) {
    case SWI_MPQ:
        return mpq_sgn(n1->value.mpq) >= 0 ? swi_floor(eval, n1, r)
                                           : swi_ceil(eval, n1, r);
    case SWI_FLOAT:
        if (isnan(n1->value.f) || isinf(n1->value.f)) {
            swi_copy(r, n1);
            return true;
        }
        return n1->value.f >= 0.0 ? swi_floor(eval, n1, r)
                                  : swi_ceil(eval, n1, r);
    default:
        swi_copy(r, n1);
        return true;
    }
}

/* round/1 (ar_integer): half away from zero. */
static bool swi_round(SwiNum *n1, SwiNum *r) {
    switch (n1->type) {
    case SWI_INTEGER:
    case SWI_MPZ:
        swi_copy(r, n1);
        return true;
    case SWI_MPQ: {
        mpq_t q, half;
        mpq_init(q);
        mpq_init(half);
        mpq_set_ui(half, 1u, 2u);
        if (mpq_sgn(n1->value.mpq) > 0)
            mpq_add(q, n1->value.mpq, half);
        else
            mpq_sub(q, n1->value.mpq, half);
        r->type = SWI_MPZ;
        mpz_init(r->value.mpz);
        mpz_set_q(r->value.mpz, q);
        mpq_clear(q);
        mpq_clear(half);
        return true;
    }
    case SWI_FLOAT:
        if (isnan(n1->value.f) || isinf(n1->value.f)) {
            swi_copy(r, n1);
            return true;
        }
        if (n1->value.f <= (float)INT64_MAX &&
            n1->value.f >= (float)INT64_MIN) {
            long rounded = lround(n1->value.f);
            if (n1->value.f > 0 && rounded < 0)
                rounded = LONG_MAX;
            else if (n1->value.f < 0 && rounded > 0)
                rounded = LONG_MIN;
            r->type = SWI_INTEGER;
            r->value.i = (int64_t)rounded;
            return true;
        }
        r->type = SWI_MPZ;
        mpz_init_set_d(r->value.mpz, n1->value.f);
        return true;
    }
    return false;
}

/* FUNCTOR applied to its evaluated arguments; NULL with a name this port
 * does not know, which declines. */
static bool swi_apply(SwiEval *eval, const char *functor, SwiNum *args,
                      uint32_t nargs, SwiNum *r) {
    if (nargs == 2u) {
        if (strcmp(functor, "+") == 0)
            return swi_add(eval, &args[0], &args[1], r);
        if (strcmp(functor, "-") == 0)
            return swi_minus(eval, &args[0], &args[1], r);
        if (strcmp(functor, "*") == 0)
            return swi_mul(eval, &args[0], &args[1], r);
        if (strcmp(functor, "/") == 0)
            return swi_divide(eval, &args[0], &args[1], r);
        if (strcmp(functor, "mod") == 0)
            return swi_mod(eval, &args[0], &args[1], r);
        if (strcmp(functor, "**") == 0)
            return swi_pow(eval, &args[0], &args[1], r);
    } else if (nargs == 1u) {
        static const struct {
            const char *name;
            SwiUnaryFloat op;
        } floats[] = {
            {"sqrt", sqrt}, {"sin", sin}, {"cos", cos}, {"tan", tan},
            {"asin", asin}, {"acos", acos}, {"atan", atan}, {"log", log},
        };
        for (size_t index = 0u; index < sizeof(floats) / sizeof(floats[0]);
             index++) {
            if (strcmp(functor, floats[index].name) == 0)
                return swi_unary_float(eval, floats[index].op, &args[0], r);
        }
        if (strcmp(functor, "abs") == 0)
            return swi_abs(&args[0], r);
        if (strcmp(functor, "truncate") == 0)
            return swi_truncate(eval, &args[0], r);
        if (strcmp(functor, "ceil") == 0)
            return swi_ceil(eval, &args[0], r);
        if (strcmp(functor, "floor") == 0)
            return swi_floor(eval, &args[0], r);
        if (strcmp(functor, "round") == 0)
            return swi_round(&args[0], r);
    }
    eval->declined = true;
    return false;
}

/* cmpNumbers: a float against any number compares as floats, NaN with
 * nothing; other mixed types promote to the wider. */
static SwiOrder swi_compare(SwiNum *n1, SwiNum *n2) {
    if (n1->type != n2->type &&
        (n1->type == SWI_FLOAT || n2->type == SWI_FLOAT)) {
        bool swapped = n1->type != SWI_FLOAT;
        SwiNum *f = swapped ? n2 : n1;
        SwiNum *other = swapped ? n1 : n2;
        if (isnan(f->value.f))
            return SWI_CMP_NOTEQ;
        double d = other->type == SWI_INTEGER ? (double)other->value.i
            : other->type == SWI_MPZ ? swi_mpz_to_double(other->value.mpz)
            : swi_mpz_fdiv(mpq_numref(other->value.mpq),
                           mpq_denref(other->value.mpq));
        SwiOrder order = f->value.f == d ? SWI_CMP_EQUAL
            : f->value.f < d ? SWI_CMP_LESS : SWI_CMP_GREATER;
        return swapped && order != SWI_CMP_EQUAL ? (SwiOrder)-order : order;
    }
    if (n1->type != n2->type) {
        if (n1->type > n2->type)
            n2->type == SWI_INTEGER && n1->type == SWI_MPZ
                ? swi_promote_to_mpz(n2) : swi_promote_to_mpq(n2);
        else
            n1->type == SWI_INTEGER && n2->type == SWI_MPZ
                ? swi_promote_to_mpz(n1) : swi_promote_to_mpq(n1);
    }
    int rc;
    switch (n1->type) {
    case SWI_INTEGER:
        return n1->value.i < n2->value.i ? SWI_CMP_LESS
             : n1->value.i > n2->value.i ? SWI_CMP_GREATER : SWI_CMP_EQUAL;
    case SWI_MPZ:
        rc = mpz_cmp(n1->value.mpz, n2->value.mpz);
        break;
    case SWI_MPQ:
        rc = mpq_cmp(n1->value.mpq, n2->value.mpq);
        break;
    case SWI_FLOAT:
        if (n1->value.f == n2->value.f)
            return SWI_CMP_EQUAL;
        if (n1->value.f < n2->value.f)
            return SWI_CMP_LESS;
        if (n1->value.f > n2->value.f)
            return SWI_CMP_GREATER;
        return SWI_CMP_NOTEQ;
    default:
        return SWI_CMP_NOTEQ;
    }
    return rc < 0 ? SWI_CMP_LESS : rc > 0 ? SWI_CMP_GREATER : SWI_CMP_EQUAL;
}

/* Stable's arith_arg/1 refuses MeTTa text and list values before is/2, as
 * the Prolog build does (petta_libpl_numeric_call). */
static bool swi_refused_operand(Arena *arena, Atom **args, uint32_t nargs,
                                CettaCallOutcome *out) {
    for (uint32_t index = 0u; index < nargs; index++) {
        Atom *arg = args[index];
        if (arg && (arg->kind == ATOM_EXPR ||
                    (arg->kind == ATOM_GROUNDED &&
                     arg->ground.gkind == GV_STRING))) {
            *out = cetta_call_raised(
                petta_semantics_arithmetic_operand_error(arena, arg));
            return true;
        }
    }
    return false;
}

/* Whether every argument crosses to Prolog as a number, an atom or a
 * variable.  The Prolog build converts them all before it evaluates any,
 * and declines where one does not cross. */
static bool swi_operands_cross(Atom **args, uint32_t nargs) {
    for (uint32_t index = 0u; index < nargs; index++) {
        Atom *arg = args[index];
        if (arg->kind != ATOM_GROUNDED)
            continue;
        switch (arg->ground.gkind) {
        case GV_INT:
        case GV_FLOAT:
        case GV_BOOL:
        case GV_BIGINT:
        case GV_RATIONAL:
            break;
        default:
            return false;
        }
    }
    return true;
}

bool petta_libpl_evaluate_arithmetic(
    Arena *arena, const char *functor, Atom **args, uint32_t nargs,
    CettaCallOutcome *out) {
    if (out)
        *out = cetta_call_failure();
    if (!arena || !out || !args || nargs == 0u || nargs > 2u ||
        (!functor && nargs != 1u))
        return false;
    for (uint32_t index = 0u; index < nargs; index++) {
        if (!args[index])
            return false;
    }
    if (swi_refused_operand(arena, args, nargs, out))
        return out->term != NULL;
    if (!swi_operands_cross(args, nargs))
        return false;
    SwiEval eval = {.arena = arena, .predicate = "is"};
    SwiNum values[2] = {{0}, {0}};
    SwiNum result = {0};
    bool ok = true;
    /* SWI evaluates a function's arguments from the last to the first. */
    for (uint32_t index = nargs; ok && index-- > 0u;)
        ok = swi_operand(&eval, args[index], &values[index]);
    if (ok) {
        if (functor) {
            ok = swi_apply(&eval, functor, values, nargs, &result);
        } else {
            result = values[0];
            values[0].type = SWI_INTEGER;
        }
    }
    if (ok) {
        swi_normalize(&result);
        *out = cetta_call_value(swi_number_atom(arena, &result));
    } else if (!eval.declined) {
        *out = cetta_call_raised(eval.raised);
    }
    swi_clear(&result);
    swi_clear(&values[0]);
    swi_clear(&values[1]);
    return !eval.declined && out->term != NULL;
}

bool petta_libpl_compare_arithmetic(
    Arena *arena, const char *relation, Atom **args, CettaCallOutcome *out) {
    if (out)
        *out = cetta_call_failure();
    if (!arena || !out || !args || !args[0] || !args[1] || !relation)
        return false;
    int which;
    if (strcmp(relation, "<") == 0)
        which = 0;
    else if (strcmp(relation, ">") == 0)
        which = 1;
    else if (strcmp(relation, "=<") == 0)
        which = 2;
    else if (strcmp(relation, ">=") == 0)
        which = 3;
    else
        return false;
    if (swi_refused_operand(arena, args, 2u, out))
        return out->term != NULL;
    if (!swi_operands_cross(args, 2u))
        return false;
    SwiEval eval = {.arena = arena, .predicate = relation};
    SwiNum left = {0};
    SwiNum right = {0};
    /* A comparison evaluates its left side first. */
    bool ok = swi_operand(&eval, args[0], &left) &&
              swi_operand(&eval, args[1], &right);
    if (ok) {
        SwiOrder order = swi_compare(&left, &right);
        bool holds = which == 0 ? order == SWI_CMP_LESS
            : which == 1 ? order == SWI_CMP_GREATER
            : which == 2 ? order == SWI_CMP_LESS || order == SWI_CMP_EQUAL
            : order == SWI_CMP_GREATER || order == SWI_CMP_EQUAL;
        *out = cetta_call_value(atom_symbol(arena, holds ? "true" : "false"));
    } else if (!eval.declined) {
        *out = cetta_call_raised(eval.raised);
    }
    swi_clear(&left);
    swi_clear(&right);
    return !eval.declined && out->term != NULL;
}

#else /* !CETTA_BUILD_WITH_GMP */

/* Without GMP this build keeps CeTTa's native answers. */
bool petta_libpl_evaluate_arithmetic(
    Arena *arena, const char *functor, Atom **args, uint32_t nargs,
    CettaCallOutcome *out) {
    (void)arena;
    (void)functor;
    (void)args;
    (void)nargs;
    if (out)
        *out = cetta_call_failure();
    return false;
}

bool petta_libpl_compare_arithmetic(
    Arena *arena, const char *relation, Atom **args, CettaCallOutcome *out) {
    (void)arena;
    (void)relation;
    (void)args;
    if (out)
        *out = cetta_call_failure();
    return false;
}

#endif /* CETTA_BUILD_WITH_GMP */
