; Prototype array helpers for CeTTa.
;
; Design intent:
; - array is a distinct lane from list/clist
; - current prototype stores flat data in ordinary expressions
; - future runtimes can replace the storage while keeping array:* stable
; - use list for symbolic collections, clist for inductive structure, array for dense-ish numeric/indexed work
; - reads are native-ish through list/index-atom; updates still rebuild in this prototype

!(import! &self list)

(= (array:from-flat $shape $flat)
   (Array $shape $flat))

(= (array:from-list $xs)
   (let $n (list:len $xs)
     (Array ($n) $xs)))

(= (array:shape (Array $shape $flat))
   $shape)

(= (array:flat (Array $shape $flat))
   $flat)

(= (array:rank (Array $shape $flat))
   (list:len $shape))

(= (array:size (Array $shape $flat))
   (list:len $flat))

(= (array:to-list (Array ($n) $flat))
   $flat)

(= (array:get (Array ($n) $flat) ($i))
   (list:at $flat $i))

(= (array:get (Array ($rows $cols) $flat) ($i $j))
   (list:at $flat (+ (* $i $cols) $j)))

(= (array:set (Array ($n) $flat) ($i) $value)
   (let $flat2 (eval (array:replace-at $flat $i $value))
     (Array ($n) $flat2)))

(= (array:set (Array ($rows $cols) $flat) ($i $j) $value)
   (let $offset (+ (* $i $cols) $j)
     (let $flat2 (eval (array:replace-at $flat $offset $value))
       (Array ($rows $cols) $flat2))))

(= (array:zeros $n)
   (array:full1 $n 0))

(= (array:ones $n)
   (array:full1 $n 1))

(= (array:full1 $n $value)
   (let $flat (eval (array:repeat $n $value))
     (Array ($n) $flat)))

(= (array:repeat $n $value)
   (if (<= $n 0)
       ()
       (let $tail (eval (array:repeat (- $n 1) $value))
         (cons-atom $value $tail))))

(= (array:replace-at () $index $value)
   ())

(= (array:replace-at $xs $index $value)
   (if (<= $index 0)
       (let ($_ $tail) (decons-atom $xs)
         (cons-atom $value $tail))
       (let ($head $tail) (decons-atom $xs)
         (let $rest (eval (array:replace-at $tail (- $index 1) $value))
           (cons-atom $head $rest)))))
