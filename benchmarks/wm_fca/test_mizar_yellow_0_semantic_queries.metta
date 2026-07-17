!(import! &self ./mizar_yellow_0_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_yellow_0-state)))
     (size-atom $observations))
   1176)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-state) mizar_yellow_0 object_000_scheme_1 attribute_001_relstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-state) mizar_yellow_0 object_000_scheme_1 attribute_000_bottom)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-state) another-context
     object_000_scheme_1 attribute_000_bottom)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_0-state)
            mizar_yellow_0 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_000_bottom)) (attribute_000_bottom attribute_001_relstr))
       (and
         (== (wm-fca-index-closure $index (attribute_001_relstr)) (attribute_001_relstr))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_bottom) (attribute_001_relstr)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_bottom) (attribute_002_subrelstr))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_yellow_0-state) mizar_yellow_0 object_000_scheme_1 attribute_000_bottom)
   ((WMFCAObservation
      mizar_yellow_0 object_000_scheme_1 attribute_000_bottom WMFalse
      mizar_yellow_0-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-0-extraction)))
