!(import! &self ./mizar_yellow_2_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_yellow_2-state)))
     (size-atom $observations))
   350)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-state) mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-state) mizar_yellow_2 object_000_theorem_6 attribute_000_function)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-state) another-context
     object_000_theorem_6 attribute_000_function)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_2-state)
            mizar_yellow_2 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_003_image)) (attribute_000_function attribute_003_image))
       (and
         (== (wm-fca-index-closure $index (attribute_000_function)) (attribute_000_function))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_003_image) (attribute_000_function)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_function) (attribute_001_ids))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_yellow_2-state) mizar_yellow_2 object_000_theorem_6 attribute_000_function)
   ((WMFCAObservation
      mizar_yellow_2 object_000_theorem_6 attribute_000_function WMFalse
      mizar_yellow_2-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-2-extraction)))
