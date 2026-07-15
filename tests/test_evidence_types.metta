!(import! &self lib_evidence_types)

; Positive examples.
!(assertEqual
   (Evidence.OrdinalMax (Evidence.Ordinal blast-bit-score 17)
                        (Evidence.Ordinal blast-bit-score 23))
   (ordinal-score blast-bit-score 23))

!(assertEqual
   (Evidence.NoisyOr
     (Evidence.CalibratedProbability cal-v1 sequence source-a 0.8)
     (Evidence.CalibratedProbability cal-v1 structure source-b 0.5))
   (calibrated-probability cal-v1
     (independent-groups sequence structure)
     (fusion source-a source-b)
     0.9))

!(assertEqual
   (Evidence.ReviseDisjoint
     (Evidence.PLN 3 1 (a b))
     (Evidence.PLN 2 4 (c d)))
   (pln-evidence 5 5 (a b c d)))

!(assertEqual
   (Evidence.ToSTV (Evidence.PLN 3 1 (packet-a)))
   (stv 0.75 0.8))

; Negative examples: no value is produced for unjustified combinations.
!(assertEqual
   (Evidence.OrdinalMax (Evidence.Ordinal blast-bit-score 17)
                        (Evidence.Ordinal cosine-similarity 0.8))
   (Evidence.OrdinalMax (ordinal-score blast-bit-score 17)
                        (ordinal-score cosine-similarity 0.8)))

!(assertEqual
   (collapse
     (Evidence.NoisyOr
       (Evidence.CalibratedProbability cal-v1 sequence source-a 0.8)
       (Evidence.CalibratedProbability cal-v1 sequence source-b 0.5)))
   ())

!(assertEqual
   (Evidence.NoisyOr (Evidence.Ordinal blast-bit-score 17)
                     (Evidence.Ordinal blast-bit-score 23))
   (Evidence.NoisyOr (ordinal-score blast-bit-score 17)
                     (ordinal-score blast-bit-score 23)))

!(assertEqual
   (collapse
     (Evidence.ReviseDisjoint
       (Evidence.PLN 3 1 (a b))
       (Evidence.PLN 2 4 (b c))))
   ())
