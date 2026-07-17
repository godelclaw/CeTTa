!(import! &self ./mizar_lattice2_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_lattice2-state) (WMFCAScopeStamp mizar_lattice2-cell-000-006)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_lattice2 object_000_notation_1 attribute_006_lattstr WMTrue
                mizar_lattice2-cell-000-006 mettapedia-mizar-family-f93a93f7 mizar-lattice2-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_lattice2
                    object_000_notation_1 attribute_006_lattstr))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_lattice2
                      object_000_notation_1 attribute_006_lattstr))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       404)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       405)
                   (== $restored-status WMTrue)))))))))
   True)
