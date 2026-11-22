; PeTTa's sort of one list is SWI's sort/2: the standard order of terms with
; duplicates (==) removed.  Numbers before symbols before strings before
; expressions; a float before an integer of equal value; -0.0 before 0.0.
!(sort (3 1 2 1))
!(sort ())
!(sort (b a b "s" 1 1.0 -0.0 0.0 (f x) (f x) (f y) (g) 2))
!(sort ((p 2) (p 1) (p 2) (p 1 0)))

; inside functions, where the compiled tiers run it
(= (sup $x) (superpose (3 1 2 3 1)))
(= (sorted-answers $x) (sort (collapse (sup $x))))
(= (sorted-let $x) (let $c (collapse (sup $x)) (sort $c)))
(= (sorted-value $xs) (sort $xs))
(= (memo-sorted $k)
   (let $l (sort (collapse (sup $k)))
     (let $_ (add-atom &self (sorted-memo $k $l)) $l)))
!(sorted-answers 0)
!(sorted-let 0)
!(sorted-value (c a b a))
!(memo-sorted 1)
!(match &self (sorted-memo 1 $l) $l)

; a list with variables keeps one copy of each variable
!(size-atom (sort ($x $y $x)))
(= (vars-sorted $a $b) (size-atom (sort ($a $b $a $b))))
!(vars-sorted $u $v)

; a non-list raises SWI's sort/2 list type error
!(catch (sort 42))

; sort with a key and an order is SWI's sort/4: key 0 compares whole elements,
; key 1 compares the head, key 2 compares the tail of cons-list compounds.
; Strict orders (@<, <, @>, >) deduplicate equal keys keeping the first;
; non-strict orders (@=<, =<, @>=, >=) keep duplicates stably.
!(sort 0 @>= (3 1 2 1))
!(sort 1 @< ((b 2) (a 1) (c 0)))
!(sort 0 @< (b a b 2 1 1.0))
!(sort 0 < (b a b 2 1 1.0))
!(sort 0 @> (b a b 2 1 1.0))
!(sort 0 > (b a b 2 1 1.0))
!(sort 0 @=< (b a b 2 1 1.0))
!(sort 0 =< (b a b 2 1 1.0))
!(sort 0 >= (b a b 2 1 1.0))
!(sort 1 @< ((b 2) (a 3) (a 1) (c 0)))
!(sort 1 @> ((b 2) (a 3) (a 1) (c 0)))
!(sort 1 @=< ((b 2) (a 3) (a 1) (c 0)))
!(sort 1 @>= ((b 2) (a 3) (a 1) (c 0)))
!(sort 2 @< ((a 2 9) (b 2 1) (c 1 5) (d 2 1)))
!(sort 2 @=< ((a 2 9) (b 2 1) (c 1 5) (d 2 1)))
!(sort 2 @> ((a 2 9) (b 2 1) (c 1 5) (d 2 1)))
!(sort 2 @>= ((a 2 9) (b 2 1) (c 1 5) (d 2 1)))
!(sort 2 @< ((b) (a)))
!(sort 5 @< ())

; sort/3 inside functions, transactions, partial applications, and dynamic heads
(= (sort-by $k $o $xs) (sort $k $o $xs))
!(sort-by 1 @>= ((b 2) (a 3) (a 1)))
!(collapse (transaction (sort 1 @< ((b 2) (a 1)))))
!(sort 1 @<)
!((sort 1 @<) ((b 2) (a 1)))
!(let $f sort ($f 1 @< ((b 2) (a 1))))

; sort/3 error terms match SWI-PeTTa
!(catch (sort $k @< (1)))
!(catch (sort -1 @< (1)))
!(catch (sort 1.5 @< (1)))
!(catch (sort 0 $o (1)))
!(catch (sort 0 123 (1)))
!(catch (sort 0 <= (2 1)))
!(catch (sort 0 foo ()))
!(catch (sort 0 @< $xs))
!(catch (sort 0 @< 42))
!(catch (sort 0 @< (cons a $t)))
!(catch (sort 0 @< (cons a b)))
!(catch (sort 1 @< ($x)))
!(catch (sort 1 @< (1)))
!(catch (sort 2 @< (())))
!(catch (sort 3 @< ((a b c))))
!(catch (sort foo @< ((a 1))))

