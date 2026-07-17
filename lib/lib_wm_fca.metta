; Finite formal-context world models for CeTTa.
;
; The state is primary.  Incidence observations retain their source, dependence
; group, and provenance stamp.  Classical FCA is obtained only by the explicit
; crisp projection `wm-fca-crisp-cell?`; false, unknown, and missing remain
; distinct in the underlying query result.
;
; This module keeps a transparent exact/reference backend alongside native,
; fail-loud indexed operations for larger finite contexts.  The powerset
; enumerator remains a small-context oracle; scalable intent and canonical-basis
; enumeration use bounded Next-Closure variants over the same public state.

!(import! &self list)

; ---------------------------------------------------------------------------
; Typed public carriers
; ---------------------------------------------------------------------------

(: WMFCAStatus Type)
(: WMTrue WMFCAStatus)
(: WMFalse WMFCAStatus)
(: WMUnknown WMFCAStatus)
(: WMMissing WMFCAStatus)

(: WMFCAObservationType Type)
(: WMFCAObservation
   (-> Atom Atom Atom WMFCAStatus Atom Atom Atom WMFCAObservationType))

(: WMFCAStateType Type)
(: WMFCAState (-> Expression Expression Expression WMFCAStateType))

; Complete binary matrices are a compact immutable base state.  One aligned
; row replaces thousands of eagerly materialized per-cell terms while source
; and dependence-group provenance remain attached to the base observation set.
(: WMFCABinaryRowType Type)
(: WMFCABinaryRow (-> Atom String WMFCABinaryRowType))
(: WMFCAPackedStampType Type)
(: WMFCAPackedStamp (-> Atom Atom Atom WMFCAPackedStampType))
(: WMFCACompleteBinaryState
   (-> Expression Expression Expression Atom Atom Atom WMFCAStateType))
(: WMFCACompleteBinaryEventState
   (-> Expression Expression Expression Atom Atom Atom Expression
       WMFCAStateType))

; A packed evidence layer is a provenance-distinct, four-valued partial matrix.
; Status rows use 1 / 0 / u / . for true / false / unknown / missing.  Several
; layers may share a context while retaining distinct sources and dependence
; groups; the layer identity makes exact duplicate chunks idempotent.
(: WMFCAStatusRowType Type)
(: WMFCAStatusRow (-> Atom String WMFCAStatusRowType))
(: WMFCAEvidenceLayerType Type)
(: WMFCAEvidenceLayer
   (-> Atom Atom Atom Atom Expression WMFCAEvidenceLayerType))
(: WMFCALayerStampType Type)
(: WMFCALayerStamp (-> Atom Atom Atom WMFCALayerStampType))
(: WMFCAPackedEvidenceState
   (-> Expression Expression Expression WMFCAStateType))

(: WMFCAEvidenceType Type)
(: WMFCAEvidence (-> Expression Expression Expression WMFCAEvidenceType))

(: WMFCACellKeyType Type)
(: WMFCACellKey (-> Atom Atom Atom WMFCACellKeyType))

(: WMFCAScope Type)
(: WMFCAScopeStamp (-> Atom WMFCAScope))
(: WMFCAScopeSource (-> Atom WMFCAScope))
(: WMFCAScopeDependenceGroup (-> Atom WMFCAScope))
(: WMFCAScopeContext (-> Atom WMFCAScope))
(: WMFCAScopeCell (-> Atom Atom Atom WMFCAScope))

(: WMFCAEventType Type)
(: WMFCAForgetEvent (-> WMFCAScope WMFCAEventType))
(: WMFCARememberEvent (-> WMFCAObservationType WMFCAEventType))
(: WMFCAReviseEvent (-> Expression WMFCAEventType))

(: WMFCAStateHistoryType Type)
(: WMFCAHistoryUnavailable WMFCAStateHistoryType)
(: WMFCAEventHistory (-> Expression WMFCAStateHistoryType))

(: WMFCAQuery Type)
(: WMFCACellQuery (-> Atom Atom Atom WMFCAQuery))
(: WMFCAExtentQuery (-> Atom Expression WMFCAQuery))
(: WMFCAIntentQuery (-> Atom Expression WMFCAQuery))
(: WMFCAClosureQuery (-> Atom Expression WMFCAQuery))
(: WMFCAConceptsQuery (-> Atom WMFCAQuery))
(: WMFCAExplainCellQuery (-> Atom Atom Atom WMFCAQuery))

(: WMFCAValue Type)
(: WMFCACellValue (-> WMFCAStatus WMFCAEvidenceType WMFCAValue))
(: WMFCAExtentValue (-> Expression WMFCAValue))
(: WMFCAIntentValue (-> Expression WMFCAValue))
(: WMFCAClosureValue (-> Expression WMFCAValue))
(: WMFCAConceptsValue (-> Expression WMFCAValue))
(: WMFCAExplanationValue (-> Expression WMFCAValue))

(: WMFCAConceptType Type)
(: WMFCAConcept (-> Expression Expression WMFCAConceptType))

(: WMFCABatchQueryResultType Type)
(: WMFCABatchQueryResult
   (-> Expression Expression Expression WMFCABatchQueryResultType))

(: WMFCAImplicationType Type)
(: WMFCAImplication (-> Expression Expression WMFCAImplicationType))

(: WMFCACoverType Type)
(: WMFCACover (-> Expression Expression WMFCACoverType))

(: WMFCAGateType Type)
(: WMFCAExactStatusGate WMFCAGateType)
(: WMFCAPositiveObservationThreshold (-> Number WMFCAGateType))
(: WMFCAPositiveSourceThreshold (-> Number WMFCAGateType))
(: WMFCAPositiveDependenceGroupThreshold (-> Number WMFCAGateType))

(: WMFCAGateConceptFamilyType Type)
(: WMFCAGateConceptFamily
   (-> WMFCAGateType Expression WMFCAGateConceptFamilyType))

(: WMFCACredalConceptFamilyType Type)
(: WMFCAEmptyGateFamily WMFCACredalConceptFamilyType)
(: WMFCACredalConceptFamily
   (-> Expression Expression Expression Expression
       WMFCACredalConceptFamilyType))

(: WMFCAConceptEnvelopeType Type)
(: WMFCAConceptEnvelope
   (-> Number Number Number Number WMFCAConceptEnvelopeType))

(: WMFCAColumnType Type)
(: WMFCAColumn (-> Atom Expression WMFCAColumnType))

(: WMFCAIndexType Type)
(: WMFCAIndex
   (-> WMFCAStateType Atom WMFCAGateType Expression WMFCAIndexType))

(: WMFCAIndexCoreType Type)
(: WMFCAIndexCore
   (-> Expression Expression Expression Expression WMFCAIndexCoreType))

(: WMFCAClosureCertificateType Type)
(: WMFCAClosureCertificate
   (-> WMFCAIndexType Expression Expression Expression
       WMFCAClosureCertificateType))

(: WMFCAImplicationCertificateType Type)
(: WMFCAImplicationCertificate
   (-> WMFCAImplicationType WMFCAClosureCertificateType Bool
       WMFCAImplicationCertificateType))

(: WMFCAConceptCertificateType Type)
(: WMFCAConceptCertificate
   (-> WMFCAConceptType WMFCAClosureCertificateType Bool
       WMFCAConceptCertificateType))

(: WMFCALecticStepType Type)
(: WMFCALecticStep (-> Atom Expression WMFCALecticStepType))

(: WMFCALecticBuildType Type)
(: WMFCALecticBuild
   (-> Expression Expression WMFCALecticBuildType))

(: WMFCANextClosedType Type)
(: WMFCANextClosedFound (-> Expression WMFCANextClosedType))
(: WMFCANextClosedNone WMFCANextClosedType)

(: WMFCAClosedEnumerationType Type)
(: WMFCAClosedEnumeration
   (-> Expression Expression Bool WMFCAClosedEnumerationType))

(: WMFCACanonicalBasisQuery (-> Atom WMFCAQuery))
(: WMFCACoversQuery (-> Atom WMFCAQuery))
(: WMFCAGatedConceptsQuery (-> Atom WMFCAGateType WMFCAQuery))
(: WMFCACredalConceptsQuery (-> Atom Expression WMFCAQuery))
(: WMFCAConceptEnvelopeQuery
   (-> Atom Expression WMFCAConceptType WMFCAQuery))
(: WMFCAClosureCertificateQuery
   (-> Atom WMFCAGateType Expression WMFCAQuery))
(: WMFCAImplicationCertificateQuery
   (-> Atom WMFCAGateType WMFCAImplicationType WMFCAQuery))
(: WMFCAConceptCertificateQuery
   (-> Atom WMFCAGateType WMFCAConceptType WMFCAQuery))
(: WMFCACanonicalBasisValue (-> Expression WMFCAValue))
(: WMFCACoversValue (-> Expression WMFCAValue))
(: WMFCAGatedConceptsValue
   (-> WMFCAGateType Expression WMFCAValue))
(: WMFCACredalConceptsValue
   (-> WMFCACredalConceptFamilyType WMFCAValue))
(: WMFCAConceptEnvelopeValue
   (-> WMFCAConceptEnvelopeType WMFCAValue))
(: WMFCAClosureCertificateValue
   (-> WMFCAClosureCertificateType WMFCAValue))
(: WMFCAImplicationCertificateValue
   (-> WMFCAImplicationCertificateType WMFCAValue))
(: WMFCAConceptCertificateValue
   (-> WMFCAConceptCertificateType WMFCAValue))

; ---------------------------------------------------------------------------
; Observation and state projections
; ---------------------------------------------------------------------------

(= (wm-fca-observation-context
     (WMFCAObservation $context $object $attribute $status $stamp $source $group))
   $context)

(= (wm-fca-observation-object
     (WMFCAObservation $context $object $attribute $status $stamp $source $group))
   $object)

(= (wm-fca-observation-attribute
     (WMFCAObservation $context $object $attribute $status $stamp $source $group))
   $attribute)

