!(import! &self ./mizar_yellow_0_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_yellow_0-state)))
     (size-atom $observations))
   1176)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-state) mizar_yellow_0 object_000_scheme_1 attribute_001_relstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-state) mizar_yellow_0 object_000_scheme_1 attribute_000_bottom)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-state) another-context
     object_000_scheme_1 attribute_000_bottom)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_yellow_0-state) mizar_yellow_0 (attribute_000_bottom))
   (attribute_000_bottom attribute_001_relstr))

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
            (wm-fca-mizar_yellow_0-state)
            mizar_yellow_0 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 36))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 64 28))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 36 69))
             (and
               (== (wm-fca-index-closure $index (attribute_000_bottom))
                   (attribute_000_bottom attribute_001_relstr))
               (and
                 (== (wm-fca-index-closure $index (attribute_001_relstr)) (attribute_001_relstr))
                 (and
                   (and
                     (== (size-atom $intents) 36)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_yellow_0-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 36)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_yellow_0-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 28)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_yellow_0-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_bottom) (attribute_001_relstr)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_bottom) (attribute_002_subrelstr))))
                           (and
                             (== (size-atom $covers) 69)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_yellow_0-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_yellow_0-state) mizar_yellow_0 object_000_scheme_1 attribute_000_bottom)
   ((WMFCAObservation
      mizar_yellow_0 object_000_scheme_1 attribute_000_bottom WMFalse
      mizar_yellow_0-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-0-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_yellow_0-state)
              (wm-fca-mizar_yellow_0-state))))
     (size-atom $observations))
   1176)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_yellow_0-without-example)
   (wm-fca-forget
     (wm-fca-mizar_yellow_0-state) (WMFCAScopeStamp mizar_yellow_0-cell-000-001)))
(= (wm-fca-mizar_yellow_0-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_yellow_0-without-example)
     (WMFCAObservation
       mizar_yellow_0 object_000_scheme_1 attribute_001_relstr WMTrue
       mizar_yellow_0-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-yellow-0-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-without-example)
     mizar_yellow_0 object_000_scheme_1 attribute_001_relstr)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_0-restored-example)
     mizar_yellow_0 object_000_scheme_1 attribute_001_relstr)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_0-state)
            mizar_yellow_0 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_0-restored-example)
              mizar_yellow_0 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
