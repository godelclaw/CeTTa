; Rust-faithful pure exec-server LocalProcess state slice.
;
; This ports deterministic state-transition behavior from:
; - openai-codex/codex-rs/exec-server/src/local_process.rs
;   - child_env / shell_environment_policy boundary shape
;   - LocalProcess::start_process validation and Starting insertion
;   - successful/failed spawn continuation
;   - exec_read retained-output paging and terminal-event fast path
;   - exec_write status/error branches
;   - terminate_process running flag branch
;   - stream_output retained-output/event/notification state mutation
;   - watch_exit / finish_output_stream / maybe_emit_closed mutation
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns tokio locks, channels, Notify/watch senders, OS process sessions,
;   and task spawns. This pure CeTTa boundary returns immutable updated process
;   maps plus explicit spawn/write/terminate/task/cleanup requests at the same
;   branch points where Rust performs side effects.
; - Rust creates process child environments through codex_config's
;   `create_env`. This slice receives the already-resolved policy environment
;   and then applies Rust's overlay/PATHEXT logic exactly.
; - Rust stores HashMap values for environments. This slice uses ordered
;   string-pair lists and removes duplicate keys while overlaying; JSON object
;   member order is not a Rust-visible contract.
; - Rust retains raw byte vectors. This slice reuses the current protocol
;   `ByteChunk` text boundary and measures `str-length`, matching Rust byte
;   counts for ASCII chunks until a byte-vector runtime library is available.

!(import! &self list)
!(import! &self str)
!(import! &self codex:exec_process_event_log)
!(import! &self codex:exec_server_process_id)
!(import! &self codex:exec_server_process_protocol)

(= (codex:exec-server-local-retained-output-bytes-per-process)
   1048576)

(= (codex:exec-server-local-notification-channel-capacity)
   256)

(= (codex:exec-server-local-process-event-channel-capacity)
   256)

(= (codex:exec-server-local-exited-process-retention-ms)
   30000)

(= (codex:exec-server-local-jsonrpc-code-invalid-request)
   -32600)

(= (codex:exec-server-local-jsonrpc-code-invalid-params)
   -32602)

(= (codex:exec-server-local-jsonrpc-code-internal-error)
   -32603)

(= (codex:exec-server-local-error $code $message)
   (CodexExecServerLocalError $code $message))

(= (codex:exec-server-local-error-code
      (CodexExecServerLocalError $code $message))
   $code)

(= (codex:exec-server-local-error-message
      (CodexExecServerLocalError $code $message))
   $message)

(= (codex:exec-server-local-error-invalid-request $message)
   (CodexExecServerLocalError
     (codex:exec-server-local-jsonrpc-code-invalid-request)
     $message))

(= (codex:exec-server-local-error-invalid-params $message)
   (CodexExecServerLocalError
     (codex:exec-server-local-jsonrpc-code-invalid-params)
     $message))

(= (codex:exec-server-local-error-internal $message)
   (CodexExecServerLocalError
     (codex:exec-server-local-jsonrpc-code-internal-error)
     $message))

(= (codex:exec-server-local-result-ok $value $process)
   (CodexExecServerLocalResultOk $value $process))

(= (codex:exec-server-local-result-err $error $process)
   (CodexExecServerLocalResultErr $error $process))

(= (codex:exec-server-local-result-value
      (CodexExecServerLocalResultOk $value $process))
   $value)

(= (codex:exec-server-local-result-process
      (CodexExecServerLocalResultOk $value $process))
   $process)

(= (codex:exec-server-local-result-process
      (CodexExecServerLocalResultErr $error $process))
   $process)

(= (codex:exec-server-local-result-error
      (CodexExecServerLocalResultErr $error $process))
   $error)

(= (codex:exec-server-local-result-kind
      (CodexExecServerLocalResultOk $value $process))
   ok)

(= (codex:exec-server-local-result-kind
      (CodexExecServerLocalResultErr $error $process))
   err)

(= (codex:exec-server-local-string-pair-key
      (CodexExecServerProtocolStringPair $key $value))
   $key)

(= (codex:exec-server-local-string-pair-value
      (CodexExecServerProtocolStringPair $key $value))
   $value)

(= (codex:exec-server-local-string-pairs-remove-key $pairs $key)
   (if (== $pairs ())
       ()
       (let $head (list:first $pairs)
         (let $tail (list:rest $pairs)
           (let $rest
             (eval
               (codex:exec-server-local-string-pairs-remove-key
                 $tail
                 $key))
             (if (== (codex:exec-server-local-string-pair-key $head)
                     $key)
                 $rest
                 (cons-atom $head $rest)))))))

(= (codex:exec-server-local-string-pairs-lookup $pairs $key)
   (if (== $pairs ())
       CodexAbsent
       (let $head (list:first $pairs)
         (if (== (codex:exec-server-local-string-pair-key $head)
                 $key)
             (codex:exec-server-local-string-pair-value $head)
             (codex:exec-server-local-string-pairs-lookup
               (list:rest $pairs)
               $key)))))

(= (codex:exec-server-local-string-pairs-overlay $base $overlay)
   (if (== $overlay ())
       $base
       (let $head (list:first $overlay)
         (let $key (codex:exec-server-local-string-pair-key $head)
           (let $without-key
             (eval
               (codex:exec-server-local-string-pairs-remove-key
                 $base
                 $key))
             (codex:exec-server-local-string-pairs-overlay
               (list:append $without-key ($head))
               (list:rest $overlay)))))))

