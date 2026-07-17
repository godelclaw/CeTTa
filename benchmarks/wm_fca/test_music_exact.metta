!(import! &self ./music_context.metta)

; In this published matrix, every matrix cell is observed rather than missing.
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
   (wm-fca-closure (wm-fca-music-state) music (attribute_000_well_rounded))
   (attribute_000_well_rounded attribute_001_well_balanced attribute_003_transparent attribute_004_structured_thoroughly))

; Compile the exact projection once.  Native Next-Closure is capped at the
; independently established concept count, so a disagreement fails loudly
; rather than returning a partial lattice.  Concepts and covers consume that
; single result, while the canonical-basis fold carries its own prior closures.
; The lexical scope preserves computed data without turning large expressions
; back into executable surface syntax.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-music-state)
            music WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 163))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 182 19))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 163 507))
             (and
               (== (wm-fca-index-closure $index (attribute_000_well_rounded))
                   (attribute_000_well_rounded attribute_001_well_balanced attribute_003_transparent attribute_004_structured_thoroughly))
               (and
                 (== (wm-fca-index-closure $index (attribute_003_transparent)) (attribute_003_transparent))
                 (and
                   (and
                     (== (size-atom $intents) 163)
                     (wm-fca-same-set?
                       $intents (wm-fca-music-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 163)
                       (wm-fca-same-set?
                         $concepts (wm-fca-music-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 19)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-music-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_well_rounded) (attribute_001_well_balanced attribute_003_transparent attribute_004_structured_thoroughly)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_well_rounded) (attribute_002_dramatic))))
                           (and
                             (== (size-atom $covers) 507)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-music-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-music-state) music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic)
   ((WMFCAObservation
      music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_002_dramatic WMFalse
      music-cell-000-002 fcatools-contexts-9306d256 music-published-matrix)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-music-state)
              (wm-fca-music-state))))
     (size-atom $observations))
   341)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-music-without-example)
   (wm-fca-forget
     (wm-fca-music-state) (WMFCAScopeStamp music-cell-000-000)))
(= (wm-fca-music-restored-example)
   (wm-fca-remember
     (wm-fca-music-without-example)
     (WMFCAObservation
       music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded WMTrue
       music-cell-000-000 fcatools-contexts-9306d256 music-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-without-example)
     music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-music-restored-example)
     music object_000_beethoven_romance_for_violin_and_orchestra_f_major attribute_000_well_rounded)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-music-state)
            music WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-music-restored-example)
              music WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
