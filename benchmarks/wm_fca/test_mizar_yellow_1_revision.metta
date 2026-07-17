!(import! &self ./mizar_yellow_1_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_yellow_1-state)
              (wm-fca-mizar_yellow_1-state))))
     (size-atom $observations))
   306)
