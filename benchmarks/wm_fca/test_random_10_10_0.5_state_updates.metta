!(import! &self ./random_10_10_0.5_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.5-state) random_10_10_0.5 object_000_g_0 attribute_001_m_1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.5-state) random_10_10_0.5 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_10_10_0.5-state) random_10_10_0.5 object_000_g_0 attribute_000_m_0)
   ((WMFCAObservation
      random_10_10_0.5 object_000_g_0 attribute_000_m_0 WMFalse
      random_10_10_0.5-cell-000-000 fcapy-controlled-random-509f45a3 random_10_10_0.5-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.5-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-random_10_10_0.5-state)
              (wm-fca-random_10_10_0.5-state))))
     (size-atom $observations))
   100)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-random_10_10_0.5-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-random_10_10_0.5-state) (WMFCAScopeStamp random_10_10_0.5-cell-000-001)))
(= (wm-fca-random_10_10_0.5-update-test-restored)
   (wm-fca-remember
     (wm-fca-random_10_10_0.5-update-test-forgotten)
     (WMFCAObservation
       random_10_10_0.5 object_000_g_0 attribute_001_m_1 WMTrue
       random_10_10_0.5-cell-000-001 fcapy-controlled-random-509f45a3 random_10_10_0.5-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.5-update-test-forgotten)
     random_10_10_0.5 object_000_g_0 attribute_001_m_1)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.5-update-test-restored)
     random_10_10_0.5 object_000_g_0 attribute_001_m_1)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-random_10_10_0.5-update-test-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-random_10_10_0.5-state)
              random_10_10_0.5 WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                random_10_10_0.5 WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
