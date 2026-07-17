!(import! &self ./mizar_conlat_1_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_conlat_1-state) (WMFCAScopeStamp mizar_conlat_1-cell-000-015)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_conlat_1 object_000_definition_1 attribute_015_contextstr WMTrue
                mizar_conlat_1-cell-000-015 mettapedia-mizar-family-f93a93f7 mizar-conlat-1-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_conlat_1
                    object_000_definition_1 attribute_015_contextstr))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_conlat_1
                      object_000_definition_1 attribute_015_contextstr))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       2655)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       2656)
                   (== $restored-status WMTrue)))))))))
   True)
