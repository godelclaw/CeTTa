!(import! &self ./random_30_10_0.5_context.metta)

(= (wm-fca-random_30_10_0.5-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-random_30_10_0.5-state) (WMFCAScopeStamp random_30_10_0.5-cell-000-000)))
(= (wm-fca-random_30_10_0.5-recompute-restored)
   (wm-fca-remember
     (wm-fca-random_30_10_0.5-recompute-forgotten)
     (WMFCAObservation
       random_30_10_0.5 object_000_g_0 attribute_000_m_0 WMTrue
       random_30_10_0.5-cell-000-000 fcapy-controlled-random-509f45a3 random_30_10_0.5-generated-matrix)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-random_30_10_0.5-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-random_30_10_0.5-state)
              random_30_10_0.5 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                random_30_10_0.5 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
