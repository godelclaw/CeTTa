; One native pass compiles provenance-bearing observations into ordered columns.
(= (wm-fca-index-test-observations)
   ((WMFCAObservation c o1 a WMTrue p1 source-1 shared)
    (WMFCAObservation c o1 a WMTrue p2 source-2 shared)
    (WMFCAObservation c o2 a WMTrue p3 source-1 group-1)
    (WMFCAObservation c o2 a WMTrue p4 source-1 group-2)
    (WMFCAObservation c o2 a WMUnknown review reviewer review-group)
    (WMFCAObservation c o2 b WMTrue p5 source-1 group-1)
    (WMFCAObservation c o2 b WMFalse n1 source-2 group-2)
    (WMFCAObservation other o1 b WMTrue ignored source-3 group-3)
    (WMFCAObservation c outside b WMTrue outside-packet source-4 group-4)))

(= (wm-fca-index-test-columns $gate)
   (let $observations (eval (wm-fca-index-test-observations))
     (eval
       (wm-fca-index-columns-atom
         (o1 o2) (a b) $observations c $gate))))

; Exact status rejects both explicit conflicts and unknown evidence.
!(assertEqual
   (wm-fca-index-test-columns WMFCAExactStatusGate)
   ((WMFCAColumn a (o1)) (WMFCAColumn b ())))

; Raw packets, distinct sources, and distinct dependence groups are genuinely
; different projections of the same primary evidence state.
!(assertEqual
   (wm-fca-index-test-columns (WMFCAPositiveObservationThreshold 2))
   ((WMFCAColumn a (o1 o2)) (WMFCAColumn b ())))
!(assertEqual
   (wm-fca-index-test-columns (WMFCAPositiveSourceThreshold 2))
   ((WMFCAColumn a (o1)) (WMFCAColumn b ())))
!(assertEqual
   (wm-fca-index-test-columns (WMFCAPositiveDependenceGroupThreshold 2))
   ((WMFCAColumn a (o2)) (WMFCAColumn b ())))

; A zero positive-evidence threshold accepts even cells with no packet, exactly
; matching the public threshold predicate.  Empty universes remain valid.
!(assertEqual
   (wm-fca-index-test-columns (WMFCAPositiveObservationThreshold 0))
   ((WMFCAColumn a (o1 o2)) (WMFCAColumn b (o1 o2))))
!(assertEqual
   (wm-fca-index-columns-atom () () () c WMFCAExactStatusGate)
   ())

; Invalid gates and malformed observations fail explicitly.
!(assertEqualToResult
   (wm-fca-index-columns-atom (o1) (a) () c UnsupportedGate)
   ((Error
      (wm-fca-index-columns-atom (o1) (a) () c UnsupportedGate)
      UnsupportedWMFCAExtractionGate)))
!(assertEqualToResult
   (wm-fca-index-columns-atom
     (o1) (a) () c (WMFCAPositiveObservationThreshold threshold))
   ((Error
      (wm-fca-index-columns-atom
        (o1) (a) () c (WMFCAPositiveObservationThreshold threshold))
      NumericWMFCAThresholdExpected)))
!(assertEqualToResult
   (wm-fca-index-columns-atom
     (o1) (a) ((not-an-observation)) c WMFCAExactStatusGate)
   ((Error
      (wm-fca-index-columns-atom
        (o1) (a) ((not-an-observation)) c WMFCAExactStatusGate)
      MalformedWMFCAObservation)))
!(assertEqualToResult
   (wm-fca-index-columns-atom
     (o1) (a)
     ((WMFCAObservation c o1 a WMMissing p source group))
     c WMFCAExactStatusGate)
   ((Error
      (wm-fca-index-columns-atom
        (o1) (a)
        ((WMFCAObservation c o1 a WMMissing p source group))
        c WMFCAExactStatusGate)
      InvalidWMFCAObservationStatus)))