(= (wm-fca-observation-status
     (WMFCAObservation $context $object $attribute $status $stamp $source $group))
   $status)

(= (wm-fca-observation-stamp
     (WMFCAObservation $context $object $attribute $status $stamp $source $group))
   $stamp)

(= (wm-fca-observation-source
     (WMFCAObservation $context $object $attribute $status $stamp $source $group))
   $source)

(= (wm-fca-observation-dependence-group
     (WMFCAObservation $context $object $attribute $status $stamp $source $group))
   $group)

(= (wm-fca-state-objects (WMFCAState $objects $attributes $observations))
   $objects)

(= (wm-fca-state-attributes (WMFCAState $objects $attributes $observations))
   $attributes)

(= (wm-fca-state-observations (WMFCAState $objects $attributes $observations))
   $observations)

(= (wm-fca-state-objects
     (WMFCACompleteBinaryState
       $objects $attributes $rows $context $source $group))
   $objects)

(= (wm-fca-state-attributes
     (WMFCACompleteBinaryState
       $objects $attributes $rows $context $source $group))
   $attributes)

(= (wm-fca-state-objects
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group $events))
   $objects)

(= (wm-fca-state-attributes
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group $events))
   $attributes)

(= (wm-fca-state-objects
     (WMFCAPackedEvidenceState $objects $attributes $layers))
   $objects)

(= (wm-fca-state-attributes
     (WMFCAPackedEvidenceState $objects $attributes $layers))
   $attributes)

(= (wm-fca-state-layers
     (WMFCAPackedEvidenceState $objects $attributes $layers))
   $layers)

(= (wm-fca-state-events
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group $events))
   $events)

; A snapshot does not pretend to remember an update sequence it was not given.
; Event states retain their immutable operation log explicitly.
(= (wm-fca-state-history
     (WMFCAState $objects $attributes $observations))
   WMFCAHistoryUnavailable)

(= (wm-fca-state-history
     (WMFCACompleteBinaryState
       $objects $attributes $rows $context $source $group))
   WMFCAHistoryUnavailable)

(= (wm-fca-state-history
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group $events))
   (WMFCAEventHistory $events))

(= (wm-fca-state-history
     (WMFCAPackedEvidenceState $objects $attributes $layers))
   WMFCAHistoryUnavailable)

; Count observations without constructing the full cell-level evidence list.
(= (wm-fca-state-observation-count
     (WMFCAState $objects $attributes $observations))
   (size-atom $observations))

(= (wm-fca-state-observation-count
     (WMFCACompleteBinaryState
       $objects $attributes $rows $context $source $group))
   (* (size-atom $objects) (size-atom $attributes)))

(= (wm-fca-state-observation-count
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group $events))
   (wm-fca-binary-event-observation-count-atom
     $objects $attributes $rows $context $source $group $events))

(= (wm-fca-state-observation-count
     (WMFCAPackedEvidenceState $objects $attributes $layers))
   (let $materializedLayers (eval $layers)
     (wm-fca-evidence-layer-observation-count-atom
       $objects $attributes $materializedLayers)))

(= (wm-fca-empty $objects $attributes)
   (WMFCAState $objects $attributes ()))

(= (wm-fca-singleton $objects $attributes $observation)
   (WMFCAState $objects $attributes ($observation)))

; Revision is overlap-aware at the observation identity level: structurally
; identical stamped chunks are idempotent.  Distinct observations, including
; conflicting reports about one cell, remain visible rather than being silently
; overwritten.
(= (wm-fca-revise
     (WMFCAState $leftObjects $leftAttributes $leftObservations)
     (WMFCAState $rightObjects $rightAttributes $rightObservations))
   (if (and (== $leftObjects $rightObjects)
            (== $leftAttributes $rightAttributes))
       (let $merged (eval (union-atom $leftObservations $rightObservations))
         (let $deduplicated (eval (unique-atom $merged))
           (WMFCAState
             $leftObjects
             $leftAttributes
             $deduplicated)))
       (WMFCARevisionDomainMismatch
         $leftObjects $leftAttributes $rightObjects $rightAttributes)))

(= (wm-fca-remember
     (WMFCAState $objects $attributes $observations)
     $observation)
   (wm-fca-revise
     (WMFCAState $objects $attributes $observations)
     (wm-fca-singleton $objects $attributes $observation)))

; Packed updates are immutable event states.  Events are stored newest-first so
; each transition is a bounded native cons; the grounded snapshot replay walks
; them oldest-first to preserve the public operation order.
(= (wm-fca-revise
     (WMFCACompleteBinaryState
       $objects $attributes $rows $context $source $group)
     (WMFCAState $rightObjects $rightAttributes $rightObservations))
   (if (and (== $objects $rightObjects)
            (== $attributes $rightAttributes))
       (let $materializedObservations (eval $rightObservations)
         (WMFCACompleteBinaryEventState
           $objects $attributes $rows $context $source $group
           ((WMFCAReviseEvent $materializedObservations))))
       (WMFCARevisionDomainMismatch
         $objects $attributes $rightObjects $rightAttributes)))

(= (wm-fca-revise
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group $events)
     (WMFCAState $rightObjects $rightAttributes $rightObservations))
   (if (and (== $objects $rightObjects)
            (== $attributes $rightAttributes))
       (let $materializedObservations (eval $rightObservations)
         (let $nextEvents
              (eval
                (cons-atom
                  (WMFCAReviseEvent $materializedObservations) $events))
           (WMFCACompleteBinaryEventState
             $objects $attributes $rows $context $source $group $nextEvents)))
       (WMFCARevisionDomainMismatch
         $objects $attributes $rightObjects $rightAttributes)))

(= (wm-fca-remember
     (WMFCACompleteBinaryState
       $objects $attributes $rows $context $source $group)
     $observation)
   (let $materializedObservation (eval $observation)
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group
       ((WMFCARememberEvent $materializedObservation)))))

(= (wm-fca-remember
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group $events)
     $observation)
   (let $materializedObservation (eval $observation)
     (let $nextEvents
          (eval
            (cons-atom
              (WMFCARememberEvent $materializedObservation) $events))
       (WMFCACompleteBinaryEventState
         $objects $attributes $rows $context $source $group $nextEvents))))

; ---------------------------------------------------------------------------
; Scoped forgetting
; ---------------------------------------------------------------------------

(= (wm-fca-observation-in-scope?
     (WMFCAObservation $context $object $attribute $status $stamp $source $group)
     (WMFCAScopeStamp $wanted))
   (== $stamp $wanted))

(= (wm-fca-observation-in-scope?
     (WMFCAObservation $context $object $attribute $status $stamp $source $group)
     (WMFCAScopeSource $wanted))
   (== $source $wanted))

(= (wm-fca-observation-in-scope?
     (WMFCAObservation $context $object $attribute $status $stamp $source $group)
     (WMFCAScopeDependenceGroup $wanted))
   (== $group $wanted))

(= (wm-fca-observation-in-scope?
     (WMFCAObservation $context $object $attribute $status $stamp $source $group)
     (WMFCAScopeContext $wanted))
   (== $context $wanted))

(= (wm-fca-observation-in-scope?
     (WMFCAObservation $context $object $attribute $status $stamp $source $group)
     (WMFCAScopeCell $wantedContext $wantedObject $wantedAttribute))
   (and (== $context $wantedContext)
        (and (== $object $wantedObject)
             (== $attribute $wantedAttribute))))

(= (wm-fca-forget (WMFCAState $objects $attributes $observations) $scope)
   (let $keptObservations
        (eval
          (collect
            (let $observation (superpose $observations)
              (if (wm-fca-observation-in-scope? $observation $scope)
                  Empty
                  $observation))))
     (WMFCAState $objects $attributes $keptObservations)))

(= (wm-fca-forget
     (WMFCACompleteBinaryState
       $objects $attributes $rows $context $source $group)
     $scope)
   (WMFCACompleteBinaryEventState
     $objects $attributes $rows $context $source $group
     ((WMFCAForgetEvent $scope))))

(= (wm-fca-forget
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group $events)
     $scope)
   (let $nextEvents
        (eval (cons-atom (WMFCAForgetEvent $scope) $events))
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $context $source $group $nextEvents)))

; ---------------------------------------------------------------------------
; Cell extraction, four-valued view, and explanation
; ---------------------------------------------------------------------------

(= (wm-fca-explain-cell
   (WMFCAState $objects $attributes $observations)
     $context $object $attribute)
   (collect
     (let $observation (superpose $observations)
       (wm-fca-explain-cell-select
         $context $object $attribute $observation))))

(= (wm-fca-explain-cell
     (WMFCACompleteBinaryState
       $objects $attributes $rows $stateContext $source $group)
     $context $object $attribute)
   (let $status
        (eval
          (wm-fca-binary-cell-status-atom
            $objects $attributes $rows $stateContext
            $context $object $attribute))
     (if (== $status WMMissing)
         ()
         ((WMFCAObservation
            $context $object $attribute $status
            (WMFCAPackedStamp $context $object $attribute)
            $source $group)))))

(= (wm-fca-explain-cell
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $stateContext $source $group $events)
     $context $object $attribute)
   (wm-fca-binary-event-cell-evidence-atom
     $objects $attributes $rows $stateContext $source $group $events
     $context $object $attribute))

(= (wm-fca-explain-cell
     (WMFCAPackedEvidenceState $objects $attributes $layers)
     $context $object $attribute)
   (let $materializedLayers (eval $layers)
     (wm-fca-evidence-layer-cell-evidence-atom
       $objects $attributes $materializedLayers
       $context $object $attribute)))

(= (wm-fca-explain-cell-select $context $object $attribute
     (WMFCAObservation
       $seenContext $seenObject $seenAttribute
       $status $stamp $source $group))
   (if (and (== $seenContext $context)
            (and (== $seenObject $object)
                 (== $seenAttribute $attribute)))
       (WMFCAObservation
         $seenContext $seenObject $seenAttribute
         $status $stamp $source $group)
       Empty))

