!(import! &self ./mizar_yellow_2_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-mizar_yellow_2-state) (WMFCAScopeStamp mizar_yellow_2-cell-000-005)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr WMTrue
                mizar_yellow_2-cell-000-005 mettapedia-mizar-family-f93a93f7 mizar-yellow-2-extraction)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten mizar_yellow_2
                    object_000_theorem_6 attribute_005_subrelstr))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored mizar_yellow_2
                      object_000_theorem_6 attribute_005_subrelstr))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       349)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       350)
                   (== $restored-status WMTrue)))))))))
   True)
