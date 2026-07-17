!(import! &self ./random_30_30_0.9_context.metta)

!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_30_30_0.9-state)
            random_30_30_0.9 WMFCAExactStatusGate))
     (wm-fca-index-column-count $index))
   30)
