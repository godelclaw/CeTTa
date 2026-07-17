!(import! &self ./random_30_10_0.5_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-random_30_10_0.5-state)
              (wm-fca-random_30_10_0.5-state))))
     (size-atom $observations))
   300)
