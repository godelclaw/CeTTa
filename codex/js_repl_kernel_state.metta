; Rust-faithful js_repl start_kernel runtime state and task wiring slice.
;
; This ports the deterministic state construction from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - `JsReplManager::start_kernel` after child stdio extraction:
;     `CancellationToken`, pending exec/context maps, stdin/child/recent
;     stderr `Arc<Mutex<_>>` cells, stdout/stderr reader task spawning, and
;     the returned `KernelState`.
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust constructs concrete `Arc<Mutex<_>>`, `HashMap`, `VecDeque`, and
;   `CancellationToken` values, then spawns Tokio tasks. This pure slice uses
;   symbolic values for those runtime resources while preserving the exact
;   initialization order, shared references, field wiring, and warning branch.
; - Rust creates a fresh cancellation token inside `start_kernel`. This pure
;   boundary receives the observed token value so surface tests can pin clone
;   sharing without inventing a global token allocator in CeTTa.

!(import! &self js_repl)
!(import! &self js_repl_kernel_spawn)

(= (codex:js-repl-arc-mutex $value)
   (CodexJsReplArcMutex $value))

(= (codex:js-repl-arc-mutex-value (CodexJsReplArcMutex $value))
   $value)

(= (codex:js-repl-arc-clone $arc)
   $arc)

(= (codex:js-repl-pending-execs $entries)
   (CodexJsReplPendingExecs $entries))

(= (codex:js-repl-pending-execs-entries
      (CodexJsReplPendingExecs $entries))
   $entries)

(= (codex:js-repl-empty-pending-execs)
   (codex:js-repl-pending-execs ()))

(= (codex:js-repl-exec-contexts $entries)
   (CodexJsReplExecContexts $entries))

(= (codex:js-repl-exec-contexts-entries
      (CodexJsReplExecContexts $entries))
   $entries)

(= (codex:js-repl-empty-exec-contexts)
   (codex:js-repl-exec-contexts ()))

(= (codex:js-repl-recent-stderr-buffer $capacity $lines)
   (CodexJsReplRecentStderrBuffer $capacity $lines))

(= (codex:js-repl-recent-stderr-buffer-capacity
      (CodexJsReplRecentStderrBuffer $capacity $lines))
   $capacity)

(= (codex:js-repl-recent-stderr-buffer-lines
      (CodexJsReplRecentStderrBuffer $capacity $lines))
   $lines)

(= (codex:js-repl-new-recent-stderr-buffer)
   (codex:js-repl-recent-stderr-buffer
     (codex:js-repl-stderr-tail-line-limit)
     ()))

(= (codex:js-repl-read-stdout-task
      $stdout
      $child
      $kernel-cell
      $recent-stderr
      $pending-execs
      $exec-contexts
      $exec-tool-calls
      $stdin
      $shutdown)
   (CodexJsReplReadStdoutTask
     $stdout
     $child
     $kernel-cell
     $recent-stderr
     $pending-execs
     $exec-contexts
     $exec-tool-calls
     $stdin
     $shutdown))

(= (codex:js-repl-read-stdout-task-stdout
      (CodexJsReplReadStdoutTask
        $stdout $child $kernel-cell $recent-stderr $pending-execs
        $exec-contexts $exec-tool-calls $stdin $shutdown))
   $stdout)

(= (codex:js-repl-read-stdout-task-child
      (CodexJsReplReadStdoutTask
        $stdout $child $kernel-cell $recent-stderr $pending-execs
        $exec-contexts $exec-tool-calls $stdin $shutdown))
   $child)

(= (codex:js-repl-read-stdout-task-kernel-cell
      (CodexJsReplReadStdoutTask
        $stdout $child $kernel-cell $recent-stderr $pending-execs
        $exec-contexts $exec-tool-calls $stdin $shutdown))
   $kernel-cell)

