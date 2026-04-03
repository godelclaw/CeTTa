; Prototype array helpers for CeTTa.
;
; Design intent:
; - array is a distinct lane from list/clist
; - current prototype stores flat data in ordinary expressions
; - future runtimes can replace the storage while keeping array:* stable
; - use list for symbolic collections, clist for inductive structure, array for dense-ish numeric/indexed work
; - reads are native-ish through offset + strides over flat storage; updates still rebuild/materialize in this prototype
; - foundation hooks are explicit now: shape, strides, offset, dtype, device, layout, ownership, writeability

!(import! &self list)

(= (array:wrap $shape $strides $offset $dtype $device $layout $ownership $writeability $storage)
   (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))

(= (array:from-flat $shape $flat)
   (array:from-flat-meta $shape Any cpu c owned writeable $flat))

(= (array:from-flat-meta $shape $dtype $device $layout $ownership $writeability $flat)
   (if (== (array:shape-size $shape) (list:len $flat))
       (array:wrap $shape (array:default-strides $shape) 0 $dtype $device $layout $ownership $writeability $flat)
       (Error (array:from-flat-meta $shape $dtype $device $layout $ownership $writeability $flat)
              "shape does not match flat length")))

(= (array:from-list $xs)
   (let $n (list:len $xs)
     (array:from-flat ($n) $xs)))

(= (array:meta (Array $meta $storage))
   $meta)

(= (array:shape (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))
   $shape)

(= (array:strides (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))
   $strides)

(= (array:offset (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))
   $offset)

(= (array:dtype (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))
   $dtype)

(= (array:device (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))
   $device)

(= (array:layout (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))
   $layout)

(= (array:ownership (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))
   $ownership)

(= (array:writeability (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))
   $writeability)

(= (array:storage (Array (ArrayMeta $shape $strides $offset $dtype $device $layout $ownership $writeability) $storage))
   $storage)

(= (array:flat $array)
   (array:storage $array))

(= (array:rank $array)
   (list:len (array:shape $array)))

(= (array:size $array)
   (array:shape-size (array:shape $array)))

(= (array:owned? $array)
   (== (array:ownership $array) owned))

(= (array:view? $array)
   (== (array:ownership $array) view))

(= (array:writeable? $array)
   (== (array:writeability $array) writeable))

(= (array:readonly? $array)
   (== (array:writeability $array) readonly))

(= (array:contiguous? $array)
   (and (== (array:offset $array) 0)
        (== (array:strides $array) (array:default-strides (array:shape $array)))))

(= (array:view $array $shape $strides $offset)
   (array:wrap $shape $strides $offset
               (array:dtype $array)
               (array:device $array)
               (array:layout $array)
               view
               (array:writeability $array)
               (array:storage $array)))

(= (array:to-list $array)
   (array:materialize-flat $array))

(= (array:materialize-flat $array)
   (if (array:contiguous? $array)
       (array:materialize-contiguous $array)
       (array:materialize-flat-indices $array (array:all-indices (array:shape $array)))))

(= (array:materialize-flat-indices $array ())
   ())

(= (array:materialize-flat-indices $array $indices-list)
   (let ($indices $tail) (decons-atom $indices-list)
     (let $value (array:get $array $indices)
       (let $rest (eval (array:materialize-flat-indices $array $tail))
         (cons-atom $value $rest)))))

(= (array:all-indices ())
   (()))

(= (array:all-indices $shape)
   (let ($dim $tail) (decons-atom $shape)
     (let $suffixes (array:all-indices $tail)
       (array:all-indices-dim 0 $dim $suffixes))))

(= (array:all-indices-dim $i $dim $suffixes)
   (if (>= $i $dim)
       ()
       (list:append (array:prefix-each $i $suffixes)
                    (array:all-indices-dim (+ $i 1) $dim $suffixes))))

(= (array:prefix-each $i ())
   ())

(= (array:prefix-each $i $suffixes)
   (let ($suffix $tail) (decons-atom $suffixes)
     (cons-atom (cons-atom $i $suffix)
                (eval (array:prefix-each $i $tail)))))

(= (array:materialize-contiguous $array)
   (array:materialize-storage (array:storage $array) (array:offset $array) (array:size $array) 0 ()))

(= (array:materialize-storage $storage $offset $size $idx $acc)
   (if (>= $idx $size)
       (list:reverse $acc)
       (let $value (list:at $storage (+ $offset $idx))
         (eval (array:materialize-storage $storage $offset $size (+ $idx 1) (cons-atom $value $acc))))))

(= (array:copy $array)
   (array:from-flat-meta (array:shape $array)
                         (array:dtype $array)
                         (array:device $array)
                         c
                         owned
                         writeable
                         (array:materialize-flat $array)))

(= (array:get $array $indices)
   (let $lin (+ (array:offset $array) (array:index-dot (array:strides $array) $indices))
     (list:at (array:storage $array) $lin)))

(= (array:set $array $indices $value)
   (let $base (array:copy $array)
     (let $flat (array:storage $base)
       (let $lin (array:index-dot (array:default-strides (array:shape $base)) $indices)
         (let $flat2 (eval (array:replace-at $flat $lin $value))
           (array:from-flat-meta (array:shape $base)
                                 (array:dtype $base)
                                 (array:device $base)
                                 (array:layout $base)
                                 owned
                                 writeable
                                 $flat2))))))

(= (array:reshape $array $shape)
   (if (== (array:size $array) (array:shape-size $shape))
       (if (array:contiguous? $array)
           (array:view $array $shape (array:default-strides $shape) (array:offset $array))
           (Error (array:reshape $array $shape) "reshape requires contiguous array in this prototype"))
       (Error (array:reshape $array $shape) "reshape size mismatch")))

(= (array:transpose2 $array)
   (let $shape (array:shape $array)
     (let ($rows $rest) (decons-atom $shape)
       (let ($cols $_) (decons-atom $rest)
         (let $strides (array:strides $array)
           (let ($sr $srest) (decons-atom $strides)
             (let ($sc $_) (decons-atom $srest)
               (array:view $array ($cols $rows) ($sc $sr) (array:offset $array)))))))))

(= (array:slice1 $array $start $stop)
   (let $shape (array:shape $array)
     (let ($n $_) (decons-atom $shape)
       (let $strides (array:strides $array)
         (let ($stride $_) (decons-atom $strides)
           (array:view $array
                       ((- $stop $start))
                       ($stride)
                       (+ (array:offset $array) (* $start $stride))))))))

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

(= (array:index-dot () ())
   0)

(= (array:index-dot $strides $indices)
   (let ($s $srest) (decons-atom $strides)
     (let ($i $irest) (decons-atom $indices)
       (+ (* $s $i) (array:index-dot $srest $irest)))))

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
