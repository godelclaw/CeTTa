!(import! &self ./mizar_yellow_1_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_yellow_1-state)))
     (size-atom $observations))
   306)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-state) mizar_yellow_1 object_000_definition_1 attribute_001_inclposet)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-state) mizar_yellow_1 object_000_definition_1 attribute_000_booleposet)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-state) another-context
     object_000_definition_1 attribute_000_booleposet)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_yellow_1-state) mizar_yellow_1 (attribute_002_monmaps))
   (attribute_002_monmaps attribute_003_relstr attribute_005_subrelstr))

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
            (wm-fca-mizar_yellow_1-state)
            mizar_yellow_1 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 13))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 22 9))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 13 21))
             (and
               (== (wm-fca-index-closure $index (attribute_002_monmaps))
                   (attribute_002_monmaps attribute_003_relstr attribute_005_subrelstr))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_booleposet)) (attribute_000_booleposet))
                 (and
                   (and
                     (== (size-atom $intents) 13)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_yellow_1-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 13)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_yellow_1-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 9)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_yellow_1-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_002_monmaps) (attribute_003_relstr attribute_005_subrelstr)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_booleposet) (attribute_001_inclposet))))
                           (and
                             (== (size-atom $covers) 21)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_yellow_1-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_yellow_1-state) mizar_yellow_1 object_000_definition_1 attribute_000_booleposet)
   ((WMFCAObservation
      mizar_yellow_1 object_000_definition_1 attribute_000_booleposet WMFalse
      mizar_yellow_1-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-1-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_yellow_1-state)
              (wm-fca-mizar_yellow_1-state))))
     (size-atom $observations))
   306)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_yellow_1-without-example)
   (wm-fca-forget
     (wm-fca-mizar_yellow_1-state) (WMFCAScopeStamp mizar_yellow_1-cell-000-001)))
(= (wm-fca-mizar_yellow_1-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_yellow_1-without-example)
     (WMFCAObservation
       mizar_yellow_1 object_000_definition_1 attribute_001_inclposet WMTrue
       mizar_yellow_1-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-yellow-1-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-without-example)
     mizar_yellow_1 object_000_definition_1 attribute_001_inclposet)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_1-restored-example)
     mizar_yellow_1 object_000_definition_1 attribute_001_inclposet)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_1-state)
            mizar_yellow_1 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_1-restored-example)
              mizar_yellow_1 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
