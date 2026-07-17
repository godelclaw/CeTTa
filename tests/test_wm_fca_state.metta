!(import! &self lib_wm_fca)

(= (toy-o1-a)
   (WMFCAObservation toy o1 a WMTrue stamp-o1-a source-a group-a))
(= (toy-o1-b)
   (WMFCAObservation toy o1 b WMFalse stamp-o1-b source-a group-a))
(= (toy-o2-a)
   (WMFCAObservation toy o2 a WMTrue stamp-o2-a source-b group-b))
(= (toy-o2-b)
   (WMFCAObservation toy o2 b WMTrue stamp-o2-b source-b group-b))

(= (toy-state)
   (WMFCAState
     (o1 o2)
     (a b)
     ((toy-o1-a) (toy-o1-b) (toy-o2-a) (toy-o2-b))))

; Positive, negative, and absent cells remain distinguishable before the crisp
; projection.
!(assertEqual (wm-fca-cell-status (toy-state) toy o1 a) WMTrue)
!(assertEqual (wm-fca-cell-status (toy-state) toy o1 b) WMFalse)
!(assertEqual (wm-fca-cell-status (toy-state) other o1 a) WMMissing)
!(assertEqual (wm-fca-crisp-cell? (toy-state) toy o1 a) True)
!(assertEqual (wm-fca-crisp-cell? (toy-state) toy o1 b) False)
!(assertEqual (wm-fca-crisp-cell? (toy-state) other o1 a) False)

; Exact finite Galois derivations.
!(assertEqual (wm-fca-extent (toy-state) toy ()) (o1 o2))
!(assertEqual (wm-fca-extent (toy-state) toy (a)) (o1 o2))
!(assertEqual (wm-fca-extent (toy-state) toy (b)) (o2))
!(assertEqual (wm-fca-intent (toy-state) toy ()) (a b))
!(assertEqual (wm-fca-intent (toy-state) toy (o1 o2)) (a))
!(assertEqual (wm-fca-closure (toy-state) toy ()) (a))
!(assertEqual (wm-fca-closure (toy-state) toy (b)) (a b))
!(assertEqual (wm-fca-closed-intent? (toy-state) toy (a)) True)
!(assertEqual (wm-fca-closed-intent? (toy-state) toy (b)) False)
!(assertEqual (wm-fca-powerset (a b)) (() (a) (b) (a b)))
!(assertEqual
   (let $intents
        (eval (wm-fca-closed-intents-reference (toy-state) toy))
     (size-atom $intents))
   2)
!(assertEqual
   (wm-fca-same-set?
     (wm-fca-closed-intents-reference (toy-state) toy)
     ((a) (a b)))
   True)

; Positive and negative implication examples.
!(assertEqual
   (wm-fca-implication-holds?
     (toy-state) toy (WMFCAImplication (b) (a)))
   True)
!(assertEqual
   (wm-fca-implication-holds?
     (toy-state) toy (WMFCAImplication (a) (b)))
   False)

; Exact reference canonical basis and intent-order Hasse cover.
!(assertEqual
   (wm-fca-canonical-basis-reference (toy-state) toy)
   ((WMFCAImplication () (a))))
!(assertEqual
   (wm-fca-covers-reference (toy-state) toy)
   ((WMFCACover (a) (a b))))
!(assertEqual
   (wm-fca-cover? ((a) (a b)) (a) (a b))
   True)
!(assertEqual
   (wm-fca-cover? ((a) (a b)) (a b) (a))
   False)

