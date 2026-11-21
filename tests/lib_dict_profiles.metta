; A dictionary works in every dialect and profile: replace, keep-first,
; reject, removal, keyed reads, and one answer each from keys, entries and
; size, whether or not the hash engine is available.
!(import! &self (library dict))
!(let* (($d (dict:new))
        ($_ (dict:put! $d "a" 1))
        ($_ (dict:put! $d "b" 2))
        ($_ (dict:put! $d "a" 3))
        ($_ (dict:put-keep-first! $d "b" 20))
        ($_ (dict:remove! $d "c")))
   (println! (dict-profiles (dict:get $d "a") (dict:get-or $d "b" none) (dict:get-or $d "c" none)
                            (dict:has-key? $d "b") (dict:has-key? $d "c") (dict:size $d)
                            (size-atom (dict:keys $d)) (size-atom (dict:entries $d)))))
!(let* (($d (dict:new)) ($_ (dict:put! $d "k" first)) ($_ (dict:remove! $d "k")))
   (println! (dict-removed (dict:get-or $d "k" gone) (dict:size $d) (dict:keys $d) (dict:entries $d))))
!(let* (($d (dict:new)) ($_ (dict:put! $d "k" 1)) ($r (dict:put-reject! $d "k" 2)))
   (println! (dict-reject (get-metatype $r) (dict:get $d "k"))))
