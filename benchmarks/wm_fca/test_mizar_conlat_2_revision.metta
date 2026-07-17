!(import! &self ./mizar_conlat_2_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_conlat_2-state)
              (wm-fca-mizar_conlat_2-state))))
     (size-atom $observations))
   243)
