; Native set predicates complement unique/intersection/subtraction without
; allocating intermediate expressions for common membership and inclusion
; queries.  Duplicate multiplicity and order are intentionally ignored.

!(assertEqual (member-atom? a (a b c)) True)
!(assertEqual (member-atom? z (a b c)) False)
!(assertEqual (member-atom? (f a) ((f b) (f a))) True)

!(assertEqual (subset-atom? () (a b)) True)
!(assertEqual (subset-atom? (a a) (b a)) True)
!(assertEqual (subset-atom? (a c) (a b)) False)

!(assertEqual (same-set-atom? (b a a) (a b)) True)
!(assertEqual (same-set-atom? (a b) (a c)) False)

!(assertEqualToResult
   (member-atom? a)
   ((Error (member-atom? a) IncorrectNumberOfArguments)))