(= (codex:exec-server-local-string-pairs-insert-if-absent
      $pairs
      $key
      $value)
   (if (== (codex:exec-server-local-string-pairs-lookup $pairs $key)
           CodexAbsent)
       (list:append
         $pairs
         ((codex:exec-server-protocol-string-pair $key $value)))
       $pairs))

(= (codex:exec-server-local-env-pattern-case-insensitive $pattern)
   (CodexExecServerLocalEnvPatternCaseInsensitive $pattern))

(= (codex:exec-server-local-env-pattern-case-insensitive-pattern
      (CodexExecServerLocalEnvPatternCaseInsensitive $pattern))
   $pattern)

(= (codex:exec-server-local-env-patterns-case-insensitive $patterns)
   (map-atom-strict
     $patterns
     $pattern
     (codex:exec-server-local-env-pattern-case-insensitive $pattern)))

(= (codex:exec-server-local-shell-environment-policy
      $inherit
      $ignore-default-excludes
      $exclude
      $set
      $include-only
      $use-profile)
   (CodexExecServerLocalShellEnvironmentPolicy
     $inherit
     $ignore-default-excludes
     $exclude
     $set
     $include-only
     $use-profile))

(= (codex:exec-server-local-shell-environment-policy-use-profile
      (CodexExecServerLocalShellEnvironmentPolicy
        $inherit
        $ignore-default-excludes
        $exclude
        $set
        $include-only
        $use-profile))
   $use-profile)

(= (codex:exec-server-local-shell-environment-policy-exclude
      (CodexExecServerLocalShellEnvironmentPolicy
        $inherit
        $ignore-default-excludes
        $exclude
        $set
        $include-only
        $use-profile))
   $exclude)

(= (codex:exec-server-local-shell-environment-policy-from-exec
      (CodexExecServerExecEnvPolicy
        $inherit
        $ignore-default-excludes
        $exclude
        $set
        $include-only))
   (CodexExecServerLocalShellEnvironmentPolicy
     $inherit
     $ignore-default-excludes
     (codex:exec-server-local-env-patterns-case-insensitive $exclude)
     $set
     (codex:exec-server-local-env-patterns-case-insensitive $include-only)
     False))

(= (codex:exec-server-local-host-platform-windows)
   (CodexExecServerLocalHostPlatformWindows))

(= (codex:exec-server-local-host-platform-other)
   (CodexExecServerLocalHostPlatformOther))

(= (codex:exec-server-local-is-windows
      (CodexExecServerLocalHostPlatformWindows))
   True)

(= (codex:exec-server-local-is-windows
      (CodexExecServerLocalHostPlatformOther))
   False)

(= (codex:exec-server-local-child-env
      (CodexExecServerExecParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0)
      $resolved-policy-env
      $host-platform)
   (if (== $env-policy CodexAbsent)
       $env
       (let $overlay
         (eval
           (codex:exec-server-local-string-pairs-overlay
             $resolved-policy-env
             $env))
         (if (codex:exec-server-local-is-windows $host-platform)
             (codex:exec-server-local-string-pairs-insert-if-absent
               $overlay
               "PATHEXT"
               ".COM;.EXE;.BAT;.CMD")
             $overlay))))

(= (codex:exec-server-local-spawn-mode-pty)
   (CodexExecServerLocalSpawnModePty))

(= (codex:exec-server-local-spawn-mode-pipe)
   (CodexExecServerLocalSpawnModePipe))

(= (codex:exec-server-local-spawn-mode-pipe-no-stdin)
   (CodexExecServerLocalSpawnModePipeNoStdin))

(= (codex:exec-server-local-spawn-mode-from-params $tty $pipe-stdin)
   (if $tty
       (CodexExecServerLocalSpawnModePty)
       (if $pipe-stdin
           (CodexExecServerLocalSpawnModePipe)
           (CodexExecServerLocalSpawnModePipeNoStdin))))

(= (codex:exec-server-local-terminal-size-default)
   (CodexExecServerLocalTerminalSizeDefault))

(= (codex:exec-server-local-spawn-request
      $process-id
      $program
      $args
      $cwd
      $env
      $arg0
      $mode
      $terminal-size)
   (CodexExecServerLocalSpawnRequest
     $process-id
     $program
     $args
     $cwd
     $env
     $arg0
     $mode
     $terminal-size))

(= (codex:exec-server-local-spawn-request-mode
      (CodexExecServerLocalSpawnRequest
        $process-id
        $program
        $args
        $cwd
        $env
        $arg0
        $mode
        $terminal-size))
   $mode)

(= (codex:exec-server-local-spawn-request-env
      (CodexExecServerLocalSpawnRequest
        $process-id
        $program
        $args
        $cwd
        $env
        $arg0
        $mode
        $terminal-size))
   $env)

(= (codex:exec-server-local-process-entry-starting)
   (CodexExecServerLocalProcessEntryStarting))

(= (codex:exec-server-local-running-process
      $session
      $tty
      $pipe-stdin
      $output
      $retained-bytes
      $next-seq
      $exit-code
      $wake-value
      $events
      $output-notify
      $open-streams
      $closed)
   (CodexExecServerLocalRunningProcess
     $session
     $tty
     $pipe-stdin
     $output
     $retained-bytes
     $next-seq
     $exit-code
     $wake-value
     $events
     $output-notify
     $open-streams
     $closed))

(= (codex:exec-server-local-running-process-output
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed))
   $output)

