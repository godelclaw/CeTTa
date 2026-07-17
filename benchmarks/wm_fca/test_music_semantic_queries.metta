!(import! &self ./music_context.metta)

; Bounded semantic checks remain separate from potentially expensive complete
; enumeration.  In this published matrix, every matrix cell is observed.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-music-state)))
     (size-atom $observations))
   341)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-state) music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-state) music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-state) another-context
     object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic)
   WMMissing)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-music-state)
            music WMFCAExactStatusGate))
     (and
       (== (wm-fca-index-closure $index (attribute_000_well_rounded)) (attribute_000_well_rounded attribute_001_well_balanced attribute_003_transparent attribute_004_structured_thoroughly))
       (and
         (== (wm-fca-index-closure $index (attribute_003_transparent)) (attribute_003_transparent))
         (and
           (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_well_rounded) (attribute_001_well_balanced attribute_003_transparent attribute_004_structured_thoroughly)))
           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_well_rounded) (attribute_002_dramatic))))))))
   True)
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-music-state) music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic)
   ((WMFCAObservation
      music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic WMFalse
      music-cell-000-002 fcatools-contexts-9306d256 music-published-matrix)))
