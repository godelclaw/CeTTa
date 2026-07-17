!(import! &self ./random_30_10_0.1_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_30_10_0.1-state)
            random_30_10_0.1 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 60 39))
       (and
         (== (size-atom $basis) 39)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-random_30_10_0.1-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
