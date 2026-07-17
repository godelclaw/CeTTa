!(import! &self ./random_30_10_0.5_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-state) random_30_10_0.5 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-state) random_30_10_0.5 object_000_g_0 attribute_002_m_2)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_30_10_0.5-state) random_30_10_0.5 object_000_g_0 attribute_002_m_2)
   ((WMFCAObservation
      random_30_10_0.5 object_000_g_0 attribute_002_m_2 WMFalse
      random_30_10_0.5-cell-000-002 fcapy-controlled-random-509f45a3 random_30_10_0.5-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-state) another-context
     object_000_g_0 attribute_002_m_2)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-random_30_10_0.5-state)
              (wm-fca-random_30_10_0.5-state))))
     (size-atom $observations))
   300)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-random_30_10_0.5-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-random_30_10_0.5-state) (WMFCAScopeStamp random_30_10_0.5-cell-000-000)))
(= (wm-fca-random_30_10_0.5-update-test-restored)
   (wm-fca-remember
     (wm-fca-random_30_10_0.5-update-test-forgotten)
     (WMFCAObservation
       random_30_10_0.5 object_000_g_0 attribute_000_m_0 WMTrue
       random_30_10_0.5-cell-000-000 fcapy-controlled-random-509f45a3 random_30_10_0.5-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-update-test-forgotten)
     random_30_10_0.5 object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-update-test-restored)
     random_30_10_0.5 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-random_30_10_0.5-update-test-restored))
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
