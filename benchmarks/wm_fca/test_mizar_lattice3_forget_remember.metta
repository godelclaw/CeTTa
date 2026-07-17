!(import! &self ./mizar_lattice3_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_lattice3-state) (WMFCAScopeStamp mizar_lattice3-cell-000-000)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_lattice3 object_000_definition_1 attribute_000_boolelatt WMTrue
                mizar_lattice3-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice3-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_lattice3
                    object_000_definition_1 attribute_000_boolelatt))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_lattice3
                      object_000_definition_1 attribute_000_boolelatt))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       868)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       869)
                   (== $restored-status WMTrue)))))))))
   True)
