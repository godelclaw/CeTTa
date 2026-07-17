!(import! &self ./mizar_lattice4_context.metta)

(= (wm-fca-mizar_lattice4-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_lattice4-state) (WMFCAScopeStamp mizar_lattice4-cell-000-009)))
(= (wm-fca-mizar_lattice4-recompute-restored)
   (wm-fca-remember
     (wm-fca-mizar_lattice4-recompute-forgotten)
     (WMFCAObservation
       mizar_lattice4 object_000_theorem_3 attribute_009_l1 WMTrue
       mizar_lattice4-cell-000-009 mettapedia-mizar-family-f93a93f7 mizar-lattice4-extraction)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_lattice4-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattice4-state)
              mizar_lattice4 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_lattice4 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
