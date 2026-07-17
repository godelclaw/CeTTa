!(import! &self ./mizar_lattice4_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice4-state)
            mizar_lattice4 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 62))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 62 136))
           (and
             (and
               (== (size-atom $concepts) 62)
               (wm-fca-same-set?
                 $concepts (wm-fca-mizar_lattice4-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 136)
               (wm-fca-same-set?
                 $covers (wm-fca-mizar_lattice4-oracle-covers))))))))
   True)
