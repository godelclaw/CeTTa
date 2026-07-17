!(import! &self ./animals_context.metta)

(= (wm-fca-animals-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-animals-state) (WMFCAScopeStamp animals-cell-000-000)))
(= (wm-fca-animals-recompute-restored)
   (wm-fca-remember
     (wm-fca-animals-recompute-forgotten)
     (WMFCAObservation
       animals object_000_alligator attribute_000_eggs WMTrue
       animals-cell-000-000 fcatools-contexts-9306d256 animals-published-matrix)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-animals-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-animals-state)
              animals WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                animals WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
