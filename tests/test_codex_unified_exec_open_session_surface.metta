!(register-module! ../codex)
!(import! &self codex:unified_exec_open_session)

(= (open-session-env)
   ((codex:unified-exec-env-var "PATH" "/usr/bin")
    (codex:unified-exec-env-var "CODEX_THREAD_ID" "thread-1")))

(= (open-session-request
      $command
      $sandbox
      $windows-level)
   (codex:unified-exec-open-session-request
     $command
     "/repo"
     (open-session-env)
     (codex:unified-exec-server-env-config
       policy-1
       ((codex:unified-exec-env-var "PATH" "/client-path")))
     CodexAbsent
     $sandbox
     sandbox-policy-1
     $windows-level
     "/policy-cwd"
     False))

(= (open-session-runtime)
   (codex:unified-exec-open-session-runtime-inputs
     (codex:unified-exec-runtime-result-ok remote-handle-1)
     (codex:unified-exec-runtime-result-ok local-handle-1)
     (codex:unified-exec-runtime-result-ok "{\"policy\":true}")
     (codex:unified-exec-runtime-result-ok "/codex-home")
     (codex:unified-exec-runtime-result-ok windows-handle-1)))

(= (open-session-result
      $request
      $tty
      $lifecycle
      $environment
      $host-platform
      $runtime)
   (codex:unified-exec-open-session-with-exec-env
     1234
     $request
     $tty
     $lifecycle
     $environment
     $host-platform
     $runtime))

!(assertEqual
  (codex:unified-exec-spawn-lifecycle-inherited-fds
    (codex:unified-exec-spawn-lifecycle (42) False))
  (42))

!(assertEqual
  (codex:unified-exec-spawn-lifecycle-after-spawn-called
    (codex:unified-exec-spawn-lifecycle-after-spawn
      (codex:unified-exec-spawn-lifecycle () False)))
  True)

!(assertEqual
  (codex:unified-exec-open-session-environment-is-remote
    (codex:unified-exec-open-session-environment True))
  True)

!(assertEqual
  (codex:unified-exec-open-session-request-cwd
    (open-session-request
      ("bash" "-lc" "true")
      (codex:sandbox-type-none)
      (codex:windows-sandbox-level-disabled)))
  "/repo")

!(assertEqual
  (codex:unified-exec-runtime-result-kind
    (codex:unified-exec-runtime-result-ok handle-1))
  ok)

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("bash" "-lc" "true")
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      True
      (codex:unified-exec-spawn-lifecycle () False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-linux)
      (open-session-runtime))
    (codex:unified-exec-open-session-result-kind $result))
  ok)

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("bash" "-lc" "true")
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      True
      (codex:unified-exec-spawn-lifecycle (7 8) False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-linux)
      (open-session-runtime))
    (let $spawn-request
      (codex:unified-exec-open-session-result-spawn-request
        $result)
      (codex:unified-exec-open-session-local-spawn-request-kind
        $spawn-request)))
  local_pty)

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("bash" "-lc" "true")
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      True
      (codex:unified-exec-spawn-lifecycle (7 8) False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-linux)
      (open-session-runtime))
    (let $spawn-request
      (codex:unified-exec-open-session-result-spawn-request
        $result)
      (codex:unified-exec-open-session-local-spawn-request-program
        $spawn-request)))
  "bash")

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("bash" "-lc" "true")
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      True
      (codex:unified-exec-spawn-lifecycle (7 8) False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-linux)
      (open-session-runtime))
    (let $spawn-request
      (codex:unified-exec-open-session-result-spawn-request
        $result)
      (codex:unified-exec-open-session-local-spawn-request-args
        $spawn-request)))
  ("-lc" "true"))

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("bash" "-lc" "true")
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      True
      (codex:unified-exec-spawn-lifecycle (7 8) False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-linux)
      (open-session-runtime))
    (let $spawn-request
      (codex:unified-exec-open-session-result-spawn-request
        $result)
      (codex:unified-exec-open-session-local-spawn-request-inherited-fds
        $spawn-request)))
  (7 8))

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("bash" "-lc" "true")
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      False
      (codex:unified-exec-spawn-lifecycle () False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-linux)
      (open-session-runtime))
    (let $spawn-request
      (codex:unified-exec-open-session-result-spawn-request
        $result)
      (codex:unified-exec-open-session-local-spawn-request-kind
        $spawn-request)))
  local_pipe)

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ()
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      False
      (codex:unified-exec-spawn-lifecycle () False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-linux)
      (open-session-runtime))
    (codex:unified-exec-error-kind
      (codex:unified-exec-open-session-result-error $result)))
  missing_command_line)

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ()
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      False
      (codex:unified-exec-spawn-lifecycle () False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-linux)
      (open-session-runtime))
    (codex:unified-exec-spawn-lifecycle-after-spawn-called
      (codex:unified-exec-open-session-result-spawn-lifecycle
        $result)))
  False)

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("bash" "-i")
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      True
      (codex:unified-exec-spawn-lifecycle () False)
      (codex:unified-exec-open-session-environment True)
      (codex:host-platform-linux)
      (open-session-runtime))
    (let $process
      (codex:unified-exec-open-session-result-process $result)
      (codex:unified-exec-open-session-process-source
        $process)))
  exec_server)

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("bash" "-i")
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      True
      (codex:unified-exec-spawn-lifecycle () False)
      (codex:unified-exec-open-session-environment True)
      (codex:host-platform-linux)
      (open-session-runtime))
    (let $spawn-request
      (codex:unified-exec-open-session-result-spawn-request
        $result)
      (codex:unified-exec-server-params-process-id
        (codex:unified-exec-open-session-remote-start-request-params
          $spawn-request))))
  "1234")

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("bash" "-i")
        (codex:sandbox-type-none)
        (codex:windows-sandbox-level-disabled))
      True
      (codex:unified-exec-spawn-lifecycle (42) False)
      (codex:unified-exec-open-session-environment True)
      (codex:host-platform-linux)
      (open-session-runtime))
    (codex:unified-exec-error-display
      (codex:unified-exec-open-session-result-error $result)))
  "Failed to create unified exec process: remote exec-server does not support inherited file descriptors")

