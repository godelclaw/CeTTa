; PeTTa's copy_term/1 (SWI copy_term/2): deep copy replacing every distinct
; unbound variable with a fresh variable while preserving internal sharing.
; Ground terms return unchanged.
!(copy_term 42)
!(copy_term abc)
!(copy_term ())
!(copy_term (a 1 "s" True))
!(== (a 1 "s") (copy_term (a 1 "s")))

; Bare variable gets a fresh variable independent of the original.
!(let $y (copy_term $x) (let $x 1 (and (is-var $y) (== $x 1))))

; Internal sharing is preserved while breaking sharing with the original.
!(let ($a $b) (copy_term ($x $x))
   (let $x 9
     (and (is-var $a) (== $a $b))))
!(let ($a $b) (copy_term ($x $x))
   (let $a 7
     (and (== $b 7) (is-var $x))))

; Distinct variables stay distinct.
!(let ($a $b) (copy_term ($x $y))
   (let $a 1 (is-var $b)))

; Open cons cells preserve sharing and freshen variables.
!(let (cons $a $b) (copy_term (cons $x $x))
   (let $x 1 (and (is-var $a) (== $a $b))))
!(let (cons $a $b) (copy_term (cons $x $y))
   (let $a 1 (is-var $b)))

; Nested sharing and mixed bound/unbound variables.
!(let $bound 5
   (let (f $a (g $b $c)) (copy_term (f $bound (g $x $x)))
     (let $x 99
       (let $b 12
         (and (== $a 5) (and (== $c 12) (== $x 99)))))))

; Inside functions (compiled tiers and reference routes) and transactions.
(= (dup-fresh $t) (copy_term $t))
!(let ($a $b) (dup-fresh ($x $x))
   (let $x 1 (and (is-var $a) (== $a $b))))
!(collapse (transaction (copy_term (k 1 2))))

; Dynamic head dispatch.
!(let $f copy_term (let ($a $b) ($f ($x $x)) (let $x 3 (and (is-var $a) (== $a $b)))))

; Closures and partial applications preserve behavior and freshen captured vars.
(= (add2 $x $y) (+ $x $y))
!(let $f (|-> ($x) (+ $x 1)) (let $g (copy_term $f) (and (== $f $g) (== ($g 4) 5))))
!(let $p (add2 10) (let $q (copy_term $p) ($q 5)))
(= (cap-pair $a $b) (box (|-> ($x) (pair $a $b $x))))
!(let (box $f) (cap-pair $n $n)
   (let $g (copy_term $f)
     (let $n 42
       (let (pair $u $v 7) ($g 7)
         (and (is-var $u) (== $u $v))))))
