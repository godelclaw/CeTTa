#include "tensor_dense_v1.h"
#include "atom_wire.h"
#include "durable_value.h"
#include "tests/test_runtime_stats_stubs.h"
#include <assert.h>
#include <math.h>
#include <float.h>
#include <fenv.h>
#include <pthread.h>
#include <stdlib.h>
#if (defined(__x86_64__) || defined(__i386__)) && (defined(__GNUC__) || defined(__clang__))
#include <immintrin.h>
#define TEST_HAS_MXCSR 1
#else
#define TEST_HAS_MXCSR 0
#endif

static CettaDenseTensorV1 *make(CettaDenseTensorV1DType dtype, const size_t *shape, size_t rank,
    const void *data, size_t bytes) {
    CettaDenseTensorV1 *tensor = NULL;
    assert(cetta_dense_tensor_v1_new(dtype, shape, rank, data, bytes, &tensor) == CETTA_DENSE_TENSOR_V1_OK);
    return tensor;
}

static void *copy_worker(void *input) {
    CettaDenseTensorV1 *source = input;
    for (unsigned i = 0; i < 400u; ++i) {
        Arena arena; arena_init_detached(&arena);
        Atom *atom = atom_tensor(&arena, source);
        assert(atom && cetta_dense_tensor_v1_equal(atom->ground.ptr, source));
        CettaDenseTensorV1 *view = NULL;
        size_t shape[] = {2u, 2u};
        assert(cetta_dense_tensor_v1_reshape(source, shape, 2u, &view) == CETTA_DENSE_TENSOR_V1_OK);
        assert(cetta_dense_tensor_v1_shares_storage(source, view));
        cetta_dense_tensor_v1_release(view);
        arena_free(&arena);
    }
    return NULL;
}

static void codecs(Arena *arena, Atom *source) {
    unsigned char *bytes = NULL; size_t size = 0;
    Atom *decoded = NULL;
    assert(cetta_atom_wire_encode(source, &bytes, &size) == ATOM_WIRE_OK);
    assert(cetta_atom_wire_decode(arena, bytes, size, &decoded) == ATOM_WIRE_OK);
    assert(atom_eq(source, decoded) && atom_hash(source) == atom_hash(decoded));
    assert(cetta_atom_wire_decode(arena, bytes, size - 1u, &decoded) != ATOM_WIRE_OK);
    free(bytes); bytes = NULL;
    assert(cetta_durable_value_encode(source, &bytes, &size) == DURABLE_OK);
    assert(cetta_durable_value_decode(arena, bytes, size, &decoded) == DURABLE_OK);
    assert(atom_eq(source, decoded) && atom_hash(source) == atom_hash(decoded));
    free(bytes);
}

static void arithmetic_reference(void) {
    /* Small exact binary fractions keep the reference independent of reduction
     * tolerance. Check every output entry, all supported dtypes and empty input. */
    for (unsigned dtype = CETTA_DENSE_TENSOR_V1_I64; dtype <= CETTA_DENSE_TENSOR_V1_F32; ++dtype) {
        for (size_t n = 0; n <= 32u; ++n) {
            unsigned char entries[32u * 8u];
            double float_sum = 0.0, float_dot = 0.0;
            int64_t int_sum = 0, int_dot = 0;
            size_t width = cetta_dense_tensor_v1_itemsize(dtype);
            for (size_t i = 0; i < n; ++i) {
                int64_t integer = dtype == CETTA_DENSE_TENSOR_V1_U8 ? (int64_t)(i % 8u) : (int64_t)(i % 11u) - 5;
                double floating = (double)integer / 4.0;
                if (dtype == CETTA_DENSE_TENSOR_V1_F32) { float compact = floating; memcpy(entries + i*width, &compact, width); }
                else if (dtype == CETTA_DENSE_TENSOR_V1_F64) memcpy(entries + i * width, &floating, width);
                else if (dtype == CETTA_DENSE_TENSOR_V1_I64) memcpy(entries + i * width, &integer, width);
                else entries[i] = (unsigned char)integer;
                float_sum += floating; float_dot += floating * floating;
                int_sum += integer; int_dot += integer * integer;
            }
            CettaDenseTensorV1 *source = make(dtype, &n, 1u, entries, n * width);
            CettaDenseTensorV1Scalar result;
            assert(cetta_dense_tensor_v1_reduce(source, NULL, &result) == CETTA_DENSE_TENSOR_V1_OK);
            if (dtype == CETTA_DENSE_TENSOR_V1_F64 || dtype == CETTA_DENSE_TENSOR_V1_F32) assert(result.value.floating == float_sum);
            else assert(result.value.integer == int_sum);
            assert(cetta_dense_tensor_v1_reduce(source, source, &result) == CETTA_DENSE_TENSOR_V1_OK);
            if (dtype == CETTA_DENSE_TENSOR_V1_F64 || dtype == CETTA_DENSE_TENSOR_V1_F32) assert(result.value.floating == float_dot);
            else assert(result.value.integer == int_dot);
            for (unsigned multiply = 0; multiply < 2u; ++multiply) {
                CettaDenseTensorV1 *output = NULL;
                assert(cetta_dense_tensor_v1_binary(source, source, multiply, &output) == CETTA_DENSE_TENSOR_V1_OK);
                const unsigned char *data = cetta_dense_tensor_v1_data(output);
                for (size_t i = 0; i < n; ++i) {
                    int64_t integer = dtype == CETTA_DENSE_TENSOR_V1_U8 ? (int64_t)(i % 8u) : (int64_t)(i % 11u) - 5;
                    double floating = (double)integer / 4.0;
                    if (dtype == CETTA_DENSE_TENSOR_V1_F64 || dtype == CETTA_DENSE_TENSOR_V1_F32) {
                        double actual;
                        if (dtype == CETTA_DENSE_TENSOR_V1_F32) { float compact; memcpy(&compact, data + i*width, width); actual = compact; }
                        else memcpy(&actual, data + i * width, width);
                        assert(actual == (multiply ? floating * floating : floating + floating));
                    } else {
                        int64_t actual;
                        if (dtype == CETTA_DENSE_TENSOR_V1_U8) actual = data[i];
                        else memcpy(&actual, data + i * width, width);
                        assert(actual == (multiply ? integer * integer : integer + integer));
                    }
                }
                cetta_dense_tensor_v1_release(output);
            }
            unsigned char *encoded; size_t size; CettaDenseTensorV1 *decoded = NULL;
            assert(cetta_dense_tensor_v1_encode(source, &encoded, &size) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_decode(encoded, size, &decoded) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_equal(source, decoded));
            free(encoded); cetta_dense_tensor_v1_release(decoded); cetta_dense_tensor_v1_release(source);
        }
    }
}

