# Durable named spaces

The optional `durable` library supplies one local commit domain across named
record spaces. It is the storage boundary for a durable process host, not a
transport dispatcher. Applications work with MeTTa data and do not issue SQL.

Build with `ENABLE_DURABLE=1`. The default SQLite provider is the pinned
amalgamation in `vendor/sqlite`. `SQLITE_PROVIDER=system` uses a development
package discoverable through pkg-config (SQLite 3.37 or newer). A build without
the feature returns `(durable:failure unavailable)`.

CLI administration is off by default. A dedicated maintenance invocation,
`cetta --durable-admin repair.metta`, enables literal top-level administrative
directives after `!(import! &self durable)`. Service and cognitive-worker
invocations must never pass this flag: their editable bootstrap files are
ordinary application code. Without the flag, even literal root directives
return `(durable:failure commit-boundary-required)`.

Administrative commits are repair-only, never application transitions. Their
arguments are literal data. For example,
`!(durable:open "coordination.db")` opens the store and returns its epoch and
revision. A subsequent `!(durable:commit "EPOCH-FROM-OPEN" 0 ((durable:insert
"state" "worker" (waiting 0))))` uses the actual 32-character epoch from that
reply. `!(durable:read "state")`, `!(durable:checkpoint)` and
`!(durable:close)` inspect, checkpoint and close it.

These are administrative commands, not effectful functions available to a
rewrite. Ordinary evaluation returns `(durable:failure commit-boundary-required)`
for their native implementation, even through user equations, `eval`, imports,
`superpose`, `collapse`, or deferred rho payloads. This deliberately replaces
the initial API that allowed a `case` around `read` to call `commit` directly.
Administrative results are returned as inert data without entering reduction.
An embedded caller must explicitly use the administrative C entry point or the
store API, outside evaluation.

The durable host will evaluate MeTTa/rho reactions against supplied snapshot
data, obtain proposed changes, select one transition, and commit through the
C API. No evaluator branch receives this authority. This boundary gates durable
administration; the host must additionally deny unmediated HTTP, foreign calls,
and other external effects during speculative evaluation.

`open` returns a recovered snapshot. `read` returns
`(durable:snapshot epoch revision (records ...))`; each record is
`(durable:record "space" "key" value)`. `read "*"` reads all named spaces.
Returned data is immutable and its nested expressions are not evaluated.
Records are enumerated by their last mutation's revision and batch position;
applications needing a different order must store their ordering key.

Each key identifies an occurrence, so identical values under different keys
remain distinct. Insert requires an absent key; replace and remove require an
existing key. A batch may name a key once. All preconditions must hold or the
whole batch rolls back. Success is `(durable:committed epoch new-revision)`.

The administrative commit API validates the expected epoch and global revision
without a read set. Use the scoped C API for application decisions:

1. `cetta_durable_observe` reads declared keys, prefixes and whole spaces in
   one transaction, returning an owned observation with immutable views.
2. Evaluation uses those views outside the transaction. All reads affecting
   the decision must be declared, including absence and range predicates.
3. `cetta_durable_commit_observed` validates the exact keys and revisions in
   each view under `BEGIN IMMEDIATE`, then applies the batch. Every written
   key must also be covered by a declared scope. Empty views validate absence.

The host must enforce three observation invariants:

- Every durable value visible to a decision comes from this observation. Do not
  supply cached state from an earlier snapshot, including remembered routing.
- The host pairs a proposal with the exact observation it supplied. A proposal
  cannot declare, widen or replace its own read scopes.
- LLM output, clock readings and randomness enter as recorded observations.

Together with denial of durable reads during evaluation, these rules make the
host-supplied observation the complete durable read set of the decision.

Validation uses exact comparisons, not hashes, and needs no tombstone table.
Unrelated writes do not conflict. A removed and reinserted record has a new
revision and invalidates a positive read. An insertion followed by removal
preserves an absence observation: the predicate is true again at commit.
Prefixes are binary byte ranges using the `(space,key)` primary index, with no
wildcard interpretation. Observations bound their total materialized size,
including overlapping scopes. They retain no SQLite transaction.

