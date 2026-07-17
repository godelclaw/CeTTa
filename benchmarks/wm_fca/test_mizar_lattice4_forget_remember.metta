!(import! &self ./mizar_lattice4_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_lattice4-state) (WMFCAScopeStamp mizar_lattice4-cell-000-009)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_lattice4 object_000_theorem_3 attribute_009_l1 WMTrue
                mizar_lattice4-cell-000-009 mettapedia-mizar-family-f93a93f7 mizar-lattice4-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_lattice4
                    object_000_theorem_3 attribute_009_l1))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_lattice4
                      object_000_theorem_3 attribute_009_l1))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       1059)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       1060)
                   (== $restored-status WMTrue)))))))))
   True)
