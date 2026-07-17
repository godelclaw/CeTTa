!(import! &self ./mizar_conlat_2_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_conlat_2-state)))
     (size-atom $observations))
   243)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-state) mizar_conlat_2 object_000_definition_1 attribute_000_cp)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-state) mizar_conlat_2 object_000_definition_1 attribute_002_conceptstr)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-state) another-context
     object_000_definition_1 attribute_002_conceptstr)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_conlat_2-state)
            mizar_conlat_2 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_005_dualhomomorphism)) (attribute_001_conceptlattice attribute_005_dualhomomorphism))
       (and
         (== (wm-fca-index-closure $index (attribute_000_cp)) (attribute_000_cp))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_005_dualhomomorphism) (attribute_001_conceptlattice)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_cp) (attribute_001_conceptlattice))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_conlat_2-state) mizar_conlat_2 object_000_definition_1 attribute_002_conceptstr)
   ((WMFCAObservation
      mizar_conlat_2 object_000_definition_1 attribute_002_conceptstr WMFalse
      mizar_conlat_2-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-conlat-2-extraction)))
