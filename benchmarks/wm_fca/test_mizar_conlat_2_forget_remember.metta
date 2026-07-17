!(import! &self ./mizar_conlat_2_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_conlat_2-state) (WMFCAScopeStamp mizar_conlat_2-cell-000-000)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_conlat_2 object_000_definition_1 attribute_000_cp WMTrue
                mizar_conlat_2-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-conlat-2-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_conlat_2
                    object_000_definition_1 attribute_000_cp))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_conlat_2
                      object_000_definition_1 attribute_000_cp))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       242)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       243)
                   (== $restored-status WMTrue)))))))))
   True)
