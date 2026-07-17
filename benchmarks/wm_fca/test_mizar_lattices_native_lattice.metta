!(import! &self ./mizar_lattices_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattices-state)
            mizar_lattices WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 81))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 81 166))
           (and
             (and
               (== (size-atom $concepts) 81)
               (wm-fca-same-set?
                 $concepts (wm-fca-mizar_lattices-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 166)
               (wm-fca-same-set?
                 $covers (wm-fca-mizar_lattices-oracle-covers))))))))
   True)