(= (codex:exec-server-local-running-process-retained-bytes
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed))
   $retained-bytes)

(= (codex:exec-server-local-running-process-next-seq
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed))
   $next-seq)

(= (codex:exec-server-local-running-process-exit-code
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed))
   $exit-code)

(= (codex:exec-server-local-running-process-wake-value
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed))
   $wake-value)

(= (codex:exec-server-local-running-process-events
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed))
   $events)

(= (codex:exec-server-local-running-process-open-streams
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed))
   $open-streams)

(= (codex:exec-server-local-running-process-closed
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed))
   $closed)

(= (codex:exec-server-local-running-process-can-write-stdin
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed))
   (or $tty $pipe-stdin))

(= (codex:exec-server-local-running-process-with-output-state
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed)
      $new-output
      $new-retained-bytes
      $new-next-seq
      $new-wake-value
      $new-events)
   (CodexExecServerLocalRunningProcess
     $session
     $tty
     $pipe-stdin
     $new-output
     $new-retained-bytes
     $new-next-seq
     $exit-code
     $new-wake-value
     $new-events
     $output-notify
     $open-streams
     $closed))

(= (codex:exec-server-local-running-process-with-exit
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed)
      $new-next-seq
      $new-exit-code
      $new-wake-value
      $new-events)
   (CodexExecServerLocalRunningProcess
     $session
     $tty
     $pipe-stdin
     $output
     $retained-bytes
     $new-next-seq
     $new-exit-code
     $new-wake-value
     $new-events
     $output-notify
     $open-streams
     $closed))

(= (codex:exec-server-local-running-process-with-open-streams
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed)
      $new-open-streams)
   (CodexExecServerLocalRunningProcess
     $session
     $tty
     $pipe-stdin
     $output
     $retained-bytes
     $next-seq
     $exit-code
     $wake-value
     $events
     $output-notify
     $new-open-streams
     $closed))

(= (codex:exec-server-local-running-process-with-closed
      (CodexExecServerLocalRunningProcess
        $session
        $tty
        $pipe-stdin
        $output
        $retained-bytes
        $next-seq
        $exit-code
        $wake-value
        $events
        $output-notify
        $open-streams
        $closed)
      $new-next-seq
      $new-wake-value
      $new-events)
   (CodexExecServerLocalRunningProcess
     $session
     $tty
     $pipe-stdin
     $output
     $retained-bytes
     $new-next-seq
     $exit-code
     $new-wake-value
     $new-events
     $output-notify
     $open-streams
     True))

(= (codex:exec-server-local-process-entry-running $process)
   (CodexExecServerLocalProcessEntryRunning $process))

(= (codex:exec-server-local-process-entry-kind
      (CodexExecServerLocalProcessEntryStarting))
   starting)

(= (codex:exec-server-local-process-entry-kind
      (CodexExecServerLocalProcessEntryRunning $process))
   running)

(= (codex:exec-server-local-process-entry-kind CodexAbsent)
   absent)

(= (codex:exec-server-local-process-entry-running-process
      (CodexExecServerLocalProcessEntryRunning $process))
   $process)

(= (codex:exec-server-local-process-record $process-id $entry)
   (CodexExecServerLocalProcessRecord $process-id $entry))

(= (codex:exec-server-local-process-record-process-id
      (CodexExecServerLocalProcessRecord $process-id $entry))
   $process-id)

(= (codex:exec-server-local-process-record-entry
      (CodexExecServerLocalProcessRecord $process-id $entry))
   $entry)

(= (codex:exec-server-local-process-records-get $records $process-id)
   (if (== $records ())
       CodexAbsent
       (let $head (list:first $records)
         (if (== (codex:exec-server-local-process-record-process-id $head)
                 $process-id)
             (codex:exec-server-local-process-record-entry $head)
             (codex:exec-server-local-process-records-get
               (list:rest $records)
               $process-id)))))

(= (codex:exec-server-local-process-records-remove $records $process-id)
   (if (== $records ())
       ()
       (let $head (list:first $records)
         (let $tail (list:rest $records)
           (let $rest
             (eval
               (codex:exec-server-local-process-records-remove
                 $tail
                 $process-id))
             (if (== (codex:exec-server-local-process-record-process-id $head)
                     $process-id)
                 $rest
                 (cons-atom $head $rest)))))))

(= (codex:exec-server-local-process-records-put
      $records
      $process-id
      $entry)
   (let $without
     (eval
       (codex:exec-server-local-process-records-remove
         $records
         $process-id))
     (cons-atom
       (codex:exec-server-local-process-record $process-id $entry)
       $without)))

(= (codex:exec-server-local-process $notifications $processes)
   (CodexExecServerLocalProcess $notifications $processes))

(= (codex:exec-server-local-process-new $notifications)
   (CodexExecServerLocalProcess $notifications ()))

(= (codex:exec-server-local-process-default)
   (CodexExecServerLocalProcess CodexAbsent ()))

(= (codex:exec-server-local-process-notifications
      (CodexExecServerLocalProcess $notifications $processes))
   $notifications)

(= (codex:exec-server-local-process-processes
      (CodexExecServerLocalProcess $notifications $processes))
   $processes)

(= (codex:exec-server-local-process-entry
      (CodexExecServerLocalProcess $notifications $processes)
      $process-id)
   (codex:exec-server-local-process-records-get $processes $process-id))

