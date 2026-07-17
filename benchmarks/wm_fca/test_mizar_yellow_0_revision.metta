!(import! &self ./mizar_yellow_0_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_yellow_0-state)
              (wm-fca-mizar_yellow_0-state))))
     (size-atom $observations))
   1176)
