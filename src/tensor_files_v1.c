#define _POSIX_C_SOURCE 200809L
#include "tensor_files_v1.h"

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <limits.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

/* The NumPy reader refuses headers beyond 10000 bytes unless asked; a header
 * of a mebibyte has room for any shape. Safetensors fixes its own bound. */
#define NPY_HEADER_LIMIT ((size_t)1 << 20)
#define SAFETENSORS_HEADER_LIMIT ((uint64_t)100000000u)
#define RANK_LIMIT 64u

#if !defined(__BYTE_ORDER__) || __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
#define HOST_LITTLE_ENDIAN 0
#else
#define HOST_LITTLE_ENDIAN 1
#endif

static bool fail(CettaTensorFileError *e, const char *reason, const char *format, ...) {
    if (e) {
        va_list list;
        e->reason = reason;
        va_start(list, format);
        vsnprintf(e->detail, sizeof e->detail, format, list);
        va_end(list);
    }
    return false;
}

static bool fail_errno(CettaTensorFileError *e, const char *reason, int number) {
    return fail(e, reason, "%s", strerror(number));
}

static uint64_t le(const unsigned char *p, size_t width) {
    uint64_t value = 0u;
    for (size_t i = 0; i < width; ++i) value |= (uint64_t)p[i] << (8u * i);
    return value;
}

static uint64_t be(const unsigned char *p, size_t width) {
    uint64_t value = 0u;
    for (size_t i = 0; i < width; ++i) value = value << 8u | p[i];
    return value;
}

const char *cetta_tensor_file_format_name(CettaTensorFileFormat format) {
    return format == CETTA_TENSOR_FILE_NPY ? "npy" :
        format == CETTA_TENSOR_FILE_SAFETENSORS ? "safetensors" :
        format == CETTA_TENSOR_FILE_CTN1 ? "ctn1" : "unknown";
}

/* ------------------------------------------------------------- mappings */

typedef struct {
    _Atomic size_t refs;
    void *base;
    size_t length;
} Mapping;

static void mapping_drop(void *context) {
    Mapping *mapping = context;
    if (atomic_fetch_sub_explicit(&mapping->refs, 1u, memory_order_acq_rel) == 1u) {
        munmap(mapping->base, mapping->length);
        free(mapping);
    }
}

static bool map_file(const char *path, Mapping **out, CettaTensorFileError *e) {
    *out = NULL;
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return fail_errno(e, "file-unreadable", errno);
    struct stat info;
    if (fstat(fd, &info) != 0) {
        int number = errno;
        close(fd);
        return fail_errno(e, "file-unreadable", number);
    }
    if (!S_ISREG(info.st_mode)) {
        close(fd);
        return fail(e, "not-a-regular-file", "%s", path);
    }
    if (info.st_size < 8) {
        close(fd);
        return fail(e, "truncated", "%lld bytes is shorter than any tensor file header",
            (long long)info.st_size);
    }
    if ((uintmax_t)info.st_size > SIZE_MAX) {
        close(fd);
        return fail(e, "file-too-large", "%lld bytes", (long long)info.st_size);
    }
    size_t length = (size_t)info.st_size;
    void *base = mmap(NULL, length, PROT_READ, MAP_PRIVATE, fd, 0);
    int number = errno;
    close(fd);
    if (base == MAP_FAILED) return fail_errno(e, "file-unreadable", number);
    Mapping *mapping = malloc(sizeof *mapping);
    if (!mapping) {
        munmap(base, length);
        return fail(e, "out-of-memory", "mapping descriptor");
    }
    atomic_init(&mapping->refs, 1u);
    mapping->base = base;
    mapping->length = length;
    *out = mapping;
    return true;
}

/* ----------------------------------------------------- element types */

typedef struct {
    CettaDenseTensorV1DType dtype;
    uint8_t width;
    uint8_t conversion;
} Element;

static const char *conversion_reason(const CettaTensorFileEntry *entry) {
    switch (entry->conversion) {
    case CETTA_TENSOR_FILE_F16: return "f16 widens to f32";
    case CETTA_TENSOR_FILE_BF16: return "bf16 widens to f32";
    case CETTA_TENSOR_FILE_SIGNED: return "a narrower integer widens to i64";
    case CETTA_TENSOR_FILE_UNSIGNED: return "an unsigned integer converts to i64";
    default: break;
    }
    if (entry->big_endian) return "big-endian bytes";
    if (entry->fortran_order) return "Fortran order";
    if (!HOST_LITTLE_ENDIAN) return "this host is big-endian";
    if (entry->offset % entry->width != 0u) return "data not aligned to its element width";
    return NULL;
}

static bool npy_element(const char *descr, Element *element, bool *big_endian) {
    char order = descr[0];
    if (order != '<' && order != '>' && order != '|' && order != '=') return false;
    char kind = descr[1];
    if (!kind || descr[2] < '0' || descr[2] > '9') return false;
    unsigned long size = 0u;
    for (const char *p = descr + 2; *p; ++p) {
        if (*p < '0' || *p > '9' || size > 64u) return false;
        size = size * 10u + (unsigned long)(*p - '0');
    }
    *big_endian = order == '>' && size > 1u;
    if (order == '|' && size > 1u) return false;
    element->width = (uint8_t)size;
    element->conversion = CETTA_TENSOR_FILE_SAME;
    switch (kind) {
    case 'f':
        if (size == 8u) element->dtype = CETTA_DENSE_TENSOR_V1_F64;
        else if (size == 4u) element->dtype = CETTA_DENSE_TENSOR_V1_F32;
        else if (size == 2u) { element->dtype = CETTA_DENSE_TENSOR_V1_F32; element->conversion = CETTA_TENSOR_FILE_F16; }
        else return false;
        return true;
    case 'i':
        if (size != 1u && size != 2u && size != 4u && size != 8u) return false;
        element->dtype = CETTA_DENSE_TENSOR_V1_I64;
        if (size != 8u) element->conversion = CETTA_TENSOR_FILE_SIGNED;
        return true;
    case 'u':
        if (size == 1u) { element->dtype = CETTA_DENSE_TENSOR_V1_U8; return true; }
        if (size != 2u && size != 4u && size != 8u) return false;
        element->dtype = CETTA_DENSE_TENSOR_V1_I64;
        element->conversion = CETTA_TENSOR_FILE_UNSIGNED;
        return true;
    case 'b':
        if (size != 1u) return false;
        element->dtype = CETTA_DENSE_TENSOR_V1_U8;
        return true;
    default:
        return false;
    }
}

static bool safetensors_element(const char *name, Element *element) {
    static const struct { const char *name; CettaDenseTensorV1DType dtype; uint8_t width, conversion; } table[] = {
        {"F64", CETTA_DENSE_TENSOR_V1_F64, 8u, CETTA_TENSOR_FILE_SAME},
        {"F32", CETTA_DENSE_TENSOR_V1_F32, 4u, CETTA_TENSOR_FILE_SAME},
        {"F16", CETTA_DENSE_TENSOR_V1_F32, 2u, CETTA_TENSOR_FILE_F16},
        {"BF16", CETTA_DENSE_TENSOR_V1_F32, 2u, CETTA_TENSOR_FILE_BF16},
        {"I64", CETTA_DENSE_TENSOR_V1_I64, 8u, CETTA_TENSOR_FILE_SAME},
        {"I32", CETTA_DENSE_TENSOR_V1_I64, 4u, CETTA_TENSOR_FILE_SIGNED},
        {"I16", CETTA_DENSE_TENSOR_V1_I64, 2u, CETTA_TENSOR_FILE_SIGNED},
        {"I8", CETTA_DENSE_TENSOR_V1_I64, 1u, CETTA_TENSOR_FILE_SIGNED},
        {"U64", CETTA_DENSE_TENSOR_V1_I64, 8u, CETTA_TENSOR_FILE_UNSIGNED},
        {"U32", CETTA_DENSE_TENSOR_V1_I64, 4u, CETTA_TENSOR_FILE_UNSIGNED},
        {"U16", CETTA_DENSE_TENSOR_V1_I64, 2u, CETTA_TENSOR_FILE_UNSIGNED},
        {"U8", CETTA_DENSE_TENSOR_V1_U8, 1u, CETTA_TENSOR_FILE_SAME},
        {"BOOL", CETTA_DENSE_TENSOR_V1_U8, 1u, CETTA_TENSOR_FILE_SAME},
    };
    for (size_t i = 0; i < sizeof table / sizeof table[0]; ++i) {
        if (strcmp(name, table[i].name) == 0) {
            element->dtype = table[i].dtype;
            element->width = table[i].width;
            element->conversion = table[i].conversion;
            return true;
        }
    }
    return false;
}

static const char *safetensors_name(CettaDenseTensorV1DType dtype) {
    return dtype == CETTA_DENSE_TENSOR_V1_F64 ? "F64" : dtype == CETTA_DENSE_TENSOR_V1_F32 ? "F32" :
        dtype == CETTA_DENSE_TENSOR_V1_I64 ? "I64" : dtype == CETTA_DENSE_TENSOR_V1_U8 ? "U8" : NULL;
}

static const char *npy_descr(CettaDenseTensorV1DType dtype) {
    return dtype == CETTA_DENSE_TENSOR_V1_F64 ? "<f8" : dtype == CETTA_DENSE_TENSOR_V1_F32 ? "<f4" :
        dtype == CETTA_DENSE_TENSOR_V1_I64 ? "<i8" : dtype == CETTA_DENSE_TENSOR_V1_U8 ? "|u1" : NULL;
}

/* The element count and stored bytes of a shape, refusing overflow. */
static bool stored_bytes(const size_t *shape, size_t rank, size_t width, uint64_t *count, uint64_t *bytes) {
    uint64_t n = 1u;
    bool zero = false;
    for (size_t i = 0; i < rank; ++i) if (shape[i] == 0u) zero = true;
    if (zero) { *count = 0u; *bytes = 0u; return true; }
    for (size_t i = 0; i < rank; ++i) {
        if (n > UINT64_MAX / shape[i]) return false;
        n *= shape[i];
    }
    if (n > UINT64_MAX / width) return false;
    *count = n;
    *bytes = n * width;
    return true;
}

/* ------------------------------------------------- file descriptions */

void cetta_tensor_file_free(CettaTensorFile *file) {
    if (!file) return;
    for (size_t i = 0; i < file->count; ++i) {
        free(file->entries[i].name);
        free(file->entries[i].shape);
    }
    for (size_t i = 0; i < file->metadata_count; ++i) {
        free(file->metadata_keys[i]);
        free(file->metadata_values[i]);
    }
    free(file->entries);
    free(file->metadata_keys);
    free(file->metadata_values);
    free(file);
}

