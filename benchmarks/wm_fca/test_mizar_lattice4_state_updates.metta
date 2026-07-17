!(import! &self ./mizar_lattice4_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-state) mizar_lattice4 object_000_theorem_3 attribute_009_l1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-state) mizar_lattice4 object_000_theorem_3 attribute_000_bl)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice4-state) mizar_lattice4 object_000_theorem_3 attribute_000_bl)
   ((WMFCAObservation
      mizar_lattice4 object_000_theorem_3 attribute_000_bl WMFalse
      mizar_lattice4-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice4-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-state) another-context
     object_000_theorem_3 attribute_000_bl)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice4-state)
              (wm-fca-mizar_lattice4-state))))
     (size-atom $observations))
   1060)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_lattice4-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_lattice4-state) (WMFCAScopeStamp mizar_lattice4-cell-000-009)))
(= (wm-fca-mizar_lattice4-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_lattice4-update-test-forgotten)
     (WMFCAObservation
       mizar_lattice4 object_000_theorem_3 attribute_009_l1 WMTrue
       mizar_lattice4-cell-000-009 mettapedia-mizar-family-f93a93f7 mizar-lattice4-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-update-test-forgotten)
     mizar_lattice4 object_000_theorem_3 attribute_009_l1)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-update-test-restored)
     mizar_lattice4 object_000_theorem_3 attribute_009_l1)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_lattice4-update-test-restored))
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
