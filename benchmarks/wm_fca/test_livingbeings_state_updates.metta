!(import! &self ./livingbeings_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-state) livingbeings object_000_leech attribute_000_needs_water_to_live)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-state) livingbeings object_000_leech attribute_002_lives_on_land)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-livingbeings-state) livingbeings object_000_leech attribute_002_lives_on_land)
   ((WMFCAObservation
      livingbeings object_000_leech attribute_002_lives_on_land WMFalse
      livingbeings-cell-000-002 fcatools-contexts-9306d256 livingbeings-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-state) another-context
     object_000_leech attribute_002_lives_on_land)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-livingbeings-state)
              (wm-fca-livingbeings-state))))
     (size-atom $observations))
   72)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-livingbeings-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-livingbeings-state) (WMFCAScopeStamp livingbeings-cell-000-000)))
(= (wm-fca-livingbeings-update-test-restored)
   (wm-fca-remember
     (wm-fca-livingbeings-update-test-forgotten)
     (WMFCAObservation
       livingbeings object_000_leech attribute_000_needs_water_to_live WMTrue
       livingbeings-cell-000-000 fcatools-contexts-9306d256 livingbeings-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-update-test-forgotten)
     livingbeings object_000_leech attribute_000_needs_water_to_live)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-update-test-restored)
     livingbeings object_000_leech attribute_000_needs_water_to_live)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-livingbeings-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-livingbeings-state)
              livingbeings WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                livingbeings WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
