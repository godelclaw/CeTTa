!(import! &self ./mizar_lattices_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-state) mizar_lattices object_000_definition_1 attribute_001_binop)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-state) mizar_lattices object_000_definition_1 attribute_000_b_lattice)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattices-state) mizar_lattices object_000_definition_1 attribute_000_b_lattice)
   ((WMFCAObservation
      mizar_lattices object_000_definition_1 attribute_000_b_lattice WMFalse
      mizar_lattices-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattices-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-state) another-context
     object_000_definition_1 attribute_000_b_lattice)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattices-state)
              (wm-fca-mizar_lattices-state))))
     (size-atom $observations))
   1800)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_lattices-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_lattices-state) (WMFCAScopeStamp mizar_lattices-cell-000-001)))
(= (wm-fca-mizar_lattices-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_lattices-update-test-forgotten)
     (WMFCAObservation
       mizar_lattices object_000_definition_1 attribute_001_binop WMTrue
       mizar_lattices-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-lattices-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-update-test-forgotten)
     mizar_lattices object_000_definition_1 attribute_001_binop)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-update-test-restored)
     mizar_lattices object_000_definition_1 attribute_001_binop)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_lattices-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattices-state)
              mizar_lattices WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_lattices WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
