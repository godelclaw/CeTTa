!(import! &self ./mizar_conlat_1_context.metta)

; Index construction has its own scale gate, independent of enumeration.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_conlat_1-state)
            mizar_conlat_1 WMFCAExactStatusGate))
     (let $columns (eval (wm-fca-index-columns $index))
       (size-atom $columns)))
   32)
