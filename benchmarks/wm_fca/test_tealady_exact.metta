!(import! &self ./tealady_context.metta)

; In this published matrix, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-tealady-state)))
     (size-atom $observations))
   252)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-state) tealady object_000_evelyn attribute_000_attribute_1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-state) tealady object_000_evelyn attribute_006_attribute_7)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-state) another-context
     object_000_evelyn attribute_006_attribute_7)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-tealady-state) tealady (attribute_000_attribute_1))
   (attribute_000_attribute_1 attribute_002_attribute_3 attribute_004_attribute_5 attribute_005_attribute_6 attribute_007_attribute_8))

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
            (wm-fca-tealady-state)
            tealady WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 65))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 88 23))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 65 148))
             (and
               (== (wm-fca-index-closure $index (attribute_000_attribute_1))
                   (attribute_000_attribute_1 attribute_002_attribute_3 attribute_004_attribute_5 attribute_005_attribute_6 attribute_007_attribute_8))
               (and
                 (== (wm-fca-index-closure $index (attribute_004_attribute_5)) (attribute_004_attribute_5))
                 (and
                   (and
                     (== (size-atom $intents) 65)
                     (wm-fca-same-set?
                       $intents (wm-fca-tealady-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 65)
                       (wm-fca-same-set?
                         $concepts (wm-fca-tealady-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 23)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-tealady-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_attribute_1) (attribute_002_attribute_3 attribute_004_attribute_5 attribute_005_attribute_6 attribute_007_attribute_8)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_attribute_1) (attribute_001_attribute_2))))
                           (and
                             (== (size-atom $covers) 148)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-tealady-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-tealady-state) tealady object_000_evelyn attribute_006_attribute_7)
   ((WMFCAObservation
      tealady object_000_evelyn attribute_006_attribute_7 WMFalse
      tealady-cell-000-006 fcatools-contexts-9306d256 tealady-published-matrix)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-tealady-state)
              (wm-fca-tealady-state))))
     (size-atom $observations))
   252)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-tealady-without-example)
   (wm-fca-forget
     (wm-fca-tealady-state) (WMFCAScopeStamp tealady-cell-000-000)))
(= (wm-fca-tealady-restored-example)
   (wm-fca-remember
     (wm-fca-tealady-without-example)
     (WMFCAObservation
       tealady object_000_evelyn attribute_000_attribute_1 WMTrue
       tealady-cell-000-000 fcatools-contexts-9306d256 tealady-published-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-without-example)
     tealady object_000_evelyn attribute_000_attribute_1)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-tealady-restored-example)
     tealady object_000_evelyn attribute_000_attribute_1)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-tealady-state)
            tealady WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-tealady-restored-example)
              tealady WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
