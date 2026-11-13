; Translator rules run once, where the code calling them is installed or a
; directive is translated.  Every line answers the same whether a rule runs
; there or at each call (CETTA_PETTA_TRANSLATOR_EXPANSION=0); the Makefile
; target runs this file both ways.

; A rule whose body is a template.
(: tx:for (-> Atom Atom Atom %Undefined%))
(= (tx:for $var $collection $body)
   (quote (let $var (superpose $collection) $body)))
!(add-translator-rule! tx:for)

; A rule that walks the written spine of its argument, one binding a round.
(: tx:let* (-> Atom Atom %Undefined%))
(= (tx:let* $bindings $body)
   (if (== $bindings ()) (quote $body)
     (let* (($binding (car-atom $bindings)) ($rest (cdr-atom $bindings))
            ($pattern (car-atom $binding))
            ($source (car-atom (cdr-atom $binding))))
       (quote (let $tx:v $source
                (case $tx:v
                  (((Bad $tx:why) $tx:v)
                   ($pattern (tx:let* $rest $body))
                   ($tx:o (Bad (no-match $tx:o))))))))))
!(add-translator-rule! tx:let*)

; A rule with no signature: its arguments are values.
(= (tx:pair $left $right) (quote (Pair $left $right)))
!(add-translator-rule! tx:pair)

(= (tx:parity $items)
   (tx:for $x $items (if (== (% $x 2) 0) (even $x) (odd $x))))
!(test (collapse (tx:parity (3 4 5))) ((odd 3) (even 4) (odd 5)))
!(test (collapse (tx:for $y (1 2 3) (* $y 10))) (10 20 30))

(= (tx:chain $x)
   (tx:let* (($a (+ $x 1)) ($b (* $a 2)) ((Pair $c $d) (Pair $b $a))) ($c $d)))
!(test (tx:chain 3) (8 4))
(= (tx:fails $x) (tx:let* (($a (Bad early)) ($b (seen-never $a))) $b))
!(test (tx:fails 1) (Bad early))
(= (tx:mismatch $x) (tx:let* (((Pair $p $q) (Single $x))) $p))
!(test (tx:mismatch 7) (Bad (no-match (Single 7))))
; Two expansions in one body, and a call variable spelled like the rule's
; own: neither captures the other.
(= (tx:two $tx:v)
   (tx:let* (($a (+ $tx:v 1)))
     (tx:let* (($b (+ $a 1)) ($tx:o (+ $b 1))) ($tx:v $a $b $tx:o))))
!(test (tx:two 10) (10 11 12 13))
; A nondeterministic source: each branch binds on its own.
(= (tx:branches) (tx:let* (($a (superpose (1 2 3))) ($b (* $a $a))) $b))
!(test (collapse (tx:branches)) (1 4 9))
; Recursion through an expanded body: every activation has fresh variables.
(= (tx:count $n)
   (tx:let* (($done (== $n 0)))
     (if $done 0 (tx:let* (($rest (tx:count (- $n 1)))) (+ $rest 1)))))
!(test (tx:count 25) 25)
; Rule calls in branches, case arms, arguments and data.
(= (tx:places $x)
   (if (> $x 0)
     (case (tx:pair $x 1)
       (((Pair $p $q) (Seen (tx:pair $p (tx:let* (($r (+ $q 1))) $r))))))
     (tx:let* (($n (- 0 $x))) (Neg $n))))
!(test (tx:places 4) (Seen (Pair 4 2)))
!(test (tx:places -2) (Neg 2))
!(test (collapse (superpose ((tx:pair 1 2) (tx:let* (($z 5)) $z)))) ((Pair 1 2) 5))

; A held argument is data, wherever its rule calls stand.
(: tx:hold (-> Atom Atom))
(= (tx:hold $code) $code)
!(test (tx:hold (tx:pair 1 2)) (quote (tx:pair 1 2)))
(= (tx:held-body) (tx:hold (tx:let* (($a 1)) $a)))
!(test (tx:held-body) (quote (tx:let* (($a 1)) $a)))
!(test (quote (tx:pair 1 2)) (quote (tx:pair 1 2)))
; A function whose result is Atom answers its body as written.
(: tx:code (-> Atom))
(= (tx:code) (tx:pair 3 4))
!(test (tx:code) (quote (tx:pair 3 4)))
; An equation added as data keeps its body as written in the Space.
(= (tx:stored $x) (tx:pair $x 0))
!(test (collapse (match &self (= (tx:stored $x) $body) $body)) (quote ((tx:pair $x 0))))
!(test (tx:stored 9) (Pair 9 0))

; Rules whose answer is not decided by what is written run at each call.
; A test of a call's value:
(: tx:peek (-> Atom Atom))
(= (tx:peek $x) (if (== $x 5) (quote five) (quote other)))
!(add-translator-rule! tx:peek)
(= (tx:peeks $a) (tx:peek $a))
!(test (tx:peeks 5) five)
!(test (tx:peeks 6) other)
; A rule computed by a function at translation time:
(= (tx:fib $n) (if (< $n 2) $n (+ (tx:fib (- $n 1)) (tx:fib (- $n 2)))))
(= (tx:compiled-fib $n) (tx:fib $n))
!(add-translator-rule! tx:compiled-fib)
(= (tx:uses-fib $b) (* (tx:compiled-fib 10) $b))
!(test (tx:uses-fib 2) 110)
; A rule selected by its argument's value, one of whose rows has no answer:
(= (tx:lane one) ok)
(= (tx:lane two) (empty))
!(add-translator-rule! tx:lane)
(= (tx:lanes) (collapse (superpose ((tx:lane one) (tx:lane two)))))
!(test (tx:lanes) (ok))
; A rule over a variable's spine reads a value decided when the call runs:
(= (tx:spine $bindings) (tx:let* $bindings done))
!(test (tx:spine ()) done)

; A rule redefined later takes effect at the next call.
(= (tx:shape $x) (quote (Old $x)))
!(add-translator-rule! tx:shape)
(= (tx:shaped $y) (tx:shape $y))
!(test (tx:shaped 1) (Old 1))
!(remove-atom &self (= (tx:shape $x) (quote (Old $x))))
(= (tx:shape $x) (quote (New $x)))
!(test (tx:shaped 2) (New 2))
; Removing the rule makes the call an ordinary call again; adding it back
; makes it a rule again.
!(remove-translator-rule! tx:shape)
!(test (tx:shaped 3) (quote (New 3)))
!(add-translator-rule! tx:shape)
!(test (tx:shaped 4) (New 4))
; A function installed before its callee became a rule follows the rule.
(= (tx:late $x) (tx:wrap $x))
(= (tx:wrap $x) (quote (Wrapped $x)))
!(test (tx:late 5) (quote (Wrapped 5)))
!(add-translator-rule! tx:wrap)
!(test (tx:late 6) (Wrapped 6))