static CettaTensorFileEntry *add_entry(CettaTensorFile *file, size_t *capacity) {
    if (file->count == *capacity) {
        size_t next = *capacity ? *capacity * 2u : 4u;
        if (next > SIZE_MAX / sizeof *file->entries) return NULL;
        CettaTensorFileEntry *grown = realloc(file->entries, next * sizeof *grown);
        if (!grown) return NULL;
        file->entries = grown;
        *capacity = next;
    }
    CettaTensorFileEntry *entry = &file->entries[file->count++];
    memset(entry, 0, sizeof *entry);
    return entry;
}

static bool finish_entry(CettaTensorFileEntry *entry, uint64_t file_bytes, CettaTensorFileError *e) {
    uint64_t count, bytes;
    if (!stored_bytes(entry->shape, entry->rank, entry->width, &count, &bytes))
        return fail(e, "malformed-header", "the shape of %s overflows", entry->name);
    if (entry->bytes != UINT64_MAX && entry->bytes != bytes)
        return fail(e, "malformed-header", "%s holds %" PRIu64 " bytes for %" PRIu64 " elements of %u",
            entry->name, entry->bytes, count, entry->width);
    entry->bytes = bytes;
    if (entry->offset > file_bytes || bytes > file_bytes - entry->offset)
        return fail(e, "truncated", "%s needs %" PRIu64 " bytes from offset %" PRIu64, entry->name, bytes, entry->offset);
    /* Rank one or less, or a single element, has one layout either way. */
    if (entry->fortran_order && count <= 1u) entry->fortran_order = false;
    if (entry->fortran_order && entry->rank < 2u) entry->fortran_order = false;
    entry->copy_reason = conversion_reason(entry);
    return true;
}

/* --------------------------------------------------------------- NumPy */

typedef struct {
    const unsigned char *p, *end;
} Literal;

static void literal_space(Literal *l) {
    while (l->p < l->end && (*l->p == ' ' || *l->p == '\t' || *l->p == '\n' || *l->p == '\r')) l->p++;
}

static bool literal_eat(Literal *l, char c) {
    literal_space(l);
    if (l->p < l->end && *l->p == (unsigned char)c) { l->p++; return true; }
    return false;
}

static bool literal_word(Literal *l, const char *word) {
    literal_space(l);
    size_t n = strlen(word);
    if ((size_t)(l->end - l->p) < n || memcmp(l->p, word, n) != 0) return false;
    l->p += n;
    return true;
}

static bool literal_string(Literal *l, char *out, size_t capacity) {
    literal_space(l);
    if (l->p >= l->end || (*l->p != '\'' && *l->p != '"')) return false;
    unsigned char quote = *l->p++;
    size_t n = 0u;
    while (l->p < l->end && *l->p != quote) {
        if (*l->p == '\\' || n + 1u >= capacity) return false;
        out[n++] = (char)*l->p++;
    }
    if (l->p >= l->end) return false;
    l->p++;
    out[n] = '\0';
    return true;
}

static bool literal_natural(Literal *l, uint64_t *value) {
    literal_space(l);
    if (l->p >= l->end || *l->p < '0' || *l->p > '9') return false;
    uint64_t v = 0u;
    while (l->p < l->end && *l->p >= '0' && *l->p <= '9') {
        unsigned digit = (unsigned)(*l->p++ - '0');
        if (v > (UINT64_MAX - digit) / 10u) return false;
        v = v * 10u + digit;
    }
    if (l->p < l->end && *l->p == 'L') l->p++;   /* Python 2's long suffix */
    *value = v;
    return true;
}

static bool parse_npy(const unsigned char *p, size_t n, CettaTensorFile *file, CettaTensorFileError *e) {
    if (n < 10u) return fail(e, "truncated", "NumPy preamble");
    unsigned major = p[6], minor = p[7];
    size_t start, length;
    if (major == 1u && minor == 0u) {
        length = (size_t)le(p + 8, 2u);
        start = 10u;
    } else if ((major == 2u || major == 3u) && minor == 0u) {
        if (n < 12u) return fail(e, "truncated", "NumPy preamble");
        length = (size_t)le(p + 8, 4u);
        start = 12u;
    } else {
        return fail(e, "unsupported-version", "NumPy format %u.%u", major, minor);
    }
    if (length > NPY_HEADER_LIMIT) return fail(e, "header-too-large", "%zu bytes", length);
    if (length == 0u || length > n - start) return fail(e, "truncated", "NumPy header");
    const unsigned char *header = p + start;
    if (header[length - 1u] != '\n') return fail(e, "malformed-header", "the NumPy header does not end its line");
    Literal l = {header, header + length};
    char descr[16] = {0}, key[32];
    bool have_descr = false, have_order = false, have_shape = false, fortran = false;
    size_t rank = 0u;
    uint64_t dims[RANK_LIMIT];
    if (!literal_eat(&l, '{')) return fail(e, "malformed-header", "the NumPy header is not a dictionary");
    if (!literal_eat(&l, '}')) {
        for (;;) {
            if (!literal_string(&l, key, sizeof key) || !literal_eat(&l, ':'))
                return fail(e, "malformed-header", "a NumPy header key");
            if (strcmp(key, "descr") == 0) {
                if (have_descr) return fail(e, "malformed-header", "descr appears twice");
                if (!literal_string(&l, descr, sizeof descr))
                    return fail(e, "unsupported-dtype", "a structured or unreadable descr");
                have_descr = true;
            } else if (strcmp(key, "fortran_order") == 0) {
                if (have_order) return fail(e, "malformed-header", "fortran_order appears twice");
                if (literal_word(&l, "True")) fortran = true;
                else if (literal_word(&l, "False")) fortran = false;
                else return fail(e, "malformed-header", "fortran_order is not True or False");
                have_order = true;
            } else if (strcmp(key, "shape") == 0) {
                if (have_shape) return fail(e, "malformed-header", "shape appears twice");
                if (!literal_eat(&l, '(')) return fail(e, "malformed-header", "shape is not a tuple");
                if (!literal_eat(&l, ')')) {
                    for (;;) {
                        uint64_t dim;
                        if (!literal_natural(&l, &dim) || dim > SIZE_MAX)
                            return fail(e, "malformed-header", "a shape entry is not a natural number");
                        if (rank == RANK_LIMIT) return fail(e, "malformed-header", "more than %u dimensions", RANK_LIMIT);
                        dims[rank++] = dim;
                        if (literal_eat(&l, ',')) { if (literal_eat(&l, ')')) break; continue; }
                        if (literal_eat(&l, ')')) {
                            if (rank == 1u) return fail(e, "malformed-header", "a one-element shape lacks its comma");
                            break;
                        }
                        return fail(e, "malformed-header", "shape");
                    }
                }
                have_shape = true;
            } else {
                return fail(e, "malformed-header", "unknown NumPy header key %s", key);
            }
            if (literal_eat(&l, ',')) { if (literal_eat(&l, '}')) break; continue; }
            if (literal_eat(&l, '}')) break;
            return fail(e, "malformed-header", "the NumPy header dictionary");
        }
    }
    literal_space(&l);
    if (l.p != l.end) return fail(e, "malformed-header", "text after the NumPy header dictionary");
    if (!have_descr || !have_order || !have_shape)
        return fail(e, "malformed-header", "the NumPy header lacks descr, fortran_order or shape");
    Element element;
    bool big = false;
    if (!npy_element(descr, &element, &big)) return fail(e, "unsupported-dtype", "%s", descr);
    size_t capacity = 0u;
    CettaTensorFileEntry *entry = add_entry(file, &capacity);
    if (!entry) return fail(e, "out-of-memory", "entry");
    entry->name = calloc(1u, 1u);
    entry->shape = rank ? malloc(rank * sizeof *entry->shape) : NULL;
    if (!entry->name || (rank && !entry->shape)) return fail(e, "out-of-memory", "shape");
    for (size_t i = 0; i < rank; ++i) entry->shape[i] = (size_t)dims[i];
    entry->rank = rank;
    snprintf(entry->stored_dtype, sizeof entry->stored_dtype, "%s", descr);
    entry->dtype = element.dtype;
    entry->width = element.width;
    entry->conversion = element.conversion;
    entry->big_endian = big;
    entry->fortran_order = fortran;
    entry->offset = start + length;
    entry->bytes = UINT64_MAX;
    file->format = CETTA_TENSOR_FILE_NPY;
    return finish_entry(entry, n, e);
}

/* ---------------------------------------------------------- safetensors */

typedef struct {
    const unsigned char *p, *end;
} Json;

static void json_space(Json *j) {
    while (j->p < j->end && (*j->p == ' ' || *j->p == '\t' || *j->p == '\n' || *j->p == '\r')) j->p++;
}

static bool json_eat(Json *j, char c) {
    json_space(j);
    if (j->p < j->end && *j->p == (unsigned char)c) { j->p++; return true; }
    return false;
}

static int hex_digit(unsigned char c) {
    return c >= '0' && c <= '9' ? c - '0' : c >= 'a' && c <= 'f' ? c - 'a' + 10 :
        c >= 'A' && c <= 'F' ? c - 'A' + 10 : -1;
}

static bool json_hex4(Json *j, uint32_t *value) {
    if (j->end - j->p < 4) return false;
    uint32_t v = 0u;
    for (int i = 0; i < 4; ++i) {
        int digit = hex_digit(*j->p++);
        if (digit < 0) return false;
        v = v << 4u | (uint32_t)digit;
    }
    *value = v;
    return true;
}

static bool utf8_valid(const unsigned char *s, size_t n) {
    size_t i = 0u;
    while (i < n) {
        unsigned char c = s[i];
        size_t extra;
        uint32_t cp;
        if (c < 0x80u) { i++; continue; }
        if (c >= 0xc2u && c <= 0xdfu) { extra = 1u; cp = c & 0x1fu; }
        else if (c >= 0xe0u && c <= 0xefu) { extra = 2u; cp = c & 0x0fu; }
        else if (c >= 0xf0u && c <= 0xf4u) { extra = 3u; cp = c & 0x07u; }
        else return false;
        if (n - i <= extra) return false;
        for (size_t k = 1; k <= extra; ++k) {
            if ((s[i + k] & 0xc0u) != 0x80u) return false;
            cp = cp << 6u | (s[i + k] & 0x3fu);
        }
        if ((extra == 2u && cp < 0x800u) || (extra == 3u && (cp < 0x10000u || cp > 0x10ffffu)) ||
            (cp >= 0xd800u && cp <= 0xdfffu))
            return false;
        i += extra + 1u;
    }
    return true;
}

