!(import! &self ./mizar_lattice3_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice3-state)
            mizar_lattice3 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 48))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 48 98))
           (and
             (and
               (== (size-atom $concepts) 48)
               (wm-fca-same-set?
                 $concepts (wm-fca-mizar_lattice3-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 98)
               (wm-fca-same-set?
                 $covers (wm-fca-mizar_lattice3-oracle-covers))))))))
   True)
