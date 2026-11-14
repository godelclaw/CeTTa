; Builds without Prolog have no CLP(FD) solver: a call whose arguments are
; not all bound cannot post its constraint, so it raises instantiation_error
; naming the reference predicate, instead of coming back as its own call.
; (The Prolog build posts the constraint.) A bound non-integer is still a
; domain error, and a bound zero divisor still has no answer.
(= (row $q $v) ($q $v))
!(row "(#+ $x 2)" (catch (#+ $x 2)))
!(row "(#- 7 $y)" (catch (#- 7 $y)))
!(row "(#* $x $y)" (catch (#* $x $y)))
!(row "(#div 7 $x)" (catch (#div 7 $x)))
!(row "(#// $x 2)" (catch (#// $x 2)))
!(row "(#mod $x 3)" (catch (#mod $x 3)))
!(row "(#min $x 1)" (catch (#min $x 1)))
!(row "(#max 1 $x)" (catch (#max 1 $x)))
!(row "(#< $x 3)" (catch (#< $x 3)))
!(row "(#> 3 $x)" (catch (#> 3 $x)))
!(row "(#= $x 3)" (catch (#= $x 3)))
!(row "(#\\= $x $y)" (catch (#\= $x $y)))
!(row "(#+ $x 1.5)" (catch (#+ $x 1.5)))
!(row "(#mod $x 0)" (catch (#mod $x 0)))
