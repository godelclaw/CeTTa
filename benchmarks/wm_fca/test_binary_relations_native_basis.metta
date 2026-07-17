!(import! &self ./binary_relations_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-binary_relations-state)
            binary_relations WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 63 13))
       (and
         (== (size-atom $basis) 13)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-binary_relations-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