typedef struct {
    char *data;
    size_t length, capacity;
} Text;

static bool text_reserve(Text *t, size_t more) {
    if (more > SIZE_MAX - t->length - 1u) return false;
    if (t->length + more + 1u <= t->capacity) return true;
    size_t next = t->capacity ? t->capacity : 64u;
    while (next < t->length + more + 1u) {
        if (next > SIZE_MAX / 2u) return false;
        next *= 2u;
    }
    char *grown = realloc(t->data, next);
    if (!grown) return false;
    t->data = grown;
    t->capacity = next;
    return true;
}

static bool text_put(Text *t, const void *bytes, size_t n) {
    if (!text_reserve(t, n)) return false;
    memcpy(t->data + t->length, bytes, n);
    t->length += n;
    t->data[t->length] = '\0';
    return true;
}

static bool text_printf(Text *t, const char *format, ...) {
    char buffer[96];
    va_list list;
    va_start(list, format);
    int n = vsnprintf(buffer, sizeof buffer, format, list);
    va_end(list);
    return n >= 0 && (size_t)n < sizeof buffer && text_put(t, buffer, (size_t)n);
}

static bool utf8_put(Text *t, uint32_t cp) {
    unsigned char out[4];
    size_t n;
    if (cp < 0x80u) { out[0] = (unsigned char)cp; n = 1u; }
    else if (cp < 0x800u) { out[0] = (unsigned char)(0xc0u | cp >> 6u); out[1] = (unsigned char)(0x80u | (cp & 0x3fu)); n = 2u; }
    else if (cp < 0x10000u) {
        out[0] = (unsigned char)(0xe0u | cp >> 12u); out[1] = (unsigned char)(0x80u | (cp >> 6u & 0x3fu));
        out[2] = (unsigned char)(0x80u | (cp & 0x3fu)); n = 3u;
    } else {
        out[0] = (unsigned char)(0xf0u | cp >> 18u); out[1] = (unsigned char)(0x80u | (cp >> 12u & 0x3fu));
        out[2] = (unsigned char)(0x80u | (cp >> 6u & 0x3fu)); out[3] = (unsigned char)(0x80u | (cp & 0x3fu)); n = 4u;
    }
    return text_put(t, out, n);
}

/* A JSON string, decoded to UTF-8 without NUL bytes. */
static bool json_string(Json *j, char **out) {
    json_space(j);
    if (j->p >= j->end || *j->p != '"') return false;
    j->p++;
    Text t = {0};
    if (!text_reserve(&t, 0u)) return false;
    t.data[0] = '\0';
    while (j->p < j->end && *j->p != '"') {
        unsigned char c = *j->p++;
        if (c < 0x20u) goto bad;
        if (c != '\\') { if (!text_put(&t, &c, 1u)) goto bad; continue; }
        if (j->p >= j->end) goto bad;
        c = *j->p++;
        unsigned char plain;
        switch (c) {
        case '"': case '\\': case '/': plain = c; break;
        case 'b': plain = '\b'; break;
        case 'f': plain = '\f'; break;
        case 'n': plain = '\n'; break;
        case 'r': plain = '\r'; break;
        case 't': plain = '\t'; break;
        case 'u': {
            uint32_t cp;
            if (!json_hex4(j, &cp)) goto bad;
            if (cp >= 0xd800u && cp <= 0xdbffu) {
                uint32_t low;
                if (j->end - j->p < 2 || j->p[0] != '\\' || j->p[1] != 'u') goto bad;
                j->p += 2;
                if (!json_hex4(j, &low) || low < 0xdc00u || low > 0xdfffu) goto bad;
                cp = 0x10000u + ((cp - 0xd800u) << 10u) + (low - 0xdc00u);
            } else if (cp >= 0xdc00u && cp <= 0xdfffu) goto bad;
            if (cp == 0u || !utf8_put(&t, cp)) goto bad;
            continue;
        }
        default: goto bad;
        }
        if (!text_put(&t, &plain, 1u)) goto bad;
    }
    if (j->p >= j->end) goto bad;
    j->p++;
    if (memchr(t.data, '\0', t.length) || !utf8_valid((const unsigned char *)t.data, t.length)) goto bad;
    *out = t.data;
    return true;
bad:
    free(t.data);
    return false;
}

static bool json_natural(Json *j, uint64_t *value) {
    json_space(j);
    if (j->p >= j->end || *j->p < '0' || *j->p > '9') return false;
    if (*j->p == '0' && j->end - j->p > 1 && j->p[1] >= '0' && j->p[1] <= '9') return false;
    uint64_t v = 0u;
    while (j->p < j->end && *j->p >= '0' && *j->p <= '9') {
        unsigned digit = (unsigned)(*j->p++ - '0');
        if (v > (UINT64_MAX - digit) / 10u) return false;
        v = v * 10u + digit;
    }
    if (j->p < j->end && (*j->p == '.' || *j->p == 'e' || *j->p == 'E')) return false;
    *value = v;
    return true;
}

static int entry_by_offset(const void *a, const void *b) {
    const CettaTensorFileEntry *x = a, *y = b;
    if (x->offset != y->offset) return x->offset < y->offset ? -1 : 1;
    if (x->bytes != y->bytes) return x->bytes < y->bytes ? -1 : 1;
    return strcmp(x->name, y->name);
}

static int entry_by_name(const void *a, const void *b) {
    return strcmp(((const CettaTensorFileEntry *)a)->name, ((const CettaTensorFileEntry *)b)->name);
}

typedef struct { char *key, *value; } Pair;

static int pair_by_key(const void *a, const void *b) {
    return strcmp(((const Pair *)a)->key, ((const Pair *)b)->key);
}

static bool parse_metadata(Json *j, CettaTensorFile *file, CettaTensorFileError *e) {
    if (!json_eat(j, '{')) return fail(e, "malformed-header", "__metadata__ is not an object");
    Pair *pairs = NULL;
    size_t count = 0u, capacity = 0u;
    bool ok = true;
    if (!json_eat(j, '}')) {
        for (;;) {
            char *key = NULL, *value = NULL;
            if (!json_string(j, &key) || !json_eat(j, ':') || !json_string(j, &value)) {
                free(key); free(value);
                ok = fail(e, "malformed-header", "__metadata__ maps strings to strings");
                break;
            }
            if (count == capacity) {
                size_t next = capacity ? capacity * 2u : 8u;
                Pair *grown = realloc(pairs, next * sizeof *grown);
                if (!grown) { free(key); free(value); ok = fail(e, "out-of-memory", "metadata"); break; }
                pairs = grown;
                capacity = next;
            }
            pairs[count].key = key;
            pairs[count++].value = value;
            if (json_eat(j, ',')) continue;
            if (json_eat(j, '}')) break;
            ok = fail(e, "malformed-header", "__metadata__");
            break;
        }
    }
    if (ok && count > 1u) {
        qsort(pairs, count, sizeof *pairs, pair_by_key);
        for (size_t i = 1; i < count && ok; ++i)
            if (strcmp(pairs[i - 1u].key, pairs[i].key) == 0)
                ok = fail(e, "malformed-header", "metadata key %s appears twice", pairs[i].key);
    }
    if (ok && count) {
        file->metadata_keys = malloc(count * sizeof *file->metadata_keys);
        file->metadata_values = malloc(count * sizeof *file->metadata_values);
        if (!file->metadata_keys || !file->metadata_values) ok = fail(e, "out-of-memory", "metadata");
    }
    for (size_t i = 0; i < count; ++i) {
        if (ok) {
            file->metadata_keys[i] = pairs[i].key;
            file->metadata_values[i] = pairs[i].value;
        } else {
            free(pairs[i].key);
            free(pairs[i].value);
        }
    }
    if (ok) file->metadata_count = count;
    free(pairs);
    return ok;
}

static bool parse_tensor_info(Json *j, CettaTensorFileEntry *entry, uint64_t data_start, CettaTensorFileError *e) {
    if (!json_eat(j, '{')) return fail(e, "malformed-header", "%s is not an object", entry->name);
    bool have_dtype = false, have_shape = false, have_offsets = false;
    uint64_t begin = 0u, end = 0u;
    size_t capacity = 0u;
    for (;;) {
        char *key = NULL;
        if (!json_string(j, &key) || !json_eat(j, ':')) {
            free(key);
            return fail(e, "malformed-header", "a field of %s", entry->name);
        }
        bool known = true;
        if (strcmp(key, "dtype") == 0 && !have_dtype) {
            char *dtype = NULL;
            Element element;
            if (!json_string(j, &dtype)) { free(key); return fail(e, "malformed-header", "the dtype of %s", entry->name); }
            bool supported = safetensors_element(dtype, &element) && strlen(dtype) < sizeof entry->stored_dtype;
            if (supported) snprintf(entry->stored_dtype, sizeof entry->stored_dtype, "%s", dtype);
            if (!supported) fail(e, "unsupported-dtype", "%s", dtype);
            free(dtype);
            if (!supported) { free(key); return false; }
            entry->dtype = element.dtype;
            entry->width = element.width;
            entry->conversion = element.conversion;
            have_dtype = true;
        } else if (strcmp(key, "shape") == 0 && !have_shape) {
            if (!json_eat(j, '[')) { free(key); return fail(e, "malformed-header", "the shape of %s", entry->name); }
            if (!json_eat(j, ']')) {
                for (;;) {
                    uint64_t dim;
                    if (!json_natural(j, &dim) || dim > SIZE_MAX || entry->rank == RANK_LIMIT) {
                        free(key);
                        return fail(e, "malformed-header", "the shape of %s", entry->name);
                    }
                    if (entry->rank == capacity) {
                        size_t next = capacity ? capacity * 2u : 4u;
                        size_t *grown = realloc(entry->shape, next * sizeof *grown);
                        if (!grown) { free(key); return fail(e, "out-of-memory", "shape"); }
                        entry->shape = grown;
                        capacity = next;
                    }
                    entry->shape[entry->rank++] = (size_t)dim;
                    if (json_eat(j, ',')) continue;
                    if (json_eat(j, ']')) break;
                    free(key);
                    return fail(e, "malformed-header", "the shape of %s", entry->name);
                }
            }
            have_shape = true;
        } else if (strcmp(key, "data_offsets") == 0 && !have_offsets) {
            if (!json_eat(j, '[') || !json_natural(j, &begin) || !json_eat(j, ',') ||
                !json_natural(j, &end) || !json_eat(j, ']') || end < begin) {
                free(key);
                return fail(e, "malformed-header", "the data_offsets of %s", entry->name);
            }
            have_offsets = true;
        } else {
            known = false;
        }
        if (!known) {
            fail(e, "malformed-header", "%s has an unknown or repeated field %s", entry->name, key);
            free(key);
            return false;
        }
        free(key);
        if (json_eat(j, ',')) continue;
        if (json_eat(j, '}')) break;
        return fail(e, "malformed-header", "%s", entry->name);
    }
    if (!have_dtype || !have_shape || !have_offsets)
        return fail(e, "malformed-header", "%s lacks dtype, shape or data_offsets", entry->name);
    if (begin > UINT64_MAX - data_start) return fail(e, "malformed-header", "the data_offsets of %s", entry->name);
    entry->offset = data_start + begin;
    entry->bytes = end - begin;
    return true;
}

