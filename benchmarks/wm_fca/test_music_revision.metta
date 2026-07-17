!(import! &self ./music_context.metta)

; Identical provenance-bearing chunks revise idempotently at scale.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-music-state)
              (wm-fca-music-state))))
     (size-atom $observations))
   341)
