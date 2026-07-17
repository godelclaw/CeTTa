!(import! &self ./random_30_10_0.1_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-random_30_10_0.1-state) (WMFCAScopeStamp random_30_10_0.1-cell-000-001)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                random_30_10_0.1 object_000_g_0 attribute_001_m_1 WMTrue
                random_30_10_0.1-cell-000-001 fcapy-controlled-random-509f45a3 random_30_10_0.1-generated-matrix)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten random_30_10_0.1
                    object_000_g_0 attribute_001_m_1))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored random_30_10_0.1
                      object_000_g_0 attribute_001_m_1))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       299)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       300)
                   (== $restored-status WMTrue)))))))))
   True)
