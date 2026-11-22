; Prolog-dependent cyclic-term entries (11b, 12, 13) of swi_differences.metta.
; These construct rational trees via translatePredicate and require libswipl
; (ENABLE_LIB_PROLOG=1).

; 11b. A binding that would make a term cyclic has no answer: unification
;      checks, as it binds a variable, that the variable does not occur in
;      its value.  SWI-PeTTa runs with occurs_check=false and builds the
;      rational tree, so this query answers ok there.  CeTTa reads a cyclic
;      term that arrives from Prolog as the term it is, but its own bindings
;      keep terms finite.
;      Recorded: Oruži, 2026-09-29.  The contract is Zar's to set.
; SWI-PeTTa: ok
!(let* (($_ (translatePredicate (= $c (f $x $c)))) ($x (g $c))) ok)

; 12. A `let` pattern headed by a variable meets its value as a pattern.
;     SWI-PeTTa's translator runs such a pattern as a run-time dispatch,
;     whose data answer may not be cyclic, and runs it before the let's
;     value when that value is computed but after it when the value is a
;     variable: the query below has no answer there, while the same pattern
;     over (index-atom $c 2), the same term, has one.  CeTTa answers both.
;     Recorded: Oruži, 2026-09-29.  The contract is Zar's to set.
; SWI-PeTTa: no answer.
!(let $_ (translatePredicate (= $c (a b $c))) (let ($x $y $z) $c (== $z $c)))

; 13. Writing a term that is not a finite tree raises
;     representation_error(cyclic_term).  SWI-PeTTa's writer never ends on
;     such a term and runs out of stack, so what its catch gives is a
;     resource_error whose context describes the host's stack.  Uncaught,
;     both stop the run with status 2 (tests/petta/rational_terms_text).
;     Recorded: Oruži, 2026-09-29.  The contract is Zar's to set.
; SWI-PeTTa: (Error (resource_error stack) (dict stack_overflow ...))
!(let $_ (translatePredicate (= $c (f $c))) (catch (repr $c)))
