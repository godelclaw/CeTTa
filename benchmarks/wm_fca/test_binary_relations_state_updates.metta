!(import! &self ./binary_relations_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-state) binary_relations object_000_object_1 attribute_001_irreflexive)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-state) binary_relations object_000_object_1 attribute_000_reflexive)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-binary_relations-state) binary_relations object_000_object_1 attribute_000_reflexive)
   ((WMFCAObservation
      binary_relations object_000_object_1 attribute_000_reflexive WMFalse
      binary_relations-cell-000-000 fcatools-contexts-9306d256 binary_relations-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-state) another-context
     object_000_object_1 attribute_000_reflexive)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-binary_relations-state)
              (wm-fca-binary_relations-state))))
     (size-atom $observations))
   126)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-binary_relations-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-binary_relations-state) (WMFCAScopeStamp binary_relations-cell-000-001)))
(= (wm-fca-binary_relations-update-test-restored)
   (wm-fca-remember
     (wm-fca-binary_relations-update-test-forgotten)
     (WMFCAObservation
       binary_relations object_000_object_1 attribute_001_irreflexive WMTrue
       binary_relations-cell-000-001 fcatools-contexts-9306d256 binary_relations-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-update-test-forgotten)
     binary_relations object_000_object_1 attribute_001_irreflexive)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-update-test-restored)
     binary_relations object_000_object_1 attribute_001_irreflexive)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-binary_relations-update-test-restored))
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