static void compact_screening_reference(void) {
    for (size_t width = 0; width <= 67; ++width) {
        size_t shape[] = {37, width};
        double data[37*67], q[67];
        for (size_t j = 0; j < width; ++j)
            q[j] = (double)((int)(j*13 % 37)-18) / 19.;
        for (size_t i = 0; i < 37; ++i) for (size_t j = 0; j < width; ++j)
            data[i*width+j] = sin((double)((i+1)*(j+3))) * .25;
        /* Two distinct f64 values with the same compact value test ambiguity. */
        if (width) { data[0] = .5; data[width] = nextafter(.5, INFINITY); }
        CettaDenseTensorV1 *wide = make(CETTA_DENSE_TENSOR_V1_F64, shape, 2, data, 37*width*8);
        CettaDenseTensorV1 *query = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, q, width*8);
        CettaDenseTensorV1 *compact = NULL, *cert = NULL, *lo = NULL, *hi = NULL, *exact = NULL;
        assert(cetta_dense_tensor_v1_cast(wide, CETTA_DENSE_TENSOR_V1_F32, &compact) == CETTA_DENSE_TENSOR_V1_OK);
        assert(cetta_dense_tensor_v1_nbytes(compact) == 37*width*4);
        assert(cetta_dense_tensor_v1_row_error_bounds(wide, compact, &cert) == CETTA_DENSE_TENSOR_V1_OK);
        assert(cetta_dense_tensor_v1_matvec_bounds(compact, query, cert, NULL, 1, &lo, &hi) == CETTA_DENSE_TENSOR_V1_OK);
        assert(cetta_dense_tensor_v1_matvec(wide, query, NULL, &exact) == CETTA_DENSE_TENSOR_V1_OK);
        const double *l = cetta_dense_tensor_v1_data(lo), *h = cetta_dense_tensor_v1_data(hi), *s = cetta_dense_tensor_v1_data(exact);
        for (size_t i = 0; i < 37; ++i) assert(l[i] <= s[i] && s[i] <= h[i]);
        /* Provider agreement also covers short tails and zero-width rows. */
        CettaDenseTensorV1 *scalar = NULL, *automatic = NULL;
        assert(cetta_dense_tensor_v1_matvec_with_provider(compact, query, NULL, CETTA_MATVEC_SCALAR4, &scalar) == CETTA_DENSE_TENSOR_V1_OK);
        assert(cetta_dense_tensor_v1_matvec(compact, query, NULL, &automatic) == CETTA_DENSE_TENSOR_V1_OK);
        assert(cetta_dense_tensor_v1_equal(scalar, automatic));
        cetta_dense_tensor_v1_release(scalar); cetta_dense_tensor_v1_release(automatic);
        for (size_t k = 0; k <= 38; ++k) {
            CettaDenseTensorV1 *candidates = NULL, *target = NULL, *selected = NULL, *top = NULL, *mapped = NULL;
            assert(cetta_dense_tensor_v1_top_k_candidates(lo, hi, k, &candidates) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_top_k(exact, NULL, k, &target) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_matvec(wide, query, candidates, &selected) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_top_k(selected, NULL, k, &top) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_gather(candidates, top, &mapped) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_equal(target, mapped));
            cetta_dense_tensor_v1_release(candidates); cetta_dense_tensor_v1_release(target); cetta_dense_tensor_v1_release(selected);
            cetta_dense_tensor_v1_release(top); cetta_dense_tensor_v1_release(mapped);
        }
        if (width == 67) {
            int old = fegetround(); assert(fesetround(FE_DOWNWARD) == 0);
            CettaDenseTensorV1 *fallback_lo = NULL, *fallback_hi = NULL, *all = NULL;
            assert(cetta_dense_tensor_v1_matvec_bounds(compact, query, cert, NULL, 1, &fallback_lo, &fallback_hi) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_top_k_candidates(fallback_lo, fallback_hi, 5, &all) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_count(all) == 37);
            assert(fesetround(old) == 0);
            cetta_dense_tensor_v1_release(fallback_lo); cetta_dense_tensor_v1_release(fallback_hi); cetta_dense_tensor_v1_release(all);
#if TEST_HAS_MXCSR
            unsigned csr = _mm_getcsr();
            for (unsigned mode = 0; mode < 2; ++mode) {
                _mm_setcsr(csr | (mode ? (1u << 6) : (1u << 15)));
                fallback_lo = NULL; fallback_hi = NULL; all = NULL;
                assert(cetta_dense_tensor_v1_matvec_bounds(compact, query, cert, NULL, 1, &fallback_lo, &fallback_hi) == CETTA_DENSE_TENSOR_V1_OK);
                assert(cetta_dense_tensor_v1_top_k_candidates(fallback_lo, fallback_hi, 5, &all) == CETTA_DENSE_TENSOR_V1_OK);
                assert(cetta_dense_tensor_v1_count(all) == 37);
                _mm_setcsr(csr);
                cetta_dense_tensor_v1_release(fallback_lo); cetta_dense_tensor_v1_release(fallback_hi); cetta_dense_tensor_v1_release(all);
            }
#endif
        }
        cetta_dense_tensor_v1_release(wide); cetta_dense_tensor_v1_release(query); cetta_dense_tensor_v1_release(compact);
        cetta_dense_tensor_v1_release(cert); cetta_dense_tensor_v1_release(lo); cetta_dense_tensor_v1_release(hi); cetta_dense_tensor_v1_release(exact);
    }
    /* Inclusive threshold retains ties; reversed intervals are refused. */
    size_t n = 3; double lowers[] = {3, 2, 0}, uppers[] = {3, 2, 2};
    CettaDenseTensorV1 *lo = make(CETTA_DENSE_TENSOR_V1_F64, &n, 1, lowers, sizeof(lowers));
    CettaDenseTensorV1 *hi = make(CETTA_DENSE_TENSOR_V1_F64, &n, 1, uppers, sizeof(uppers)), *candidates = NULL;
    assert(cetta_dense_tensor_v1_top_k_candidates(lo, hi, 2, &candidates) == CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_count(candidates) == 3); cetta_dense_tensor_v1_release(candidates);
    lowers[2] = 4;
    CettaDenseTensorV1 *bad = make(CETTA_DENSE_TENSOR_V1_F64, &n, 1, lowers, sizeof(lowers));
    assert(cetta_dense_tensor_v1_top_k_candidates(bad, hi, 0, &candidates) == CETTA_DENSE_TENSOR_V1_VALUE && !candidates);
    cetta_dense_tensor_v1_release(bad); cetta_dense_tensor_v1_release(lo); cetta_dense_tensor_v1_release(hi);
    /* Naive f32 top-1 drops the true winner; bound/refine must keep it. */
    size_t pair_shape[] = {2,1}, one=1;
    double close_values[] = {.5,nextafter(.5,INFINITY)}, query_value=1;
    CettaDenseTensorV1 *wide = make(CETTA_DENSE_TENSOR_V1_F64,pair_shape,2,close_values,sizeof(close_values));
    CettaDenseTensorV1 *query = make(CETTA_DENSE_TENSOR_V1_F64,&one,1,&query_value,8), *narrow=NULL, *cert=NULL, *scores=NULL, *top=NULL;
    assert(cetta_dense_tensor_v1_cast(wide,CETTA_DENSE_TENSOR_V1_F32,&narrow)==CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_matvec(narrow,query,NULL,&scores)==CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_top_k(scores,NULL,1,&top)==CETTA_DENSE_TENSOR_V1_OK);
    assert(((const int64_t *)cetta_dense_tensor_v1_data(top))[0]==0);
    assert(cetta_dense_tensor_v1_row_error_bounds(wide,narrow,&cert)==CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_matvec_bounds(narrow,query,cert,NULL,1,&lo,&hi)==CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_top_k_candidates(lo,hi,1,&candidates)==CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_count(candidates)==2);
    cetta_dense_tensor_v1_release(scores); cetta_dense_tensor_v1_release(top);
    assert(cetta_dense_tensor_v1_matvec(wide,query,candidates,&scores)==CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_top_k(scores,NULL,1,&top)==CETTA_DENSE_TENSOR_V1_OK);
    assert(((const int64_t *)cetta_dense_tensor_v1_data(top))[0]==1);
    cetta_dense_tensor_v1_release(wide); cetta_dense_tensor_v1_release(query); cetta_dense_tensor_v1_release(narrow);
    cetta_dense_tensor_v1_release(cert); cetta_dense_tensor_v1_release(lo); cetta_dense_tensor_v1_release(hi);
    cetta_dense_tensor_v1_release(candidates); cetta_dense_tensor_v1_release(scores); cetta_dense_tensor_v1_release(top);
    /* Portable bits include signed zero and NaN payloads. */
    uint32_t bits[] = {0, UINT32_C(0x80000000), UINT32_C(0x7fc00001)};
    CettaDenseTensorV1 *source = make(CETTA_DENSE_TENSOR_V1_F32, &n, 1, bits, sizeof(bits)), *copy = NULL;
    assert(cetta_dense_tensor_v1_copy(source, &copy) == CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_compare(source, copy) == 0 && cetta_dense_tensor_v1_equal(source, copy));
    unsigned char *bytes; size_t size;
    assert(cetta_dense_tensor_v1_encode(source, &bytes, &size) == CETTA_DENSE_TENSOR_V1_OK);
    assert(size == 29 && bytes[4] == 4 && bytes[24] == 128 && bytes[25] == 1);
    CettaDenseTensorV1 *decoded = NULL;
    assert(cetta_dense_tensor_v1_decode(bytes, size, &decoded) == CETTA_DENSE_TENSOR_V1_OK && cetta_dense_tensor_v1_equal(source, decoded));
    cetta_dense_tensor_v1_release(source); cetta_dense_tensor_v1_release(copy); cetta_dense_tensor_v1_release(decoded); free(bytes);
}

#define OK CETTA_DENSE_TENSOR_V1_OK
static uint64_t int8_state = 88172645463325252u;
static double int8_widest = 0;
static double int8_uniform(void) {
    int8_state ^= int8_state << 13; int8_state ^= int8_state >> 7; int8_state ^= int8_state << 17;
    return (double)(int8_state >> 11) / 9007199254740992. * 2. - 1.;
}
/* The f64 reference top k over the int8 candidates equals the reference top k over
 * the whole selection: the same rows, in the same order, with the same scores. */
