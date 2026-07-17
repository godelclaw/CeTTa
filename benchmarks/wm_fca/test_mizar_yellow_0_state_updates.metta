!(import! &self ./mizar_yellow_0_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-state) mizar_yellow_0 object_000_scheme_1 attribute_001_relstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-state) mizar_yellow_0 object_000_scheme_1 attribute_000_bottom)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_yellow_0-state) mizar_yellow_0 object_000_scheme_1 attribute_000_bottom)
   ((WMFCAObservation
      mizar_yellow_0 object_000_scheme_1 attribute_000_bottom WMFalse
      mizar_yellow_0-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-0-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-state) another-context
     object_000_scheme_1 attribute_000_bottom)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_yellow_0-state)
              (wm-fca-mizar_yellow_0-state))))
     (size-atom $observations))
   1176)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-mizar_yellow_0-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-mizar_yellow_0-state) (WMFCAScopeStamp mizar_yellow_0-cell-000-001)))
(= (wm-fca-mizar_yellow_0-update-test-restored)
   (wm-fca-remember
     (wm-fca-mizar_yellow_0-update-test-forgotten)
     (WMFCAObservation
       mizar_yellow_0 object_000_scheme_1 attribute_001_relstr WMTrue
       mizar_yellow_0-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-yellow-0-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-update-test-forgotten)
     mizar_yellow_0 object_000_scheme_1 attribute_001_relstr)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-update-test-restored)
     mizar_yellow_0 object_000_scheme_1 attribute_001_relstr)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-mizar_yellow_0-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_0-state)
              mizar_yellow_0 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                mizar_yellow_0 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
