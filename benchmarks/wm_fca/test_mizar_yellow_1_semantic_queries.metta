!(import! &self ./mizar_yellow_1_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_yellow_1-state)))
     (size-atom $observations))
   306)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-state) mizar_yellow_1 object_000_definition_1 attribute_001_inclposet)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-state) mizar_yellow_1 object_000_definition_1 attribute_000_booleposet)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-state) another-context
     object_000_definition_1 attribute_000_booleposet)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_1-state)
            mizar_yellow_1 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_002_monmaps)) (attribute_002_monmaps attribute_003_relstr attribute_005_subrelstr))
       (and
         (== (wm-fca-index-closure $index (attribute_000_booleposet)) (attribute_000_booleposet))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_002_monmaps) (attribute_003_relstr attribute_005_subrelstr)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_booleposet) (attribute_001_inclposet))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_yellow_1-state) mizar_yellow_1 object_000_definition_1 attribute_000_booleposet)
   ((WMFCAObservation
      mizar_yellow_1 object_000_definition_1 attribute_000_booleposet WMFalse
      mizar_yellow_1-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-1-extraction)))