static size_t int8_expect_exact(CettaDenseTensorV1 *wide, CettaDenseTensorV1 *codes,
    CettaDenseTensorV1 *record, CettaDenseTensorV1 *query, CettaDenseTensorV1 *indices, size_t k) {
    CettaDenseTensorV1 *candidates = NULL, *all = NULL, *target = NULL, *ids = NULL, *scores = NULL;
    CettaDenseTensorV1 *local = NULL, *mapped = NULL, *expected = NULL, *actual = NULL, *lo = NULL, *hi = NULL;
    assert(cetta_dense_tensor_v1_int8_candidates(codes, record, query, indices, k, &candidates) == OK);
    assert(cetta_dense_tensor_v1_matvec(wide, query, indices, &all) == OK);
    /* Every selected row's reference score lies inside its bounds. */
    assert(cetta_dense_tensor_v1_int8_bounds(codes, record, query, indices, &lo, &hi) == OK);
    const double *l = cetta_dense_tensor_v1_data(lo), *h = cetta_dense_tensor_v1_data(hi), *r = cetta_dense_tensor_v1_data(all);
    for (size_t i = 0; i < cetta_dense_tensor_v1_count(all); ++i) {
        assert(l[i] <= r[i] && r[i] <= h[i]);
        double below = r[i] - l[i], above = h[i] - r[i];
        if (below > int8_widest) int8_widest = below;
        if (above > int8_widest) int8_widest = above;
    }
    cetta_dense_tensor_v1_release(lo); cetta_dense_tensor_v1_release(hi);
    assert(cetta_dense_tensor_v1_top_k(all, NULL, k, &target) == OK);
    if (indices) assert(cetta_dense_tensor_v1_gather(indices, target, &ids) == OK);
    else { ids = target; cetta_dense_tensor_v1_retain(ids); }
    assert(cetta_dense_tensor_v1_matvec(wide, query, candidates, &scores) == OK);
    assert(cetta_dense_tensor_v1_top_k(scores, NULL, k, &local) == OK);
    assert(cetta_dense_tensor_v1_gather(candidates, local, &mapped) == OK);
    assert(cetta_dense_tensor_v1_equal(ids, mapped));
    assert(cetta_dense_tensor_v1_gather(all, target, &expected) == OK);
    assert(cetta_dense_tensor_v1_gather(scores, local, &actual) == OK);
    assert(cetta_dense_tensor_v1_equal(expected, actual));
    /* Candidates keep the selection's order and come from it. */
    size_t kept = cetta_dense_tensor_v1_count(candidates);
    const int64_t *c = cetta_dense_tensor_v1_data(candidates);
    const int64_t *chosen = indices ? cetta_dense_tensor_v1_data(indices) : NULL;
    size_t available = indices ? cetta_dense_tensor_v1_count(indices) : cetta_dense_tensor_v1_shape(wide)[0];
    for (size_t i = 0, j = 0; i < kept; ++i) {
        while (j < available && (chosen ? chosen[j] : (int64_t)j) != c[i]) ++j;
        assert(j < available); ++j;
    }
    cetta_dense_tensor_v1_release(candidates); cetta_dense_tensor_v1_release(all); cetta_dense_tensor_v1_release(target);
    cetta_dense_tensor_v1_release(ids); cetta_dense_tensor_v1_release(scores); cetta_dense_tensor_v1_release(local);
    cetta_dense_tensor_v1_release(mapped); cetta_dense_tensor_v1_release(expected); cetta_dense_tensor_v1_release(actual);
    return kept;
}
static void int8_rows_of(CettaDenseTensorV1 *wide, CettaDenseTensorV1 **codes, CettaDenseTensorV1 **record) {
    assert(cetta_dense_tensor_v1_int8_rows(wide, codes, record) == OK);
    const size_t *shape = cetta_dense_tensor_v1_shape(wide);
    assert(cetta_dense_tensor_v1_dtype(*codes) == CETTA_DENSE_TENSOR_V1_U8);
    assert(cetta_dense_tensor_v1_shape(*codes)[0] == shape[0] && cetta_dense_tensor_v1_shape(*codes)[1] == shape[1]);
    assert(cetta_dense_tensor_v1_shape(*record)[0] == shape[0] && cetta_dense_tensor_v1_shape(*record)[1] == 4);
    const int8_t *code = cetta_dense_tensor_v1_data(*codes);
    for (size_t i = 0; i < shape[0] * shape[1]; ++i) assert(code[i] >= -127 && code[i] <= 127);
}
static CettaDenseTensorV1 *int8_unit_rows(size_t rows, size_t width, double *data) {
    for (size_t i = 0; i < rows; ++i) {
        double total = 0;
        for (size_t j = 0; j < width; ++j) total += data[i*width+j] * data[i*width+j];
        for (size_t j = 0; j < width && total > 0; ++j) data[i*width+j] /= sqrt(total);
    }
    size_t shape[] = {rows, width};
    return make(CETTA_DENSE_TENSOR_V1_F64, shape, 2, data, rows*width*8);
}

/* Every available kernel equals the scalar sum, at every block boundary and at the
 * widest admitted width with every product at its extreme. */
static void int8_kernel_reference(void) {
    static int8_t a[(1u << 17) + 1], b[(1u << 17) + 1];
    const CettaDenseTensorV1Int8Kernel kernels[] = {CETTA_INT8_KERNEL_AVX2, CETTA_INT8_KERNEL_AVX512_VNNI};
    size_t widths[300], count = 0;
    for (size_t w = 0; w <= 260; ++w) widths[count++] = w;
    const size_t larger[] = {511, 512, 513, 1023, 1024, 1025, 4096, 4159, 1u << 17};
    for (size_t i = 0; i < sizeof(larger)/sizeof(larger[0]); ++i) widths[count++] = larger[i];
    for (unsigned pattern = 0; pattern < 4; ++pattern) {
        for (size_t j = 0; j < (1u << 17); ++j) {
            int random_a = (int)(int8_uniform() * 127.5), random_b = (int)(int8_uniform() * 127.5);
            if (random_a > 127) random_a = 127;
            if (random_a < -127) random_a = -127;
            if (random_b > 127) random_b = 127;
            if (random_b < -127) random_b = -127;
            a[j] = (int8_t)(pattern == 0 ? random_a : pattern == 1 ? 127 : pattern == 2 ? (j % 3 ? -127 : 127) : (j % 2 ? 0 : -127));
            b[j] = (int8_t)(pattern == 0 ? random_b : pattern == 1 ? 127 : pattern == 2 ? -127 : (j % 5 ? 127 : -1));
        }
        for (size_t i = 0; i < count; ++i) {
            int32_t expected = 0, actual = 0;
            assert(cetta_dense_tensor_v1_int8_dot(CETTA_INT8_KERNEL_SCALAR, a, b, widths[i], &expected) == OK);
            int64_t wide = 0;
            for (size_t j = 0; j < widths[i]; ++j) wide += (int64_t)a[j] * b[j];
            assert(wide == expected);
            for (size_t k = 0; k < 2; ++k) {
                if (!cetta_dense_tensor_v1_int8_kernel_available(kernels[k])) {
                    assert(cetta_dense_tensor_v1_int8_dot(kernels[k], a, b, widths[i], &actual) == CETTA_DENSE_TENSOR_V1_PROVIDER);
                    continue;
                }
                assert(cetta_dense_tensor_v1_int8_dot(kernels[k], a, b, widths[i], &actual) == OK && actual == expected);
                /* Unaligned rows too. */
                if (widths[i] && widths[i] < (1u << 17)) {
                    assert(cetta_dense_tensor_v1_int8_dot(kernels[k], a + 1, b + 1, widths[i], &actual) == OK);
                    int32_t shifted = 0;
                    assert(cetta_dense_tensor_v1_int8_dot(CETTA_INT8_KERNEL_SCALAR, a + 1, b + 1, widths[i], &shifted) == OK);
                    assert(actual == shifted);
                }
            }
        }
    }
    int32_t out = 0;
    a[3] = INT8_MIN;
    assert(cetta_dense_tensor_v1_int8_dot(CETTA_INT8_KERNEL_SCALAR, a, b, 8, &out) == CETTA_DENSE_TENSOR_V1_VALUE);
    assert(cetta_dense_tensor_v1_int8_dot(CETTA_INT8_KERNEL_SCALAR, a, b, (1u << 17) + 1, &out) == CETTA_DENSE_TENSOR_V1_OVERFLOW);
    assert(cetta_dense_tensor_v1_int8_dot(CETTA_INT8_KERNEL_SCALAR, a, b, 8, NULL) == CETTA_DENSE_TENSOR_V1_VALUE);
}

