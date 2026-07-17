!(import! &self ./mizar_lattice4_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice4-state)
              (wm-fca-mizar_lattice4-state))))
     (size-atom $observations))
   1060)
