#ifndef CETTA_TENSOR_FILES_V1_H
#define CETTA_TENSOR_FILES_V1_H

#include "tensor_dense_v1.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Dense tensors in the standard interchange files, recognized by their magic:
 * NumPy .npy (format versions 1.0 to 3.0), safetensors, and CeTTa's CTN1.
 *
 * Reading copies or shares. A copy converts the element types CeTTa does not
 * store: f16 and bf16 to f32; i8, i16, i32, u16, u32 and u64 to i64 (u64 only
 * while every value fits); bool to u8; big-endian to little-endian; Fortran to
 * C order. Sharing maps the file read-only and never converts: it fails, and
 * says why, when the stored bytes are not already CeTTa's or are not aligned.
 * A shared tensor keeps its mapping until its last view is released; the file
 * must not be truncated meanwhile. Its bytes belong to the file's page cache,
 * so it is charged as its descriptor only.
 *
 * Writing produces NumPy 1.0 (2.0 for a header beyond 64 KiB) and safetensors
 * files whose data a reader can share: NumPy data starts at a multiple of 64,
 * and safetensors orders tensors by element width so every tensor is aligned.
 * A file is written to a temporary sibling, synced and renamed into place. */

typedef enum {
    CETTA_TENSOR_FILE_NPY = 1,
    CETTA_TENSOR_FILE_SAFETENSORS = 2,
    CETTA_TENSOR_FILE_CTN1 = 3,
} CettaTensorFileFormat;

typedef enum {
    CETTA_TENSOR_FILE_SAME = 0,      /* stored as CeTTa stores it */
    CETTA_TENSOR_FILE_F16,           /* binary16 widened to f32 */
    CETTA_TENSOR_FILE_BF16,          /* bfloat16 widened to f32 */
    CETTA_TENSOR_FILE_SIGNED,        /* a narrower signed integer, to i64 */
    CETTA_TENSOR_FILE_UNSIGNED,      /* an unsigned integer, to i64 */
} CettaTensorFileConversion;

typedef struct {
    char *name;                      /* "" in a one-tensor format */
    char stored_dtype[16];           /* as the file spells it: "<f2", "BF16" */
    CettaDenseTensorV1DType dtype;   /* what it loads as */
    size_t rank;
    size_t *shape;
    uint64_t offset;                 /* stored data, from the file's start */
    uint64_t bytes;
    uint8_t width;                   /* stored element width */
    uint8_t conversion;              /* CettaTensorFileConversion */
    bool big_endian;
    bool fortran_order;
    const char *copy_reason;         /* NULL when the data can be shared */
} CettaTensorFileEntry;

typedef struct {
    CettaTensorFileFormat format;
    uint64_t file_bytes;
    size_t count;
    CettaTensorFileEntry *entries;   /* sorted by name */
    size_t metadata_count;
    char **metadata_keys;            /* sorted */
    char **metadata_values;
} CettaTensorFile;

typedef struct {
    const char *reason;              /* a word such as "malformed-header" */
    char detail[200];
} CettaTensorFileError;

const char *cetta_tensor_file_format_name(CettaTensorFileFormat format);

bool cetta_tensor_file_inspect(const char *path, CettaTensorFile **out,
    CettaTensorFileError *error);
void cetta_tensor_file_free(CettaTensorFile *file);

/* name NULL selects the file's only tensor. One caller hold is returned. */
bool cetta_tensor_file_read(const char *path, const char *name, bool share,
    CettaDenseTensorV1 **out, CettaTensorFileError *error);

/* tensors[i] belongs to (*file)->entries[i]. The caller releases every tensor
 * and frees the array and the file description. */
bool cetta_tensor_file_read_all(const char *path, bool share, CettaTensorFile **file,
    CettaDenseTensorV1 ***tensors, CettaTensorFileError *error);
/* As read_all, sharing each tensor stored as CeTTa holds it and copying the
 * others, so one converted tensor does not copy the whole file. */
bool cetta_tensor_file_open_all(const char *path, CettaTensorFile **file,
    CettaDenseTensorV1 ***tensors, CettaTensorFileError *error);

bool cetta_tensor_file_write_npy(const char *path, const CettaDenseTensorV1 *tensor,
    uint64_t *written, CettaTensorFileError *error);
bool cetta_tensor_file_write_safetensors(const char *path, size_t count,
    const char *const *names, const CettaDenseTensorV1 *const *tensors,
    size_t metadata_count, const char *const *keys, const char *const *values,
    uint64_t *written, CettaTensorFileError *error);
/* booleans[i] writes the u8 tensors[i], of 0 and 1, as BOOL. */
bool cetta_tensor_file_write_safetensors_as(const char *path, size_t count,
    const char *const *names, const CettaDenseTensorV1 *const *tensors, const bool *booleans,
    size_t metadata_count, const char *const *keys, const char *const *values,
    uint64_t *written, CettaTensorFileError *error);

/* A string column, as Arrow stores one: i64 offsets of length n + 1, starting
 * at 0 and nondecreasing, into the UTF-8 bytes of a u8 tensor. */
bool cetta_tensor_string_column(size_t count, const char *const *strings,
    const size_t *lengths, CettaDenseTensorV1 **offsets, CettaDenseTensorV1 **bytes,
    CettaTensorFileError *error);
/* Checks every offset and string. */
bool cetta_tensor_string_count(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes,
    size_t *count, CettaTensorFileError *e);
/* Checks only the two offsets it reads, and that string's UTF-8. */
bool cetta_tensor_string_at(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes,
    size_t index, const char **text, size_t *length, CettaTensorFileError *error);
/* An open-addressing table of the column's rows, i64 [2^k] with at least
 * twice as many slots as strings and -1 for an empty slot. Checks the column
 * as string_count does, and refuses two equal strings. */
bool cetta_tensor_string_index(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes,
    CettaDenseTensorV1 **index, CettaTensorFileError *error);
/* The row of the string equal to value, or -1. Every candidate row is
 * compared, so a damaged index can miss a string but never names a wrong row. */
bool cetta_tensor_string_find(const CettaDenseTensorV1 *index, const CettaDenseTensorV1 *offsets,
    const CettaDenseTensorV1 *bytes, const char *value, size_t length, int64_t *row,
    CettaTensorFileError *error);
/* A u8 [n] mask, 1 where the string equals value. */
bool cetta_tensor_string_mask(const CettaDenseTensorV1 *offsets, const CettaDenseTensorV1 *bytes,
    const char *value, size_t length, CettaDenseTensorV1 **mask, CettaTensorFileError *error);

/* The lib_tensor natives: file_info, load, map, load_all, map_all, open_all,
 * save_npy, save_safetensors, strings, string_count, string_at, string_index,
 * string_find, string_mask and string_column. */
Atom *cetta_tensor_files_v1_dispatch(Arena *arena, const char *operation, size_t length,
    Atom **args, uint32_t nargs);

#endif
