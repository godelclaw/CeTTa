!(import! &self ./random_100_10_0.9_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this FCApy controlled random matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-random_100_10_0.9-state)))
     (size-atom $observations))
   1000)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.9-state) random_100_10_0.9 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.9-state) random_100_10_0.9 object_001_g_1 attribute_007_m_7)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.9-state) another-context
     object_001_g_1 attribute_007_m_7)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_10_0.9-state)
            random_100_10_0.9 WMFCAExactStatusGate))
     (and
       True
       (and
         (== (wm-fca-index-closure $index (attribute_000_m_0)) (attribute_000_m_0))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_000_m_0)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_001_m_1))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_100_10_0.9-state) random_100_10_0.9 object_001_g_1 attribute_007_m_7)
   ((WMFCAObservation
      random_100_10_0.9 object_001_g_1 attribute_007_m_7 WMFalse
      random_100_10_0.9-cell-001-007 fcapy-controlled-random-509f45a3 random_100_10_0.9-generated-matrix)))
