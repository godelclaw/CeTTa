!(import! &self ./random_100_30_0.1_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_100_30_0.1-state))
   3000)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_30_0.1-state) random_100_30_0.1 object_000_g_0 attribute_002_m_2)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_30_0.1-state) random_100_30_0.1 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_30_0.1-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
