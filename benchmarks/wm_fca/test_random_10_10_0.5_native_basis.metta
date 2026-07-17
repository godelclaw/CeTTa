!(import! &self ./random_10_10_0.5_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_10_10_0.5-state)
            random_10_10_0.5 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 68 22))
       (and
         (== (size-atom $basis) 22)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-random_10_10_0.5-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
