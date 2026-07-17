!(import! &self ./mizar_yellow_0_context.metta)

; This scale-ladder gate isolates native Ganter enumeration from the more
; expensive implication-basis and cover calculations in the full exact test.
; The independent oracle count is also the fail-loud enumeration cap.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_0-state)
            mizar_yellow_0 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 36))
       (and
         (== (size-atom $intents) 36)
         (wm-fca-same-set?
           $intents (wm-fca-mizar_yellow_0-oracle-intents)))))
   True)
