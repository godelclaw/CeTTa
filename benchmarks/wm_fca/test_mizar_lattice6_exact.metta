!(import! &self ./mizar_lattice6_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattice6-state)))
     (size-atom $observations))
   462)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-state) mizar_lattice6 object_000_registration_1 attribute_001_lattposet)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-state) mizar_lattice6 object_000_registration_1 attribute_000_jirrs)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-state) another-context
     object_000_registration_1 attribute_000_jirrs)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_lattice6-state) mizar_lattice6 (attribute_002_mirrs))
   (attribute_002_mirrs attribute_003_subset))

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
            (wm-fca-mizar_lattice6-state)
            mizar_lattice6 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 36))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 71 35))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 36 74))
             (and
               (== (wm-fca-index-closure $index (attribute_002_mirrs))
                   (attribute_002_mirrs attribute_003_subset))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_jirrs)) (attribute_000_jirrs))
                 (and
                   (and
                     (== (size-atom $intents) 36)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_lattice6-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 36)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_lattice6-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 35)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_lattice6-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_002_mirrs) (attribute_003_subset)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_jirrs) (attribute_001_lattposet))))
                           (and
                             (== (size-atom $covers) 74)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_lattice6-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice6-state) mizar_lattice6 object_000_registration_1 attribute_000_jirrs)
   ((WMFCAObservation
      mizar_lattice6 object_000_registration_1 attribute_000_jirrs WMFalse
      mizar_lattice6-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice6-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice6-state)
              (wm-fca-mizar_lattice6-state))))
     (size-atom $observations))
   462)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_lattice6-without-example)
   (wm-fca-forget
     (wm-fca-mizar_lattice6-state) (WMFCAScopeStamp mizar_lattice6-cell-000-001)))
(= (wm-fca-mizar_lattice6-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_lattice6-without-example)
     (WMFCAObservation
       mizar_lattice6 object_000_registration_1 attribute_001_lattposet WMTrue
       mizar_lattice6-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-lattice6-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-without-example)
     mizar_lattice6 object_000_registration_1 attribute_001_lattposet)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice6-restored-example)
     mizar_lattice6 object_000_registration_1 attribute_001_lattposet)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice6-state)
            mizar_lattice6 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattice6-restored-example)
              mizar_lattice6 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