(= (codex:js-repl-read-stdout-task-recent-stderr
      (CodexJsReplReadStdoutTask
        $stdout $child $kernel-cell $recent-stderr $pending-execs
        $exec-contexts $exec-tool-calls $stdin $shutdown))
   $recent-stderr)

(= (codex:js-repl-read-stdout-task-pending-execs
      (CodexJsReplReadStdoutTask
        $stdout $child $kernel-cell $recent-stderr $pending-execs
        $exec-contexts $exec-tool-calls $stdin $shutdown))
   $pending-execs)

(= (codex:js-repl-read-stdout-task-exec-contexts
      (CodexJsReplReadStdoutTask
        $stdout $child $kernel-cell $recent-stderr $pending-execs
        $exec-contexts $exec-tool-calls $stdin $shutdown))
   $exec-contexts)

(= (codex:js-repl-read-stdout-task-exec-tool-calls
      (CodexJsReplReadStdoutTask
        $stdout $child $kernel-cell $recent-stderr $pending-execs
        $exec-contexts $exec-tool-calls $stdin $shutdown))
   $exec-tool-calls)

(= (codex:js-repl-read-stdout-task-stdin
      (CodexJsReplReadStdoutTask
        $stdout $child $kernel-cell $recent-stderr $pending-execs
        $exec-contexts $exec-tool-calls $stdin $shutdown))
   $stdin)

(= (codex:js-repl-read-stdout-task-shutdown
      (CodexJsReplReadStdoutTask
        $stdout $child $kernel-cell $recent-stderr $pending-execs
        $exec-contexts $exec-tool-calls $stdin $shutdown))
   $shutdown)

(= (codex:js-repl-read-stderr-task
      $stderr
      $recent-stderr
      $shutdown)
   (CodexJsReplReadStderrTask $stderr $recent-stderr $shutdown))

(= (codex:js-repl-read-stderr-task-stderr
      (CodexJsReplReadStderrTask $stderr $recent-stderr $shutdown))
   $stderr)

(= (codex:js-repl-read-stderr-task-recent-stderr
      (CodexJsReplReadStderrTask $stderr $recent-stderr $shutdown))
   $recent-stderr)

(= (codex:js-repl-read-stderr-task-shutdown
      (CodexJsReplReadStderrTask $stderr $recent-stderr $shutdown))
   $shutdown)

(= (codex:js-repl-kernel-state
      $child
      $recent-stderr
      $stdin
      $pending-execs
      $exec-contexts
      $top-level-exec-state
      $shutdown)
   (CodexJsReplKernelState
     $child
     $recent-stderr
     $stdin
     $pending-execs
     $exec-contexts
     $top-level-exec-state
     $shutdown))

(= (codex:js-repl-kernel-state-child
      (CodexJsReplKernelState
        $child $recent-stderr $stdin $pending-execs $exec-contexts
        $top-level-exec-state $shutdown))
   $child)

(= (codex:js-repl-kernel-state-recent-stderr
      (CodexJsReplKernelState
        $child $recent-stderr $stdin $pending-execs $exec-contexts
        $top-level-exec-state $shutdown))
   $recent-stderr)

(= (codex:js-repl-kernel-state-stdin
      (CodexJsReplKernelState
        $child $recent-stderr $stdin $pending-execs $exec-contexts
        $top-level-exec-state $shutdown))
   $stdin)

(= (codex:js-repl-kernel-state-pending-execs
      (CodexJsReplKernelState
        $child $recent-stderr $stdin $pending-execs $exec-contexts
        $top-level-exec-state $shutdown))
   $pending-execs)

(= (codex:js-repl-kernel-state-exec-contexts
      (CodexJsReplKernelState
        $child $recent-stderr $stdin $pending-execs $exec-contexts
        $top-level-exec-state $shutdown))
   $exec-contexts)

(= (codex:js-repl-kernel-state-top-level-exec-state
      (CodexJsReplKernelState
        $child $recent-stderr $stdin $pending-execs $exec-contexts
        $top-level-exec-state $shutdown))
   $top-level-exec-state)

