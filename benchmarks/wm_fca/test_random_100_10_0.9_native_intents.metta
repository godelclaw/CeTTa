!(import! &self ./random_100_10_0.9_context.metta)

; This scale-ladder gate isolates native Ganter enumeration from the more
; expensive implication-basis and cover calculations in the full exact test.
; The independent oracle count is also the fail-loud enumeration cap.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_10_0.9-state)
            random_100_10_0.9 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 1024))
       (and
         (== (size-atom $intents) 1024)
         (wm-fca-same-set?
           $intents (wm-fca-random_100_10_0.9-oracle-intents)))))
   True)
