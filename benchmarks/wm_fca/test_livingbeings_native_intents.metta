!(import! &self ./livingbeings_context.metta)

; This scale-ladder gate isolates native Ganter enumeration from the more
; expensive implication-basis and cover calculations in the full exact test.
; The independent oracle count is also the fail-loud enumeration cap.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-livingbeings-state)
            livingbeings WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 19))
       (and
         (== (size-atom $intents) 19)
         (wm-fca-same-set?
           $intents (wm-fca-livingbeings-oracle-intents)))))
   True)