(= (codex:js-repl-kernel-state-shutdown
      (CodexJsReplKernelState
        $child $recent-stderr $stdin $pending-execs $exec-contexts
        $top-level-exec-state $shutdown))
   $shutdown)

(= (codex:js-repl-kernel-runtime-plan
      $kernel-state
      $stdout-task
      $stderr-task
      $warnings)
   (CodexJsReplKernelRuntimePlan
     $kernel-state
     $stdout-task
     $stderr-task
     $warnings))

(= (codex:js-repl-kernel-runtime-plan-state
      (CodexJsReplKernelRuntimePlan
        $kernel-state $stdout-task $stderr-task $warnings))
   $kernel-state)

(= (codex:js-repl-kernel-runtime-plan-stdout-task
      (CodexJsReplKernelRuntimePlan
        $kernel-state $stdout-task $stderr-task $warnings))
   $stdout-task)

(= (codex:js-repl-kernel-runtime-plan-stderr-task
      (CodexJsReplKernelRuntimePlan
        $kernel-state $stdout-task $stderr-task $warnings))
   $stderr-task)

(= (codex:js-repl-kernel-runtime-plan-warnings
      (CodexJsReplKernelRuntimePlan
        $kernel-state $stdout-task $stderr-task $warnings))
   $warnings)

(= (codex:js-repl-start-kernel-runtime-stderr-task
      $stderr
      $recent-stderr
      $shutdown)
   (if (== $stderr CodexAbsent)
       CodexAbsent
       (codex:js-repl-read-stderr-task
         $stderr
         (codex:js-repl-arc-clone $recent-stderr)
         $shutdown)))

(= (codex:js-repl-start-kernel-runtime-warnings $warning)
   (if (== $warning CodexAbsent)
       ()
       ($warning)))

(= (codex:js-repl-start-kernel-runtime-plan
      $spawned-kernel
      $kernel-cell
      $exec-tool-calls
      $shutdown)
   (let $pending-execs
     (codex:js-repl-arc-mutex
       (codex:js-repl-empty-pending-execs))
     (let $exec-contexts
       (codex:js-repl-arc-mutex
         (codex:js-repl-empty-exec-contexts))
       (let $stdin
         (codex:js-repl-arc-mutex
           (codex:js-repl-spawned-kernel-stdin $spawned-kernel))
         (let $child
           (codex:js-repl-arc-mutex
             (codex:js-repl-spawned-kernel-child $spawned-kernel))
           (let $recent-stderr
             (codex:js-repl-arc-mutex
               (codex:js-repl-new-recent-stderr-buffer))
             (codex:js-repl-kernel-runtime-plan
               (codex:js-repl-kernel-state
                 $child
                 $recent-stderr
                 $stdin
                 $pending-execs
                 $exec-contexts
                 (codex:js-repl-top-level-exec-state-idle)
                 $shutdown)
               (codex:js-repl-read-stdout-task
                 (codex:js-repl-spawned-kernel-stdout $spawned-kernel)
                 (codex:js-repl-arc-clone $child)
                 (codex:js-repl-arc-clone $kernel-cell)
                 (codex:js-repl-arc-clone $recent-stderr)
                 (codex:js-repl-arc-clone $pending-execs)
                 (codex:js-repl-arc-clone $exec-contexts)
                 (codex:js-repl-arc-clone $exec-tool-calls)
                 (codex:js-repl-arc-clone $stdin)
                 $shutdown)
               (codex:js-repl-start-kernel-runtime-stderr-task
                 (codex:js-repl-spawned-kernel-stderr $spawned-kernel)
                 $recent-stderr
                 $shutdown)
               (codex:js-repl-start-kernel-runtime-warnings
                 (codex:js-repl-spawned-kernel-stderr-warning
                   $spawned-kernel)))))))))
