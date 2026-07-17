!(import! &self ./mizar_lattices_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattices-state)))
     (size-atom $observations))
   1800)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-state) mizar_lattices object_000_definition_1 attribute_001_binop)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-state) mizar_lattices object_000_definition_1 attribute_000_b_lattice)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-state) another-context
     object_000_definition_1 attribute_000_b_lattice)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattices-state)
            mizar_lattices WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_011_lattice_like)) (attribute_009_lattstr attribute_011_lattice_like))
       (and
         (== (wm-fca-index-closure $index (attribute_000_b_lattice)) (attribute_000_b_lattice))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_011_lattice_like) (attribute_009_lattstr)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_b_lattice) (attribute_001_binop))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattices-state) mizar_lattices object_000_definition_1 attribute_000_b_lattice)
   ((WMFCAObservation
      mizar_lattices object_000_definition_1 attribute_000_b_lattice WMFalse
      mizar_lattices-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattices-extraction)))
