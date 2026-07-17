!(import! &self ./mizar_lattice6_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_lattice6-state) (WMFCAScopeStamp mizar_lattice6-cell-000-001)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_lattice6 object_000_registration_1 attribute_001_lattposet WMTrue
                mizar_lattice6-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-lattice6-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_lattice6
                    object_000_registration_1 attribute_001_lattposet))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_lattice6
                      object_000_registration_1 attribute_001_lattposet))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       461)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       462)
                   (== $restored-status WMTrue)))))))))
   True)
