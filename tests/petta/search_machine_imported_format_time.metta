!(import_prolog_function get_time)
!(import_prolog_function string_length)
(= (clock-text)
   (let $time (get_time)
     (progn
       (translatePredicate
         (format_time
           (Predicate (string $text))
           "%Y-%m-%d %H:%M:%S"
           $time))
       $text)))
(= (epoch-year)
   (progn
     (translatePredicate
       (format_time (Predicate (string $year)) "%Y" 0))
     $year))
!(epoch-year)
!(string_length (clock-text))
