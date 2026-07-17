!(import! &self ./random_100_10_0.9_context.metta)

; In this FCApy controlled random matrix, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-random_100_10_0.9-state)))
     (size-atom $observations))
   1000)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.9-state) random_100_10_0.9 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.9-state) random_100_10_0.9 object_001_g_1 attribute_007_m_7)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.9-state) another-context
     object_001_g_1 attribute_007_m_7)
   WMMissing)


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
            (wm-fca-random_100_10_0.9-state)
            random_100_10_0.9 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 1024))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 1024 0))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 1024 5120))
             (and
               True
               (and
                 (== (wm-fca-index-closure $index (attribute_000_m_0)) (attribute_000_m_0))
                 (and
                   (and
                     (== (size-atom $intents) 1024)
                     (wm-fca-same-set?
                       $intents (wm-fca-random_100_10_0.9-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 1024)
                       (wm-fca-same-set?
                         $concepts (wm-fca-random_100_10_0.9-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 0)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-random_100_10_0.9-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_000_m_0)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_001_m_1))))
                           (and
                             (== (size-atom $covers) 5120)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-random_100_10_0.9-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_100_10_0.9-state) random_100_10_0.9 object_001_g_1 attribute_007_m_7)
   ((WMFCAObservation
      random_100_10_0.9 object_001_g_1 attribute_007_m_7 WMFalse
      random_100_10_0.9-cell-001-007 fcapy-controlled-random-509f45a3 random_100_10_0.9-generated-matrix)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-random_100_10_0.9-state)
              (wm-fca-random_100_10_0.9-state))))
     (size-atom $observations))
   1000)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-random_100_10_0.9-without-example)
   (wm-fca-forget
     (wm-fca-random_100_10_0.9-state) (WMFCAScopeStamp random_100_10_0.9-cell-000-000)))
(= (wm-fca-random_100_10_0.9-restored-example)
   (wm-fca-remember
     (wm-fca-random_100_10_0.9-without-example)
     (WMFCAObservation
       random_100_10_0.9 object_000_g_0 attribute_000_m_0 WMTrue
       random_100_10_0.9-cell-000-000 fcapy-controlled-random-509f45a3 random_100_10_0.9-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.9-without-example)
     random_100_10_0.9 object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_100_10_0.9-restored-example)
     random_100_10_0.9 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-random_100_10_0.9-state)
            random_100_10_0.9 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-random_100_10_0.9-restored-example)
              random_100_10_0.9 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
