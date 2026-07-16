;; NAL-7: Temporal Inference Rules
;;!Temporal sequencing and induction
(= (|-nal7 ($A $T1) ($B $T2)) ((=/> $A $B) (Truth_Induction $T1 $T2)))
(= (|-nal7 ($A $T1) ($B $T2)) ((&/ $A $B) (Truth_Intersection $T1 $T2)))
;;!Syllogisms
(= (|-nal7 ((=/> $a $b) $T1) ((=/> $b $c) $T2)) ((=/> $a $c) (Truth_Deduction $T1 $T2)))
(= (|-nal7 ((=/> $a $b) $T1) ((=/> $a $c) $T2)) ((=/> $c $b) (Truth_Induction $T1 $T2)))
(= (|-nal7 ((=/> $a $c) $T1) ((=/> $b $c) $T2)) ((=/> $b $a) (Truth_Abduction $T1 $T2)))
(= (|-nal7 ((=|> $a $b) $T1) ((=|> $b $c) $T2)) ((=|> $a $c) (Truth_Deduction $T1 $T2)))
(= (|-nal7 ((=|> $a $b) $T1) ((=|> $a $c) $T2)) ((=|> $c $b) (Truth_Induction $T1 $T2)))
(= (|-nal7 ((=|> $a $c) $T1) ((=|> $b $c) $T2)) ((=|> $b $a) (Truth_Abduction $T1 $T2)))
;;!Equivalence
(= (|-nal7 ((</> $a $b) $T1) ((</> $b $c) $T2)) ((</> $a $c) (Truth_Resemblance $T1 $T2)))
(= (|-nal7 ((</> $a $b) $T1) ((=/> $b $c) $T2)) ((=/> $a $c) (Truth_Analogy $T1 $T2)))
(= (|-nal7 ((=/> $a $b) $T1) ((</> $b $c) $T2)) ((=/> $a $c) (Truth_Analogy $T1 $T2)))
(= (|-nal7 ((<|> $a $b) $T1) ((<|> $b $c) $T2)) ((<|> $a $c) (Truth_Resemblance $T1 $T2)))
(= (|-nal7 ((<|> $a $b) $T1) ((=|> $b $c) $T2)) ((=|> $a $c) (Truth_Analogy $T1 $T2)))
(= (|-nal7 ((=|> $a $b) $T1) ((<|> $b $c) $T2)) ((=|> $a $c) (Truth_Analogy $T1 $T2)))
;;!Conditional
(= (|-nal7 ($A $T1) ((=/> $A $B) $T2)) ($B (Truth_Deduction $T1 $T2)))
(= (|-nal7 ($A $T1) ((=|> $A $B) $T2)) ($B (Truth_Deduction $T1 $T2)))
(= (|-nal7 ($B $T1) ((=/> $A $B) $T2)) ($A (Truth_Abduction $T1 $T2)))
(= (|-nal7 ($B $T1) ((=|> $A $B) $T2)) ($A (Truth_Abduction $T1 $T2)))
;;!Equivalence inrto
(= (|-nal7 ((=|> $A $B) $T1) ((=|> $B $A) $T2)) ((<|> $A $B) (Truth_Intersection $T1 $T2)))

(= (|-t $a $b)
   (unique-atom (collapse (superpose ((|-nal7 $a $b) (|-nal7 $b $a))))))
