!(import! &self ./binary_relations_context.metta)

; In this published matrix, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-binary_relations-state)))
     (size-atom $observations))
   126)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-state) binary_relations object_000_object_1 attribute_001_irreflexive)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-state) binary_relations object_000_object_1 attribute_000_reflexive)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-state) another-context
     object_000_object_1 attribute_000_reflexive)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-binary_relations-state) binary_relations (attribute_003_asymmetric))
   (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric))

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
            (wm-fca-binary_relations-state)
            binary_relations WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 50))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 63 13))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 50 116))
             (and
               (== (wm-fca-index-closure $index (attribute_003_asymmetric))
                   (attribute_001_irreflexive attribute_003_asymmetric attribute_004_antisymmetric))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_reflexive)) (attribute_000_reflexive))
                 (and
                   (and
                     (== (size-atom $intents) 50)
                     (wm-fca-same-set?
                       $intents (wm-fca-binary_relations-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 50)
                       (wm-fca-same-set?
                         $concepts (wm-fca-binary_relations-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 13)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-binary_relations-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_003_asymmetric) (attribute_001_irreflexive attribute_004_antisymmetric)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_reflexive) (attribute_001_irreflexive))))
                           (and
                             (== (size-atom $covers) 116)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-binary_relations-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-binary_relations-state) binary_relations object_000_object_1 attribute_000_reflexive)
   ((WMFCAObservation
      binary_relations object_000_object_1 attribute_000_reflexive WMFalse
      binary_relations-cell-000-000 fcatools-contexts-9306d256 binary_relations-published-matrix)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-binary_relations-state)
              (wm-fca-binary_relations-state))))
     (size-atom $observations))
   126)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-binary_relations-without-example)
   (wm-fca-forget
     (wm-fca-binary_relations-state) (WMFCAScopeStamp binary_relations-cell-000-001)))
(= (wm-fca-binary_relations-restored-example)
   (wm-fca-remember
     (wm-fca-binary_relations-without-example)
     (WMFCAObservation
       binary_relations object_000_object_1 attribute_001_irreflexive WMTrue
       binary_relations-cell-000-001 fcatools-contexts-9306d256 binary_relations-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-without-example)
     binary_relations object_000_object_1 attribute_001_irreflexive)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-binary_relations-restored-example)
     binary_relations object_000_object_1 attribute_001_irreflexive)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-binary_relations-state)
            binary_relations WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-binary_relations-restored-example)
              binary_relations WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
