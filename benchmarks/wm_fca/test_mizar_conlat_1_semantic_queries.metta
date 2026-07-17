!(import! &self ./mizar_conlat_1_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_conlat_1-state)))
     (size-atom $observations))
   2656)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_1-state) mizar_conlat_1 object_000_definition_1 attribute_015_contextstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_1-state) mizar_conlat_1 object_000_definition_1 attribute_000_attribute)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_1-state) another-context
     object_000_definition_1 attribute_000_attribute)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_conlat_1-state)
            mizar_conlat_1 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_001_attributederivation)) (attribute_001_attributederivation attribute_018_formalcontext))
       (and
         (== (wm-fca-index-closure $index (attribute_000_attribute)) (attribute_000_attribute))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_001_attributederivation) (attribute_018_formalcontext)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_attribute) (attribute_001_attributederivation))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_conlat_1-state) mizar_conlat_1 object_000_definition_1 attribute_000_attribute)
   ((WMFCAObservation
      mizar_conlat_1 object_000_definition_1 attribute_000_attribute WMFalse
      mizar_conlat_1-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-conlat-1-extraction)))
