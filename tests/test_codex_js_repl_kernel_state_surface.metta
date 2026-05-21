!(register-module! ../codex)
!(import! &self codex:js_repl)
!(import! &self codex:js_repl_kernel_spawn)
!(import! &self codex:js_repl_kernel_state)

(= (test:js-repl-spawned-with-stderr)
   (codex:js-repl-start-kernel-spawn-result-value
     (codex:js-repl-start-kernel-handle-spawn
       (codex:js-repl-child-spawn-ok
         child-1
         stdout-1
         stderr-1
         stdin-1))))

(= (test:js-repl-runtime-plan-with-stderr)
   (codex:js-repl-start-kernel-runtime-plan
     (test:js-repl-spawned-with-stderr)
     kernel-cell-1
     exec-tool-calls-1
     shutdown-1))

(= (test:js-repl-runtime-state-with-stderr)
   (codex:js-repl-kernel-runtime-plan-state
     (test:js-repl-runtime-plan-with-stderr)))

(= (test:js-repl-runtime-stdout-task-with-stderr)
   (codex:js-repl-kernel-runtime-plan-stdout-task
     (test:js-repl-runtime-plan-with-stderr)))

(= (test:js-repl-runtime-stderr-task-with-stderr)
   (codex:js-repl-kernel-runtime-plan-stderr-task
     (test:js-repl-runtime-plan-with-stderr)))

(= (test:js-repl-spawned-without-stderr)
   (codex:js-repl-start-kernel-spawn-result-value
     (codex:js-repl-start-kernel-handle-spawn
       (codex:js-repl-child-spawn-ok
         child-2
         stdout-2
         CodexAbsent
         stdin-2))))

(= (test:js-repl-runtime-plan-without-stderr)
   (codex:js-repl-start-kernel-runtime-plan
     (test:js-repl-spawned-without-stderr)
     kernel-cell-2
     exec-tool-calls-2
     shutdown-2))

!(assertEqual
  (codex:js-repl-arc-mutex-value
    (codex:js-repl-kernel-state-child
      (test:js-repl-runtime-state-with-stderr)))
  child-1)

!(assertEqual
  (codex:js-repl-arc-mutex-value
    (codex:js-repl-kernel-state-stdin
      (test:js-repl-runtime-state-with-stderr)))
  stdin-1)

!(assertEqual
  (codex:js-repl-recent-stderr-buffer-capacity
    (codex:js-repl-arc-mutex-value
      (codex:js-repl-kernel-state-recent-stderr
        (test:js-repl-runtime-state-with-stderr))))
  (codex:js-repl-stderr-tail-line-limit))

!(assertEqual
  (codex:js-repl-recent-stderr-buffer-lines
    (codex:js-repl-arc-mutex-value
      (codex:js-repl-kernel-state-recent-stderr
        (test:js-repl-runtime-state-with-stderr))))
  ())

!(assertEqual
  (codex:js-repl-pending-execs-entries
    (codex:js-repl-arc-mutex-value
      (codex:js-repl-kernel-state-pending-execs
        (test:js-repl-runtime-state-with-stderr))))
  ())

!(assertEqual
  (codex:js-repl-exec-contexts-entries
    (codex:js-repl-arc-mutex-value
      (codex:js-repl-kernel-state-exec-contexts
        (test:js-repl-runtime-state-with-stderr))))
  ())

!(assertEqual
  (codex:js-repl-kernel-state-top-level-exec-state
    (test:js-repl-runtime-state-with-stderr))
  (codex:js-repl-top-level-exec-state-idle))

!(assertEqual
  (codex:js-repl-kernel-state-shutdown
    (test:js-repl-runtime-state-with-stderr))
  shutdown-1)

!(assertEqual
  (codex:js-repl-read-stdout-task-stdout
    (test:js-repl-runtime-stdout-task-with-stderr))
  stdout-1)

!(assertEqual
  (codex:js-repl-read-stdout-task-child
    (test:js-repl-runtime-stdout-task-with-stderr))
  (codex:js-repl-kernel-state-child
    (test:js-repl-runtime-state-with-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-task-kernel-cell
    (test:js-repl-runtime-stdout-task-with-stderr))
  kernel-cell-1)

!(assertEqual
  (codex:js-repl-read-stdout-task-recent-stderr
    (test:js-repl-runtime-stdout-task-with-stderr))
  (codex:js-repl-kernel-state-recent-stderr
    (test:js-repl-runtime-state-with-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-task-pending-execs
    (test:js-repl-runtime-stdout-task-with-stderr))
  (codex:js-repl-kernel-state-pending-execs
    (test:js-repl-runtime-state-with-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-task-exec-contexts
    (test:js-repl-runtime-stdout-task-with-stderr))
  (codex:js-repl-kernel-state-exec-contexts
    (test:js-repl-runtime-state-with-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-task-exec-tool-calls
    (test:js-repl-runtime-stdout-task-with-stderr))
  exec-tool-calls-1)

!(assertEqual
  (codex:js-repl-read-stdout-task-stdin
    (test:js-repl-runtime-stdout-task-with-stderr))
  (codex:js-repl-kernel-state-stdin
    (test:js-repl-runtime-state-with-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-task-shutdown
    (test:js-repl-runtime-stdout-task-with-stderr))
  shutdown-1)

!(assertEqual
  (codex:js-repl-read-stderr-task-stderr
    (test:js-repl-runtime-stderr-task-with-stderr))
  stderr-1)

!(assertEqual
  (codex:js-repl-read-stderr-task-recent-stderr
    (test:js-repl-runtime-stderr-task-with-stderr))
  (codex:js-repl-kernel-state-recent-stderr
    (test:js-repl-runtime-state-with-stderr)))

!(assertEqual
  (codex:js-repl-read-stderr-task-shutdown
    (test:js-repl-runtime-stderr-task-with-stderr))
  shutdown-1)

!(assertEqual
  (codex:js-repl-kernel-runtime-plan-warnings
    (test:js-repl-runtime-plan-with-stderr))
  ())

!(assertEqual
  (codex:js-repl-kernel-runtime-plan-stderr-task
    (test:js-repl-runtime-plan-without-stderr))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-kernel-runtime-plan-warnings
    (test:js-repl-runtime-plan-without-stderr))
  ("js_repl kernel missing stderr"))

!(assertEqual
  (codex:js-repl-read-stdout-task-stdout
    (codex:js-repl-kernel-runtime-plan-stdout-task
      (test:js-repl-runtime-plan-without-stderr)))
  stdout-2)

!(assertEqual
  (codex:js-repl-kernel-state-shutdown
    (codex:js-repl-kernel-runtime-plan-state
      (test:js-repl-runtime-plan-without-stderr)))
  shutdown-2)
