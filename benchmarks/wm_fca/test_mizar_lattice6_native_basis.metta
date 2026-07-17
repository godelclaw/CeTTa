!(import! &self ./mizar_lattice6_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice6-state)
            mizar_lattice6 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 71 35))
       (and
         (== (size-atom $basis) 35)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-mizar_lattice6-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
