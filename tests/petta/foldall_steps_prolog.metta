; Prolog-dependent delayed-constraint cases of foldall_steps.metta
; (uses translatePredicate (#< $t 5) and CLP(FD) #+ on unbound variables;
; requires libswipl / ENABLE_LIB_PROLOG=1).

; The state is a copy that takes the goals delayed on its variables along,
; as a collection's copies do: they hold when the fold's value is bound,
; and a step that refuses its constraint leaves the state as it was.
(= (bounded $v $s) (let $t (#+ $s $v) (let $_ (translatePredicate (#< $t 5)) $t)))
!(collapse (let* (($f (foldall bounded (superpose (1 2)) $z)) ($f 4)) ok))
!(collapse (let* (($f (foldall bounded (superpose (1 2)) $z)) ($f 6)) ok))
!(foldall bounded (superpose (1 2)) 1)
!(collapse (foldall bounded (superpose (1 2)) 3))
