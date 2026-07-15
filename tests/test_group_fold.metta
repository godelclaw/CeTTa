; Ordered mode releases groups in canonical key order and audits canonical
; encounter-ordered item encodings.
!(collapse
  (group-fold
    ordered
    (superpose ((a 1) (a 3) (b 2) (b 5) (c 4)))
    0
    $acc
    $item
    (let ($key $value) $item $key)
    (let ($key $value) $item
      (eval (+ (eval (* $acc 10)) $value)))))

; External mode sorts bounded runs, but is stable within a key. A run size of
; two forces multiple initial runs and a merge in this small regression.
!(collapse
  (group-fold
    (external-merge 2)
    (superpose ((a 1) (b 2) (a 3) (c 4) (b 5)))
    0
    $acc
    $item
    (let ($key $value) $item $key)
    (let ($key $value) $item
      (eval (+ (eval (* $acc 10)) $value)))))

; Empty input has no groups.
!(collapse
  (group-fold ordered (superpose ()) 0 $acc $item $item
    (eval (+ $acc 1))))
