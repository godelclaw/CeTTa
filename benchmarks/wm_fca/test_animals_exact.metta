!(import! &self ./animals_context.metta)

; In this published matrix, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-animals-state)))
     (size-atom $observations))
   385)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-state) animals object_000_alligator attribute_000_eggs)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-state) animals object_000_alligator attribute_001_nocturnal)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-state) another-context
     object_000_alligator attribute_001_nocturnal)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-animals-state) animals (attribute_001_nocturnal))
   (attribute_001_nocturnal attribute_006_airbreather))

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
            (wm-fca-animals-state)
            animals WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 35))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 64 29))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 35 66))
             (and
               (== (wm-fca-index-closure $index (attribute_001_nocturnal))
                   (attribute_001_nocturnal attribute_006_airbreather))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_eggs)) (attribute_000_eggs))
                 (and
                   (and
                     (== (size-atom $intents) 35)
                     (wm-fca-same-set?
                       $intents (wm-fca-animals-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 35)
                       (wm-fca-same-set?
                         $concepts (wm-fca-animals-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 29)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-animals-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_001_nocturnal) (attribute_006_airbreather)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_eggs) (attribute_001_nocturnal))))
                           (and
                             (== (size-atom $covers) 66)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-animals-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-animals-state) animals object_000_alligator attribute_001_nocturnal)
   ((WMFCAObservation
      animals object_000_alligator attribute_001_nocturnal WMFalse
      animals-cell-000-001 fcatools-contexts-9306d256 animals-published-matrix)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-animals-state)
              (wm-fca-animals-state))))
     (size-atom $observations))
   385)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-animals-without-example)
   (wm-fca-forget
     (wm-fca-animals-state) (WMFCAScopeStamp animals-cell-000-000)))
(= (wm-fca-animals-restored-example)
   (wm-fca-remember
     (wm-fca-animals-without-example)
     (WMFCAObservation
       animals object_000_alligator attribute_000_eggs WMTrue
       animals-cell-000-000 fcatools-contexts-9306d256 animals-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-without-example)
     animals object_000_alligator attribute_000_eggs)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-animals-restored-example)
     animals object_000_alligator attribute_000_eggs)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-animals-state)
            animals WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-animals-restored-example)
              animals WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
