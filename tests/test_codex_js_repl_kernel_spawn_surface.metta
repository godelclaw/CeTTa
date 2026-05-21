!(register-module! ../codex)
!(import! &self codex:js_repl)
!(import! &self codex:js_repl_kernel_spawn)
!(import! &self codex:sandbox_tags)

(= (test:js-repl-spawn-env)
   ((codex:js-repl-env-var "PATH" "/usr/bin")
    (codex:js-repl-env-var "CODEX_JS_TMP_DIR" "/tmp/js")))

(= (test:js-repl-exec-env $arg0)
   (codex:js-repl-exec-env
     ("/sandbox/node" "--experimental-vm-modules" "/tmp/kernel.mjs")
     "/repo"
     (test:js-repl-spawn-env)
     $arg0))

(= (test:js-repl-unix-plan)
   (codex:js-repl-tokio-command-plan-from-exec-env
     (test:js-repl-exec-env CodexAbsent)
     (codex:host-platform-linux)))

!(assertEqual
  (codex:js-repl-command-first-or-default
    ("/sandbox/node" "--experimental-vm-modules"))
  "/sandbox/node")

!(assertEqual
  (codex:js-repl-command-first-or-default ())
  "")

!(assertEqual
  (codex:js-repl-command-args-after-program
    ("/sandbox/node" "--experimental-vm-modules" "/tmp/kernel.mjs"))
  ("--experimental-vm-modules" "/tmp/kernel.mjs"))

!(assertEqual
  (codex:js-repl-command-args-after-program ("/sandbox/node"))
  ())

!(assertEqual
  (codex:js-repl-tokio-command-plan-program
    (test:js-repl-unix-plan))
  "/sandbox/node")

!(assertEqual
  (codex:js-repl-tokio-command-plan-args
    (test:js-repl-unix-plan))
  ("--experimental-vm-modules" "/tmp/kernel.mjs"))

!(assertEqual
  (codex:js-repl-tokio-command-plan-arg0
    (test:js-repl-unix-plan))
  "/sandbox/node")

!(assertEqual
  (codex:js-repl-tokio-command-plan-arg0
    (codex:js-repl-tokio-command-plan-from-exec-env
      (test:js-repl-exec-env "node-arg0")
      (codex:host-platform-linux)))
  "node-arg0")

!(assertEqual
  (codex:js-repl-tokio-command-plan-arg0
    (codex:js-repl-tokio-command-plan-from-exec-env
      (test:js-repl-exec-env "node-arg0")
      (codex:host-platform-windows)))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-tokio-command-plan-arg0
    (codex:js-repl-tokio-command-plan-from-exec-env
      (codex:js-repl-exec-env () "/repo" () CodexAbsent)
      (codex:host-platform-linux)))
  "")

!(assertEqual
  (codex:js-repl-tokio-command-plan-cwd
    (test:js-repl-unix-plan))
  "/repo")

!(assertEqual
  (codex:js-repl-tokio-command-plan-env
    (test:js-repl-unix-plan))
  (test:js-repl-spawn-env))

!(assertEqual
  (codex:js-repl-tokio-command-plan-env-clear
    (test:js-repl-unix-plan))
  True)

!(assertEqual
  (codex:js-repl-tokio-command-plan-stdin
    (test:js-repl-unix-plan))
  (CodexJsReplStdioPiped))

!(assertEqual
  (codex:js-repl-tokio-command-plan-stdout
    (test:js-repl-unix-plan))
  (CodexJsReplStdioPiped))

!(assertEqual
  (codex:js-repl-tokio-command-plan-stderr
    (test:js-repl-unix-plan))
  (CodexJsReplStdioPiped))

!(assertEqual
  (codex:js-repl-tokio-command-plan-kill-on-drop
    (test:js-repl-unix-plan))
  True)

!(assertEqual
  (codex:js-repl-start-kernel-spawn-result-error-message
    (codex:js-repl-start-kernel-handle-spawn
      (codex:js-repl-child-spawn-error "permission denied")))
  "failed to start Node runtime: permission denied")

!(assertEqual
  (codex:js-repl-start-kernel-spawn-result-error-message
    (codex:js-repl-start-kernel-handle-spawn
      (codex:js-repl-child-spawn-ok
        child-1
        CodexAbsent
        CodexAbsent
        CodexAbsent)))
  "js_repl kernel missing stdout")

!(assertEqual
  (codex:js-repl-start-kernel-spawn-result-error-message
    (codex:js-repl-start-kernel-handle-spawn
      (codex:js-repl-child-spawn-ok
        child-1
        stdout-1
        CodexAbsent
        CodexAbsent)))
  "js_repl kernel missing stdin")

!(assertEqual
  (codex:js-repl-spawned-kernel-stderr-warning
    (codex:js-repl-start-kernel-spawn-result-value
      (codex:js-repl-start-kernel-handle-spawn
        (codex:js-repl-child-spawn-ok
          child-1
          stdout-1
          CodexAbsent
          stdin-1))))
  "js_repl kernel missing stderr")

!(assertEqual
  (codex:js-repl-spawned-kernel-stderr
    (codex:js-repl-start-kernel-spawn-result-value
      (codex:js-repl-start-kernel-handle-spawn
        (codex:js-repl-child-spawn-ok
          child-1
          stdout-1
          CodexAbsent
          stdin-1))))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-spawned-kernel-child
    (codex:js-repl-start-kernel-spawn-result-value
      (codex:js-repl-start-kernel-handle-spawn
        (codex:js-repl-child-spawn-ok
          child-2
          stdout-2
          stderr-2
          stdin-2))))
  child-2)

!(assertEqual
  (codex:js-repl-spawned-kernel-stdout
    (codex:js-repl-start-kernel-spawn-result-value
      (codex:js-repl-start-kernel-handle-spawn
        (codex:js-repl-child-spawn-ok
          child-2
          stdout-2
          stderr-2
          stdin-2))))
  stdout-2)

!(assertEqual
  (codex:js-repl-spawned-kernel-stderr
    (codex:js-repl-start-kernel-spawn-result-value
      (codex:js-repl-start-kernel-handle-spawn
        (codex:js-repl-child-spawn-ok
          child-2
          stdout-2
          stderr-2
          stdin-2))))
  stderr-2)

!(assertEqual
  (codex:js-repl-spawned-kernel-stdin
    (codex:js-repl-start-kernel-spawn-result-value
      (codex:js-repl-start-kernel-handle-spawn
        (codex:js-repl-child-spawn-ok
          child-2
          stdout-2
          stderr-2
          stdin-2))))
  stdin-2)

!(assertEqual
  (codex:js-repl-spawned-kernel-stderr-warning
    (codex:js-repl-start-kernel-spawn-result-value
      (codex:js-repl-start-kernel-handle-spawn
        (codex:js-repl-child-spawn-ok
          child-2
          stdout-2
          stderr-2
          stdin-2))))
  CodexAbsent)
