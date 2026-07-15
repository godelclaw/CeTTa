#ifndef CETTA_GROUP_FOLD_EXTERNAL_H
#define CETTA_GROUP_FOLD_EXTERNAL_H

#include <errno.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define CETTA_GROUP_FOLD_MERGE_FAN_IN 32u

typedef struct {
    char *key;
    char *item;
    uint64_t ordinal;
} CettaGroupFoldRecord;

typedef struct {
    CettaGroupFoldRecord *records;
    size_t len;
    size_t cap;
} CettaGroupFoldRecordBuffer;

typedef struct {
    char **paths;
    size_t len;
    size_t cap;
} CettaGroupFoldRunList;

static inline void cetta_group_fold_record_clear(CettaGroupFoldRecord *record) {
    if (!record)
        return;
    free(record->key);
    free(record->item);
    *record = (CettaGroupFoldRecord){0};
}

static inline void cetta_group_fold_record_buffer_clear(
    CettaGroupFoldRecordBuffer *buffer) {
    if (!buffer)
        return;
    for (size_t i = 0; i < buffer->len; i++)
        cetta_group_fold_record_clear(&buffer->records[i]);
    free(buffer->records);
    *buffer = (CettaGroupFoldRecordBuffer){0};
}

static inline bool cetta_group_fold_record_buffer_push(
    CettaGroupFoldRecordBuffer *buffer,
    const char *key,
    const char *item,
    uint64_t ordinal) {
    if (!buffer || !key || !item)
        return false;
    if (buffer->len == buffer->cap) {
        size_t next_cap = buffer->cap ? buffer->cap * 2u : 256u;
        if (next_cap < buffer->cap ||
            next_cap > SIZE_MAX / sizeof(*buffer->records)) {
            return false;
        }
        CettaGroupFoldRecord *next =
            realloc(buffer->records, next_cap * sizeof(*next));
        if (!next)
            return false;
        buffer->records = next;
        buffer->cap = next_cap;
    }
    char *key_copy = strdup(key);
    char *item_copy = strdup(item);
    if (!key_copy || !item_copy) {
        free(key_copy);
        free(item_copy);
        return false;
    }
    buffer->records[buffer->len++] = (CettaGroupFoldRecord){
        .key = key_copy,
        .item = item_copy,
        .ordinal = ordinal,
    };
    return true;
}

static inline int cetta_group_fold_record_compare(const void *lhs_raw,
                                                  const void *rhs_raw) {
    const CettaGroupFoldRecord *lhs = lhs_raw;
    const CettaGroupFoldRecord *rhs = rhs_raw;
    int by_key = strcmp(lhs->key, rhs->key);
    if (by_key != 0)
        return by_key;
    if (lhs->ordinal < rhs->ordinal)
        return -1;
    if (lhs->ordinal > rhs->ordinal)
        return 1;
    return 0;
}

static inline bool cetta_group_fold_write_u32(FILE *file, uint32_t value) {
    uint8_t bytes[4] = {
        (uint8_t)(value >> 24),
        (uint8_t)(value >> 16),
        (uint8_t)(value >> 8),
        (uint8_t)value,
    };
    return fwrite(bytes, 1, sizeof(bytes), file) == sizeof(bytes);
}

static inline bool cetta_group_fold_write_u64(FILE *file, uint64_t value) {
    uint8_t bytes[8];
    for (unsigned i = 0; i < 8; i++)
        bytes[7u - i] = (uint8_t)(value >> (i * 8u));
    return fwrite(bytes, 1, sizeof(bytes), file) == sizeof(bytes);
}

static inline bool cetta_group_fold_read_u32(FILE *file, uint32_t *value,
                                             bool *at_end) {
    uint8_t bytes[4];
    size_t got = fread(bytes, 1, sizeof(bytes), file);
    if (got == 0 && feof(file)) {
        if (at_end)
            *at_end = true;
        return true;
    }
    if (got != sizeof(bytes))
        return false;
    if (at_end)
        *at_end = false;
    *value = ((uint32_t)bytes[0] << 24) |
             ((uint32_t)bytes[1] << 16) |
             ((uint32_t)bytes[2] << 8) |
             (uint32_t)bytes[3];
    return true;
}

