; Repeated real provider preparation, including its compatibility view.
; Retain each result through the loop and check the final legacy digest.
; No provider transport is called.
!(import! &self "./outcome_kernel_benchmark.metta")

(= (okp:input $size $heavy)
   (let* (($padding (if (== $size 0) "hello" (okb:repeat $size "x")))
          ($prompt (if (== $size 0) $padding
             (str:join "" ("{\"kind\":\"role-context-v1\",\"messages\":[{\"role\":\"user\",\"content\":\""
               $padding "\"}],\"cache_points\":[]}"))))
          ($tokens (if $heavy "\"bad\"" "100")))
     (str:join "" ("\"responses\" \"fixture-model\" " $tokens " \"default\" "
                    (repr $prompt) " JsonNull \"5m\""))))
(= (okp:expression $mode $arguments)
   (if (== $mode kernel)
     (str:join "" ("(kpr:legacy-view (kpr:prepare-command " $arguments "))"))
     (if (== $mode builtin)
       (str:join "" ("(aipr:legacy-view (catch (aipr:prepare-command " $arguments ")))"))
       (str:join "" ("(preq:prepare-command " $arguments ")")))))
(= (okp:code $consumer $size $heavy $path $repetitions)
   (let* (($mode (okb:family $path))
          ($module (str:concat $consumer (if (== $mode kernel) "/src/provider_request_kernel.metta"
                    (if (== $mode builtin) "/src/provider_request_ai.metta" "/src/provider_request_cetta.metta"))))
          ($arguments (okp:input $size $heavy)))
     (str:join "" (
       (if (or (== $path kernel-composed) (== $path off-composed))
         "!(ai:experiment he-composed-execution) " "")
       (if (== $mode kernel) "!(ai:experiment outcome-kernel) "
         (if (== $mode builtin) "!(ai:experiment failure-values) " ""))
       "!(import! &self (library system)) !(import! &self (library str)) !(import! &self " (repr $module) ") "
       "(= (op:step) " (okp:expression $mode $arguments) ") "
       "(= (op:repeat $left $last) (if (== $left 0) $last "
       "(let $next (op:step) (op:repeat (- $left 1) $next)))) "
       "!(let $warm (op:step) (let $start (system:monotonic-ns) "
       "(let $last (op:repeat " (repr $repetitions) " $warm) "
       "(let $elapsed (- (system:monotonic-ns) $start) "
       "(PreparationMeasurement (str:sha256 (repr $last)) $elapsed)))))"))))
(= (okp:one $binary $root $consumer $lang $size $heavy $mode $repetitions $rss)
   (let $program (okp:code $consumer $size $heavy $mode $repetitions)
     (case (proc:run ("/usr/bin/time" "-f" "%M" "-o" $rss $binary "--lang" $lang "--profile" "ai" "-e" $program)
                       $root (bp:environment) 20000 1048576)
       (((proc:exited 0 $out "")
          (let* (($last (okb:last (str:split "\n" (str:trim $out))))
                 ($line (if (== $lang "he") (str:byte-slice $last 1 (- (str:byte-length $last) 1)) $last)))
            (case (parse $line)
              (((PreparationMeasurement $digest $ns)
                 (ProviderMeasurement $digest $ns (str:string->number (str:trim (fs:read-text $rss)))))
               ($bad (ProviderUnavailable $lang $mode $bad))))))
        ($bad (ProviderExecutionFailed $lang $mode $bad))))))
(= (okp:sample $binary $root $consumer $lang $size $heavy $count $dir $modes $rows)
   (if (== $modes ()) $rows
     (let* (($mode (car-atom $modes))
            ($measurement (okp:one $binary $root $consumer $lang $size $heavy $mode $count
                            (str:join "" ($dir "/provider-" (repr $mode) ".rss"))))
            ($printed (println! (KernelProviderSample $lang $size $heavy $count $mode $measurement))))
       (okp:sample $binary $root $consumer $lang $size $heavy $count $dir (cdr-atom $modes)
         (cons-atom (Mode $mode $measurement) $rows)))))
(= (okp:check $rows $digest)
   (if (== $rows ()) True
     (case (car-atom $rows)
       (((Mode $mode (ProviderMeasurement $same $ns $rss))
          (if (and (== $same $digest) (and (> $ns 0) (> $rss 0)))
            (okp:check (cdr-atom $rows) $digest) (ProviderDigestMismatch $mode $same $digest)))
        ($unavailable (ProviderComparisonUnavailable $unavailable))))))
(= (okp:reference $rows)
   (if (== $rows ()) MissingReference
     (case (car-atom $rows)
       (((Mode off (ProviderMeasurement $digest $ns $rss)) $digest)
        ($other (okp:reference (cdr-atom $rows)))))))
(= (okp:walk $binary $root $consumer $lang $size $heavy $count $dir $remaining $phase)
   (if (== $remaining 0) (KernelProviderComplete $lang $size $heavy $count)
     (let* (($first (if (== $phase 0) (off builtin kernel)
                     (if (== $phase 1) (builtin kernel off) (kernel off builtin))))
            ($modes $first)
            ($rows (okp:sample $binary $root $consumer $lang $size $heavy $count $dir $modes ()))
            ($digest (okp:reference $rows))
            ($checked (println! (KernelProviderComparison $lang $size $heavy (okp:check $rows $digest)))))
       (okp:walk $binary $root $consumer $lang $size $heavy $count $dir (- $remaining 1)
         (if (== $phase 2) 0 (+ $phase 1))))))
