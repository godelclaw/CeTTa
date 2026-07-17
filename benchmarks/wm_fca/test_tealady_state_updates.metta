!(import! &self ./tealady_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-state) tealady object_000_evelyn attribute_000_attribute_1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-state) tealady object_000_evelyn attribute_006_attribute_7)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-tealady-state) tealady object_000_evelyn attribute_006_attribute_7)
   ((WMFCAObservation
      tealady object_000_evelyn attribute_006_attribute_7 WMFalse
      tealady-cell-000-006 fcatools-contexts-9306d256 tealady-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-state) another-context
     object_000_evelyn attribute_006_attribute_7)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-tealady-state)
              (wm-fca-tealady-state))))
     (size-atom $observations))
   252)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-tealady-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-tealady-state) (WMFCAScopeStamp tealady-cell-000-000)))
(= (wm-fca-tealady-update-test-restored)
   (wm-fca-remember
     (wm-fca-tealady-update-test-forgotten)
     (WMFCAObservation
       tealady object_000_evelyn attribute_000_attribute_1 WMTrue
       tealady-cell-000-000 fcatools-contexts-9306d256 tealady-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-update-test-forgotten)
     tealady object_000_evelyn attribute_000_attribute_1)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-update-test-restored)
     tealady object_000_evelyn attribute_000_attribute_1)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-tealady-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-tealady-state)
              tealady WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                tealady WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
