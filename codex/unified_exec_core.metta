; Rust-faithful pure unified-exec core/mod.rs slice.
;
; This ports deterministic data shapes and helpers from:
; - openai-codex/codex-rs/core/src/unified_exec/mod.rs
;   - UnifiedExecContext::new
;   - ExecCommandRequest
;   - WriteStdinRequest
;   - UnifiedExecProcessManager::new / Default
;   - clamp_yield_time
;   - resolve_max_tokens
;   - generate_chunk_id hex formatting
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - write_stdin yield-time bound calculation
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores `Arc<Session>` and `Arc<TurnContext>` in `UnifiedExecContext`.
;   This pure data boundary preserves those fields as opaque atoms until the
;   session/turn runtime is ported.
; - Rust `ExecCommandRequest` uses `Option<T>` and borrowed path/network/profile
;   types. This port follows the existing CeTTa Codex convention and represents
;   `None` as `CodexAbsent`; present values are carried directly.
; - Rust `UnifiedExecProcessManager` owns a `tokio::sync::Mutex<ProcessStore>`.
;   This pure boundary stores the ported immutable process-store atom directly;
;   later runtime slices can wrap the same value in mutable/session storage.
; - Rust `generate_chunk_id` samples six random nibbles with `rand::rng()`.
;   Until a numeric RNG library is part of the CeTTa runtime boundary, this
;   slice ports the exact six-hex materialization from an explicit six-nibble
;   input. The future runtime helper should supply those nibbles from the RNG.

!(import! &self list)
!(import! &self unified_exec_process_store)

; `UNIFIED_EXEC_OUTPUT_MAX_BYTES` is already ported in
; unified_exec_head_tail_buffer.metta; process-count constants are already
; ported in unified_exec_process_pruning.metta. This slice does not redefine
; those public helpers so importing multiple unified-exec modules does not
; create duplicate CeTTa results.

(= (codex:unified-exec-min-yield-time-ms)
   250)

; Minimum yield time for an empty write_stdin.
(= (codex:unified-exec-min-empty-yield-time-ms)
   5000)

(= (codex:unified-exec-max-yield-time-ms)
   30000)

(= (codex:unified-exec-default-max-background-terminal-timeout-ms)
   300000)

(= (codex:unified-exec-default-max-output-tokens)
   10000)

(= (codex:unified-exec-output-max-tokens)
   262144)

(= (codex:unified-exec-context-new $session $turn $call-id)
   (CodexUnifiedExecContext $session $turn $call-id))

(= (codex:unified-exec-context-session
      (CodexUnifiedExecContext $session $turn $call-id))
   $session)

(= (codex:unified-exec-context-turn
      (CodexUnifiedExecContext $session $turn $call-id))
   $turn)

(= (codex:unified-exec-context-call-id
      (CodexUnifiedExecContext $session $turn $call-id))
   $call-id)

(= (codex:unified-exec-exec-command-request
      $command
      $hook-command
      $process-id
      $yield-time-ms
      $max-output-tokens
      $workdir
      $network
      $tty
      $sandbox-permissions
      $additional-permissions
      $additional-permissions-preapproved
      $justification
      $prefix-rule)
   (CodexUnifiedExecExecCommandRequest
     $command
     $hook-command
     $process-id
     $yield-time-ms
     $max-output-tokens
     $workdir
     $network
     $tty
     $sandbox-permissions
     $additional-permissions
     $additional-permissions-preapproved
     $justification
     $prefix-rule))

