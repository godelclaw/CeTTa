!(import! &self ./mizar_lattice3_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice3-state)
            mizar_lattice3 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 94 46))
       (and
         (== (size-atom $basis) 46)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-mizar_lattice3-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
