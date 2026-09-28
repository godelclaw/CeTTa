#ifndef CETTA_DURABLE_INBOX_H
#define CETTA_DURABLE_INBOX_H
#include "durable_store.h"
#include "atom.h"

typedef struct CettaInboxWindow CettaInboxWindow;
typedef enum { INBOX_ROUTED, INBOX_UNSUPPORTED, INBOX_UNAUTHORIZED } CettaInboxDisposition;
typedef struct {
    int64_t id;
    const char *lane; /* host-classified chat/thread, never arbitrary path syntax */
    CettaInboxDisposition disposition;
    const Atom *value; /* screened, validated closed input; no evaluator call here */
} CettaInboxItem;
typedef struct { int64_t revision, next_offset; size_t inserted; } CettaInboxCommit;

/* Native host only. Source is a stable, non-secret bot identity. Source/lane
 * components are 1..64 ASCII letters/digits/._- and never interned as symbols.
 * A window owns the committed cursor observation used to construct one poll.
 * Store outlives windows; serialize each window's calls. */
CettaDurableStatus cetta_inbox_begin(CettaDurableStore *store, const char *source,
                                   CettaInboxWindow **out);
int64_t cetta_inbox_offset(const CettaInboxWindow *window);
void cetta_inbox_window_free(CettaInboxWindow *window);
/* Up to 100 items, IDs nonnegative and below INT64_MAX, no contiguity/order
 * assumption. Ledger occurrence, routed inbox reference and cursor commit
 * together. The caller may acknowledge the returned next_offset remotely ONLY
 * on OK. On UNKNOWN reopen and inspect/retry the batch against a fresh window;
 * never infer non-commit. Attempted windows are spent, including empty batches.
 * Dedupe survives consumption: retain host.received while remote replay remains
 * possible. Same identity with different recorded data is CORRUPT, not replace.
 * This API does not parse Telegram or grant worker code poll authority. */
CettaDurableStatus cetta_inbox_commit(CettaInboxWindow *window,
    const CettaInboxItem *items, size_t count, CettaInboxCommit *out);
/* Build the read scope/inbox key needed by the trusted reaction. */
CettaDurableStatus cetta_inbox_keys(const char *source, const char *lane, int64_t id,
                                  char ledger[96], char input[168]);
#endif