A conflict permits retrying a pure decision; it does not permit repeating an
external effect. In particular, persist a completed LLM response as an input
observation rather than repeating its request to rebuild a draft. After losing
a commit acknowledgment, inspect the accepted-work record before proposing
another action.

## Storage and recovery

SQLite runs in WAL mode with synchronous FULL and short transactions. Each
transaction updates current records, appends their deltas, and advances the
revision together. Open compares the checkpoint-plus-delta reconstruction against current records
byte for byte, and checks accounting in the same read transaction. A mismatch
fails closed as corruption. Snapshot and recovery also use explicit read
transactions. Reconstruction executes no application program. Checkpointing replaces
the checkpoint and truncates the delta history atomically, preserving every
live record, including pending and uncertain work. SQLite's own WAL recovery
remains responsible for interrupted database transactions.

A persistent random epoch distinguishes database identities. A restored copy
retains that epoch: it does not gain dispatch authority. The host must start
shadow/replay copies with dispatch disabled and separately control ownership. Schema versions
are checked on open. The service must pin its handler, payload-language and
continuation versions in its own coordination records; this storage layer does
not migrate application programs.

One cooperating local process holds a lifetime OS lock on the database inode.
Use a private directory on a local filesystem for the database and its SQLite
sidecars. Do not rename or replace an open database. This lock is not fencing
for a distributed deployment or for unrelated software that bypasses it.
Store operations serialize across threads; close requires exclusive caller
ownership. Evaluation and HTTP never run inside a database transaction.

Default admission bounds are 1 MiB per value, 4 MiB per batch, 4096 operations
per batch, 100,000 live records, 64 MiB of live record data and names, and 16 MiB
of retained delta data and names. A growth batch folds history into a
checkpoint when its budget would be exceeded. Removal-only batches use a
reclamation reserve instead: their extra history is bounded by the names of
existing occurrences they remove. This avoids copying the live set to permit
a deletion near the page cap. Removal-only batches also tolerate lowered byte
budgets smaller than existing names; their size remains bounded by the operation
count and the fixed name-size limit. Before a subsequent growth batch, history is
compacted again. The database is capped at 65,536 pages; checkpoint
and WAL space also require disk headroom. A full disk or exceeded quota fails
the operation without publishing a revision. An I/O error at COMMIT instead
returns `unknown-outcome`: the transaction might have committed. I/O errors
and corruption poison the connection; subsequent operations return `poisoned`
until it is closed and reopened. Never use a missing success receipt as
permission to acknowledge an input, dispatch a proposal, or blindly retry it.

Lowering admission limits does not prevent open, snapshot, recovery, removal or
checkpointing. The usage API reports exceeded limits. Changes that increase an
already excessive live-byte or record count are rejected; shrinking changes
remain admissible. Existing values above a new value-size limit remain readable.
Physical disk exhaustion can still prevent any write; the reserve avoids a
forced checkpoint copy, not SQLite's own need for working disk space.

The C API exposes bounds for the host to configure. The MeTTa library currently
uses the defaults. No long-lived SQLite reader transaction escapes this API.
Backups must use SQLite's backup facilities or a stopped, closed database;
copying only the database file while WAL is active is not a backup protocol.

## Stored data

The versioned CDV1 codec supports symbols, strings, booleans, signed integers,
binary64 floats, big integers and rationals, and ground expressions. Float bits
survive the round trip, including signed zero and NaN. Exact numbers retain
their exact value. Decoding rejects truncation, trailing bytes, unknown tags
and invalid exact-number text. Unknown tags and damaged headers are corruption;
a recognized newer CDV header is an unsupported version. A failed MeTTa decode
identifies the offending space and key. It never silently drops the record.

Use strings for unbounded identifiers, user text, Telegram IDs, and effect IDs.
Symbols are intended for a finite protocol vocabulary: decoding interns them in
CeTTa's process-wide symbol table, which is not reclaimed by arena resets. This
codec does not enforce a lifetime budget on newly interned symbols.

