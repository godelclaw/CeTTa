!(import! &self ./mizar_conlat_1_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
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
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 256 680))
           (and
             (and
               (== (size-atom $concepts) 256)
               (wm-fca-same-set?
                 $concepts (wm-fca-mizar_conlat_1-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 680)
               (wm-fca-same-set?
                 $covers (wm-fca-mizar_conlat_1-oracle-covers))))))))
   True)
