; Prolog-dependent constraint and callPredicate exception cases of
; identity_forwarding.metta (requires libswipl / ENABLE_LIB_PROLOG=1).

; Delayed goals on the binder wake when it gets its value.
!(collapse (let $c (#> $x 2) (chain 1 $x $x)))
!(collapse (let $c (#> $x 2) (chain 5 $x $x)))
!(collapse (let $u (translatePredicate (dif $x 1)) (chain 1 $x $x)))
!(let $u (translatePredicate (freeze $x (Predicate (writeln woke)))) (let $d (chain (+ 0 1) $x $x) $d))

; Forwarding preserves an escaped exception's enclosing handler.
!(catch (chain (callPredicate (Predicate (throw identity-forward-fault))) $v $v))
!(catch (let $v (callPredicate (Predicate (throw identity-forward-fault))) $v))
