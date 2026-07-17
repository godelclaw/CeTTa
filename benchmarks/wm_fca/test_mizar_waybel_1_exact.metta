!(import! &self ./mizar_waybel_1_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_waybel_1-state)))
     (size-atom $observations))
   1904)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-state) mizar_waybel_1 object_000_definition_1 attribute_002_function)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-state) mizar_waybel_1 object_000_definition_1 attribute_000_boolean)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-state) another-context
     object_000_definition_1 attribute_000_boolean)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_waybel_1-state) mizar_waybel_1 (attribute_001_connection))
   (attribute_001_connection attribute_002_function))

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
            (wm-fca-mizar_waybel_1-state)
            mizar_waybel_1 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 52))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 118 66))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 52 106))
             (and
               (== (wm-fca-index-closure $index (attribute_001_connection))
                   (attribute_001_connection attribute_002_function))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_boolean)) (attribute_000_boolean))
                 (and
                   (and
                     (== (size-atom $intents) 52)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_waybel_1-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 52)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_waybel_1-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 66)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_waybel_1-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_001_connection) (attribute_002_function)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_boolean) (attribute_001_connection))))
                           (and
                             (== (size-atom $covers) 106)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_waybel_1-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_waybel_1-state) mizar_waybel_1 object_000_definition_1 attribute_000_boolean)
   ((WMFCAObservation
      mizar_waybel_1 object_000_definition_1 attribute_000_boolean WMFalse
      mizar_waybel_1-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_waybel_1-state)
              (wm-fca-mizar_waybel_1-state))))
     (size-atom $observations))
   1904)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_waybel_1-without-example)
   (wm-fca-forget
     (wm-fca-mizar_waybel_1-state) (WMFCAScopeStamp mizar_waybel_1-cell-000-002)))
(= (wm-fca-mizar_waybel_1-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_waybel_1-without-example)
     (WMFCAObservation
       mizar_waybel_1 object_000_definition_1 attribute_002_function WMTrue
       mizar_waybel_1-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-waybel-1-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-without-example)
     mizar_waybel_1 object_000_definition_1 attribute_002_function)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_waybel_1-restored-example)
     mizar_waybel_1 object_000_definition_1 attribute_002_function)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_waybel_1-state)
            mizar_waybel_1 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_waybel_1-restored-example)
              mizar_waybel_1 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