This is a closed-data fragment, not a heap image. Variables, spaces, mutable
cells, foreign values and native handles are rejected. Represent a continuation
by its name, program version and ground arguments. Expression depth is bounded
at 128 and expanded node count at 100,000. Sharing is not encoded, and cycles
fail admission. These are explicit admission limits, not claims that arbitrary
CeTTa spaces or cyclic runtime objects can be persisted.

## Checks

`make test-durable-store` checks atomic transitions, stale snapshot rejection,
checkpoint/delta reconstruction, concurrent decisions, process death at four
write boundaries, a SQLite full-disk condition, quotas and version rejection.
It also tests actual WAL fsync failure through a VFS interposer, poisoned-handle
refusal, byte-for-byte recovery validation, lowered limits, deletion at the page
cap, a concurrent writer between metadata and record reads, and scoped decisions
amid unrelated traffic and conflicting positive/negative reads.
`make test-durable-value` checks the codec. With an enabled binary,
`python3 tests/test_durable_library.py ./cetta` checks the MeTTa boundary and
recovery, refusal without administrative opt-in, and speculative denial in
PeTTa and HE, including rho payloads even during an administrative invocation.

## Speculative evaluation

The native host uses `eval_top_speculative` with an HE library context to compute
proposals. This policy is native authority: no MeTTa option, pragma, CLI repair
flag or environment variable enables effects within it. Nested choices and rho
payloads inherit the same session policy. The previous policy and context are
restored on return, including the previous fuel setting. Other language profiles remain available to an independent
cognitive worker; this service evaluation entry currently accepts HE only.

An explicit allowlist admits arithmetic, structural computation, control forms,
in-memory queries and the audited string, JSON and rho interfaces. Core
operations and native library extensions are denied by default until audited.
The checks apply at execution, so quoted effect descriptions are ordinary data.
Filesystem access, ambient process observations, raw transport, foreign calls,
module loading, mutable state/space operations and durable-store operations are
unavailable. Rejection produces `(Error speculative-evaluation EffectNotAllowed)`
without echoing arguments. Existing HE control forms retain their error
semantics: for example, `collapse` may omit a rejected branch. Every attempted
forbidden effect also increments a shared atomic counter, independent of the
result bag. `EvalOutcome.effect_denials` reports this count. If evaluation would
otherwise be complete, a denial changes completion to `effect-denied`; another
incomplete reason (such as exhausted fuel) is preserved alongside the count.
The host must reject the entire evaluation on any denial or incomplete outcome,
without committing its remaining proposals. An ordinary Error value supplied as
data is not itself a denied effect. Counts saturate instead of wrapping.
State changes are returned as proposals. Prepared execution and
the relational machine are deferred at this boundary pending separate
qualification; ordinary evaluations retain their existing optimizations.

The host must load its trusted, versioned program before this entry and provide
fresh in-memory query spaces for the exact durable observation. Never provide
external backends, foreign handles, mutable live resources or cached state from
another snapshot. This is an evaluator effect boundary, not an OS sandbox for
untrusted native code. The host must validate closed proposal values, pair them
with the original observation and commit the selected transition. Returning a
term named `telegram:send` does not confer channel authority or dispatch it.
The entry requires an explicit positive fuel argument and refuses zero or
unlimited budgets before evaluation. Nested evaluation debits the same bounded
purse. The host also supplies input/result limits and wall-clock supervision;
this entry does not implement service admission or scheduling policy.

`make ENABLE_HTTP=1 ENABLE_DURABLE=1 test-speculative-eval` exercises the native
entry against a private counted HTTP peer and a file sentinel. It checks pure
proposals, quoted data, computed heads, nested choices and rho payloads, denied
operations and policy restoration. Qualification uses HE's extended profile,
including a two-thread configuration; finite fuel selects the existing
cooperative fallback. Threaded rho/cost-trace entries remain excluded. Before
admitting them, workers must attach a context without `eval_set_library_context`
(which initializes its fuel from thread-local defaults). Python-enabled builds also load a callable
before evaluation and verify that neither a direct nor computed call executes
it. Other language entries are refused before execution. The normal HE and
PeTTa corpus paths run with the policy off.

The native host below pairs this evaluation boundary with scoped channel
grants and durable acceptance. The independently supervised Telegram service
remains integration work.


