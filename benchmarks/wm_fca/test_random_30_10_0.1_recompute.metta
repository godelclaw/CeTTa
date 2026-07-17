!(import! &self ./random_30_10_0.1_context.metta)

(= (wm-fca-random_30_10_0.1-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-random_30_10_0.1-state) (WMFCAScopeStamp random_30_10_0.1-cell-000-001)))
(= (wm-fca-random_30_10_0.1-recompute-restored)
   (wm-fca-remember
     (wm-fca-random_30_10_0.1-recompute-forgotten)
     (WMFCAObservation
       random_30_10_0.1 object_000_g_0 attribute_001_m_1 WMTrue
       random_30_10_0.1-cell-000-001 fcapy-controlled-random-509f45a3 random_30_10_0.1-generated-matrix)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-random_30_10_0.1-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-random_30_10_0.1-state)
              random_30_10_0.1 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                random_30_10_0.1 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
