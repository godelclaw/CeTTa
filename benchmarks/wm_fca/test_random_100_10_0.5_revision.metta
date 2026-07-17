!(import! &self ./random_100_10_0.5_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-random_100_10_0.5-state)
              (wm-fca-random_100_10_0.5-state))))
     (size-atom $observations))
   1000)
