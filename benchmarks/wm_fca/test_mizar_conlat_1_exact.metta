!(import! &self ./mizar_conlat_1_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_conlat_1-state)))
     (size-atom $observations))
   2656)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_1-state) mizar_conlat_1 object_000_definition_1 attribute_015_contextstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_1-state) mizar_conlat_1 object_000_definition_1 attribute_000_attribute)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_1-state) another-context
     object_000_definition_1 attribute_000_attribute)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_conlat_1-state) mizar_conlat_1 (attribute_001_attributederivation))
   (attribute_001_attributederivation attribute_018_formalcontext))

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
            (wm-fca-mizar_conlat_1-state)
            mizar_conlat_1 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 256))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 514 258))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 256 680))
             (and
               (== (wm-fca-index-closure $index (attribute_001_attributederivation))
                   (attribute_001_attributederivation attribute_018_formalcontext))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_attribute)) (attribute_000_attribute))
                 (and
                   (and
                     (== (size-atom $intents) 256)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_conlat_1-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 256)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_conlat_1-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 258)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_conlat_1-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_001_attributederivation) (attribute_018_formalcontext)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_attribute) (attribute_001_attributederivation))))
                           (and
                             (== (size-atom $covers) 680)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_conlat_1-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_conlat_1-state) mizar_conlat_1 object_000_definition_1 attribute_000_attribute)
   ((WMFCAObservation
      mizar_conlat_1 object_000_definition_1 attribute_000_attribute WMFalse
      mizar_conlat_1-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-conlat-1-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_conlat_1-state)
              (wm-fca-mizar_conlat_1-state))))
     (size-atom $observations))
   2656)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_conlat_1-without-example)
   (wm-fca-forget
     (wm-fca-mizar_conlat_1-state) (WMFCAScopeStamp mizar_conlat_1-cell-000-015)))
(= (wm-fca-mizar_conlat_1-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_conlat_1-without-example)
     (WMFCAObservation
       mizar_conlat_1 object_000_definition_1 attribute_015_contextstr WMTrue
       mizar_conlat_1-cell-000-015 mettapedia-mizar-family-f93a93f7 mizar-conlat-1-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_1-without-example)
     mizar_conlat_1 object_000_definition_1 attribute_015_contextstr)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_1-restored-example)
     mizar_conlat_1 object_000_definition_1 attribute_015_contextstr)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_conlat_1-state)
            mizar_conlat_1 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_conlat_1-restored-example)
              mizar_conlat_1 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
