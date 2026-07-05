;; PeTTa oracle fixture for translatePredicate binding export through progn.
;; The first witnesses mirror the language-adapter lane; later witnesses cover
;; relation-output arithmetic and old utility helpers from native PeTTa.

!(import_prolog_function get_time)

(= (progn $first $second $third $fourth)
   (let $_ $first (progn $second $third $fourth)))

!(test (progn (translatePredicate (is $x 2))
              (translatePredicate (+ $x 40 $z))
              $z)
       42)

!(test (progn (translatePredicate (= $who sam))
              $who)
       sam)

!(test (progn (translatePredicate (< 2 3 $ok))
              $ok)
       True)

!(test (progn (translatePredicate (= sam sam $same))
              $same)
       True)

!(test (progn (translatePredicate (= sam bob $same))
              $same)
       False)

!(test (progn (translatePredicate (#< 1 2 $ok))
              $ok)
       True)

!(test (progn (translatePredicate (#> 2 1 $ok))
              $ok)
       True)

!(test (progn (translatePredicate (#= 1 1 $ok))
              $ok)
       True)

!(test (progn (translatePredicate (#= 1 2 $ok))
              $ok)
       False)

!(test (progn (translatePredicate (#+ 7 35 $sum))
              $sum)
       42)

!(test (progn (translatePredicate (#+ (+ 1 2) 39 $sum))
              $sum)
       42)

!(test (progn (translatePredicate (#- 7 2 $out))
              $out)
       5)

!(test (progn (translatePredicate (#* 6 7 $out))
              $out)
       42)

!(test (progn (translatePredicate (#mod 17 5 $out))
              $out)
       2)

!(test (progn (translatePredicate (#div 7 2 $out))
              $out)
       3)

!(test (progn (translatePredicate (#// 7 2 $out))
              $out)
       3)

!(test (progn (translatePredicate (#\= 7 2 $ok))
              $ok)
       True)

!(test (progn (translatePredicate (#\= 7 7 $ok))
              $ok)
       False)

!(test (progn (translatePredicate (#min 7 2 $out))
              $out)
       2)

!(test (progn (translatePredicate (#max 7 2 $out))
              $out)
       7)

!(test (progn (translatePredicate (string_concat foo bar $out))
              $out)
       "foobar")

!(test (progn (translatePredicate (string_concat "foo" "bar" $out))
              $out)
       "foobar")

!(test (progn (translatePredicate (atomics_to_string (":- table " name "/" 2 ".") $out))
              $out)
       ":- table name/2.")

!(test (progn (translatePredicate (atomics_to_string (True False) $out))
              $out)
       "truefalse")

!(test (progn (translatePredicate (string_length "abcd" $n))
              $n)
       4)

!(test (progn (translatePredicate (number_string $n "42"))
              $n)
       42)

!(test (progn (translatePredicate (number_string 42 $s))
              $s)
       "42")

!(test (progn (translatePredicate (atom_number "42" $n))
              $n)
       42)

!(test (progn (translatePredicate (atom_number answer $n))
              $n)
       ())

!(test (progn (translatePredicate (exists_file "tests/support/fs_fixture.txt"))
              True)
       True)

!(test (progn (translatePredicate (read_file_to_string "tests/support/fs_fixture.txt" $content ()))
              $content)
       "first line\nsecond line\n\nthird line\n")

!(test (collapse (translatePredicate (exists_file "tests/support/no_such_translate_predicate_file.txt")))
       ())

!(test (progn (translatePredicate (sleep 0))
              True)
       True)

!(test (progn (translatePredicate (format_time (Predicate (string $s)) "%Y" 0))
              $s)
       "1970")

!(test (progn (translatePredicate (format_time (Predicate (string $s)) "%Y-%m-%d %H:%M:%S" (get_time)))
              (translatePredicate (string_length $s $n))
              $n)
       19)

!(test (progn (translatePredicate (atom_string answer $s))
              $s)
       "answer")

!(test (progn (translatePredicate (atom_string 42 $s))
              $s)
       "42")

!(test (progn (translatePredicate (atom_string True $s))
              $s)
       "true")

!(test (progn (translatePredicate (atom_string $a "answer"))
              $a)
       answer)

!(test (progn (translatePredicate (atom_codes $NL (10)))
              (translatePredicate (atom_string $NL $S))
              $S)
       "\n")

!(test (progn (translatePredicate (atom_codes $NL (10)))
              (translatePredicate (atom_string $NL $S))
              (translatePredicate (string_length $S $N))
              $N)
       1)

!(test (progn (translatePredicate (atom_codes hi $Codes))
              $Codes)
       (104 105))

!(test (progn (translatePredicate (atom_codes $A (104 105)))
              (translatePredicate (atom_string $A $S))
              $S)
       "hi")

!(test (progn (translatePredicate (sub_string "abcdef" 2 3 1 $sub))
              $sub)
       "cde")

!(test (progn (translatePredicate (sub_string "abcdef" 0 3 $after $sub))
              (Pair $after $sub))
       (Pair 3 "abc"))

!(test (progn (translatePredicate (sub_string "a=b" 0 1 2 $key))
              $key)
       "a")

!(test (progn (translatePredicate (sub_string "a=b" 2 1 0 $value))
              $value)
       "b")

!(test (progn (translatePredicate (sub_string "abcdef" $before 3 1 "cde"))
              $before)
       2)
