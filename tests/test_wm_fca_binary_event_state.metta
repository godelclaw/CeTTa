!(import! &self lib_wm_fca)

(= (wm-fca-event-base)
   (WMFCACompleteBinaryState
     (o1 o2) (a b)
     ((WMFCABinaryRow o1 "10")
      (WMFCABinaryRow o2 "11"))
     ctx s0 g0))

(= (wm-fca-event-base-o1-a)
   (WMFCAObservation
     ctx o1 a WMTrue (WMFCAPackedStamp ctx o1 a) s0 g0))

(= (wm-fca-event-conflict)
   (WMFCAObservation ctx o1 a WMFalse conflict-stamp s1 g1))

(= (wm-fca-event-extra-positive)
   (WMFCAObservation ctx o1 a WMTrue positive-stamp s1 g1))

(= (wm-fca-event-foreign)
   (WMFCAObservation other o1 a WMTrue foreign-stamp sx gx))

(= (wm-fca-event-forgotten)
   (wm-fca-forget
     (wm-fca-event-base)
     (WMFCAScopeStamp (WMFCAPackedStamp ctx o1 a))))

(= (wm-fca-event-restored)
   (wm-fca-remember
     (wm-fca-event-forgotten)
     (wm-fca-event-base-o1-a)))

(= (wm-fca-event-forget-then-false)
   (wm-fca-remember
     (wm-fca-forget
       (wm-fca-event-base) (WMFCAScopeCell ctx o1 a))
     (wm-fca-event-conflict)))

(= (wm-fca-event-false-then-forget)
   (wm-fca-forget
     (wm-fca-remember
       (wm-fca-event-base) (wm-fca-event-conflict))
     (WMFCAScopeCell ctx o1 a)))

(= (wm-fca-event-supported)
   (wm-fca-remember
     (wm-fca-event-base) (wm-fca-event-extra-positive)))

(= (wm-fca-event-conflicted)
   (wm-fca-remember
     (wm-fca-event-base) (wm-fca-event-conflict)))

(= (wm-fca-event-fresh-forget-then-false)
   (WMFCAState
     (o1 o2) (a b)
     ((WMFCAObservation ctx o1 a WMFalse conflict-stamp s1 g1)
      (WMFCAObservation
        ctx o1 b WMFalse (WMFCAPackedStamp ctx o1 b) s0 g0)
      (WMFCAObservation
        ctx o2 a WMTrue (WMFCAPackedStamp ctx o2 a) s0 g0)
      (WMFCAObservation
        ctx o2 b WMTrue (WMFCAPackedStamp ctx o2 b) s0 g0))))

; Base forgetting exposes missingness without expanding the complete matrix.
!(assertEqual
   (wm-fca-state-observation-count (wm-fca-event-base))
   4)
!(assertEqual
   (wm-fca-state-observation-count (wm-fca-event-forgotten))
   3)
!(assertEqual
   (wm-fca-cell-status (wm-fca-event-forgotten) ctx o1 a)
   WMMissing)
!(assertEqual
   (wm-fca-explain-cell (wm-fca-event-forgotten) ctx o1 a)
   ())

; Remembering the exact packed packet restores it once, not twice.
!(assertEqual
   (wm-fca-state-observation-count (wm-fca-event-restored))
   4)
!(assertEqual
   (wm-fca-cell-status (wm-fca-event-restored) ctx o1 a)
   WMTrue)
!(assertEqual
   (wm-fca-explain-cell (wm-fca-event-restored) ctx o1 a)
   ((WMFCAObservation
      ctx o1 a WMTrue (WMFCAPackedStamp ctx o1 a) s0 g0)))

; Ordered event replay distinguishes forget-then-remember from the reverse.
!(assertEqual
   (wm-fca-cell-status (wm-fca-event-forget-then-false) ctx o1 a)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status (wm-fca-event-false-then-forget) ctx o1 a)
   WMMissing)
!(assertEqual
   (wm-fca-state-observation-count (wm-fca-event-forget-then-false))
   4)
!(assertEqual
   (wm-fca-state-observation-count (wm-fca-event-false-then-forget))
   3)

; Conflicting evidence stays visible; corroborating provenance changes the
; observation/source/dependence-group gates without changing exact truth.
!(assertEqual
   (wm-fca-cell-status (wm-fca-event-conflicted) ctx o1 a)
   WMUnknown)
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index
       (wm-fca-event-conflicted) ctx WMFCAExactStatusGate))
   ((WMFCAColumn a (o2)) (WMFCAColumn b (o2))))
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index
       (wm-fca-event-supported)
       ctx (WMFCAPositiveObservationThreshold 2)))
   ((WMFCAColumn a (o1)) (WMFCAColumn b ())))
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index
       (wm-fca-event-supported)
       ctx (WMFCAPositiveSourceThreshold 2)))
   ((WMFCAColumn a (o1)) (WMFCAColumn b ())))
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index
       (wm-fca-event-supported)
       ctx (WMFCAPositiveDependenceGroupThreshold 2)))
   ((WMFCAColumn a (o1)) (WMFCAColumn b ())))
