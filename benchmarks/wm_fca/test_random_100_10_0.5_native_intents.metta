!(import! &self ./random_100_10_0.5_context.metta)

; This scale-ladder gate isolates native Ganter enumeration from the more
; expensive implication-basis and cover calculations in the full exact test.
; The independent oracle count is also the fail-loud enumeration cap.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_10_0.5-state)
            random_100_10_0.5 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 491))
       (and
         (== (size-atom $intents) 491)
         (wm-fca-same-set?
           $intents (wm-fca-random_100_10_0.5-oracle-intents)))))
   True)