static void int8_screening_reference(void) {
    int8_kernel_reference();
    /* Every width to 67 and every k, all rows and every other row. */
    for (size_t width = 0; width <= 67; ++width) {
        double data[37*67], q[67];
        for (size_t j = 0; j < width; ++j) q[j] = (double)((int)(j*13 % 37)-18) / 19.;
        for (size_t i = 0; i < 37; ++i) for (size_t j = 0; j < width; ++j)
            data[i*width+j] = sin((double)((i+1)*(j+3))) * .25;
        if (width) { data[0] = .5; data[width] = nextafter(.5, INFINITY); }
        size_t shape[] = {37, width};
        CettaDenseTensorV1 *wide = make(CETTA_DENSE_TENSOR_V1_F64, shape, 2, data, 37*width*8);
        CettaDenseTensorV1 *query = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, q, width*8);
        CettaDenseTensorV1 *codes = NULL, *record = NULL;
        int8_rows_of(wide, &codes, &record);
        size_t half = 19; int64_t even[19];
        for (size_t i = 0; i < half; ++i) even[i] = (int64_t)(2*i);
        CettaDenseTensorV1 *indices = make(CETTA_DENSE_TENSOR_V1_I64, &half, 1, even, sizeof(even));
        for (size_t k = 0; k <= 38; ++k) {
            size_t kept = int8_expect_exact(wide, codes, record, query, NULL, k);
            assert(k ? kept >= (k < 37 ? k : 37) : kept == 0);
            kept = int8_expect_exact(wide, codes, record, query, indices, k);
            assert(kept <= half);
        }
        cetta_dense_tensor_v1_release(wide); cetta_dense_tensor_v1_release(query);
        cetta_dense_tensor_v1_release(codes); cetta_dense_tensor_v1_release(record); cetta_dense_tensor_v1_release(indices);
    }
    /* Exact ties: eight vectors, five copies each; boundary ties follow row order. */
    {
        size_t rows = 40, width = 24; double data[40*24], q[24];
        for (size_t v = 0; v < 8; ++v) for (size_t j = 0; j < width; ++j) {
            double value = cos((double)((v+2)*(j+1)));
            for (size_t c = 0; c < 5; ++c) data[(c*8+v)*width+j] = value;
        }
        CettaDenseTensorV1 *wide = int8_unit_rows(rows, width, data), *codes = NULL, *record = NULL;
        int8_rows_of(wide, &codes, &record);
        for (size_t trial = 0; trial < 6; ++trial) {
            for (size_t j = 0; j < width; ++j) q[j] = int8_uniform();
            CettaDenseTensorV1 *query = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, q, sizeof(q));
            for (size_t k = 1; k <= 12; ++k) {
                size_t kept = int8_expect_exact(wide, codes, record, query, NULL, k);
                assert(kept % 5 == 0);
            }
            cetta_dense_tensor_v1_release(query);
        }
        cetta_dense_tensor_v1_release(wide); cetta_dense_tensor_v1_release(codes); cetta_dense_tensor_v1_release(record);
    }
    /* Extreme codes: every entry at the row's peak, widths with and without a tail. */
    for (size_t width = 31; width <= 97; width += 33) {
        size_t rows = 50; double data[50*97], q[97];
        for (size_t i = 0; i < rows; ++i) for (size_t j = 0; j < width; ++j)
            data[i*width+j] = int8_uniform() < 0 ? -1. : 1.;
        for (size_t j = 0; j < width; ++j) q[j] = j % 3 ? -1. : 1.;
        CettaDenseTensorV1 *wide = int8_unit_rows(rows, width, data), *codes = NULL, *record = NULL;
        int8_rows_of(wide, &codes, &record);
        CettaDenseTensorV1 *query = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, q, width*8);
        for (size_t k = 1; k <= 7; ++k) (void)int8_expect_exact(wide, codes, record, query, NULL, k);
        cetta_dense_tensor_v1_release(wide); cetta_dense_tensor_v1_release(codes);
        cetta_dense_tensor_v1_release(record); cetta_dense_tensor_v1_release(query);
    }
    /* An embedding-sized store: exact, and the screen keeps few rows. */
    {
        size_t rows = 1500, width = 384;
        double *data = malloc(rows*width*8), q[384];
        assert(data);
        for (size_t i = 0; i < rows*width; ++i) data[i] = int8_uniform();
        CettaDenseTensorV1 *wide = int8_unit_rows(rows, width, data), *codes = NULL, *record = NULL;
        free(data);
        int8_rows_of(wide, &codes, &record);
        for (size_t trial = 0; trial < 8; ++trial) {
            double total = 0;
            for (size_t j = 0; j < width; ++j) { q[j] = int8_uniform(); total += q[j]*q[j]; }
            for (size_t j = 0; j < width; ++j) q[j] /= sqrt(total);
            CettaDenseTensorV1 *query = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, q, sizeof(q));
            int8_widest = 0;
            assert(int8_expect_exact(wide, codes, record, query, NULL, 5) < 150);
            assert(int8_expect_exact(wide, codes, record, query, NULL, 10) < 300);
            assert(int8_widest > 0 && int8_widest < .05);
            cetta_dense_tensor_v1_release(query);
        }
        /* Outside the admitted rounding fragment every row is a candidate. */
        double unit = 1; for (size_t j = 0; j < width; ++j) q[j] = j ? 0 : unit;
        CettaDenseTensorV1 *query = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, q, sizeof(q));
        int old = fegetround(); assert(fesetround(FE_DOWNWARD) == 0);
        CettaDenseTensorV1 *all = NULL, *codes_down = NULL, *record_down = NULL;
        assert(cetta_dense_tensor_v1_int8_candidates(codes, record, query, NULL, 5, &all) == OK);
        assert(cetta_dense_tensor_v1_count(all) == rows); cetta_dense_tensor_v1_release(all);
        assert(cetta_dense_tensor_v1_int8_rows(wide, &codes_down, &record_down) == OK);
        assert(fesetround(old) == 0);
        assert(cetta_dense_tensor_v1_int8_candidates(codes_down, record_down, query, NULL, 5, &all) == OK);
        assert(cetta_dense_tensor_v1_count(all) == rows); cetta_dense_tensor_v1_release(all);
        cetta_dense_tensor_v1_release(codes_down); cetta_dense_tensor_v1_release(record_down);
#if TEST_HAS_MXCSR
        unsigned csr = _mm_getcsr();
        for (unsigned mode = 0; mode < 2; ++mode) {
            _mm_setcsr(csr | (mode ? (1u << 6) : (1u << 15)));
            all = NULL;
            assert(cetta_dense_tensor_v1_int8_candidates(codes, record, query, NULL, 5, &all) == OK);
            _mm_setcsr(csr);
            assert(cetta_dense_tensor_v1_count(all) == rows); cetta_dense_tensor_v1_release(all);
        }
#endif
        /* Refusals: wrong dtypes, shapes and indices, non-finite input. */
        CettaDenseTensorV1 *out = NULL;
        assert(cetta_dense_tensor_v1_int8_candidates(wide, record, query, NULL, 5, &out) == CETTA_DENSE_TENSOR_V1_DTYPE && !out);
        assert(cetta_dense_tensor_v1_int8_candidates(codes, codes, query, NULL, 5, &out) == CETTA_DENSE_TENSOR_V1_DTYPE && !out);
        size_t short_width = 383;
        CettaDenseTensorV1 *narrow = make(CETTA_DENSE_TENSOR_V1_F64, &short_width, 1, q, 383*8);
        assert(cetta_dense_tensor_v1_int8_candidates(codes, record, narrow, NULL, 5, &out) == CETTA_DENSE_TENSOR_V1_SHAPE && !out);
        size_t one = 1; int64_t beyond = (int64_t)rows;
        CettaDenseTensorV1 *outside = make(CETTA_DENSE_TENSOR_V1_I64, &one, 1, &beyond, 8);
        assert(cetta_dense_tensor_v1_int8_candidates(codes, record, query, outside, 5, &out) == CETTA_DENSE_TENSOR_V1_INDEX && !out);
        q[3] = NAN;
        CettaDenseTensorV1 *invalid = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, q, sizeof(q));
        assert(cetta_dense_tensor_v1_int8_candidates(codes, record, invalid, NULL, 5, &out) == CETTA_DENSE_TENSOR_V1_VALUE && !out);
        size_t pair[] = {2, 2}; double bad_rows[] = {1, 0, INFINITY, 0};
        CettaDenseTensorV1 *bad = make(CETTA_DENSE_TENSOR_V1_F64, pair, 2, bad_rows, sizeof(bad_rows)), *bad_codes = NULL, *bad_record = NULL;
        assert(cetta_dense_tensor_v1_int8_rows(bad, &bad_codes, &bad_record) == CETTA_DENSE_TENSOR_V1_VALUE && !bad_codes && !bad_record);
        assert(cetta_dense_tensor_v1_int8_rows(query, &bad_codes, &bad_record) == CETTA_DENSE_TENSOR_V1_SHAPE);
        assert(cetta_dense_tensor_v1_int8_rows(wide, &bad_codes, &bad_codes) == CETTA_DENSE_TENSOR_V1_VALUE);
        cetta_dense_tensor_v1_release(narrow); cetta_dense_tensor_v1_release(outside);
        cetta_dense_tensor_v1_release(invalid); cetta_dense_tensor_v1_release(bad); cetta_dense_tensor_v1_release(query);
        cetta_dense_tensor_v1_release(wide); cetta_dense_tensor_v1_release(codes); cetta_dense_tensor_v1_release(record);
    }
}
#undef OK

