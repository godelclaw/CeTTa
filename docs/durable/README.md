# Durable named spaces

The optional `durable` library supplies one local commit domain across named
record spaces. It is the storage boundary for a durable process host, not a
transport dispatcher. Applications work with MeTTa data and do not issue SQL.

Build with `ENABLE_DURABLE=1`. The default SQLite provider is the pinned
amalgamation in `vendor/sqlite`. `SQLITE_PROVIDER=system` uses a development
package discoverable through pkg-config (SQLite 3.37 or newer). A build without
the feature returns `(durable:failure unavailable)`.

The CLI recognizes explicit top-level administrative directives after
`!(import! &self durable)`. Their arguments are literal data. For example,
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

The simple commit API still validates the expected epoch and global revision.
It suits short coordination transactions. The scoped C API supports longer
pure decisions:

1. `cetta_durable_observe` reads declared keys, prefixes and whole spaces in
   one transaction, returning an owned observation with immutable views.
2. Evaluation uses those views outside the transaction. All reads affecting
   the decision must be declared, including absence and range predicates.
3. `cetta_durable_commit_observed` validates the exact keys and revisions in
   each view under `BEGIN IMMEDIATE`, then applies the batch. Every written
   key must also be covered by a declared scope. Empty views validate absence.

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
recovery and speculative denial in PeTTa and HE, including rho payloads.

This layer does not yet provide the durable host's effect capabilities,
credential handling, transport, or Telegram policy. The durable-administration
gate is in place; the remaining effect boundaries must be in place before using
this store to dispatch external work.
