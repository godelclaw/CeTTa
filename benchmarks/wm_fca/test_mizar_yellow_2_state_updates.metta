!(import! &self ./mizar_yellow_2_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-state) mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-state) mizar_yellow_2 object_000_theorem_6 attribute_000_function)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_yellow_2-state) mizar_yellow_2 object_000_theorem_6 attribute_000_function)
   ((WMFCAObservation
      mizar_yellow_2 object_000_theorem_6 attribute_000_function WMFalse
      mizar_yellow_2-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-2-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-state) another-context
     object_000_theorem_6 attribute_000_function)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_yellow_2-state)
              (wm-fca-mizar_yellow_2-state))))
     (size-atom $observations))
   350)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_yellow_2-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_yellow_2-state) (WMFCAScopeStamp mizar_yellow_2-cell-000-005)))
(= (wm-fca-mizar_yellow_2-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_yellow_2-update-test-forgotten)
     (WMFCAObservation
       mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr WMTrue
       mizar_yellow_2-cell-000-005 mettapedia-mizar-family-f93a93f7 mizar-yellow-2-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-update-test-forgotten)
     mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-update-test-restored)
     mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_yellow_2-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_2-state)
              mizar_yellow_2 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_yellow_2 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
