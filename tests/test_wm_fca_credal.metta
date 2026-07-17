!(import! &self lib_wm_fca)

; Two raw packets for o1-a share a dependence group.  They are distinct source
; reports but not independent support.  The other true cells have two genuinely
; distinct dependence groups.
(= (credal-toy-state)
   (WMFCAState
     (o1 o2)
     (a b)
     ((WMFCAObservation
        credal-toy o1 a WMTrue
        o1-a-packet-1 source-1 shared-pipeline)
      (WMFCAObservation
        credal-toy o1 a WMTrue
        o1-a-packet-2 source-2 shared-pipeline)
      (WMFCAObservation
        credal-toy o2 a WMTrue
        o2-a-packet-1 source-1 independent-1)
      (WMFCAObservation
        credal-toy o2 a WMTrue
        o2-a-packet-2 source-2 independent-2)
      (WMFCAObservation
        credal-toy o2 b WMTrue
        o2-b-packet-1 source-1 independent-1)
      (WMFCAObservation
        credal-toy o2 b WMTrue
        o2-b-packet-2 source-2 independent-2))))

(= (credal-toy-gates)
   ((WMFCAPositiveDependenceGroupThreshold 1)
    (WMFCAPositiveDependenceGroupThreshold 2)))

(= (credal-toy-loose-concepts)
   ((WMFCAConcept (o1 o2) (a))
    (WMFCAConcept (o2) (a b))))

(= (credal-toy-strict-concepts)
   ((WMFCAConcept (o1 o2) ())
    (WMFCAConcept (o2) (a b))))

(= (credal-toy-lower-concepts)
   ((WMFCAConcept (o2) (a b))))

(= (credal-toy-upper-concepts)
   ((WMFCAConcept (o1 o2) (a))
    (WMFCAConcept (o1 o2) ())
    (WMFCAConcept (o2) (a b))))

(= (credal-toy-unstable-concepts)
   ((WMFCAConcept (o1 o2) (a))
    (WMFCAConcept (o1 o2) ())))

; Raw/source thresholds count both correlated packets.  The dependence-group
; gate does not.
!(assertEqual
   (wm-fca-gate-accepts?
     (credal-toy-state) credal-toy o1 a
     (WMFCAPositiveObservationThreshold 2))
   True)
!(assertEqual
   (wm-fca-gate-accepts?
     (credal-toy-state) credal-toy o1 a
     (WMFCAPositiveSourceThreshold 2))
   True)
!(assertEqual
   (wm-fca-gate-accepts?
     (credal-toy-state) credal-toy o1 a
     (WMFCAPositiveDependenceGroupThreshold 2))
   False)
!(assertEqual
   (wm-fca-gate-accepts?
     (credal-toy-state) credal-toy o2 a
     (WMFCAPositiveDependenceGroupThreshold 2))
   True)

; Each precise gate has its own exact FCA concept family.
!(assertEqual
   (wm-fca-same-set?
     (wm-fca-concepts-with-gate-reference
       (credal-toy-state) credal-toy
       (WMFCAPositiveDependenceGroupThreshold 1))
     (credal-toy-loose-concepts))
   True)
!(assertEqual
   (wm-fca-same-set?
     (wm-fca-concepts-with-gate-reference
       (credal-toy-state) credal-toy
       (WMFCAPositiveDependenceGroupThreshold 2))
     (credal-toy-strict-concepts))
   True)

; Compiling the same evidence gate changes representation, not semantics.
!(assertEqual
   (let $native
        (eval
          (wm-fca-build-index
            (credal-toy-state) credal-toy
            (WMFCAPositiveDependenceGroupThreshold 2)))
     (let $reference
          (eval
            (wm-fca-build-index-reference
              (credal-toy-state) credal-toy
              (WMFCAPositiveDependenceGroupThreshold 2)))
       (wm-fca-same-set?
         (wm-fca-index-columns $native)
         (wm-fca-index-columns $reference))))
   True)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (credal-toy-state) credal-toy
            (WMFCAPositiveDependenceGroupThreshold 1)))
     (wm-fca-same-set?
       (wm-fca-index-concepts-reference $index)
       (credal-toy-loose-concepts)))
   True)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (credal-toy-state) credal-toy
            (WMFCAPositiveDependenceGroupThreshold 2)))
     (wm-fca-same-set?
       (wm-fca-index-concepts-reference $index)
       (credal-toy-strict-concepts)))
   True)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (credal-toy-state) credal-toy
            (WMFCAPositiveDependenceGroupThreshold 2)))
     (wm-fca-index-columns $index))
   ((WMFCAColumn a (o2)) (WMFCAColumn b (o2))))

; Lower means every gate; upper means at least one gate.  The result preserves
; both gate-specific families as an audit trail.
!(assertEqual
   (let $family
        (eval
          (wm-fca-credal-concepts-reference
            (credal-toy-state) credal-toy (credal-toy-gates)))
     (and
       (== (size-atom (wm-fca-credal-gate-families $family)) 2)
       (and
         (wm-fca-same-set?
           (wm-fca-credal-lower $family)
           (credal-toy-lower-concepts))
         (and
           (wm-fca-same-set?
             (wm-fca-credal-upper $family)
             (credal-toy-upper-concepts))
           (wm-fca-same-set?
             (wm-fca-credal-unstable $family)
             (credal-toy-unstable-concepts))))))
   True)