(= (wm-fca-observations-with-status $observations $wantedStatus)
   (collect
     (let $observation (superpose $observations)
       (wm-fca-status-select $wantedStatus $observation))))

(= (wm-fca-status-select $wantedStatus
     (WMFCAObservation
       $context $object $attribute $seenStatus $stamp $source $group))
   (if (== $seenStatus $wantedStatus)
       (WMFCAObservation
         $context $object $attribute $seenStatus $stamp $source $group)
       Empty))

(= (wm-fca-extract-cell $state $context $object $attribute)
   (let $matching (wm-fca-explain-cell $state $context $object $attribute)
     (let $positive
          (eval (wm-fca-observations-with-status $matching WMTrue))
       (let $negative
            (eval (wm-fca-observations-with-status $matching WMFalse))
         (let $unknown
              (eval (wm-fca-observations-with-status $matching WMUnknown))
           (WMFCAEvidence $positive $negative $unknown))))))

(= (wm-fca-evidence-positive (WMFCAEvidence $positive $negative $unknown))
   $positive)

(= (wm-fca-evidence-negative (WMFCAEvidence $positive $negative $unknown))
   $negative)

(= (wm-fca-evidence-unknown (WMFCAEvidence $positive $negative $unknown))
   $unknown)

(= (wm-fca-evidence-status (WMFCAEvidence $positive $negative $unknown))
   (if (> (size-atom $unknown) 0)
       WMUnknown
       (if (and (> (size-atom $positive) 0) (> (size-atom $negative) 0))
           WMUnknown
           (if (> (size-atom $positive) 0)
               WMTrue
               (if (> (size-atom $negative) 0)
                   WMFalse
                   WMMissing)))))

; Incidence queries are the inner loop of Galois derivation.  Compute their
; four-valued status in one grounded fold rather than materializing an
; explanation and three status-specific lists.  The explanation API above is
; retained for callers that actually request evidence.
(= (wm-fca-status-join $accumulated $observed)
   (if (== $accumulated WMMissing)
       $observed
       (if (== $accumulated $observed)
           $accumulated
           WMUnknown)))

(= (wm-fca-cell-status-step
     $context $object $attribute $accumulated
     (WMFCAObservation
       $seenContext $seenObject $seenAttribute
       $observed $stamp $source $group))
   (if (and (== $seenContext $context)
            (and (== $seenObject $object)
                 (== $seenAttribute $attribute)))
       (wm-fca-status-join $accumulated $observed)
       $accumulated))

(= (wm-fca-cell-status
     (WMFCAState $objects $attributes $observations)
     $context $object $attribute)
   (fold
     (superpose $observations)
     WMMissing
     $accumulated
     $observation
     (eval
       (wm-fca-cell-status-step
         $context $object $attribute $accumulated $observation))))

(= (wm-fca-cell-status
     (WMFCACompleteBinaryState
       $objects $attributes $rows $stateContext $source $group)
     $context $object $attribute)
   (wm-fca-binary-cell-status-atom
     $objects $attributes $rows $stateContext $context $object $attribute))

(= (wm-fca-cell-status
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $stateContext $source $group $events)
     $context $object $attribute)
   (let $evidence
        (eval
          (wm-fca-extract-cell
            (WMFCACompleteBinaryEventState
              $objects $attributes $rows $stateContext $source $group $events)
            $context $object $attribute))
     (wm-fca-evidence-status $evidence)))

(= (wm-fca-cell-status
     (WMFCAPackedEvidenceState $objects $attributes $layers)
     $context $object $attribute)
   (let $evidence
        (eval
          (wm-fca-extract-cell
            (WMFCAPackedEvidenceState $objects $attributes $layers)
            $context $object $attribute))
     (wm-fca-evidence-status $evidence)))

; The packed backend evaluates a finite query batch without substituting the
; compiled index through an interpreted loop.  The grounded operation validates
; the same state and gate contract as single-query index construction.
(= (wm-fca-batch-queries
     (WMFCACompleteBinaryState
       $objects $attributes $rows $stateContext $source $group)
     $context $gate $queries)
   (let $materializedQueries (eval $queries)
     (wm-fca-binary-query-batch-atom
       $objects $attributes $rows $stateContext
       $context $gate $materializedQueries)))

(= (wm-fca-batch-queries
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $stateContext $source $group $events)
     $context $gate $queries)
   (let $materializedQueries (eval $queries)
     (wm-fca-binary-event-query-batch-atom
       $objects $attributes $rows $stateContext $source $group $events
       $context $gate $materializedQueries)))

(= (wm-fca-batch-queries
     (WMFCAPackedEvidenceState $objects $attributes $layers)
     $context $gate $queries)
   (let $materializedLayers (eval $layers)
     (let $materializedQueries (eval $queries)
       (wm-fca-evidence-layer-query-batch-atom
         $objects $attributes $materializedLayers
         $context $gate $materializedQueries))))

; Evidence gates are projections of the primary state.  The observation-count
; gate matches the existing Lean positive-threshold semantics.  Source and
; dependence-group gates additionally prevent multiple correlated packets from
; masquerading as independent support.
(= (wm-fca-positive-observations $state $context $object $attribute)
   (let $evidence
        (eval (wm-fca-extract-cell $state $context $object $attribute))
     (eval (wm-fca-evidence-positive $evidence))))

(= (wm-fca-positive-sources $state $context $object $attribute)
   (let $positive
        (eval
          (wm-fca-positive-observations
            $state $context $object $attribute))
     (let $sources
          (eval
            (collect
              (let $observation (superpose $positive)
                (wm-fca-observation-source $observation))))
       (eval (unique-atom $sources)))))

(= (wm-fca-positive-dependence-groups
     $state $context $object $attribute)
   (let $positive
        (eval
          (wm-fca-positive-observations
            $state $context $object $attribute))
     (let $groups
          (eval
            (collect
              (let $observation (superpose $positive)
                (wm-fca-observation-dependence-group $observation))))
       (eval (unique-atom $groups)))))

(= (wm-fca-gate-accepts?
     $state $context $object $attribute WMFCAExactStatusGate)
   (== (wm-fca-cell-status $state $context $object $attribute) WMTrue))

(= (wm-fca-gate-accepts?
     $state $context $object $attribute
     (WMFCAPositiveObservationThreshold $threshold))
   (let $positive
        (eval
          (wm-fca-positive-observations
            $state $context $object $attribute))
     (>= (size-atom $positive) $threshold)))

(= (wm-fca-gate-accepts?
     $state $context $object $attribute
     (WMFCAPositiveSourceThreshold $threshold))
   (let $sources
        (eval
          (wm-fca-positive-sources
            $state $context $object $attribute))
     (>= (size-atom $sources) $threshold)))

(= (wm-fca-gate-accepts?
     $state $context $object $attribute
     (WMFCAPositiveDependenceGroupThreshold $threshold))
   (let $groups
        (eval
          (wm-fca-positive-dependence-groups
            $state $context $object $attribute))
     (>= (size-atom $groups) $threshold)))

; ---------------------------------------------------------------------------
; Compiled column index
; ---------------------------------------------------------------------------

; The exact/reference enumerator below intentionally exposes the semantics in
; the smallest form.  Repeatedly scanning provenance packets is not an
; appropriate execution strategy for wider contexts, so this index compiles a
; precise state+gate view once.  All subsequent Galois operations use column
; intersections while the original state and gate remain attached for audit.

(= (wm-fca-index-state
     (WMFCAIndex $state $context $gate $columns))
   $state)

(= (wm-fca-index-context
     (WMFCAIndex $state $context $gate $columns))
   $context)

(= (wm-fca-index-gate
     (WMFCAIndex $state $context $gate $columns))
   $gate)

(= (wm-fca-index-columns
     (WMFCAIndex $state $context $gate $columns))
   $columns)

(= (wm-fca-index-column-count
     (WMFCAIndex $state $context $gate $columns))
   (size-atom $columns))

(= (wm-fca-core-objects
     (WMFCAIndexCore
       $objects $attributes $columns $columnObjectLists))
   $objects)

(= (wm-fca-core-attributes
     (WMFCAIndexCore
       $objects $attributes $columns $columnObjectLists))
   $attributes)

(= (wm-fca-core-columns
     (WMFCAIndexCore
       $objects $attributes $columns $columnObjectLists))
   $columns)

(= (wm-fca-core-column-object-lists
     (WMFCAIndexCore
       $objects $attributes $columns $columnObjectLists))
   $columnObjectLists)

(= (wm-fca-column-objects
     (WMFCAColumn $attribute $objects))
   $objects)

(= (wm-fca-column-object-list-step $columnObjectLists $column)
   (let $objects (eval (wm-fca-column-objects $column))
     (list:push $columnObjectLists $objects)))

; The audited index retains the complete WM state and extraction gate.  Inner
; Galois loops use this compact projection so they do not carry every
; provenance packet through every closure calculation.
(= (wm-fca-index-core $index)
   (let $state (eval (wm-fca-index-state $index))
     (let $objects (eval (wm-fca-state-objects $state))
       (let $attributes (eval (wm-fca-state-attributes $state))
         (let $columns (eval (wm-fca-index-columns $index))
           (let $columnObjectLists
                (eval
                  (foldl-atom
                    $columns
                    ()
                    $seenObjectLists
                    $column
                    (eval
                      (wm-fca-column-object-list-step
                        $seenObjectLists $column))))
             (WMFCAIndexCore
               $objects $attributes $columns $columnObjectLists)))))))

(= (wm-fca-index-column-object-step
     $state $context $gate $attribute $objects $object)
   (if
     (wm-fca-gate-accepts?
       $state $context $object $attribute $gate)
     (list:push $objects $object)
     $objects))

