!(import! &self ./mizar_lattice2_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-state) mizar_lattice2 object_000_notation_1 attribute_006_lattstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-state) mizar_lattice2 object_000_notation_1 attribute_000_d0_lattice)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice2-state) mizar_lattice2 object_000_notation_1 attribute_000_d0_lattice)
   ((WMFCAObservation
      mizar_lattice2 object_000_notation_1 attribute_000_d0_lattice WMFalse
      mizar_lattice2-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice2-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-state) another-context
     object_000_notation_1 attribute_000_d0_lattice)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice2-state)
              (wm-fca-mizar_lattice2-state))))
     (size-atom $observations))
   405)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_lattice2-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_lattice2-state) (WMFCAScopeStamp mizar_lattice2-cell-000-006)))
(= (wm-fca-mizar_lattice2-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_lattice2-update-test-forgotten)
     (WMFCAObservation
       mizar_lattice2 object_000_notation_1 attribute_006_lattstr WMTrue
       mizar_lattice2-cell-000-006 mettapedia-mizar-family-f93a93f7 mizar-lattice2-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-update-test-forgotten)
     mizar_lattice2 object_000_notation_1 attribute_006_lattstr)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-update-test-restored)
     mizar_lattice2 object_000_notation_1 attribute_006_lattstr)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_lattice2-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattice2-state)
              mizar_lattice2 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_lattice2 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
