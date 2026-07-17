!(import! &self ./planets_context.metta)

; The published 9 x 7 matrix is complete and keeps explicit zeroes distinct
; from cells absent from another context.
!(assertEqual
   (let $observations
        (eval (wm-fca-state-observations (wm-fca-planets-state)))
     (size-atom $observations))
   63)
!(assertEqual
   (wm-fca-cell-status (wm-fca-planets-state) planets Mercury small)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status (wm-fca-planets-state) planets Mercury moon)
   WMFalse)
!(assertEqual
   (wm-fca-cell-status (wm-fca-planets-state) another Mercury moon)
   WMMissing)

; Independent fcaR closure/derivation examples.
!(assertEqual
   (wm-fca-intent (wm-fca-planets-state) planets (Earth Mars))
   (small near moon))
!(assertEqual
   (wm-fca-extent (wm-fca-planets-state) planets (large moon))
   (Jupiter Saturn))
!(assertEqual
   (wm-fca-closure (wm-fca-planets-state) planets (large moon))
   (large far moon))
!(assertEqual
   (wm-fca-closed-intent?
     (wm-fca-planets-state) planets (large moon))
   False)
!(assertEqual
   (wm-fca-closed-intent?
     (wm-fca-planets-state) planets (large far moon))
   True)

; All published concepts and intents, not merely their counts.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-planets-state) planets WMFCAExactStatusGate))
     (let $intents
          (eval (wm-fca-index-closed-intents-native $index 12))
       (and
         (== (size-atom $intents) 12)
         (wm-fca-same-set?
           $intents (wm-fca-planets-published-intents)))))
   True)
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-planets-state) planets WMFCAExactStatusGate))
     (let $intents
          (eval (wm-fca-index-closed-intents-native $index 12))
       (let $concepts
            (eval (wm-fca-index-concepts-from-intents $index $intents))
         (and
           (== (size-atom $concepts) 12)
           (wm-fca-same-set?
             $concepts (wm-fca-planets-published-concepts))))))
   True)

; Duquenne-Guigues canonical basis and its positive/negative query boundary.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-planets-state) planets WMFCAExactStatusGate))
     (let $basis
          (eval (wm-fca-index-canonical-basis-native $index 22 10))
       (and
         (== (size-atom $basis) 10)
         (and
           (wm-fca-same-set? $basis (wm-fca-planets-published-basis))
           (wm-fca-index-all-implications-hold? $index $basis)))))
   True)
!(assertEqual
   (wm-fca-implication-holds?
     (wm-fca-planets-state)
     planets
     (WMFCAImplication (far) (moon)))
   True)
!(assertEqual
   (wm-fca-implication-holds?
     (wm-fca-planets-state)
     planets
     (WMFCAImplication (moon) (far)))
   False)

; Exact Hasse covers under intent inclusion.
!(assertEqual
   (let $index
        (eval
          (wm-fca-build-index
            (wm-fca-planets-state) planets WMFCAExactStatusGate))
     (let $intents
          (eval (wm-fca-index-closed-intents-native $index 12))
       (let $covers (eval (wm-fca-covers-from-intents $intents))
         (and
           (== (size-atom $covers) 18)
           (wm-fca-same-set?
             $covers (wm-fca-planets-published-covers))))))
   True)

; Cell explanations retain the exact negative observation and provenance.
!(assertEqual
   (wm-fca-explain-cell
     (wm-fca-planets-state) planets Mercury moon)
   ((WMFCAObservation
      planets Mercury moon WMFalse
      planets-Mercury-moon fcaR-v2.0.0-planets fcaR-planets-matrix)))

; Duplicate revision is idempotent by provenance-bearing observation identity.
!(assertEqual
   (let $observations
        (eval
          (wm-fca-state-observations
            (wm-fca-revise
              (wm-fca-planets-state)
              (wm-fca-planets-state))))
     (size-atom $observations))
   63)

; Incremental forgetting and exact remembering agree with fresh recomputation.
(= (wm-fca-planets-without-Pluto-far)
   (wm-fca-forget
     (wm-fca-planets-state)
     (WMFCAScopeStamp planets-Pluto-far)))

(= (wm-fca-planets-restored-Pluto-far)
   (wm-fca-remember
     (wm-fca-planets-without-Pluto-far)
     (WMFCAObservation
       planets Pluto far WMTrue
       planets-Pluto-far fcaR-v2.0.0-planets fcaR-planets-matrix)))

!(assertEqual
   (wm-fca-cell-status
     (wm-fca-planets-without-Pluto-far) planets Pluto far)
   WMMissing)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-planets-without-Pluto-far) planets Neptune far)
   WMTrue)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-planets-restored-Pluto-far) planets Pluto far)
   WMTrue)
!(assertEqual
   (let $restored-state
        (eval (wm-fca-planets-restored-Pluto-far))
     (let $incremental
        (eval
          (wm-fca-build-index
            $restored-state planets WMFCAExactStatusGate))
       (let $fresh
          (eval
            (wm-fca-build-index
              (wm-fca-planets-state) planets WMFCAExactStatusGate))
         (wm-fca-same-set?
           (wm-fca-index-columns $incremental)
           (wm-fca-index-columns $fresh)))))
   True)

; A distinct indeterminate report produces Unknown and can be forgotten exactly.
(= (wm-fca-planets-with-review)
   (wm-fca-remember
     (wm-fca-planets-state)
     (WMFCAObservation
       planets Pluto far WMUnknown
       planets-Pluto-far-review review-source review-group)))

!(assertEqual
   (wm-fca-cell-status
     (wm-fca-planets-with-review) planets Pluto far)
   WMUnknown)
!(assertEqual
   (wm-fca-cell-status
     (wm-fca-forget
       (wm-fca-planets-with-review)
       (WMFCAScopeStamp planets-Pluto-far-review))
     planets Pluto far)
   WMTrue)
