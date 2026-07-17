!(import! &self ./random_10_10_0.5_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-random_10_10_0.5-state) (WMFCAScopeStamp random_10_10_0.5-cell-000-001)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                random_10_10_0.5 object_000_g_0 attribute_001_m_1 WMTrue
                random_10_10_0.5-cell-000-001 fcapy-controlled-random-509f45a3 random_10_10_0.5-generated-matrix)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten random_10_10_0.5
                    object_000_g_0 attribute_001_m_1))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored random_10_10_0.5
                      object_000_g_0 attribute_001_m_1))
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