static void screening_exponent_reference(void) {
    /* Exercise cancellation, f32 underflow, extreme query/scale exponents,
     * and repeated/permuted selectors. Unsafe arithmetic must keep all rows.
     * These are implementation checks, not a proof of IEEE error analysis. */
    uint32_t seed = 901107;
    const size_t widths[] = {1, 3, 4, 7, 31, 137};
    const int source_exp[] = {-1073, -1022, -150, -126, -30, 0, 30, 120};
    const int query_exp[] = {-1020, -150, -30, 0, 30, 700, 1000};
    const int scale_exp[] = {-1000, -30, 0, 30, 1000};
    size_t count = 8;
    int64_t rows[] = {6, 0, 6, 2, 5, 1, 4, 3};
    CettaDenseTensorV1 *indices = make(CETTA_DENSE_TENSOR_V1_I64, &count, 1, rows, sizeof(rows));
    for (size_t w = 0; w < sizeof(widths)/sizeof(widths[0]); ++w) {
        size_t width = widths[w], shape[] = {7, width};
        for (unsigned trial = 0; trial < 80; ++trial) {
            double data[7*137], q[137];
            for (size_t j = 0; j < 7*width; ++j) {
                seed = seed*1664525u + 1013904223u;
                double value = ((double)(seed%2047u)-1023)/1024;
                data[j] = ldexp(value, source_exp[trial%8]);
            }
            for (size_t j = 0; j < width; ++j) {
                seed = seed*1664525u + 1013904223u;
                q[j] = ldexp(((double)(seed%2047u)-1023)/1024, query_exp[(trial/8)%7]);
            }
            double scale = ldexp(1., scale_exp[trial%5]);
            CettaDenseTensorV1 *wide = make(CETTA_DENSE_TENSOR_V1_F64, shape, 2, data, 7*width*8);
            CettaDenseTensorV1 *query = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, q, width*8);
            CettaDenseTensorV1 *compact=NULL, *cert=NULL, *lo=NULL, *hi=NULL, *exact=NULL;
            assert(cetta_dense_tensor_v1_cast(wide, CETTA_DENSE_TENSOR_V1_F32, &compact) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_row_error_bounds(wide, compact, &cert) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_matvec_bounds(compact, query, cert, indices, scale, &lo, &hi) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_matvec(wide, query, indices, &exact) == CETTA_DENSE_TENSOR_V1_OK);
            const double *l=cetta_dense_tensor_v1_data(lo), *h=cetta_dense_tensor_v1_data(hi), *s=cetta_dense_tensor_v1_data(exact);
            for (size_t i = 0; i < count; ++i) {
                double score = s[i]*scale;
                if (isfinite(score)) assert(l[i] <= score && score <= h[i]);
                else assert(l[i] == -INFINITY && h[i] == INFINITY);
            }
            cetta_dense_tensor_v1_release(wide); cetta_dense_tensor_v1_release(query); cetta_dense_tensor_v1_release(compact);
            cetta_dense_tensor_v1_release(cert); cetta_dense_tensor_v1_release(lo); cetta_dense_tensor_v1_release(hi); cetta_dense_tensor_v1_release(exact);
        }
    }
    cetta_dense_tensor_v1_release(indices);
}

static void selection_reference(void) {
    /* Independent repeated maximum selection, with ties and integer values
     * above binary64's exact range. This does not use the implementation heap. */
    for (unsigned dtype = CETTA_DENSE_TENSOR_V1_I64; dtype <= CETTA_DENSE_TENSOR_V1_F32; ++dtype) {
        for (size_t n = 0; n <= 65u; ++n) {
            int64_t integers[65]; double floats[65]; float compacts[65]; unsigned char bytes[65], mask[65];
            for (size_t i = 0; i < n; ++i) {
                integers[i] = INT64_C(9007199254740992) + (int64_t)((i * 17u) % 23u);
                floats[i] = (double)((int)((i * 17u) % 23u) - 11) / 4.0;
                compacts[i] = (float)floats[i];
                bytes[i] = (unsigned char)((i * 17u) % 23u);
                mask[i] = (i % 3u) != 1u;
            }
            const void *data = dtype == CETTA_DENSE_TENSOR_V1_I64 ? (const void *)integers :
                               dtype == CETTA_DENSE_TENSOR_V1_F64 ? (const void *)floats :
                               dtype == CETTA_DENSE_TENSOR_V1_F32 ? (const void *)compacts : (const void *)bytes;
            CettaDenseTensorV1 *scores = make(dtype, &n, 1u, data, n * cetta_dense_tensor_v1_itemsize(dtype));
            CettaDenseTensorV1 *enabled = make(CETTA_DENSE_TENSOR_V1_U8, &n, 1u, mask, n);
            for (unsigned masked = 0; masked < 2; ++masked) {
                size_t expected[65], count = 0;
                bool used[65] = {false};
                for (;;) {
                    size_t best = n;
                    for (size_t i = 0; i < n; ++i) if (!used[i] && (!masked || mask[i])) {
                        if (best == n || (dtype == CETTA_DENSE_TENSOR_V1_I64 ? integers[i] > integers[best] :
                            dtype == CETTA_DENSE_TENSOR_V1_F64 ? floats[i] > floats[best] :
                            dtype == CETTA_DENSE_TENSOR_V1_F32 ? compacts[i] > compacts[best] : bytes[i] > bytes[best])) best = i;
                    }
                    if (best == n) break;
                    expected[count++] = best; used[best] = true;
                }
                for (size_t k = 0; k <= n + 1u; ++k) {
                    CettaDenseTensorV1 *top = NULL;
                    assert(cetta_dense_tensor_v1_top_k(scores, masked ? enabled : NULL, k, &top) == CETTA_DENSE_TENSOR_V1_OK);
                    size_t wanted = k < count ? k : count;
                    assert(cetta_dense_tensor_v1_count(top) == wanted);
                    const int64_t *actual = cetta_dense_tensor_v1_data(top);
                    for (size_t i = 0; i < wanted; ++i) assert(actual[i] == (int64_t)expected[i]);
                    CettaDenseTensorV1 *gathered = NULL;
                    assert(cetta_dense_tensor_v1_gather(scores, top, &gathered) == CETTA_DENSE_TENSOR_V1_OK);
                    const unsigned char *selected = cetta_dense_tensor_v1_data(gathered);
                    for (size_t i = 0; i < wanted; ++i) assert(!memcmp(selected + i * cetta_dense_tensor_v1_itemsize(dtype),
                        (const unsigned char *)data + expected[i] * cetta_dense_tensor_v1_itemsize(dtype), cetta_dense_tensor_v1_itemsize(dtype)));
                    cetta_dense_tensor_v1_release(gathered); cetta_dense_tensor_v1_release(top);
                }
            }
            CettaDenseTensorV1 *indices = NULL, *rebuilt = NULL, *merged = NULL;
            assert(cetta_dense_tensor_v1_nonzero(enabled, &indices) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_mask_indices(n, indices, &rebuilt) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_equal(enabled, rebuilt));
            assert(cetta_dense_tensor_v1_mask_binary(enabled, rebuilt, false, &merged) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_equal(enabled, merged)); cetta_dense_tensor_v1_release(merged);
            assert(cetta_dense_tensor_v1_mask_binary(enabled, rebuilt, true, &merged) == CETTA_DENSE_TENSOR_V1_OK);
            assert(cetta_dense_tensor_v1_equal(enabled, merged)); cetta_dense_tensor_v1_release(merged);
            assert(cetta_dense_tensor_v1_mask_not(enabled, &merged) == CETTA_DENSE_TENSOR_V1_OK);
            for (size_t i = 0; i < n; ++i)
                assert(((const unsigned char *)cetta_dense_tensor_v1_data(merged))[i] == !mask[i]);
            CettaDenseTensorV1 *combined = NULL;
            assert(cetta_dense_tensor_v1_mask_binary(enabled, merged, true, &combined) == CETTA_DENSE_TENSOR_V1_OK);
            for (size_t i = 0; i < n; ++i)
                assert(((const unsigned char *)cetta_dense_tensor_v1_data(combined))[i] == 1);
            cetta_dense_tensor_v1_release(combined);
            assert(cetta_dense_tensor_v1_mask_binary(enabled, merged, false, &combined) == CETTA_DENSE_TENSOR_V1_OK);
            for (size_t i = 0; i < n; ++i)
                assert(((const unsigned char *)cetta_dense_tensor_v1_data(combined))[i] == 0);
            cetta_dense_tensor_v1_release(combined);
            cetta_dense_tensor_v1_release(merged);
            cetta_dense_tensor_v1_release(rebuilt); cetta_dense_tensor_v1_release(indices);
            cetta_dense_tensor_v1_release(enabled); cetta_dense_tensor_v1_release(scores);
        }
    }
    size_t n = 3; double nonfinite[] = {1, NAN, INFINITY}; unsigned char bits[] = {1, 0, 0};
    CettaDenseTensorV1 *scores = make(CETTA_DENSE_TENSOR_V1_F64, &n, 1, nonfinite, sizeof(nonfinite));
    CettaDenseTensorV1 *mask = make(CETTA_DENSE_TENSOR_V1_U8, &n, 1, bits, sizeof(bits));
    CettaDenseTensorV1 *result = NULL;
    assert(cetta_dense_tensor_v1_top_k(scores, mask, SIZE_MAX, &result) == CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_count(result) == 1 && ((const int64_t *)cetta_dense_tensor_v1_data(result))[0] == 0);
    cetta_dense_tensor_v1_release(result);
    assert(cetta_dense_tensor_v1_top_k(scores, NULL, 0, &result) == CETTA_DENSE_TENSOR_V1_VALUE && !result);
    cetta_dense_tensor_v1_release(mask);
    bits[2] = 2; mask = make(CETTA_DENSE_TENSOR_V1_U8, &n, 1, bits, sizeof(bits));
    assert(cetta_dense_tensor_v1_nonzero(mask, &result) == CETTA_DENSE_TENSOR_V1_VALUE && !result);
    assert(cetta_dense_tensor_v1_mask_not(mask, &result) == CETTA_DENSE_TENSOR_V1_VALUE && !result);
    assert(cetta_dense_tensor_v1_top_k(scores, mask, 1, &result) == CETTA_DENSE_TENSOR_V1_VALUE && !result);
    cetta_dense_tensor_v1_release(mask); cetta_dense_tensor_v1_release(scores);

    float compact_nonfinite[] = {1, NAN, INFINITY};
    scores = make(CETTA_DENSE_TENSOR_V1_F32, &n, 1, compact_nonfinite, sizeof(compact_nonfinite));
    unsigned char compact_enabled[] = {1, 0, 0};
    mask = make(CETTA_DENSE_TENSOR_V1_U8, &n, 1, compact_enabled, sizeof(compact_enabled));
    assert(cetta_dense_tensor_v1_top_k(scores, mask, 1, &result) == CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_count(result) == 1 && ((const int64_t *)cetta_dense_tensor_v1_data(result))[0] == 0);
    cetta_dense_tensor_v1_release(result);
    assert(cetta_dense_tensor_v1_top_k(scores, NULL, 0, &result) == CETTA_DENSE_TENSOR_V1_VALUE && !result);
    cetta_dense_tensor_v1_release(mask); cetta_dense_tensor_v1_release(scores);

    int64_t bad = -1; n = 1;
    CettaDenseTensorV1 *indices = make(CETTA_DENSE_TENSOR_V1_I64, &n, 1, &bad, sizeof(bad));
    assert(cetta_dense_tensor_v1_mask_indices(3, indices, &result) == CETTA_DENSE_TENSOR_V1_INDEX && !result);
    cetta_dense_tensor_v1_release(indices);
    bad = 3; indices = make(CETTA_DENSE_TENSOR_V1_I64, &n, 1, &bad, sizeof(bad));
    assert(cetta_dense_tensor_v1_mask_indices(3, indices, &result) == CETTA_DENSE_TENSOR_V1_INDEX && !result);
    cetta_dense_tensor_v1_release(indices);
}

