!(import! &self ./tealady_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-tealady-state) (WMFCAScopeStamp tealady-cell-000-000)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                tealady object_000_evelyn attribute_000_attribute_1 WMTrue
                tealady-cell-000-000 fcatools-contexts-9306d256 tealady-published-matrix)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten tealady
                    object_000_evelyn attribute_000_attribute_1))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored tealady
                      object_000_evelyn attribute_000_attribute_1))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       251)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       252)
                   (== $restored-status WMTrue)))))))))
   True)
