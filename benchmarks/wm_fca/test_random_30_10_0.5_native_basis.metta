!(import! &self ./random_30_10_0.5_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-random_30_10_0.5-state)
            random_30_10_0.5 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 219 47))
       (and
         (== (size-atom $basis) 47)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-random_30_10_0.5-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
