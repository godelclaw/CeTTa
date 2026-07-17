!(import! &self ./random_10_10_0.5_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this FCApy controlled random matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-random_10_10_0.5-state)))
     (size-atom $observations))
   100)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.5-state) random_10_10_0.5 object_000_g_0 attribute_001_m_1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.5-state) random_10_10_0.5 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_10_0.5-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_10_10_0.5-state)
            random_10_10_0.5 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_000_m_0)) (attribute_000_m_0 attribute_006_m_6))
       (and
         (== (wm-fca-index-closure $index (attribute_001_m_1)) (attribute_001_m_1))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_006_m_6)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_001_m_1))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_10_10_0.5-state) random_10_10_0.5 object_000_g_0 attribute_000_m_0)
   ((WMFCAObservation
      random_10_10_0.5 object_000_g_0 attribute_000_m_0 WMFalse
      random_10_10_0.5-cell-000-000 fcapy-controlled-random-509f45a3 random_10_10_0.5-generated-matrix)))
