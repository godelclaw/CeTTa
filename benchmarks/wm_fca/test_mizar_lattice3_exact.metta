!(import! &self ./mizar_lattice3_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattice3-state)))
     (size-atom $observations))
   869)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-state) mizar_lattice3 object_000_definition_1 attribute_000_boolelatt)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-state) mizar_lattice3 object_000_definition_1 attribute_002_lattposet)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-state) another-context
     object_000_definition_1 attribute_002_lattposet)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_lattice3-state) mizar_lattice3 (attribute_000_boolelatt attribute_001_it))
   (attribute_000_boolelatt attribute_001_it attribute_003_lattstr))

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
            (wm-fca-mizar_lattice3-state)
            mizar_lattice3 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 48))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 94 46))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 48 98))
             (and
               (== (wm-fca-index-closure $index (attribute_000_boolelatt attribute_001_it))
                   (attribute_000_boolelatt attribute_001_it attribute_003_lattstr))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_boolelatt)) (attribute_000_boolelatt))
                 (and
                   (and
                     (== (size-atom $intents) 48)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_lattice3-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 48)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_lattice3-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 46)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_lattice3-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_boolelatt attribute_001_it) (attribute_003_lattstr)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_boolelatt) (attribute_001_it))))
                           (and
                             (== (size-atom $covers) 98)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_lattice3-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice3-state) mizar_lattice3 object_000_definition_1 attribute_002_lattposet)
   ((WMFCAObservation
      mizar_lattice3 object_000_definition_1 attribute_002_lattposet WMFalse
      mizar_lattice3-cell-000-002 mettapedia-mizar-family-f93a93f7 mizar-lattice3-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice3-state)
              (wm-fca-mizar_lattice3-state))))
     (size-atom $observations))
   869)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_lattice3-without-example)
   (wm-fca-forget
     (wm-fca-mizar_lattice3-state) (WMFCAScopeStamp mizar_lattice3-cell-000-000)))
(= (wm-fca-mizar_lattice3-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_lattice3-without-example)
     (WMFCAObservation
       mizar_lattice3 object_000_definition_1 attribute_000_boolelatt WMTrue
       mizar_lattice3-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice3-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-without-example)
     mizar_lattice3 object_000_definition_1 attribute_000_boolelatt)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice3-restored-example)
     mizar_lattice3 object_000_definition_1 attribute_000_boolelatt)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice3-state)
            mizar_lattice3 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattice3-restored-example)
              mizar_lattice3 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
