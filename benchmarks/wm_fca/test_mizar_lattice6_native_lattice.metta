!(import! &self ./mizar_lattice6_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice6-state)
            mizar_lattice6 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 36))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 36 74))
           (and
             (and
               (== (size-atom $concepts) 36)
               (wm-fca-same-set?
                 $concepts (wm-fca-mizar_lattice6-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 74)
               (wm-fca-same-set?
                 $covers (wm-fca-mizar_lattice6-oracle-covers))))))))
   True)
