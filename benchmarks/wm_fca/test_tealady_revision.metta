!(import! &self ./tealady_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-tealady-state)
              (wm-fca-tealady-state))))
     (size-atom $observations))
   252)
