!(import! &self ./mizar_lattice2_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice2-state)
            mizar_lattice2 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 22))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 22 39))
           (and
             (and
               (== (size-atom $concepts) 22)
               (wm-fca-same-set?
                 $concepts (wm-fca-mizar_lattice2-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 39)
               (wm-fca-same-set?
                 $covers (wm-fca-mizar_lattice2-oracle-covers))))))))
   True)
