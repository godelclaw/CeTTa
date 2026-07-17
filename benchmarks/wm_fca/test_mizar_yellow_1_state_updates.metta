!(import! &self ./mizar_yellow_1_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-state) mizar_yellow_1 object_000_definition_1 attribute_001_inclposet)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-state) mizar_yellow_1 object_000_definition_1 attribute_000_booleposet)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_yellow_1-state) mizar_yellow_1 object_000_definition_1 attribute_000_booleposet)
   ((WMFCAObservation
      mizar_yellow_1 object_000_definition_1 attribute_000_booleposet WMFalse
      mizar_yellow_1-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-1-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-state) another-context
     object_000_definition_1 attribute_000_booleposet)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_yellow_1-state)
              (wm-fca-mizar_yellow_1-state))))
     (size-atom $observations))
   306)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_yellow_1-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_yellow_1-state) (WMFCAScopeStamp mizar_yellow_1-cell-000-001)))
(= (wm-fca-mizar_yellow_1-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_yellow_1-update-test-forgotten)
     (WMFCAObservation
       mizar_yellow_1 object_000_definition_1 attribute_001_inclposet WMTrue
       mizar_yellow_1-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-yellow-1-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-update-test-forgotten)
     mizar_yellow_1 object_000_definition_1 attribute_001_inclposet)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-update-test-restored)
     mizar_yellow_1 object_000_definition_1 attribute_001_inclposet)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_yellow_1-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_1-state)
              mizar_yellow_1 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_yellow_1 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
