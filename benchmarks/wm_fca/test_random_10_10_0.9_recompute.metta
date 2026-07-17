!(import! &self ./random_10_10_0.9_context.metta)

(= (wm-fca-random_10_10_0.9-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-random_10_10_0.9-state) (WMFCAScopeStamp random_10_10_0.9-cell-000-000)))
(= (wm-fca-random_10_10_0.9-recompute-restored)
   (wm-fca-remember
     (wm-fca-random_10_10_0.9-recompute-forgotten)
     (WMFCAObservation
       random_10_10_0.9 object_000_g_0 attribute_000_m_0 WMTrue
       random_10_10_0.9-cell-000-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-random_10_10_0.9-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-random_10_10_0.9-state)
              random_10_10_0.9 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                random_10_10_0.9 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
