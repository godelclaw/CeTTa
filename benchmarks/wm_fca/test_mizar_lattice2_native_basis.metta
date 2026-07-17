!(import! &self ./mizar_lattice2_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice2-state)
            mizar_lattice2 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 42 20))
       (and
         (== (size-atom $basis) 20)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-mizar_lattice2-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
