!(import! &self ./mizar_waybel_1_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_waybel_1-state)))
     (size-atom $observations))
   1904)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-state) mizar_waybel_1 object_000_definition_1 attribute_002_function)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-state) mizar_waybel_1 object_000_definition_1 attribute_000_boolean)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-state) another-context
     object_000_definition_1 attribute_000_boolean)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_waybel_1-state)
            mizar_waybel_1 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_001_connection)) (attribute_001_connection attribute_002_function))
       (and
         (== (wm-fca-index-closure $index (attribute_000_boolean)) (attribute_000_boolean))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_001_connection) (attribute_002_function)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_boolean) (attribute_001_connection))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_waybel_1-state) mizar_waybel_1 object_000_definition_1 attribute_000_boolean)
   ((WMFCAObservation
      mizar_waybel_1 object_000_definition_1 attribute_000_boolean WMFalse
      mizar_waybel_1-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)))
