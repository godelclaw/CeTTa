!(import! &self ./random_100_10_0.1_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this FCApy controlled random matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-random_100_10_0.1-state)))
     (size-atom $observations))
   1000)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.1-state) random_100_10_0.1 object_000_g_0 attribute_003_m_3)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.1-state) random_100_10_0.1 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.1-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_10_0.1-state)
            random_100_10_0.1 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_000_m_0 attribute_002_m_2)) (attribute_000_m_0 attribute_002_m_2 attribute_006_m_6))
       (and
         (== (wm-fca-index-closure $index (attribute_000_m_0)) (attribute_000_m_0))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0 attribute_002_m_2) (attribute_006_m_6)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_001_m_1))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_100_10_0.1-state) random_100_10_0.1 object_000_g_0 attribute_000_m_0)
   ((WMFCAObservation
      random_100_10_0.1 object_000_g_0 attribute_000_m_0 WMFalse
      random_100_10_0.1-cell-000-000 fcapy-controlled-random-509f45a3 random_100_10_0.1-generated-matrix)))
