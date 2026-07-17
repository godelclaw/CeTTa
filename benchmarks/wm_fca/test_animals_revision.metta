!(import! &self ./animals_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-animals-state)
              (wm-fca-animals-state))))
     (size-atom $observations))
   385)
