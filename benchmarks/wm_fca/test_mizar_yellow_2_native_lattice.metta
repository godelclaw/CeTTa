!(import! &self ./mizar_yellow_2_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_2-state)
            mizar_yellow_2 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 17))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 17 26))
           (and
             (and
               (== (size-atom $concepts) 17)
               (wm-fca-same-set?
                 $concepts (wm-fca-mizar_yellow_2-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 26)
               (wm-fca-same-set?
                 $covers (wm-fca-mizar_yellow_2-oracle-covers))))))))
   True)