!(assertEqual
  (let $runtime
    (codex:unified-exec-open-session-runtime-inputs
      (codex:unified-exec-runtime-result-err "remote down")
      (codex:unified-exec-runtime-result-ok local-handle-1)
      (codex:unified-exec-runtime-result-ok "{}")
      (codex:unified-exec-runtime-result-ok "/codex-home")
      (codex:unified-exec-runtime-result-ok windows-handle-1))
    (let $result
      (open-session-result
        (open-session-request
          ("bash" "-i")
          (codex:sandbox-type-none)
          (codex:windows-sandbox-level-disabled))
        True
        (codex:unified-exec-spawn-lifecycle () False)
        (codex:unified-exec-open-session-environment True)
        (codex:host-platform-linux)
        $runtime)
      (codex:unified-exec-error-display
        (codex:unified-exec-open-session-result-error $result))))
  "Failed to create unified exec process: remote down")

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("pwsh" "-NoLogo")
        (codex:sandbox-type-windows-restricted-token)
        (codex:windows-sandbox-level-elevated))
      True
      (codex:unified-exec-spawn-lifecycle () False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-windows)
      (open-session-runtime))
    (let $spawn-request
      (codex:unified-exec-open-session-result-spawn-request
        $result)
      (codex:unified-exec-open-session-windows-spawn-request-kind
        $spawn-request)))
  windows_elevated)

!(assertEqual
  (let $result
    (open-session-result
      (open-session-request
        ("pwsh" "-NoLogo")
        (codex:sandbox-type-windows-restricted-token)
        (codex:windows-sandbox-level-restricted-token))
      True
      (codex:unified-exec-spawn-lifecycle () False)
      (codex:unified-exec-open-session-environment False)
      (codex:host-platform-windows)
      (open-session-runtime))
    (let $process
      (codex:unified-exec-open-session-result-process $result)
      (codex:unified-exec-open-session-process-source
        $process)))
  windows_legacy)

!(assertEqual
  (let $runtime
    (codex:unified-exec-open-session-runtime-inputs
      (codex:unified-exec-runtime-result-ok remote-handle-1)
      (codex:unified-exec-runtime-result-ok local-handle-1)
      (codex:unified-exec-runtime-result-err "json boom")
      (codex:unified-exec-runtime-result-ok "/codex-home")
      (codex:unified-exec-runtime-result-ok windows-handle-1))
    (let $result
      (open-session-result
        (open-session-request
          ("pwsh")
          (codex:sandbox-type-windows-restricted-token)
          (codex:windows-sandbox-level-elevated))
        True
        (codex:unified-exec-spawn-lifecycle () False)
        (codex:unified-exec-open-session-environment False)
        (codex:host-platform-windows)
        $runtime)
      (codex:unified-exec-error-display
        (codex:unified-exec-open-session-result-error $result))))
  "Failed to create unified exec process: failed to serialize Windows sandbox policy: json boom")

!(assertEqual
  (let $runtime
    (codex:unified-exec-open-session-runtime-inputs
      (codex:unified-exec-runtime-result-ok remote-handle-1)
      (codex:unified-exec-runtime-result-ok local-handle-1)
      (codex:unified-exec-runtime-result-ok "{}")
      (codex:unified-exec-runtime-result-err "home boom")
      (codex:unified-exec-runtime-result-ok windows-handle-1))
    (let $result
      (open-session-result
        (open-session-request
          ("pwsh")
          (codex:sandbox-type-windows-restricted-token)
          (codex:windows-sandbox-level-elevated))
        True
        (codex:unified-exec-spawn-lifecycle () False)
        (codex:unified-exec-open-session-environment False)
        (codex:host-platform-windows)
        $runtime)
      (codex:unified-exec-error-display
        (codex:unified-exec-open-session-result-error $result))))
  "Failed to create unified exec process: windows sandbox: failed to resolve codex_home: home boom")

!(assertEqual
  (let $runtime
    (codex:unified-exec-open-session-runtime-inputs
      (codex:unified-exec-runtime-result-ok remote-handle-1)
      (codex:unified-exec-runtime-result-err "spawn denied")
      (codex:unified-exec-runtime-result-ok "{}")
      (codex:unified-exec-runtime-result-ok "/codex-home")
      (codex:unified-exec-runtime-result-ok windows-handle-1))
    (let $result
      (open-session-result
        (open-session-request
          ("bash")
          (codex:sandbox-type-none)
          (codex:windows-sandbox-level-disabled))
        False
        (codex:unified-exec-spawn-lifecycle () False)
        (codex:unified-exec-open-session-environment False)
        (codex:host-platform-linux)
        $runtime)
      (codex:unified-exec-error-display
        (codex:unified-exec-open-session-result-error $result))))
  "Failed to create unified exec process: spawn denied")