(= (codex:exec-server-local-process-with-entry
      (CodexExecServerLocalProcess $notifications $processes)
      $process-id
      $entry)
   (CodexExecServerLocalProcess
     $notifications
     (codex:exec-server-local-process-records-put
       $processes
       $process-id
       $entry)))

(= (codex:exec-server-local-process-remove-entry
      (CodexExecServerLocalProcess $notifications $processes)
      $process-id)
   (CodexExecServerLocalProcess
     $notifications
     (codex:exec-server-local-process-records-remove
       $processes
       $process-id)))

(= (codex:exec-server-local-process-set-notification-sender
      (CodexExecServerLocalProcess $notifications $processes)
      $new-notifications)
   (CodexExecServerLocalProcess $new-notifications $processes))

(= (codex:exec-server-local-invalid-duplicate-message $process-id)
   (format-args
     "process {} already exists"
     ((codex:exec-server-process-id-as-str $process-id))))

(= (codex:exec-server-local-unknown-process-message $process-id)
   (format-args
     "unknown process id {}"
     ((codex:exec-server-process-id-as-str $process-id))))

(= (codex:exec-server-local-starting-process-message $process-id)
   (format-args
     "process id {} is starting"
     ((codex:exec-server-process-id-as-str $process-id))))

(= (codex:exec-server-local-start-process-plan
      $local-process
      (CodexExecServerExecParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0)
      $resolved-policy-env
      $host-platform)
   (if (== $argv ())
       (codex:exec-server-local-result-err
         (codex:exec-server-local-error-invalid-params
           "argv must not be empty")
         $local-process)
       (let $existing
         (codex:exec-server-local-process-entry
           $local-process
           $process-id)
         (if (== $existing CodexAbsent)
             (let $with-starting
               (codex:exec-server-local-process-with-entry
                 $local-process
                 $process-id
                 (codex:exec-server-local-process-entry-starting))
               (codex:exec-server-local-result-ok
                 (codex:exec-server-local-spawn-request
                   $process-id
                   (list:first $argv)
                   (list:rest $argv)
                   $cwd
                   (codex:exec-server-local-child-env
                     (CodexExecServerExecParams
                       $process-id
                       $argv
                       $cwd
                       $env-policy
                       $env
                       $tty
                       $pipe-stdin
                       $arg0)
                     $resolved-policy-env
                     $host-platform)
                   $arg0
                   (codex:exec-server-local-spawn-mode-from-params
                     $tty
                     $pipe-stdin)
                   (codex:exec-server-local-terminal-size-default))
                 $with-starting))
             (codex:exec-server-local-result-err
               (codex:exec-server-local-error-invalid-request
                 (codex:exec-server-local-invalid-duplicate-message
                   $process-id))
               $local-process)))))

(= (codex:exec-server-local-stream-task-request
      $process-id
      $stream
      $output-notify)
   (CodexExecServerLocalStreamTaskRequest
     $process-id
     $stream
     $output-notify))

(= (codex:exec-server-local-exit-watch-task-request
      $process-id
      $output-notify)
   (CodexExecServerLocalExitWatchTaskRequest
     $process-id
     $output-notify))

(= (codex:exec-server-local-started
      $response
      $wake-value
      $events
      $task-requests)
   (CodexExecServerLocalStarted
     $response
     $wake-value
     $events
     $task-requests))

(= (codex:exec-server-local-started-response
      (CodexExecServerLocalStarted
        $response
        $wake-value
        $events
        $task-requests))
   $response)

(= (codex:exec-server-local-started-task-requests
      (CodexExecServerLocalStarted
        $response
        $wake-value
        $events
        $task-requests))
   $task-requests)

(= (codex:exec-server-local-start-stdout-stream $tty)
   (if $tty
       (codex:exec-server-output-stream-pty)
       (codex:exec-server-output-stream-stdout)))

(= (codex:exec-server-local-start-stderr-stream $tty)
   (if $tty
       (codex:exec-server-output-stream-pty)
       (codex:exec-server-output-stream-stderr)))

(= (codex:exec-server-local-start-process-spawned
      $local-process
      (CodexExecServerExecParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0)
      $session
      $output-notify)
   (let $events
     (codex:exec-process-event-log-new
       (codex:exec-server-local-process-event-channel-capacity)
       (codex:exec-server-local-retained-output-bytes-per-process))
     (let $running
       (codex:exec-server-local-running-process
         $session
         $tty
         $pipe-stdin
         ()
         0
         1
         CodexAbsent
         0
         $events
         $output-notify
         2
         False)
       (let $updated
         (codex:exec-server-local-process-with-entry
           $local-process
           $process-id
           (codex:exec-server-local-process-entry-running $running))
         (codex:exec-server-local-result-ok
           (codex:exec-server-local-started
             (codex:exec-server-exec-response $process-id)
             0
             $events
             ((codex:exec-server-local-stream-task-request
                $process-id
                (codex:exec-server-local-start-stdout-stream $tty)
                $output-notify)
              (codex:exec-server-local-stream-task-request
                $process-id
                (codex:exec-server-local-start-stderr-stream $tty)
                $output-notify)
              (codex:exec-server-local-exit-watch-task-request
                $process-id
                $output-notify)))
           $updated)))))

(= (codex:exec-server-local-start-process-spawn-failed
      $local-process
      $process-id
      $message)
   (let $entry
     (codex:exec-server-local-process-entry
       $local-process
       $process-id)
     (let $updated
       (if (== $entry (CodexExecServerLocalProcessEntryStarting))
           (codex:exec-server-local-process-remove-entry
             $local-process
             $process-id)
           $local-process)
       (codex:exec-server-local-result-err
         (codex:exec-server-local-error-internal $message)
         $updated))))

