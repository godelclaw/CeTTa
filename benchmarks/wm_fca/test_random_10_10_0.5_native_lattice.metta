!(import! &self ./random_10_10_0.5_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_10_10_0.5-state)
            random_10_10_0.5 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 46))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 46 102))
           (and
             (and
               (== (size-atom $concepts) 46)
               (wm-fca-same-set?
                 $concepts (wm-fca-random_10_10_0.5-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 102)
               (wm-fca-same-set?
                 $covers (wm-fca-random_10_10_0.5-oracle-covers))))))))
   True)
