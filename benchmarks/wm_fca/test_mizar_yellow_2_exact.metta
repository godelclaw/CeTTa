!(import! &self ./mizar_yellow_2_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_yellow_2-state)))
     (size-atom $observations))
   350)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-state) mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-state) mizar_yellow_2 object_000_theorem_6 attribute_000_function)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-state) another-context
     object_000_theorem_6 attribute_000_function)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_yellow_2-state) mizar_yellow_2 (attribute_003_image))
   (attribute_000_function attribute_003_image))

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
            (wm-fca-mizar_yellow_2-state)
            mizar_yellow_2 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 17))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 28 11))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 17 26))
             (and
               (== (wm-fca-index-closure $index (attribute_003_image))
                   (attribute_000_function attribute_003_image))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_function)) (attribute_000_function))
                 (and
                   (and
                     (== (size-atom $intents) 17)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_yellow_2-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 17)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_yellow_2-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 11)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_yellow_2-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_003_image) (attribute_000_function)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_function) (attribute_001_ids))))
                           (and
                             (== (size-atom $covers) 26)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_yellow_2-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_yellow_2-state) mizar_yellow_2 object_000_theorem_6 attribute_000_function)
   ((WMFCAObservation
      mizar_yellow_2 object_000_theorem_6 attribute_000_function WMFalse
      mizar_yellow_2-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-2-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_yellow_2-state)
              (wm-fca-mizar_yellow_2-state))))
     (size-atom $observations))
   350)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_yellow_2-without-example)
   (wm-fca-forget
     (wm-fca-mizar_yellow_2-state) (WMFCAScopeStamp mizar_yellow_2-cell-000-005)))
(= (wm-fca-mizar_yellow_2-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_yellow_2-without-example)
     (WMFCAObservation
       mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr WMTrue
       mizar_yellow_2-cell-000-005 mettapedia-mizar-family-f93a93f7 mizar-yellow-2-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-without-example)
     mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_2-restored-example)
     mizar_yellow_2 object_000_theorem_6 attribute_005_subrelstr)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_2-state)
            mizar_yellow_2 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_2-restored-example)
              mizar_yellow_2 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
