; Scalable native Duquenne-Guigues bases via logical-pseudo-closure NextClosure.

; Attribute a is shared by every object, so the sole canonical implication is
; the positive statement empty -> a.
!(assertEqual
   (galois-canonical-basis-next-atom
     (o1 o2) (a b) ((o1 o2) (o2)) 3 1)
   ((() (a))))

; The scalable and powerset reference implementations agree exactly as sets.
!(assertEqual
   (let $next
        (eval
          (galois-canonical-basis-next-atom
            (o1 o2 o3) (a b c)
            ((o1 o2) (o2 o3) (o1 o3)) 8 0))
     (let $reference
          (eval
            (galois-canonical-basis-atom
              (o1 o2 o3) (a b c)
              ((o1 o2) (o2 o3) (o1 o3)) 8 0))
       (same-set-atom? $next $reference)))
   True)

; Independent singleton columns realize the full powerset and imply nothing.
!(assertEqual
   (galois-canonical-basis-next-atom
     (o1 o2) (a b) ((o1) (o2)) 4 0)
   ())

; The empty attribute universe is a valid negative/no-implication example.
!(assertEqual
   (galois-canonical-basis-next-atom
     (o1 o2) () () 1 0)
   ())

; Logical-closure and output bounds fail loudly rather than returning a
; partial basis.
!(assertEqualToResult
   (galois-canonical-basis-next-atom
     (o1 o2) (a b) ((o1 o2) (o2)) 2 1)
   ((Error
      (galois-canonical-basis-next-atom
        (o1 o2) (a b) ((o1 o2) (o2)) 2 1)
      GaloisLogicalClosureLimitExceeded)))
!(assertEqualToResult
   (galois-canonical-basis-next-atom
     (o1 o2) (a b) ((o1 o2) (o2)) 3 0)
   ((Error
      (galois-canonical-basis-next-atom
        (o1 o2) (a b) ((o1 o2) (o2)) 3 0)
      GaloisBasisLimitExceeded)))

!(assertEqualToResult
   (galois-canonical-basis-next-atom
     (o1) (a) ((o1)) 2.5 0)
   ((Error
      (galois-canonical-basis-next-atom
        (o1) (a) ((o1)) 2.5 0)
      IntegerEnumerationLimitExpected)))

!(assertEqualToResult
   (galois-canonical-basis-next-atom
     (o1) (a) ((o1)) 0 0)
   ((Error
      (galois-canonical-basis-next-atom
        (o1) (a) ((o1)) 0 0)
      PositiveLogicalClosureLimitExpected)))