(= (wm-fca-index-column-step
     $state $context $gate $objects $columns $attribute)
   (let $columnObjects
        (eval
          (foldl-atom
            $objects
            ()
            $acceptedObjects
            $object
            (eval
              (wm-fca-index-column-object-step
                $state $context $gate $attribute
                $acceptedObjects $object))))
     (list:push
       $columns
       (WMFCAColumn $attribute $columnObjects))))

(= (wm-fca-build-index-reference $state $context $gate)
   (let $materializedState (eval $state)
     (let $objects (eval (wm-fca-state-objects $materializedState))
       (let $attributes (eval (wm-fca-state-attributes $materializedState))
         (let $columns
              (eval
                (foldl-atom
                  $attributes
                  ()
                  $seenColumns
                  $attribute
                  (eval
                    (wm-fca-index-column-step
                      $materializedState $context $gate $objects
                      $seenColumns $attribute))))
           (WMFCAIndex
             $materializedState $context $gate $columns))))))

(= (wm-fca-observation-cell-key
     (WMFCAObservation
       $context $object $attribute $status $stamp $source $group))
   (WMFCACellKey $context $object $attribute))

(= (wm-fca-evidence-add-observation
     (WMFCAEvidence $positive $negative $unknown)
     (WMFCAObservation
       $context $object $attribute WMTrue $stamp $source $group))
   (let $next
        (eval
          (list:push
            $positive
            (WMFCAObservation
              $context $object $attribute WMTrue $stamp $source $group)))
     (WMFCAEvidence $next $negative $unknown)))

(= (wm-fca-evidence-add-observation
     (WMFCAEvidence $positive $negative $unknown)
     (WMFCAObservation
       $context $object $attribute WMFalse $stamp $source $group))
   (let $next
        (eval
          (list:push
            $negative
            (WMFCAObservation
              $context $object $attribute WMFalse $stamp $source $group)))
     (WMFCAEvidence $positive $next $unknown)))

(= (wm-fca-evidence-add-observation
     (WMFCAEvidence $positive $negative $unknown)
     (WMFCAObservation
       $context $object $attribute WMUnknown $stamp $source $group))
   (let $next
        (eval
          (list:push
            $unknown
            (WMFCAObservation
              $context $object $attribute WMUnknown $stamp $source $group)))
     (WMFCAEvidence $positive $negative $next)))

(= (wm-fca-evidence-source-step $sources $observation)
   (let $source (eval (wm-fca-observation-source $observation))
     (list:push $sources $source)))

(= (wm-fca-evidence-positive-sources
     (WMFCAEvidence $positive $negative $unknown))
   (let $sources
        (eval
          (foldl-atom
            $positive () $seen $observation
            (eval
              (wm-fca-evidence-source-step
                $seen $observation))))
     (eval (unique-atom $sources))))

(= (wm-fca-evidence-group-step $groups $observation)
   (let $group
        (eval (wm-fca-observation-dependence-group $observation))
     (list:push $groups $group)))

(= (wm-fca-evidence-positive-groups
     (WMFCAEvidence $positive $negative $unknown))
   (let $groups
        (eval
          (foldl-atom
            $positive () $seen $observation
            (eval
              (wm-fca-evidence-group-step
                $seen $observation))))
     (eval (unique-atom $groups))))

(= (wm-fca-gate-accepts-evidence?
     WMFCAExactStatusGate $evidence)
   (== (wm-fca-evidence-status $evidence) WMTrue))

(= (wm-fca-gate-accepts-evidence?
     (WMFCAPositiveObservationThreshold $threshold)
     (WMFCAEvidence $positive $negative $unknown))
   (>= (size-atom $positive) $threshold))

(= (wm-fca-gate-accepts-evidence?
     (WMFCAPositiveSourceThreshold $threshold) $evidence)
   (let $sources (eval (wm-fca-evidence-positive-sources $evidence))
     (>= (size-atom $sources) $threshold)))

(= (wm-fca-gate-accepts-evidence?
     (WMFCAPositiveDependenceGroupThreshold $threshold) $evidence)
   (let $groups (eval (wm-fca-evidence-positive-groups $evidence))
     (>= (size-atom $groups) $threshold)))

(= (wm-fca-index-summary-column-step
     $context $gate $attribute $objects
     ((WMFCACellKey $seenContext $object $seenAttribute) $evidence))
   (if
     (and (== $seenContext $context)
          (and (== $seenAttribute $attribute)
               (wm-fca-gate-accepts-evidence? $gate $evidence)))
     (list:push $objects $object)
     $objects))

(= (wm-fca-index-summary-column
     $summaries $context $gate $objectUniverse $attribute)
   (let $acceptedObjects
        (eval
          (foldl-atom
            $summaries
            ()
            $accepted
            $summary
            (eval
              (wm-fca-index-summary-column-step
                $context $gate $attribute $accepted $summary))))
     (let $orderedObjects
          (eval (intersection-atom $objectUniverse $acceptedObjects))
       (WMFCAColumn $attribute $orderedObjects))))

(= (wm-fca-index-summary-columns-step
     $summaries $context $gate $objectUniverse $columns $attribute)
   (let $column
        (eval
          (wm-fca-index-summary-column
            $summaries $context $gate $objectUniverse $attribute))
     (list:push $columns $column)))

; Compile all provenance packets in one native pass, then project the selected
; gate without repeatedly interpreting one fold per attribute.  The transparent
; reference compiler above remains an independent executable specification.
(= (wm-fca-build-index
     (WMFCAState $objects $attributes $observations)
     $context $gate)
   (let $materializedObservations (eval $observations)
     (let $columns
          (eval
            (wm-fca-index-columns-atom
              $objects $attributes $materializedObservations $context $gate))
       (WMFCAIndex
         (WMFCAState $objects $attributes $materializedObservations)
         $context $gate $columns))))

(= (wm-fca-build-index
     (WMFCACompleteBinaryState
       $objects $attributes $rows $stateContext $source $group)
     $context $gate)
   (let $columns
        (eval
          (wm-fca-binary-rows-columns-atom
            $objects $attributes $rows $stateContext $context $gate))
     (WMFCAIndex
       (WMFCACompleteBinaryState
         $objects $attributes $rows $stateContext $source $group)
       $context $gate $columns)))

(= (wm-fca-build-index
     (WMFCACompleteBinaryEventState
       $objects $attributes $rows $stateContext $source $group $events)
     $context $gate)
   (let $columns
        (eval
          (wm-fca-binary-event-columns-atom
            $objects $attributes $rows $stateContext $source $group $events
            $context $gate))
     (WMFCAIndex
       (WMFCACompleteBinaryEventState
         $objects $attributes $rows $stateContext $source $group $events)
       $context $gate $columns)))

(= (wm-fca-build-index
     (WMFCAPackedEvidenceState $objects $attributes $layers)
     $context $gate)
   (let $materializedLayers (eval $layers)
     (let $columns
          (eval
            (wm-fca-evidence-layer-columns-atom
              $objects $attributes $materializedLayers $context $gate))
       (WMFCAIndex
         (WMFCAPackedEvidenceState
           $objects $attributes $materializedLayers)
         $context $gate $columns))))

(= (wm-fca-index-extent-step
     $attributes $extent (WMFCAColumn $attribute $columnObjects))
   (if (wm-fca-list-member? $attribute $attributes)
       (intersection-atom $extent $columnObjects)
       $extent))

(= (wm-fca-core-extent $core $attributes)
   (let $objects (eval (wm-fca-core-objects $core))
     (let $columns (eval (wm-fca-core-columns $core))
       (foldl-atom
         $columns
         $objects
         $extent
         $column
         (eval
           (wm-fca-index-extent-step
             $attributes $extent $column))))))

(= (wm-fca-index-extent $index $attributes)
   (let $materializedIndex (eval $index)
     (eval
       (wm-fca-index-extent-materialized
         $materializedIndex $attributes))))

(= (wm-fca-index-extent-materialized
     (WMFCAIndex $state $context $gate $columns)
     $attributes)
   (let $objects (eval (wm-fca-state-objects $state))
     (foldl-atom
       $columns
       $objects
       $extent
       $column
       (eval
         (wm-fca-index-extent-step
           $attributes $extent $column)))))

(= (wm-fca-index-intent-step
     $objects $intent (WMFCAColumn $attribute $columnObjects))
   (if (wm-fca-all-members? $objects $columnObjects)
       (list:push $intent $attribute)
       $intent))

(= (wm-fca-core-intent $core $objects)
   (let $columns (eval (wm-fca-core-columns $core))
     (foldl-atom
       $columns
       ()
       $intent
       $column
       (eval
         (wm-fca-index-intent-step
           $objects $intent $column)))))

(= (wm-fca-index-intent $index $objects)
   (let $materializedIndex (eval $index)
     (eval
       (wm-fca-index-intent-materialized
         $materializedIndex $objects))))

(= (wm-fca-index-intent-materialized
     (WMFCAIndex $state $context $gate $columns)
     $objects)
   (foldl-atom
     $columns
     ()
     $intent
     $column
     (eval
       (wm-fca-index-intent-step
         $objects $intent $column))))

(= (wm-fca-core-closure $core $attributes)
   (let $objects (eval (wm-fca-core-objects $core))
     (let $universeAttributes
          (eval (wm-fca-core-attributes $core))
       (let $columnObjectLists
            (eval (wm-fca-core-column-object-lists $core))
         (galois-closure-atom
           $objects $universeAttributes
           $columnObjectLists $attributes)))))

(= (wm-fca-index-closure $index $attributes)
   (let $materializedIndex (eval $index)
     (eval
       (wm-fca-index-closure-materialized
         $materializedIndex $attributes))))

