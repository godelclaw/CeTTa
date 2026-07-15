; Ordered mode rejects a key regression transactionally: no completed group is
; emitted alongside the error.
!(group-fold
  ordered
  (superpose ((b 1) (a 2)))
  0
  $acc
  $item
  (let ($key $value) $item $key)
  (eval (+ $acc 1)))
