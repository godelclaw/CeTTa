!(register-module! ../codex)
!(import! &self codex:js_repl)
!(import! &self codex:js_repl_kernel_sandbox)
!(import! &self codex:permissions)
!(import! &self codex:sandbox_tags)
!(import! &self codex:tool_config)

(= (test:js-repl-kernel-env)
   ((codex:js-repl-env-var "PATH" "/usr/bin")
    (codex:js-repl-env-var "CODEX_JS_TMP_DIR" "/tmp/js")))

(= (test:js-repl-kernel-turn $network $file-system-policy)
   (codex:js-repl-start-kernel-turn-context
     "/repo"
     (CodexSessionSandboxPolicyWorkspaceWrite)
     $file-system-policy
     (codex:network-sandbox-policy-enabled)
     $network
     (codex:windows-sandbox-level-disabled)
     "/usr/lib/codex-linux-sandbox"
     True
     True
     (codex:host-platform-linux)))

(= (test:js-repl-kernel-managed-turn)
   (test:js-repl-kernel-turn
     (CodexNetworkProxy "managed")
     (codex:file-system-sandbox-policy-unrestricted)))

(= (test:js-repl-kernel-unmanaged-turn)
   (test:js-repl-kernel-turn
     CodexAbsent
     (codex:file-system-sandbox-policy-unrestricted)))

(= (test:js-repl-kernel-restricted-turn)
   (test:js-repl-kernel-turn
     CodexAbsent
     (codex:file-system-sandbox-policy-default)))

(= (test:js-repl-kernel-command)
   (codex:js-repl-start-kernel-sandbox-command
     "/usr/bin/node"
     "/tmp/codex-js-kernel.mjs"
     "/repo"
     (test:js-repl-kernel-env)))

(= (test:js-repl-kernel-transform-request)
   (codex:js-repl-start-kernel-transform-request
     "/usr/bin/node"
     "/tmp/codex-js-kernel.mjs"
     (test:js-repl-kernel-env)
     (test:js-repl-kernel-managed-turn)))

(= (test:js-repl-kernel-plan)
   (codex:js-repl-start-kernel-plan-value
     (codex:js-repl-start-kernel-plan
       "/usr/bin/node"
       "/tmp/codex-js-kernel.mjs"
       (codex:js-repl-start-kernel-env-ok
         (test:js-repl-kernel-env))
       (test:js-repl-kernel-managed-turn))))

!(assertEqual
  (codex:js-repl-start-kernel-managed-network-active
    (test:js-repl-kernel-managed-turn))
  True)

!(assertEqual
  (codex:js-repl-start-kernel-managed-network-active
    (test:js-repl-kernel-unmanaged-turn))
  False)

!(assertEqual
  (codex:js-repl-start-kernel-sandbox-type
    (test:js-repl-kernel-managed-turn))
  (codex:sandbox-type-linux-seccomp))

!(assertEqual
  (codex:js-repl-start-kernel-sandbox-type
    (test:js-repl-kernel-unmanaged-turn))
  (codex:sandbox-type-none))

!(assertEqual
  (codex:js-repl-start-kernel-sandbox-type
    (test:js-repl-kernel-restricted-turn))
  (codex:sandbox-type-linux-seccomp))

!(assertEqual
  (codex:js-repl-sandbox-command-program
    (test:js-repl-kernel-command))
  "/usr/bin/node")

!(assertEqual
  (codex:js-repl-sandbox-command-args
    (test:js-repl-kernel-command))
  ("--experimental-vm-modules" "/tmp/codex-js-kernel.mjs"))

!(assertEqual
  (codex:js-repl-sandbox-command-cwd
    (test:js-repl-kernel-command))
  "/repo")

!(assertEqual
  (codex:js-repl-sandbox-command-env
    (test:js-repl-kernel-command))
  (test:js-repl-kernel-env))

!(assertEqual
  (codex:js-repl-sandbox-command-additional-permissions
    (test:js-repl-kernel-command))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-sandbox-command-program
    (codex:js-repl-sandbox-transform-request-command
      (test:js-repl-kernel-transform-request)))
  "/usr/bin/node")

!(assertEqual
  (codex:js-repl-sandbox-transform-request-policy
    (test:js-repl-kernel-transform-request))
  (CodexSessionSandboxPolicyWorkspaceWrite))

!(assertEqual
  (codex:js-repl-sandbox-transform-request-file-system-policy
    (test:js-repl-kernel-transform-request))
  (codex:file-system-sandbox-policy-unrestricted))

!(assertEqual
  (codex:js-repl-sandbox-transform-request-network-policy
    (test:js-repl-kernel-transform-request))
  (codex:network-sandbox-policy-enabled))

!(assertEqual
  (codex:js-repl-sandbox-transform-request-sandbox
    (test:js-repl-kernel-transform-request))
  (codex:sandbox-type-linux-seccomp))

!(assertEqual
  (codex:js-repl-sandbox-transform-request-enforce-managed-network
    (test:js-repl-kernel-transform-request))
  True)

!(assertEqual
  (codex:js-repl-sandbox-transform-request-network
    (test:js-repl-kernel-transform-request))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-sandbox-transform-request-sandbox-policy-cwd
    (test:js-repl-kernel-transform-request))
  "/repo")

!(assertEqual
  (codex:js-repl-sandbox-transform-request-codex-linux-sandbox-exe
    (test:js-repl-kernel-transform-request))
  "/usr/lib/codex-linux-sandbox")

!(assertEqual
  (codex:js-repl-sandbox-transform-request-use-legacy-landlock
    (test:js-repl-kernel-transform-request))
  True)

!(assertEqual
  (codex:js-repl-sandbox-transform-request-windows-sandbox-level
    (test:js-repl-kernel-transform-request))
  (codex:windows-sandbox-level-disabled))

!(assertEqual
  (codex:js-repl-sandbox-transform-request-windows-sandbox-private-desktop
    (test:js-repl-kernel-transform-request))
  True)

!(assertEqual
  (codex:js-repl-exec-options-expiration
    (codex:js-repl-start-kernel-exec-options))
  (CodexJsReplExecExpirationDefaultTimeout))

!(assertEqual
  (codex:js-repl-exec-options-capture-policy
    (codex:js-repl-start-kernel-exec-options))
  (CodexJsReplExecCapturePolicyShellTool))

!(assertEqual
  (codex:js-repl-start-kernel-transform-plan-windows-sandbox-policy-cwd
    (test:js-repl-kernel-plan))
  "/repo")

!(assertEqual
  (codex:js-repl-sandbox-transform-request-network
    (codex:js-repl-start-kernel-transform-plan-request
      (test:js-repl-kernel-plan)))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-exec-options-capture-policy
    (codex:js-repl-start-kernel-transform-plan-exec-options
      (test:js-repl-kernel-plan)))
  (CodexJsReplExecCapturePolicyShellTool))

!(assertEqual
  (codex:js-repl-start-kernel-plan-error-message
    (codex:js-repl-start-kernel-plan
      "/usr/bin/node"
      "/tmp/codex-js-kernel.mjs"
      (codex:js-repl-start-kernel-env-error "env failed")
      (test:js-repl-kernel-managed-turn)))
  "env failed")

!(assertEqual
  (codex:js-repl-start-kernel-transform-error-message
    "missing codex-linux-sandbox executable path")
  "failed to configure sandbox for js_repl: missing codex-linux-sandbox executable path")
