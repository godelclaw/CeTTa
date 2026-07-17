; Exact finite intent enumeration using native Ganter Next-Closure.

; A mandatory attribute yields two concepts in lectic order.
!(assertEqual
   (galois-intents-atom
     (o1 o2) (a b) ((o1 o2) (o2)) 4)
   ((a) (a b)))

; Independent singleton columns expose all four attribute subsets.
!(assertEqual
   (galois-intents-atom
     (o1 o2) (a b) ((o1) (o2)) 4)
   (() (b) (a) (a b)))

; With no objects, every attribute is vacuously shared and only the top
; intent exists.
!(assertEqual
   (galois-intents-atom
     () (a b) (() ()) 1)
   ((a b)))

; The explicit limit fails loudly instead of returning a partial lattice.
!(assertEqualToResult
   (galois-intents-atom
     (o1 o2) (a b) ((o1) (o2)) 3)
   ((Error
      (galois-intents-atom
        (o1 o2) (a b) ((o1) (o2)) 3)
      GaloisEnumerationLimitExceeded)))

!(assertEqualToResult
   (galois-intents-atom
     (o1) (a) ((o1)) 1.5)
   ((Error
      (galois-intents-atom
        (o1) (a) ((o1)) 1.5)
      IntegerEnumerationLimitExpected)))
