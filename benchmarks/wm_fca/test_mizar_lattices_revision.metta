!(import! &self ./mizar_lattices_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattices-state)
              (wm-fca-mizar_lattices-state))))
     (size-atom $observations))
   1800)
