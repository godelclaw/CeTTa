!(import! &self ./mizar_lattice6_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice6-state)
              (wm-fca-mizar_lattice6-state))))
     (size-atom $observations))
   462)