(= (codex:exec-server-local-byte-chunk-len $chunk)
   (str-length
     (codex:exec-server-byte-chunk-into-inner $chunk)))

(= (codex:exec-server-local-output-chunk-retained-len
      (CodexExecServerProcessOutputChunk $seq $stream $chunk))
   (codex:exec-server-local-byte-chunk-len $chunk))

(= (codex:exec-server-local-saturating-sub $value $amount)
   (if (< $value $amount)
       0
       (- $value $amount)))

(= (codex:exec-server-local-output-retain-trim
      $output
      $retained-bytes
      $byte-capacity)
   (if (== $output ())
       (CodexExecServerLocalOutputRetainResult () $retained-bytes)
       (if (> $retained-bytes $byte-capacity)
           (let $evicted (list:first $output)
             (codex:exec-server-local-output-retain-trim
               (list:rest $output)
               (codex:exec-server-local-saturating-sub
                 $retained-bytes
                 (codex:exec-server-local-output-chunk-retained-len
                   $evicted))
               $byte-capacity))
           (CodexExecServerLocalOutputRetainResult
             $output
             $retained-bytes))))

(= (codex:exec-server-local-output-retain-result-output
      (CodexExecServerLocalOutputRetainResult $output $retained-bytes))
   $output)

(= (codex:exec-server-local-output-retain-result-retained-bytes
      (CodexExecServerLocalOutputRetainResult $output $retained-bytes))
   $retained-bytes)

(= (codex:exec-server-local-event-stream
      (CodexExecServerExecOutputStreamStdout))
   (codex:exec-output-stream-stdout))

(= (codex:exec-server-local-event-stream
      (CodexExecServerExecOutputStreamStderr))
   (codex:exec-output-stream-stderr))

(= (codex:exec-server-local-event-stream
      (CodexExecServerExecOutputStreamPty))
   (codex:exec-output-stream-pty))

(= (codex:exec-server-local-output-event $protocol-chunk)
   (codex:exec-process-event-output
     (codex:exec-process-output-chunk
       (codex:exec-server-process-output-chunk-seq $protocol-chunk)
       (codex:exec-server-local-event-stream
         (codex:exec-server-process-output-chunk-stream
           $protocol-chunk))
       (codex:exec-server-byte-chunk-into-inner
         (codex:exec-server-process-output-chunk-chunk
           $protocol-chunk)))))

(= (codex:exec-server-local-output-recorded
      $notification
      $wake-seq)
   (CodexExecServerLocalOutputRecorded $notification $wake-seq))

(= (codex:exec-server-local-output-ignored)
   (CodexExecServerLocalOutputIgnored))

(= (codex:exec-server-local-record-output-with-capacity
      $local-process
      $process-id
      $stream
      $chunk
      $byte-capacity)
   (let $entry
     (codex:exec-server-local-process-entry
       $local-process
       $process-id)
     (if (== (codex:exec-server-local-process-entry-kind $entry)
             running)
         (let $running
           (codex:exec-server-local-process-entry-running-process
             $entry)
           (let $seq
             (codex:exec-server-local-running-process-next-seq $running)
             (let $output
               (codex:exec-server-process-output-chunk
                 $seq
                 $stream
                 $chunk)
               (let $trimmed
                 (codex:exec-server-local-output-retain-trim
                   (list:append
                     (codex:exec-server-local-running-process-output
                       $running)
                     ($output))
                   (+
                     (codex:exec-server-local-running-process-retained-bytes
                       $running)
                     (codex:exec-server-local-byte-chunk-len $chunk))
                   $byte-capacity)
                 (let $events
                   (codex:exec-process-event-log-publish
                     (codex:exec-server-local-running-process-events
                       $running)
                     (codex:exec-server-local-output-event $output))
                   (let $updated-running
                     (codex:exec-server-local-running-process-with-output-state
                       $running
                       (codex:exec-server-local-output-retain-result-output
                         $trimmed)
                       (codex:exec-server-local-output-retain-result-retained-bytes
                         $trimmed)
                       (+ $seq 1)
                       $seq
                       $events)
                     (codex:exec-server-local-result-ok
                       (codex:exec-server-local-output-recorded
                         (codex:exec-server-output-delta-notification
                           $process-id
                           $seq
                           $stream
                           $chunk)
                         $seq)
                       (codex:exec-server-local-process-with-entry
                         $local-process
                         $process-id
                         (codex:exec-server-local-process-entry-running
                           $updated-running)))))))))
         (codex:exec-server-local-result-ok
           (codex:exec-server-local-output-ignored)
           $local-process))))

(= (codex:exec-server-local-record-output
      $local-process
      $process-id
      $stream
      $chunk)
   (codex:exec-server-local-record-output-with-capacity
     $local-process
     $process-id
     $stream
     $chunk
     (codex:exec-server-local-retained-output-bytes-per-process)))

(= (codex:exec-server-local-max-would-exceed
      $total-bytes
      $chunk-len
      CodexAbsent)
   False)

(= (codex:exec-server-local-max-would-exceed
      $total-bytes
      $chunk-len
      $max-bytes)
   (> (+ $total-bytes $chunk-len) $max-bytes))

(= (codex:exec-server-local-total-at-least-max
      $total-bytes
      CodexAbsent)
   False)

