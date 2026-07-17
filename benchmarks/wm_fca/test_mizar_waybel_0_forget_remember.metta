!(import! &self ./mizar_waybel_0_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_waybel_0-state) (WMFCAScopeStamp mizar_waybel_0-cell-000-011)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_waybel_0 object_000_definition_1 attribute_011_relstr WMTrue
                mizar_waybel_0-cell-000-011 mettapedia-mizar-family-f93a93f7 mizar-waybel-0-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_waybel_0
                    object_000_definition_1 attribute_011_relstr))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_waybel_0
                      object_000_definition_1 attribute_011_relstr))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       4575)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       4576)
                   (== $restored-status WMTrue)))))))))
   True)
