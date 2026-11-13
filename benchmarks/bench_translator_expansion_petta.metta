; Per-use cost of a translator rule against the code it stands for.
; Run with `!(tx:one VARIANT N)`; the line printed is (VARIANT N NANOSECONDS).
; scripts/bench_translator_expansion.sh times every variant at N, 4N and 16N
; with the rule expanded once (the default) and run at each call
; (CETTA_PETTA_TRANSLATOR_EXPANSION=0).
!(import! &self (library outcome))
!(import! &self (library system))

; A template rule and the let it stands for.
(: tb:bind (-> Atom Atom Atom %Undefined%))
(= (tb:bind $var $source $body) (quote (let $var $source $body)))
!(add-translator-rule! tb:bind)
(= (tb:rule $x) (tb:bind $y (+ $x 1) (* $y 2)))
(= (tb:hand $x) (let $y (+ $x 1) (* $y 2)))

; A four-binding chain that stops at the first failure: written by hand, as
; the library's out:let*, and as a plain let*.
(= (tb:plain $x) (let* (($a (+ $x 1)) ($b (+ $a 1)) ($c (+ $b 1)) ($d (+ $c 1))) $d))
(= (tb:checked $x)
   (let $a (+ $x 1)
     (case $a (((Error $w $r) $a)
       ($a1 (let $b (+ $a1 1)
         (case $b (((Error $w2 $r2) $b)
           ($b1 (let $c (+ $b1 1)
             (case $c (((Error $w3 $r3) $c)
               ($c1 (+ $c1 1))))))))))))))
(= (tb:out $x) (out:let* (($a (+ $x 1)) ($b (+ $a 1)) ($c (+ $b 1)) ($d (+ $c 1))) $d))
; What out:let* expands to, written out: its checks are the library's (three
; failure shapes and a reported mismatch), more than tb:checked makes.
(= (tb:out-by-hand $x)
   (let $v1 (+ $x 1)
     (case $v1
       (((Error $w1 $r1) $v1) ((Error $e1) $v1) ((Error $p1 $q1 $s1) $v1)
        ($a (let $v2 (+ $a 1)
              (case $v2
                (((Error $w2 $r2) $v2) ((Error $e2) $v2) ((Error $p2 $q2 $s2) $v2)
                 ($b (let $v3 (+ $b 1)
                       (case $v3
                         (((Error $w3 $r3) $v3) ((Error $e3) $v3) ((Error $p3 $q3 $s3) $v3)
                          ($c (let $v4 (+ $c 1)
                                (case $v4
                                  (((Error $w4 $r4) $v4) ((Error $e4) $v4)
                                   ((Error $p4 $q4 $s4) $v4)
                                   ($d $d)
                                   ($o4 (out:unsolvable out:let* (no-match $o4)))))))
                          ($o3 (out:unsolvable out:let* (no-match $o3)))))))
                 ($o2 (out:unsolvable out:let* (no-match $o2)))))))
        ($o1 (out:unsolvable out:let* (no-match $o1)))))))

; A two-value guard before a computation.
(= (tb:guard-hand $o $v)
   (case ($o $v)
     ((((Error $w $r) $ignored) (Error $w $r))
      (($ignored (Error $w $r)) (Error $w $r))
      (($a $b) (+ $a $b)))))
(= (tb:guard-out $o $v) (out:with ($o $v) (+ $o $v)))

; The failure path: the first binding fails.
(= (tb:fail-hand $x)
   (let $a (out:unsolvable tb bad)
     (case $a (((Error $w $r) $a) ($a1 (let $b (+ $a1 1) $b))))))
(= (tb:fail-out $x) (out:let* (($a (out:unsolvable tb bad)) ($b (+ $a 1))) $b))

; A condition that decides on True or False only.
(= (tb:if-hand $x)
   (let $c (> $x 0)
     (if (== $c True) pos (if (== $c False) neg (out:no-verdict tb $c)))))
(= (tb:if-out $x) (out:if (> $x 0) pos neg))

(= (tb:step rule $n) (tb:rule $n))
(= (tb:step hand $n) (tb:hand $n))
(= (tb:step plain $n) (tb:plain $n))
(= (tb:step checked $n) (tb:checked $n))
(= (tb:step out $n) (tb:out $n))
(= (tb:step out-by-hand $n) (tb:out-by-hand $n))
(= (tb:step guard-hand $n) (tb:guard-hand $n 1))
(= (tb:step guard-out $n) (tb:guard-out $n 1))
(= (tb:step fail-hand $n) (case (tb:fail-hand $n) (((Error $w $r) 1) ($v 0))))
(= (tb:step fail-out $n) (case (tb:fail-out $n) (((Error $w $r) 1) ($v 0))))
(= (tb:step if-hand $n) (case (tb:if-hand $n) ((pos 1) ($v 0))))
(= (tb:step if-out $n) (case (tb:if-out $n) ((pos 1) ($v 0))))

(= (tb:loop $variant $n $acc)
   (if (== $n 0) $acc
     (tb:loop $variant (- $n 1) (+ $acc (tb:step $variant $n)))))

(: tx:one (-> Atom Atom %Undefined%))
(= (tx:one $variant $n)
   (let* (($t0 (system:monotonic-ns)) ($r (tb:loop $variant $n 0))
          ($t1 (system:monotonic-ns)))
     (println! ($variant $n (- $t1 $t0)))))