## Native Telegram credential boundary

`telegram_transport.h` supplies an immutable host-only credential reference.
The host opens a private regular descriptor without following symlinks; reading
is bounded, accepts a final newline, leaves the descriptor position unchanged,
and returns enum errors only. The reference has no token getter and never
enters a MeTTa value, durable record or serialized proposal. Rotation constructs
a replacement after outstanding users have finished.

The native adapter constructs the token-bearing Bot API URL immediately before
request admission. Production defaults to `https://api.telegram.org`. A trusted
host configuration can select another HTTPS origin and CA bundle; HTTP requires
an explicit loopback-only mock option. Proposals cannot select the origin,
redirect policy, proxy, TLS configuration or idempotence. Ambient proxies are
disabled for this adapter, redirects are refused, and certificate/hostname
verification stays enabled. The generic HTTP worker still supports native
proxy/CA settings, with their copied bytes charged to its admission budget.

Effects use the default fresh, non-reusable transport. The separate host poll
entry alone opts into reuse for `getUpdates`; an effect cannot select that
method, `setWebhook`, `deleteWebhook`, `logOut` or `close`, regardless of case.
These control update delivery or bot availability and require operator action.
The host still enforces positive method and chat-routing allowlists. Application
permissions and retry decisions remain the host and MeTTa/rho library's responsibility.

Before journaling a response or constructing any evaluator atoms, the host must
call `cetta_telegram_response_safe`. It performs a bounded linear scan for the
secret suffix after the colon, including percent/JSON ASCII-Unicode escaped
spellings. This also catches the full token. On reflection,
suppress the body and record a minimal privacy outcome: the remote operation's
success remains unknown. This is defense against accidental reflection, not
information-flow security against an adversarial server's arbitrary encoding.
Provider schema validation is still required. Private URL buffers owned by the
adapter and worker are erased; this does not promise erasure of every copy
inside curl/TLS. The service must disable core dumps (`LimitCORE=0` under systemd).

`make BUILD=core ENABLE_HTTP=1 test-telegram-transport` uses only fake credentials
and loopback peers. Its Python fixture requires `h2` and `openssl`. It qualifies
HTTP/1.1, HTTPS/1.1 and negotiated HTTP/2 against drop-after-complete-request-read,
with independent receipt counts and connection identity checks. It also checks
poll reuse, redirect refusal, poisoned ambient proxy settings, reflected-token
screening, untrusted CA and wrong-hostname failures. These tests qualify those
faults on the linked libcurl; they do not establish remote exactly-once delivery
or a universal absence of every protocol-level retry.

This native adapter is not an evaluator builtin. The production durable host
must still connect credential lookup and response screening to its registered
channel and observation-recording boundaries.

## Native decision acceptance

`durable_host.h` joins the scoped store and the speculative evaluator. It is a
native host API, not a library operation available to evaluated code. The host
opens a decision with an input occurrence, actor identity, program version,
read/write space grants and channel grants. It receives immutable views from
one snapshot. Input and actor dependencies are always included; other scopes
include negative key/prefix/space observations. Unrelated inbox arrivals or
HTTP outcomes do not invalidate the decision.

`cetta_host_evaluate` builds fresh in-memory spaces and a private registry from
the ticket's views and the trusted program. It owns the copied syntax, projected
values and evaluation outcome. The program version must match the ticket.
`cetta_host_accept` accepts only that stored outcome; no caller-supplied status
or foreign ticket's result can replace it. A failed re-evaluation clears the old
result. Program templates are immutable code/static facts, never cached decision
data; native handles and preinserted `host:record` facts are refused. The program's
library context must not contain a previous decision's registry or spaces.
Worker proposals, LLM output, clock and randomness enter through recorded inbox
data, never as a trusted expression to execute. Parse and JSON
inputs must be bounded before symbol interning; use strings for unbounded IDs
and external text. Pending ticket count and aggregate observation memory also
require bounded admission in the service.

For draft supersession, key inbound occurrences by chat/update and include a
read-only prefix scope for that chat's inbox lane. New input in the same lane
invalidates the unaccepted decision; another chat's input does not. This does
not cancel an already accepted intent.

