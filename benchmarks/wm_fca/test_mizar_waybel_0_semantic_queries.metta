!(import! &self ./mizar_waybel_0_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_waybel_0-state)))
     (size-atom $observations))
   4576)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_0-state) mizar_waybel_0 object_000_definition_1 attribute_011_relstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_0-state) mizar_waybel_0 object_000_definition_1 attribute_000_chain)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_0-state) another-context
     object_000_definition_1 attribute_000_chain)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_waybel_0-state)
            mizar_waybel_0 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_001_filt)) (attribute_001_filt attribute_006_ids attribute_011_relstr))
       (and
         (== (wm-fca-index-closure $index (attribute_000_chain)) (attribute_000_chain))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_001_filt) (attribute_006_ids attribute_011_relstr)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_chain) (attribute_001_filt))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_waybel_0-state) mizar_waybel_0 object_000_definition_1 attribute_000_chain)
   ((WMFCAObservation
      mizar_waybel_0 object_000_definition_1 attribute_000_chain WMFalse
      mizar_waybel_0-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-0-extraction)))
