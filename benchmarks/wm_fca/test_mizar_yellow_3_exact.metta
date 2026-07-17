!(import! &self ./mizar_yellow_3_context.metta)

; In this complete positive-occurrence article context, every matrix cell is observed rather than missing.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-mizar_yellow_3-state)))
     (size-atom $observations))
   70)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_3-state) mizar_yellow_3 object_000_registration_1 attribute_000_relstr)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_3-state) another-context
     object_000_registration_1 attribute_000_relstr)
   WMMissing)
!(assertEqual
   (wm-fca-closure (wm-fca-mizar_yellow_3-state) mizar_yellow_3 ())
   (attribute_000_relstr))

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
            (wm-fca-mizar_yellow_3-state)
            mizar_yellow_3 WMFCAExactStatusGate))
     (let $intents
          (eval
            (wm-fca-index-closed-intents-native
              $index 1))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (let $basis
              (eval
                (wm-fca-index-canonical-basis-native
                  $index 2 1))
           (let $covers
                (eval
                  (wm-fca-covers-from-intents-native
                    $intents 1 0))
             (and
               (== (wm-fca-index-closure $index ())
                   (attribute_000_relstr))
               (and
                 (== (wm-fca-index-closure $index (attribute_000_relstr)) (attribute_000_relstr))
                 (and
                   (and
                     (== (size-atom $intents) 1)
                     (wm-fca-same-set?
                       $intents (wm-fca-mizar_yellow_3-oracle-intents)))
                   (and
                     (and
                       (== (size-atom $concepts) 1)
                       (wm-fca-same-set?
                         $concepts (wm-fca-mizar_yellow_3-oracle-concepts)))
                     (and
                       (and
                         (== (size-atom $basis) 1)
                         (and
                           (wm-fca-same-set?
                             $basis (wm-fca-mizar_yellow_3-oracle-basis))
                           (wm-fca-index-all-implications-hold?
                             $index $basis)))
                       (and
                         (wm-fca-index-implication-holds? $index (WMFCAImplication () (attribute_000_relstr)))
                         (and
                           True
                           (and
                             (== (size-atom $covers) 0)
                             (wm-fca-same-set?
                               $covers
                               (wm-fca-mizar_yellow_3-oracle-covers)))))))))))))))
   True)

; This full one-attribute relation has no false in-domain cell.  Missingness
; is still tested by querying the same coordinates in another context.


; Revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-mizar_yellow_3-state)
              (wm-fca-mizar_yellow_3-state))))
     (size-atom $observations))
   70)

; Forgetting one true cell exposes missingness; restoring the same observation
; reconstructs the exact original indexed incidence from fresh state.
(= (wm-fca-mizar_yellow_3-without-example)
   (wm-fca-forget
     (wm-fca-mizar_yellow_3-state) (WMFCAScopeStamp mizar_yellow_3-cell-000-000)))
(= (wm-fca-mizar_yellow_3-restored-example)
   (wm-fca-remember
     (wm-fca-mizar_yellow_3-without-example)
     (WMFCAObservation
       mizar_yellow_3 object_000_registration_1 attribute_000_relstr WMTrue
       mizar_yellow_3-cell-000-000 mettapedia-mizar-family-f93a93f7 mizar-yellow-3-extraction)))
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_3-without-example)
     mizar_yellow_3 object_000_registration_1 attribute_000_relstr)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-mizar_yellow_3-restored-example)
     mizar_yellow_3 object_000_registration_1 attribute_000_relstr)
   WMTrue)
!(assertEqual
   (let $original-index
        (eval
          (wm-fca-build-index
            (wm-fca-mizar_yellow_3-state)
            mizar_yellow_3 WMFCAExactStatusGate))
     (let $restored-index
          (eval
            (wm-fca-build-index
              (wm-fca-mizar_yellow_3-restored-example)
              mizar_yellow_3 WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $original-index)
         (wm-fca-index-columns $restored-index))))
   True)
