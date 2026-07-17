!(import! &self ./mizar_conlat_2_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_conlat_2-state)))
     (size-atom $observations))
   243)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-state) mizar_conlat_2 object_000_definition_1 attribute_000_cp)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-state) mizar_conlat_2 object_000_definition_1 attribute_002_conceptstr)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-state) another-context
     object_000_definition_1 attribute_002_conceptstr)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_conlat_2-state) mizar_conlat_2 (attribute_005_dualhomomorphism))
   (attribute_001_conceptlattice attribute_005_dualhomomorphism))

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
            (wm-fca-mizar_conlat_2-state)
            mizar_conlat_2 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 32))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 57 25))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 32 60))
             (and
               (== (wm-fca-index-closure $index (attribute_005_dualhomomorphism))
                   (attribute_001_conceptlattice attribute_005_dualhomomorphism))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_cp)) (attribute_000_cp))
                 (and
                   (and
                     (== (size-atom $intents) 32)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_conlat_2-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 32)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_conlat_2-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 25)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_conlat_2-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_005_dualhomomorphism) (attribute_001_conceptlattice)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_cp) (attribute_001_conceptlattice))))
                           (and
                             (== (size-atom $covers) 60)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_conlat_2-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_conlat_2-state) mizar_conlat_2 object_000_definition_1 attribute_002_conceptstr)
   ((WMFCAObservation
      mizar_conlat_2 object_000_definition_1 attribute_002_conceptstr WMFalse
      mizar_conlat_2-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-conlat-2-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_conlat_2-state)
              (wm-fca-mizar_conlat_2-state))))
     (size-atom $observations))
   243)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_conlat_2-without-example)
   (wm-fca-forget
     (wm-fca-mizar_conlat_2-state) (WMFCAScopeStamp mizar_conlat_2-cell-000-000)))
(= (wm-fca-mizar_conlat_2-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_conlat_2-without-example)
     (WMFCAObservation
       mizar_conlat_2 object_000_definition_1 attribute_000_cp WMTrue
       mizar_conlat_2-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-conlat-2-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-without-example)
     mizar_conlat_2 object_000_definition_1 attribute_000_cp)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_conlat_2-restored-example)
     mizar_conlat_2 object_000_definition_1 attribute_000_cp)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_conlat_2-state)
            mizar_conlat_2 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_conlat_2-restored-example)
              mizar_conlat_2 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
