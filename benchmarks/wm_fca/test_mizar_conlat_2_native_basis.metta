!(import! &self ./mizar_conlat_2_context.metta)

; This scale-ladder gate isolates native Duquenne-Guigues basis construction.
; Independent oracle counts bound both logical-closure traversal and output.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_conlat_2-state)
            mizar_conlat_2 WMFCAExactStatusGate))
     (let $basis
          (eval
            (wm-fca-index-canonical-basis-native
              $index 57 25))
       (and
         (== (size-atom $basis) 25)
         (and
           (wm-fca-same-set?
             $basis (wm-fca-mizar_conlat_2-oracle-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
