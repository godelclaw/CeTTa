!(import! &self array)

!(assertEqual (array:shape (array:from-list (a b c))) (3))
!(assertEqual (array:rank (array:from-list (a b c))) 1)
!(assertEqual (array:size (array:from-list (a b c))) 3)
!(assertEqual (array:to-list (array:from-list (a b c))) (a b c))
!(assertEqual (array:get (array:from-list (a b c)) (1)) b)
!(assertEqual (array:get (array:from-flat (2 2) (1 2 3 4)) (1 0)) 3)
!(assertEqual (array:zeros 3) (array:from-flat (3) (0 0 0)))
!(assertEqual (array:ones 3) (array:from-flat (3) (1 1 1)))
!(assertEqual (array:full1 3 7) (array:from-flat (3) (7 7 7)))
!(assertEqual
  (array:set (array:from-list (a b c)) (1) z)
  (array:from-flat (3) (a z c)))
!(assertEqual
  (array:set (array:from-flat (2 2) (1 2 3 4)) (0 1) 9)
  (array:from-flat (2 2) (1 9 3 4)))
