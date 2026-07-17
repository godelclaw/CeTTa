!(import! &self ./music_context.metta)

; Complete-matrix status and provenance remain explicit before projection.
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-state) music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-state) music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic)
   WMFalse)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-music-state) music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic)
   ((WMFCAObservation
      music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic WMFalse
      music-cell-000-002 fcatools-contexts-9306d256 music-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-state) another-context
     object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic)
   WMMissing)
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-music-state)
              (wm-fca-music-state))))
     (size-atom $observations))
   341)

; Forgetting makes the cell missing; remembering its exact observation restores
; both the query and the freshly compiled finite context.
(= (wm-fca-music-update-test-forgotten)
   (wm-fca-forget
     (wm-fca-music-state) (WMFCAScopeStamp music-cell-000-000)))
(= (wm-fca-music-update-test-restored)
   (wm-fca-remember
     (wm-fca-music-update-test-forgotten)
     (WMFCAObservation
       music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded WMTrue
       music-cell-000-000 fcatools-contexts-9306d256 music-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-update-test-forgotten)
     music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-update-test-restored)
     music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-music-update-test-restored))
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
