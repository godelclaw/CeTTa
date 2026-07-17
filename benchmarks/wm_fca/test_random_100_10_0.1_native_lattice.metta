!(import! &self ./random_100_10_0.1_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_10_0.1-state)
            random_100_10_0.1 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 39))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 39 83))
           (and
             (and
               (== (size-atom $concepts) 39)
               (wm-fca-same-set?
                 $concepts (wm-fca-random_100_10_0.1-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 83)
               (wm-fca-same-set?
                 $covers (wm-fca-random_100_10_0.1-oracle-covers))))))))
   True)
