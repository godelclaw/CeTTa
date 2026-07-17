!(import! &self ./tealady_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-tealady-state)
            tealady WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 65))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 65 148))
           (and
             (and
               (== (size-atom $concepts) 65)
               (wm-fca-same-set?
                 $concepts (wm-fca-tealady-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 148)
               (wm-fca-same-set?
                 $covers (wm-fca-tealady-oracle-covers))))))))
   True)
