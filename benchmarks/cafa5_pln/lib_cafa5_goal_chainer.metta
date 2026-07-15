; CAFA5 provenance and evidence helpers over CeTTa's typed goal chainer.
;
; Primary fusion is conservative maximum on a named normalized ranking scale.
; Calibrated noisy-OR remains typed and is available only for distinct groups.

!(import! &self ../genomic_pln/lib_pln_inference_rules.metta)
!(import! &self ../../lib/lib_evidence_types.metta)

(= (cafa-ordinal-score $value)
   (Evidence.Ordinal cafa5-normalized-ranking $value))

(= (cafa-max-step $acc $next)
   (let (ordinal-score cafa5-normalized-ranking $best)
        (Evidence.OrdinalMax
          (cafa-ordinal-score $acc)
          (cafa-ordinal-score $next))
     $best))

(= (cafa-group-score-step $acc ($key ($label $score)))
   (cafa-max-step $acc $score))

(= (cafa-calibrated-group-step
      $calibration
      (cafa-noisy-or-empty)
      ($key ($group $score)))
   (Evidence.CalibratedProbability
     $calibration $group (dependence-group $group) $score))

(= (cafa-calibrated-group-step
      $calibration
      (calibrated-probability
        $calibration $acc-group $acc-source $acc-probability)
      ($key ($group $score)))
   (Evidence.NoisyOr
     (calibrated-probability
       $calibration $acc-group $acc-source $acc-probability)
     (Evidence.CalibratedProbability
       $calibration $group (dependence-group $group) $score)))

(= (cafa-calibrated-noisy-or
      $calibration
      $left-group $left-source $left
      $right-group $right-source $right)
   (Evidence.NoisyOr
     (Evidence.CalibratedProbability
       $calibration $left-group $left-source $left)
     (Evidence.CalibratedProbability
       $calibration $right-group $right-source $right)))

(= (cafa-proof-source
      (cafa-direct
        (cafa-pred-fact $source $group $protein $term $score)))
   $source)

(= (cafa-proof-group
      (cafa-direct
        (cafa-pred-fact $source $group $protein $term $score)))
   $group)

(= (cafa-proof-score
      (cafa-direct
        (cafa-pred-fact $source $group $protein $term $score)))
   $score)

(= (cafa-proof-packet
      (cafa-direct
        (cafa-pred-fact $source $group $protein $term $score)))
   (cafa-prediction $source $group $protein $term $score))
