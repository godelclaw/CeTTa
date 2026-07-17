!(import! &self ./mizar_yellow_3_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this complete positive-occurrence article context, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_yellow_3-state)))
     (size-atom $observations))
   70)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_3-state) mizar_yellow_3 object_000_registration_1 attribute_000_relstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_3-state) another-context
     object_000_registration_1 attribute_000_relstr)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_3-state)
            mizar_yellow_3 WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index ()) (attribute_000_relstr))
       (and
         (== (wm-fca-index-closure $index (attribute_000_relstr)) (attribute_000_relstr))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication () (attribute_000_relstr)))
           True))))
   True)
