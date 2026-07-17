!(import! &self ./mizar_lattice6_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-state) mizar_lattice6 object_000_registration_1 attribute_001_lattposet)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-state) mizar_lattice6 object_000_registration_1 attribute_000_jirrs)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice6-state) mizar_lattice6 object_000_registration_1 attribute_000_jirrs)
   ((WMFCAObservation
      mizar_lattice6 object_000_registration_1 attribute_000_jirrs WMFalse
      mizar_lattice6-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice6-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-state) another-context
     object_000_registration_1 attribute_000_jirrs)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice6-state)
              (wm-fca-mizar_lattice6-state))))
     (size-atom $observations))
   462)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_lattice6-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_lattice6-state) (WMFCAScopeStamp mizar_lattice6-cell-000-001)))
(= (wm-fca-mizar_lattice6-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_lattice6-update-test-forgotten)
     (WMFCAObservation
       mizar_lattice6 object_000_registration_1 attribute_001_lattposet WMTrue
       mizar_lattice6-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-lattice6-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-update-test-forgotten)
     mizar_lattice6 object_000_registration_1 attribute_001_lattposet)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-update-test-restored)
     mizar_lattice6 object_000_registration_1 attribute_001_lattposet)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_lattice6-update-test-restored))
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
