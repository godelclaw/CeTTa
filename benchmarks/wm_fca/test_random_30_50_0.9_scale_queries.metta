!(import! &self ./random_30_50_0.9_context.metta)

; The packed backend compiles the matrix once for this bounded query batch.
; No interpreted recursion or full-lattice enumeration is involved.

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_30_50_0.9-state))
   1500)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_50_0.9-state) random_30_50_0.9 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_50_0.9-state) random_30_50_0.9 object_000_g_0 attribute_025_m_25)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_50_0.9-state) another-context
     object_000_g_0 attribute_025_m_25)
   WMMissing)
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-random_30_50_0.9-state)
     random_30_50_0.9
     WMFCAExactStatusGate
     (wm-fca-random_30_50_0.9-scale-candidates))
   (wm-fca-random_30_50_0.9-scale-results))
