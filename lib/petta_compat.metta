;; Small PeTTa/Omega helper-name compatibility shims over existing CeTTa
;; primitives.  This is intentionally not a Prolog runtime: relation-style
;; helpers that need binding export remain in translatePredicate.

!(import! &self str)
!(import! &self time)

(= (atomic_list_concat $parts $separator)
   (str:join $separator $parts))

(= (split_string $text $separator "")
   (str:split $separator $text))

(= (string_concat $lhs $rhs)
   (str:concat $lhs $rhs))

(= (string_length $text)
   (str:length $text))

(= (string-replace $text $from $to)
   (str:join $to (str:split $from $text)))

(= (string-safe $text)
   (string-replace
     (string-replace
       (string-replace $text "\"" "_quote_")
       "\n" "_newline_")
     "'" "_apostrophe_"))

(= (last_chars $text $n)
   (let $len (str:length $text)
        (str:slice $text (if (> $n $len) 0 (- $len $n)) $len)))

(= (get_time_as_string)
   (time:time-string "%Y-%m-%d %H:%M:%S"))

(= (newline) "\n")