; The compiled column index is extensionally identical to the transparent
; reference backend for every exact FCA artifact.
!(assertEqual
   (let $native
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (let $reference
          (eval
            (wm-fca-build-index-reference
              (toy-state) toy WMFCAExactStatusGate))
       (wm-fca-same-set?
         (wm-fca-index-columns $native)
         (wm-fca-index-columns $reference))))
   True)
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-index-columns $index))
   ((WMFCAColumn a (o1 o2)) (WMFCAColumn b (o2))))
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-index-extent $index (b)))
   (o2))
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-index-intent $index (o1 o2)))
   (a))
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-index-closure $index (b)))
   (a b))
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-same-set?
       (wm-fca-index-concepts-reference $index)
       (wm-fca-concepts-reference (toy-state) toy)))
   True)
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-same-set?
       (wm-fca-index-closed-intents-next-closure $index)
       (wm-fca-index-closed-intents-reference $index)))
   True)
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-same-set?
       (wm-fca-index-closed-intents-native $index 2)
       (wm-fca-index-closed-intents-reference $index)))
   True)
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-same-set?
       (wm-fca-index-canonical-basis-reference $index)
       (wm-fca-canonical-basis-reference (toy-state) toy)))
   True)
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-same-set?
       (wm-fca-index-canonical-basis-native $index 4 1)
       (wm-fca-index-canonical-basis-reference $index)))
   True)
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (wm-fca-same-set?
       (wm-fca-index-covers-reference $index)
       (wm-fca-covers-reference (toy-state) toy)))
   True)
!(assertEqual
   (let $index
        (eval (wm-fca-build-index (toy-state) toy WMFCAExactStatusGate))
     (let $basis (eval (wm-fca-index-canonical-basis-reference $index))
       (wm-fca-index-all-implications-hold? $index $basis)))
   True)

; Revision is idempotent for identical provenance-bearing chunks.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise (toy-state) (toy-state))))
     (size-atom $observations))
   4)

; A conflicting/indeterminate observation remains visible and produces Unknown;
; forgetting that exact stamp restores the prior answer.
(= (toy-unknown)
   (WMFCAObservation toy o1 a WMUnknown stamp-o1-a-review review group-review))
(= (toy-with-unknown)
   (wm-fca-remember (toy-state) (toy-unknown)))
!(assertEqual (wm-fca-cell-status (toy-with-unknown) toy o1 a) WMUnknown)
!(assertEqual
   (let $explanation
        (eval (wm-fca-explain-cell (toy-with-unknown) toy o1 a))
     (size-atom $explanation))
   2)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-forget
       (toy-with-unknown) (WMFCAScopeStamp stamp-o1-a-review))
     toy o1 a)
   WMTrue)

; Scoped forgetting changes only observations in the declared scope.
(= (toy-without-o1-b)
   (wm-fca-forget (toy-state) (WMFCAScopeStamp stamp-o1-b)))
!(assertEqual (wm-fca-cell-status (toy-without-o1-b) toy o1 b) WMMissing)
!(assertEqual (wm-fca-cell-status (toy-without-o1-b) toy o2 b) WMTrue)
!(assertEqual
   (wm-fca-forget
     (wm-fca-forget (toy-state) (WMFCAScopeSource source-a))
     (WMFCAScopeSource source-a))
   (wm-fca-forget (toy-state) (WMFCAScopeSource source-a)))

; Query-specific extraction returns typed sum constructors.
!(assertEqual
   (wm-fca-query (toy-state) (WMFCAClosureQuery toy (b)))
   (WMFCAClosureValue (a b)))
!(assertEqual
   (wm-fca-query (toy-state) (WMFCACellQuery toy o1 b))
   (WMFCACellValue
     WMFalse
     (WMFCAEvidence
       ()
       ((WMFCAObservation
          toy o1 b WMFalse stamp-o1-b source-a group-a))
       ())))
!(assertEqual
   (wm-fca-query (toy-state) (WMFCAExplainCellQuery toy o2 a))
   (WMFCAExplanationValue
     ((WMFCAObservation
        toy o2 a WMTrue stamp-o2-a source-b group-b))))
!(assertEqual
   (wm-fca-query (toy-state) (WMFCACanonicalBasisQuery toy))
   (WMFCACanonicalBasisValue ((WMFCAImplication () (a)))))
!(assertEqual
   (wm-fca-query (toy-state) (WMFCACoversQuery toy))
   (WMFCACoversValue ((WMFCACover (a) (a b)))))

; Revision across incompatible finite domains fails loud as data.
!(assertEqual
   (wm-fca-revise
     (toy-state)
     (wm-fca-empty (o1 o2 o3) (a b)))
   (WMFCARevisionDomainMismatch (o1 o2) (a b) (o1 o2 o3) (a b)))