(= (codex:exec-server-local-total-at-least-max
      $total-bytes
      $max-bytes)
   (>= $total-bytes $max-bytes))

(= (codex:exec-server-local-read-collect
      $output
      $after-seq
      $max-bytes
      $chunks
      $total-bytes
      $next-seq)
   (if (== $output ())
       (CodexExecServerLocalReadCollectResult
         $chunks
         $total-bytes
         $next-seq)
       (let $head (list:first $output)
         (let $tail (list:rest $output)
           (if (<= (codex:exec-server-process-output-chunk-seq $head)
                   $after-seq)
               (codex:exec-server-local-read-collect
                 $tail
                 $after-seq
                 $max-bytes
                 $chunks
                 $total-bytes
                 $next-seq)
               (let $chunk-len
                 (codex:exec-server-local-output-chunk-retained-len $head)
                 (if (and
                       (not (== $chunks ()))
                       (codex:exec-server-local-max-would-exceed
                         $total-bytes
                         $chunk-len
                         $max-bytes))
                     (CodexExecServerLocalReadCollectResult
                       $chunks
                       $total-bytes
                       $next-seq)
                     (let $new-total (+ $total-bytes $chunk-len)
                       (let $new-next-seq
                         (+
                           (codex:exec-server-process-output-chunk-seq
                             $head)
                           1)
                         (let $new-chunks
                           (list:append $chunks ($head))
                           (if (codex:exec-server-local-total-at-least-max
                                 $new-total
                                 $max-bytes)
                               (CodexExecServerLocalReadCollectResult
                                 $new-chunks
                                 $new-total
                                 $new-next-seq)
                               (codex:exec-server-local-read-collect
                                 $tail
                                 $after-seq
                                 $max-bytes
                                 $new-chunks
                                 $new-total
                                 $new-next-seq))))))))))))

(= (codex:exec-server-local-read-collect-result-chunks
      (CodexExecServerLocalReadCollectResult
        $chunks
        $total-bytes
        $next-seq))
   $chunks)

(= (codex:exec-server-local-read-collect-result-next-seq
      (CodexExecServerLocalReadCollectResult
        $chunks
        $total-bytes
        $next-seq))
   $next-seq)

(= (codex:exec-server-local-is-present $value)
   (not (== $value CodexAbsent)))

(= (codex:exec-server-local-read-ready $response)
   (CodexExecServerLocalReadReady $response))

(= (codex:exec-server-local-read-pending $response)
   (CodexExecServerLocalReadPending $response))

(= (codex:exec-server-local-read-outcome-response
      (CodexExecServerLocalReadReady $response))
   $response)

(= (codex:exec-server-local-read-outcome-response
      (CodexExecServerLocalReadPending $response))
   $response)

(= (codex:exec-server-local-read-outcome-kind
      (CodexExecServerLocalReadReady $response))
   ready)

(= (codex:exec-server-local-read-outcome-kind
      (CodexExecServerLocalReadPending $response))
   pending)

(= (codex:exec-server-local-read-default-after-seq $after-seq)
   (if (== $after-seq CodexAbsent) 0 $after-seq))

(= (codex:exec-server-local-read-default-max-bytes $max-bytes)
   (if (== $max-bytes CodexAbsent) CodexAbsent $max-bytes))

(= (codex:exec-server-local-read-should-return
      $chunks
      $closed
      $exited
      $after-seq
      $next-seq
      $deadline-reached)
   (let $has-new-terminal-event
     (and
       $exited
       (< $after-seq
          (codex:exec-server-local-saturating-sub $next-seq 1)))
     (or
       (not (== $chunks ()))
       (or $closed
           (or $has-new-terminal-event $deadline-reached)))))

(= (codex:exec-server-local-exec-read-step
      $local-process
      (CodexExecServerReadParams
        $process-id
        $after-seq-option
        $max-bytes-option
        $wait-ms)
      $deadline-reached)
   (let $entry
     (codex:exec-server-local-process-entry
       $local-process
       $process-id)
     (case $entry
       ((CodexAbsent
         (codex:exec-server-local-result-err
           (codex:exec-server-local-error-invalid-request
             (codex:exec-server-local-unknown-process-message
               $process-id))
           $local-process))
        ((CodexExecServerLocalProcessEntryStarting)
         (codex:exec-server-local-result-err
           (codex:exec-server-local-error-invalid-request
             (codex:exec-server-local-starting-process-message
               $process-id))
           $local-process))
        ((CodexExecServerLocalProcessEntryRunning $running)
         (let $after-seq
           (codex:exec-server-local-read-default-after-seq
             $after-seq-option)
           (let $collected
             (codex:exec-server-local-read-collect
               (codex:exec-server-local-running-process-output $running)
               $after-seq
               (codex:exec-server-local-read-default-max-bytes
                 $max-bytes-option)
               ()
               0
               (codex:exec-server-local-running-process-next-seq
                 $running))
             (let $chunks
               (codex:exec-server-local-read-collect-result-chunks
                 $collected)
               (let $next-seq
                 (codex:exec-server-local-read-collect-result-next-seq
                   $collected)
                 (let $exit-code
                   (codex:exec-server-local-running-process-exit-code
                     $running)
                   (let $response
                     (codex:exec-server-read-response
                       $chunks
                       $next-seq
                       (codex:exec-server-local-is-present $exit-code)
                       $exit-code
                       (codex:exec-server-local-running-process-closed
                         $running)
                       CodexAbsent)
                     (codex:exec-server-local-result-ok
                       (if (codex:exec-server-local-read-should-return
                             $chunks
                             (codex:exec-server-local-running-process-closed
                               $running)
                             (codex:exec-server-local-is-present
                               $exit-code)
                             $after-seq
                             $next-seq
                             $deadline-reached)
                           (codex:exec-server-local-read-ready $response)
                           (codex:exec-server-local-read-pending
                             $response))
                       $local-process))))))))))))

