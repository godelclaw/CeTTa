!(import! &self ./random_100_30_0.1_context.metta)

!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_30_0.1-state)
            random_100_30_0.1 WMFCAExactStatusGate))
     (wm-fca-index-column-count $index))
   30)
