!(import! &self ./random_10_10_0.9_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.9-state) random_10_10_0.9 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.9-state) random_10_10_0.9 object_002_g_2 attribute_006_m_6)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_10_10_0.9-state) random_10_10_0.9 object_002_g_2 attribute_006_m_6)
   ((WMFCAObservation
      random_10_10_0.9 object_002_g_2 attribute_006_m_6 WMFalse
      random_10_10_0.9-cell-002-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.9-state) another-context
     object_002_g_2 attribute_006_m_6)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-random_10_10_0.9-state)
              (wm-fca-random_10_10_0.9-state))))
     (size-atom $observations))
   100)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-random_10_10_0.9-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-random_10_10_0.9-state) (WMFCAScopeStamp random_10_10_0.9-cell-000-000)))
(= (wm-fca-random_10_10_0.9-update-test-restored)
   (wm-fca-remember
     (wm-fca-random_10_10_0.9-update-test-forgotten)
     (WMFCAObservation
       random_10_10_0.9 object_000_g_0 attribute_000_m_0 WMTrue
       random_10_10_0.9-cell-000-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.9-update-test-forgotten)
     random_10_10_0.9 object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.9-update-test-restored)
     random_10_10_0.9 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-random_10_10_0.9-update-test-restored))
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
