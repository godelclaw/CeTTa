!(import! &self ./random_30_10_0.1_context.metta)

; In this FCApy controlled random matrix, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-random_30_10_0.1-state)))
     (size-atom $observations))
   300)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.1-state) random_30_10_0.1 object_000_g_0 attribute_001_m_1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.1-state) random_30_10_0.1 object_000_g_0 attribute_000_m_0)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.1-state) another-context
     object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (wm-fca-closure
     (wm-fca-random_30_10_0.1-state) random_30_10_0.1 (attribute_000_m_0 attribute_001_m_1))
   (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))



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
            (wm-fca-random_30_10_0.1-state)
            random_30_10_0.1 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 21))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 60 39))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 21 38))
             (and
               (== (wm-fca-index-closure $index (attribute_000_m_0 attribute_001_m_1)) (attribute_000_m_0 attribute_001_m_1 attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_m_0)) (attribute_000_m_0))
                 (and
                   (and
                     (== (size-atom $intents) 21)
                     (wm-fca-same-set?
                       $intents (wm-fca-random_30_10_0.1-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 21)
                       (wm-fca-same-set?
                         $concepts (wm-fca-random_30_10_0.1-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 39)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-random_30_10_0.1-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0 attribute_001_m_1) (attribute_002_m_2 attribute_003_m_3 attribute_004_m_4 attribute_005_m_5 attribute_006_m_6 attribute_007_m_7 attribute_008_m_8 attribute_009_m_9)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_001_m_1))))
                           (and
                             (== (size-atom $covers) 38)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-random_30_10_0.1-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_30_10_0.1-state) random_30_10_0.1 object_000_g_0 attribute_000_m_0)
   ((WMFCAObservation
      random_30_10_0.1 object_000_g_0 attribute_000_m_0 WMFalse
      random_30_10_0.1-cell-000-000 fcapy-controlled-random-509f45a3 random_30_10_0.1-generated-matrix)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-random_30_10_0.1-state)
              (wm-fca-random_30_10_0.1-state))))
     (size-atom $observations))
   300)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-random_30_10_0.1-without-example)
   (wm-fca-forget
     (wm-fca-random_30_10_0.1-state) (WMFCAScopeStamp random_30_10_0.1-cell-000-001)))
(= (wm-fca-random_30_10_0.1-restored-example)
   (wm-fca-remember
     (wm-fca-random_30_10_0.1-without-example)
     (WMFCAObservation
       random_30_10_0.1 object_000_g_0 attribute_001_m_1 WMTrue
       random_30_10_0.1-cell-000-001 fcapy-controlled-random-509f45a3 random_30_10_0.1-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.1-without-example)
     random_30_10_0.1 object_000_g_0 attribute_001_m_1)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.1-restored-example)
     random_30_10_0.1 object_000_g_0 attribute_001_m_1)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-random_30_10_0.1-state)
            random_30_10_0.1 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-random_30_10_0.1-restored-example)
              random_30_10_0.1 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
