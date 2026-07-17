!(import! &self ./binary_relations_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-binary_relations-state)
              (wm-fca-binary_relations-state))))
     (size-atom $observations))
   126)
