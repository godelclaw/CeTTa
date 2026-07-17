!(import! &self ./random_100_50_0.5_context.metta)

; The packed backend compiles the matrix once for this bounded query batch.
; No interpreted recursion or full-lattice enumeration is involved.

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_100_50_0.5-state))
   5000)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_50_0.5-state) random_100_50_0.5 object_000_g_0 attribute_001_m_1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_50_0.5-state) random_100_50_0.5 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_50_0.5-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-random_100_50_0.5-state)
     random_100_50_0.5
     WMFCAExactStatusGate
     (wm-fca-random_100_50_0.5-scale-candidates))
   (wm-fca-random_100_50_0.5-scale-results))
