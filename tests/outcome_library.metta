; lib/outcome: failures are one answer, absence is data, zero stays zero.
!(import! &self (library outcome))

(= (bad) (out:unsolvable bad-input (missing name)))
(= (refused) (out:forbidden policy (quota exceeded)))
(= (cut-off) (out:incomplete scan (budget 10)))
(= (seen $tag $value) (let $_ (println! (ran $tag)) $value))

; Classification: every Error is a failure; legacy reasons read as Fault.
!(collapse (map-atom ((bad) (refused) (cut-off) (Error x y) (Error t c z) (Error e) Error () 1 (Empty s) (ok 1))
   $v (out:failed? $v)))
!(collapse (map-atom ((bad) (refused) (cut-off) (out:fault io eof) (Error (f 1) "message") 5) $v (out:kind $v)))
!(collapse (out:detail (bad)))
!(collapse (out:at outer (bad)))
!(collapse (out:at outer 7))

; out:let* stops at the first failure; nothing after it runs.
!(collapse (out:let* (($a (seen a 1)) ($b (seen b (bad))) ($c (seen c 3))) (seen body (+ $a $c))))
!(collapse (out:let* (($a (seen a 1)) ($b (seen b 2))) (+ $a $b)))
!(collapse (out:let* ((($x $y) (seen pair (P Q)))) ($y $x)))
; Branch-local: each answer continues or stops on its own.
!(collapse (out:let* (($x (superpose (1 (Error e first) 3)))) (* $x 2)))
; Zero is not a failure: no answers stay no answers.
!(collapse (out:let* (($x (superpose ()))) (* $x 2)))

; out:all: values in order, or the earliest failure; later sources never run.
!(collapse (out:all ((seen 1 10) (seen 2 (refused)) (seen 3 (bad)))))
!(collapse (out:all ((+ 1 1) (* 2 3) 4)))
!(collapse (out:all ()))

; Lists never carry a failure as elements.
!(collapse (out:cons a (bad)))
!(collapse (out:cons (refused) (bad)))
!(collapse (out:cons a (b c)))
!(collapse (out:append (1 2) (3 4)))
!(collapse (out:append (1 2) (cut-off)))
!(collapse (out:finish (out:snoc (out:snoc (out:snoc () 1) 2) 3)))
!(collapse (out:finish (out:snoc (out:snoc () 1) (bad))))
; Compare: cons-atom splices the failure into a plain list.
!(collapse (cons-atom a (bad)))

; out:with checks computed values, then runs its body.
!(collapse (let* (($u 1) ($v (bad))) (out:with ($u $v) (seen with-body done))))
!(collapse (let* (($u 1) ($v 2)) (out:with ($u $v) (+ $u $v))))

; Conditions decide only on True or False.
!(collapse (out:if (== 1 1) yes no))
!(collapse (out:if (bad) yes no))
!(collapse (out:if maybe yes no))
!(collapse (if (bad) yes no))
!(collapse (out:and ((== 1 1) (seen second False) (seen third (bad)))))
!(collapse (out:and ((== 1 2) (seen never True))))
!(collapse (out:or ((== 1 2) (seen second True) (seen never False))))
!(collapse (out:or (False (refused))))
!(collapse (out:require (> 3 2) Unsolvable size too-small))
!(collapse (out:require (> 2 3) Unsolvable size too-small))

; Observing failures, including raised ones.
!(collapse (out:recover (bad) $f (handled (out:kind $f))))
!(collapse (out:recover 5 $f (handled $f)))
!(collapse (out:or-else (refused) fallback))
!(collapse (out:kind (out:catch (+ 1 a))))

; Zero observed as data.
!(collapse (out:one (superpose (7)) lookup))
!(collapse (out:one (superpose ()) lookup))
!(collapse (out:one (superpose (1 2)) lookup))
!(collapse (out:first (superpose ()) (Region a b)))
!(collapse (out:first (superpose (5 6)) (Region a b)))
!(collapse (out:absent? (out:first (superpose ()) here)))

; A binding pattern that does not match is a failure, not a silent zero.
!(collapse (out:let* (($x 1) ($x 2)) $x))
!(collapse (out:let* (((P $y) (Q 1))) $y))
!(collapse (out:let (P $y) (P 5) (+ $y 1)))
