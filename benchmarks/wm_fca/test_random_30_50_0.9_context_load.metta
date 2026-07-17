!(import! &self ./random_30_50_0.9_context.metta)

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
