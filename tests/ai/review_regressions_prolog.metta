!(ai:experiment failure-values)
; The atom-only directive cannot export the machine's pending solver owner.
!(collapse (let $_ (translatePredicate (dif $x 1)) (Box $x)))
