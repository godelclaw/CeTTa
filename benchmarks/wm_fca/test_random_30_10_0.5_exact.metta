!(import! &self ./random_30_10_0.5_context.metta)

; In this FCApy controlled random matrix, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-random_30_10_0.5-state)))
     (size-atom $observations))
   300)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-state) random_30_10_0.5 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-state) random_30_10_0.5 object_000_g_0 attribute_002_m_2)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-state) another-context
     object_000_g_0 attribute_002_m_2)
   WMMissing)
!(assertEqual
   (wm-fca-closure
     (wm-fca-random_30_10_0.5-state) random_30_10_0.5 (attribute_000_m_0 attribute_002_m_2))
   (attribute_000_m_0 attribute_002_m_2 attribute_006_m_6))



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
            (wm-fca-random_30_10_0.5-state)
            random_30_10_0.5 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 172))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 219 47))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 172 521))
             (and
               (== (wm-fca-index-closure $index (attribute_000_m_0 attribute_002_m_2)) (attribute_000_m_0 attribute_002_m_2 attribute_006_m_6))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_m_0)) (attribute_000_m_0))
                 (and
                   (and
                     (== (size-atom $intents) 172)
                     (wm-fca-same-set?
                       $intents (wm-fca-random_30_10_0.5-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 172)
                       (wm-fca-same-set?
                         $concepts (wm-fca-random_30_10_0.5-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 47)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-random_30_10_0.5-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0 attribute_002_m_2) (attribute_006_m_6)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_m_0) (attribute_001_m_1))))
                           (and
                             (== (size-atom $covers) 521)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-random_30_10_0.5-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-random_30_10_0.5-state) random_30_10_0.5 object_000_g_0 attribute_002_m_2)
   ((WMFCAObservation
      random_30_10_0.5 object_000_g_0 attribute_002_m_2 WMFalse
      random_30_10_0.5-cell-000-002 fcapy-controlled-random-509f45a3 random_30_10_0.5-generated-matrix)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-random_30_10_0.5-state)
              (wm-fca-random_30_10_0.5-state))))
     (size-atom $observations))
   300)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-random_30_10_0.5-without-example)
   (wm-fca-forget
     (wm-fca-random_30_10_0.5-state) (WMFCAScopeStamp random_30_10_0.5-cell-000-000)))
(= (wm-fca-random_30_10_0.5-restored-example)
   (wm-fca-remember
     (wm-fca-random_30_10_0.5-without-example)
     (WMFCAObservation
       random_30_10_0.5 object_000_g_0 attribute_000_m_0 WMTrue
       random_30_10_0.5-cell-000-000 fcapy-controlled-random-509f45a3 random_30_10_0.5-generated-matrix)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-without-example)
     random_30_10_0.5 object_000_g_0 attribute_000_m_0)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-random_30_10_0.5-restored-example)
     random_30_10_0.5 object_000_g_0 attribute_000_m_0)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-random_30_10_0.5-state)
            random_30_10_0.5 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-random_30_10_0.5-restored-example)
              random_30_10_0.5 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
