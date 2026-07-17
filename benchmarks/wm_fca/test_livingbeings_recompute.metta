!(import! &self ./livingbeings_context.metta)

(= (wm-fca-livingbeings-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-livingbeings-state) (WMFCAScopeStamp livingbeings-cell-000-000)))
(= (wm-fca-livingbeings-recompute-restored)
   (wm-fca-remember
     (wm-fca-livingbeings-recompute-forgotten)
     (WMFCAObservation
       livingbeings object_000_leech attribute_000_needs_water_to_live WMTrue
       livingbeings-cell-000-000 fcatools-contexts-9306d256 livingbeings-published-matrix)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-livingbeings-recompute-restored))
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
