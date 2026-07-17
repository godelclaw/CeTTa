!(import! &self ./mizar_conlat_1_context.metta)

; This scale-ladder gate isolates native Ganter enumeration from the more
; expensive implication-basis and cover calculations in the full exact test.
; The independent oracle count is also the fail-loud enumeration cap.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_conlat_1-state)
            mizar_conlat_1 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 256))
       (and
         (== (size-atom $intents) 256)
         (wm-fca-same-set?
           $intents (wm-fca-mizar_conlat_1-oracle-intents)))))
   True)
