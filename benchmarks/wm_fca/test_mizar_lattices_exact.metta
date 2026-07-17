!(import! &self ./mizar_lattices_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattices-state)))
     (size-atom $observations))
   1800)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-state) mizar_lattices object_000_definition_1 attribute_001_binop)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-state) mizar_lattices object_000_definition_1 attribute_000_b_lattice)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-state) another-context
     object_000_definition_1 attribute_000_b_lattice)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_lattices-state) mizar_lattices (attribute_011_lattice_like))
   (attribute_009_lattstr attribute_011_lattice_like))

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
            (wm-fca-mizar_lattices-state)
            mizar_lattices WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 81))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 281 200))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 81 166))
             (and
               (== (wm-fca-index-closure $index (attribute_011_lattice_like))
                   (attribute_009_lattstr attribute_011_lattice_like))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_b_lattice)) (attribute_000_b_lattice))
                 (and
                   (and
                     (== (size-atom $intents) 81)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_lattices-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 81)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_lattices-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 200)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_lattices-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_011_lattice_like) (attribute_009_lattstr)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_b_lattice) (attribute_001_binop))))
                           (and
                             (== (size-atom $covers) 166)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_lattices-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattices-state) mizar_lattices object_000_definition_1 attribute_000_b_lattice)
   ((WMFCAObservation
      mizar_lattices object_000_definition_1 attribute_000_b_lattice WMFalse
      mizar_lattices-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattices-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattices-state)
              (wm-fca-mizar_lattices-state))))
     (size-atom $observations))
   1800)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_lattices-without-example)
   (wm-fca-forget
     (wm-fca-mizar_lattices-state) (WMFCAScopeStamp mizar_lattices-cell-000-001)))
(= (wm-fca-mizar_lattices-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_lattices-without-example)
     (WMFCAObservation
       mizar_lattices object_000_definition_1 attribute_001_binop WMTrue
       mizar_lattices-cell-000-001 mettapedia-mizar-family-f93a93f7 mizar-lattices-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-without-example)
     mizar_lattices object_000_definition_1 attribute_001_binop)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattices-restored-example)
     mizar_lattices object_000_definition_1 attribute_001_binop)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattices-state)
            mizar_lattices WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattices-restored-example)
              mizar_lattices WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
