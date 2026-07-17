!(import! &self ./mizar_waybel_1_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_waybel_1-state)
            mizar_waybel_1 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 52))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 52 106))
           (and
             (and
               (== (size-atom $concepts) 52)
               (wm-fca-same-set?
                 $concepts (wm-fca-mizar_waybel_1-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 106)
               (wm-fca-same-set?
                 $covers (wm-fca-mizar_waybel_1-oracle-covers))))))))
   True)
