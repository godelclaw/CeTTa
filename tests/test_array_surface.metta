!(import! &self array)

!(assertEqual (array:shape (array:from-list (a b c))) (3))
!(assertEqual (array:rank (array:from-list (a b c))) 1)
!(assertEqual (array:size (array:from-list (a b c))) 3)
!(assertEqual (array:to-list (array:from-list (a b c))) (a b c))
!(assertEqual (array:dtype (array:from-list (a b c))) Any)
!(assertEqual (array:device (array:from-list (a b c))) cpu)
!(assertEqual (array:layout (array:from-list (a b c))) c)
!(assertEqual (array:offset (array:from-list (a b c))) 0)
!(assertEqual (array:strides (array:from-list (a b c))) (1))
!(assertEqual (array:owned? (array:from-list (a b c))) True)
!(assertEqual (array:view? (array:from-list (a b c))) False)
!(assertEqual (array:writeable? (array:from-list (a b c))) True)
!(assertEqual (array:readonly? (array:from-list (a b c))) False)
!(assertEqual (array:contiguous? (array:from-list (a b c))) True)
!(assertEqual (array:get (array:from-list (a b c)) (1)) b)
!(assertEqual (array:strides (array:from-flat (2 2) (1 2 3 4))) (2 1))
!(assertEqual (array:get (array:from-flat (2 2) (1 2 3 4)) (1 0)) 3)
!(assertEqual (array:get (array:transpose2 (array:from-flat (2 2) (1 2 3 4))) (1 0)) 2)
!(assertEqual (array:shape (array:transpose2 (array:from-flat (2 2) (1 2 3 4)))) (2 2))
!(assertEqual (array:strides (array:transpose2 (array:from-flat (2 2) (1 2 3 4)))) (1 2))
!(assertEqual (array:view? (array:transpose2 (array:from-flat (2 2) (1 2 3 4)))) True)
!(assertEqual (array:to-list (array:slice1 (array:from-list (a b c d e)) 1 4)) (b c d))
!(assertEqual (array:offset (array:slice1 (array:from-list (a b c d e)) 1 4)) 1)
!(assertEqual (array:reshape (array:from-list (1 2 3 4)) (2 2))
              (array:view (array:from-list (1 2 3 4)) (2 2) (2 1) 0))
!(assertEqual (array:zeros 3) (array:from-flat (3) (0 0 0)))
!(assertEqual (array:ones 3) (array:from-flat (3) (1 1 1)))
!(assertEqual (array:full1 3 7) (array:from-flat (3) (7 7 7)))
!(assertEqual
  (array:set (array:from-list (a b c)) (1) z)
  (array:from-flat (3) (a z c)))
!(assertEqual
  (array:set (array:from-flat (2 2) (1 2 3 4)) (0 1) 9)
  (array:from-flat (2 2) (1 9 3 4)))
!(assertEqual
  (array:view? (array:wrap (2 2) (2 1) 0 f32 cpu c view readonly (1 2 3 4)))
  True)
!(assertEqual
  (array:readonly? (array:wrap (2 2) (2 1) 0 f32 cpu c view readonly (1 2 3 4)))
  True)
!(assertEqual
  (array:builder:len (array:builder:new))
  0)
!(assertEqual
  (array:builder:finish1
    (array:builder:push
      (array:builder:push
        (array:builder:push (array:builder:new-typed f32 cpu) 1)
        2)
      3))
  (array:from-flat-meta (3) f32 cpu c owned writeable (1 2 3)))
!(assertEqual
  (array:builder:finish
    (array:builder:push
      (array:builder:push
        (array:builder:push
          (array:builder:push (array:builder:new-typed f64 cpu) 1)
          2)
        3)
      4)
    (2 2))
  (array:from-flat-meta (2 2) f64 cpu c owned writeable (1 2 3 4)))

!(assertEqual
  (array:to-list (array:transpose2 (array:from-flat (2 2) (1 2 3 4))))
  (1 3 2 4))
!(assertEqual
  (array:copy (array:transpose2 (array:from-flat (2 2) (1 2 3 4))))
  (array:from-flat-meta (2 2) Any cpu c owned writeable (1 3 2 4)))
!(assertEqual
  (array:set (array:transpose2 (array:from-flat (2 2) (1 2 3 4))) (1 0) 9)
  (array:from-flat-meta (2 2) Any cpu c owned writeable (1 3 9 4)))
