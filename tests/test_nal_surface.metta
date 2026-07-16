!(import! &self ../lib/nal.metta)
!(import! &self ../lib/nal7.metta)

!(assertEqual (Truth_Negation (stv 0.75 0.8)) (stv 0.25 0.8))
!(assertEqual (Truth_Deduction (stv 1.0 0.9) (stv 0.8 0.7))
               (stv 0.8 0.504))

;; NAL7 supplies both temporal-induction and sequence-formation candidates.
!(assertEqual
   (collapse (|-nal7 (rain (stv 1.0 0.0)) (wet (stv 0.8 0.0))))
   (((=/> rain wet) (stv 1.0 0.0))
    ((&/ rain wet) (stv 0.8 0.0))))
