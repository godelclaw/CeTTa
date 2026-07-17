!(import! &self ./music_context.metta)

; This scale-ladder gate isolates native Ganter enumeration from the more
; expensive implication-basis and cover calculations in the full exact test.
; The independent oracle count is also the fail-loud enumeration cap.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-music-state)
            music WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 163))
       (and
         (== (size-atom $intents) 163)
         (wm-fca-same-set?
           $intents (wm-fca-music-oracle-intents)))))
   True)
