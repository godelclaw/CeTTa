!(import! &self ./mizar_yellow_0_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_yellow_0-state) (WMFCAScopeStamp mizar_yellow_0-cell-000-001)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_yellow_0 object_000_scheme_1 attribute_001_relstr WMTrue
                mizar_yellow_0-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-yellow-0-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_yellow_0
                    object_000_scheme_1 attribute_001_relstr))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_yellow_0
                      object_000_scheme_1 attribute_001_relstr))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       1175)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       1176)
                   (== $restored-status WMTrue)))))))))
   True)
