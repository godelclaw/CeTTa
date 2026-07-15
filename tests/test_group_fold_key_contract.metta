; A key expression must produce exactly one canonical ground key.
!(group-fold
  ordered
  (superpose ((a 1)))
  0
  $acc
  $item
  (superpose (a b))
  (eval (+ $acc 1)))
