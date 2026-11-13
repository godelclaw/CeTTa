; A match whose pattern is a variable enumerates every row of the space.
; A space named by a symbol and never written holds no native rows, and in
; a build without Prolog no foreign ones either: the match has no answer,
; as SWI-PeTTa's get-atoms finds none.
!(collapse (match &never-written $a $a))
!(collapse (match &never-written $a (found $a)))
!(collapse (match &never-written ($a) $a))
!(bind! &empty (new-space))
!(collapse (match &empty $a $a))
!(collapse (match &empty $a 1))
!(let $s (new-space) (collapse (match $s $a $a)))
!(add-atom &empty (item 1))
!(add-atom &empty two)
!(collapse (match &empty $a $a))
!(remove-atom &empty (item 1))
!(remove-atom &empty two)
!(collapse (match &empty $a $a))
!(collapse (match &self $a (never $a)))
