!(import! &self ./mizar_waybel_0_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_waybel_0-state)
            mizar_waybel_0 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 293 182))
       (and
         (== (size-atom $basis) 182)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-mizar_waybel_0-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