(= (wm-fca-index-closure-materialized
     (WMFCAIndex $state $context $gate $columns)
     $attributes)
   (let $objects (eval (wm-fca-state-objects $state))
     (let $extent
          (eval
            (foldl-atom
              $columns
              $objects
              $seenObjects
              $column
              (eval
                (wm-fca-index-extent-step
                  $attributes $seenObjects $column))))
       (foldl-atom
         $columns
         ()
         $intent
         $column
         (eval
           (wm-fca-index-intent-step
             $extent $intent $column))))))

; Native Ganter enumeration retains the same finite-context contract as the
; reference algorithm below.  The caller supplies an explicit positive cap;
; exhausting it is an error, never a partial concept family.
(= (wm-fca-core-closed-intents-native $core $maxConcepts)
   (let $objects (eval (wm-fca-core-objects $core))
     (let $attributes (eval (wm-fca-core-attributes $core))
       (let $columnObjectLists
            (eval (wm-fca-core-column-object-lists $core))
         (galois-intents-atom
           $objects $attributes $columnObjectLists $maxConcepts)))))

(= (wm-fca-index-closed-intents-native $index $maxConcepts)
   (let $core (eval (wm-fca-index-core $index))
     (eval
       (wm-fca-core-closed-intents-native
         $core $maxConcepts))))

; Build one lectic step per attribute.  Prefixes contain all earlier
; attributes; steps are consed so the search visits attributes right-to-left.
(= (wm-fca-lectic-build-step
     (WMFCALecticBuild $prefix $steps) $attribute)
   (let $nextPrefix (eval (cons-atom $attribute $prefix))
     (let $nextSteps
          (eval
            (cons-atom
              (WMFCALecticStep $attribute $prefix) $steps))
       (WMFCALecticBuild $nextPrefix $nextSteps))))

(= (wm-fca-lectic-build-steps
     (WMFCALecticBuild $prefix $steps))
   $steps)

(= (wm-fca-core-next-closed-step
     $core $current
     (WMFCANextClosedFound $next)
     $lecticStep)
   (WMFCANextClosedFound $next))

(= (wm-fca-core-next-closed-step
     $core $current WMFCANextClosedNone
     (WMFCALecticStep $attribute $prefix))
   (if (wm-fca-list-member? $attribute $current)
       WMFCANextClosedNone
       (let $currentPrefix
            (eval (intersection-atom $current $prefix))
         (let $seed (eval (cons-atom $attribute $currentPrefix))
           (let $candidate
                (eval (wm-fca-core-closure $core $seed))
             (let $candidatePrefix
                  (eval (intersection-atom $candidate $prefix))
               (let $lectic
                    (eval
                      (wm-fca-all-members?
                        $candidatePrefix $current))
                 (if $lectic
                     (WMFCANextClosedFound $candidate)
                     WMFCANextClosedNone))))))))

(= (wm-fca-core-next-closed $core $lecticSteps $current)
   (foldl-atom
     $lecticSteps
     WMFCANextClosedNone
     $search
     $lecticStep
     (eval
       (wm-fca-core-next-closed-step
         $core $current $search $lecticStep))))

(= (wm-fca-index-closed-enumeration-advance
     $current $intents
     (WMFCANextClosedFound $next))
   (let $nextIntents (eval (cons-atom $next $intents))
     (FoldContinue
       (WMFCAClosedEnumeration $next $nextIntents False))))

(= (wm-fca-index-closed-enumeration-advance
     $current $intents WMFCANextClosedNone)
   (FoldStop
     (WMFCAClosedEnumeration $current $intents True)))

(= (wm-fca-core-closed-enumeration-step
     $core $lecticSteps
     (WMFCAClosedEnumeration $current $intents True)
     $tick)
   (FoldStop
     (WMFCAClosedEnumeration $current $intents True)))

(= (wm-fca-core-closed-enumeration-step
     $core $lecticSteps
     (WMFCAClosedEnumeration $current $intents False)
     $tick)
   (let $next
        (eval
          (wm-fca-core-next-closed
            $core $lecticSteps $current))
     (eval
       (wm-fca-index-closed-enumeration-advance
         $current $intents $next))))

(= (wm-fca-closed-enumeration-intents
     (WMFCAClosedEnumeration $current $intents $done))
   $intents)

; Ganter's Next-Closure algorithm.  The finite powerset is used only as a
; grounded iteration budget; closure is evaluated once per lectic proposal,
; not once per subset.  FoldStop ends the budget traversal immediately.
(= (wm-fca-index-closed-intents-next-closure $index)
   (let $core (eval (wm-fca-index-core $index))
     (let $attributes (eval (wm-fca-core-attributes $core))
       (let $lecticBuild
            (eval
              (foldl-atom
                $attributes
                (WMFCALecticBuild () ())
                $build
                $attribute
                (eval
                  (wm-fca-lectic-build-step
                    $build $attribute))))
         (let $lecticSteps
              (eval (wm-fca-lectic-build-steps $lecticBuild))
           (let $initial
                (eval (wm-fca-core-closure $core ()))
             (let $ticks (eval (wm-fca-powerset $attributes))
               (let $enumeration
                    (eval
                      (foldl-until-atom
                        $ticks
                        (WMFCAClosedEnumeration
                          $initial ($initial) False)
                        $progress
                        $tick
                        (eval
                          (wm-fca-core-closed-enumeration-step
                            $core $lecticSteps
                            $progress $tick))))
                 (eval
                   (wm-fca-closed-enumeration-intents
                     $enumeration))))))))))

(= (wm-fca-core-close-candidate-step $core $closures $candidate)
   (let $closure (eval (wm-fca-core-closure $core $candidate))
     (list:push $closures $closure)))

(= (wm-fca-index-closed-intents-reference $index)
   (let $core (eval (wm-fca-index-core $index))
     (let $attributes (eval (wm-fca-core-attributes $core))
       (let $candidates (eval (wm-fca-powerset $attributes))
         (let $closures
              (eval
                (foldl-atom
                  $candidates
                  ()
                  $seenClosures
                  $candidate
                  (eval
                    (wm-fca-core-close-candidate-step
                      $core $seenClosures $candidate))))
           (eval (unique-atom $closures)))))))

(= (wm-fca-core-concept-value $core $intent)
   (let $extent (eval (wm-fca-core-extent $core $intent))
     (WMFCAConcept $extent $intent)))

(= (wm-fca-core-concepts-from-intents $core $intents)
   (collect
     (let $intent (superpose $intents)
       (wm-fca-core-concept-value $core $intent))))

(= (wm-fca-index-concepts-from-intents $index $intents)
   (let $core (eval (wm-fca-index-core $index))
     (eval (wm-fca-core-concepts-from-intents $core $intents))))

(= (wm-fca-index-concepts-reference $index)
   (let $intents (eval (wm-fca-index-closed-intents-reference $index))
     (eval (wm-fca-index-concepts-from-intents $index $intents))))

; Classical FCA accepts exactly the true cells.  False, unknown, and missing
; all project to non-incidence without becoming equal in the WM state.
(= (wm-fca-crisp-cell? $state $context $object $attribute)
   (== (wm-fca-cell-status $state $context $object $attribute) WMTrue))

; ---------------------------------------------------------------------------
; Finite Galois derivations and exact reference concept enumeration
; ---------------------------------------------------------------------------

(= (wm-fca-list-member? $item $items)
   (member-atom? $item $items))

(= (wm-fca-all-members? $needles $haystack)
   (subset-atom? $needles $haystack))

(= (wm-fca-same-set? $left $right)
   (same-set-atom? $left $right))

(= (wm-fca-object-has-all? $state $context $object $attributes)
   (foldl-atom
     $attributes
     True
     $all
     $attribute
     (eval
       (and
         $all
         (wm-fca-crisp-cell? $state $context $object $attribute)))))

(= (wm-fca-all-objects-have? $state $context $objects $attribute)
   (foldl-atom
     $objects
     True
     $all
     $object
     (eval
       (and
         $all
         (wm-fca-crisp-cell? $state $context $object $attribute)))))

(= (wm-fca-extent $state $context $attributes)
   (wm-fca-extent-from-objects
     $state $context $attributes (wm-fca-state-objects $state)))

(= (wm-fca-extent-from-objects $state $context $attributes $objects)
   (foldl-atom
     $objects
     ()
     $extent
     $object
     (eval
       (wm-fca-extent-step
         $state $context $attributes $extent $object))))

(= (wm-fca-extent-step $state $context $attributes $extent $object)
   (if (wm-fca-object-has-all? $state $context $object $attributes)
       (list:push $extent $object)
       $extent))

(= (wm-fca-intent $state $context $objects)
   (wm-fca-intent-from-attributes
     $state $context $objects (wm-fca-state-attributes $state)))

(= (wm-fca-intent-from-attributes $state $context $objects $attributes)
   (foldl-atom
     $attributes
     ()
     $intent
     $attribute
     (eval
       (wm-fca-intent-step
         $state $context $objects $intent $attribute))))

(= (wm-fca-intent-step $state $context $objects $intent $attribute)
   (if (wm-fca-all-objects-have? $state $context $objects $attribute)
       (list:push $intent $attribute)
       $intent))

(= (wm-fca-closure $state $context $attributes)
   (let $extent (eval (wm-fca-extent $state $context $attributes))
     (eval (wm-fca-intent $state $context $extent))))

(= (wm-fca-closed-intent? $state $context $attributes)
   (let $closure (eval (wm-fca-closure $state $context $attributes))
     (eval (wm-fca-same-set? $attributes $closure))))

(= (wm-fca-powerset $items)
   (foldl-atom
     $items
     (())
     $subsets
     $item
     (eval (wm-fca-powerset-step $subsets $item))))

(= (wm-fca-powerset-step $subsets $item)
   (list:append
     $subsets
     (foldl-atom
       $subsets
       ()
       $prefixed
       $subset
       (let $extendedSubset (eval (list:push $subset $item))
         (eval (list:push $prefixed $extendedSubset))))))

(= (wm-fca-close-candidates $state $context $candidates)
   (foldl-atom
     $candidates
     ()
     $closures
     $candidate
     (let $closure (eval (wm-fca-closure $state $context $candidate))
       (eval (list:push $closures $closure)))))

