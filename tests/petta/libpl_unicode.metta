!(import! &self (library lib_import))
!(import_prolog_functions_from_file
    "tests/petta/fixtures/libpl_unicode.pl"
    (cetta-unicode-echo))
!(import_prolog_function string_length)
!(import_prolog_function sub_string)
!(py-call (str (cetta-unicode-echo "prefix…suffix")))
!(cetta-unicode-echo "Příliš žluťoučký kůň")
!(string_length "prefix…suffix")
!(py-call (str (sub_string "ab…cd" 3 $_ 0)))
