!(import! &self lib_wm_fca)

(= (wm-fca-binary-test-rows)
   ((WMFCABinaryRow o1 "101")
    (WMFCABinaryRow o2 "010")))

(= (wm-fca-binary-test-columns $stateContext $queryContext $gate)
   (let $rows (eval (wm-fca-binary-test-rows))
     (eval
       (wm-fca-binary-rows-columns-atom
         (o1 o2) (a b c) $rows $stateContext $queryContext $gate))))

(= (wm-fca-binary-test-status $stateContext $queryContext $object $attribute)
   (let $rows (eval (wm-fca-binary-test-rows))
     (eval
       (wm-fca-binary-cell-status-atom
         (o1 o2) (a b c) $rows
         $stateContext $queryContext $object $attribute))))

(= (wm-fca-binary-test-state)
   (WMFCACompleteBinaryState
     (o1 o2) (a b c)
     ((WMFCABinaryRow o1 "101")
      (WMFCABinaryRow o2 "010"))
     ctx source group))

!(assertEqual
   (wm-fca-binary-test-columns ctx ctx WMFCAExactStatusGate)
   ((WMFCAColumn a (o1))
    (WMFCAColumn b (o2))
    (WMFCAColumn c (o1))))
!(assertEqual
   (wm-fca-binary-test-columns
     ctx ctx (WMFCAPositiveObservationThreshold 0))
   ((WMFCAColumn a (o1 o2))
    (WMFCAColumn b (o1 o2))
    (WMFCAColumn c (o1 o2))))
!(assertEqual
   (wm-fca-binary-test-columns
     ctx ctx (WMFCAPositiveObservationThreshold 1))
   ((WMFCAColumn a (o1))
    (WMFCAColumn b (o2))
    (WMFCAColumn c (o1))))
!(assertEqual
   (wm-fca-binary-test-columns
     ctx ctx (WMFCAPositiveObservationThreshold 2))
   ((WMFCAColumn a ())
    (WMFCAColumn b ())
    (WMFCAColumn c ())))
!(assertEqual
   (wm-fca-binary-test-columns
     ctx ctx (WMFCAPositiveSourceThreshold 1))
   ((WMFCAColumn a (o1))
    (WMFCAColumn b (o2))
    (WMFCAColumn c (o1))))
!(assertEqual
   (wm-fca-binary-test-columns
     ctx ctx (WMFCAPositiveDependenceGroupThreshold 1))
   ((WMFCAColumn a (o1))
    (WMFCAColumn b (o2))
    (WMFCAColumn c (o1))))

; Another context has no base packets.  A zero threshold still accepts every
; cell, exactly as it does for an empty ordinary observation state.
!(assertEqual
   (wm-fca-binary-test-columns ctx other WMFCAExactStatusGate)
   ((WMFCAColumn a ())
    (WMFCAColumn b ())
    (WMFCAColumn c ())))
!(assertEqual
   (wm-fca-binary-test-columns
     ctx other (WMFCAPositiveObservationThreshold 0))
   ((WMFCAColumn a (o1 o2))
    (WMFCAColumn b (o1 o2))
    (WMFCAColumn c (o1 o2))))

!(assertEqual
   (wm-fca-binary-test-status ctx ctx o1 a)
   WMTrue)
!(assertEqual
   (wm-fca-binary-test-status ctx ctx o1 b)
   WMFalse)
!(assertEqual
   (wm-fca-binary-test-status ctx other o1 a)
   WMMissing)
!(assertEqual
   (wm-fca-binary-test-status ctx ctx outside a)
   WMMissing)
!(assertEqual
   (wm-fca-state-observation-count (wm-fca-binary-test-state))
   6)
!(assertEqual
   (wm-fca-cell-status (wm-fca-binary-test-state) ctx o2 b)
   WMTrue)
!(assertEqual
   (wm-fca-explain-cell (wm-fca-binary-test-state) ctx o1 b)
   ((WMFCAObservation
      ctx o1 b WMFalse (WMFCAPackedStamp ctx o1 b) source group)))
!(assertEqual
   (wm-fca-index-columns
     (wm-fca-build-index
       (wm-fca-binary-test-state) ctx WMFCAExactStatusGate))
   ((WMFCAColumn a (o1))
    (WMFCAColumn b (o2))
    (WMFCAColumn c (o1))))
