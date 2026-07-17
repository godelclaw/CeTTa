!(import! &self ./random_100_30_0.5_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_100_30_0.5-state))
   3000)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_30_0.5-state) random_100_30_0.5 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_30_0.5-state) random_100_30_0.5 object_000_g_0 attribute_006_m_6)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_30_0.5-state) another-context
     object_000_g_0 attribute_006_m_6)
   WMMissing)