static void matrix_reference(void) {
    for (size_t width = 0; width <= 33; ++width) {
        double data[4*33], query[33], expected[4] = {0};
        for (size_t j = 0; j < width; ++j) query[j] = (double)((int)(j % 5) - 2) / 4;
        for (size_t i = 0; i < 4; ++i) for (size_t j = 0; j < width; ++j) {
            data[i*width+j] = (double)((int)((i*width+j) % 7) - 3) / 4;
            expected[i] += data[i*width+j] * query[j];
        }
        size_t shape[] = {4, width}, count = 3;
        int64_t rows[] = {3, 0, 3};
        CettaDenseTensorV1 *matrix = make(CETTA_DENSE_TENSOR_V1_F64, shape, 2, data, 4*width*8);
        CettaDenseTensorV1 *q = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, query, width*8);
        CettaDenseTensorV1 *indices = make(CETTA_DENSE_TENSOR_V1_I64, &count, 1, rows, sizeof(rows));
        CettaDenseTensorV1 *out = NULL;
        assert(cetta_dense_tensor_v1_matvec(matrix, q, NULL, &out) == CETTA_DENSE_TENSOR_V1_OK);
        for (size_t i = 0; i < 4; ++i) assert(((const double *)cetta_dense_tensor_v1_data(out))[i] == expected[i]);
        cetta_dense_tensor_v1_release(out);
        assert(cetta_dense_tensor_v1_matvec_with_provider(matrix, q, NULL, CETTA_MATVEC_SCALAR4, &out) == CETTA_DENSE_TENSOR_V1_OK);
        for (size_t i = 0; i < 4; ++i) assert(((const double *)cetta_dense_tensor_v1_data(out))[i] == expected[i]);
        cetta_dense_tensor_v1_release(out);
        assert(cetta_dense_tensor_v1_matvec_with_provider(matrix, q, NULL, (CettaDenseTensorV1MatvecProvider)42, &out)
               == CETTA_DENSE_TENSOR_V1_PROVIDER && !out);
        assert(cetta_dense_tensor_v1_matvec(matrix, q, indices, &out) == CETTA_DENSE_TENSOR_V1_OK);
        for (size_t i = 0; i < count; ++i) assert(((const double *)cetta_dense_tensor_v1_data(out))[i] == expected[rows[i]]);
        cetta_dense_tensor_v1_release(out);
        assert(cetta_dense_tensor_v1_gather(matrix, indices, &out) == CETTA_DENSE_TENSOR_V1_OK);
        for (size_t i = 0; i < count; ++i) if (width) assert(!memcmp(
            (const double *)cetta_dense_tensor_v1_data(out) + i * width, data + rows[i] * width, width * 8));
        cetta_dense_tensor_v1_release(out);
        assert(cetta_dense_tensor_v1_scale(q, 2, &out) == CETTA_DENSE_TENSOR_V1_OK);
        for (size_t i = 0; i < width; ++i) assert(((const double *)cetta_dense_tensor_v1_data(out))[i] == 2*query[i]);
        cetta_dense_tensor_v1_release(out);
        assert(cetta_dense_tensor_v1_div(q, q, &out) == CETTA_DENSE_TENSOR_V1_OK);
        for (size_t i = 0; i < width; ++i) {
            double v = ((const double *)cetta_dense_tensor_v1_data(out))[i];
            assert(query[i] == 0 ? isnan(v) : v == 1);
        }
        cetta_dense_tensor_v1_release(out); cetta_dense_tensor_v1_release(indices);
        cetta_dense_tensor_v1_release(q); cetta_dense_tensor_v1_release(matrix);
    }
    /* Provider conformance uses irregular binary64 values, tails, and repeated
     * row selectors. It checks bit agreement between distinct implementations. */
    size_t width = 1025, shape[] = {7, 1025}, count = 4;
    double data[7*1025], query[1025];
    uint32_t seed = 77109;
    for (size_t j = 0; j < width; ++j) {
        seed = seed * 1664525u + 1013904223u;
        query[j] = ldexp(((double)(seed % 2000001u) - 1000000) / 1000003, (int)(j % 17) - 8);
    }
    for (size_t j = 0; j < 7*width; ++j) {
        seed = seed * 1664525u + 1013904223u;
        data[j] = ((double)(seed % 2000001u) - 1000000) / 1000033;
    }
    int64_t rows[] = {6, 0, 6, 3};
    CettaDenseTensorV1 *matrix = make(CETTA_DENSE_TENSOR_V1_F64, shape, 2, data, sizeof(data));
    CettaDenseTensorV1 *q = make(CETTA_DENSE_TENSOR_V1_F64, &width, 1, query, sizeof(query));
    CettaDenseTensorV1 *indices = make(CETTA_DENSE_TENSOR_V1_I64, &count, 1, rows, sizeof(rows));
    for (unsigned selected = 0; selected < 2; ++selected) {
        CettaDenseTensorV1 *reference = NULL, *actual = NULL;
        assert(cetta_dense_tensor_v1_matvec_with_provider(matrix, q, selected ? indices : NULL,
            CETTA_MATVEC_SCALAR4, &reference) == CETTA_DENSE_TENSOR_V1_OK);
        assert(cetta_dense_tensor_v1_matvec(matrix, q, selected ? indices : NULL, &actual) == CETTA_DENSE_TENSOR_V1_OK);
        assert(cetta_dense_tensor_v1_equal(reference, actual)); cetta_dense_tensor_v1_release(actual);
        CettaDenseTensorV1Status status = cetta_dense_tensor_v1_matvec_with_provider(matrix, q, selected ? indices : NULL,
            CETTA_MATVEC_AVX4, &actual);
        if (cetta_dense_tensor_v1_matvec_provider_available(CETTA_MATVEC_AVX4)) {
            assert(status == CETTA_DENSE_TENSOR_V1_OK && cetta_dense_tensor_v1_equal(reference, actual));
            cetta_dense_tensor_v1_release(actual);
        } else assert(status == CETTA_DENSE_TENSOR_V1_PROVIDER && !actual);
        cetta_dense_tensor_v1_release(reference);
    }
    cetta_dense_tensor_v1_release(indices); cetta_dense_tensor_v1_release(q); cetta_dense_tensor_v1_release(matrix);
}

