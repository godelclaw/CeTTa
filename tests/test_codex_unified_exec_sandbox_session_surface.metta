!(register-module! ../codex)
!(import! &self codex:unified_exec_sandbox_session)

(= (sandbox-session-local-policy-env)
   ((codex:unified-exec-env-var "PATH" "/usr/bin")
    (codex:unified-exec-env-var "HOME" "/home/user")))

(= (sandbox-session-explicit-env-overrides)
   ((codex:unified-exec-env-var "EXPLICIT" "1")))

(= (sandbox-session-request $preapproved)
   (codex:unified-exec-exec-command-request
     ("bash" "-lc" "printf hi")
     "printf hi"
     9
     1000
     CodexAbsent
     "/ignored-workdir"
     network-1
     True
     "require_escalated"
     additional-permissions-1
     $preapproved
     "need more access"
     ("bash" "-lc")))

(= (sandbox-session-context)
   (codex:unified-exec-context-new
     session-1
     turn-1
     "call-1"))

(= (sandbox-session-output $exit-code $aggregated-output)
   (codex:unified-exec-process-exec-tool-call-output
     $exit-code
     "stdout-text"
     "stderr-text"
     $aggregated-output
     17
     False))

(= (sandbox-session-inputs $orchestrator-result)
   (codex:unified-exec-open-session-sandbox-inputs
     (sandbox-session-local-policy-env)
     exec-env-policy-1
     (sandbox-session-explicit-env-overrides)
     "conv-42"
     approval-policy-1
     sandbox-policy-1
     file-system-sandbox-policy-1
     (codex:approval-needs-approval "policy")
     $orchestrator-result
     shell-mode-direct))

(= (sandbox-session-result $preapproved $orchestrator-result)
   (codex:unified-exec-open-session-with-sandbox
     (sandbox-session-request $preapproved)
     "/repo"
     (sandbox-session-context)
     (sandbox-session-inputs $orchestrator-result)))

!(assertEqual
  (codex:unified-exec-open-session-approval-sandbox-permissions
    (sandbox-session-request False))
  "require_escalated")

!(assertEqual
  (codex:unified-exec-open-session-approval-sandbox-permissions
    (sandbox-session-request True))
  (codex:approval-sandbox-permissions-use-default))

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (codex:unified-exec-open-session-with-sandbox-result-kind
      $result))
  ok)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (codex:unified-exec-open-session-with-sandbox-result-process
      $result))
  process-1)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (codex:unified-exec-open-session-with-sandbox-result-deferred-network-approval
      $result))
  deferred-network-approval-1)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-command $tool-request)))
  ("bash" "-lc" "printf hi"))

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-hook-command
        $tool-request)))
  "printf hi")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-process-id
        $tool-request)))
  9)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-cwd $tool-request)))
  "/repo")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-env-get
        (codex:unified-exec-tool-request-env $tool-request)
        "CODEX_THREAD_ID")))
  "conv-42")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-env-get
        (codex:unified-exec-tool-request-env $tool-request)
        "NO_COLOR")))
  "1")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-env-get
        (codex:unified-exec-tool-request-env $tool-request)
        "PATH")))
  "/usr/bin")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (let $config
        (codex:unified-exec-tool-request-exec-server-env-config
          $tool-request)
        (codex:unified-exec-server-env-config-policy $config))))
  exec-env-policy-1)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (let $config
        (codex:unified-exec-tool-request-exec-server-env-config
          $tool-request)
        (codex:unified-exec-server-env-config-local-policy-env
          $config))))
  (sandbox-session-local-policy-env))

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-explicit-env-overrides
        $tool-request)))
  (sandbox-session-explicit-env-overrides))

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-network $tool-request)))
  network-1)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-tty $tool-request)))
  True)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-sandbox-permissions
        $tool-request)))
  "require_escalated")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-additional-permissions
        $tool-request)))
  additional-permissions-1)

!(assertEqual
  (let $result
    (sandbox-session-result
      True
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-additional-permissions-preapproved
        $tool-request)))
  True)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:unified-exec-tool-request-justification
        $tool-request)))
  "need more access")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-request
      (codex:unified-exec-open-session-with-sandbox-result-tool-request
        $result)
      (codex:approval-requirement-type
        (codex:unified-exec-tool-request-exec-approval-requirement
          $tool-request))))
  "needs_approval")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-ctx
      (codex:unified-exec-open-session-with-sandbox-result-tool-ctx
        $result)
      (codex:unified-exec-tool-ctx-tool-name $tool-ctx)))
  "exec_command")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $tool-ctx
      (codex:unified-exec-open-session-with-sandbox-result-tool-ctx
        $result)
      (codex:unified-exec-tool-ctx-call-id $tool-ctx)))
  "call-1")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $approval-request
      (codex:unified-exec-open-session-with-sandbox-result-approval-request
        $result)
      (codex:unified-exec-exec-approval-request-sandbox-permissions
        $approval-request)))
  "require_escalated")

!(assertEqual
  (let $result
    (sandbox-session-result
      True
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $approval-request
      (codex:unified-exec-open-session-with-sandbox-result-approval-request
        $result)
      (codex:unified-exec-exec-approval-request-sandbox-permissions
        $approval-request)))
  (codex:approval-sandbox-permissions-use-default))

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (let $approval-request
      (codex:unified-exec-open-session-with-sandbox-result-approval-request
        $result)
      (codex:unified-exec-exec-approval-request-prefix-rule
        $approval-request)))
  ("bash" "-lc"))

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-ok
        process-1
        deferred-network-approval-1))
    (codex:unified-exec-open-session-with-sandbox-result-runtime-shell-mode
      $result))
  shell-mode-direct)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-sandbox-denied
        (sandbox-session-output 126 "blocked by sandbox")))
    (codex:unified-exec-open-session-with-sandbox-result-kind
      $result))
  err)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-sandbox-denied
        (sandbox-session-output 126 "blocked by sandbox")))
    (let $error
      (codex:unified-exec-open-session-with-sandbox-result-error
        $result)
      (codex:unified-exec-error-kind $error)))
  sandbox_denied)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-sandbox-denied
        (sandbox-session-output 126 "blocked by sandbox")))
    (let $error
      (codex:unified-exec-open-session-with-sandbox-result-error
        $result)
      (codex:unified-exec-error-message $error)))
  "blocked by sandbox")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-sandbox-denied
        (sandbox-session-output 23 "")))
    (let $error
      (codex:unified-exec-open-session-with-sandbox-result-error
        $result)
      (codex:unified-exec-error-message $error)))
  "Process exited with code 23")

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-sandbox-denied
        (sandbox-session-output 23 "")))
    (let $error
      (codex:unified-exec-open-session-with-sandbox-result-error
        $result)
      (codex:unified-exec-process-exec-tool-call-output-exit-code
        (codex:unified-exec-error-output $error))))
  23)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-err
        "ToolError::Other"))
    (let $error
      (codex:unified-exec-open-session-with-sandbox-result-error
        $result)
      (codex:unified-exec-error-kind $error)))
  create_process)

!(assertEqual
  (let $result
    (sandbox-session-result
      False
      (codex:unified-exec-orchestrator-run-err
        "ToolError::Other"))
    (let $error
      (codex:unified-exec-open-session-with-sandbox-result-error
        $result)
      (codex:unified-exec-error-message $error)))
  "ToolError::Other")
