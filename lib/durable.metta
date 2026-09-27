; One commit domain across named spaces. Each key is an occurrence identity.
; A snapshot is immutable data. It carries an epoch and a global revision;
; committing a decision made from a stale snapshot fails, including absence
; queries. Keep input consumption, state/continuation, and outbox in one batch.
;
; Stored values are closed data. Name the continuation and save its arguments;
; do not capture a runtime space, state cell, variable, or native handle.

(: durable:open (-> String Expression))
(: durable:read (-> String Expression))
(: durable:commit (-> String Number Atom Expression))
(: durable:checkpoint (-> Expression))
(: durable:close (-> Expression))


(= (durable:open $path)
   (__cetta_lib_durable_open $path))
(= (durable:read $space)
   (__cetta_lib_durable_read $space))
(= (durable:commit $epoch $revision $operations)
   (__cetta_lib_durable_commit $epoch $revision $operations))
(= (durable:checkpoint)
   (__cetta_lib_durable_checkpoint ()))
(= (durable:close)
   (__cetta_lib_durable_close ()))
