!(import! &self ./random_30_10_0.9_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_30_10_0.9-state)
            random_30_10_0.9 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 352))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 352 1336))
           (and
             (and
               (== (size-atom $concepts) 352)
               (wm-fca-same-set?
                 $concepts (wm-fca-random_30_10_0.9-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 1336)
               (wm-fca-same-set?
                 $covers (wm-fca-random_30_10_0.9-oracle-covers))))))))
   True)
