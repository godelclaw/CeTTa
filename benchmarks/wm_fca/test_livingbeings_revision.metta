!(import! &self ./livingbeings_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-livingbeings-state)
              (wm-fca-livingbeings-state))))
     (size-atom $observations))
   72)
