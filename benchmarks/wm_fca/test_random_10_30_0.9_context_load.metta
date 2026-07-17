!(import! &self ./random_10_30_0.9_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-random_10_30_0.9-state))
   300)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_30_0.9-state) random_10_30_0.9 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_30_0.9-state) random_10_30_0.9 object_000_g_0 attribute_017_m_17)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_10_30_0.9-state) another-context
     object_000_g_0 attribute_017_m_17)
   WMMissing)
