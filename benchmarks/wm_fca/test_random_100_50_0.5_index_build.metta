!(import! &self ./random_100_50_0.5_context.metta)

!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_50_0.5-state)
            random_100_50_0.5 WMFCAExactStatusGate))
     (wm-fca-index-column-count $index))
   50)
