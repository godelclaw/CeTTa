; Exact Hasse covers for finite families under set inclusion.

; A chain exposes each adjacent inclusion and suppresses transitive pairs.
!(assertEqual
   (subset-cover-relations-atom (() (a) (a b) (a b c)) 4 3)
   ((() (a)) ((a) (a b)) ((a b) (a b c))))

; A diamond has two covers above bottom and two below top.
!(assertEqual
   (subset-cover-relations-atom (() (a) (b) (a b)) 4 4)
   ((() (a)) (() (b)) ((a) (a b)) ((b) (a b))))

; Family duplicates and duplicate set elements are semantically inert.
!(assertEqual
   (subset-cover-relations-atom (() (a a) (a) (a b)) 4 2)
   ((() (a a)) ((a a) (a b))))

; A singleton family is the negative/no-cover case.
!(assertEqual
   (subset-cover-relations-atom ((a)) 1 0)
   ())

; Both safety bounds fail loudly instead of returning partial relations.
!(assertEqualToResult
   (subset-cover-relations-atom (() (a)) 1 1)
   ((Error
      (subset-cover-relations-atom (() (a)) 1 1)
      SubsetCoverFamilyLimitExceeded)))
!(assertEqualToResult
   (subset-cover-relations-atom (() (a) (a b)) 3 1)
   ((Error
      (subset-cover-relations-atom (() (a) (a b)) 3 1)
      SubsetCoverLimitExceeded)))

!(assertEqualToResult
   (subset-cover-relations-atom (() (a)) 2.5 1)
   ((Error
      (subset-cover-relations-atom (() (a)) 2.5 1)
      IntegerEnumerationLimitExpected)))
