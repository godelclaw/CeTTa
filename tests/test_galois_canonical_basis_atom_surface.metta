; Exact native Duquenne-Guigues bases over finite binary contexts.

; Attribute a is shared by every object, so the sole canonical implication is
; the positive statement empty -> a.
!(assertEqual
   (galois-canonical-basis-atom
     (o1 o2) (a b) ((o1 o2) (o2)) 4 1)
   ((() (a))))

; Independent singleton columns realize the full powerset and imply nothing.
!(assertEqual
   (galois-canonical-basis-atom
     (o1 o2) (a b) ((o1) (o2)) 4 0)
   ())

; The empty attribute universe is a valid negative/no-implication example.
!(assertEqual
   (galois-canonical-basis-atom
     (o1 o2) () () 1 0)
   ())

; Candidate and result bounds fail loudly rather than returning partial bases.
!(assertEqualToResult
   (galois-canonical-basis-atom
     (o1 o2) (a b) ((o1) (o2)) 3 0)
   ((Error
      (galois-canonical-basis-atom
        (o1 o2) (a b) ((o1) (o2)) 3 0)
      GaloisCandidateLimitExceeded)))
!(assertEqualToResult
   (galois-canonical-basis-atom
     (o1 o2) (a b) ((o1 o2) (o2)) 4 0)
   ((Error
      (galois-canonical-basis-atom
        (o1 o2) (a b) ((o1 o2) (o2)) 4 0)
      GaloisBasisLimitExceeded)))

!(assertEqualToResult
   (galois-canonical-basis-atom
     (o1) (a) ((o1)) 2.5 0)
   ((Error
      (galois-canonical-basis-atom
        (o1) (a) ((o1)) 2.5 0)
      IntegerEnumerationLimitExpected)))
