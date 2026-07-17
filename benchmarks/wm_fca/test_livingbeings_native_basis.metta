!(import! &self ./livingbeings_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-livingbeings-state)
            livingbeings WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 29 10))
       (and
         (== (size-atom $basis) 10)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-livingbeings-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
