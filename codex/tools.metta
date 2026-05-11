; Visible minimal tool-execution slice for the restarted Codex port.
;
; This ports the narrowest runnable `exec_command` path from
; openai-codex/codex-rs/core/src/tools/{handlers/unified_exec.rs,context.rs}
; and codex-rs/core/src/unified_exec/mod.rs:
; - exec_command JSON argument decoding
; - shell selection and argv derivation
; - running/completed unified-exec output formatting
; - write_stdin JSON decoding and lowering
; - custom-tool-call -> custom-tool-call-output lowering for exec_command and
;   write_stdin
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust generates random six-hex chunk IDs. This slice derives a stable chunk
;   marker from the tool call id because the current CeTTa library surface has
;   no RNG helper yet.
; - Rust truncation preserves UTF-8 scalar boundaries. CeTTa's current
;   `str-slice` surface is byte-indexed, so the truncation helper is
;   byte-oriented in this slice. The demo/tests keep ASCII output until a
;   scalar-aware string helper lands.
; - Rust does not need a helper to resume a prior exec result object because
;   its async handler layer can naturally thread `session_id` into a later
;   write_stdin tool call. This slice adds an internal
;   `codex:run-exec-command-then-write-stdin-result` helper only for
;   deterministic local surface coverage, because the current evaluator is
;   still brittle when a single `.metta` file tries to rebuild follow-on JSON
;   from a prior result. The public `write_stdin` tool path remains unchanged,
;   but the helper keeps the resumed-session metadata lane auditable.
; - Rust applies `apply_patch` interception inside unified_exec. The restarted
;   CeTTa tool layer does not yet have the full unified_exec/orchestrator
;   stack, so the visible interception is wired at the custom-tool-call
;   lowering surface instead. This preserves the exec_command behavior that is
;   user-visible in the current restart slices.
; - Rust threads login-shell allowance from session config. This slice assumes
;   login shells are allowed and therefore matches the public `exec_command`
;   default of `login = true`.
; - The restarted tool surface does not yet expose turn/session approval
;   config. Direct `apply_patch` execution and exec_command interception
;   therefore use the current local CLI assumptions from `codex:apply_patch`.

!(import! &self apply_patch)
!(import! &self command)
!(import! &self json)
!(import! &self list)
!(import! &self path)
!(import! &self process)
!(import! &self protocol)
!(import! &self request_permissions)
!(import! &self request_user_input)
!(import! &self str)
!(import! &self system)

(= (codex:default-exec-yield-time-ms)
   10000)

(= (codex:default-write-stdin-yield-time-ms)
   250)

(= (codex:minimum-exec-yield-time-ms)
   250)

(= (codex:maximum-exec-yield-time-ms)
   30000)

(= (codex:default-max-output-tokens)
   10000)

(= (codex:maximum-raw-output-bytes)
   1048576)

(= (codex:json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:json-object-required-string $object $key)
   (json-string-value (json-object-get $object $key)))

(= (codex:json-object-required-int $object $key)
   (codex:decimal-string-to-number
     (json-number-value (json-object-get $object $key))))

(= (codex:json-object-optional-string $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $text) $text))))

(= (codex:json-object-optional-bool $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonBool $value) $value))))

(= (codex:json-object-optional-int $object $key)
   (case (codex:json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonNumber $text) (codex:decimal-string-to-number $text)))))

(= (codex:decimal-digit-value "0")
   0)

(= (codex:decimal-digit-value "1")
   1)

(= (codex:decimal-digit-value "2")
   2)

(= (codex:decimal-digit-value "3")
   3)

(= (codex:decimal-digit-value "4")
   4)

(= (codex:decimal-digit-value "5")
   5)

(= (codex:decimal-digit-value "6")
   6)

(= (codex:decimal-digit-value "7")
   7)

(= (codex:decimal-digit-value "8")
   8)

(= (codex:decimal-digit-value "9")
   9)

(= (codex:decimal-string-to-number $text)
   (if (== $text "")
       0
       (codex:decimal-string-to-number-from $text 0 0)))

