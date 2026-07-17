!(import! &self ./mizar_lattice6_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattice6-state)))
     (size-atom $observations))
   462)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-state) mizar_lattice6 object_000_registration_1 attribute_001_lattposet)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-state) mizar_lattice6 object_000_registration_1 attribute_000_jirrs)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-state) another-context
     object_000_registration_1 attribute_000_jirrs)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice6-state)
            mizar_lattice6 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_002_mirrs)) (attribute_002_mirrs attribute_003_subset))
       (and
         (== (wm-fca-index-closure $index (attribute_000_jirrs)) (attribute_000_jirrs))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_002_mirrs) (attribute_003_subset)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_jirrs) (attribute_001_lattposet))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice6-state) mizar_lattice6 object_000_registration_1 attribute_000_jirrs)
   ((WMFCAObservation
      mizar_lattice6 object_000_registration_1 attribute_000_jirrs WMFalse
      mizar_lattice6-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice6-extraction)))
