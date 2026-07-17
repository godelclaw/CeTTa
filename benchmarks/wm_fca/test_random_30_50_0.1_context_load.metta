!(import! &self ./random_30_50_0.1_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_30_50_0.1-state))
   1500)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_50_0.1-state) random_30_50_0.1 object_000_g_0 attribute_015_m_15)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_50_0.1-state) random_30_50_0.1 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_50_0.1-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
