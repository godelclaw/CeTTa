; Typed evidence values and the combinations that are semantically justified.
;
; Unsupported combinations intentionally have no reduction rule.  In
; particular, ordinal scores are not probabilities, and overlapping PLN
; provenance is not silently counted twice.

!(import! &self lib_wmpln)
!(import! &self lib_wmpln_evidence)
!(import! &self lib_overlap_corrected_revision)

(= (Evidence.Ordinal $scale $value)
   (ordinal-score $scale $value))

(= (Evidence.Binary $source $observed)
   (binary-evidence $source $observed))

(= (Evidence.CalibratedProbability $calibration $group $source $probability)
   (if (and (>= $probability 0) (<= $probability 1))
       (calibrated-probability $calibration $group $source $probability)
       (empty)))

(= (Evidence.PLN $positive $negative $stamp)
   (if (and (>= $positive 0) (>= $negative 0))
       (pln-evidence $positive $negative $stamp)
       (empty)))

; Maximum is meaningful only within the same explicitly named ordinal scale.
(= (Evidence.OrdinalMax
      (ordinal-score $scale $left)
      (ordinal-score $scale $right))
   (let $best (if (> $left $right) $left $right)
        (ordinal-score $scale $best)))

; Independent calibrated probabilities may be fused by noisy-OR.  Evidence in
; the same dependence group deliberately has no matching equation.
(= (Evidence.NoisyOr
      (calibrated-probability $calibration $left-group $left-source $left)
      (calibrated-probability $calibration $right-group $right-source $right))
   (if (== $left-group $right-group)
       (empty)
       (let $probability (- 1 (* (- 1 $left) (- 1 $right)))
            (calibrated-probability
              $calibration
              (independent-groups $left-group $right-group)
              (fusion $left-source $right-source)
              $probability))))

; PLN count revision is valid here only for disjoint stamps.  Overlap-aware
; policies must be chosen explicitly by the caller instead of being guessed.
(= (Evidence.ReviseDisjoint
      (pln-evidence $left-positive $left-negative $left-stamp)
      (pln-evidence $right-positive $right-negative $right-stamp))
   (if (== (StampIntersectionCount $left-stamp $right-stamp) 0)
       (let* (($positive (+ $left-positive $right-positive))
              ($negative (+ $left-negative $right-negative))
              ($stamp (TupleConcat $left-stamp $right-stamp)))
         (pln-evidence $positive $negative $stamp))
       (empty)))

(= (Evidence.ToSTV (pln-evidence $positive $negative $stamp))
   (evidence-toSTV (evidence $positive $negative)))
