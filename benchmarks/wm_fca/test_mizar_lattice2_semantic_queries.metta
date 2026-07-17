!(import! &self ./mizar_lattice2_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattice2-state)))
     (size-atom $observations))
   405)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-state) mizar_lattice2 object_000_notation_1 attribute_006_lattstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-state) mizar_lattice2 object_000_notation_1 attribute_000_d0_lattice)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-state) another-context
     object_000_notation_1 attribute_000_d0_lattice)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice2-state)
            mizar_lattice2 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_000_d0_lattice)) (attribute_000_d0_lattice attribute_007_lattice))
       (and
         (== (wm-fca-index-closure $index (attribute_001_finjoin)) (attribute_001_finjoin))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_d0_lattice) (attribute_007_lattice)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_d0_lattice) (attribute_001_finjoin))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice2-state) mizar_lattice2 object_000_notation_1 attribute_000_d0_lattice)
   ((WMFCAObservation
      mizar_lattice2 object_000_notation_1 attribute_000_d0_lattice WMFalse
      mizar_lattice2-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice2-extraction)))
