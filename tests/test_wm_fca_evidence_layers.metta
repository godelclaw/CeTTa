!(import! &self lib_wm_fca)

(= (layer-one)
   (WMFCAEvidenceLayer
     layer-1 ctx source-1 shared-group
     ((WMFCAStatusRow o1 "10.")
      (WMFCAStatusRow o2 "011"))))

(= (layer-two)
   (WMFCAEvidenceLayer
     layer-2 ctx source-2 shared-group
     ((WMFCAStatusRow o1 "1u0")
      (WMFCAStatusRow o2 ".11"))))

(= (layer-three)
   (WMFCAEvidenceLayer
     layer-3 ctx source-3 independent-group
     ((WMFCAStatusRow o1 "...")
      (WMFCAStatusRow o2 ".11"))))

(= (layer-other-context)
   (WMFCAEvidenceLayer
     layer-4 other source-4 other-group
     ((WMFCAStatusRow o1 "010")
      (WMFCAStatusRow o2 "..."))))

(= (layer-state)
   (WMFCAPackedEvidenceState
     (o1 o2) (a b c)
     ((layer-one) (layer-two) (layer-three) (layer-other-context))))

; Four-valued partial observations remain distinct before extraction.
!(assertEqual (wm-fca-state-observation-count (layer-state)) 15)
!(assertEqual (wm-fca-cell-status (layer-state) ctx o1 a) WMTrue)
!(assertEqual (wm-fca-cell-status (layer-state) ctx o1 b) WMUnknown)
!(assertEqual (wm-fca-cell-status (layer-state) ctx o1 c) WMFalse)
!(assertEqual (wm-fca-cell-status (layer-state) other o1 b) WMTrue)
!(assertEqual (wm-fca-cell-status (layer-state) other o2 a) WMMissing)

; Cell explanations synthesize stable, provenance-bearing layer stamps.
!(assertEqual
   (wm-fca-explain-cell (layer-state) ctx o1 a)
   ((WMFCAObservation
      ctx o1 a WMTrue (WMFCALayerStamp layer-1 o1 a)
      source-1 shared-group)
    (WMFCAObservation
      ctx o1 a WMTrue (WMFCALayerStamp layer-2 o1 a)
      source-2 shared-group)))

; Exact, raw/source, and dependence-aware projections are intentionally
; different: two sources in one group do not masquerade as two independent
; groups.
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index (layer-state) ctx WMFCAExactStatusGate))
   ((WMFCAColumn a (o1))
    (WMFCAColumn b (o2))
    (WMFCAColumn c (o2))))
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index
       (layer-state) ctx (WMFCAPositiveObservationThreshold 2)))
   ((WMFCAColumn a (o1))
    (WMFCAColumn b (o2))
    (WMFCAColumn c (o2))))
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index
       (layer-state) ctx (WMFCAPositiveSourceThreshold 2)))
   ((WMFCAColumn a (o1))
    (WMFCAColumn b (o2))
    (WMFCAColumn c (o2))))
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index
       (layer-state) ctx
       (WMFCAPositiveDependenceGroupThreshold 2)))
   ((WMFCAColumn a ())
    (WMFCAColumn b (o2))
    (WMFCAColumn c (o2))))

; Fixed-query FCA derivation stays native and bounded.
!(assertEqual
   (wm-fca-batch-queries
     (layer-state) ctx WMFCAExactStatusGate (() (a) (b) (c)))
   ((WMFCABatchQueryResult () (o1 o2) ())
    (WMFCABatchQueryResult (a) (o1) (a))
    (WMFCABatchQueryResult (b) (o2) (b c))
    (WMFCABatchQueryResult (c) (o2) (b c))))

; Repeating an identical provenance layer is idempotent.
!(assertEqual
   (let $layers (eval ((layer-one) (layer-two) (layer-one)))
     (wm-fca-evidence-layer-observation-count-atom
       (o1 o2) (a b c) $layers))
   10)

; Empty universes and no evidence form a valid finite context.
!(assertEqual
   (wm-fca-evidence-layer-observation-count-atom () () ())
   0)
!(assertEqual
   (wm-fca-evidence-layer-query-batch-atom
     () () () ctx WMFCAExactStatusGate (()))
   ((WMFCABatchQueryResult () () ())))

; Conflicting provenance identities and malformed rows fail loudly.
!(assertEqualToResult
   (wm-fca-evidence-layer-observation-count-atom
     (o1 o2) (a b c)
     ((WMFCAEvidenceLayer
        layer-1 ctx source-1 shared-group
        ((WMFCAStatusRow o1 "10.")
         (WMFCAStatusRow o2 "011")))
      (WMFCAEvidenceLayer
        layer-1 ctx source-1 shared-group
        ((WMFCAStatusRow o1 "11.")
         (WMFCAStatusRow o2 "011")))))
   ((Error
      (wm-fca-evidence-layer-observation-count-atom
        (o1 o2) (a b c)
        ((WMFCAEvidenceLayer
           layer-1 ctx source-1 shared-group
           ((WMFCAStatusRow o1 "10.")
            (WMFCAStatusRow o2 "011")))
         (WMFCAEvidenceLayer
           layer-1 ctx source-1 shared-group
           ((WMFCAStatusRow o1 "11.")
            (WMFCAStatusRow o2 "011")))))
      WMFCAConflictingEvidenceLayerIdentity)))
!(assertEqualToResult
   (wm-fca-evidence-layer-observation-count-atom
     (o1 o2) (a b c)
     ((WMFCAEvidenceLayer
        malformed ctx source group
        ((WMFCAStatusRow o1 "10.")
         (WMFCAStatusRow o2 "01")))))
   ((Error
      (wm-fca-evidence-layer-observation-count-atom
        (o1 o2) (a b c)
        ((WMFCAEvidenceLayer
           malformed ctx source group
           ((WMFCAStatusRow o1 "10.")
            (WMFCAStatusRow o2 "01")))))
      WMFCAStatusRowWidthMismatch)))
!(assertEqualToResult
   (wm-fca-evidence-layer-observation-count-atom
     (o1) (a b c)
     ((WMFCAEvidenceLayer
        invalid ctx source group
        ((WMFCAStatusRow o1 "1x.")))))
   ((Error
      (wm-fca-evidence-layer-observation-count-atom
        (o1) (a b c)
        ((WMFCAEvidenceLayer
           invalid ctx source group
           ((WMFCAStatusRow o1 "1x.")))))
      InvalidWMFCAStatusCell)))
!(assertEqualToResult
   (wm-fca-evidence-layer-observation-count-atom
     (o1 o2) (a) ((WMFCAEvidenceLayer malformed ctx source group (bad-row))))
   ((Error
      (wm-fca-evidence-layer-observation-count-atom
        (o1 o2) (a)
        ((WMFCAEvidenceLayer malformed ctx source group (bad-row))))
      WMFCAEvidenceLayerRowCountMismatch)))
