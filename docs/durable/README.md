# Durable named spaces

The optional `durable` library supplies one local commit domain across named
record spaces. It is the storage boundary for a durable process host, not a
transport dispatcher. Applications work with MeTTa data and do not issue SQL.

Build with `ENABLE_DURABLE=1`. The default SQLite provider is the pinned
amalgamation in `vendor/sqlite`. `SQLITE_PROVIDER=system` uses a development
package discoverable through pkg-config (SQLite 3.37 or newer). A build without
the feature returns `(durable:failure unavailable)`.

```metta
!(import! &self durable)
!(durable:open "coordination.db")

; Evaluate a decision from a snapshot, then submit its changes together.
!(case (durable:read "*")
  (((durable:snapshot $epoch $revision $records)
    (durable:commit $epoch $revision
      ((durable:insert "inbox" "update:1" (message "hello"))
       (durable:insert "state" "worker" (waiting 0)))))))

!(case (durable:read "*")
  (((durable:snapshot $epoch $revision $records)
    (durable:commit $epoch $revision
      ((durable:remove "inbox" "update:1")
       (durable:replace "state" "worker" (resume reply-completion 1))
       (durable:insert "outbox" "send:1" (accepted "hello back")))))))

!(durable:checkpoint)
!(durable:close)
```

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

The expected epoch and global revision validate the snapshot used for the
decision. This is deliberately conservative: any intervening change conflicts,
even in another named space. It covers reads of absence and ranges, not just
write collisions. A conflict permits retrying a pure decision; it does not
permit repeating an external effect. After losing a commit acknowledgment,
inspect the durable accepted-work record before proposing another action.

## Storage and recovery

SQLite runs in WAL mode with synchronous FULL and short transactions. Each
transaction updates current records, appends their deltas, and advances the
revision together. Open reconstructs the view from the checkpoint and later
deltas. Reconstruction executes no application program. Checkpointing replaces
the checkpoint and truncates the delta history atomically, preserving every
live record, including pending and uncertain work. SQLite's own WAL recovery
remains responsible for interrupted database transactions.

A persistent random epoch distinguishes database identities. Schema versions
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
of retained delta data and names. History is folded into a checkpoint when its
budget would be exceeded. The database is capped at 65,536 pages; checkpoint
and WAL space also require disk headroom. A full disk or exceeded quota fails
the operation without publishing a revision. Never treat this failure as
permission to acknowledge an input or dispatch a proposal.

The C API exposes bounds for the host to configure. The MeTTa library currently
uses the defaults. No long-lived SQLite reader transaction escapes this API.
Backups must use SQLite's backup facilities or a stopped, closed database;
copying only the database file while WAL is active is not a backup protocol.

## Stored data

The versioned CDV1 codec supports symbols, strings, booleans, signed integers,
binary64 floats, big integers and rationals, and ground expressions. Float bits
survive the round trip, including signed zero and NaN. Exact numbers retain
their exact value. Decoding rejects truncation, trailing bytes, unknown tags
and invalid exact-number text.

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
`make test-durable-value` checks the codec. With an enabled binary,
`python3 tests/test_durable_library.py ./cetta` checks the MeTTa boundary and
recovery in PeTTa and HE.

This layer does not yet provide the durable host's effect capabilities,
speculation gate, credential handling, transport, or Telegram policy. Call it
from trusted coordination code. Those boundaries must be in place before using
it to dispatch external work.
