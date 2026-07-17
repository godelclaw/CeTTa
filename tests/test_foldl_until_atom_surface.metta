; A continuing fold consumes the complete expression.
!(assertEqual
   (foldl-until-atom
     (1 2 3) 0 $sum $item
     (let $next (eval (+ $sum $item))
       (FoldContinue $next)))
   6)

; FoldStop returns the current result without evaluating later items.
!(assertEqual
   (foldl-until-atom
     (1 2 10 100) 0 $sum $item
     (if (> $item 3)
         (FoldStop $sum)
         (let $next (eval (+ $sum $item))
           (FoldContinue $next))))
   3)

; Empty input returns the initial accumulator.
!(assertEqual
   (foldl-until-atom
     () seed $acc $item (FoldContinue $item))
   seed)

; Stopping on the first item is distinct from completing a full fold.
!(assertEqual
   (foldl-until-atom
     (stop ignored) initial $acc $item
     (FoldStop ($acc $item)))
   (initial stop))
