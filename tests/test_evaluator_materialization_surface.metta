; Regression surface for the evaluator-materialization workaround idioms
; that the codex port depends on (catalogued 2026-06-10 while porting
; turn_diff_tracker; see specs/codex_known_red_surfaces.md history and
; tests/repro_evaluator_materialization.metta for the broken forms).
;
; If any assertion here goes red, the workaround idioms used across
; codex/*.metta are no longer safe and the port needs an audit.

!(import! &self list)
!(import! &self str)

; recursive list builder in the single-equation if-empty style, with the
; recursive result materialized through case-collapse before cons-atom
(= (test:double-all $xs)
   (if (== $xs ())
       ()
       (let ($head $tail) (decons-atom $xs)
         (let $doubled (* $head 2)
           (case (collapse (test:double-all $tail))
             ((($rest)
               (cons-atom $doubled $rest))))))))

!(assertEqualToResult
  (test:double-all (1 2 3))
  ((2 4 6)))

; case-collapse materialization of a deep-recursion result used as an
; argument to another user function
(= (test:sum $xs)
   (if (== $xs ())
       0
       (let ($head $tail) (decons-atom $xs)
         (+ $head (test:sum $tail)))))

!(assertEqualToResult
  (case (collapse (test:double-all (1 2 3)))
    ((($doubled)
      (test:sum $doubled))))
  (12))

; equation dispatch on a boolean (the safe replacement for `if` under
; deep case-collapse nesting)
(= (test:pick True $a $b) $a)
(= (test:pick False $a $b) $b)

!(assertEqualToResult
  (case (collapse (str-trim "  x  "))
    ((($trimmed)
      (case (collapse (== $trimmed "x"))
        ((($flag)
          (test:pick $flag "matched" "other")))))))
  ("matched"))

; accumulator threading through tail calls (the safe replacement for
; post-concatenating a deeply nested rendered string)
(= (test:render-items $items $acc)
   (if (== $items ())
       $acc
       (let ($head $tail) (decons-atom $items)
         (test:render-items
           $tail
           (str-concat $acc (str-concat $head ";"))))))

!(assertEqualToResult
  (test:render-items ("a" "b" "c") "")
  ("a;b;c;"))

; zero-arg helper values survive when materialized through case-collapse
; before use as a native-call argument
(= (test:alphabet)
   "abcdefghijklmnopqrstuvwxyz")

!(assertEqualToResult
  (case (collapse (test:alphabet))
    ((($table)
      (case (collapse (str-find $table "d"))
        ((()
          -1)
         (($rank)
          $rank))))))
  (3))
