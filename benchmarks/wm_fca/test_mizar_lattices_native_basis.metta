!(import! &self ./mizar_lattices_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattices-state)
            mizar_lattices WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 281 200))
       (and
         (== (size-atom $basis) 200)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-mizar_lattices-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
