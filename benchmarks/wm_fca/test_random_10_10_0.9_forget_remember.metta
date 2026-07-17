!(import! &self ./random_10_10_0.9_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-random_10_10_0.9-state) (WMFCAScopeStamp random_10_10_0.9-cell-000-000)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                random_10_10_0.9 object_000_g_0 attribute_000_m_0 WMTrue
                random_10_10_0.9-cell-000-000 fcapy-controlled-random-509f45a3 random_10_10_0.9-generated-matrix)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten random_10_10_0.9
                    object_000_g_0 attribute_000_m_0))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored random_10_10_0.9
                      object_000_g_0 attribute_000_m_0))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       99)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       100)
                   (== $restored-status WMTrue)))))))))
   True)
