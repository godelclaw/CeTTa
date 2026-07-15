!(import! &self ./lib_cafa5_goal_chainer.metta)
!(import! &cafa5-rb ./cafa5_rules.metta)
!(import! &cafa5-kb ./cafa5_fixture.metta)

; The chainer must expose all three leaf provenance routes.
!(collapse
   (let (: $proof
           (cafa-candidate protein-p go-0001 $group $source $score))
        (bc &cafa5-kb &cafa5-rb (fromNumber 1)
            (: $proof
               (cafa-candidate protein-p go-0001 $group $source $score)))
     (cafa-proof-route
       (cafa-proof-group $proof)
       (cafa-proof-source $proof)
       (cafa-proof-score $proof))))

; Same-group sources collapse to 0.8 rather than combining to 0.94.
!(fold
   (let (: $proof
           (cafa-candidate protein-p go-0001 sequence-shared $source $score))
        (bc &cafa5-kb &cafa5-rb (fromNumber 1)
            (: $proof
               (cafa-candidate protein-p go-0001 sequence-shared $source $score)))
     $score)
   0.0
   $acc
   $next
   (eval (cafa-max-step $acc $next)))

; Primary fusion remains conservative maximum across dependence groups.
!(let* (($sequence
          (fold
            (let (: $proof
                    (cafa-candidate protein-p go-0001 sequence-shared $source $score))
                 (bc &cafa5-kb &cafa5-rb (fromNumber 1)
                     (: $proof
                        (cafa-candidate protein-p go-0001 sequence-shared $source $score)))
              $score)
            0.0
            $acc
            $next
            (eval (cafa-max-step $acc $next))))
         ($structure
          (fold
            (let (: $proof
                    (cafa-candidate protein-p go-0001 structure-independent $source $score))
                 (bc &cafa5-kb &cafa5-rb (fromNumber 1)
                     (: $proof
                        (cafa-candidate protein-p go-0001 structure-independent $source $score)))
              $score)
            0.0
            $acc
            $next
            (eval (cafa-max-step $acc $next)))))
   (cafa-fused-primary protein-p go-0001
                       (cafa-max-step $sequence $structure)))

; A named, shared calibration permits noisy-OR across distinct groups.
!(cafa-calibrated-noisy-or
    cal-v1
    sequence-shared homology-a 0.8
    structure-independent structure-c 0.5)

; Negative example: same-group evidence is not combined by noisy-OR.
!(collapse
   (cafa-calibrated-noisy-or
     cal-v1
     sequence-shared homology-a 0.8
     sequence-shared homology-b 0.7))

; Negative example: differently calibrated probabilities cannot be combined.
!(collapse
   (Evidence.NoisyOr
     (Evidence.CalibratedProbability cal-v1 sequence-shared homology-a 0.8)
     (Evidence.CalibratedProbability cal-v2 structure-independent structure-c 0.5)))

; A missing group contributes no support.
!(fold
   (let (: $proof
           (cafa-candidate protein-p go-0001 absent-group $source $score))
        (bc &cafa5-kb &cafa5-rb (fromNumber 1)
            (: $proof
               (cafa-candidate protein-p go-0001 absent-group $source $score)))
     $score)
   0.0
   $acc
   $next
   (eval (cafa-max-step $acc $next)))
