!(import! &self ./bob_ross_context.metta)

!(assertEqual
   (wm-fca-state-observation-count (wm-fca-bob_ross-state))
   27001)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-bob_ross-state) bob_ross object_000_s01e01_a_walk_in_the_woods attribute_007_bushes)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-bob_ross-state) bob_ross object_000_s01e01_a_walk_in_the_woods attribute_000_apple_frame)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-bob_ross-state) another-context
     object_000_s01e01_a_walk_in_the_woods attribute_000_apple_frame)
   WMMissing)
