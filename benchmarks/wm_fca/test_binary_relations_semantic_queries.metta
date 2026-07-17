!(import! &self ./binary_relations_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this published matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-binary_relations-state)))
     (size-atom $observations))
   126)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-state) binary_relations object_000_object_1 attribute_001_irreflexive)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-state) binary_relations object_000_object_1 attribute_000_reflexive)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-state) another-context
     object_000_object_1 attribute_000_reflexive)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-binary_relations-state)
            binary_relations WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_003_asymmetric)) (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric))
       (and
         (== (wm-fca-index-closure $index (attribute_000_reflexive)) (attribute_000_reflexive))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_003_asymmetric) (attribute_001_irreflexive attribute_004_antisymmetric)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_reflexive) (attribute_001_irreflexive))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-binary_relations-state) binary_relations object_000_object_1 attribute_000_reflexive)
   ((WMFCAObservation
      binary_relations object_000_object_1 attribute_000_reflexive WMFalse
      binary_relations-cell-000-000 fcatools-contexts-9306d256 binary_relations-published-matrix)))
