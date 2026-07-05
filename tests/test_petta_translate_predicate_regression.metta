;; PeTTa translatePredicate helper compatibility for HE/CeTTa.
;; Starts from the upstream PeTTa adapter regression on zariuq/lang/petta-v1
;; and extends it with relation-output arithmetic plus old utility helpers
;; witnessed by native PeTTa.

(= (progn $first $second)
   (let $_ $first $second))
(= (progn $first $second $third)
   (let $_ $first (progn $second $third)))
(= (progn $first $second $third $fourth)
   (let $_ $first (progn $second $third $fourth)))

!(assertEqualToResult
  (progn (translatePredicate (is $x 2))
         (translatePredicate (+ $x 40 $z))
         $z)
  (42))

!(assertEqualToResult
  (progn (translatePredicate (= $who sam))
         $who)
  (sam))

!(assertEqualToResult
  (progn (translatePredicate (< 2 3 $ok))
         $ok)
  (True))

!(assertEqualToResult
  (progn (translatePredicate (= sam sam $same))
         $same)
  (True))

!(assertEqualToResult
  (progn (translatePredicate (= sam bob $same))
         $same)
  (False))

!(assertEqualToResult
  (progn (translatePredicate (#< 1 2 $ok))
         $ok)
  (True))

!(assertEqualToResult
  (progn (translatePredicate (#> 2 1 $ok))
         $ok)
  (True))

!(assertEqualToResult
  (progn (translatePredicate (#= 1 1 $ok))
         $ok)
  (True))

!(assertEqualToResult
  (progn (translatePredicate (#= 1 2 $ok))
         $ok)
  (False))

!(assertEqualToResult
  (progn (translatePredicate (#+ 7 35 $sum))
         $sum)
  (42))

!(assertEqualToResult
  (progn (translatePredicate (#+ (+ 1 2) 39 $sum))
         $sum)
  (42))

!(assertEqualToResult
  (progn (translatePredicate (#- 7 2 $out))
         $out)
  (5))

!(assertEqualToResult
  (progn (translatePredicate (#* 6 7 $out))
         $out)
  (42))

!(assertEqualToResult
  (progn (translatePredicate (#mod 17 5 $out))
         $out)
  (2))

!(assertEqualToResult
  (progn (translatePredicate (#div 7 2 $out))
         $out)
  (3))

!(assertEqualToResult
  (progn (translatePredicate (#// 7 2 $out))
         $out)
  (3))

!(assertEqualToResult
  (progn (translatePredicate (#\= 7 2 $ok))
         $ok)
  (True))

!(assertEqualToResult
  (progn (translatePredicate (#\= 7 7 $ok))
         $ok)
  (False))

!(assertEqualToResult
  (progn (translatePredicate (#min 7 2 $out))
         $out)
  (2))

!(assertEqualToResult
  (progn (translatePredicate (#max 7 2 $out))
         $out)
  (7))

!(assertEqualToResult
  (progn (translatePredicate (string_concat foo bar $out))
         $out)
  ("foobar"))

!(assertEqualToResult
  (progn (translatePredicate (string_concat "foo" "bar" $out))
         $out)
  ("foobar"))

!(assertEqualToResult
  (progn (translatePredicate (atomics_to_string (":- table " name "/" 2 ".") $out))
         $out)
  (":- table name/2."))

!(assertEqualToResult
  (progn (translatePredicate (atomics_to_string (True False) $out))
         $out)
  ("truefalse"))

!(assertEqualToResult
  (progn (translatePredicate (string_length "abcd" $n))
         $n)
  (4))

!(assertEqualToResult
  (progn (translatePredicate (number_string $n "42"))
         $n)
  (42))

!(assertEqualToResult
  (progn (translatePredicate (number_string 42 $s))
         $s)
  ("42"))

!(assertEqualToResult
  (progn (translatePredicate (atom_number "42" $n))
         $n)
  (42))

!(assertEqualToResult
  (progn (translatePredicate (atom_number answer $n))
         $n)
  ())

!(assertEqualToResult
  (progn (translatePredicate (exists_file "tests/support/fs_fixture.txt"))
         True)
  (True))

!(assertEqualToResult
  (progn (translatePredicate (exists_file "tests/support/no_such_translate_predicate_file.txt"))
         True)
  ())

!(assertEqualToResult
  (progn (translatePredicate (read_file_to_string "tests/support/fs_fixture.txt" $content ()))
         $content)
  ("first line\nsecond line\n\nthird line\n"))

!(assertEqualToResult
  (progn (translatePredicate (sleep 0))
         True)
  (True))

!(assertEqualToResult
  (progn (translatePredicate (format_time (Predicate (string $s)) "%Y" 0))
         $s)
  ("1970"))

!(assertEqualToResult
  (progn (translatePredicate (format_time (Predicate (string $s)) "%Y-%m-%d %H:%M:%S" (get_time)))
         (translatePredicate (string_length $s $n))
         $n)
  (19))

!(assertEqualToResult
  (progn (translatePredicate (atom_string answer $s))
         $s)
  ("answer"))

!(assertEqualToResult
  (progn (translatePredicate (atom_string 42 $s))
         $s)
  ("42"))

!(assertEqualToResult
  (progn (translatePredicate (atom_string True $s))
         $s)
  ("true"))

!(assertEqualToResult
  (progn (translatePredicate (atom_string $a "answer"))
         $a)
  (answer))

!(assertEqualToResult
  (progn (translatePredicate (atom_codes $NL (10)))
         (translatePredicate (atom_string $NL $S))
         $S)
  ("\n"))

!(assertEqualToResult
  (progn (translatePredicate (atom_codes $NL (10)))
         (translatePredicate (atom_string $NL $S))
         (translatePredicate (string_length $S $N))
         $N)
  (1))

!(assertEqualToResult
  (progn (translatePredicate (atom_codes hi $Codes))
         $Codes)
  ((104 105)))

!(assertEqualToResult
  (progn (translatePredicate (atom_codes $A (104 105)))
         (translatePredicate (atom_string $A $S))
         $S)
  ("hi"))

!(assertEqualToResult
  (progn (translatePredicate (sub_string "abcdef" 2 3 1 $sub))
         $sub)
  ("cde"))

!(assertEqualToResult
  (progn (translatePredicate (sub_string "abcdef" 0 3 $after $sub))
         (Pair $after $sub))
  ((Pair 3 "abc")))

!(assertEqualToResult
  (progn (translatePredicate (sub_string "a=b" 0 1 2 $key))
         $key)
  ("a"))

!(assertEqualToResult
  (progn (translatePredicate (sub_string "a=b" 2 1 0 $value))
         $value)
  ("b"))

!(assertEqualToResult
  (progn (translatePredicate (sub_string "abcdef" $before 3 1 "cde"))
         $before)
  (2))
