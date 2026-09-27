#ifndef CETTA_DURABLE_STORE_H
#define CETTA_DURABLE_STORE_H

#include <stddef.h>
#include <stdint.h>

/* One local owner, one commit domain, many named spaces. Keys identify
 * occurrences, so equal payloads can coexist. Values are opaque, versioned
 * data, never runtime pointers. All returned memory belongs to the caller. */
typedef struct CettaDurableStore CettaDurableStore;

typedef enum {
    DURABLE_OK, DURABLE_INVALID, DURABLE_BUSY, DURABLE_CONFLICT,
    DURABLE_PRECONDITION, DURABLE_LIMIT, DURABLE_NOMEM,
    DURABLE_IO, DURABLE_CORRUPT, DURABLE_VERSION
} CettaDurableStatus;

typedef struct {
    size_t record_bytes, batch_bytes, live_bytes, history_bytes;
    size_t records, operations;
    uint32_t database_pages; /* 4096-byte pages, plus bounded WAL overhead */
} CettaDurableLimits;

typedef enum { DURABLE_INSERT = 1, DURABLE_REPLACE = 2, DURABLE_REMOVE = 3 }
    CettaDurableOpKind;

typedef struct {
    CettaDurableOpKind kind;
    const char *space, *key;
    const void *data;
    size_t size;
} CettaDurableOp;

typedef struct {
    char *space, *key;
    unsigned char *data;
    size_t size;
    int64_t revision, position;
} CettaDurableRecord;

typedef struct {
    char epoch[33];
    int64_t revision;
    CettaDurableRecord *records;
    size_t count;
} CettaDurableSnapshot;

CettaDurableLimits cetta_durable_default_limits(void);
const char *cetta_durable_status_name(CettaDurableStatus status);

/* Opens a local regular file and holds an exclusive OS lock until close.
 * Schema versions fail closed. The caller supplies a private directory;
 * SQLite sidecars must remain on the same local filesystem. */
CettaDurableStatus cetta_durable_open(const char *path,
    const CettaDurableLimits *limits, CettaDurableStore **out);
void cetta_durable_close(CettaDurableStore *store);

/* Copies a consistent snapshot, releasing the connection before returning.
 * NULL space reads all named spaces. Even filtered reads carry the global
 * revision: committing with it validates absence and range reads too. */
CettaDurableStatus cetta_durable_snapshot(CettaDurableStore *store,
    const char *space, CettaDurableSnapshot *out);
void cetta_durable_snapshot_free(CettaDurableSnapshot *snapshot);

/* Commits all operations, their log, and the new revision atomically.
 * expected_epoch/revision come from the evaluated snapshot. No evaluation or
 * network operations occur here. Each (space,key) may occur once per batch.
 * INSERT requires absence; REPLACE and REMOVE require presence. This API has
 * no blind upsert. A failed commit never returns a published revision.
 * After an interrupted/unknown acknowledgment, inspect durable state; never
 * infer that a missing acknowledgment means a transition did not commit. */
CettaDurableStatus cetta_durable_commit(CettaDurableStore *store,
    const char *expected_epoch, int64_t expected_revision,
    const CettaDurableOp *ops, size_t count, int64_t *published_revision);

/* Atomically folds the log into a checkpoint without changing the revision.
 * Live records (including unresolved work) are never pruned. Checkpointing
 * does not grant semantic permission to remove records. */
CettaDurableStatus cetta_durable_checkpoint(CettaDurableStore *store);

/* Reconstructs a snapshot from checkpoint + committed deltas. Useful for
 * rebuilding query indexes; does not execute an application continuation. */
CettaDurableStatus cetta_durable_recover(CettaDurableStore *store,
    CettaDurableSnapshot *out);

#endif
