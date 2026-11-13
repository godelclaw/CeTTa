; Active experiment cost, including CLI startup, against its extended host.
!(import! &self "./benchmark.metta")
!(import! &self (library math))

(= (hb:code $size $shape)
   (if (== $shape sum) (bp:code $size)
     (str:join "" (
       "(= (build $n) (if (== $n 0) Nil (Cons (Box $n) (build (- $n 1))))) "
       "(= (total Nil) 0) (= (total (Cons (Box $v) $t)) (+ $v (total $t))) "
       "!(total (build " (repr $size) "))"))))
(= (hb:one $binary $enabled $size $shape $cwd $rss)
   (let* (($core (hb:code $size $shape))
          ($program (if $enabled (str:concat "!(ai:experiment failure-values) " $core) $core))
          ($answer (if (== $shape sum) (* 32 (* $size (+ $size 1))) (math:floor (/ (* $size (+ $size 1)) 2))))
          ($wanted (str:join "" ((if $enabled "[()]\n" "") "[" (repr $answer) "]\n")))
          ($argv ("/usr/bin/time" "-f" "%M" "-o" $rss $binary "--lang" "he" "--profile"
                  (if $enabled "ai" "extended") "-e" $program))
          ($start (system:monotonic-ns))
          ($ran (proc:run $argv $cwd (bp:environment) 60000 1048576))
          ($end (system:monotonic-ns)))
     (case $ran
       (((proc:exited 0 $actual "")
          (if (== $actual $wanted)
            (Measurement (- $end $start) (str:string->number (str:trim (fs:read-text $rss))))
            (bp:fail (ActiveHEBenchmarkValueMismatch $enabled $size $shape $wanted $actual))))
        ($bad (bp:fail (ActiveHEBenchmarkExecutionFailed $enabled $size $shape $bad)))))))
(= (hb:walk $binary $size $shape $cwd $dir $left $enabled-first $rows)
   (if (== $left 0) $rows
     (let* (($one (hb:one $binary $enabled-first $size $shape $cwd (str:concat $dir "/one.rss")))
            ($two (hb:one $binary (not $enabled-first) $size $shape $cwd (str:concat $dir "/two.rss")))
            ((Measurement $ons $orss) $one) ((Measurement $tns $trss) $two)
            ($row (if $enabled-first (Sample $tns $ons $trss $orss) (Sample $ons $tns $orss $trss)))
            ($shown (println! (ActiveHEBenchmarkSample $size $shape $left $row))))
       (hb:walk $binary $size $shape $cwd $dir (- $left 1) (not $enabled-first) (cons-atom $row $rows)))))
(= (hb:run $binary $size $shape $cwd $dir)
   (let* (($made (fs:make-directories $dir 511))
          ($warm-base (hb:one $binary False $size $shape $cwd (str:concat $dir "/warm-base.rss")))
          ($warm-active (hb:one $binary True $size $shape $cwd (str:concat $dir "/warm-active.rss")))
          ($rows (hb:walk $binary $size $shape $cwd $dir 9 True ())))
     (bp:summary (ActiveHE $shape) $size $rows)))
