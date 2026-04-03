; Prototype array helpers for CeTTa.
;
; Design intent:
; - array is a distinct lane from list/clist
; - current prototype stores flat data in ordinary expressions
; - future runtimes can replace the storage while keeping array:* stable
; - use list for symbolic collections, clist for inductive structure, array for dense-ish numeric/indexed work
; - reads are native-ish through list/index-atom; updates still rebuild in this prototype
; - foundation hooks are explicit now: shape, strides, dtype, device, layout, ownership, writeability

!(import! &self list)

(= (array:wrap $shape $strides $dtype $device $layout $ownership $writeability $flat)
   (Array (ArrayMeta $shape $strides $dtype $device $layout $ownership $writeability) $flat))

(= (array:from-flat $shape $flat)
   (array:from-flat-meta $shape Any cpu c owned writeable $flat))

(= (array:from-flat-meta $shape $dtype $device $layout $ownership $writeability $flat)
   (if (== (array:shape-size $shape) (list:len $flat))
       (array:wrap $shape (array:default-strides $shape) $dtype $device $layout $ownership $writeability $flat)
       (Error (array:from-flat-meta $shape $dtype $device $layout $ownership $writeability $flat)
              "shape does not match flat length")))

(= (array:from-list $xs)
   (let $n (list:len $xs)
     (array:from-flat ($n) $xs)))

(= (array:meta (Array $meta $flat))
   $meta)

(= (array:shape (Array (ArrayMeta $shape $strides $dtype $device $layout $ownership $writeability) $flat))
   $shape)

(= (array:strides (Array (ArrayMeta $shape $strides $dtype $device $layout $ownership $writeability) $flat))
   $strides)

(= (array:dtype (Array (ArrayMeta $shape $strides $dtype $device $layout $ownership $writeability) $flat))
   $dtype)

(= (array:device (Array (ArrayMeta $shape $strides $dtype $device $layout $ownership $writeability) $flat))
   $device)

(= (array:layout (Array (ArrayMeta $shape $strides $dtype $device $layout $ownership $writeability) $flat))
   $layout)

(= (array:ownership (Array (ArrayMeta $shape $strides $dtype $device $layout $ownership $writeability) $flat))
   $ownership)

(= (array:writeability (Array (ArrayMeta $shape $strides $dtype $device $layout $ownership $writeability) $flat))
   $writeability)

(= (array:flat (Array (ArrayMeta $shape $strides $dtype $device $layout $ownership $writeability) $flat))
   $flat)

(= (array:rank $array)
   (list:len (array:shape $array)))

(= (array:size $array)
   (list:len (array:flat $array)))

(= (array:owned? $array)
   (== (array:ownership $array) owned))

(= (array:view? $array)
   (== (array:ownership $array) view))

(= (array:writeable? $array)
   (== (array:writeability $array) writeable))

(= (array:readonly? $array)
   (== (array:writeability $array) readonly))

(= (array:contiguous? $array)
   (== (array:strides $array) (array:default-strides (array:shape $array))))

(= (array:to-list (Array (ArrayMeta ($n) $strides $dtype $device $layout $ownership $writeability) $flat))
   $flat)

(= (array:get (Array (ArrayMeta ($n) $strides $dtype $device $layout $ownership $writeability) $flat) ($i))
   (list:at $flat $i))

(= (array:get (Array (ArrayMeta ($rows $cols) $strides $dtype $device $layout $ownership $writeability) $flat) ($i $j))
   (list:at $flat (+ (* $i $cols) $j)))

(= (array:set (Array (ArrayMeta ($n) $strides $dtype $device $layout $ownership $writeability) $flat) ($i) $value)
   (let $flat2 (eval (array:replace-at $flat $i $value))
     (array:wrap ($n) $strides $dtype $device $layout owned writeable $flat2)))

(= (array:set (Array (ArrayMeta ($rows $cols) $strides $dtype $device $layout $ownership $writeability) $flat) ($i $j) $value)
   (let $offset (+ (* $i $cols) $j)
     (let $flat2 (eval (array:replace-at $flat $offset $value))
       (array:wrap ($rows $cols) $strides $dtype $device $layout owned writeable $flat2))))

(= (array:zeros $n)
   (array:full1 $n 0))

(= (array:ones $n)
   (array:full1 $n 1))

(= (array:full1 $n $value)
   (let $flat (eval (array:repeat $n $value))
     (array:from-flat ($n) $flat)))

(= (array:shape-size ())
   1)

(= (array:shape-size $shape)
   (let ($dim $tail) (decons-atom $shape)
     (* $dim (array:shape-size $tail))))

(= (array:default-strides $shape)
   (array:default-strides-acc (list:reverse $shape) 1 ()))

(= (array:default-strides-acc () $stride $acc)
   $acc)

(= (array:default-strides-acc $revshape $stride $acc)
   (let ($dim $tail) (decons-atom $revshape)
     (eval (array:default-strides-acc $tail (* $stride $dim) (cons-atom $stride $acc)))))

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

(= (array:builder:new)
   (ArrayBuilder Any cpu c ()))

(= (array:builder:new-typed $dtype $device)
   (ArrayBuilder $dtype $device c ()))

(= (array:builder:dtype (ArrayBuilder $dtype $device $layout $revflat))
   $dtype)

(= (array:builder:device (ArrayBuilder $dtype $device $layout $revflat))
   $device)

(= (array:builder:layout (ArrayBuilder $dtype $device $layout $revflat))
   $layout)

(= (array:builder:push (ArrayBuilder $dtype $device $layout $revflat) $value)
   (ArrayBuilder $dtype $device $layout (cons-atom $value $revflat)))

(= (array:builder:len (ArrayBuilder $dtype $device $layout $revflat))
   (list:len $revflat))

(= (array:builder:flat (ArrayBuilder $dtype $device $layout $revflat))
   (list:reverse $revflat))

(= (array:builder:finish (ArrayBuilder $dtype $device $layout $revflat) $shape)
   (let $flat (array:builder:flat (ArrayBuilder $dtype $device $layout $revflat))
     (array:from-flat-meta $shape $dtype $device $layout owned writeable $flat)))

(= (array:builder:finish1 (ArrayBuilder $dtype $device $layout $revflat))
   (let $n (list:len $revflat)
     (array:builder:finish (ArrayBuilder $dtype $device $layout $revflat) ($n))))
