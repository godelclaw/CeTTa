; Native resource values are deliberately excluded from canonical audits.
!(group-fold
  ordered
  (superpose ((new-state 1)))
  0
  $acc
  $item
  resource
  (eval (+ $acc 1)))
