!(import! &self ./mizar_waybel_1_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_waybel_1-state) (WMFCAScopeStamp mizar_waybel_1-cell-000-002)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_waybel_1 object_000_definition_1 attribute_002_function WMTrue
                mizar_waybel_1-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_waybel_1
                    object_000_definition_1 attribute_002_function))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_waybel_1
                      object_000_definition_1 attribute_002_function))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       1903)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       1904)
                   (== $restored-status WMTrue)))))))))
   True)
