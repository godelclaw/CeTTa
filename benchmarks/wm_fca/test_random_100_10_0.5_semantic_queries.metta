!(import! &self ./random_100_10_0.5_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this FCApy controlled random matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-random_100_10_0.5-state)))
     (size-atom $observations))
   1000)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.5-state) random_100_10_0.5 object_000_g_0 attribute_003_m_3)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.5-state) random_100_10_0.5 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.5-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_10_0.5-state)
            random_100_10_0.5 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_001_m_1 attribute_005_m_5 attribute_009_m_9)) (attribute_000_m_0 attribute_001_m_1 attribute_005_m_5 attribute_007_m_7 attribute_009_m_9))
       (and
         (== (wm-fca-index-closure $index (attribute_000_m_0)) (attribute_000_m_0))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_001_m_1 attribute_005_m_5 attribute_009_m_9) (attribute_000_m_0 attribute_007_m_7)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_001_m_1))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_100_10_0.5-state) random_100_10_0.5 object_000_g_0 attribute_000_m_0)
   ((WMFCAObservation
      random_100_10_0.5 object_000_g_0 attribute_000_m_0 WMFalse
      random_100_10_0.5-cell-000-000 fcapy-controlled-random-509f45a3 random_100_10_0.5-generated-matrix)))
