; lib/outcome under HE: the shared interface, where HE's own rule (an Error an
; argument or a binding produces ends the computation) already holds.
!(import! &self (library outcome))

(= (bad) (out:unsolvable bad-input (missing name)))
(= (refused) (out:forbidden policy (quota exceeded)))
(= (cut-off) (out:incomplete scan (budget 10)))
(= (seen $tag $value) (let $_ (println! (ran $tag)) $value))

; Observers read a failure that arrives bound.
!(collapse (chain (eval (bad)) $f (out:failed? $f)))
!(collapse (chain (eval (refused)) $f (out:kind $f)))
!(collapse (chain (eval (cut-off)) $f (out:detail $f)))
!(collapse (chain (eval (bad)) $f (out:at outer $f)))
!(collapse (out:kind 5))
; HE ends the call at a failure its argument produces, before the observer.
!(collapse (out:failed? (bad)))

!(collapse (out:let* (($a (seen a 1)) ($b (seen b (bad))) ($c (seen c 3))) (seen body (+ $a $c))))
!(collapse (out:let* (($a (seen a 1)) ($b (seen b 2))) (+ $a $b)))
; HE does not report the failing answer beside the values.
!(collapse (out:let* (($x (superpose (1 (Error e first) 3)))) (* $x 2)))
!(collapse (out:let* (($x (superpose ()))) (* $x 2)))

!(collapse (out:all ((seen 1 10) (seen 2 (refused)) (seen 3 (bad)))))
!(collapse (out:all ((+ 1 1) (* 2 3) 4)))

!(collapse (chain (eval (bad)) $f (out:cons a $f)))
!(collapse (chain (bad) $f (cons-atom a $f)))
!(collapse (out:cons a (b c)))
!(collapse (out:append (1 2) (3 4)))
!(collapse (out:finish (out:snoc (out:snoc (out:snoc () 1) 2) 3)))

!(collapse (out:if (== 1 1) yes no))
!(collapse (out:if (bad) yes no))
!(collapse (out:if maybe yes no))
!(collapse (out:and ((== 1 1) (seen second False) (seen third (bad)))))
!(collapse (out:or ((== 1 2) (seen second True) (seen never False))))
!(collapse (out:require (> 2 3) Unsolvable size too-small))

!(collapse (out:recover (bad) $f (handled (out:kind $f))))
!(collapse (out:or-else (refused) fallback))

!(collapse (out:one (superpose (7)) lookup))
!(collapse (out:one (superpose ()) lookup))
!(collapse (out:one (superpose (1 2)) lookup))
!(collapse (out:first (superpose ()) (Region a b)))

!(collapse (out:let* (($x 1) ($x 2)) $x))
!(collapse (out:let* (((P $y) (Q 1))) $y))
!(collapse (out:let (P $y) (P 5) (+ $y 1)))
!(collapse (out:let* ((($u $v) (seen pair (P Q)))) ($v $u)))

!(collapse (out:reify (bad)))
!(collapse (out:reify 5))
!(collapse (== (out:reify (refused)) (Failed policy Forbidden (quota exceeded))))
!(collapse (out:reflect (Failed policy Forbidden (quota exceeded))))
