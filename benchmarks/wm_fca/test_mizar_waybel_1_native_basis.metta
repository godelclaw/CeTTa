!(import! &self ./mizar_waybel_1_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_waybel_1-state)
            mizar_waybel_1 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 118 66))
       (and
         (== (size-atom $basis) 66)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-mizar_waybel_1-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
