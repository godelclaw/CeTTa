!(import! &self ./animals_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-animals-state) (WMFCAScopeStamp animals-cell-000-000)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                animals object_000_alligator attribute_000_eggs WMTrue
                animals-cell-000-000 fcatools-contexts-9306d256 animals-published-matrix)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten animals
                    object_000_alligator attribute_000_eggs))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored animals
                      object_000_alligator attribute_000_eggs))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       384)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       385)
                   (== $restored-status WMTrue)))))))))
   True)