static inline bool cetta_group_fold_read_u64(FILE *file, uint64_t *value) {
    uint8_t bytes[8];
    if (fread(bytes, 1, sizeof(bytes), file) != sizeof(bytes))
        return false;
    uint64_t result = 0;
    for (unsigned i = 0; i < 8; i++)
        result = (result << 8) | bytes[i];
    *value = result;
    return true;
}

static inline bool cetta_group_fold_write_record(
    FILE *file, const CettaGroupFoldRecord *record) {
    size_t key_len = strlen(record->key);
    size_t item_len = strlen(record->item);
    if (key_len > UINT32_MAX || item_len > UINT32_MAX)
        return false;
    return cetta_group_fold_write_u32(file, (uint32_t)key_len) &&
           cetta_group_fold_write_u32(file, (uint32_t)item_len) &&
           cetta_group_fold_write_u64(file, record->ordinal) &&
           fwrite(record->key, 1, key_len, file) == key_len &&
           fwrite(record->item, 1, item_len, file) == item_len;
}

static inline bool cetta_group_fold_read_record(FILE *file,
                                                CettaGroupFoldRecord *record,
                                                bool *at_end) {
    uint32_t key_len = 0;
    uint32_t item_len = 0;
    uint64_t ordinal = 0;
    bool ended = false;
    *record = (CettaGroupFoldRecord){0};
    if (!cetta_group_fold_read_u32(file, &key_len, &ended))
        return false;
    if (ended) {
        if (at_end)
            *at_end = true;
        return true;
    }
    if (!cetta_group_fold_read_u32(file, &item_len, NULL) ||
        !cetta_group_fold_read_u64(file, &ordinal)) {
        return false;
    }
    char *key = malloc((size_t)key_len + 1u);
    char *item = malloc((size_t)item_len + 1u);
    if (!key || !item) {
        free(key);
        free(item);
        return false;
    }
    if (fread(key, 1, key_len, file) != key_len ||
        fread(item, 1, item_len, file) != item_len) {
        free(key);
        free(item);
        return false;
    }
    key[key_len] = '\0';
    item[item_len] = '\0';
    *record = (CettaGroupFoldRecord){
        .key = key,
        .item = item,
        .ordinal = ordinal,
    };
    if (at_end)
        *at_end = false;
    return true;
}

static inline bool cetta_group_fold_run_list_push(CettaGroupFoldRunList *runs,
                                                  char *path) {
    if (runs->len == runs->cap) {
        size_t next_cap = runs->cap ? runs->cap * 2u : 16u;
        if (next_cap < runs->cap || next_cap > SIZE_MAX / sizeof(*runs->paths))
            return false;
        char **next = realloc(runs->paths, next_cap * sizeof(*next));
        if (!next)
            return false;
        runs->paths = next;
        runs->cap = next_cap;
    }
    runs->paths[runs->len++] = path;
    return true;
}

static inline void cetta_group_fold_run_list_clear(CettaGroupFoldRunList *runs,
                                                   bool unlink_files) {
    if (!runs)
        return;
    for (size_t i = 0; i < runs->len; i++) {
        if (runs->paths[i]) {
            if (unlink_files)
                (void)unlink(runs->paths[i]);
            free(runs->paths[i]);
        }
    }
    free(runs->paths);
    *runs = (CettaGroupFoldRunList){0};
}

static inline FILE *cetta_group_fold_new_run(char **path_out) {
    const char *tmpdir = getenv("TMPDIR");
    if (!tmpdir || tmpdir[0] == '\0')
        tmpdir = "/tmp";
    size_t needed = strlen(tmpdir) + sizeof("/cetta-group-fold-XXXXXX");
    char *path = malloc(needed);
    if (!path)
        return NULL;
    snprintf(path, needed, "%s/cetta-group-fold-XXXXXX", tmpdir);
    int fd = mkstemp(path);
    if (fd < 0) {
        free(path);
        return NULL;
    }
    FILE *file = fdopen(fd, "w+b");
    if (!file) {
        close(fd);
        unlink(path);
        free(path);
        return NULL;
    }
    *path_out = path;
    return file;
}