(= (wm-fca-closed-intents-reference $state $context)
   (let $attributes (eval (wm-fca-state-attributes $state))
     (let $candidates (eval (wm-fca-powerset $attributes))
       (let $closures
            (eval (wm-fca-close-candidates $state $context $candidates))
         (eval (unique-atom $closures))))))

(= (wm-fca-concepts-from-intents $state $context $intents)
   (foldl-atom
     $intents
     ()
     $concepts
     $intent
     (let $extent (eval (wm-fca-extent $state $context $intent))
       (eval
         (list:push
           $concepts
           (WMFCAConcept $extent $intent))))))

(= (wm-fca-concepts-reference $state $context)
   (let $intents
        (eval (wm-fca-closed-intents-reference $state $context))
     (eval (wm-fca-concepts-from-intents $state $context $intents))))

; ---------------------------------------------------------------------------
; Gate-indexed and lower/upper concept families
; ---------------------------------------------------------------------------

(= (wm-fca-object-has-all-with-gate?
     $state $context $gate $object $attributes)
   (foldl-atom
     $attributes
     True
     $all
     $attribute
     (eval
       (and
         $all
         (wm-fca-gate-accepts?
           $state $context $object $attribute $gate)))))

(= (wm-fca-all-objects-have-with-gate?
     $state $context $gate $objects $attribute)
   (foldl-atom
     $objects
     True
     $all
     $object
     (eval
       (and
         $all
         (wm-fca-gate-accepts?
           $state $context $object $attribute $gate)))))

(= (wm-fca-extent-with-gate-step
     $state $context $gate $attributes $extent $object)
   (if
     (wm-fca-object-has-all-with-gate?
       $state $context $gate $object $attributes)
     (list:push $extent $object)
     $extent))

(= (wm-fca-extent-with-gate $state $context $gate $attributes)
   (let $objects (eval (wm-fca-state-objects $state))
     (foldl-atom
       $objects
       ()
       $extent
       $object
       (eval
         (wm-fca-extent-with-gate-step
           $state $context $gate $attributes $extent $object)))))

(= (wm-fca-intent-with-gate-step
     $state $context $gate $objects $intent $attribute)
   (if
     (wm-fca-all-objects-have-with-gate?
       $state $context $gate $objects $attribute)
     (list:push $intent $attribute)
     $intent))

(= (wm-fca-intent-with-gate $state $context $gate $objects)
   (let $attributes (eval (wm-fca-state-attributes $state))
     (foldl-atom
       $attributes
       ()
       $intent
       $attribute
       (eval
         (wm-fca-intent-with-gate-step
           $state $context $gate $objects $intent $attribute)))))

(= (wm-fca-closure-with-gate $state $context $gate $attributes)
   (let $extent
        (eval
          (wm-fca-extent-with-gate
            $state $context $gate $attributes))
     (eval
       (wm-fca-intent-with-gate
         $state $context $gate $extent))))

(= (wm-fca-close-candidate-with-gate-step
     $state $context $gate $closures $candidate)
   (let $closure
        (eval
          (wm-fca-closure-with-gate
            $state $context $gate $candidate))
     (list:push $closures $closure)))

(= (wm-fca-closed-intents-with-gate-reference $state $context $gate)
   (let $attributes (eval (wm-fca-state-attributes $state))
     (let $candidates (eval (wm-fca-powerset $attributes))
       (let $closures
            (eval
              (foldl-atom
                $candidates
                ()
                $seenClosures
                $candidate
                (eval
                  (wm-fca-close-candidate-with-gate-step
                    $state $context $gate
                    $seenClosures $candidate))))
         (eval (unique-atom $closures))))))

(= (wm-fca-concept-with-gate-step
     $state $context $gate $concepts $intent)
   (let $extent
        (eval
          (wm-fca-extent-with-gate
            $state $context $gate $intent))
     (list:push $concepts (WMFCAConcept $extent $intent))))

(= (wm-fca-concepts-with-gate-reference $state $context $gate)
   (let $intents
        (eval
          (wm-fca-closed-intents-with-gate-reference
            $state $context $gate))
     (foldl-atom
       $intents
       ()
       $concepts
       $intent
       (eval
         (wm-fca-concept-with-gate-step
           $state $context $gate $concepts $intent)))))

(= (wm-fca-gate-concept-family-step
     $state $context $families $gate)
   (let $concepts
        (eval
          (wm-fca-concepts-with-gate-reference
            $state $context $gate))
     (list:push
       $families
       (WMFCAGateConceptFamily $gate $concepts))))

(= (wm-fca-gate-concept-families-reference $state $context $gates)
   (foldl-atom
     $gates
     ()
     $families
     $gate
     (eval
       (wm-fca-gate-concept-family-step
         $state $context $families $gate))))

(= (wm-fca-upper-concepts-step
     $upper (WMFCAGateConceptFamily $gate $concepts))
   (let $merged (eval (union-atom $upper $concepts))
     (eval (unique-atom $merged))))

(= (wm-fca-upper-concepts-from-families $families)
   (foldl-atom
     $families
     ()
     $upper
     $family
     (eval (wm-fca-upper-concepts-step $upper $family))))

(= (wm-fca-concept-in-family-step
     $concept $inAll (WMFCAGateConceptFamily $gate $concepts))
   (and $inAll (wm-fca-list-member? $concept $concepts)))

(= (wm-fca-concept-in-all-families? $families $concept)
   (foldl-atom
     $families
     True
     $inAll
     $family
     (eval
       (wm-fca-concept-in-family-step
         $concept $inAll $family))))

(= (wm-fca-lower-concepts-step $families $lower $concept)
   (if (wm-fca-concept-in-all-families? $families $concept)
       (list:push $lower $concept)
       $lower))

(= (wm-fca-lower-concepts-from-families $families $upper)
   (foldl-atom
     $upper
     ()
     $lower
     $concept
     (eval
       (wm-fca-lower-concepts-step
         $families $lower $concept))))

(= (wm-fca-credal-concepts-reference $state $context $gates)
   (if (== $gates ())
       WMFCAEmptyGateFamily
       (let $families
            (eval
              (wm-fca-gate-concept-families-reference
                $state $context $gates))
         (let $upper
              (eval (wm-fca-upper-concepts-from-families $families))
           (let $lower
                (eval
                  (wm-fca-lower-concepts-from-families
                    $families $upper))
             (let $unstable (eval (subtraction-atom $upper $lower))
               (WMFCACredalConceptFamily
                 $families $lower $upper $unstable)))))))

(= (wm-fca-credal-gate-families
     (WMFCACredalConceptFamily $families $lower $upper $unstable))
   $families)

(= (wm-fca-credal-lower
     (WMFCACredalConceptFamily $families $lower $upper $unstable))
   $lower)

(= (wm-fca-credal-upper
     (WMFCACredalConceptFamily $families $lower $upper $unstable))
   $upper)

(= (wm-fca-credal-unstable
     (WMFCACredalConceptFamily $families $lower $upper $unstable))
   $unstable)

(= (wm-fca-concept-envelope $credalFamily $concept)
   (let $lowerConcepts (eval (wm-fca-credal-lower $credalFamily))
     (let $upperConcepts (eval (wm-fca-credal-upper $credalFamily))
       (let $lower
            (if (wm-fca-list-member? $concept $lowerConcepts) 1 0)
         (let $upper
              (if (wm-fca-list-member? $concept $upperConcepts) 1 0)
           (WMFCAConceptEnvelope
             $lower
             $upper
             (/ (+ $lower $upper) 2)
             (- $upper $lower)))))))

(= (wm-fca-implication-holds?
     $state $context (WMFCAImplication $antecedent $consequent))
   (let $closure (eval (wm-fca-closure $state $context $antecedent))
     (eval (wm-fca-all-members? $consequent $closure))))

(= (wm-fca-all-implications-hold? $state $context $implications)
   (foldl-atom
     $implications
     True
     $all
     $implication
     (eval
       (and
         $all
         (wm-fca-implication-holds? $state $context $implication)))))

; ---------------------------------------------------------------------------
; Exact finite canonical basis and Hasse covers
; ---------------------------------------------------------------------------

; These are intentionally reference algorithms.  They enumerate the finite
; attribute powerset and are therefore suitable for oracle-sized contexts.
; Scale contexts must use a bounded query or a specialized exact FCA engine.

(= (wm-fca-proper-subset? $left $right)
   (let $included (eval (wm-fca-all-members? $left $right))
     (let $same (eval (wm-fca-same-set? $left $right))
       (and $included (not $same)))))

(= (wm-fca-pseudo-intent-respects-step
     $state $context $candidate $respects $priorPseudoIntent)
   (let $isPriorSubset
        (eval (wm-fca-proper-subset? $priorPseudoIntent $candidate))
     (if $isPriorSubset
         (let $priorClosure
              (eval
                (wm-fca-closure
                  $state $context $priorPseudoIntent))
           (let $contained
                (eval (wm-fca-all-members? $priorClosure $candidate))
             (and $respects $contained)))
         $respects)))

(= (wm-fca-pseudo-intent? $state $context $priorPseudoIntents $candidate)
   (let $closure (eval (wm-fca-closure $state $context $candidate))
     (let $closed (eval (wm-fca-same-set? $candidate $closure))
       (if $closed
           False
           (foldl-atom
             $priorPseudoIntents
             True
             $respects
             $priorPseudoIntent
             (eval
               (wm-fca-pseudo-intent-respects-step
                 $state $context $candidate
                 $respects $priorPseudoIntent)))))))

(= (wm-fca-pseudo-intent-step
     $state $context $pseudoIntents $candidate)
   (let $isPseudo
        (eval
          (wm-fca-pseudo-intent?
            $state $context $pseudoIntents $candidate))
     (if $isPseudo
         (list:push $pseudoIntents $candidate)
         $pseudoIntents)))