static bool parse_safetensors(const unsigned char *p, size_t n, CettaTensorFile *file, CettaTensorFileError *e) {
    uint64_t length = le(p, 8u);
    if (length > SAFETENSORS_HEADER_LIMIT) return fail(e, "header-too-large", "%" PRIu64 " bytes", length);
    if (length > n - 8u) return fail(e, "truncated", "the safetensors header");
    uint64_t data_start = 8u + length;
    Json j = {p + 8, p + data_start};
    size_t capacity = 0u;
    bool have_metadata = false;
    file->format = CETTA_TENSOR_FILE_SAFETENSORS;
    if (!json_eat(&j, '{')) return fail(e, "malformed-header", "the safetensors header is not an object");
    if (!json_eat(&j, '}')) {
        for (;;) {
            char *key = NULL;
            if (!json_string(&j, &key) || !json_eat(&j, ':')) {
                free(key);
                return fail(e, "malformed-header", "a safetensors header key");
            }
            if (strcmp(key, "__metadata__") == 0) {
                free(key);
                if (have_metadata) return fail(e, "malformed-header", "__metadata__ appears twice");
                if (!parse_metadata(&j, file, e)) return false;
                have_metadata = true;
            } else {
                CettaTensorFileEntry *entry = add_entry(file, &capacity);
                if (!entry) { free(key); return fail(e, "out-of-memory", "entry"); }
                entry->name = key;
                if (!parse_tensor_info(&j, entry, data_start, e)) return false;
            }
            if (json_eat(&j, ',')) continue;
            if (json_eat(&j, '}')) break;
            return fail(e, "malformed-header", "the safetensors header object");
        }
    }
    json_space(&j);
    if (j.p != j.end) return fail(e, "malformed-header", "bytes after the safetensors header object");
    for (size_t i = 0; i < file->count; ++i)
        if (!finish_entry(&file->entries[i], n, e)) return false;
    /* As the reference reader requires, the tensors cover the data exactly,
     * without holes or overlaps. */
    if (file->count) qsort(file->entries, file->count, sizeof *file->entries, entry_by_offset);
    uint64_t next = data_start;
    for (size_t i = 0; i < file->count; ++i) {
        if (file->entries[i].offset != next)
            return fail(e, "malformed-header", "%s does not follow the previous tensor's data", file->entries[i].name);
        next = file->entries[i].offset + file->entries[i].bytes;
    }
    if (next != n) return fail(e, "malformed-header", "%" PRIu64 " data bytes are covered of %" PRIu64,
        next - data_start, (uint64_t)n - data_start);
    if (file->count) qsort(file->entries, file->count, sizeof *file->entries, entry_by_name);
    for (size_t i = 1; i < file->count; ++i)
        if (strcmp(file->entries[i - 1u].name, file->entries[i].name) == 0)
            return fail(e, "malformed-header", "tensor %s appears twice", file->entries[i].name);
    return true;
}

/* ----------------------------------------------------------------- CTN1 */

static bool parse_ctn1(const unsigned char *p, size_t n, CettaTensorFile *file, CettaTensorFileError *e) {
    if (n < 9u) return fail(e, "truncated", "CTN1 header");
    CettaDenseTensorV1DType dtype = (CettaDenseTensorV1DType)p[4];
    size_t width = cetta_dense_tensor_v1_itemsize(dtype);
    if (!width) return fail(e, "unsupported-dtype", "CTN1 dtype %u", p[4]);
    uint64_t rank = le(p + 5, 4u);
    if (rank > RANK_LIMIT || rank > (n - 9u) / 8u) return fail(e, "malformed-header", "CTN1 rank %" PRIu64, rank);
    size_t capacity = 0u;
    CettaTensorFileEntry *entry = add_entry(file, &capacity);
    if (!entry) return fail(e, "out-of-memory", "entry");
    entry->name = calloc(1u, 1u);
    entry->shape = rank ? malloc((size_t)rank * sizeof *entry->shape) : NULL;
    if (!entry->name || (rank && !entry->shape)) return fail(e, "out-of-memory", "shape");
    for (size_t i = 0; i < rank; ++i) {
        uint64_t dim = le(p + 9 + 8u * i, 8u);
        if (dim > SIZE_MAX) return fail(e, "malformed-header", "CTN1 dimension");
        entry->shape[i] = (size_t)dim;
    }
    entry->rank = (size_t)rank;
    snprintf(entry->stored_dtype, sizeof entry->stored_dtype, "%s", cetta_dense_tensor_v1_dtype_name(dtype));
    entry->dtype = dtype;
    entry->width = (uint8_t)width;
    entry->offset = 9u + 8u * rank;
    entry->bytes = UINT64_MAX;
    file->format = CETTA_TENSOR_FILE_CTN1;
    if (!finish_entry(entry, n, e)) return false;
    if (entry->offset + entry->bytes != n) return fail(e, "malformed-header", "CTN1 length");
    return true;
}

static bool parse(const unsigned char *p, size_t n, CettaTensorFile *file, CettaTensorFileError *e) {
    file->file_bytes = n;
    if (n >= 6u && memcmp(p, "\x93NUMPY", 6u) == 0) return parse_npy(p, n, file, e);
    if (n >= 4u && memcmp(p, "CTN1", 4u) == 0) return parse_ctn1(p, n, file, e);
    if (n >= 9u && le(p, 8u) <= n - 8u && p[8] == '{') return parse_safetensors(p, n, file, e);
    return fail(e, "unknown-format", "neither NumPy, safetensors nor CTN1");
}

static bool describe(const Mapping *mapping, CettaTensorFile **out, CettaTensorFileError *e) {
    CettaTensorFile *file = calloc(1u, sizeof *file);
    if (!file) return fail(e, "out-of-memory", "file description");
    if (!parse(mapping->base, mapping->length, file, e)) {
        cetta_tensor_file_free(file);
        return false;
    }
    *out = file;
    return true;
}

bool cetta_tensor_file_inspect(const char *path, CettaTensorFile **out, CettaTensorFileError *e) {
    if (!path || !out) return fail(e, "invalid-argument", "path");
    *out = NULL;
    Mapping *mapping;
    if (!map_file(path, &mapping, e)) return false;
    bool ok = describe(mapping, out, e);
    mapping_drop(mapping);
    return ok;
}

/* ---------------------------------------------------- loading entries */

static float half_to_float(uint16_t h) {
    uint32_t sign = (uint32_t)(h & 0x8000u) << 16u, exponent = h >> 10u & 0x1fu, mantissa = h & 0x3ffu, bits;
    if (exponent == 0u) {
        if (mantissa == 0u) bits = sign;
        else {
            int shift = -1;
            do { shift++; mantissa <<= 1u; } while (!(mantissa & 0x400u));
            bits = sign | (uint32_t)(127 - 15 - shift) << 23u | (mantissa & 0x3ffu) << 13u;
        }
    } else if (exponent == 31u) {
        bits = sign | 0x7f800000u | mantissa << 13u;
    } else {
        bits = sign | (exponent + 112u) << 23u | mantissa << 13u;
    }
    float value;
    memcpy(&value, &bits, sizeof value);
    return value;
}

typedef struct {
    const unsigned char *source;
    const CettaTensorFileEntry *entry;
    CettaTensorFileError *error;
} Fill;

/* Writes element `index`, read from the stored element at `from`. */
static bool convert_element(const Fill *fill, const unsigned char *from, unsigned char *to) {
    const CettaTensorFileEntry *entry = fill->entry;
    size_t width = entry->width;
    uint64_t raw = entry->big_endian ? be(from, width) : le(from, width);
    switch (entry->conversion) {
    case CETTA_TENSOR_FILE_F16: { float v = half_to_float((uint16_t)raw); memcpy(to, &v, 4u); return true; }
    case CETTA_TENSOR_FILE_BF16: { uint32_t bits = (uint32_t)raw << 16u; memcpy(to, &bits, 4u); return true; }
    case CETTA_TENSOR_FILE_SIGNED: {
        uint64_t sign = (uint64_t)1u << (8u * width - 1u);
        int64_t v = (int64_t)((raw ^ sign) - sign);
        memcpy(to, &v, 8u);
        return true;
    }
    case CETTA_TENSOR_FILE_UNSIGNED:
        if (raw > (uint64_t)INT64_MAX)
            return fail(fill->error, "value-out-of-range", "%s holds %" PRIu64 ", beyond i64", entry->name, raw);
        { int64_t v = (int64_t)raw; memcpy(to, &v, 8u); }
        return true;
    default:
        for (size_t i = 0; i < width; ++i) to[i] = (unsigned char)(raw >> (8u * i));
        return true;
    }
}

static bool fill_entry(void *context, unsigned char *data, size_t bytes) {
    const Fill *fill = context;
    const CettaTensorFileEntry *entry = fill->entry;
    if (!entry->big_endian && !entry->fortran_order && entry->conversion == CETTA_TENSOR_FILE_SAME &&
        HOST_LITTLE_ENDIAN) {
        if (bytes) memcpy(data, fill->source, bytes);
        return true;
    }
    size_t width = entry->width, out_width = cetta_dense_tensor_v1_itemsize(entry->dtype);
    size_t count = bytes / out_width;
    if (!entry->fortran_order) {
        for (size_t i = 0; i < count; ++i)
            if (!convert_element(fill, fill->source + i * width, data + i * out_width)) return false;
        return true;
    }
    /* C order over the Fortran layout: the first index varies fastest there. */
    size_t index[RANK_LIMIT] = {0}, stride[RANK_LIMIT];
    size_t rank = entry->rank;
    stride[0] = 1u;
    for (size_t k = 1; k < rank; ++k) stride[k] = stride[k - 1u] * entry->shape[k - 1u];
    for (size_t i = 0; i < count; ++i) {
        size_t at = 0u;
        for (size_t k = 0; k < rank; ++k) at += index[k] * stride[k];
        if (!convert_element(fill, fill->source + at * width, data + i * out_width)) return false;
        for (size_t k = rank; k-- > 0u;) {
            if (++index[k] < entry->shape[k]) break;
            index[k] = 0u;
        }
    }
    return true;
}

