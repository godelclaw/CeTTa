;; tabled-lattice: a tabled relation whose results for each instance of its
;; call are joined (min, max, or a function of two arguments) inside the
;; fixpoint, so shortest paths and reachable sets on cyclic graphs terminate.
;; Against SWI's mode-directed tabling (min, max, lattice(J/3)), on fixed and
;; seeded random graphs, the same arcs asserted to both.
!(import! &self (library lib_tabling))

(= (arc a) (b 1))
(= (arc a) (c 4))
(= (arc b) (c 1))
(= (arc c) (a 1))
(= (arc c) (d 2))
!(tabled-lattice (dist $x $y) min)
(= (dist $x $y) (let ($y $w) (arc $x) $w))
(= (dist $x $y) (let ($z $w) (arc $x) (let $d (dist $z $y) (+ $w $d))))
;; the cycle a -> b -> c -> a: each target once, at its least cost
!(msort (collapse (let $c (dist a $y) ($y $c))))
!(collapse (dist a d))
!(msort (collapse (let $c (dist $x d) ($x $c))))

;; max: longest paths on a DAG
(= (darc s) (t 1))
(= (darc s) (u 5))
(= (darc t) (u 1))
(= (darc u) (v 1))
!(tabled-lattice (far $x $y) max)
(= (far $x $y) (let ($y $w) (darc $x) $w))
(= (far $x $y) (let ($z $w) (darc $x) (let $d (far $z $y) (+ $w $d))))
!(msort (collapse (let $c (far s $y) ($y $c))))
;; the same relation tabled plainly keeps every path's cost
!(tabled (every $x $y))
(= (every $x $y) (let ($y $w) (darc $x) $w))
(= (every $x $y) (let ($z $w) (darc $x) (let $d (every $z $y) (+ $w $d))))
!(msort (collapse (let $c (every s $y) ($y $c))))
;; a join of two arguments: the nodes a node reaches, joined by set union,
;; on a cyclic graph
(= (sunion $a $b) (msort (unique-atom (union-atom $a $b))))
!(tabled-lattice (reach $x) sunion)
(= (reach $x) (let ($y $w) (arc $x) ($y)))
(= (reach $x) (let ($y $w) (arc $x) (reach $y)))
!(msort (collapse (let $s (reach $x) ($x $s))))

;; Seeded random-graph differential checks against SWI mode-directed tabling
;; live in tabled_lattice_prolog.metta (gated on ENABLE_LIB_PROLOG=1).