(= (codex:decimal-string-to-number-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10) (codex:decimal-digit-value $digit-char))))))

(= (codex:clamp-yield-time-ms $value)
   (if (< $value (codex:minimum-exec-yield-time-ms))
       (codex:minimum-exec-yield-time-ms)
       (if (> $value (codex:maximum-exec-yield-time-ms))
           (codex:maximum-exec-yield-time-ms)
           $value)))

(= (codex:resolve-login-shell $value)
   (if (== $value CodexAbsent)
       True
       $value))

(= (codex:resolve-tty $value)
   (if (== $value CodexAbsent)
       False
       $value))

(= (codex:resolve-max-output-tokens $value)
   (if (== $value CodexAbsent)
       (codex:default-max-output-tokens)
       $value))

(= (codex:resolve-yield-time-ms $value)
   (if (== $value CodexAbsent)
       (codex:default-exec-yield-time-ms)
       (codex:clamp-yield-time-ms $value)))

(= (codex:resolve-write-stdin-yield-time-ms $value)
   (if (== $value CodexAbsent)
       (codex:default-write-stdin-yield-time-ms)
       $value))

(= (codex:resolve-workdir $workdir)
   (if (== $workdir CodexAbsent)
       (system-cwd)
       (if (path-is-absolute? $workdir)
           (path-normalize $workdir)
           (path-join (system-cwd) $workdir))))

(= (codex:shell-path-name $shell-path)
   (let $parts (path-parts $shell-path)
     (if (== $parts ())
         $shell-path
         (list:first (list:reverse $parts)))))

(= (codex:resolve-shell-from-path $shell-path)
   (let $shell-name (codex:shell-path-name $shell-path)
     (if (== $shell-name "bash")
         (process-shell "bash" $shell-path)
         (if (== $shell-name "zsh")
             (process-shell "zsh" $shell-path)
             (if (== $shell-name "sh")
                 (process-shell "sh" $shell-path)
                 (if (== $shell-name "pwsh")
                     (process-shell "powershell" $shell-path)
                     (if (== $shell-name "powershell")
                         (process-shell "powershell" $shell-path)
                         (if (== $shell-name "cmd")
                             (process-shell "cmd" $shell-path)
                             (if (== $shell-name "cmd.exe")
                                 (process-shell "cmd" $shell-path)
                                 (process-default-shell))))))))))

(= (codex:resolve-shell $shell-path)
   (if (== $shell-path CodexAbsent)
       (process-default-shell)
       (codex:resolve-shell-from-path $shell-path)))

(= (codex:parse-exec-command-args $input)
   (let $json (json-parse $input)
     (let $cmd (codex:json-object-required-string $json "cmd")
       (let $workdir (codex:json-object-optional-string $json "workdir")
         (let $shell (codex:json-object-optional-string $json "shell")
           (let $login (codex:json-object-optional-bool $json "login")
             (let $tty (codex:json-object-optional-bool $json "tty")
               (let $yield-time-ms (codex:json-object-optional-int $json "yield_time_ms")
                 (let $max-output-tokens
                   (codex:json-object-optional-int $json "max_output_tokens")
                   (CodexExecCommandArgs
                     $cmd
                     (codex:resolve-workdir $workdir)
                     (codex:resolve-shell $shell)
                     (codex:resolve-login-shell $login)
                     (codex:resolve-tty $tty)
                     (codex:resolve-yield-time-ms $yield-time-ms)
                     (codex:resolve-max-output-tokens $max-output-tokens)))))))))))

(= (codex:parse-write-stdin-args $input)
   (let $json (json-parse $input)
     (let $chars (codex:json-object-optional-string $json "chars")
       (let $yield-time-ms (codex:json-object-optional-int $json "yield_time_ms")
         (let $max-output-tokens
           (codex:json-object-optional-int $json "max_output_tokens")
           (CodexWriteStdinArgs
             (codex:json-object-required-int $json "session_id")
             (if (== $chars CodexAbsent) "" $chars)
             (codex:resolve-write-stdin-yield-time-ms $yield-time-ms)
             (codex:resolve-max-output-tokens $max-output-tokens)))))))

