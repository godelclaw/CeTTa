!(import! &self ./mizar_waybel_0_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_waybel_0-state)
            mizar_waybel_0 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 111))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 111 254))
           (and
             (and
               (== (size-atom $concepts) 111)
               (wm-fca-same-set?
                 $concepts (wm-fca-mizar_waybel_0-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 254)
               (wm-fca-same-set?
                 $covers (wm-fca-mizar_waybel_0-oracle-covers))))))))
   True)
