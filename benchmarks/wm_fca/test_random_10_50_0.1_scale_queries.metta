!(import! &self ./random_10_50_0.1_context.metta)

; The packed backend compiles the matrix once for this bounded query batch.
; No interpreted recursion or full-lattice enumeration is involved.

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_10_50_0.1-state))
   500)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_50_0.1-state) random_10_50_0.1 object_000_g_0 attribute_009_m_9)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_50_0.1-state) random_10_50_0.1 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_50_0.1-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-random_10_50_0.1-state)
     random_10_50_0.1
     WMFCAExactStatusGate
     (wm-fca-random_10_50_0.1-scale-candidates))
   (wm-fca-random_10_50_0.1-scale-results))
