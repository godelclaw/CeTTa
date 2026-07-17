!(import! &self ./mizar_lattice6_context.metta)

(= (wm-fca-mizar_lattice6-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_lattice6-state) (WMFCAScopeStamp mizar_lattice6-cell-000-001)))
(= (wm-fca-mizar_lattice6-recompute-restored)
   (wm-fca-remember
     (wm-fca-mizar_lattice6-recompute-forgotten)
     (WMFCAObservation
       mizar_lattice6 object_000_registration_1 attribute_001_lattposet WMTrue
       mizar_lattice6-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-lattice6-extraction)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_lattice6-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattice6-state)
              mizar_lattice6 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_lattice6 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
