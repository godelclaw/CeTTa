!(import! &self ./mizar_waybel_0_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_waybel_0-state)
              (wm-fca-mizar_waybel_0-state))))
     (size-atom $observations))
   4576)