One selected result has this closed-data shape:

```metta
(host:transition
  (waiting "reply")
  ((host:put 0 "actor/value" 42))
  ((host:send 0 (sendMessage "approved-chat" "hello") (resume "reply"))))
```

A write uses a space-grant index and a string key inside its declared scope.
`host:put` inserts or replaces according to that exact observation;
`host:remove` requires presence. Duplicate write keys are rejected before a
commit attempt, including aliases through different grants. A send uses a channel-grant index, payload and
reply continuation. These indices select authority bound to the native ticket;
writing a channel name or another number grants no additional permission.
Native channel validators are pure and bounded, and enforce payload/method/chat
permissions before commitment. Their context must stay immutable until the
host retires the ticket; a policy change must retire affected tickets. Programs
cannot write reserved `host.*` spaces through state grants.

`cetta_host_accept` requires bounded, complete evaluation with no effect denials.
It bounds and encodes the selected result, validates all grants, then atomically:

- consumes the bound `host.inbox` occurrence;
- replaces `host.actors` with a versioned continuation;
- applies granted state writes;
- inserts immutable `host.outbox` intents with channel and handler versions;
- records program version, input/actor identity and selected alternative in
  `host.commits`.

No evaluation, callback or networking runs inside the storage transaction.
Unselected alternatives produce no intents. There is no dispatch operation in
this API. The thin `durable:rho` module supplies request descriptions and pure
completion-to-rho projection; the embedding host supplies completions only after
recording them durably.

Private random receipt keys and outbox prefixes reserve fresh identities using
absence scopes. This bookkeeping randomness is not exposed as program input or
used to select branches. The receipt key remains available through the native
ticket even after an unknown commit acknowledgment. A ticket is spent once
commit is attempted; recovery inspects its journal receipt. Transport handles
are not effect IDs: an immutable outbox row's `(epoch, revision, position)` is
its durable occurrence identity. Keep claims/outcomes separate so later status
changes never overwrite the acceptance revision. Checkpoints preserve those
identities and all unresolved intents.

Wire records use CDV1, with schema 1 envelopes `host:actor`, `host:commit` and
`host:intent`. This records versions, not an automatic upgrade protocol: the
service must explicitly handle incompatible waiting continuations/handlers.
Receipts support inspection; they do not constitute deterministic replay.

`make BUILD=core ENABLE_DURABLE=1 test-durable-host` exercises actual speculative
HE evaluation and rho COMM, authority rejection, hidden effect denial, selection
of one alternative, absence conflicts, unrelated traffic, atomic rollback and
process death before/after acceptance.

## Accepted intent to durable completion

`durable_dispatch.h` connects immutable accepted outbox rows to the native
Telegram transport. It owns one HTTP worker and binds channel names/versions
to immutable native credentials and bounded request marshalling callbacks.
Those callbacks enforce positive method and destination allowlists; they run
on the host thread, before admission. Application routing and retry decisions
belong in MeTTa/rho, not these callbacks.

The store's lifetime file lock excludes other processes. A native runtime
attachment also refuses a second dispatcher on the same store handle. Startup
recovery completes before the worker starts. Administration, store closure and
policy/credential replacement require stopping the owner first.

The I/O owner checks the exact accepted row (epoch, revision, position and
bytes, including channel name/version) against its authorized request and
current immutable registry. It atomically inserts `host.attempts` before any
network activity. A repeated submission never creates a second attempt.
Transport handles are ephemeral; durable effect IDs use the acceptance
`epoch/revision/position`, with a distinct `/1` first-attempt ID.

Responses pass the credential screen before encoding or journaling. The owner
uses the native CDV1 field encoder, which has no evaluator or symbol-table
access. It commits `host.outcomes` and a `host.inbox` completion occurrence in
one transaction. Outcomes retain the transport status and safe response bytes;
HTTP 200 is not itself Telegram API success. The trusted application must
validate the JSON response and classify its `ok`/result/error fields.

Schema-1 outcome shape:

