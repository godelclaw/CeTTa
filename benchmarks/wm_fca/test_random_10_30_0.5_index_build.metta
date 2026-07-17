!(import! &self ./random_10_30_0.5_context.metta)

!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_10_30_0.5-state)
            random_10_30_0.5 WMFCAExactStatusGate))
     (wm-fca-index-column-count $index))
   30)