/* The content hash keeps its definition when it is computed on demand: FNV-1a
 * over the little-endian bytes, then the dtype, rank and each dimension as
 * 64-bit words. Equality answers alike whether hashes are known or not. */
static uint32_t reference_fnv(uint32_t hash, const unsigned char *bytes, size_t n) {
    for (size_t i = 0; i < n; ++i) hash = (hash ^ bytes[i]) * UINT32_C(16777619);
    return hash;
}
static uint32_t reference_word(uint32_t hash, uint64_t word) {
    unsigned char bytes[8];
    for (unsigned i = 0; i < 8u; ++i) bytes[i] = (unsigned char)(word >> (8u * i));
    return reference_fnv(hash, bytes, 8u);
}
static uint32_t reference_hash(CettaDenseTensorV1DType dtype, const size_t *shape, size_t rank,
    const void *data, size_t bytes) {
    uint32_t hash = reference_fnv(UINT32_C(2166136261), data, bytes);
    hash = reference_word(reference_word(hash, (uint64_t)dtype), rank);
    for (size_t i = 0; i < rank; ++i) hash = reference_word(hash, shape[i]);
    return hash;
}
static void lazy_hash_reference(void) {
    double values[6] = {1.5, -0., 3., 1e-300, -7.25, 2.};
    size_t flat[] = {6u}, grid[] = {2u, 3u};
    CettaDenseTensorV1 *a = make(CETTA_DENSE_TENSOR_V1_F64, flat, 1u, values, sizeof values);
    CettaDenseTensorV1 *b = make(CETTA_DENSE_TENSOR_V1_F64, flat, 1u, values, sizeof values);
    assert(cetta_dense_tensor_v1_equal(a, b));
    assert(cetta_dense_tensor_v1_hash(a) == reference_hash(CETTA_DENSE_TENSOR_V1_F64, flat, 1u, values, sizeof values));
    assert(cetta_dense_tensor_v1_equal(a, b) && cetta_dense_tensor_v1_equal(b, a));
    assert(cetta_dense_tensor_v1_hash(b) == cetta_dense_tensor_v1_hash(a));
    CettaDenseTensorV1 *view = NULL;
    assert(cetta_dense_tensor_v1_reshape(a, grid, 2u, &view) == CETTA_DENSE_TENSOR_V1_OK);
    CettaDenseTensorV1 *fresh = make(CETTA_DENSE_TENSOR_V1_F64, grid, 2u, values, sizeof values);
    assert(cetta_dense_tensor_v1_hash(view) == reference_hash(CETTA_DENSE_TENSOR_V1_F64, grid, 2u, values, sizeof values));
    assert(cetta_dense_tensor_v1_hash(fresh) == cetta_dense_tensor_v1_hash(view));
    assert(cetta_dense_tensor_v1_hash(view) != cetta_dense_tensor_v1_hash(a));
    double other[6];
    memcpy(other, values, sizeof other);
    other[5] = 2.0000000000000004;
    CettaDenseTensorV1 *c = make(CETTA_DENSE_TENSOR_V1_F64, flat, 1u, other, sizeof other);
    assert(!cetta_dense_tensor_v1_equal(a, c) && !cetta_dense_tensor_v1_equal(c, a));
    assert(cetta_dense_tensor_v1_hash(c) != cetta_dense_tensor_v1_hash(a));
    assert(!cetta_dense_tensor_v1_equal(a, c));
    float narrow[3] = {1.f, -2.f, .5f};
    size_t three[] = {3u}, five[] = {5u};
    CettaDenseTensorV1 *f = make(CETTA_DENSE_TENSOR_V1_F32, three, 1u, narrow, sizeof narrow);
    assert(cetta_dense_tensor_v1_hash(f) == reference_hash(CETTA_DENSE_TENSOR_V1_F32, three, 1u, narrow, sizeof narrow));
    unsigned char bytes[5] = {0u, 1u, 254u, 255u, 7u};
    CettaDenseTensorV1 *u = make(CETTA_DENSE_TENSOR_V1_U8, five, 1u, bytes, sizeof bytes);
    assert(cetta_dense_tensor_v1_hash(u) == reference_hash(CETTA_DENSE_TENSOR_V1_U8, five, 1u, bytes, sizeof bytes));
    CettaDenseTensorV1 *all[] = {a, b, view, fresh, c, f, u};
    for (size_t i = 0; i < sizeof all / sizeof all[0]; ++i) cetta_dense_tensor_v1_release(all[i]);
}

