; Prolog-constructed NaN, rational, and float_overflow=infinity numeric
; equality cases split from numeric_equality.metta (requires libswipl).
(= (dag $n $leaf) (if (== $n 0) $leaf (let $t (dag (- $n 1) $leaf) (node $t $t))))
!(println! (nan (let $_ (translatePredicate (is $n nan)) (== $n $n)) (let $_ (translatePredicate (is $n nan)) (== (a $n) (a $n))) (let $_ (translatePredicate (is $n nan)) (!= $n $n)) (let $_ (translatePredicate (is $n nan)) (< $n 1)) (let $_ (translatePredicate (is $n nan)) (>= $n 1))))
!(println! (rationals (let $_ (translatePredicate (number_string $half "1r2")) ($half (== $half 0.5) (!= $half 0.5) (== (x $half) (x 0.5)) (< $half 0.75))) (let $_ (translatePredicate (number_string $q "7r22")) ($q (== $q 0.3181818181818182) (* $q 22)))))
!(println! (shared-nan (let $_ (translatePredicate (is $n nan)) (let $d (dag 40 $n) (== $d $d)))))
!(let $flag (translatePredicate (set_prolog_flag float_overflow infinity)) infinity-enabled)
!(println! (infinity (== inf inf) (== (+ inf 0) (+ inf 0)) (== inf (+ inf 0))))