(= (codex:exec-command-text
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens))
   $cmd)

(= (codex:exec-command-cwd
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens))
   $workdir)

(= (codex:exec-command-shell
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens))
   $shell)

(= (codex:exec-command-login-shell
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens))
   $use-login-shell)

(= (codex:exec-command-tty
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens))
   $tty)

(= (codex:exec-command-yield-time-ms
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens))
   $yield-time-ms)

(= (codex:exec-command-max-output-tokens
      (CodexExecCommandArgs
        $cmd
        $workdir
        $shell
        $use-login-shell
        $tty
        $yield-time-ms
        $max-output-tokens))
   $max-output-tokens)

(= (codex:write-stdin-session-id
      (CodexWriteStdinArgs
        $session-id
        $chars
        $yield-time-ms
        $max-output-tokens))
   $session-id)

(= (codex:write-stdin-chars
      (CodexWriteStdinArgs
        $session-id
        $chars
        $yield-time-ms
        $max-output-tokens))
   $chars)

(= (codex:write-stdin-yield-time-ms
      (CodexWriteStdinArgs
        $session-id
        $chars
        $yield-time-ms
        $max-output-tokens))
   $yield-time-ms)

(= (codex:write-stdin-max-output-tokens
      (CodexWriteStdinArgs
        $session-id
        $chars
        $yield-time-ms
        $max-output-tokens))
   $max-output-tokens)

(= (codex:exec-command-argv $args)
   (process-shell-argv
     (codex:exec-command-shell $args)
     (codex:exec-command-text $args)
     (codex:exec-command-login-shell $args)))

(= (codex:strip-trailing-dot-zero $text)
   (if (str-ends-with? $text ".0")
       (str-slice $text 0 (- (str-length $text) 2))
       $text))

(= (codex:number-text $value)
   (codex:strip-trailing-dot-zero (format-args "{}" ($value))))

(= (codex:normalize-whole-number $value)
   (codex:decimal-string-to-number (codex:number-text $value)))

(= (codex:approx-token-count $text)
   (codex:normalize-whole-number
     (ceil-math (/ (str-length $text) 4))))

(= (codex:approx-bytes-for-tokens $tokens)
   (* $tokens 4))

(= (codex:approx-tokens-from-byte-count $bytes)
   (codex:normalize-whole-number
     (ceil-math (/ $bytes 4))))

