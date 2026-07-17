!(import! &self ./mizar_lattice3_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattice3-state)))
     (size-atom $observations))
   869)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-state) mizar_lattice3 object_000_definition_1 attribute_000_boolelatt)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-state) mizar_lattice3 object_000_definition_1 attribute_002_lattposet)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-state) another-context
     object_000_definition_1 attribute_002_lattposet)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice3-state)
            mizar_lattice3 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_000_boolelatt attribute_001_it)) (attribute_000_boolelatt attribute_001_it attribute_003_lattstr))
       (and
         (== (wm-fca-index-closure $index (attribute_000_boolelatt)) (attribute_000_boolelatt))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_boolelatt attribute_001_it) (attribute_003_lattstr)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_boolelatt) (attribute_001_it))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice3-state) mizar_lattice3 object_000_definition_1 attribute_002_lattposet)
   ((WMFCAObservation
      mizar_lattice3 object_000_definition_1 attribute_002_lattposet WMFalse
      mizar_lattice3-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-lattice3-extraction)))
