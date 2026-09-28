#ifndef CETTA_DURABLE_DISPATCH_H
#define CETTA_DURABLE_DISPATCH_H
#include "durable_store.h"
#include "telegram_transport.h"
#include "atom.h"

typedef struct CettaDurableDispatch CettaDurableDispatch;
typedef struct {
    const char *method, *content_type;
    const void *body;
    size_t size;
} CettaTelegramPlan;
typedef struct {
    const char *name, *version;
    const CettaTelegramCredential *credential;
    void *context;
    /* Trusted, bounded, pure native policy/marshalling on the evaluator thread.
     * Enforce a positive method AND destination allowlist. The request must
     * derive entirely from this accepted payload. Storage/network/evaluation
     * are forbidden here. Plan bytes may borrow the supplied arena. */
    bool (*plan)(void *context, Arena *arena, const Atom *payload,
                 const Atom *reply, CettaTelegramPlan *out);
} CettaDispatchChannel;
typedef struct {
    const CettaDispatchChannel *channels;
    size_t channel_count;
    uint32_t timeout_ms;
    size_t max_response_bytes;
    void *health_context;
    /* Must report degraded health outside the journal. Called on the I/O owner,
     * without a store/dispatcher lock. No evaluator calls or dispatcher free. */
    void (*degraded)(void *context, const char *outbox_key, CettaDurableStatus status);
} CettaDispatchConfig;

/* One dispatcher per store, owned by the service. Create after acquiring the
 * store's lifetime OS lock and BEFORE admitting any transport. Claims without
 * outcomes recover as uncertain; completed effects are never re-enqueued.
 * Channel registry and policy contexts are immutable for this lifetime; contexts and credentials
 * outlive free. Calls below (except wait) belong to the evaluator/host thread. */
CettaDurableStatus cetta_dispatch_new(CettaDurableStore *store,
    const CettaDispatchConfig *config, CettaDurableDispatch **out);
/* Admit an existing accepted intent. Eligibility/order/retry policy is owned
 * by MeTTa/rho. This mechanism permits one attempt per intent; retry requires
 * a separately accepted intent, not another call on the old key. */
CettaDurableStatus cetta_dispatch_submit(CettaDurableDispatch *dispatcher,
                                       const char *outbox_key);
/* Unclaimed -> definitive not-started outcome and completion, atomically.
 * Claimed -> durable cancellation request, then best-effort transport signal.
 * Existing observations are retained. No promise to undo remote execution. */
CettaDurableStatus cetta_dispatch_cancel(CettaDurableDispatch *dispatcher,
                                       const char *outbox_key);
bool cetta_dispatch_resume(CettaDurableDispatch *dispatcher, const char *outbox_key);
uint64_t cetta_dispatch_wait(CettaDurableDispatch *dispatcher,
                            uint64_t generation, uint32_t timeout_ms);
/* Stop/join before closing store or credentials. Returns unrecorded jobs;
 * persisted claims recover as uncertain on the next service start. */
size_t cetta_dispatch_free(CettaDurableDispatch *dispatcher);
#endif