(= (codex:unified-exec-exec-command-request-command
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $command)

(= (codex:unified-exec-exec-command-request-hook-command
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $hook-command)

(= (codex:unified-exec-exec-command-request-process-id
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $process-id)

(= (codex:unified-exec-exec-command-request-yield-time-ms
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $yield-time-ms)

(= (codex:unified-exec-exec-command-request-max-output-tokens
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $max-output-tokens)

(= (codex:unified-exec-exec-command-request-workdir
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $workdir)

(= (codex:unified-exec-exec-command-request-network
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $network)

(= (codex:unified-exec-exec-command-request-tty
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $tty)

(= (codex:unified-exec-exec-command-request-sandbox-permissions
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $sandbox-permissions)

(= (codex:unified-exec-exec-command-request-additional-permissions
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $additional-permissions)

(= (codex:unified-exec-exec-command-request-additional-permissions-preapproved
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $additional-permissions-preapproved)

(= (codex:unified-exec-exec-command-request-justification
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $justification)

(= (codex:unified-exec-exec-command-request-prefix-rule
      (CodexUnifiedExecExecCommandRequest
        $command
        $hook-command
        $process-id
        $yield-time-ms
        $max-output-tokens
        $workdir
        $network
        $tty
        $sandbox-permissions
        $additional-permissions
        $additional-permissions-preapproved
        $justification
        $prefix-rule))
   $prefix-rule)

(= (codex:unified-exec-write-stdin-request
      $process-id
      $input
      $yield-time-ms
      $max-output-tokens)
   (CodexUnifiedExecWriteStdinRequest
     $process-id
     $input
     $yield-time-ms
     $max-output-tokens))

(= (codex:unified-exec-write-stdin-request-process-id
      (CodexUnifiedExecWriteStdinRequest
        $process-id
        $input
        $yield-time-ms
        $max-output-tokens))
   $process-id)

(= (codex:unified-exec-write-stdin-request-input
      (CodexUnifiedExecWriteStdinRequest
        $process-id
        $input
        $yield-time-ms
        $max-output-tokens))
   $input)

(= (codex:unified-exec-write-stdin-request-yield-time-ms
      (CodexUnifiedExecWriteStdinRequest
        $process-id
        $input
        $yield-time-ms
        $max-output-tokens))
   $yield-time-ms)

(= (codex:unified-exec-write-stdin-request-max-output-tokens
      (CodexUnifiedExecWriteStdinRequest
        $process-id
        $input
        $yield-time-ms
        $max-output-tokens))
   $max-output-tokens)

(= (codex:unified-exec-process-manager $process-store $max-write-stdin-yield-time-ms)
   (CodexUnifiedExecProcessManager
     $process-store
     $max-write-stdin-yield-time-ms))

(= (codex:unified-exec-process-manager-process-store
      (CodexUnifiedExecProcessManager
        $process-store
        $max-write-stdin-yield-time-ms))
   $process-store)

(= (codex:unified-exec-process-manager-max-write-stdin-yield-time-ms
      (CodexUnifiedExecProcessManager
        $process-store
        $max-write-stdin-yield-time-ms))
   $max-write-stdin-yield-time-ms)

(= (codex:unified-exec-process-manager-new $max-write-stdin-yield-time-ms)
   (CodexUnifiedExecProcessManager
     (codex:unified-exec-process-store-default)
     (if (> $max-write-stdin-yield-time-ms
            (codex:unified-exec-min-empty-yield-time-ms))
         $max-write-stdin-yield-time-ms
         (codex:unified-exec-min-empty-yield-time-ms))))

(= (codex:unified-exec-process-manager-default)
   (codex:unified-exec-process-manager-new
     (codex:unified-exec-default-max-background-terminal-timeout-ms)))

(= (codex:unified-exec-clamp-yield-time $yield-time-ms)
   (if (< $yield-time-ms (codex:unified-exec-min-yield-time-ms))
       (codex:unified-exec-min-yield-time-ms)
       (if (> $yield-time-ms (codex:unified-exec-max-yield-time-ms))
           (codex:unified-exec-max-yield-time-ms)
           $yield-time-ms)))

(= (codex:unified-exec-resolve-max-tokens $max-tokens)
   (if (== $max-tokens CodexAbsent)
       (codex:unified-exec-default-max-output-tokens)
       $max-tokens))

(= (codex:unified-exec-write-stdin-yield-time-ms
      $manager
      $request)
   (let $request-yield-time-ms
     (codex:unified-exec-write-stdin-request-yield-time-ms $request)
     (let $input
       (codex:unified-exec-write-stdin-request-input $request)
       (let $time-ms
         (if (> $request-yield-time-ms
                (codex:unified-exec-min-yield-time-ms))
             $request-yield-time-ms
             (codex:unified-exec-min-yield-time-ms))
         (if (== $input "")
             (let $empty-min
               (codex:unified-exec-min-empty-yield-time-ms)
               (let $manager-max
                 (codex:unified-exec-process-manager-max-write-stdin-yield-time-ms
                   $manager)
                 (if (< $time-ms $empty-min)
                     $empty-min
                     (if (> $time-ms $manager-max)
                         $manager-max
                         $time-ms))))
             (if (> $time-ms (codex:unified-exec-max-yield-time-ms))
                 (codex:unified-exec-max-yield-time-ms)
                 $time-ms))))))

(= (codex:unified-exec-hex-nibble $nibble)
   (if (== $nibble 0)
       "0"
       (if (== $nibble 1)
           "1"
           (if (== $nibble 2)
               "2"
               (if (== $nibble 3)
                   "3"
                   (if (== $nibble 4)
                       "4"
                       (if (== $nibble 5)
                           "5"
                           (if (== $nibble 6)
                               "6"
                               (if (== $nibble 7)
                                   "7"
                                   (if (== $nibble 8)
                                       "8"
                                       (if (== $nibble 9)
                                           "9"
                                           (if (== $nibble 10)
                                               "a"
                                               (if (== $nibble 11)
                                                   "b"
                                                   (if (== $nibble 12)
                                                       "c"
                                                       (if (== $nibble 13)
                                                           "d"
                                                           (if (== $nibble 14)
                                                               "e"
                                                               (if (== $nibble 15)
                                                                   "f"
                                                                   CodexAbsent)))))))))))))))))

(= (codex:unified-exec-chunk-id-from-hex-chars
      $a
      $b
      $c
      $d
      $e
      $f)
   (if (== $a CodexAbsent)
       CodexAbsent
       (if (== $b CodexAbsent)
           CodexAbsent
           (if (== $c CodexAbsent)
               CodexAbsent
               (if (== $d CodexAbsent)
                   CodexAbsent
                   (if (== $e CodexAbsent)
                       CodexAbsent
                       (if (== $f CodexAbsent)
                           CodexAbsent
                           (format-args
                             "{}{}{}{}{}{}"
                             ($a $b $c $d $e $f)))))))))

(= (codex:unified-exec-generate-chunk-id-from-nibbles $nibbles)
   (if (== (list:len $nibbles) 6)
       (codex:unified-exec-chunk-id-from-hex-chars
         (codex:unified-exec-hex-nibble (list:at $nibbles 0))
         (codex:unified-exec-hex-nibble (list:at $nibbles 1))
         (codex:unified-exec-hex-nibble (list:at $nibbles 2))
         (codex:unified-exec-hex-nibble (list:at $nibbles 3))
         (codex:unified-exec-hex-nibble (list:at $nibbles 4))
         (codex:unified-exec-hex-nibble (list:at $nibbles 5)))
       CodexAbsent))
