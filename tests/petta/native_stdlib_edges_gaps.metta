; Rows where candidate 7 (311fa0fd) differs from SWI-Prolog 10.1.9. The
; expected lines are SWI's results (evidence: swi.txt in the review run);
; this file is expected to FAIL until the builtin changes. Do not edit the
; expected lines to match CeTTa.
; term_hash/4 with Depth >= 2 (or -1) must see the arguments, so two terms
; that differ below depth 1 hash differently.
!(== (term_hash (foo a b) 2 1000) (term_hash (foo a c) 2 1000))
!(== (term_hash (foo a b) 2 2147483647) (term_hash (foo a c) 2 2147483647))
!(== (term_hash (foo a b) -1 2147483647) (term_hash (foo a c) -1 2147483647))
!(== (term_hash (foo a b) 3 2147483647) (term_hash (foo a c) 3 2147483647))
