!(import! &self ./animals_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-animals-state)
            animals WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 64 29))
       (and
         (== (size-atom $basis) 29)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-animals-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
