!(import! &self ./random_10_10_0.9_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this FCApy controlled random matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-random_10_10_0.9-state)))
     (size-atom $observations))
   100)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.9-state) random_10_10_0.9 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.9-state) random_10_10_0.9 object_002_g_2 attribute_006_m_6)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.9-state) another-context
     object_002_g_2 attribute_006_m_6)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_10_10_0.9-state)
            random_10_10_0.9 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index ()) (attribute_004_m_4 attribute_009_m_9))
       (and
         (== (wm-fca-index-closure $index (attribute_004_m_4 attribute_009_m_9)) (attribute_004_m_4 attribute_009_m_9))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication () (attribute_004_m_4 attribute_009_m_9)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_001_m_1))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_10_10_0.9-state) random_10_10_0.9 object_002_g_2 attribute_006_m_6)
   ((WMFCAObservation
      random_10_10_0.9 object_002_g_2 attribute_006_m_6 WMFalse
      random_10_10_0.9-cell-002-006 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)))
