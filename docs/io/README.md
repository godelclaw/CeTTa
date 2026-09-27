# Native HTTP owner and durable recording boundary

With `ENABLE_HTTP=1`, native requests run on one curl owner thread per I/O
runtime. The evaluator can sleep or compute without polling to drive transfers.
Only C bytes cross the thread boundary; `io:poll` and `io:wait` create arena atoms
on the evaluator thread. The browser backend continues to use browser callbacks.
The native provider requires libcurl 7.85 or newer with thread-safe global
initialization and asynchronous DNS; otherwise HTTP capability is unavailable.

The existing `io` library remains ephemeral. `io:submit` returns a transport
handle, `io:poll` consumes a completion once or returns `(io:idle)`, and
`io:wait milliseconds` waits up to that monotonic deadline and consumes a
completion. A zero-time wait polls. Blocking wait is native-only; browser code
must yield to its event loop. Ephemeral `io:cancel` abandons the completion,
which is not evidence that the peer did not receive the request.

`CettaHttpWorker` is also the transport mechanism for the durable host. Its
optional pair of hooks executes on the owner thread:

1. `prepare(id)` returns READY only after the attempt claim is durable. DEFER
   keeps the request queued without networking; DROP produces a not-started
   cancellation observation.
2. Networking records status, bounded response bytes and a transport result.
3. `observe(result)` returns true only after durable recording, or after
   confirming that the same observation is already recorded. False retains
   the exact result and retries recording after a bounded wait, without
   repeating HTTP. New requests do not start while an observation is waiting
   for persistence; already active transfers continue.

Hooks must perform bounded work: no application evaluation or network calls.
Database operations must be short and fail promptly under contention. A hook
must not join or free its own worker. The host owns effect identities, attempt
identities, routing, retry policy, response redaction and completion delivery.
A worker handle is only a process-local transport identifier.

A durable worker cannot abandon a completion or expose it through `take`.
Cancellation before starting produces `started=false`; after starting it cannot
establish remote non-execution. A completed response remains a fact even if
cancellation arrives while its durable recording is pending. The host must
interpret ambiguous transport outcomes according to the effect's policy.

Stopping closes admission, cancels transfers, offers outstanding observations
to the recording hook one last time and joins the owner. It returns the count
of unrecorded observations. The caller must exclude concurrent API users
before freeing the worker. Persisted attempts without recorded outcomes must
recover conservatively as uncertain; orderly teardown does not prove delivery.

## Bounds and errors

Defaults are 64 outstanding jobs, 8 MiB of copied requests and job metadata,
and 32 MiB of response buffers. Results awaiting consumption or recording
continue to occupy those budgets. The C API can set other limits. Admission
checks capacity before copying a request body. Curl, TLS and resolver internals
use additional implementation-owned memory; these budgets are not a cap on
process RSS.

Each request additionally bounds its response, and response growth charges the
aggregate budget. Exceeding either limit fails explicitly, never reporting
truncated data as a successful response. Aggregate exhaustion is distinct from
exceeding the request's own response limit. Raw C results support binary bodies;
the existing MeTTa string adapter rejects embedded NUL bytes.

The MeTTa adapter permits at most 256 headers, 8192 bytes per header line and
URL, an 8 MiB input body, and timeout/response bounds below the signed 32-bit
limits. Inputs still must fit the aggregate admission budget.

Validation errors constructed by this adapter identify only the operation,
e.g. `(io:submit)`. Asynchronous errors identify only `(io:request id)`.
URLs, headers and request bodies are
never echoed in those error sources. Native transport diagnostics use constant
curl error descriptions; browser failures use a fixed message. Successful
response bodies are data and may themselves contain sensitive content; the
durable host must classify them before recording or exposing them.
Raw `io` still accepts caller-supplied URLs; this change does not make it a
credential vault or sanitize errors produced earlier by general evaluation.
Credential references must keep secrets out of application atoms altogether.

## Checks and scope

`make ENABLE_HTTP=1 test-http-worker` runs a private loopback fixture with a
SQLite journal. It checks independent progress, copied binary data, duplicate
handles, admission and response bounds, cancellation, durable claims before
dispatch, retained completion bytes through repeated recording failures, no
HTTP replay, recovery, unrecorded shutdown outcomes and concurrent producers.
The fixture counts requests independently of the worker.

`test-io-runtime` checks the evaluator adapter, wait, safe error sources and
one-time completion consumption, including a mutation that deliberately replays
completions. `test-io-library` exercises real submit/wait/poll calls in both HE
and PeTTa. The wrappers return Expression and dispatch directly so PeTTa does
not leave them as unevaluated function bodies.
`test-io-syntax`, `test-io-no-http` and `test-io-rho-bridge` cover the
library surface. `test-io-browser` requires an Emscripten/browser toolchain.

The recording hooks are a mechanism, not a production durable dispatcher.
Credential references, the speculative-effect gate, durable timers, Telegram
policy, the service/worker protocol and crash recovery of that protocol belong
to the host layer. Ordinary `io:submit` does not gain durability from this change.
