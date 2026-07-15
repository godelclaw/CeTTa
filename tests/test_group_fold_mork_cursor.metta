; MORK matching already has a strict direct visitor lane. group-fold consumes
; that cursor incrementally instead of adding a second materializing query API.
!(import! &self mork)
!(bind! &group-source (mork:new-space))
!(mork:add-atoms &group-source
  (collapse
    (superpose ((packet a 1) (packet b 2) (packet a 3) (packet c 4)))))
!(collapse
  (group-fold
    (external-merge 2)
    (mork:match &group-source (packet $key $value) ($key $value))
    0
    $acc
    $item
    (let ($key $value) $item $key)
    (let ($key $value) $item (eval (+ $acc $value)))))