int main(void) {
    SymbolTable symbols; symbol_table_init(&symbols);
    symbol_table_init_builtins(&symbols, &g_builtin_syms); g_symbols = &symbols;
    g_hashcons = NULL; g_var_intern = NULL;
    Arena origin, survivor; arena_init_detached(&origin); arena_init_detached(&survivor);
    assert(cetta_dense_tensor_v1_owns_head(atom_symbol(&origin, "__cetta_lib_tensor_from")));
    assert(cetta_dense_tensor_v1_owns_head(atom_symbol(&origin, "__cetta_lib_tensor_cast")));
    assert(cetta_dense_tensor_v1_owns_head(atom_symbol(&origin, "__cetta_lib_tensor_matvec_bounds_selected")));
    Atom *future_operation = atom_symbol(&origin, "__cetta_lib_tensor_future_operation");
    assert(!cetta_dense_tensor_v1_owns_head(future_operation));
    assert(!cetta_dense_tensor_v1_dispatch(&origin, future_operation, NULL, 0u));
    assert(!cetta_dense_tensor_v1_owns_head(atom_symbol(&origin, "__cetta_lib_str")));
    assert(!cetta_dense_tensor_v1_owns_head(atom_int(&origin, 0)));
    assert(!cetta_dense_tensor_v1_owns_head(NULL));
    size_t shape[] = {4u}; int64_t entries[] = {1, 2, 3, 4};
    CettaDenseTensorV1 *tensor = make(CETTA_DENSE_TENSOR_V1_I64, shape, 1u, entries, sizeof(entries));
    Atom *atom = atom_tensor(&origin, tensor);
    assert(origin.external_bytes >= cetta_dense_tensor_v1_retained_bytes(tensor));
    Atom *copy = atom_deep_copy(&survivor, atom);
    assert(copy && copy->arena_id == survivor.identity);
    assert(atom_eq(copy, atom) && atom_hash(copy) == atom_hash(atom));
    assert(cetta_dense_tensor_v1_shares_storage(copy->ground.ptr, tensor));
    codecs(&survivor, atom);
    ArenaMark mark = arena_mark(&survivor);
    atom_tensor(&survivor, tensor);
    assert(survivor.external_bytes >= mark.external_bytes + cetta_dense_tensor_v1_retained_bytes(tensor));
    arena_reset(&survivor, mark);
    assert(survivor.external_bytes == mark.external_bytes);
    assert(atom_eq(copy, atom));

    /* A view outlives both its producing descriptor and original arena. */
    size_t reshaped[] = {2u, 2u}; CettaDenseTensorV1 *view = NULL;
    assert(cetta_dense_tensor_v1_reshape(tensor, reshaped, 2u, &view) == CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_shares_storage(tensor, view));
    assert(!cetta_dense_tensor_v1_equal(tensor, view));
    cetta_dense_tensor_v1_release(tensor);
    arena_free(&origin);
    assert(((const int64_t *)cetta_dense_tensor_v1_data(view))[3] == 4);

    CettaDenseTensorV1 *updated = NULL; int64_t replacement = 99;
    assert(cetta_dense_tensor_v1_with(copy->ground.ptr, 0u, &replacement, &updated) == CETTA_DENSE_TENSOR_V1_OK);
    assert(!cetta_dense_tensor_v1_shares_storage(copy->ground.ptr, updated));
    assert(((const int64_t *)cetta_dense_tensor_v1_data(copy->ground.ptr))[0] == 1);
    assert(((const int64_t *)cetta_dense_tensor_v1_data(updated))[0] == 99);
    cetta_dense_tensor_v1_release(updated);
    assert(cetta_dense_tensor_v1_with(copy->ground.ptr, 4u, &replacement, &updated) == CETTA_DENSE_TENSOR_V1_INDEX);
    assert(!updated);
    CettaDenseTensorV1Scalar sum;
    assert(cetta_dense_tensor_v1_reduce(copy->ground.ptr, NULL, &sum) == CETTA_DENSE_TENSOR_V1_OK && sum.value.integer == 10);
    assert(cetta_dense_tensor_v1_reduce(copy->ground.ptr, copy->ground.ptr, &sum) == CETTA_DENSE_TENSOR_V1_OK && sum.value.integer == 30);
    assert(cetta_dense_tensor_v1_reduce(view, view, &sum) == CETTA_DENSE_TENSOR_V1_SHAPE);
    assert(cetta_dense_tensor_v1_binary(view, copy->ground.ptr, false, &updated) == CETTA_DENSE_TENSOR_V1_SHAPE);
    cetta_dense_tensor_v1_release(view);

    pthread_t threads[4];
    for (unsigned i = 0; i < 4; ++i) assert(!pthread_create(&threads[i], NULL, copy_worker, copy->ground.ptr));
    for (unsigned i = 0; i < 4; ++i) assert(!pthread_join(threads[i], NULL));

    /* Exact bit identity, independent of scalar IEEE comparison. */
    uint64_t bits[] = {UINT64_C(0x7ff8000000000001), UINT64_C(0x8000000000000000)};
    size_t pair[] = {2u};
    CettaDenseTensorV1 *nan = make(CETTA_DENSE_TENSOR_V1_F64, pair, 1u, bits, sizeof(bits));
    CettaDenseTensorV1 *same = NULL;
    assert(cetta_dense_tensor_v1_copy(nan, &same) == CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_equal(nan, same) && cetta_dense_tensor_v1_compare(nan, same) == 0);
    assert(cetta_dense_tensor_v1_hash(nan) == cetta_dense_tensor_v1_hash(same));
    codecs(&survivor, atom_tensor(&survivor, nan));
    cetta_dense_tensor_v1_release(same);
    bits[1] = 0u;
    same = make(CETTA_DENSE_TENSOR_V1_F64, pair, 1u, bits, sizeof(bits));
    assert(!cetta_dense_tensor_v1_equal(nan, same) && cetta_dense_tensor_v1_compare(nan, same) != 0);
    cetta_dense_tensor_v1_release(same); cetta_dense_tensor_v1_release(nan);

    /* The codec has an independently specified little-endian golden value. */
    int64_t scalar = -2;
    tensor = make(CETTA_DENSE_TENSOR_V1_I64, NULL, 0u, &scalar, 8u);
    const unsigned char golden[] = {'C','T','N','1',1,0,0,0,0,254,255,255,255,255,255,255,255};
    unsigned char *encoded = NULL; size_t size = 0;
    assert(cetta_dense_tensor_v1_encode(tensor, &encoded, &size) == CETTA_DENSE_TENSOR_V1_OK);
    assert(size == sizeof(golden) && !memcmp(encoded, golden, size));
    assert(cetta_dense_tensor_v1_decode(golden, sizeof(golden), &same) == CETTA_DENSE_TENSOR_V1_OK);
    assert(cetta_dense_tensor_v1_equal(tensor, same)); cetta_dense_tensor_v1_release(same);
    for (size_t i = 0; i < size; ++i) {
        same = NULL;
        assert(cetta_dense_tensor_v1_decode(encoded, i, &same) != CETTA_DENSE_TENSOR_V1_OK && !same);
    }
    encoded[4] = 255u;
    assert(cetta_dense_tensor_v1_decode(encoded, size, &same) == CETTA_DENSE_TENSOR_V1_DTYPE && !same);
    free(encoded); cetta_dense_tensor_v1_release(tensor);

    /* Transport limits are checked before allocating a serialized tensor. */
    size_t large_shape[] = {CETTA_ATOM_WIRE_BYTES};
    unsigned char *large = calloc(large_shape[0], 1u);
    assert(large);
    tensor = make(CETTA_DENSE_TENSOR_V1_U8, large_shape, 1u, large, large_shape[0]);
    free(large);
    assert(cetta_dense_tensor_v1_encoded_size(tensor, &size) == CETTA_DENSE_TENSOR_V1_OK);
    assert(size == large_shape[0] + 17u);
    atom = atom_tensor(&survivor, tensor);
    encoded = NULL;
    assert(cetta_atom_wire_encode(atom, &encoded, &size) == ATOM_WIRE_LIMIT && !encoded);
    assert(cetta_durable_value_encode(atom, &encoded, &size) == DURABLE_LIMIT && !encoded);
    cetta_dense_tensor_v1_release(tensor);

    size_t count, bytes, enormous[] = {SIZE_MAX, 2u, 0u, 3u};
    assert(cetta_dense_tensor_v1_byte_count(CETTA_DENSE_TENSOR_V1_F64, enormous, 4u, &count, &bytes) == CETTA_DENSE_TENSOR_V1_OK);
    assert(!count && !bytes);
    tensor = make(CETTA_DENSE_TENSOR_V1_F64, enormous, 4u, NULL, 0u);
    assert(cetta_dense_tensor_v1_reduce(tensor, NULL, &sum) == CETTA_DENSE_TENSOR_V1_OK && sum.value.floating == 0.0);
    cetta_dense_tensor_v1_release(tensor);
    assert(cetta_dense_tensor_v1_byte_count(CETTA_DENSE_TENSOR_V1_F64, enormous, 2u, &count, &bytes) == CETTA_DENSE_TENSOR_V1_OVERFLOW);
    assert(cetta_dense_tensor_v1_byte_count(CETTA_DENSE_TENSOR_V1_F64, enormous, 1u, &count, &bytes) == CETTA_DENSE_TENSOR_V1_OVERFLOW);
    assert(cetta_dense_tensor_v1_new(CETTA_DENSE_TENSOR_V1_I64, shape, 1u, entries, 8u, &tensor) == CETTA_DENSE_TENSOR_V1_COUNT && !tensor);

    int64_t over[] = {INT64_MAX, 1};
    tensor = make(CETTA_DENSE_TENSOR_V1_I64, pair, 1u, over, sizeof(over));
    assert(cetta_dense_tensor_v1_reduce(tensor, NULL, &sum) == CETTA_DENSE_TENSOR_V1_OVERFLOW);
    assert(cetta_dense_tensor_v1_binary(tensor, tensor, false, &same) == CETTA_DENSE_TENSOR_V1_OVERFLOW && !same);
    assert(((const int64_t *)cetta_dense_tensor_v1_data(tensor))[0] == INT64_MAX);
    cetta_dense_tensor_v1_release(tensor);
    unsigned char u8[] = {255, 1};
    tensor = make(CETTA_DENSE_TENSOR_V1_U8, pair, 1u, u8, sizeof(u8));
    assert(cetta_dense_tensor_v1_binary(tensor, tensor, false, &same) == CETTA_DENSE_TENSOR_V1_OVERFLOW && !same);
    assert(cetta_dense_tensor_v1_reduce(tensor, NULL, &sum) == CETTA_DENSE_TENSOR_V1_OK && sum.value.integer == 256);
    cetta_dense_tensor_v1_release(tensor);
    arithmetic_reference();
    selection_reference(); matrix_reference(); lazy_hash_reference(); compact_screening_reference(); int8_screening_reference(); screening_exponent_reference();
    arena_free(&survivor); symbol_table_free(&symbols);
    puts("PASS: native tensor ownership, alternatives, arithmetic, bounds and codecs");
    return 0;
}
