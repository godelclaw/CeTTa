!(import! &self ./mizar_lattice3_context.metta)

; This scale-ladder gate isolates native Ganter enumeration from the more
; expensive implication-basis and cover calculations in the full exact test.
; The independent oracle count is also the fail-loud enumeration cap.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice3-state)
            mizar_lattice3 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 48))
       (and
         (== (size-atom $intents) 48)
         (wm-fca-same-set?
           $intents (wm-fca-mizar_lattice3-oracle-intents)))))
   True)