; Singleton collapse recovers the exact gate-specific family on both sides.
!(assertEqual
   (let $exactConcepts
        (eval
          (wm-fca-concepts-with-gate-reference
            (credal-toy-state) credal-toy WMFCAExactStatusGate))
     (let $family
          (eval
            (wm-fca-credal-concepts-reference
              (credal-toy-state) credal-toy (WMFCAExactStatusGate)))
       (and
         (wm-fca-same-set?
           (wm-fca-credal-lower $family) $exactConcepts)
         (and
           (wm-fca-same-set?
             (wm-fca-credal-upper $family) $exactConcepts)
           (== (wm-fca-credal-unstable $family) ())))))
   True)

; Empty gate families are rejected as an explicit typed value, not interpreted
; as a vacuous lower/upper envelope.
!(assertEqual
   (wm-fca-credal-concepts-reference (credal-toy-state) credal-toy ())
   WMFCAEmptyGateFamily)

; Robust, upper-only, and absent concepts have exact interval coordinates.
!(assertEqual
   (let $family
        (eval
          (wm-fca-credal-concepts-reference
            (credal-toy-state) credal-toy (credal-toy-gates)))
     (wm-fca-concept-envelope
       $family (WMFCAConcept (o2) (a b))))
   (WMFCAConceptEnvelope 1 1 1 0))
!(assertEqual
   (let $family
        (eval
          (wm-fca-credal-concepts-reference
            (credal-toy-state) credal-toy (credal-toy-gates)))
     (wm-fca-concept-envelope
       $family (WMFCAConcept (o1 o2) (a))))
   (WMFCAConceptEnvelope 0 1 0.5 1))
!(assertEqual
   (let $family
        (eval
          (wm-fca-credal-concepts-reference
            (credal-toy-state) credal-toy (credal-toy-gates)))
     (wm-fca-concept-envelope
       $family (WMFCAConcept (o1) (b))))
   (WMFCAConceptEnvelope 0 0 0 0))

!(assertEqual
   (wm-fca-query
     (credal-toy-state)
     (WMFCAConceptEnvelopeQuery
       credal-toy
       (credal-toy-gates)
       (WMFCAConcept (o2) (a b))))
   (WMFCAConceptEnvelopeValue
     (WMFCAConceptEnvelope 1 1 1 0)))

; Adding an independent group makes the strict gate accept o1-a; forgetting
; that exact stamp restores the previous rejection.
(= (credal-toy-with-independent-o1-a)
   (wm-fca-remember
     (credal-toy-state)
     (WMFCAObservation
       credal-toy o1 a WMTrue
       o1-a-independent source-3 independent-3)))

!(assertEqual
   (wm-fca-gate-accepts?
     (credal-toy-with-independent-o1-a) credal-toy o1 a
     (WMFCAPositiveDependenceGroupThreshold 2))
   True)
!(assertEqual
   (wm-fca-gate-accepts?
     (wm-fca-forget
       (credal-toy-with-independent-o1-a)
       (WMFCAScopeStamp o1-a-independent))
     credal-toy o1 a
     (WMFCAPositiveDependenceGroupThreshold 2))
   False)

; The native one-pass index compiler and the transparent reference compiler
; agree for every public extraction gate.
(= (credal-toy-index-parity? $state $gate)
   (let $native
        (eval (wm-fca-build-index $state credal-toy $gate))
     (let $reference
          (eval (wm-fca-build-index-reference $state credal-toy $gate))
       (wm-fca-same-set?
         (wm-fca-index-columns $native)
         (wm-fca-index-columns $reference)))))

!(assertEqual
   (credal-toy-index-parity? (credal-toy-state) WMFCAExactStatusGate)
   True)
!(assertEqual
   (credal-toy-index-parity?
     (credal-toy-state) (WMFCAPositiveObservationThreshold 2))
   True)
!(assertEqual
   (credal-toy-index-parity?
     (credal-toy-state) (WMFCAPositiveSourceThreshold 2))
   True)
!(assertEqual
   (credal-toy-index-parity?
     (credal-toy-state) (WMFCAPositiveDependenceGroupThreshold 2))
   True)

; Indeterminate exact status and positive-evidence thresholds intentionally
; differ.  Both native projections remain identical to the reference semantics.
(= (credal-toy-with-conflicts)
   (wm-fca-remember
     (wm-fca-remember
       (credal-toy-state)
       (WMFCAObservation
         credal-toy o2 a WMUnknown
         o2-a-review review-source review-group))
     (WMFCAObservation
       credal-toy o2 b WMFalse
       o2-b-negative negative-source negative-group)))

!(assertEqual
   (credal-toy-index-parity?
     (credal-toy-with-conflicts) WMFCAExactStatusGate)
   True)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (credal-toy-with-conflicts) credal-toy WMFCAExactStatusGate))
     (wm-fca-index-columns $index))
   ((WMFCAColumn a (o1)) (WMFCAColumn b ())))
!(assertEqual
   (credal-toy-index-parity?
     (credal-toy-with-conflicts)
     (WMFCAPositiveObservationThreshold 2))
   True)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (credal-toy-with-conflicts) credal-toy
            (WMFCAPositiveObservationThreshold 2)))
     (wm-fca-index-columns $index))
   ((WMFCAColumn a (o1 o2)) (WMFCAColumn b (o2))))
