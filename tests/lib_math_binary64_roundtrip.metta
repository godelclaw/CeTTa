; math:binary64-from-parts is the exact inverse of math:binary64-parts: every
; one of 4096 pseudo-random 64-bit words, taken apart as binary64 fields,
; comes back as the value whose parts are exactly those fields (subnormals,
; signed zeros, infinities and NaN payloads included), and a value binary64
; cannot hold exactly is refused by name, never rounded.
!(import! &self (library math))

(= (rt:two63) 9223372036854775808)
(= (rt:two52) 4503599627370496)
; The parts binary64-parts reports for the value whose bits are $word.
(= (rt:parts $word)
   (let* (($negative (>= $word (rt:two63)))
          ($sign (if $negative -1 1))
          ($rest (if $negative (- $word (rt:two63)) $word))
          ((IntegerDivmodV1 $field $fraction) (math:integer-divmod $rest (rt:two52))))
     (if (== $field 2047)
         (if (== $fraction 0) (Binary64InfinityV1 $sign) (Binary64NaNV1 $sign $fraction))
         (if (== $field 0)
             (Binary64PartsV1 $sign $fraction -1074)
             (Binary64PartsV1 $sign (+ $fraction (rt:two52)) (- $field 1075))))))
(= (rt:next $word)
   (let (IntegerDivmodV1 $q $r)
        (math:integer-divmod (+ (* 6364136223846793005 $word) 1442695040888963407) 18446744073709551616)
     $r))
(= (rt:round-trips? $parts) (== (math:binary64-parts (math:binary64-from-parts $parts)) $parts))
; The words run in batches of 64, so no dialect recurses deeper than about 128.
(= (rt:batch $word $left $passed)
   (if (== $left 0) ($word $passed)
     (rt:batch (rt:next $word) (- $left 1) (if (rt:round-trips? (rt:parts $word)) (+ $passed 1) $passed))))
; The number of words, from $word on, whose parts round-trip.
(= (rt:count $word $batches $passed)
   (if (== $batches 0) $passed
     (let ($next $sum) (rt:batch $word 64 $passed) (rt:count $next (- $batches 1) $sum))))

!(println! (EDGES
  (map-atom (0 1 9223372036854775808 9223372036854775809 4503599627370495 4503599627370496
             4607182418800017408 9218868437227405311 9218868437227405312 18442240474082181120
             9218868437227405313 18444492273895866434)
            $word (rt:round-trips? (rt:parts $word)))))
!(println! (ZEROS (math:binary64-parts (math:binary64-from-parts (Binary64PartsV1 -1 0 7)))
                  (math:binary64-parts (math:binary64-from-parts (Binary64PartsV1 1 0 -2000)))))
!(println! (VALUES (math:binary64-from-parts (Binary64PartsV1 1 3 -1))
                   (math:binary64-from-parts (Binary64PartsV1 -1 4 -3))
                   (math:binary64-from-parts (Binary64PartsV1 1 1267650600228229401496703205376 -100))
                   (== (math:binary64-from-parts (Binary64PartsV1 1 1 -1074)) 4.9406564584124654e-324)
                   (== (math:binary64-from-parts (Binary64PartsV1 1 9007199254740991 971)) 1.7976931348623157e+308)))
!(println! (REFUSED
  (math:binary64-from-parts (Binary64PartsV1 1 9007199254740993 0))
  (math:binary64-from-parts (Binary64PartsV1 1 1 -1075))
  (math:binary64-from-parts (Binary64PartsV1 1 3 -1075))
  (math:binary64-from-parts (Binary64PartsV1 1 1 1024))
  (math:binary64-from-parts (Binary64PartsV1 1 9007199254740991 972))
  (math:binary64-from-parts (Binary64PartsV1 0 1 0))
  (math:binary64-from-parts (Binary64PartsV1 1 -1 0))
  (math:binary64-from-parts (Binary64PartsV1 1 1.0 0))
  (math:binary64-from-parts (Binary64NaNV1 1 0))
  (math:binary64-from-parts (Binary64NaNV1 1 4503599627370496))
  (math:binary64-from-parts (Binary64InfinityV1 2))
  (math:binary64-from-parts 1.5)))
!(println! (RANDOM (rt:count 2710532 64 0)))