(= (codex:is-string-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

(= (codex:count-lines $text)
   (if (== $text "")
       0
       (let $parts (str-split "\n" $text)
         (if (str-ends-with? $text "\n")
             (- (list:len $parts) 1)
             (list:len $parts)))))

(= (codex:token-truncation-marker $removed-bytes)
   (str-concat
     "..."
     (str-concat
       (codex:number-text
         (codex:approx-tokens-from-byte-count $removed-bytes))
       " tokens truncated...")))

(= (codex:truncate-middle-with-token-budget $text $max-tokens)
   (let $max-bytes (codex:approx-bytes-for-tokens $max-tokens)
     (codex:truncate-middle-with-token-budget-bytes $text $max-bytes)))

(= (codex:truncate-middle-with-token-budget-bytes $text $max-bytes)
   (if (<= (str-length $text) $max-bytes)
       $text
       (if (== $max-bytes 0)
           (codex:token-truncation-marker (str-length $text))
           (let $text-len (str-length $text)
             (let $left-budget (/ $max-bytes 2)
               (let $right-budget (- $max-bytes $left-budget)
                 (let $prefix-end
                   (if (> $left-budget $text-len) $text-len $left-budget)
                   (let $suffix-start-target
                     (if (> $right-budget $text-len)
                         0
                         (- $text-len $right-budget))
                     (let $suffix-start
                       (if (< $suffix-start-target $prefix-end)
                           $prefix-end
                           $suffix-start-target)
                       (str-concat
                         (str-slice $text 0 $prefix-end)
                         (str-concat
                           (codex:token-truncation-marker
                             (- $text-len $max-bytes))
                           (str-slice $text $suffix-start $text-len))))))))))))

(= (codex:format-truncated-output $text $max-output-tokens)
   (let $max-bytes (codex:approx-bytes-for-tokens $max-output-tokens)
     (if (<= (str-length $text) $max-bytes)
         $text
         (str-concat
           (format-args "Total output lines: {}\n\n" ((codex:count-lines $text)))
           (codex:truncate-middle-with-token-budget $text $max-output-tokens)))))

(= (codex:pad-left-3 $text)
   (if (== (str-length $text) 0)
       "000"
       (if (== (str-length $text) 1)
           (str-concat "00" $text)
           (if (== (str-length $text) 2)
               (str-concat "0" $text)
               $text))))

(= (codex:duration-ms-to-seconds-text $duration-ms)
   (let $seconds-whole
     (codex:normalize-whole-number (trunc-math (/ $duration-ms 1000)))
     (let $millis (% $duration-ms 1000)
       (str-concat
         (codex:number-text $seconds-whole)
         (str-concat
           "."
           (str-concat
             (codex:pad-left-3 (codex:number-text $millis))
             "0"))))))

(= (codex:chunk-id-from-call-id $call-id)
   (if (<= (str-length $call-id) 6)
       $call-id
       (str-slice $call-id 0 6)))

(= (codex:format-exec-command-output
      $chunk-id
      $duration-ms
      $is-running
      $session-id
      $has-exit-code
      $exit-code
      $aggregated-output
      $max-output-tokens
      $original-token-count)
   (if $has-exit-code
       (if $is-running
           (format-args
             "Chunk ID: {}\nWall time: {} seconds\nProcess exited with code {}\nProcess running with session ID {}\nOriginal token count: {}\nOutput:\n{}"
             ($chunk-id
              (codex:duration-ms-to-seconds-text $duration-ms)
              $exit-code
              $session-id
              (codex:number-text $original-token-count)
              (codex:format-truncated-output
                $aggregated-output
                $max-output-tokens)))
           (format-args
             "Chunk ID: {}\nWall time: {} seconds\nProcess exited with code {}\nOriginal token count: {}\nOutput:\n{}"
             ($chunk-id
              (codex:duration-ms-to-seconds-text $duration-ms)
              $exit-code
              (codex:number-text $original-token-count)
              (codex:format-truncated-output
                $aggregated-output
                $max-output-tokens))))
       (if $is-running
           (format-args
             "Chunk ID: {}\nWall time: {} seconds\nProcess running with session ID {}\nOriginal token count: {}\nOutput:\n{}"
             ($chunk-id
              (codex:duration-ms-to-seconds-text $duration-ms)
              $session-id
              (codex:number-text $original-token-count)
              (codex:format-truncated-output
                $aggregated-output
                $max-output-tokens)))
           (format-args
             "Chunk ID: {}\nWall time: {} seconds\nOriginal token count: {}\nOutput:\n{}"
             ($chunk-id
              (codex:duration-ms-to-seconds-text $duration-ms)
              (codex:number-text $original-token-count)
              (codex:format-truncated-output
                $aggregated-output
                $max-output-tokens))))))

(= (codex:make-exec-command-run-from-snapshot
      $chunk-id
      $max-output-tokens
      (ProcessSessionSnapshot
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $event-call-id
        $hook-command))
   (let $original-token-count
     (codex:approx-token-count $aggregated-output)
     (CodexExecCommandRun
       $event-call-id
       $chunk-id
       $hook-command
       $max-output-tokens
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $original-token-count
       (codex:format-exec-command-output
         $chunk-id
         $duration-ms
         $is-running
         $session-id
         $has-exit-code
         $exit-code
         $aggregated-output
         $max-output-tokens
         $original-token-count))))

(= (codex:make-exec-command-error-run
      $call-id
      $hook-command
      $max-output-tokens
      $error)
   (let $aggregated-output (str-concat "exec_command failed: " $error)
     (let $original-token-count (codex:approx-token-count $aggregated-output)
       (CodexExecCommandRun
         $call-id
         ""
         $hook-command
         $max-output-tokens
         False
         0
         False
         0
         ""
         $error
         $aggregated-output
         0
         $original-token-count
         $aggregated-output))))

(= (codex:run-exec-command $call-id $input)
   (let $args (codex:parse-exec-command-args $input)
     (case
       (process-open-session-cmd-cwd-env-tty-event-call-id-hook-command-yield-cap-bytes
         (codex:exec-command-argv $args)
         (codex:exec-command-cwd $args)
         (process-create-shell-env-no-thread
           (process-default-shell-env-policy))
         (codex:exec-command-tty $args)
         $call-id
         (codex:exec-command-text $args)
         (codex:exec-command-yield-time-ms $args)
         (codex:maximum-raw-output-bytes))
       (((ProcessSessionCallResult True $error $snapshot)
         (codex:make-exec-command-run-from-snapshot
           (codex:chunk-id-from-call-id $call-id)
           (codex:exec-command-max-output-tokens $args)
           $snapshot))
        ((ProcessSessionCallResult False $error $snapshot)
         (codex:make-exec-command-error-run
           $call-id
           (codex:exec-command-text $args)
           (codex:exec-command-max-output-tokens $args)
           $error))))))

(= (codex:exec-command-run-event-call-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $call-id)

(= (codex:exec-command-run-call-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $call-id)

(= (codex:exec-command-run-chunk-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $chunk-id)

(= (codex:exec-command-run-hook-command
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $hook-command)

(= (codex:exec-command-run-max-output-tokens
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $max-output-tokens)

(= (codex:exec-command-run-text
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $text)

(= (codex:is-exec-command-run-running
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $is-running)

(= (codex:exec-command-run-session-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $session-id)

(= (codex:exec-command-run-exit-code
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        True
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $exit-code)

(= (codex:exec-command-run-stdout
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $stdout)

(= (codex:exec-command-run-stderr
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $stderr)

(= (codex:exec-command-run-aggregated-output
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $aggregated-output)

(= (codex:exec-command-run-duration-ms
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $duration-ms)

(= (codex:exec-command-run-original-token-count
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   $original-token-count)

(= (codex:is-exec-command-run-timed-out
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   False)

(= (codex:exec-command-run-output-item
      $output-call-id
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   (codex:tool-result $output-call-id $text))

(= (codex:exec-command-run-output-item
      (CodexExecCommandRun
        $call-id
        $chunk-id
        $hook-command
        $max-output-tokens
        $is-running
        $session-id
        $has-exit-code
        $exit-code
        $stdout
        $stderr
        $aggregated-output
        $duration-ms
        $original-token-count
        $text))
   (codex:tool-result $call-id $text))

(= (codex:write-stdin-result-text
      (CodexWriteStdinResultSuccess $run))
   (codex:exec-command-run-text $run))

(= (codex:write-stdin-result-text
      (CodexWriteStdinResultError $text))
   $text)

(= (codex:is-write-stdin-result-success
      (CodexWriteStdinResultSuccess $run))
   True)

(= (codex:is-write-stdin-result-success
      (CodexWriteStdinResultError $text))
   False)

(= (codex:write-stdin-result-run
      (CodexWriteStdinResultSuccess $run))
   $run)

(= (codex:write-stdin-call-result-to-result
      $call-id
      $max-output-tokens
      (ProcessSessionCallResult True $error $snapshot))
   (CodexWriteStdinResultSuccess
     (codex:make-exec-command-run-from-snapshot
       (codex:chunk-id-from-call-id $call-id)
       $max-output-tokens
       $snapshot)))

(= (codex:write-stdin-call-result-to-result
      $call-id
      $max-output-tokens
      (ProcessSessionCallResult False $error $snapshot))
   (CodexWriteStdinResultError
     (format-args "write_stdin failed: {}" ($error))))

(= (codex:run-write-stdin $call-id $input)
   (let $args (codex:parse-write-stdin-args $input)
     (case
       (process-write-session-stdin-yield-cap-bytes
         (codex:write-stdin-session-id $args)
         (codex:write-stdin-chars $args)
         (codex:write-stdin-yield-time-ms $args)
         (codex:maximum-raw-output-bytes))
       (((ProcessSessionCallResult True $error $snapshot)
         (CodexWriteStdinResultSuccess
           (codex:make-exec-command-run-from-snapshot
             (codex:chunk-id-from-call-id $call-id)
             (codex:write-stdin-max-output-tokens $args)
             $snapshot)))
       ((ProcessSessionCallResult False $error $snapshot)
         (CodexWriteStdinResultError
           (format-args "write_stdin failed: {}" ($error))))))))

(= (codex:run-write-stdin-output-text $call-id $input)
   (codex:write-stdin-result-text
     (codex:run-write-stdin $call-id $input)))

(= (codex:run-exec-command-then-write-stdin-result
      $open-call-id
      $open-input
      $write-call-id
      $chars
      $yield-time-ms)
   (case
     (codex:run-exec-command $open-call-id $open-input)
     (((CodexExecCommandRun
         $prior-call-id
         $prior-chunk-id
         $prior-hook-command
         $max-output-tokens
         True
         $session-id
         $has-exit-code
         $exit-code
         $stdout
         $stderr
         $aggregated-output
         $duration-ms
         $original-token-count
         $text)
       (case
         (process-write-session-stdin-yield-cap-bytes
           $session-id
           $chars
           $yield-time-ms
           (codex:maximum-raw-output-bytes))
         (((ProcessSessionCallResult True $error $snapshot)
           (CodexWriteStdinResultSuccess
             (codex:make-exec-command-run-from-snapshot
               (codex:chunk-id-from-call-id $write-call-id)
               $max-output-tokens
               $snapshot)))
          ((ProcessSessionCallResult False $error $snapshot)
           (CodexWriteStdinResultError
             (format-args "write_stdin failed: {}" ($error)))))))
      ($other
       (CodexWriteStdinResultError
         "write_stdin helper requires a running exec_command result")))))

(= (codex:run-exec-command-then-write-stdin-output-text
      $open-call-id
      $open-input
      $write-call-id
      $chars
      $yield-time-ms)
   (codex:write-stdin-result-text
     (codex:run-exec-command-then-write-stdin-result
       $open-call-id
       $open-input
       $write-call-id
       $chars
       $yield-time-ms)))

(= (codex:run-write-stdin-tool-call $call-id $input)
   (let $result (codex:run-write-stdin $call-id $input)
     (codex:tool-result
       $call-id
       (codex:write-stdin-result-text $result))))

(= (codex:run-exec-command-tool-call $call-id $input)
   (let $args (codex:parse-exec-command-args $input)
     (case
       (codex:run-apply-patch-shell-command-local
         (codex:exec-command-cwd $args)
         (codex:exec-command-text $args))
       (((CodexApplyPatchInterceptNotMatched)
         (let $run (codex:run-exec-command $call-id $input)
           (codex:exec-command-run-output-item
             $call-id
             $run)))
        ((CodexApplyPatchInterceptMatched $text)
         (codex:tool-result $call-id $text)))))

(= (codex:run-apply-patch-tool-call $call-id $input)
   (codex:tool-result $call-id (codex:run-apply-patch-local $input)))

(= (codex:run-request-permissions-tool-call-item $call-id $input)
   (codex:run-request-permissions-tool-call $call-id $input))

(= (codex:run-tool-call-item
      (CodexResponseItemCustomToolCall $call-id $name $input))
   (if (== $name "exec_command")
       (codex:run-exec-command-tool-call $call-id $input)
       (if (== $name "write_stdin")
           (codex:run-write-stdin-tool-call $call-id $input)
           (if (== $name "apply_patch")
               (codex:run-apply-patch-tool-call $call-id $input)
               (if (== $name "request_permissions")
                   (codex:run-request-permissions-tool-call-item $call-id $input)
                   (if (== $name "request_user_input")
                       (codex:run-request-user-input-tool-call $call-id $input)
                   (codex:named-tool-result
                         $call-id
                         $name
                         (format-args "unsupported tool: {}" ($name))))))))))
