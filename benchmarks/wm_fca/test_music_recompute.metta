!(import! &self ./music_context.metta)

(= (wm-fca-music-recompute-forgotten)
   (wm-fca-forget
     (wm-fca-music-state) (WMFCAScopeStamp music-cell-000-000)))
(= (wm-fca-music-recompute-restored)
   (wm-fca-remember
     (wm-fca-music-recompute-forgotten)
     (WMFCAObservation
       music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded WMTrue
       music-cell-000-000 fcatools-contexts-9306d256 music-published-matrix)))

; The incremental forget/remember sequence and fresh compilation agree exactly.
!(assertEqual
   (let $restored-state
        (eval (wm-fca-music-recompute-restored))
     (let $original-index
          (eval
            (wm-fca-build-index
              (wm-fca-music-state)
              music WMFCAExactStatusGate))
       (let $restored-index
            (eval
              (wm-fca-build-index
                $restored-state
                music WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $original-index)
           (wm-fca-index-columns $restored-index)))))
   True)
