; A value that has the shape of a call is data in and out of a Python call:
; a parsed command is handed to Python as the list it spells, and a list
; Python returns whose head names a function comes back as that list.
(= (effect) (progn (println! effect-ran) done))
!(let $x (sread "(effect)") (py-call (builtins.repr $x)))
!(let $x (sread "(effect)") (py-call (builtins.repr (wrap $x))))
(= (hand $v) (py-call (builtins.repr $v)))
!(let $x (sread "(effect)") (hand $x))
!(py-call (.split "effect"))
!(let $r (py-call (.split "effect")) (quote $r))
; A call written in the Python call is evaluated first.
!(py-call (builtins.repr (effect)))