!(assertEqual
   (wm-fca-index-extent
     (wm-fca-build-index
       (wm-fca-binary-test-state) ctx WMFCAExactStatusGate)
     (a))
   (o1))
!(assertEqual
   (wm-fca-index-closure
     (wm-fca-build-index
       (wm-fca-binary-test-state) ctx WMFCAExactStatusGate)
     (a))
   (a c))
!(assertEqual
   (wm-fca-batch-queries
     (wm-fca-binary-test-state)
     ctx
     WMFCAExactStatusGate
     (() (a) (b c)))
   ((WMFCABatchQueryResult () (o1 o2) ())
    (WMFCABatchQueryResult (a) (o1) (a c))
    (WMFCABatchQueryResult (b c) () (a b c))))
!(assertEqualToResult
   (wm-fca-binary-query-batch-atom
     (o1) (a) ((WMFCABinaryRow o1 "1"))
     ctx ctx WMFCAExactStatusGate (not-a-query))
   ((Error
      (wm-fca-binary-query-batch-atom
        (o1) (a) ((WMFCABinaryRow o1 "1"))
        ctx ctx WMFCAExactStatusGate (not-a-query))
      MalformedWMFCABatchQuery)))

; Every malformed packed carrier fails explicitly before a column or status is
; emitted.
!(assertEqualToResult
   (wm-fca-binary-rows-columns-atom
     (o1 o2) (a b c) ((WMFCABinaryRow o1 "101"))
     ctx ctx WMFCAExactStatusGate)
   ((Error
      (wm-fca-binary-rows-columns-atom
        (o1 o2) (a b c) ((WMFCABinaryRow o1 "101"))
        ctx ctx WMFCAExactStatusGate)
      WMFCABinaryRowCountMismatch)))
!(assertEqualToResult
   (wm-fca-binary-rows-columns-atom
     (o1) (a) ((not-a-row)) ctx ctx WMFCAExactStatusGate)
   ((Error
      (wm-fca-binary-rows-columns-atom
        (o1) (a) ((not-a-row)) ctx ctx WMFCAExactStatusGate)
      MalformedWMFCABinaryRow)))
!(assertEqualToResult
   (wm-fca-binary-rows-columns-atom
     (o1) (a) ((WMFCABinaryRow wrong "1"))
     ctx ctx WMFCAExactStatusGate)
   ((Error
      (wm-fca-binary-rows-columns-atom
        (o1) (a) ((WMFCABinaryRow wrong "1"))
        ctx ctx WMFCAExactStatusGate)
      WMFCABinaryRowObjectMismatch)))
!(assertEqualToResult
   (wm-fca-binary-rows-columns-atom
     (o1) (a b) ((WMFCABinaryRow o1 "1"))
     ctx ctx WMFCAExactStatusGate)
   ((Error
      (wm-fca-binary-rows-columns-atom
        (o1) (a b) ((WMFCABinaryRow o1 "1"))
        ctx ctx WMFCAExactStatusGate)
      WMFCABinaryRowWidthMismatch)))
!(assertEqualToResult
   (wm-fca-binary-rows-columns-atom
     (o1) (a) ((WMFCABinaryRow o1 "x"))
     ctx ctx WMFCAExactStatusGate)
   ((Error
      (wm-fca-binary-rows-columns-atom
        (o1) (a) ((WMFCABinaryRow o1 "x"))
        ctx ctx WMFCAExactStatusGate)
      InvalidWMFCABinaryCell)))
!(assertEqualToResult
   (wm-fca-binary-rows-columns-atom
     (o1) (a) ((WMFCABinaryRow o1 "1")) ctx ctx UnsupportedGate)
   ((Error
      (wm-fca-binary-rows-columns-atom
        (o1) (a) ((WMFCABinaryRow o1 "1")) ctx ctx UnsupportedGate)
      UnsupportedWMFCAExtractionGate)))
!(assertEqualToResult
   (wm-fca-binary-rows-columns-atom
     (o1) (a) ((WMFCABinaryRow o1 "1"))
     ctx ctx (WMFCAPositiveSourceThreshold threshold))
   ((Error
      (wm-fca-binary-rows-columns-atom
        (o1) (a) ((WMFCABinaryRow o1 "1"))
        ctx ctx (WMFCAPositiveSourceThreshold threshold))
      NumericWMFCAThresholdExpected)))
