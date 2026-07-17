; Exact finite Galois closure over object-membership columns.

!(assertEqual
   (galois-closure-atom
     (o1 o2) (a b) ((o1 o2) (o2)) ())
   (a))
!(assertEqual
   (galois-closure-atom
     (o1 o2) (a b) ((o1 o2) (o2)) (b))
   (a b))
!(assertEqual
   (galois-closure-atom
     (o1 o2) (a b) ((o1 o2) (o2)) (outside))
   (a))

; An empty extent derives every attribute.
!(assertEqual
   (galois-closure-atom
     (o1 o2) (a b c) ((o1 o2) (o2) ()) (c))
   (a b c))

; Both incidence patterns and query outcomes have negative examples.
!(assertEqual
   (galois-closure-atom
     (o1 o2) (a b c) ((o1 o2) (o2) ()) (a))
   (a))

!(assertEqualToResult
   (galois-closure-atom (o1) (a) ((o1)))
   ((Error
      (galois-closure-atom (o1) (a) ((o1)))
      IncorrectNumberOfArguments)))
