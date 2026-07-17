!(import! &self ./music_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-music-state)
            music WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 182 19))
       (and
         (== (size-atom $basis) 19)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-music-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
