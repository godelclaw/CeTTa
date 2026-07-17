!(import! &self ./binary_relations_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-binary_relations-state) (WMFCAScopeStamp binary_relations-cell-000-001)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                binary_relations object_000_object_1 attribute_001_irreflexive WMTrue
                binary_relations-cell-000-001 fcatools-contexts-9306d256 binary_relations-published-matrix)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten binary_relations
                    object_000_object_1 attribute_001_irreflexive))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored binary_relations
                      object_000_object_1 attribute_001_irreflexive))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       125)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       126)
                   (== $restored-status WMTrue)))))))))
   True)