static bool load_entry(Mapping *mapping, const CettaTensorFileEntry *entry, bool share,
    CettaDenseTensorV1 **out, CettaTensorFileError *e) {
    const unsigned char *source = (const unsigned char *)mapping->base + entry->offset;
    CettaDenseTensorV1Status status;
    if (share) {
        if (entry->copy_reason)
            return fail(e, "unshareable", "%s%s%s", entry->name, *entry->name ? ": " : "", entry->copy_reason);
        atomic_fetch_add_explicit(&mapping->refs, 1u, memory_order_relaxed);
        status = cetta_dense_tensor_v1_new_external(entry->dtype, entry->shape, entry->rank, source,
            (size_t)entry->bytes, mapping_drop, mapping, out);
        if (status != CETTA_DENSE_TENSOR_V1_OK) mapping_drop(mapping);
    } else {
        Fill fill = {source, entry, e};
        if (e) e->reason = NULL;
        status = cetta_dense_tensor_v1_new_filled(entry->dtype, entry->shape, entry->rank, fill_entry, &fill, out);
        if (status == CETTA_DENSE_TENSOR_V1_VALUE && e && e->reason) return false;
    }
    if (status != CETTA_DENSE_TENSOR_V1_OK)
        return fail(e, status == CETTA_DENSE_TENSOR_V1_NOMEM ? "out-of-memory" : "invalid-tensor", "%s: %s",
            entry->name, cetta_dense_tensor_v1_status_name(status));
    return true;
}

bool cetta_tensor_file_read(const char *path, const char *name, bool share,
    CettaDenseTensorV1 **out, CettaTensorFileError *e) {
    if (!path || !out) return fail(e, "invalid-argument", "path");
    *out = NULL;
    Mapping *mapping;
    if (!map_file(path, &mapping, e)) return false;
    CettaTensorFile *file = NULL;
    bool ok = describe(mapping, &file, e);
    const CettaTensorFileEntry *entry = NULL;
    if (ok) {
        if (!name) {
            if (file->count == 1u) entry = &file->entries[0];
            else ok = fail(e, file->count ? "several-tensors" : "no-tensor", "%zu tensors; name one", file->count);
        } else {
            for (size_t i = 0; i < file->count && !entry; ++i)
                if (strcmp(file->entries[i].name, name) == 0) entry = &file->entries[i];
            if (!entry) ok = fail(e, "missing-tensor", "%s", name);
        }
    }
    if (ok) ok = load_entry(mapping, entry, share, out, e);
    cetta_tensor_file_free(file);
    mapping_drop(mapping);
    return ok;
}

enum { READ_COPY, READ_SHARE, READ_SHARE_WHERE_STORED };

static bool read_all(const char *path, int mode, CettaTensorFile **out_file,
    CettaDenseTensorV1 ***out_tensors, CettaTensorFileError *e) {
    if (!path || !out_file || !out_tensors) return fail(e, "invalid-argument", "path");
    *out_file = NULL;
    *out_tensors = NULL;
    Mapping *mapping;
    if (!map_file(path, &mapping, e)) return false;
    CettaTensorFile *file = NULL;
    bool ok = describe(mapping, &file, e);
    CettaDenseTensorV1 **tensors = NULL;
    if (ok && file->count) {
        tensors = calloc(file->count, sizeof *tensors);
        if (!tensors) ok = fail(e, "out-of-memory", "tensor list");
    }
    for (size_t i = 0; ok && i < file->count; ++i) {
        const CettaTensorFileEntry *entry = &file->entries[i];
        bool share = mode == READ_SHARE || (mode == READ_SHARE_WHERE_STORED && !entry->copy_reason);
        ok = load_entry(mapping, entry, share, &tensors[i], e);
    }
    if (!ok) {
        if (tensors) for (size_t i = 0; i < file->count; ++i) cetta_dense_tensor_v1_release(tensors[i]);
        free(tensors);
        cetta_tensor_file_free(file);
        file = NULL;
        tensors = NULL;
    }
    mapping_drop(mapping);
    *out_file = file;
    *out_tensors = tensors;
    return ok;
}

bool cetta_tensor_file_read_all(const char *path, bool share, CettaTensorFile **file,
    CettaDenseTensorV1 ***tensors, CettaTensorFileError *e) {
    return read_all(path, share ? READ_SHARE : READ_COPY, file, tensors, e);
}

bool cetta_tensor_file_open_all(const char *path, CettaTensorFile **file,
    CettaDenseTensorV1 ***tensors, CettaTensorFileError *e) {
    return read_all(path, READ_SHARE_WHERE_STORED, file, tensors, e);
}

/* -------------------------------------------------------------- writing */

static bool write_all(int fd, const void *bytes, size_t n, CettaTensorFileError *e) {
    const unsigned char *p = bytes;
    while (n) {
        size_t chunk = n > ((size_t)1 << 30) ? (size_t)1 << 30 : n;
        ssize_t wrote = write(fd, p, chunk);
        if (wrote < 0) {
            if (errno == EINTR) continue;
            return fail_errno(e, "file-unwritable", errno);
        }
        p += (size_t)wrote;
        n -= (size_t)wrote;
    }
    return true;
}

typedef bool (*WriteBody)(int fd, void *context, CettaTensorFileError *e);

