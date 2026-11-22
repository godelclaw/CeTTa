; PeTTa's atom_concat/2 (SWI atom_concat/3) and atom_chars/1 (SWI atom_chars/2).
; Atomic operands render to UTF-8 text; atom_concat produces an interned symbol
; (including the empty symbol) and atom_chars splits into single-codepoint symbols.
!(atom_concat foo bar)
!(get-metatype (atom_concat foo bar))
!(atom_concat "ab" "cd")
!(get-metatype (atom_concat "ab" "cd"))
!(atom_concat item_ 42)
!(atom_concat true _flag)
!(atom_concat false _flag)
!(atom_concat n_ 100000000000000000000)
!(atom_concat x_ 3.5)
!(atom_concat &self _tag)
!(atom_concat "a—" "ř⋄")
!(atom_concat "" "")
!(let $e (atom_concat "" "") (atom_concat $e ok))
!(let $e (atom_concat "" "") (atom_concat ok $e))

!(atom_chars abc)
!(atom_chars "")
!(atom_chars (atom_concat "" ""))
!(atom_chars "xy")
!(atom_chars 123)
!(get-metatype (car-atom (atom_chars 123)))
!(== (car-atom (atom_chars 123)) 1)
!(atom_chars -42)
!(atom_chars 1.5)
!(atom_chars True)
!(atom_chars False)
!(atom_chars "a—ř⋄")
!(size-atom (atom_chars "a—ř⋄"))

; inside functions (compiled tiers and reference routes)
(= (join-pair $a $b) (atom_concat $a $b))
(= (split-text $x) (atom_chars $x))
!(join-pair hello _world)
!(split-text "a—b")
!(collapse (transaction (atom_concat txn_ ok)))
!(collapse (transaction (atom_chars hi)))

; computed state name via atom_concat at root and inside let
!(change-state! (atom_concat nat_ key) 99)
!(get-state (atom_concat nat_ key))
!(let $k (atom_concat nat_ key) (get-state $k))

; partial application and dynamic head dispatch
!((atom_concat pre_) suf)
!(let $f atom_concat ($f dyn_ ok))
!(let $f atom_chars ($f xy))

; error terms match SWI-PeTTa
!(catch (atom_concat $u bar))
!(catch (atom_concat foo $u))
!(catch (atom_concat () bar))
!(catch (atom_concat (a b) bar))
!(catch (atom_concat foo (a b)))
!(catch (atom_chars $u))
!(catch (atom_chars ()))
!(catch (atom_chars (a b)))
