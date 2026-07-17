!(import! &self ./random_100_10_0.1_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-random_100_10_0.1-state) (WMFCAScopeStamp random_100_10_0.1-cell-000-003)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                random_100_10_0.1 object_000_g_0 attribute_003_m_3 WMTrue
                random_100_10_0.1-cell-000-003 fcapy-controlled-random-509f45a3 random_100_10_0.1-generated-matrix)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten random_100_10_0.1
                    object_000_g_0 attribute_003_m_3))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored random_100_10_0.1
                      object_000_g_0 attribute_003_m_3))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       999)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       1000)
                   (== $restored-status WMTrue)))))))))
   True)
