!(collapse
  (group-fold
    (external-merge 2)
    (fs:stream-atom-lines "tests/support/group_fold_atom_lines_malformed.metta")
    0
    $acc
    $item
    (let ($key $value) $item $key)
    (let ($key $value) $item (eval (+ $acc $value)))))
