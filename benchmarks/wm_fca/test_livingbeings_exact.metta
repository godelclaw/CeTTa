!(import! &self ./livingbeings_context.metta)

; In this published matrix, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-livingbeings-state)))
     (size-atom $observations))
   72)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-state) livingbeings object_000_leech attribute_000_needs_water_to_live)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-state) livingbeings object_000_leech attribute_002_lives_on_land)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-state) another-context
     object_000_leech attribute_002_lives_on_land)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-livingbeings-state) livingbeings ())
   (attribute_000_needs_water_to_live))

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
            (wm-fca-livingbeings-state)
            livingbeings WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 19))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 29 10))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 19 32))
             (and
               (== (wm-fca-index-closure $index ())
                   (attribute_000_needs_water_to_live))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_needs_water_to_live)) (attribute_000_needs_water_to_live))
                 (and
                   (and
                     (== (size-atom $intents) 19)
                     (wm-fca-same-set?
                       $intents (wm-fca-livingbeings-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 19)
                       (wm-fca-same-set?
                         $concepts (wm-fca-livingbeings-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 10)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-livingbeings-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication () (attribute_000_needs_water_to_live)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_needs_water_to_live) (attribute_001_lives_in_water))))
                           (and
                             (== (size-atom $covers) 32)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-livingbeings-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-livingbeings-state) livingbeings object_000_leech attribute_002_lives_on_land)
   ((WMFCAObservation
      livingbeings object_000_leech attribute_002_lives_on_land WMFalse
      livingbeings-cell-000-002 fcatools-contexts-9306d256 livingbeings-published-matrix)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-livingbeings-state)
              (wm-fca-livingbeings-state))))
     (size-atom $observations))
   72)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-livingbeings-without-example)
   (wm-fca-forget
     (wm-fca-livingbeings-state) (WMFCAScopeStamp livingbeings-cell-000-000)))
(= (wm-fca-livingbeings-restored-example)
   (wm-fca-remember
     (wm-fca-livingbeings-without-example)
     (WMFCAObservation
       livingbeings object_000_leech attribute_000_needs_water_to_live WMTrue
       livingbeings-cell-000-000 fcatools-contexts-9306d256 livingbeings-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-without-example)
     livingbeings object_000_leech attribute_000_needs_water_to_live)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-livingbeings-restored-example)
     livingbeings object_000_leech attribute_000_needs_water_to_live)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-livingbeings-state)
            livingbeings WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-livingbeings-restored-example)
              livingbeings WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
