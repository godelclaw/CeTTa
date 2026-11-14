; Repair-only CLI commands with literal data arguments require --durable-admin.
; Service and cognitive-worker invocations must never enable that flag.
; Ordinary reduction (including rho payloads) cannot invoke the native store.
; Reactions produce proposals; the durable host commits a selected transition.
; Keep consumed input, state/continuation and outbox in one atomic batch.
; Use strings for unbounded identifiers; symbols are a finite protocol vocabulary.
; Stored continuations contain names, versions and ground arguments, not pointers.

(: durable:open (-> String Expression))
(: durable:read (-> String Expression))
(: durable:commit (-> String Number Atom Expression))
(: durable:checkpoint (-> Expression))
(: durable:close (-> Expression))
; Scoped administration: attach answers (durable:attached EPOCH REVISION ROWS)
; instead of every row; read-key and read-prefix answer the durable:snapshot
; of one key, or of the keys with a prefix, in one space.
(: durable:attach (-> String Expression))
(: durable:read-key (-> String String Expression))
(: durable:read-prefix (-> String String Expression))


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
(= (durable:attach $path)
   (__cetta_lib_durable_attach $path))
(= (durable:read-key $space $key)
   (__cetta_lib_durable_read_key $space $key))
(= (durable:read-prefix $space $prefix)
   (__cetta_lib_durable_read_prefix $space $prefix))
