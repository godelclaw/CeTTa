; A lookup by head joined with a pattern of a variable head, while removed
; rows are still marked, over a space that keeps as many facts in relations
; as it has marked rows: under CETTA_SPACE_DENSE=eager it keeps (R z z) and
; (P z z) in relations from their first fact, and the facts of one column
; stay rows.  Every row of (R $x) meets, (R 2) past a removed row included,
; with relations and without.
!(bind! &k (new-space))
!(add-atom &k (R z z))
!(add-atom &k (P z z))
!(add-atom &k (R 1))
!(add-atom &k (P 1))
!(add-atom &k (R 2))
!(add-atom &k (P 2))
!(add-atom &k (R 3))
!(add-atom &k (P 3))
!(add-atom &k (R 4))
!(add-atom &k (P 4))
!(add-atom &k (R 5))
!(add-atom &k (P 5))
!(add-atom &k (R 6))
!(add-atom &k (P 6))
!(add-atom &k (R 7))
!(add-atom &k (P 7))
!(add-atom &k (R 8))
!(add-atom &k (P 8))
!(add-atom &k (R 9))
!(add-atom &k (P 9))
!(remove-atom &k (P 1))
!(remove-atom &k (P 2))
!(collapse (match &k (, (R $x) ($h $x)) ($h $x)))
