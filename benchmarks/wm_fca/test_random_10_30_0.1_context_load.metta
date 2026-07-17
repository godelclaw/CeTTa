!(import! &self ./random_10_30_0.1_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_10_30_0.1-state))
   300)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_30_0.1-state) random_10_30_0.1 object_000_g_0 attribute_005_m_5)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_30_0.1-state) random_10_30_0.1 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_30_0.1-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