(= (wm-fca-pseudo-intents-reference $state $context)
   (let $attributes (eval (wm-fca-state-attributes $state))
     (let $candidates (eval (wm-fca-powerset $attributes))
       (foldl-atom
         $candidates
         ()
         $pseudoIntents
         $candidate
         (eval
           (wm-fca-pseudo-intent-step
             $state $context $pseudoIntents $candidate))))))

(= (wm-fca-canonical-implication-step
     $state $context $implications $pseudoIntent)
   (let $closure
        (eval (wm-fca-closure $state $context $pseudoIntent))
     (let $consequent
          (eval (subtraction-atom $closure $pseudoIntent))
       (list:push
         $implications
         (WMFCAImplication $pseudoIntent $consequent)))))

(= (wm-fca-canonical-basis-reference $state $context)
   (let $pseudoIntents
        (eval (wm-fca-pseudo-intents-reference $state $context))
     (foldl-atom
       $pseudoIntents
       ()
       $implications
       $pseudoIntent
       (eval
         (wm-fca-canonical-implication-step
           $state $context $implications $pseudoIntent)))))

(= (wm-fca-between-step $general $specific $found $middle)
   (let $aboveGeneral (eval (wm-fca-proper-subset? $general $middle))
     (let $belowSpecific (eval (wm-fca-proper-subset? $middle $specific))
       (or $found (and $aboveGeneral $belowSpecific)))))

(= (wm-fca-cover? $intents $general $specific)
   (let $ordered (eval (wm-fca-proper-subset? $general $specific))
     (if $ordered
         (let $hasIntermediate
              (eval
                (foldl-atom
                  $intents
                  False
                  $found
                  $middle
                  (eval
                    (wm-fca-between-step
                      $general $specific $found $middle))))
           (not $hasIntermediate))
         False)))

(= (wm-fca-cover-specific-step
     $intents $general $covers $specific)
   (let $isCover (eval (wm-fca-cover? $intents $general $specific))
     (if $isCover
         (list:push $covers (WMFCACover $general $specific))
         $covers)))

(= (wm-fca-cover-general-step $intents $covers $general)
   (foldl-atom
     $intents
     $covers
     $nextCovers
     $specific
     (eval
       (wm-fca-cover-specific-step
         $intents $general $nextCovers $specific))))

(= (wm-fca-covers-from-intents $intents)
   (foldl-atom
     $intents
     ()
     $covers
     $general
     (eval (wm-fca-cover-general-step $intents $covers $general))))

(= (wm-fca-cover-pair-value ($general $specific))
   (WMFCACover $general $specific))

; The native finite-poset kernel returns representation-neutral pairs.  The
; wrapper attaches WM/FCA cover typing after both the family-size and output
; bounds have been checked.
(= (wm-fca-covers-from-intents-native
     $intents $maxIntents $maxCovers)
   (let $pairs
        (eval
          (subset-cover-relations-atom
            $intents $maxIntents $maxCovers))
     (collect
       (let $pair (superpose $pairs)
         (wm-fca-cover-pair-value $pair)))))

(= (wm-fca-covers-reference $state $context)
   (let $intents
        (eval (wm-fca-closed-intents-reference $state $context))
     (eval (wm-fca-covers-from-intents $intents))))

; Indexed twins of the canonical-basis and implication checks.  They share the
; mathematical definitions above but route every closure through the compiled
; column representation.

(= (wm-fca-index-pseudo-intent-respects-step
     $index $candidate $respects $priorPseudoIntent)
   (let $isPriorSubset
        (eval (wm-fca-proper-subset? $priorPseudoIntent $candidate))
     (if $isPriorSubset
         (let $priorClosure
              (eval (wm-fca-index-closure $index $priorPseudoIntent))
           (let $contained
                (eval (wm-fca-all-members? $priorClosure $candidate))
             (and $respects $contained)))
         $respects)))

(= (wm-fca-index-pseudo-intent? $index $priorPseudoIntents $candidate)
   (let $closure (eval (wm-fca-index-closure $index $candidate))
     (let $closed (eval (wm-fca-same-set? $candidate $closure))
       (if $closed
           False
           (foldl-atom
             $priorPseudoIntents
             True
             $respects
             $priorPseudoIntent
             (eval
               (wm-fca-index-pseudo-intent-respects-step
                 $index $candidate $respects $priorPseudoIntent)))))))

(= (wm-fca-index-pseudo-intent-step
     $index $pseudoIntents $candidate)
   (let $isPseudo
        (eval
          (wm-fca-index-pseudo-intent?
            $index $pseudoIntents $candidate))
     (if $isPseudo
         (list:push $pseudoIntents $candidate)
         $pseudoIntents)))

(= (wm-fca-index-pseudo-intents-reference $index)
   (let $state (eval (wm-fca-index-state $index))
     (let $attributes (eval (wm-fca-state-attributes $state))
       (let $candidates (eval (wm-fca-powerset $attributes))
         (foldl-atom
           $candidates
           ()
           $pseudoIntents
           $candidate
           (eval
             (wm-fca-index-pseudo-intent-step
               $index $pseudoIntents $candidate)))))))

(= (wm-fca-index-canonical-implication-step
     $index $implications $pseudoIntent)
   (let $closure (eval (wm-fca-index-closure $index $pseudoIntent))
     (let $consequent
          (eval (subtraction-atom $closure $pseudoIntent))
       (list:push
         $implications
         (WMFCAImplication $pseudoIntent $consequent)))))

; A prior canonical implication stores its pseudo-intent closure as
; antecedent union consequent.  Carrying those implications through the fold
; avoids re-closing every prior pseudo-intent for every new candidate.
(= (wm-fca-index-candidate-respects-implication-step
     $candidate $respects
     (WMFCAImplication $antecedent $consequent))
   (let $isPriorSubset
        (eval (wm-fca-proper-subset? $antecedent $candidate))
     (if $isPriorSubset
         (let $containsConsequent
              (eval (wm-fca-all-members? $consequent $candidate))
           (and $respects $containsConsequent))
         $respects)))

(= (wm-fca-core-canonical-basis-candidate-step
     $core $implications $candidate)
   (let $closure (eval (wm-fca-core-closure $core $candidate))
     (let $closed (eval (wm-fca-same-set? $candidate $closure))
       (if $closed
           $implications
           (let $respects
                (eval
                  (foldl-atom
                    $implications
                    True
                    $all
                    $implication
                    (eval
                      (wm-fca-index-candidate-respects-implication-step
                        $candidate $all $implication))))
             (if $respects
                 (let $consequent
                      (eval (subtraction-atom $closure $candidate))
                   (list:push
                     $implications
                     (WMFCAImplication $candidate $consequent)))
                 $implications))))))

(= (wm-fca-index-canonical-basis-reference $index)
   (let $core (eval (wm-fca-index-core $index))
     (let $attributes (eval (wm-fca-core-attributes $core))
       (let $candidates (eval (wm-fca-powerset $attributes))
         (foldl-atom
           $candidates
           ()
           $implications
           $candidate
           (eval
             (wm-fca-core-canonical-basis-candidate-step
               $core $implications $candidate)))))))

(= (wm-fca-canonical-basis-pair-step
     $implications ($antecedent $consequent))
   (list:push
     $implications
     (WMFCAImplication $antecedent $consequent)))

; The scalable native kernel uses Ganter's NextClosure over the logical
; pseudo-closure and returns representation-neutral pairs.  This wrapper is
; the only place where those pairs acquire WM/FCA implication typing.
(= (wm-fca-core-canonical-basis-native
     $core $maxLogicalClosures $maxImplications)
   (let $objects (eval (wm-fca-core-objects $core))
     (let $attributes (eval (wm-fca-core-attributes $core))
       (let $columnObjectLists
            (eval (wm-fca-core-column-object-lists $core))
         (let $pairs
              (eval
                (galois-canonical-basis-next-atom
                  $objects $attributes $columnObjectLists
                  $maxLogicalClosures $maxImplications))
           (foldl-atom
             $pairs
             ()
             $implications
             $pair
             (eval
               (wm-fca-canonical-basis-pair-step
                 $implications $pair))))))))

(= (wm-fca-index-canonical-basis-native
     $index $maxLogicalClosures $maxImplications)
   (let $core (eval (wm-fca-index-core $index))
     (eval
       (wm-fca-core-canonical-basis-native
         $core $maxLogicalClosures $maxImplications))))

(= (wm-fca-core-implication-holds?
     $core (WMFCAImplication $antecedent $consequent))
   (let $closure (eval (wm-fca-core-closure $core $antecedent))
     (eval (wm-fca-all-members? $consequent $closure))))

(= (wm-fca-index-implication-holds?
     $index (WMFCAImplication $antecedent $consequent))
   (let $core (eval (wm-fca-index-core $index))
     (eval
       (wm-fca-core-implication-holds?
         $core (WMFCAImplication $antecedent $consequent)))))

(= (wm-fca-core-all-implications-hold? $core $implications)
   (foldl-atom
     $implications
     True
     $all
     $implication
     (eval
       (and
         $all
         (wm-fca-core-implication-holds? $core $implication)))))

(= (wm-fca-index-all-implications-hold? $index $implications)
   (let $core (eval (wm-fca-index-core $index))
     (eval (wm-fca-core-all-implications-hold? $core $implications))))

(= (wm-fca-index-covers-reference $index)
   (let $intents (eval (wm-fca-index-closed-intents-reference $index))
     (eval (wm-fca-covers-from-intents $intents))))

; ---------------------------------------------------------------------------
; Replayable query certificates
; ---------------------------------------------------------------------------

