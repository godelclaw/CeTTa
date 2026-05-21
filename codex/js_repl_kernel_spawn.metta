; Rust-faithful js_repl start_kernel spawn planning slice.
;
; This ports deterministic command setup and observed spawn/stdio error mapping
; from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - `JsReplManager::start_kernel` after sandbox transform:
;     `tokio::process::Command` construction, Unix `arg0`, cwd/env/stdin/
;     stdout/stderr/kill_on_drop setup, spawn error mapping, and required
;     stdout/stdin extraction.
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust owns `tokio::process::Command`, `Child`, and stdio handles. This pure
;   slice uses symbolic child/handle values and observed spawn outcomes while
;   preserving the same setup data, branch order, and error strings.
; - Rust gates `cmd.arg0(...)` with `#[cfg(unix)]`. The shared CeTTa port uses
;   explicit host-platform values, so this slice applies Unix arg0 behavior for
;   linux/macos and omits arg0 otherwise.

!(import! &self js_repl_kernel_sandbox)
!(import! &self list)
!(import! &self sandbox_tags)
!(import! &self str)

(= (codex:js-repl-exec-env $command $cwd $env $arg0)
   (CodexJsReplExecEnv $command $cwd $env $arg0))

(= (codex:js-repl-exec-env-command
      (CodexJsReplExecEnv $command $cwd $env $arg0))
   $command)

(= (codex:js-repl-exec-env-cwd
      (CodexJsReplExecEnv $command $cwd $env $arg0))
   $cwd)

(= (codex:js-repl-exec-env-env
      (CodexJsReplExecEnv $command $cwd $env $arg0))
   $env)

(= (codex:js-repl-exec-env-arg0
      (CodexJsReplExecEnv $command $cwd $env $arg0))
   $arg0)

(= (codex:js-repl-command-first-or-default $command)
   (case $command
     ((() "")
      ($items (list:first $items)))))

(= (codex:js-repl-command-args-after-program $command)
   (case $command
     ((() ())
      ($items
       (if (> (list:len $items) 1)
           (list:rest $items)
           ())))))

(= (codex:js-repl-host-platform-is-unix $host-platform)
   (or
     (== $host-platform (codex:host-platform-linux))
     (== $host-platform (codex:host-platform-macos))))

(= (codex:js-repl-spawn-arg0-for-platform $host-platform $exec-env)
   (if (codex:js-repl-host-platform-is-unix $host-platform)
       (let $arg0 (codex:js-repl-exec-env-arg0 $exec-env)
         (if (== $arg0 CodexAbsent)
             (codex:js-repl-command-first-or-default
               (codex:js-repl-exec-env-command $exec-env))
             $arg0))
       CodexAbsent))

(= (codex:js-repl-stdio-piped)
   (CodexJsReplStdioPiped))

(= (codex:js-repl-tokio-command-plan
      $program
      $args
      $arg0
      $cwd
      $env
      $env-clear
      $stdin
      $stdout
      $stderr
      $kill-on-drop)
   (CodexJsReplTokioCommandPlan
     $program
     $args
     $arg0
     $cwd
     $env
     $env-clear
     $stdin
     $stdout
     $stderr
     $kill-on-drop))

