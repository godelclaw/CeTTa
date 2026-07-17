!(import! &self ./binary_relations_context.metta)

(= (wm-fca-binary_relations-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-binary_relations-state) (WMFCAScopeStamp binary_relations-cell-000-001)))
(= (wm-fca-binary_relations-recompute-restored)
   (wm-fca-remember
     (wm-fca-binary_relations-recompute-forgotten)
     (WMFCAObservation
       binary_relations object_000_object_1 attribute_001_irreflexive WMTrue
       binary_relations-cell-000-001 fcatools-contexts-9306d256 binary_relations-published-matrix)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-binary_relations-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-binary_relations-state)
              binary_relations WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                binary_relations WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
