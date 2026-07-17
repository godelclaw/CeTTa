!(import! &self ./mizar_lattices_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_lattices-state) (WMFCAScopeStamp mizar_lattices-cell-000-001)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_lattices object_000_definition_1 attribute_001_binop WMTrue
                mizar_lattices-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-lattices-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_lattices
                    object_000_definition_1 attribute_001_binop))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_lattices
                      object_000_definition_1 attribute_001_binop))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       1799)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       1800)
                   (== $restored-status WMTrue)))))))))
   True)
