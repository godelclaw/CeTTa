!(import! &self ./random_30_30_0.5_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_30_30_0.5-state))
   900)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_30_0.5-state) random_30_30_0.5 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_30_0.5-state) random_30_30_0.5 object_000_g_0 attribute_002_m_2)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_30_0.5-state) another-context
     object_000_g_0 attribute_002_m_2)
   WMMissing)
