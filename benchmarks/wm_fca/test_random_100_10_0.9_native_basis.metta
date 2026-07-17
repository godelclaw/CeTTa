!(import! &self ./random_100_10_0.9_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_10_0.9-state)
            random_100_10_0.9 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 1024 0))
       (and
         (== (size-atom $basis) 0)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-random_100_10_0.9-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