```metta
(host:outcome 1 "effect-id" "attempt-id-or-empty" kind
  (started cancelled curl-code http-status request-size-known request-size
   response-too-large response-budget-exceeded allocation-failed)
  "response-body")
(host:completion 1 "effect-id" "outbox-key")
```

Kinds are `observed`, `uncertain`, `not-started`, `privacy-suppressed` and
`unrecordable`. Privacy-suppressed and unrecordable outcomes make no assertion
of API success or failure. Embedded NUL cannot enter a CDV1 string, so such a
body becomes an explicit unrecordable outcome. Response bodies are bounded to
256 KiB; there are at most 64 registered jobs, in addition to the HTTP worker's
queue/byte limits. Unbounded external IDs and response text remain strings.

Full recording failures use the worker's bounded retries and minimal-fact
fallback. If even the minimal transaction cannot commit, retained jobs park and
the required health callback escalates outside the journal. No HTTP is repeated.
Transient claim conflicts/busy results retry at most five times before
escalation and recording of a not-started result. Failed/unknown commits never
authorize network activity.

Cancellation before a claim atomically records a definitive not-started outcome
and completion. After a claim, it records a cancellation request and signals the
worker; a racing completion remains a fact. An existing outcome is never
overwritten or re-injected after its completion has been consumed.

On startup, a claim without an outcome becomes `uncertain`; unavailable
transport metadata is represented by `unknown`, not fabricated zero/false
values. Recovery itself performs no HTTP. This first-attempt mechanism has no
automatic retry: another dispatch of the same intent is refused. A later retry
policy must explicitly authorize and record new work, with its relationship to
the original intent, before sending again.

`make BUILD=core ENABLE_HTTP=1 ENABLE_DURABLE=1 test-durable-dispatch` runs a real
rho reaction through acceptance, HTTP, durable completion and a second rho
continuation. A private mock exercises HTTP/1.1, HTTPS/1.1 and negotiated HTTP/2,
lost responses, secret reflection, cancellation, oversized recording, storage
exhaustion, duplicate admission, SIGKILL after remote receipt and recovery
without resending or recreating consumed completions. The fixture uses only
invented credentials.

This is an embedded transport boundary. The independently supervised service,
worker IPC, inbox cursor, timers, ordered chat lanes and full Telegram policy
remain separate integration work.

## Received batches and the remote cursor

