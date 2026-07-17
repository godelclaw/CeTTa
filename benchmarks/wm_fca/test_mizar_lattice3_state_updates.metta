!(import! &self ./mizar_lattice3_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-state) mizar_lattice3 object_000_definition_1 attribute_000_boolelatt)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-state) mizar_lattice3 object_000_definition_1 attribute_002_lattposet)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice3-state) mizar_lattice3 object_000_definition_1 attribute_002_lattposet)
   ((WMFCAObservation
      mizar_lattice3 object_000_definition_1 attribute_002_lattposet WMFalse
      mizar_lattice3-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-lattice3-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-state) another-context
     object_000_definition_1 attribute_002_lattposet)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice3-state)
              (wm-fca-mizar_lattice3-state))))
     (size-atom $observations))
   869)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_lattice3-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_lattice3-state) (WMFCAScopeStamp mizar_lattice3-cell-000-000)))
(= (wm-fca-mizar_lattice3-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_lattice3-update-test-forgotten)
     (WMFCAObservation
       mizar_lattice3 object_000_definition_1 attribute_000_boolelatt WMTrue
       mizar_lattice3-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice3-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-update-test-forgotten)
     mizar_lattice3 object_000_definition_1 attribute_000_boolelatt)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-update-test-restored)
     mizar_lattice3 object_000_definition_1 attribute_000_boolelatt)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_lattice3-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattice3-state)
              mizar_lattice3 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_lattice3 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
