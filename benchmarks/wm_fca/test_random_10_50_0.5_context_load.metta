!(import! &self ./random_10_50_0.5_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_10_50_0.5-state))
   500)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_50_0.5-state) random_10_50_0.5 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_50_0.5-state) random_10_50_0.5 object_000_g_0 attribute_001_m_1)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_50_0.5-state) another-context
     object_000_g_0 attribute_001_m_1)
   WMMissing)
