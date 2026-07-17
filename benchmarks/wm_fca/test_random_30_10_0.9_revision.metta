!(import! &self ./random_30_10_0.9_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-random_30_10_0.9-state)
              (wm-fca-random_30_10_0.9-state))))
     (size-atom $observations))
   300)