(= (codex:exec-server-local-exec-write
      $local-process
      (CodexExecServerWriteParams $process-id $chunk)
      $stdin-send-ok)
   (let $entry
     (codex:exec-server-local-process-entry
       $local-process
       $process-id)
     (case $entry
       ((CodexAbsent
         (codex:exec-server-local-result-ok
           (codex:exec-server-write-response
             (codex:exec-server-write-status-unknown-process))
           $local-process))
        ((CodexExecServerLocalProcessEntryStarting)
         (codex:exec-server-local-result-ok
           (codex:exec-server-write-response
             (codex:exec-server-write-status-starting))
           $local-process))
        ((CodexExecServerLocalProcessEntryRunning $running)
         (if (not
               (codex:exec-server-local-running-process-can-write-stdin
                 $running))
             (codex:exec-server-local-result-ok
               (codex:exec-server-write-response
                 (codex:exec-server-write-status-stdin-closed))
               $local-process)
             (if $stdin-send-ok
                 (codex:exec-server-local-result-ok
                   (codex:exec-server-write-response
                     (codex:exec-server-write-status-accepted))
                   $local-process)
                 (codex:exec-server-local-result-err
                   (codex:exec-server-local-error-internal
                     "failed to write to process stdin")
                   $local-process))))))))

(= (codex:exec-server-local-terminate-request $process-id)
   (CodexExecServerLocalTerminateRequest $process-id))

(= (codex:exec-server-local-terminate-outcome
      $response
      $terminate-request)
   (CodexExecServerLocalTerminateOutcome
     $response
     $terminate-request))

(= (codex:exec-server-local-terminate-outcome-response
      (CodexExecServerLocalTerminateOutcome
        $response
        $terminate-request))
   $response)

(= (codex:exec-server-local-terminate-outcome-request
      (CodexExecServerLocalTerminateOutcome
        $response
        $terminate-request))
   $terminate-request)

(= (codex:exec-server-local-terminate-process
      $local-process
      (CodexExecServerTerminateParams $process-id))
   (let $entry
     (codex:exec-server-local-process-entry
       $local-process
       $process-id)
     (case $entry
       ((CodexAbsent
         (codex:exec-server-local-result-ok
           (codex:exec-server-local-terminate-outcome
             (codex:exec-server-terminate-response False)
             CodexAbsent)
           $local-process))
        ((CodexExecServerLocalProcessEntryStarting)
         (codex:exec-server-local-result-ok
           (codex:exec-server-local-terminate-outcome
             (codex:exec-server-terminate-response False)
             CodexAbsent)
           $local-process))
        ((CodexExecServerLocalProcessEntryRunning $running)
         (if (codex:exec-server-local-is-present
               (codex:exec-server-local-running-process-exit-code
                 $running))
             (codex:exec-server-local-result-ok
               (codex:exec-server-local-terminate-outcome
                 (codex:exec-server-terminate-response False)
                 CodexAbsent)
               $local-process)
             (codex:exec-server-local-result-ok
               (codex:exec-server-local-terminate-outcome
                 (codex:exec-server-terminate-response True)
                 (codex:exec-server-local-terminate-request
                   $process-id))
               $local-process)))))))

(= (codex:exec-server-local-closed-cleanup-request
      $process-id
      $retention-ms)
   (CodexExecServerLocalClosedCleanupRequest
     $process-id
     $retention-ms))

(= (codex:exec-server-local-maybe-closed-result
      $notification
      $cleanup-request
      $wake-seq)
   (CodexExecServerLocalMaybeClosedResult
     $notification
     $cleanup-request
     $wake-seq))

(= (codex:exec-server-local-maybe-closed-result-notification
      (CodexExecServerLocalMaybeClosedResult
        $notification
        $cleanup-request
        $wake-seq))
   $notification)

(= (codex:exec-server-local-maybe-closed-result-cleanup-request
      (CodexExecServerLocalMaybeClosedResult
        $notification
        $cleanup-request
        $wake-seq))
   $cleanup-request)

(= (codex:exec-server-local-maybe-emit-closed $local-process $process-id)
   (let $entry
     (codex:exec-server-local-process-entry
       $local-process
       $process-id)
     (case $entry
       (((CodexExecServerLocalProcessEntryRunning $running)
         (if (or
               (codex:exec-server-local-running-process-closed $running)
               (or
                 (not
                   (== (codex:exec-server-local-running-process-open-streams
                         $running)
                       0))
                 (not
                   (codex:exec-server-local-is-present
                     (codex:exec-server-local-running-process-exit-code
                       $running)))))
             (codex:exec-server-local-result-ok
               (codex:exec-server-local-maybe-closed-result
                 CodexAbsent
                 CodexAbsent
                 CodexAbsent)
               $local-process)
             (let $seq
               (codex:exec-server-local-running-process-next-seq $running)
               (let $events
                 (codex:exec-process-event-log-publish
                   (codex:exec-server-local-running-process-events $running)
                   (codex:exec-process-event-closed $seq))
                 (let $updated-running
                   (codex:exec-server-local-running-process-with-closed
                     $running
                     (+ $seq 1)
                     $seq
                     $events)
                   (codex:exec-server-local-result-ok
                     (codex:exec-server-local-maybe-closed-result
                       (codex:exec-server-closed-notification
                         $process-id
                         $seq)
                       (codex:exec-server-local-closed-cleanup-request
                         $process-id
                         (codex:exec-server-local-exited-process-retention-ms))
                       $seq)
                     (codex:exec-server-local-process-with-entry
                       $local-process
                       $process-id
                       (codex:exec-server-local-process-entry-running
                         $updated-running))))))))
        ($other
         (codex:exec-server-local-result-ok
           (codex:exec-server-local-maybe-closed-result
             CodexAbsent
             CodexAbsent
             CodexAbsent)
           $local-process))))))

