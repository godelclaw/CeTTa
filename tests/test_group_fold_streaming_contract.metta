(edge a 1)
(edge b 2)

; group-fold is deliberately streaming-only. An ordinary in-memory match must
; not silently materialize before reduction.
!(collapse
  (group-fold
    ordered
    (match &self (edge $key $value) ($key $value))
    0
    $acc
    $item
    (let ($key $value) $item $key)
    (eval (+ $acc 1))))
