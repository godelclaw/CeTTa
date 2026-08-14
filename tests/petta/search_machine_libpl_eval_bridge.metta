!(import! &self (library lib_import))
!(import_prolog_functions_from_file
    "tests/petta/fixtures/libpl_eval_bridge.pl"
    (eval-once eval-many libpl-double eval-foreign))
!(println! (libpl-eval-result (eval-once (+ 20 22))))
!(println! (libpl-eval-many-result (collapse (eval-many))))
!(println! (libpl-reentrant-result (eval-foreign)))
