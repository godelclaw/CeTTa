!(import! &self ./tealady_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-tealady-state)
            tealady WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 88 23))
       (and
         (== (size-atom $basis) 23)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-tealady-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