static inline bool cetta_group_fold_flush_run(
    CettaGroupFoldRecordBuffer *buffer,
    CettaGroupFoldRunList *runs) {
    if (buffer->len == 0)
        return true;
    qsort(buffer->records, buffer->len, sizeof(*buffer->records),
          cetta_group_fold_record_compare);
    char *path = NULL;
    FILE *file = cetta_group_fold_new_run(&path);
    if (!file)
        return false;
    bool ok = true;
    for (size_t i = 0; i < buffer->len; i++) {
        if (!cetta_group_fold_write_record(file, &buffer->records[i])) {
            ok = false;
            break;
        }
    }
    if (fclose(file) != 0)
        ok = false;
    if (!ok || !cetta_group_fold_run_list_push(runs, path)) {
        unlink(path);
        free(path);
        return false;
    }
    for (size_t i = 0; i < buffer->len; i++)
        cetta_group_fold_record_clear(&buffer->records[i]);
    buffer->len = 0;
    return true;
}

static inline bool cetta_group_fold_merge_batch(char **paths,
                                                size_t path_count,
                                                char **merged_path_out) {
    FILE **inputs = calloc(path_count, sizeof(*inputs));
    CettaGroupFoldRecord *heads = calloc(path_count, sizeof(*heads));
    bool *at_end = calloc(path_count, sizeof(*at_end));
    char *output_path = NULL;
    FILE *output = NULL;
    bool ok = inputs && heads && at_end;

    for (size_t i = 0; ok && i < path_count; i++) {
        inputs[i] = fopen(paths[i], "rb");
        if (!inputs[i] ||
            !cetta_group_fold_read_record(inputs[i], &heads[i], &at_end[i])) {
            ok = false;
        }
    }
    if (ok) {
        output = cetta_group_fold_new_run(&output_path);
        ok = output != NULL;
    }
    while (ok) {
        size_t best = path_count;
        for (size_t i = 0; i < path_count; i++) {
            if (at_end[i])
                continue;
            if (best == path_count ||
                cetta_group_fold_record_compare(&heads[i], &heads[best]) < 0) {
                best = i;
            }
        }
        if (best == path_count)
            break;
        if (!cetta_group_fold_write_record(output, &heads[best])) {
            ok = false;
            break;
        }
        cetta_group_fold_record_clear(&heads[best]);
        if (!cetta_group_fold_read_record(inputs[best], &heads[best], &at_end[best]))
            ok = false;
    }

    if (output && fclose(output) != 0)
        ok = false;
    for (size_t i = 0; i < path_count; i++) {
        cetta_group_fold_record_clear(&heads[i]);
        if (inputs[i])
            fclose(inputs[i]);
    }
    free(inputs);
    free(heads);
    free(at_end);
    if (!ok) {
        if (output_path) {
            unlink(output_path);
            free(output_path);
        }
        return false;
    }
    *merged_path_out = output_path;
    return true;
}

static inline bool cetta_group_fold_merge_all_runs(CettaGroupFoldRunList *runs) {
    while (runs->len > 1) {
        CettaGroupFoldRunList next = {0};
        bool ok = true;
        for (size_t start = 0; ok && start < runs->len;
             start += CETTA_GROUP_FOLD_MERGE_FAN_IN) {
            size_t count = runs->len - start;
            if (count > CETTA_GROUP_FOLD_MERGE_FAN_IN)
                count = CETTA_GROUP_FOLD_MERGE_FAN_IN;
            char *merged = NULL;
            if (!cetta_group_fold_merge_batch(runs->paths + start, count, &merged) ||
                !cetta_group_fold_run_list_push(&next, merged)) {
                if (merged) {
                    unlink(merged);
                    free(merged);
                }
                ok = false;
            }
        }
        if (!ok) {
            cetta_group_fold_run_list_clear(&next, true);
            return false;
        }
        cetta_group_fold_run_list_clear(runs, true);
        *runs = next;
    }
    return true;
}

#endif
