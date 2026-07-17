!(import! &self ./mizar_lattice4_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_lattice4-state)))
     (size-atom $observations))
   1060)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-state) mizar_lattice4 object_000_theorem_3 attribute_009_l1)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-state) mizar_lattice4 object_000_theorem_3 attribute_000_bl)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-state) another-context
     object_000_theorem_3 attribute_000_bl)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_lattice4-state) mizar_lattice4 (attribute_009_l1))
   (attribute_009_l1 attribute_010_l2))

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
            (wm-fca-mizar_lattice4-state)
            mizar_lattice4 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 62))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 167 105))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 62 136))
             (and
               (== (wm-fca-index-closure $index (attribute_009_l1))
                   (attribute_009_l1 attribute_010_l2))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_bl)) (attribute_000_bl))
                 (and
                   (and
                     (== (size-atom $intents) 62)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_lattice4-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 62)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_lattice4-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 105)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_lattice4-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_009_l1) (attribute_010_l2)))
                         (and
                           (not (wm-fca-index-implication-holds? $index (WMFCAImplication (attribute_000_bl) (attribute_001_closedsubset))))
                           (and
                             (== (size-atom $covers) 136)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_lattice4-oracle-covers)))))))))))))))
   True)

; Explanations retain the exact negative observation and its provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-mizar_lattice4-state) mizar_lattice4 object_000_theorem_3 attribute_000_bl)
   ((WMFCAObservation
      mizar_lattice4 object_000_theorem_3 attribute_000_bl WMFalse
      mizar_lattice4-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-lattice4-extraction)))


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_lattice4-state)
              (wm-fca-mizar_lattice4-state))))
     (size-atom $observations))
   1060)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_lattice4-without-example)
   (wm-fca-forget
     (wm-fca-mizar_lattice4-state) (WMFCAScopeStamp mizar_lattice4-cell-000-009)))
(= (wm-fca-mizar_lattice4-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_lattice4-without-example)
     (WMFCAObservation
       mizar_lattice4 object_000_theorem_3 attribute_009_l1 WMTrue
       mizar_lattice4-cell-000-009 mettapedia-mizar-family-f93a93f7 mizar-lattice4-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-without-example)
     mizar_lattice4 object_000_theorem_3 attribute_009_l1)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_lattice4-restored-example)
     mizar_lattice4 object_000_theorem_3 attribute_009_l1)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_lattice4-state)
            mizar_lattice4 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_lattice4-restored-example)
              mizar_lattice4 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
