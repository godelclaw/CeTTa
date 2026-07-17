!(import! &self ./mizar_lattice2_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattice2-state)))
     (size-atom $observations))
   405)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-state) mizar_lattice2 object_000_notation_1 attribute_006_lattstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-state) mizar_lattice2 object_000_notation_1 attribute_000_d0_lattice)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-state) another-context
     object_000_notation_1 attribute_000_d0_lattice)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_lattice2-state) mizar_lattice2 (attribute_000_d0_lattice))
   (attribute_000_d0_lattice attribute_007_lattice))

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
            (wm-fca-mizar_lattice2-state)
            mizar_lattice2 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 22))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 42 20))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 22 39))
             (and
               (== (wm-fca-index-closure $index (attribute_000_d0_lattice))
                   (attribute_000_d0_lattice attribute_007_lattice))
               (and
                 (== (wm-fca-index-closure $index (attribute_001_finjoin)) (attribute_001_finjoin))
                 (and
                   (and
                     (== (size-atom $intents) 22)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_lattice2-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 22)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_lattice2-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 20)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_lattice2-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_d0_lattice) (attribute_007_lattice)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_d0_lattice) (attribute_001_finjoin))))
                           (and
                             (== (size-atom $covers) 39)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_lattice2-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice2-state) mizar_lattice2 object_000_notation_1 attribute_000_d0_lattice)
   ((WMFCAObservation
      mizar_lattice2 object_000_notation_1 attribute_000_d0_lattice WMFalse
      mizar_lattice2-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice2-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice2-state)
              (wm-fca-mizar_lattice2-state))))
     (size-atom $observations))
   405)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_lattice2-without-example)
   (wm-fca-forget
     (wm-fca-mizar_lattice2-state) (WMFCAScopeStamp mizar_lattice2-cell-000-006)))
(= (wm-fca-mizar_lattice2-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_lattice2-without-example)
     (WMFCAObservation
       mizar_lattice2 object_000_notation_1 attribute_006_lattstr WMTrue
       mizar_lattice2-cell-000-006 mettapedia-mizar-family-f93a93f7 mizar-lattice2-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-without-example)
     mizar_lattice2 object_000_notation_1 attribute_006_lattstr)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice2-restored-example)
     mizar_lattice2 object_000_notation_1 attribute_006_lattstr)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice2-state)
            mizar_lattice2 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattice2-restored-example)
              mizar_lattice2 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
