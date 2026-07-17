!(import! &self ./music_context.metta)

; One native intent enumeration feeds typed concepts and exact Hasse covers.
; This isolates lattice parity from basis and state-update checks.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-music-state)
            music WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 163))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $covers
              (eval
                (wm-fca-covers-from-intents-native
                  $intents 163 507))
           (and
             (and
               (== (size-atom $concepts) 163)
               (wm-fca-same-set?
                 $concepts (wm-fca-music-oracle-concepts))
             )
             (and
               (== (size-atom $covers) 507)
               (wm-fca-same-set?
                 $covers (wm-fca-music-oracle-covers))))))))
   True)
