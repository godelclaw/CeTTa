; Minimal repros of the evaluator behaviors that force the workaround
; idioms asserted in tests/test_evaluator_materialization_surface.metta.
; This file is intentionally named outside the test_*.metta green lanes:
; several probes produce wrong/empty results by design until the
; evaluator is fixed. Catalogued 2026-06-10 during the turn_diff_tracker
; port; the larger in-module manifestations are described in
; codex/turn_diff_tracker.metta's deviation notes.
;
; Run manually:
;   ./cetta --lang he --profile he_extended tests/repro_evaluator_materialization.metta

!(import! &self list)
!(import! &self str)

(= (test:double-all $xs)
   (if (== $xs ())
       ()
       (let ($head $tail) (decons-atom $xs)
         (let $doubled (* $head 2)
           (case (collapse (test:double-all $tail))
             ((($rest)
               (cons-atom $doubled $rest))))))))

; 1. cons-atom quotes call arguments instead of evaluating them.
;    Expected if fixed: ((2 4) tail). Currently: the unreduced call.
!(println! "--- repro 1: cons-atom does not evaluate call arguments")
!(println! (cons-atom (test:double-all (1 2)) (tail)))

; 2. Tracking probe: let-binding a deep-recursion result then handing it
;    to cons-atom prints ((2 4) (9)) in this minimal form, but the same
;    shape lost the value in module context during the turn_diff_tracker
;    port (a directly-printed call worked while the let+cons form went
;    empty). Kept to detect when the behavior shifts.
!(println! "--- repro 2 (tracking): let-bound recursive result into cons-atom")
!(println! (let $rows (test:double-all (1 2)) (cons-atom $rows ((9)))))

; 3. Tracking probe: (once (eval ...)) — in module context this produced
;    Empty inside cons-atom while case-collapse worked. Minimal form
;    currently prints ((2 4) (9)).
!(println! "--- repro 3 (tracking): once/eval materialization")
!(println! (let $rows (once (eval (test:double-all (1 2)))) (cons-atom $rows ((9)))))

; 4. The working idiom for comparison: case-collapse materialization.
;    This one is correct today and asserted in the green surface.
!(println! "--- repro 4 (working): case-collapse materialization")
!(println!
  (case (collapse (test:double-all (1 2)))
    ((($rows)
      (cons-atom $rows ((9)))))))

; 5. Tracking probe: a ()-equation plus a general equation can double-match
;    the empty list, making the general equation error on (decons-atom ()).
;    This minimal form does NOT currently reproduce (it prints clean
;    results); the failure was observed in module context during the
;    turn_diff_tracker port (see that module's deviation notes), so the
;    probe is kept to detect when the behavior shifts either way.
(= (test:bad-len ()) 0)
(= (test:bad-len $xs)
   (let ($head $tail) (decons-atom $xs)
     (+ 1 (test:bad-len $tail))))

!(println! "--- repro 5 (tracking): ()-equation plus general equation")
!(println! (collapse (test:bad-len ())))
!(println! (test:bad-len (7)))

!(println! "--- repro file complete")
