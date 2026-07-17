!(import! &self ./random_100_30_0.9_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_100_30_0.9-state))
   3000)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_30_0.9-state) random_100_30_0.9 object_000_g_0 attribute_001_m_1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_30_0.9-state) random_100_30_0.9 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_30_0.9-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