(= (codex:exec-server-local-exit-recorded
      $exit-notification
      $closed-notification
      $cleanup-request)
   (CodexExecServerLocalExitRecorded
     $exit-notification
     $closed-notification
     $cleanup-request))

(= (codex:exec-server-local-exit-recorded-closed-notification
      (CodexExecServerLocalExitRecorded
        $exit-notification
        $closed-notification
        $cleanup-request))
   $closed-notification)

(= (codex:exec-server-local-exit-ignored)
   (CodexExecServerLocalExitIgnored))

(= (codex:exec-server-local-record-exit
      $local-process
      $process-id
      $exit-code)
   (let $entry
     (codex:exec-server-local-process-entry
       $local-process
       $process-id)
     (case $entry
       (((CodexExecServerLocalProcessEntryRunning $running)
         (let $seq
           (codex:exec-server-local-running-process-next-seq $running)
           (let $events
             (codex:exec-process-event-log-publish
               (codex:exec-server-local-running-process-events $running)
               (codex:exec-process-event-exited $seq $exit-code))
             (let $updated-running
               (codex:exec-server-local-running-process-with-exit
                 $running
                 (+ $seq 1)
                 $exit-code
                 $seq
                 $events)
               (let $after-exit
                 (codex:exec-server-local-process-with-entry
                   $local-process
                   $process-id
                   (codex:exec-server-local-process-entry-running
                     $updated-running))
                 (let $closed-result
                   (codex:exec-server-local-maybe-emit-closed
                     $after-exit
                     $process-id)
                   (let $closed-value
                     (codex:exec-server-local-result-value
                       $closed-result)
                     (codex:exec-server-local-result-ok
                       (codex:exec-server-local-exit-recorded
                         (codex:exec-server-exited-notification
                           $process-id
                           $seq
                           $exit-code)
                         (codex:exec-server-local-maybe-closed-result-notification
                           $closed-value)
                         (codex:exec-server-local-maybe-closed-result-cleanup-request
                           $closed-value))
                       (codex:exec-server-local-result-process
                         $closed-result)))))))))
        ($other
         (codex:exec-server-local-result-ok
           (codex:exec-server-local-exit-ignored)
           $local-process))))))

(= (codex:exec-server-local-finish-output-stream
      $local-process
      $process-id)
   (let $entry
     (codex:exec-server-local-process-entry
       $local-process
       $process-id)
     (case $entry
       (((CodexExecServerLocalProcessEntryRunning $running)
         (let $open-streams
           (codex:exec-server-local-running-process-open-streams
             $running)
           (let $updated-running
             (codex:exec-server-local-running-process-with-open-streams
               $running
               (if (> $open-streams 0)
                   (- $open-streams 1)
                   $open-streams))
             (codex:exec-server-local-maybe-emit-closed
               (codex:exec-server-local-process-with-entry
                 $local-process
                 $process-id
                 (codex:exec-server-local-process-entry-running
                   $updated-running))
               $process-id))))
        ($other
         (codex:exec-server-local-result-ok
           (codex:exec-server-local-maybe-closed-result
             CodexAbsent
             CodexAbsent
             CodexAbsent)
           $local-process))))))

(= (codex:exec-server-local-shutdown-session-request $process-id)
   (CodexExecServerLocalShutdownSessionRequest $process-id))

(= (codex:exec-server-local-shutdown-result
      $local-process
      $terminate-requests)
   (CodexExecServerLocalShutdownResult
     $local-process
     $terminate-requests))

(= (codex:exec-server-local-shutdown-result-terminate-requests
      (CodexExecServerLocalShutdownResult
        $local-process
        $terminate-requests))
   $terminate-requests)

(= (codex:exec-server-local-shutdown-requests-from-records $records)
   (if (== $records ())
       ()
       (let $head (list:first $records)
         (let $tail (list:rest $records)
           (let $entry
             (codex:exec-server-local-process-record-entry $head)
             (case $entry
               (((CodexExecServerLocalProcessEntryRunning $running)
                 (let $rest
                   (eval
                     (codex:exec-server-local-shutdown-requests-from-records
                       $tail))
                   (cons-atom
                     (codex:exec-server-local-shutdown-session-request
                       (codex:exec-server-local-process-record-process-id
                         $head))
                     $rest)))
                ($other
                 (codex:exec-server-local-shutdown-requests-from-records
                   $tail)))))))))

(= (codex:exec-server-local-shutdown
      (CodexExecServerLocalProcess $notifications $processes))
   (codex:exec-server-local-shutdown-result
     (CodexExecServerLocalProcess $notifications ())
     (codex:exec-server-local-shutdown-requests-from-records
       $processes)))
