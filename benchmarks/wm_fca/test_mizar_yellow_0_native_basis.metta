!(import! &self ./mizar_yellow_0_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_0-state)
            mizar_yellow_0 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 64 28))
       (and
         (== (size-atom $basis) 28)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-mizar_yellow_0-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
