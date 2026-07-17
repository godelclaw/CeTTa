!(import! &self ./mizar_lattice4_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattice4-state)))
     (size-atom $observations))
   1060)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-state) mizar_lattice4 object_000_theorem_3 attribute_009_l1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-state) mizar_lattice4 object_000_theorem_3 attribute_000_bl)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-state) another-context
     object_000_theorem_3 attribute_000_bl)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice4-state)
            mizar_lattice4 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_009_l1)) (attribute_009_l1 attribute_010_l2))
       (and
         (== (wm-fca-index-closure $index (attribute_000_bl)) (attribute_000_bl))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_009_l1) (attribute_010_l2)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_bl) (attribute_001_closedsubset))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice4-state) mizar_lattice4 object_000_theorem_3 attribute_000_bl)
   ((WMFCAObservation
      mizar_lattice4 object_000_theorem_3 attribute_000_bl WMFalse
      mizar_lattice4-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice4-extraction)))