(= (codex:js-repl-tokio-command-plan-program
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $program)

(= (codex:js-repl-tokio-command-plan-args
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $args)

(= (codex:js-repl-tokio-command-plan-arg0
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $arg0)

(= (codex:js-repl-tokio-command-plan-cwd
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $cwd)

(= (codex:js-repl-tokio-command-plan-env
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $env)

(= (codex:js-repl-tokio-command-plan-env-clear
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $env-clear)

(= (codex:js-repl-tokio-command-plan-stdin
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $stdin)

(= (codex:js-repl-tokio-command-plan-stdout
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $stdout)

(= (codex:js-repl-tokio-command-plan-stderr
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $stderr)

(= (codex:js-repl-tokio-command-plan-kill-on-drop
      (CodexJsReplTokioCommandPlan
        $program $args $arg0 $cwd $env $env-clear
        $stdin $stdout $stderr $kill-on-drop))
   $kill-on-drop)

(= (codex:js-repl-tokio-command-plan-from-exec-env
      $exec-env
      $host-platform)
   (let $command (codex:js-repl-exec-env-command $exec-env)
     (codex:js-repl-tokio-command-plan
       (codex:js-repl-command-first-or-default $command)
       (codex:js-repl-command-args-after-program $command)
       (codex:js-repl-spawn-arg0-for-platform
         $host-platform
         $exec-env)
       (codex:js-repl-exec-env-cwd $exec-env)
       (codex:js-repl-exec-env-env $exec-env)
       True
       (codex:js-repl-stdio-piped)
       (codex:js-repl-stdio-piped)
       (codex:js-repl-stdio-piped)
       True)))

(= (codex:js-repl-child-spawn-ok $child $stdout $stderr $stdin)
   (CodexJsReplChildSpawnOk $child $stdout $stderr $stdin))

(= (codex:js-repl-child-spawn-error $message)
   (CodexJsReplChildSpawnError $message))

(= (codex:js-repl-spawned-kernel $child $stdout $stderr $stdin $stderr-warning)
   (CodexJsReplSpawnedKernel
     $child $stdout $stderr $stdin $stderr-warning))

(= (codex:js-repl-spawned-kernel-child
      (CodexJsReplSpawnedKernel
        $child $stdout $stderr $stdin $stderr-warning))
   $child)

(= (codex:js-repl-spawned-kernel-stdout
      (CodexJsReplSpawnedKernel
        $child $stdout $stderr $stdin $stderr-warning))
   $stdout)

(= (codex:js-repl-spawned-kernel-stderr
      (CodexJsReplSpawnedKernel
        $child $stdout $stderr $stdin $stderr-warning))
   $stderr)

(= (codex:js-repl-spawned-kernel-stdin
      (CodexJsReplSpawnedKernel
        $child $stdout $stderr $stdin $stderr-warning))
   $stdin)

(= (codex:js-repl-spawned-kernel-stderr-warning
      (CodexJsReplSpawnedKernel
        $child $stdout $stderr $stdin $stderr-warning))
   $stderr-warning)

(= (codex:js-repl-start-kernel-spawn-ok $kernel)
   (CodexJsReplStartKernelSpawnOk $kernel))

(= (codex:js-repl-start-kernel-spawn-error $message)
   (CodexJsReplStartKernelSpawnError $message))

(= (codex:js-repl-start-kernel-spawn-result-value
      (CodexJsReplStartKernelSpawnOk $kernel))
   $kernel)

(= (codex:js-repl-start-kernel-spawn-result-error-message
      (CodexJsReplStartKernelSpawnError $message))
   $message)

(= (codex:js-repl-start-kernel-spawn-error-message $message)
   (str-concat "failed to start Node runtime: " $message))

(= (codex:js-repl-kernel-missing-stdout-message)
   "js_repl kernel missing stdout")

(= (codex:js-repl-kernel-missing-stdin-message)
   "js_repl kernel missing stdin")

(= (codex:js-repl-kernel-missing-stderr-warning)
   "js_repl kernel missing stderr")

(= (codex:js-repl-start-kernel-handle-spawn $observation)
   (case $observation
     (((CodexJsReplChildSpawnError $message)
       (codex:js-repl-start-kernel-spawn-error
         (codex:js-repl-start-kernel-spawn-error-message
           $message)))
      ((CodexJsReplChildSpawnOk $child $stdout $stderr $stdin)
       (if (== $stdout CodexAbsent)
           (codex:js-repl-start-kernel-spawn-error
             (codex:js-repl-kernel-missing-stdout-message))
           (if (== $stdin CodexAbsent)
               (codex:js-repl-start-kernel-spawn-error
                 (codex:js-repl-kernel-missing-stdin-message))
               (if (== $stderr CodexAbsent)
                   (codex:js-repl-start-kernel-spawn-ok
                     (codex:js-repl-spawned-kernel
                       $child
                       $stdout
                       CodexAbsent
                       $stdin
                       (codex:js-repl-kernel-missing-stderr-warning)))
                   (codex:js-repl-start-kernel-spawn-ok
                     (codex:js-repl-spawned-kernel
                       $child
                       $stdout
                       $stderr
                       $stdin
                       CodexAbsent)))))))))
