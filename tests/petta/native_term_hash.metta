; PeTTa's term_hash/1 (SWI term_hash/2) and term_hash/3 (SWI term_hash/4):
; deterministic portable structural hash, independent of libswipl, process
; memory layout, and internal symbol IDs.
!(== (term_hash (a 1)) (term_hash (a 1)))
!(== (term_hash True) (term_hash true))
!(== (term_hash False) (term_hash false))
!(== (term_hash 1) (term_hash 1.0))
!(== (term_hash 0.0) (term_hash -0.0))
!(== (term_hash (a 1)) (term_hash (cons a (cons 1 ()))))
!(let $h (term_hash (a 1)) (and (>= $h 0) (< $h 4294967296)))
!(let $h (term_hash (a (b 1)) 2 1000) (and (>= $h 0) (< $h 1000)))
!(term_hash (a 1) 0 1)
!(term_hash (a 1) -1 1)
!(== (term_hash (a 1) -1 1000) (term_hash (a 1) 10 1000))

; Nonground terms return a fresh unbound variable when a variable is reached
; within the inspected depth; depth 0 stops before inspecting the root.
!(is-var (term_hash $x))
!(is-var (term_hash (a $x)))
!(is-var (term_hash (cons a $t)))
!(is-var (term_hash $x 0 100))
!(is-var (term_hash $x 1 100))
!(is-var (term_hash $x -1 100))
!(is-var (term_hash (a $x) 1 100))
!(is-var (term_hash (a $x) 2 100))
!(is-var (term_hash (a (b $x)) 2 100))
!(is-var (term_hash (a (b $x)) 3 100))
!(is-var (term_hash (a (b $x)) -1 100))
; Freshness: the returned variable is independent of the input variable.
!(let $h (term_hash $x) (let $x 42 (is-var $h)))

; Inside functions, transactions, partial applications, and dynamic heads.
(= (hash-key $t) (term_hash $t))
(= (hash-bucket $t $d $r) (term_hash $t $d $r))
!(== (hash-key (f a 1)) (term_hash (f a 1)))
!(== (hash-bucket (f a 1) -1 997) (term_hash (f a 1) -1 997))
!(== (collapse (transaction (term_hash (f a 1)))) (collapse (term_hash (f a 1))))
!(term_hash)
!(term_hash (a 1) 2)
!(== ((term_hash (a 1) 2) 1000) (term_hash (a 1) 2 1000))
!(let $f term_hash (== ($f (a 1)) (term_hash (a 1))))
!(let $f term_hash (== ($f (a 1) -1 500) (term_hash (a 1) -1 500)))

; Error terms for invalid depth and range arguments.
!(catch (term_hash (a 1) -2 100))
!(catch (term_hash (a 1) foo 100))
!(catch (term_hash (a 1) $d 100))
!(catch (term_hash (a 1) 2 0))
!(catch (term_hash (a 1) 2 -5))
!(catch (term_hash (a 1) 2 foo))
!(catch (term_hash (a 1) 2 $r))
