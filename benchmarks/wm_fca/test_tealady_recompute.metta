!(import! &self ./tealady_context.metta)

(= (wm-fca-tealady-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-tealady-state) (WMFCAScopeStamp tealady-cell-000-000)))
(= (wm-fca-tealady-recompute-restored)
   (wm-fca-remember
     (wm-fca-tealady-recompute-forgotten)
     (WMFCAObservation
       tealady object_000_evelyn attribute_000_attribute_1 WMTrue
       tealady-cell-000-000 fcatools-contexts-9306d256 tealady-published-matrix)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-tealady-recompute-restored))
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
