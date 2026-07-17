!(import! &self ./animals_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-animals-state)
            animals WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 35))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 35 66))
           (and
             (and
               (== (size-atom $concepts) 35)
               (wm-fca-same-set?
                 $concepts (wm-fca-animals-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 66)
               (wm-fca-same-set?
                 $covers (wm-fca-animals-oracle-covers))))))))
   True)
