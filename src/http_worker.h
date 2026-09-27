#ifndef CETTA_HTTP_WORKER_H
#define CETTA_HTTP_WORKER_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Native bytes only: no arena atoms or evaluator callbacks cross this API.
 * One thread owns all easy handles and runs prepare/observe. The multi handle
 * is touched elsewhere only through curl_multi_wakeup. */
typedef struct CettaHttpWorker CettaHttpWorker;

typedef struct {
    size_t jobs, request_bytes, response_bytes;
} CettaHttpWorkerLimits;

typedef enum {
    HTTP_WORKER_OK, HTTP_WORKER_INVALID, HTTP_WORKER_FULL,
    HTTP_WORKER_DUPLICATE, HTTP_WORKER_CLOSED, HTTP_WORKER_NOMEM,
    HTTP_WORKER_UNAVAILABLE
} CettaHttpWorkerStatus;

typedef struct {
    uint64_t id;                     /* transport handle, not a durable ID */
    const char *method, *url;
    const char *const *headers;      /* complete header lines */
    size_t header_count;
    const void *body;
    size_t body_size;
    uint32_t timeout_ms;
    size_t max_response_bytes;
    bool follow_redirects;
} CettaHttpRequest;

typedef struct {
    uint64_t id;
    bool started;                   /* may have reached the remote peer */
    bool cancelled;
    bool response_too_large;
    bool response_budget_exceeded;
    bool allocation_failed;
    int transport_code;             /* CURLcode; no token-bearing error text */
    long status;
    unsigned char *body;
    size_t body_size;
} CettaHttpResult;

typedef enum {
    HTTP_PREPARE_READY,             /* claim is durable: networking may start */
    HTTP_PREPARE_DEFER,             /* no network; retry after a bounded wait */
    HTTP_PREPARE_DROP               /* no network; observe a not-started result */
} CettaHttpPrepare;

typedef struct {
    void *context;
    /* Hooks must be bounded, must not evaluate application code or perform
     * network I/O, and must not join/free this worker from its owner thread. */
    CettaHttpPrepare (*prepare)(void *context, uint64_t id);
    /* true acknowledges durable recording, or a result already recorded.
     * false retains the exact result and retries without repeating HTTP.
     * Results are observations: a cancelled started request can still have
     * executed remotely. Never interpret cancellation as proof of non-send. */
    bool (*observe)(void *context, const CettaHttpResult *result);
} CettaHttpWorkerHooks;

CettaHttpWorkerLimits cetta_http_worker_default_limits(void);
CettaHttpWorkerStatus cetta_http_worker_new(const CettaHttpWorkerLimits *limits,
    const CettaHttpWorkerHooks *hooks, CettaHttpWorker **out);

/* Copies request bytes on admission. Outstanding jobs and owned request/body
 * buffers are bounded, including completed but unacknowledged results. Curl,
 * TLS and resolver internals have additional implementation-owned memory. */
CettaHttpWorkerStatus cetta_http_worker_submit(CettaHttpWorker *worker,
    const CettaHttpRequest *request);
bool cetta_http_worker_cancel(CettaHttpWorker *worker, uint64_t id);

/* Ephemeral clients may abandon a result. This operation is refused on a
 * durable worker (one with hooks). Cancellation there must remain observable. */
bool cetta_http_worker_abandon(CettaHttpWorker *worker, uint64_t id);

/* Only available without observe hooks. Transfers the result's body to the
 * caller, which frees it with cetta_http_result_free. */
bool cetta_http_worker_take(CettaHttpWorker *worker, CettaHttpResult *out);
void cetta_http_result_free(CettaHttpResult *result);

/* Wait for a completion/progress notification or timeout, using a monotonic
 * condition variable. Does not run the transport or evaluate any MeTTa. */
uint64_t cetta_http_worker_wait(CettaHttpWorker *worker,
    uint64_t observed_generation, uint32_t timeout_ms);

/* Stop admission, abort active transfers, and join the owner. Every remaining
 * durable result is offered to observe once more. Return the number it could
 * not record; their persisted attempts must recover as uncertain. Call only
 * after excluding concurrent API users. Hooks/context live until this returns. */
size_t cetta_http_worker_free(CettaHttpWorker *worker);
#endif
