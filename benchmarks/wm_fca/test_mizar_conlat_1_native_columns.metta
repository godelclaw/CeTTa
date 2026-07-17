!(import! &self ./mizar_conlat_1_context.metta)

; The native evidence index is checked before wrapping it in an audited index.
!(assertEqual
   (let $state (eval (wm-fca-mizar_conlat_1-state))
     (let $objects (eval (wm-fca-state-objects $state))
       (let $attributes (eval (wm-fca-state-attributes $state))
         (let $observations (eval (wm-fca-state-observations $state))
           (let $columns
                (eval
                  (wm-fca-index-columns-atom
                    $objects $attributes $observations
                    mizar_conlat_1 WMFCAExactStatusGate))
             (size-atom $columns))))))
   32)