; The certificate retains the immutable state and extraction gate through its
; index.  It records both Galois derivation stages without eagerly duplicating
; every contributing observation.  Required cell evidence remains available
; on demand through wm-fca-closure-certificate-explain-required-cell.
(= (wm-fca-index-certify-closure $index $attributes)
   (let $materializedIndex (eval $index)
     (let $extent
          (eval (wm-fca-index-extent $materializedIndex $attributes))
       (let $closure
            (eval (wm-fca-index-intent $materializedIndex $extent))
         (WMFCAClosureCertificate
           $materializedIndex $attributes $extent $closure)))))

(= (wm-fca-certify-closure $state $context $gate $attributes)
   (let $index (eval (wm-fca-build-index $state $context $gate))
     (eval (wm-fca-index-certify-closure $index $attributes))))

(= (wm-fca-closure-certificate-index
     (WMFCAClosureCertificate $index $query $extent $closure))
   $index)

(= (wm-fca-closure-certificate-query
     (WMFCAClosureCertificate $index $query $extent $closure))
   $query)

(= (wm-fca-closure-certificate-extent
     (WMFCAClosureCertificate $index $query $extent $closure))
   $extent)

(= (wm-fca-closure-certificate-closure
     (WMFCAClosureCertificate $index $query $extent $closure))
   $closure)

(= (wm-fca-closure-certificate-state $certificate)
   (let $index (eval (wm-fca-closure-certificate-index $certificate))
     (eval (wm-fca-index-state $index))))

(= (wm-fca-closure-certificate-context $certificate)
   (let $index (eval (wm-fca-closure-certificate-index $certificate))
     (eval (wm-fca-index-context $index))))

(= (wm-fca-closure-certificate-gate $certificate)
   (let $index (eval (wm-fca-closure-certificate-index $certificate))
     (eval (wm-fca-index-gate $index))))

(= (wm-fca-closure-certificate-history $certificate)
   (let $state (eval (wm-fca-closure-certificate-state $certificate))
     (eval (wm-fca-state-history $state))))

; Computing an extent consults every object at each queried attribute.
; Computing the resulting intent consults every attribute at each extent
; object.  This predicate exposes that exact finite cell-query boundary.
(= (wm-fca-closure-certificate-required-cell?
     (WMFCAClosureCertificate $index $query $extent $closure)
     $object $attribute)
   (or
     (wm-fca-list-member? $attribute $query)
     (wm-fca-list-member? $object $extent)))

(= (wm-fca-closure-certificate-explain-required-cell
     $certificate $object $attribute)
   (if
     (wm-fca-closure-certificate-required-cell?
       $certificate $object $attribute)
     (let $state (eval (wm-fca-closure-certificate-state $certificate))
       (let $context
            (eval (wm-fca-closure-certificate-context $certificate))
         (eval
           (wm-fca-explain-cell
             $state $context $object $attribute))))
     ()))

(= (wm-fca-verify-closure-certificate
     (WMFCAClosureCertificate $index $query $extent $closure))
   (let $computedExtent (eval (wm-fca-index-extent $index $query))
     (let $computedClosure (eval (wm-fca-index-intent $index $computedExtent))
       (and
         (wm-fca-same-set? $extent $computedExtent)
         (wm-fca-same-set? $closure $computedClosure)))))

(= (wm-fca-index-certify-implication
     $index (WMFCAImplication $antecedent $consequent))
   (let $closureCertificate
        (eval (wm-fca-index-certify-closure $index $antecedent))
     (let $closure
          (eval
            (wm-fca-closure-certificate-closure
              $closureCertificate))
       (let $holds
            (eval (wm-fca-all-members? $consequent $closure))
         (WMFCAImplicationCertificate
           (WMFCAImplication $antecedent $consequent)
           $closureCertificate $holds)))))

(= (wm-fca-certify-implication $state $context $gate $implication)
   (let $index (eval (wm-fca-build-index $state $context $gate))
     (eval (wm-fca-index-certify-implication $index $implication))))

(= (wm-fca-implication-certificate-result
     (WMFCAImplicationCertificate
       $implication $closureCertificate $result))
   $result)

(= (wm-fca-implication-certificate-closure
     (WMFCAImplicationCertificate
       $implication $closureCertificate $result))
   $closureCertificate)

(= (wm-fca-verify-implication-certificate
     (WMFCAImplicationCertificate
       (WMFCAImplication $antecedent $consequent)
       $closureCertificate $result))
   (let $query
        (eval
          (wm-fca-closure-certificate-query
            $closureCertificate))
     (let $closure
          (eval
            (wm-fca-closure-certificate-closure
              $closureCertificate))
       (and
         (wm-fca-verify-closure-certificate $closureCertificate)
         (and
           (wm-fca-same-set? $antecedent $query)
           (==
             $result
             (wm-fca-all-members? $consequent $closure)))))))

(= (wm-fca-index-certify-concept
     $index (WMFCAConcept $extent $intent))
   (let $closureCertificate
        (eval (wm-fca-index-certify-closure $index $intent))
     (let $computedExtent
          (eval
            (wm-fca-closure-certificate-extent
              $closureCertificate))
       (let $computedClosure
            (eval
              (wm-fca-closure-certificate-closure
                $closureCertificate))
         (let $formed
              (eval
                (and
                  (wm-fca-same-set? $extent $computedExtent)
                  (wm-fca-same-set? $intent $computedClosure)))
           (WMFCAConceptCertificate
             (WMFCAConcept $extent $intent)
             $closureCertificate $formed))))))

(= (wm-fca-certify-concept $state $context $gate $concept)
   (let $index (eval (wm-fca-build-index $state $context $gate))
     (eval (wm-fca-index-certify-concept $index $concept))))

(= (wm-fca-concept-certificate-result
     (WMFCAConceptCertificate
       $concept $closureCertificate $result))
   $result)

(= (wm-fca-concept-certificate-closure
     (WMFCAConceptCertificate
       $concept $closureCertificate $result))
   $closureCertificate)

(= (wm-fca-verify-concept-certificate
     (WMFCAConceptCertificate
       (WMFCAConcept $extent $intent) $closureCertificate $result))
   (let $query
        (eval
          (wm-fca-closure-certificate-query
            $closureCertificate))
     (let $computedExtent
          (eval
            (wm-fca-closure-certificate-extent
              $closureCertificate))
       (let $computedClosure
            (eval
              (wm-fca-closure-certificate-closure
                $closureCertificate))
         (let $computedResult
              (eval
                (and
                  (wm-fca-same-set? $extent $computedExtent)
                  (wm-fca-same-set? $intent $computedClosure)))
           (and
             (wm-fca-verify-closure-certificate
               $closureCertificate)
             (and
               (wm-fca-same-set? $intent $query)
               (== $result $computedResult))))))))

; ---------------------------------------------------------------------------
; Query-specific extraction surface
; ---------------------------------------------------------------------------

(= (wm-fca-query $state (WMFCACellQuery $context $object $attribute))
   (let $evidence (wm-fca-extract-cell $state $context $object $attribute)
     (let $status (eval (wm-fca-evidence-status $evidence))
       (WMFCACellValue $status $evidence))))

(= (wm-fca-query $state (WMFCAExtentQuery $context $attributes))
   (let $extent (eval (wm-fca-extent $state $context $attributes))
     (WMFCAExtentValue $extent)))

(= (wm-fca-query $state (WMFCAIntentQuery $context $objects))
   (let $intent (eval (wm-fca-intent $state $context $objects))
     (WMFCAIntentValue $intent)))

(= (wm-fca-query $state (WMFCAClosureQuery $context $attributes))
   (let $closure (eval (wm-fca-closure $state $context $attributes))
     (WMFCAClosureValue $closure)))

(= (wm-fca-query $state (WMFCAConceptsQuery $context))
   (let $concepts (eval (wm-fca-concepts-reference $state $context))
     (WMFCAConceptsValue $concepts)))

(= (wm-fca-query $state (WMFCAExplainCellQuery $context $object $attribute))
   (let $explanation
        (eval (wm-fca-explain-cell $state $context $object $attribute))
     (WMFCAExplanationValue $explanation)))

(= (wm-fca-query $state (WMFCACanonicalBasisQuery $context))
   (let $basis (eval (wm-fca-canonical-basis-reference $state $context))
     (WMFCACanonicalBasisValue $basis)))

(= (wm-fca-query $state (WMFCACoversQuery $context))
   (let $covers (eval (wm-fca-covers-reference $state $context))
     (WMFCACoversValue $covers)))

(= (wm-fca-query
     $state (WMFCAGatedConceptsQuery $context $gate))
   (let $concepts
        (eval
          (wm-fca-concepts-with-gate-reference
            $state $context $gate))
     (WMFCAGatedConceptsValue $gate $concepts)))

(= (wm-fca-query
     $state (WMFCACredalConceptsQuery $context $gates))
   (let $credalFamily
        (eval
          (wm-fca-credal-concepts-reference
            $state $context $gates))
     (WMFCACredalConceptsValue $credalFamily)))

(= (wm-fca-query
     $state
     (WMFCAConceptEnvelopeQuery $context $gates $concept))
   (let $credalFamily
        (eval
          (wm-fca-credal-concepts-reference
            $state $context $gates))
     (let $envelope
          (eval (wm-fca-concept-envelope $credalFamily $concept))
       (WMFCAConceptEnvelopeValue $envelope))))

(= (wm-fca-query
     $state
     (WMFCAClosureCertificateQuery $context $gate $attributes))
   (let $certificate
        (eval
          (wm-fca-certify-closure
            $state $context $gate $attributes))
     (WMFCAClosureCertificateValue $certificate)))

(= (wm-fca-query
     $state
     (WMFCAImplicationCertificateQuery $context $gate $implication))
   (let $certificate
        (eval
          (wm-fca-certify-implication
            $state $context $gate $implication))
     (WMFCAImplicationCertificateValue $certificate)))

(= (wm-fca-query
     $state
     (WMFCAConceptCertificateQuery $context $gate $concept))
   (let $certificate
        (eval
          (wm-fca-certify-concept
            $state $context $gate $concept))
     (WMFCAConceptCertificateValue $certificate)))
