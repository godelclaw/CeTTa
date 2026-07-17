!(import! &self ./livingbeings_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-livingbeings-state) (WMFCAScopeStamp livingbeings-cell-000-000)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                livingbeings object_000_leech attribute_000_needs_water_to_live WMTrue
                livingbeings-cell-000-000 fcatools-contexts-9306d256 livingbeings-published-matrix)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten livingbeings
                    object_000_leech attribute_000_needs_water_to_live))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored livingbeings
                      object_000_leech attribute_000_needs_water_to_live))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       71)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       72)
                   (== $restored-status WMTrue)))))))))
   True)
