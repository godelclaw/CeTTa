!(import! &self time)
!(import! &self str)

!(assertEqualToResult
  (let $ms (time:unix-time-ms)
    (and (== (get-type $ms) Number) (> $ms 1750000000000)))
  (True))

!(assertEqualToResult
  (let $t0 (time:unix-time-ms)
    (let $slept (time:sleep-ms 15)
      (let $t1 (time:unix-time-ms)
        (and (== $slept True) (>= (- $t1 $t0) 10)))))
  (True))

!(time:sleep-ms 0)

!(assertEqualToResult
  (let $s (time:time-string "%Y")
    (and (== (get-type $s) String) (== (str:length $s) 4)))
  (True))

!(assertEqualToResult
  (let $s (time:time-string)
    (== (str:length $s) 19))
  (True))

;; Out-of-int32-range values are rejected, not truncated to a short sleep.
;; (Contained in case: a top-level Error result halts file evaluation.)
!(case (time:sleep-ms 4294967296)
   (((Error $call $msg) big-int-rejected)
    ($other (unexpected $other))))

!(time:sleep-ms -1)
