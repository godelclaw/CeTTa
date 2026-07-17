!(import! &self ./music_context.metta)

; Materialize each immutable transition once and check both cardinality and
; four-valued query behavior before any FCA compilation.
!(assertEqual
   (let $forgotten
        (eval
          (wm-fca-forget
            (wm-fca-music-state) (WMFCAScopeStamp music-cell-000-000)))
     (let $restored
          (eval
            (wm-fca-remember
              $forgotten
              (WMFCAObservation
                music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded WMTrue
                music-cell-000-000 fcatools-contexts-9306d256 music-published-matrix)))
       (let $forgotten-observations
            (eval (wm-fca-state-observations $forgotten))
         (let $restored-observations
              (eval (wm-fca-state-observations $restored))
           (let $forgotten-status
                (eval
                  (wm-fca-cell-status
                    $forgotten music
                    object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded))
             (let $restored-status
                  (eval
                    (wm-fca-cell-status
                      $restored music
                      object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded))
               (and
                 (and
                   (== (size-atom $forgotten-observations)
                       340)
                   (== $forgotten-status WMMissing))
                 (and
                   (== (size-atom $restored-observations)
                       341)
                   (== $restored-status WMTrue)))))))))
   True)
