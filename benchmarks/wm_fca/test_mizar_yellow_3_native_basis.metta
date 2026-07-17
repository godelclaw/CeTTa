!(import! &self ./mizar_yellow_3_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_3-state)
            mizar_yellow_3 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 2 1))
       (and
         (== (size-atom $basis) 1)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-mizar_yellow_3-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