/* A temporary sibling, synced, renamed into place, then the directory synced. */
static bool write_atomically(const char *path, WriteBody body, void *context, CettaTensorFileError *e) {
    static _Atomic unsigned serial;
    size_t n = strlen(path);
    char *temporary = malloc(n + 48u);
    if (!temporary) return fail(e, "out-of-memory", "path");
    snprintf(temporary, n + 48u, "%s.tmp-%ld-%u", path, (long)getpid(),
        atomic_fetch_add_explicit(&serial, 1u, memory_order_relaxed));
    int fd = open(temporary, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0644);
    if (fd < 0) {
        int number = errno;
        free(temporary);
        return fail_errno(e, "file-unwritable", number);
    }
    bool ok = body(fd, context, e);
    if (ok && fsync(fd) != 0) ok = fail_errno(e, "file-unwritable", errno);
    if (close(fd) != 0 && ok) ok = fail_errno(e, "file-unwritable", errno);
    if (ok && rename(temporary, path) != 0) ok = fail_errno(e, "file-unwritable", errno);
    if (!ok) unlink(temporary);
    free(temporary);
    if (ok) {
        char *directory = strdup(path);
        if (directory) {
            char *slash = strrchr(directory, '/');
            const char *name = slash ? (slash == directory ? "/" : (*slash = '\0', directory)) : ".";
            int dir = open(name, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
            if (dir >= 0) { (void)fsync(dir); close(dir); }
            free(directory);
        }
    }
    return ok;
}

typedef struct {
    const char *header;
    size_t header_length;
    const CettaDenseTensorV1 *const *tensors;
    size_t count;
    const size_t *order;
} Body;

static bool write_body(int fd, void *context, CettaTensorFileError *e) {
    const Body *body = context;
    if (!write_all(fd, body->header, body->header_length, e)) return false;
    for (size_t i = 0; i < body->count; ++i) {
        const CettaDenseTensorV1 *t = body->tensors[body->order ? body->order[i] : i];
        if (!write_all(fd, cetta_dense_tensor_v1_data(t), cetta_dense_tensor_v1_nbytes(t), e)) return false;
    }
    return true;
}

static uint64_t written_bytes(const Body *body) {
    uint64_t total = body->header_length;
    for (size_t i = 0; i < body->count; ++i) total += cetta_dense_tensor_v1_nbytes(body->tensors[i]);
    return total;
}

bool cetta_tensor_file_write_npy(const char *path, const CettaDenseTensorV1 *tensor,
    uint64_t *written, CettaTensorFileError *e) {
    if (!path || !tensor) return fail(e, "invalid-argument", "path or tensor");
    if (!HOST_LITTLE_ENDIAN) return fail(e, "unsupported-host", "big-endian hosts do not write tensor files");
    const char *descr = npy_descr(cetta_dense_tensor_v1_dtype(tensor));
    if (!descr) return fail(e, "unsupported-dtype", "%s", cetta_dense_tensor_v1_dtype_name(cetta_dense_tensor_v1_dtype(tensor)));
    size_t rank = cetta_dense_tensor_v1_rank(tensor);
    const size_t *shape = cetta_dense_tensor_v1_shape(tensor);
    Text t = {0};
    bool ok = text_printf(&t, "{'descr': '%s', 'fortran_order': False, 'shape': (", descr);
    for (size_t i = 0; ok && i < rank; ++i) ok = text_printf(&t, i ? ", %zu" : "%zu", shape[i]);
    ok = ok && text_printf(&t, rank == 1u ? ",), }" : "), }");
    if (!ok) { free(t.data); return fail(e, "out-of-memory", "NumPy header"); }
    /* Version 1.0 counts its header in 16 bits; the data starts at a multiple of 64. */
    size_t preamble = 10u, total = preamble + t.length + 1u;
    if (total + 63u > 65535u + preamble) preamble = 12u;
    total = preamble + t.length + 1u;
    size_t padded = (total + 63u) / 64u * 64u;
    size_t header_length = padded - preamble;
    char *header = malloc(padded);
    if (!header) { free(t.data); return fail(e, "out-of-memory", "NumPy header"); }
    memcpy(header, "\x93NUMPY", 6u);
    header[6] = preamble == 10u ? 1 : 2;
    header[7] = 0;
    for (size_t i = 0; i < preamble - 8u; ++i) header[8 + i] = (char)(header_length >> (8u * i));
    memcpy(header + preamble, t.data, t.length);
    memset(header + preamble + t.length, ' ', header_length - t.length - 1u);
    header[padded - 1u] = '\n';
    free(t.data);
    Body body = {header, padded, &tensor, 1u, NULL};
    ok = write_atomically(path, write_body, &body, e);
    if (ok && written) *written = written_bytes(&body);
    free(header);
    return ok;
}

static bool json_quote(Text *t, const char *s, CettaTensorFileError *e) {
    size_t n = strlen(s);
    if (!utf8_valid((const unsigned char *)s, n)) return fail(e, "invalid-name", "not UTF-8");
    if (!text_put(t, "\"", 1u)) return false;
    for (size_t i = 0; i < n; ++i) {
        unsigned char c = (unsigned char)s[i];
        bool ok = c == '"' ? text_put(t, "\\\"", 2u) : c == '\\' ? text_put(t, "\\\\", 2u) :
            c < 0x20u ? text_printf(t, "\\u%04x", c) : text_put(t, &c, 1u);
        if (!ok) return fail(e, "out-of-memory", "header");
    }
    return text_put(t, "\"", 1u) || fail(e, "out-of-memory", "header");
}

/* Widest elements first, then by name. */
static bool written_before(size_t x, size_t y, const char *const *names, const CettaDenseTensorV1 *const *tensors) {
    size_t wx = cetta_dense_tensor_v1_itemsize(cetta_dense_tensor_v1_dtype(tensors[x]));
    size_t wy = cetta_dense_tensor_v1_itemsize(cetta_dense_tensor_v1_dtype(tensors[y]));
    return wx != wy ? wx > wy : strcmp(names[x], names[y]) < 0;
}

bool cetta_tensor_file_write_safetensors(const char *path, size_t count, const char *const *names,
    const CettaDenseTensorV1 *const *tensors, size_t metadata_count, const char *const *keys,
    const char *const *values, uint64_t *written, CettaTensorFileError *e) {
    return cetta_tensor_file_write_safetensors_as(path, count, names, tensors, NULL, metadata_count,
        keys, values, written, e);
}

/* A u8 tensor of 0 and 1 may be written as BOOL, as NumPy and PyTorch store
 * booleans. */
static bool boolean_values(const CettaDenseTensorV1 *tensor) {
    if (cetta_dense_tensor_v1_dtype(tensor) != CETTA_DENSE_TENSOR_V1_U8) return false;
    const unsigned char *data = cetta_dense_tensor_v1_data(tensor);
    for (size_t i = 0; i < cetta_dense_tensor_v1_count(tensor); ++i)
        if (data[i] > 1u) return false;
    return true;
}

bool cetta_tensor_file_write_safetensors_as(const char *path, size_t count, const char *const *names,
    const CettaDenseTensorV1 *const *tensors, const bool *booleans, size_t metadata_count,
    const char *const *keys, const char *const *values, uint64_t *written, CettaTensorFileError *e) {
    if (!path || (count && (!names || !tensors)) || (metadata_count && (!keys || !values)))
        return fail(e, "invalid-argument", "names, tensors or metadata");
    if (!HOST_LITTLE_ENDIAN) return fail(e, "unsupported-host", "big-endian hosts do not write tensor files");
    for (size_t i = 0; i < count; ++i) {
        if (!names[i] || !tensors[i]) return fail(e, "invalid-argument", "entry %zu", i);
        if (strcmp(names[i], "__metadata__") == 0) return fail(e, "invalid-name", "__metadata__ is reserved");
        if (!safetensors_name(cetta_dense_tensor_v1_dtype(tensors[i])))
            return fail(e, "unsupported-dtype", "%s", names[i]);
        if (booleans && booleans[i] && !boolean_values(tensors[i]))
            return fail(e, "invalid-value", "%s: BOOL holds a u8 tensor of 0 and 1", names[i]);
        for (size_t k = 0; k < i; ++k)
            if (strcmp(names[k], names[i]) == 0) return fail(e, "invalid-name", "%s appears twice", names[i]);
    }
    for (size_t i = 0; i < metadata_count; ++i) {
        if (!keys[i] || !values[i]) return fail(e, "invalid-argument", "metadata %zu", i);
        for (size_t k = 0; k < i; ++k)
            if (strcmp(keys[k], keys[i]) == 0) return fail(e, "invalid-name", "metadata key %s appears twice", keys[i]);
    }
    size_t *order = count ? malloc(count * sizeof *order) : NULL;
    if (count && !order) return fail(e, "out-of-memory", "order");
    for (size_t i = 0; i < count; ++i) order[i] = i;
    /* Widest elements first: every tensor then starts aligned to its width. */
    for (size_t i = 1; i < count; ++i) {
        size_t moving = order[i], k = i;
        for (; k > 0u && written_before(moving, order[k - 1u], names, tensors); --k) order[k] = order[k - 1u];
        order[k] = moving;
    }
    Text t = {0};
    bool ok = text_put(&t, "{", 1u);
    if (ok && metadata_count) {
        ok = text_put(&t, "\"__metadata__\":{", 16u);
        for (size_t i = 0; ok && i < metadata_count; ++i)
            ok = (!i || text_put(&t, ",", 1u)) && json_quote(&t, keys[i], e) && text_put(&t, ":", 1u) &&
                json_quote(&t, values[i], e);
        ok = ok && text_put(&t, "}", 1u);
    }
    uint64_t offset = 0u;
    for (size_t k = 0; ok && k < count; ++k) {
        const CettaDenseTensorV1 *tensor = tensors[order[k]];
        size_t rank = cetta_dense_tensor_v1_rank(tensor);
        const size_t *shape = cetta_dense_tensor_v1_shape(tensor);
        uint64_t bytes = cetta_dense_tensor_v1_nbytes(tensor);
        const char *stored = booleans && booleans[order[k]] ? "BOOL" : safetensors_name(cetta_dense_tensor_v1_dtype(tensor));
        ok = (metadata_count || k ? text_put(&t, ",", 1u) : true) && json_quote(&t, names[order[k]], e) &&
            text_printf(&t, ":{\"dtype\":\"%s\",\"shape\":[", stored);
        for (size_t i = 0; ok && i < rank; ++i) ok = text_printf(&t, i ? ",%zu" : "%zu", shape[i]);
        ok = ok && text_printf(&t, "],\"data_offsets\":[%" PRIu64 ",%" PRIu64 "]}", offset, offset + bytes);
        offset += bytes;
    }
    ok = ok && text_put(&t, "}", 1u);
    /* Pad with spaces so the data starts at a multiple of eight. */
    while (ok && (8u + t.length) % 8u) ok = text_put(&t, " ", 1u);
    if (!ok) {
        free(t.data);
        free(order);
        return e && e->reason ? false : fail(e, "out-of-memory", "header");
    }
    size_t header_length = 8u + t.length;
    char *header = malloc(header_length);
    if (!header) { free(t.data); free(order); return fail(e, "out-of-memory", "header"); }
    for (size_t i = 0; i < 8u; ++i) header[i] = (char)((uint64_t)t.length >> (8u * i));
    memcpy(header + 8, t.data, t.length);
    free(t.data);
    Body body = {header, header_length, tensors, count, order};
    ok = write_atomically(path, write_body, &body, e);
    if (ok && written) *written = written_bytes(&body);
    free(header);
    free(order);
    return ok;
}

/* ------------------------------------------------------- string columns */

bool cetta_tensor_string_column(size_t count, const char *const *strings, const size_t *lengths,
    CettaDenseTensorV1 **offsets_out, CettaDenseTensorV1 **bytes_out, CettaTensorFileError *e) {
    *offsets_out = *bytes_out = NULL;
    if (count > (SIZE_MAX / sizeof(int64_t)) - 1u) return fail(e, "out-of-memory", "offsets");
    int64_t *offsets = malloc((count + 1u) * sizeof *offsets);
    if (!offsets) return fail(e, "out-of-memory", "offsets");
    uint64_t total = 0u;
    offsets[0] = 0;
    for (size_t i = 0; i < count; ++i) {
        if (!utf8_valid((const unsigned char *)strings[i], lengths[i])) {
            free(offsets);
            return fail(e, "invalid-string", "string %zu is not UTF-8", i);
        }
        if (lengths[i] > (uint64_t)INT64_MAX - total) { free(offsets); return fail(e, "out-of-memory", "column"); }
        total += lengths[i];
        offsets[i + 1u] = (int64_t)total;
    }
    unsigned char *bytes = total ? malloc((size_t)total) : NULL;
    if (total && !bytes) { free(offsets); return fail(e, "out-of-memory", "column"); }
    for (size_t i = 0; i < count; ++i)
        if (lengths[i]) memcpy(bytes + offsets[i], strings[i], lengths[i]);
    size_t shape_offsets = count + 1u, shape_bytes = (size_t)total;
    CettaDenseTensorV1Status status = cetta_dense_tensor_v1_new(CETTA_DENSE_TENSOR_V1_I64, &shape_offsets, 1u,
        offsets, shape_offsets * sizeof *offsets, offsets_out);
    if (status == CETTA_DENSE_TENSOR_V1_OK)
        status = cetta_dense_tensor_v1_new(CETTA_DENSE_TENSOR_V1_U8, &shape_bytes, 1u, bytes, shape_bytes, bytes_out);
    free(offsets);
    free(bytes);
    if (status != CETTA_DENSE_TENSOR_V1_OK) {
        cetta_dense_tensor_v1_release(*offsets_out);
        *offsets_out = NULL;
        return fail(e, "out-of-memory", "column");
    }
    return true;
}

static bool column_shape(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes, CettaTensorFileError *e) {
    if (!offsets || !bytes || cetta_dense_tensor_v1_dtype(offsets) != CETTA_DENSE_TENSOR_V1_I64 ||
        cetta_dense_tensor_v1_rank(offsets) != 1u || cetta_dense_tensor_v1_count(offsets) == 0u ||
        cetta_dense_tensor_v1_dtype(bytes) != CETTA_DENSE_TENSOR_V1_U8 || cetta_dense_tensor_v1_rank(bytes) != 1u)
        return fail(e, "invalid-column", "offsets must be i64 [n + 1] and bytes u8 [m]");
    return true;
}

/* String index's bytes, after checking the two offsets that bound it. */
static bool string_span(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes, size_t index,
    const unsigned char **text, size_t *length, CettaTensorFileError *e) {
    size_t n = cetta_dense_tensor_v1_count(offsets) - 1u;
    if (index >= n) return fail(e, "index-out-of-range", "%zu of %zu strings", index, n);
    int64_t from, to;
    const unsigned char *o = cetta_dense_tensor_v1_data(offsets);
    memcpy(&from, o + index * 8u, 8u);
    memcpy(&to, o + (index + 1u) * 8u, 8u);
    if (from < 0 || to < from || (uint64_t)to > cetta_dense_tensor_v1_count(bytes))
        return fail(e, "invalid-column", "offsets %zu and %zu", index, index + 1u);
    *text = (const unsigned char *)cetta_dense_tensor_v1_data(bytes) + from;
    *length = (size_t)(to - from);
    return true;
}

bool cetta_tensor_string_at(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes, size_t index,
    const char **text, size_t *length, CettaTensorFileError *e) {
    if (!column_shape(offsets, bytes, e)) return false;
    const unsigned char *span;
    if (!string_span(offsets, bytes, index, &span, length, e)) return false;
    *text = (const char *)span;
    if (!utf8_valid(span, *length)) return fail(e, "invalid-string", "string %zu is not UTF-8", index);
    return true;
}

/* The whole column, as tensor:string-at reads each string: offsets that do
 * not decrease and stay within the bytes, and UTF-8 strings. */
bool cetta_tensor_string_count(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes,
    size_t *count, CettaTensorFileError *e) {
    if (!column_shape(offsets, bytes, e)) return false;
    size_t n = cetta_dense_tensor_v1_count(offsets) - 1u;
    for (size_t i = 0; i < n; ++i) {
        const char *text;
        size_t length;
        if (!cetta_tensor_string_at(offsets, bytes, i, &text, &length, e)) return false;
    }
    *count = n;
    return true;
}

/* FNV-1a and a 64-bit finalizer. A search compares the strings themselves,
 * so the hash only decides where it starts. */
static uint64_t string_hash(const unsigned char *p, size_t n) {
    uint64_t h = UINT64_C(14695981039346656037);
    for (size_t i = 0; i < n; ++i) {
        h ^= p[i];
        h *= UINT64_C(1099511628211);
    }
    h ^= h >> 33;
    h *= UINT64_C(0xff51afd7ed558ccd);
    h ^= h >> 33;
    h *= UINT64_C(0xc4ceb9fe1a85ec53);
    return h ^ (h >> 33);
}

bool cetta_tensor_string_index(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes,
    CettaDenseTensorV1 **out, CettaTensorFileError *e) {
    *out = NULL;
    if (!column_shape(offsets, bytes, e)) return false;
    size_t n = cetta_dense_tensor_v1_count(offsets) - 1u, capacity = 8u;
    while (capacity / 2u < n) {
        if (capacity > SIZE_MAX / 2u / sizeof(int64_t)) return fail(e, "out-of-memory", "index of %zu strings", n);
        capacity *= 2u;
    }
    int64_t *slots = malloc(capacity * sizeof *slots);
    if (!slots) return fail(e, "out-of-memory", "index of %zu strings", n);
    memset(slots, 0xff, capacity * sizeof *slots); /* -1 marks an empty slot */
    size_t mask = capacity - 1u;
    for (size_t i = 0; i < n; ++i) {
        const char *text;
        size_t length;
        if (!cetta_tensor_string_at(offsets, bytes, i, &text, &length, e)) { free(slots); return false; }
        size_t at = (size_t)string_hash((const unsigned char *)text, length) & mask;
        for (; slots[at] >= 0; at = (at + 1u) & mask) {
            const unsigned char *other;
            size_t size;
            size_t row = (size_t)slots[at];
            if (string_span(offsets, bytes, row, &other, &size, e) && size == length && !memcmp(other, text, length)) {
                free(slots);
                return fail(e, "duplicate-string", "string %zu equals string %zu", i, row);
            }
        }
        slots[at] = (int64_t)i;
    }
    size_t shape = capacity;
    CettaDenseTensorV1Status status = cetta_dense_tensor_v1_new(CETTA_DENSE_TENSOR_V1_I64, &shape, 1u,
        slots, capacity * sizeof *slots, out);
    free(slots);
    if (status != CETTA_DENSE_TENSOR_V1_OK) return fail(e, "out-of-memory", "index of %zu strings", n);
    return true;
}

bool cetta_tensor_string_find(const CettaDenseTensorV1 *index, const CettaDenseTensorV1 *offsets,
    const CettaDenseTensorV1 *bytes, const char *value, size_t length, int64_t *row, CettaTensorFileError *e) {
    if (!column_shape(offsets, bytes, e)) return false;
    size_t n = cetta_dense_tensor_v1_count(offsets) - 1u;
    size_t capacity = index ? cetta_dense_tensor_v1_count(index) : 0u;
    if (!index || cetta_dense_tensor_v1_dtype(index) != CETTA_DENSE_TENSOR_V1_I64 ||
        cetta_dense_tensor_v1_rank(index) != 1u || capacity == 0u || (capacity & (capacity - 1u)) ||
        capacity / 2u < n)
        return fail(e, "invalid-index", "an index of %zu strings is i64 [2^k], k > log2(2n), as tensor:string-index builds", n);
    const unsigned char *slots = cetta_dense_tensor_v1_data(index);
    size_t mask = capacity - 1u, at = (size_t)string_hash((const unsigned char *)value, length) & mask;
    for (size_t probe = 0; probe < capacity; ++probe, at = (at + 1u) & mask) {
        int64_t slot;
        memcpy(&slot, slots + at * 8u, 8u);
        if (slot == -1) break;
        if (slot < 0 || (uint64_t)slot >= n)
            return fail(e, "invalid-index", "slot %zu names row %" PRId64 " of %zu", at, slot, n);
        const unsigned char *text;
        size_t size;
        if (!string_span(offsets, bytes, (size_t)slot, &text, &size, e)) return false;
        if (size == length && !memcmp(text, value, length)) {
            *row = slot;
            return true;
        }
    }
    *row = -1;
    return true;
}

bool cetta_tensor_string_mask(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes,
    const char *value, size_t length, CettaDenseTensorV1 **out, CettaTensorFileError *e) {
    *out = NULL;
    if (!column_shape(offsets, bytes, e)) return false;
    size_t n = cetta_dense_tensor_v1_count(offsets) - 1u;
    unsigned char *mask = malloc(n ? n : 1u);
    if (!mask) return fail(e, "out-of-memory", "mask of %zu strings", n);
    for (size_t i = 0; i < n; ++i) {
        const unsigned char *text;
        size_t size;
        if (!string_span(offsets, bytes, i, &text, &size, e)) { free(mask); return false; }
        mask[i] = size == length && !memcmp(text, value, length);
    }
    CettaDenseTensorV1Status status = cetta_dense_tensor_v1_new(CETTA_DENSE_TENSOR_V1_U8, &n, 1u, mask, n, out);
    free(mask);
    if (status != CETTA_DENSE_TENSOR_V1_OK) return fail(e, "out-of-memory", "mask of %zu strings", n);
    return true;
}

/* ------------------------------------------------------------- natives */

static Atom *failure_atom(Arena *arena, const CettaTensorFileError *e) {
    Atom *why = atom_expr2(arena, atom_symbol(arena, e->reason ? e->reason : "failed"),
        atom_string_n(arena, e->detail, strlen(e->detail)));
    return atom_expr2(arena, atom_symbol(arena, "TensorFailure"), why);
}

static Atom *refuse(Arena *arena, const char *reason, const char *detail) {
    CettaTensorFileError e = {reason, {0}};
    snprintf(e.detail, sizeof e.detail, "%s", detail);
    return failure_atom(arena, &e);
}

static CettaDenseTensorV1 *tensor_of(const Atom *atom) {
    return atom && atom->kind == ATOM_GROUNDED && atom->ground.gkind == GV_TENSOR ? atom->ground.ptr : NULL;
}

static bool string_of(const Atom *atom, const char **bytes, size_t *length) {
    if (!atom || atom->kind != ATOM_GROUNDED || atom->ground.gkind != GV_STRING) return false;
    *bytes = atom->ground.sval;
    *length = atom->ground.slen;
    return true;
}

/* A NUL-terminated copy of a string atom without interior NUL bytes. */
static char *c_string(const Atom *atom) {
    const char *bytes;
    size_t length;
    if (!string_of(atom, &bytes, &length) || memchr(bytes, '\0', length)) return NULL;
    char *copy = malloc(length + 1u);
    if (copy) { memcpy(copy, bytes, length); copy[length] = '\0'; }
    return copy;
}

static Atom *tensor_atom(Arena *arena, CettaDenseTensorV1 *tensor) {
    Atom *atom = atom_tensor(arena, tensor);
    cetta_dense_tensor_v1_release(tensor);
    return atom ? atom : refuse(arena, "out-of-memory", "tensor atom");
}

static Atom *shape_atom(Arena *arena, const size_t *shape, size_t rank) {
    Atom **items = arena_alloc(arena, (rank ? rank : 1u) * sizeof *items);
    for (size_t i = 0; i < rank; ++i) items[i] = atom_int(arena, (int64_t)shape[i]);
    return atom_expr(arena, items, (CettaExprLen)rank);
}

static Atom *metadata_atom(Arena *arena, const CettaTensorFile *file) {
    Atom **items = arena_alloc(arena, (file->metadata_count ? file->metadata_count : 1u) * sizeof *items);
    for (size_t i = 0; i < file->metadata_count; ++i)
        items[i] = atom_expr2(arena,
            atom_string_n(arena, file->metadata_keys[i], strlen(file->metadata_keys[i])),
            atom_string_n(arena, file->metadata_values[i], strlen(file->metadata_values[i])));
    return atom_expr(arena, items, (CettaExprLen)file->metadata_count);
}

static bool named(const char *operation, size_t length, const char *name) {
    return strlen(name) == length && memcmp(operation, name, length) == 0;
}

Atom *cetta_tensor_files_v1_dispatch(Arena *arena, const char *operation, size_t length,
    Atom **args, uint32_t nargs) {
    CettaTensorFileError e = {NULL, {0}};
    if (named(operation, length, "string_at")) {
        size_t index;
        if (nargs != 3u || args[2]->kind != ATOM_GROUNDED || args[2]->ground.gkind != GV_INT || args[2]->ground.ival < 0)
            return refuse(arena, "invalid-argument", "(tensor:string-at offsets bytes index)");
        index = (size_t)args[2]->ground.ival;
        const char *text;
        size_t n;
        if (!cetta_tensor_string_at(tensor_of(args[0]), tensor_of(args[1]), index, &text, &n, &e))
            return failure_atom(arena, &e);
        return atom_string_n(arena, text, n);
    }
    if (named(operation, length, "string_count")) {
        if (nargs != 2u) return refuse(arena, "invalid-argument", "(tensor:string-count offsets bytes)");
        size_t n;
        if (!cetta_tensor_string_count(tensor_of(args[0]), tensor_of(args[1]), &n, &e)) return failure_atom(arena, &e);
        return atom_int(arena, (int64_t)n);
    }
    if (named(operation, length, "string_index")) {
        if (nargs != 2u) return refuse(arena, "invalid-argument", "(tensor:string-index offsets bytes)");
        CettaDenseTensorV1 *index;
        if (!cetta_tensor_string_index(tensor_of(args[0]), tensor_of(args[1]), &index, &e)) return failure_atom(arena, &e);
        return tensor_atom(arena, index);
    }
    if (named(operation, length, "string_find") || named(operation, length, "string_mask")) {
        bool find = named(operation, length, "string_find");
        const char *value;
        size_t n;
        if (nargs != (find ? 4u : 3u) || !string_of(args[nargs - 1u], &value, &n))
            return refuse(arena, "invalid-argument",
                find ? "(tensor:string-find index offsets bytes string)" : "(tensor:string-mask offsets bytes string)");
        if (find) {
            int64_t row;
            if (!cetta_tensor_string_find(tensor_of(args[0]), tensor_of(args[1]), tensor_of(args[2]), value, n, &row, &e))
                return failure_atom(arena, &e);
            return atom_int(arena, row);
        }
        CettaDenseTensorV1 *mask;
        if (!cetta_tensor_string_mask(tensor_of(args[0]), tensor_of(args[1]), value, n, &mask, &e))
            return failure_atom(arena, &e);
        return tensor_atom(arena, mask);
    }
    if (named(operation, length, "strings")) {
        if (nargs != 2u) return refuse(arena, "invalid-argument", "(tensor:strings offsets bytes)");
        const CettaDenseTensorV1 *offsets = tensor_of(args[0]), *bytes = tensor_of(args[1]);
        if (!column_shape(offsets, bytes, &e)) return failure_atom(arena, &e);
        size_t n = cetta_dense_tensor_v1_count(offsets) - 1u;
        Atom **items = arena_alloc(arena, (n ? n : 1u) * sizeof *items);
        for (size_t i = 0; i < n; ++i) {
            const char *text;
            size_t size;
            if (!cetta_tensor_string_at(offsets, bytes, i, &text, &size, &e)) return failure_atom(arena, &e);
            items[i] = atom_string_n(arena, text, size);
        }
        return atom_expr(arena, items, (CettaExprLen)n);
    }
    if (named(operation, length, "string_column")) {
        if (nargs != 1u || args[0]->kind != ATOM_EXPR)
            return refuse(arena, "invalid-argument", "(tensor:string-column (string ...))");
        size_t n = args[0]->expr.len;
        const char **strings = n ? malloc(n * sizeof *strings) : NULL;
        size_t *lengths = n ? malloc(n * sizeof *lengths) : NULL;
        if (n && (!strings || !lengths)) { free(strings); free(lengths); return refuse(arena, "out-of-memory", "column"); }
        for (size_t i = 0; i < n; ++i) {
            if (!string_of(args[0]->expr.elems[i], &strings[i], &lengths[i])) {
                free(strings); free(lengths);
                return refuse(arena, "invalid-argument", "every element must be a string");
            }
        }
        CettaDenseTensorV1 *offsets, *bytes;
        bool ok = cetta_tensor_string_column(n, strings, lengths, &offsets, &bytes, &e);
        free(strings);
        free(lengths);
        if (!ok) return failure_atom(arena, &e);
        return atom_expr2(arena, tensor_atom(arena, offsets), tensor_atom(arena, bytes));
    }
    /* Everything else names a file first. */
    if (nargs < 1u) return refuse(arena, "invalid-argument", "a path");
    char *path = c_string(args[0]);
    if (!path) return refuse(arena, "invalid-argument", "the path must be a string without NUL bytes");
    Atom *answer = NULL;
    if (named(operation, length, "file_info")) {
        CettaTensorFile *file;
        if (nargs != 1u) answer = refuse(arena, "invalid-argument", "(tensor:file-info path)");
        else if (!cetta_tensor_file_inspect(path, &file, &e)) answer = failure_atom(arena, &e);
        else {
            Atom **entries = arena_alloc(arena, (file->count ? file->count : 1u) * sizeof *entries);
            for (size_t i = 0; i < file->count; ++i) {
                const CettaTensorFileEntry *entry = &file->entries[i];
                Atom *sharing = entry->copy_reason
                    ? atom_expr2(arena, atom_symbol(arena, "copied"),
                        atom_string_n(arena, entry->copy_reason, strlen(entry->copy_reason)))
                    : atom_symbol(arena, "shared");
                Atom *fields[] = {atom_symbol(arena, "TensorFileEntry"),
                    atom_string_n(arena, entry->name, strlen(entry->name)),
                    atom_symbol(arena, cetta_dense_tensor_v1_dtype_name(entry->dtype)),
                    shape_atom(arena, entry->shape, entry->rank),
                    atom_string_n(arena, entry->stored_dtype, strlen(entry->stored_dtype)), sharing};
                entries[i] = atom_expr(arena, fields, 6u);
            }
            Atom *fields[] = {atom_symbol(arena, "TensorFileInfo"),
                atom_symbol(arena, cetta_tensor_file_format_name(file->format)),
                atom_int(arena, (int64_t)file->file_bytes), atom_expr(arena, entries, (CettaExprLen)file->count),
                metadata_atom(arena, file)};
            answer = atom_expr(arena, fields, 5u);
            cetta_tensor_file_free(file);
        }
    } else if (named(operation, length, "load") || named(operation, length, "map")) {
        bool share = named(operation, length, "map");
        char *name = nargs == 2u ? c_string(args[1]) : NULL;
        CettaDenseTensorV1 *tensor;
        if (nargs != 1u && nargs != 2u) answer = refuse(arena, "invalid-argument", "(tensor:load path [name])");
        else if (nargs == 2u && !name) answer = refuse(arena, "invalid-argument", "the name must be a string");
        else if (!cetta_tensor_file_read(path, name, share, &tensor, &e)) answer = failure_atom(arena, &e);
        else answer = tensor_atom(arena, tensor);
        free(name);
    } else if (named(operation, length, "load_all") || named(operation, length, "map_all") ||
               named(operation, length, "open_all")) {
        CettaTensorFile *file;
        CettaDenseTensorV1 **tensors;
        bool opened = nargs == 1u && (named(operation, length, "open_all")
            ? cetta_tensor_file_open_all(path, &file, &tensors, &e)
            : cetta_tensor_file_read_all(path, named(operation, length, "map_all"), &file, &tensors, &e));
        if (nargs != 1u) answer = refuse(arena, "invalid-argument", "(tensor:load-all path)");
        else if (!opened)
            answer = failure_atom(arena, &e);
        else {
            Atom **entries = arena_alloc(arena, (file->count ? file->count : 1u) * sizeof *entries);
            for (size_t i = 0; i < file->count; ++i)
                entries[i] = atom_expr2(arena,
                    atom_string_n(arena, file->entries[i].name, strlen(file->entries[i].name)),
                    tensor_atom(arena, tensors[i]));
            Atom *fields[] = {atom_symbol(arena, "TensorFile"),
                atom_symbol(arena, cetta_tensor_file_format_name(file->format)),
                atom_expr(arena, entries, (CettaExprLen)file->count), metadata_atom(arena, file)};
            answer = atom_expr(arena, fields, 4u);
            free(tensors);
            cetta_tensor_file_free(file);
        }
    } else if (named(operation, length, "save_npy")) {
        uint64_t written;
        if (nargs != 2u || !tensor_of(args[1])) answer = refuse(arena, "invalid-argument", "(tensor:save-npy path tensor)");
        else if (!cetta_tensor_file_write_npy(path, tensor_of(args[1]), &written, &e)) answer = failure_atom(arena, &e);
        else answer = atom_expr3(arena, atom_symbol(arena, "TensorSaved"), args[0], atom_int(arena, (int64_t)written));
    } else if (named(operation, length, "save_safetensors")) {
        if ((nargs != 2u && nargs != 3u) || args[1]->kind != ATOM_EXPR || (nargs == 3u && args[2]->kind != ATOM_EXPR)) {
            answer = refuse(arena, "invalid-argument", "(tensor:save-safetensors path ((name tensor) ...) [((key value) ...)])");
        } else {
            size_t n = args[1]->expr.len, m = nargs == 3u ? args[2]->expr.len : 0u;
            char **names = calloc(n ? n : 1u, sizeof *names), **keys = calloc(m ? m : 1u, sizeof *keys);
            char **values = calloc(m ? m : 1u, sizeof *values);
            const CettaDenseTensorV1 **tensors = calloc(n ? n : 1u, sizeof *tensors);
            bool *booleans = calloc(n ? n : 1u, sizeof *booleans);
            bool ok = names && keys && values && tensors && booleans;
            if (!ok) answer = refuse(arena, "out-of-memory", "entries");
            for (size_t i = 0; ok && i < n; ++i) {
                Atom *pair = args[1]->expr.elems[i];
                ok = pair->kind == ATOM_EXPR && (pair->expr.len == 2u ||
                        (pair->expr.len == 3u && atom_is_symbol(pair->expr.elems[2], "bool"))) &&
                    (names[i] = c_string(pair->expr.elems[0])) && (tensors[i] = tensor_of(pair->expr.elems[1]));
                if (ok) booleans[i] = pair->expr.len == 3u;
                if (!ok) answer = refuse(arena, "invalid-argument", "each entry is (name tensor) or (name tensor bool)");
            }
            for (size_t i = 0; ok && i < m; ++i) {
                Atom *pair = args[2]->expr.elems[i];
                ok = pair->kind == ATOM_EXPR && pair->expr.len == 2u && (keys[i] = c_string(pair->expr.elems[0])) &&
                    (values[i] = c_string(pair->expr.elems[1]));
                if (!ok) answer = refuse(arena, "invalid-argument", "each metadata entry is (key value), both strings");
            }
            uint64_t written;
            if (ok && !cetta_tensor_file_write_safetensors_as(path, n, (const char *const *)names, tensors, booleans, m,
                    (const char *const *)keys, (const char *const *)values, &written, &e))
                answer = failure_atom(arena, &e);
            else if (ok)
                answer = atom_expr3(arena, atom_symbol(arena, "TensorSaved"), args[0], atom_int(arena, (int64_t)written));
            for (size_t i = 0; names && i < n; ++i) free(names[i]);
            for (size_t i = 0; keys && values && i < m; ++i) { free(keys[i]); free(values[i]); }
            free(names); free(keys); free(values); free((void *)tensors); free(booleans);
        }
    } else {
        answer = refuse(arena, "unknown-operation", "tensor file operation");
    }
    free(path);
    return answer;
}
