; Edge cases for the native PeTTa atom_concat/2, atom_chars/1, copy_term/1,
; term_hash/1 and term_hash/3 builtins (SWI atom_concat/3, atom_chars/2,
; copy_term/2, term_hash/2 and term_hash/4). Expected lines are SWI-Prolog
; 10.1.9 results translated to the PeTTa spelling, never CeTTa output.
; Rows that depend on dicts, attributed variables, cyclic terms or the '[]'
; atom are left out. Hash values are compared by property, not by number.
; Rows where candidate 7 differs from SWI live in native_stdlib_edges_gaps.metta.
!(atom_concat abc def)
!(atom_concat 1 2)
!(atom_concat 1.5 x)
!(atom_concat "s" t)
!(atom_concat "" "")
!(catch (atom_concat $a def))
!(catch (atom_concat abc $b))
!(catch (atom_concat (f x) a))
!(atom_chars abc)
!(atom_chars 123)
!(atom_chars 1.5)
!(atom_chars "")
!(atom_chars "str")
!(catch (atom_chars $x))
!(catch (atom_chars (f x)))
!(copy_term a)
!(let (f $a $b $c) (copy_term (f $x $y $x)) (== $a $c))
!(let (f $a $b $c) (copy_term (f $x $y $x)) (== $a $b))
!(== (term_hash foo) (term_hash foo))
!(== (term_hash 1) (term_hash 1.0))
!(== (term_hash "a") (term_hash a))
!(== (term_hash (foo a b) 1 1000) (term_hash (foo a c) 1 1000))
!(== (term_hash foo 1 10) (term_hash foo 2 10))
!(== (term_hash a 0 10) (term_hash b 0 10))
!(< (term_hash (foo a b) -1 1000) 1000)
!(term_hash foo 1 1)
!(term_hash (f $x))
!(term_hash $x)
!(get-type (term_hash (f $x) 1 10))
!(catch (term_hash foo $d 10))
!(catch (term_hash foo 1 $r))
!(catch (term_hash foo -2 10))
!(catch (term_hash foo a 10))
(= (h-in-fn $k) (== (term_hash (foo a b) 1 1000) (term_hash (foo $k c) 1 1000)))
!(h-in-fn q)
(= (cat-in-fn $a $b) (atom_concat $a $b))
!(cat-in-fn ab cd)
(= (chars-in-fn $a) (atom_chars $a))
!(chars-in-fn xyz)
; term_hash depth is counted over MeTTa expression nesting, not Prolog cons cells (tests/petta/swi_differences.metta entry 20). Expected lines come from swipl 10.1.9 run on compound terms foo(a,b) and foo(a,c) (evidence godel-compound-hash-run-EL18st/swi-compound.txt).
!(== (term_hash (foo a b) 1 1000) (term_hash (foo a c) 1 1000))
!(== (term_hash (foo a b) 2 1000) (term_hash (foo a c) 2 1000))
!(== (term_hash (foo a b) 3 1000) (term_hash (foo a c) 3 1000))
!(== (term_hash (foo a b) 4 1000) (term_hash (foo a c) 4 1000))
!(== (term_hash (foo a b) 3 2147483647) (term_hash (foo a c) 3 2147483647))
!(== (term_hash (foo a b) 4 2147483647) (term_hash (foo a c) 4 2147483647))
!(== (term_hash (foo a b) -1 2147483647) (term_hash (foo a c) -1 2147483647))
!(== (term_hash (foo a b) 2 2147483647) (term_hash (foo x b) 2 2147483647))

; Range must fit a C int, as in SWI. A Range below one is reported with the
; Range itself; SWI 10.1.9 reports the Depth there (swi_differences entry 20).
!(catch (term_hash foo 1 2147483648))