!(assertEqual
   (wm-fca-explain-cell (wm-fca-event-supported) ctx o1 a)
   ((WMFCAObservation
      ctx o1 a WMTrue (WMFCAPackedStamp ctx o1 a) s0 g0)
    (WMFCAObservation ctx o1 a WMTrue positive-stamp s1 g1)))

; Repeated identical provenance is idempotent.
!(assertEqual
   (wm-fca-state-observation-count
     (wm-fca-remember
       (wm-fca-event-supported) (wm-fca-event-extra-positive)))
   5)

; Incremental exact extraction equals a fresh surviving-observation state.
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index
       (wm-fca-event-forget-then-false) ctx WMFCAExactStatusGate))
   (wm-fca-index-columns
     (wm-fca-build-index
       (wm-fca-event-fresh-forget-then-false) ctx WMFCAExactStatusGate)))
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-event-forget-then-false)
     ctx WMFCAExactStatusGate (() (a) (b)))
   ((WMFCABatchQueryResult () (o1 o2) ())
    (WMFCABatchQueryResult (a) (o2) (a b))
    (WMFCABatchQueryResult (b) (o2) (a b))))

; A revision is one immutable batch event and preserves foreign-context facts.
!(assertEqual
   (let $revised
        (eval
          (wm-fca-revise
            (wm-fca-event-base)
            (WMFCAState
              (o1 o2) (a b)
              ((WMFCAObservation ctx o1 a WMFalse conflict-stamp s1 g1)
               (WMFCAObservation other o1 a WMTrue foreign-stamp sx gx)))))
     (and
       (let $events (eval (wm-fca-state-events $revised))
         (== (size-atom $events) 1))
       (and
         (== (wm-fca-cell-status $revised ctx o1 a) WMUnknown)
         (== (wm-fca-cell-status $revised other o1 a) WMTrue))))
   True)
!(assertEqual
   (wm-fca-revise
     (wm-fca-event-base)
     (WMFCAState (o1 o2 o3) (a b) ()))
   (WMFCARevisionDomainMismatch (o1 o2) (a b) (o1 o2 o3) (a b)))

; Every public forgetting scope applies to both the packed base and additions.
!(assertEqual
   (wm-fca-state-observation-count
     (wm-fca-forget (wm-fca-event-base) (WMFCAScopeSource s0)))
   0)
!(assertEqual
   (wm-fca-state-observation-count
     (wm-fca-forget
       (wm-fca-event-base) (WMFCAScopeDependenceGroup g0)))
   0)
!(assertEqual
   (wm-fca-state-observation-count
     (wm-fca-forget (wm-fca-event-base) (WMFCAScopeContext ctx)))
   0)
!(assertEqual
   (wm-fca-state-observation-count
     (wm-fca-forget (wm-fca-event-base) (WMFCAScopeCell ctx o1 a)))
   3)

; Empty finite domains remain valid, bounded states.  A foreign observation is
; retained for explanation without becoming an incidence in the empty domain.
!(assertEqual
   (wm-fca-binary-event-observation-count-atom
     () () () ctx s0 g0 ())
   0)
!(assertEqual
   (wm-fca-binary-event-query-batch-atom
     () () () ctx s0 g0 () ctx WMFCAExactStatusGate (()))
   ((WMFCABatchQueryResult () () ())))
!(assertEqual
   (wm-fca-binary-event-observation-count-atom
     () () () ctx s0 g0
     ((WMFCARememberEvent
        (WMFCAObservation other o1 a WMTrue stamp sx gx))))
   1)
!(assertEqual
   (wm-fca-binary-event-cell-evidence-atom
     () () () ctx s0 g0
     ((WMFCARememberEvent
        (WMFCAObservation other o1 a WMTrue stamp sx gx)))
     other o1 a)
   ((WMFCAObservation other o1 a WMTrue stamp sx gx)))

; Malformed event, scope, and observation carriers fail explicitly.
!(assertEqualToResult
   (wm-fca-binary-event-observation-count-atom
     (o1) (a) ((WMFCABinaryRow o1 "1")) ctx s0 g0 (not-an-event))
   ((Error
      (wm-fca-binary-event-observation-count-atom
        (o1) (a) ((WMFCABinaryRow o1 "1")) ctx s0 g0 (not-an-event))
      MalformedWMFCAEvent)))
!(assertEqualToResult
   (wm-fca-binary-event-observation-count-atom
     (o1) (a) ((WMFCABinaryRow o1 "1")) ctx s0 g0
     ((WMFCAForgetEvent NotAScope)))
   ((Error
      (wm-fca-binary-event-observation-count-atom
        (o1) (a) ((WMFCABinaryRow o1 "1")) ctx s0 g0
        ((WMFCAForgetEvent NotAScope)))
      MalformedWMFCAScope)))
!(assertEqualToResult
   (wm-fca-binary-event-observation-count-atom
     (o1) (a) ((WMFCABinaryRow o1 "1")) ctx s0 g0
     ((WMFCARememberEvent
        (WMFCAObservation ctx o1 a Invalid stamp s1 g1))))
   ((Error
      (wm-fca-binary-event-observation-count-atom
        (o1) (a) ((WMFCABinaryRow o1 "1")) ctx s0 g0
        ((WMFCARememberEvent
           (WMFCAObservation ctx o1 a Invalid stamp s1 g1))))
      MalformedWMFCAObservation)))