`durable_inbox.h` provides the native batch-commit boundary. The host opens a
window on one source's committed cursor, uses that offset for its poll, and
commits the screened, validated and classified batch through that window.
Only a successful commit returns a new offset that may acknowledge the batch
remotely. Telegram confirms updates when a later poll's offset passes their
IDs, so constructing offsets from uncommitted responses loses updates across
a crash. [Telegram getUpdates](https://core.telegram.org/bots/api#getupdates).

One transaction inserts immutable `host.received` occurrences, their
`host.inbox` references and the new `host.cursors` value. Identity is
`source/update-id`; the inbox key is `source/lane/update-id`, so a chat-prefix
read scope can invalidate stale drafts without depending on other chats.
Source and lane are bounded native-selected string components, not symbols or
credentials. A source is the stable bot identity across token rotations.

Schema-1 envelopes:

```metta
(host:received 1 "source" update-id "lane" disposition closed-payload)
(host:input 1 "source" update-id "source/update-id" "lane" disposition)
(host:cursor 1 "source" next-offset)
```

The trusted reaction declares the referenced received-record scope when it
needs the payload. Core consumption remains a separate input/state/outbox
transaction. Consuming an inbox reference does not erase its received record;
repeated delivery therefore cannot recreate consumed work. Different payload,
lane or disposition under an existing identity is an explicit corruption
result, never a silent replacement. Retention must preserve this deduplication
evidence while replay is possible; storage pressure stops admission rather
than acknowledging data that was not retained.

Gaps, repeated IDs and out-of-order batches are handled without a contiguous-ID
assumption. A distinct lower ID is retained while the cursor remains monotone.
Exact duplicate IDs within a batch collapse; conflicting duplicates reject
the whole batch. `routed`, `unsupported` and `unauthorized` dispositions all
retain the payload. Application policy decides which inputs enter cognition
or operator handling; unsupported input is not silently discarded.

A window conflicts if its source cursor changes; unrelated traffic does not
invalidate it. Commit attempts spend the window even when acknowledgment is
unknown. Recovery opens a fresh window and reconciles the original batch
against the ledger. Empty batches spend their window without writing or
advancing the cursor. Batches contain at most 100 items and at most 4 MiB of
encoded candidates, subject also to the store's configured limits and the
closed-value codec's per-value bounds.

`make BUILD=core ENABLE_DURABLE=1 test-durable-inbox` covers these rules,
capacity-failure rollback and process death before/after the batch commit.
This native API is not exposed to worker proposals. The HTTP poll owner must
still bind requests to its window and validate/screen provider data before
calling it; this module alone is not a receiving service.

## Durable timers

`durable_timer.h` implements the native `timer.after` channel, version `1`.
The accepted outbox intent is the timer registration; there is no second
registration write. `durable:timer:after` and `durable:timer:every` in
`lib/durable/timer.metta` construct requests from a supplied, recorded clock
observation. They never read an ambient clock. The native channel validator
accepts closed payloads and replies of at most 64 KiB each:

```metta
(timer:at 1 utc-deadline-ms period-ms policy grace-ms value)
```

Deadlines, periods and grace intervals are nonnegative signed 64-bit
milliseconds. Period zero means one-shot. The policy is explicit:

- `FireOnce` emits one firing representing all due occurrences and advances
  beyond the sampled time.
- `SkipMissed` records a summary of deadlines older than the grace interval.
  A deadline exactly at the grace boundary still fires. Skipped work is
  observable, not silently lost.
- `CatchUpAll` emits individual overdue occurrences, at most eight per timer
  per tick. A tick admits at most 64 events, with a caller-selected smaller
  budget and a round-robin cursor so one backlog cannot monopolize admission.

For each timer, one transaction inserts its `host.inbox` observations and
advances `host.timer-state`, or writes a terminal `host.outcomes` record and
removes the cursor. Event keys are `timer/effect-id/sequence`, where effect
identity comes from the accepted intent's epoch, revision and position.

```metta
(host:timer-event 1 "effect-id" sequence kind scheduled-ms observed-ms
  represented-count value reply)
(host:timer-state 1 "effect-id" next-deadline-ms next-sequence observed-ms)
(host:timer-outcome 1 "effect-id" kind next-sequence observed-ms)
```

Event kinds are `fired`, `skipped` and `cancelled`. A cancellation records its
own event with represented count zero and prevents later firings; any earlier
committed firing remains a fact. Cancelling an already terminal timer is a
no-op. Concurrent firing and cancellation conflict on their observed state;
neither overwrites the other. A deadline beyond the integer range ends the
periodic timer with an `exhausted` outcome instead of wrapping.

Recovery uses the committed cursor/outcome. Consuming a wake-up does not make
it eligible for delivery again. A failed event transaction cannot advance its
timer. An unknown commit acknowledgment requires recovery, not an assumed
failure. Invalid or unsupported timer records are retained and reported by a
required native fault callback; other timers may continue. Storage failures
stop admission and report the failure. The host must escalate or back off,
rather than spin on an unrecordable wake-up.

A forward wall-clock jump makes timers overdue; a backward jump postpones
firing until the stored UTC deadline is reached. Used time samples are stored
with the event and cursor. `cetta_timer_wait_ms` derives a monotonic wait from
a UTC/monotonic sample and caps it at one second, so the service can resample
wall time and notice new work. It does not perform the wait. Tick/validation
run on the host's evaluator thread, not the HTTP owner thread.

This initial implementation scans the bounded accepted outbox when ticked;
the event budget does not bound scan cost. A service may schedule the next
tick using the returned deadline and admission wake-ups. An incremental timer
index and retention of completed intents are separate optimizations, and must
preserve the journal as the authority. The independent service loop is still
integration work.

`make BUILD=core ENABLE_DURABLE=1 test-durable-timer` covers the accepted
MeTTa requests, clock jumps, overdue policies and inclusive grace boundary,
bounded catch-up and fairness, cancellation, integer exhaustion, capacity
rollback, and process exit/recovery before and after delivery.
