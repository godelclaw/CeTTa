!(register-module! ../codex)
!(import! &self codex:tool_config)

(= (codex-tool-config-default-model)
   (codex:tool-config-model-info
     (codex:config-shell-tool-type-unified-exec)
     CodexAbsent
     ("list_dir")
     False))

(= (codex-tool-config-default-features)
   (codex:tool-config-features
     True
     True
     False
     True
     False
     False
     False))

(= (codex-tool-config-zsh-fork-features)
   (codex:tool-config-features
     True
     True
     True
     False
     False
     False
     False))

(= (codex-tool-config-explicit-function-model)
   (codex:tool-config-model-info
     (codex:config-shell-tool-type-shell-command)
     (codex:apply-patch-tool-type-function)
     ()
     True))

(= (codex-tool-config-request-permissions-features)
   (codex:tool-config-features
     True
     True
     False
     True
     True
     True
     True))

(= (codex-tool-config-js-repl-features)
   (codex:tool-config-features-with-js-repl
     True
     True
     False
     True
     False
     False
     True
     False
     False))

(= (codex-tool-config-js-repl-tools-only-features)
   (codex:tool-config-features-with-js-repl
     True
     True
     False
     True
     False
     False
     True
     True
     False))

(= (codex-tool-config-default-config)
   (codex:tools-config-new
     (codex:tools-config-new-params
       (codex-tool-config-default-model)
       (codex-tool-config-default-features)
       False
       (codex:tool-config-sandbox-policy-danger-full-access)
       (codex:windows-sandbox-level-disabled))))

!(assertEqualToResult
  (codex:unified-exec-allowed-in-environment
    True
    (codex:tool-config-sandbox-policy-read-only)
    (codex:windows-sandbox-level-restricted-token))
  (False))

!(assertEqualToResult
  (codex:unified-exec-allowed-in-environment
    True
    (codex:tool-config-sandbox-policy-danger-full-access)
    (codex:windows-sandbox-level-restricted-token))
  (True))

!(assertEqualToResult
  (codex:tools-config-shell-type
    (codex-tool-config-default-config))
  ("UnifiedExec"))

!(assertEqualToResult
  (codex:tools-config-shell-command-backend
    (codex-tool-config-default-config))
  ("Classic"))

!(assertEqualToResult
  (codex:tools-config-apply-patch-tool-type
    (codex-tool-config-default-config))
  ("Freeform"))

!(assertEqualToResult
  (codex:tools-config-experimental-supported-tools
    (codex-tool-config-default-config))
  (("list_dir")))

!(assertEqualToResult
  (codex:tools-config-can-request-original-image-detail
    (codex-tool-config-default-config))
  (False))

!(assertEqualToResult
  (codex:tools-config-shell-type
    (codex:tools-config-new
      (codex:tools-config-new-params
        (codex-tool-config-default-model)
        (codex-tool-config-zsh-fork-features)
        False
        (codex:tool-config-sandbox-policy-danger-full-access)
        (codex:windows-sandbox-level-disabled))))
  ("ShellCommand"))

!(assertEqualToResult
  (codex:tools-config-shell-command-backend
    (codex:tools-config-new
      (codex:tools-config-new-params
        (codex-tool-config-default-model)
        (codex-tool-config-zsh-fork-features)
        False
        (codex:tool-config-sandbox-policy-danger-full-access)
        (codex:windows-sandbox-level-disabled))))
  ("ZshFork"))

!(assertEqualToResult
  (codex:unified-exec-shell-mode-for-session
    True
    (codex:shell-command-backend-config-zsh-fork)
    (codex:tool-user-shell-type-zsh)
    "/opt/codex/zsh"
    "/opt/codex/codex-execve-wrapper")
  ((CodexUnifiedExecShellModeZshFork
     "/opt/codex/zsh"
     "/opt/codex/codex-execve-wrapper")))

!(assertEqualToResult
  (codex:unified-exec-shell-mode-for-session
    False
    (codex:shell-command-backend-config-zsh-fork)
    (codex:tool-user-shell-type-zsh)
    "/opt/codex/zsh"
    "/opt/codex/codex-execve-wrapper")
  ("Direct"))

!(assertEqualToResult
  (codex:unified-exec-shell-mode-for-session
    True
    (codex:shell-command-backend-config-classic)
    (codex:tool-user-shell-type-zsh)
    "/opt/codex/zsh"
    "/opt/codex/codex-execve-wrapper")
  ("Direct"))

!(assertEqualToResult
  (codex:unified-exec-shell-mode-for-session
    True
    (codex:shell-command-backend-config-zsh-fork)
    (codex:tool-user-shell-type-bash)
    "/opt/codex/zsh"
    "/opt/codex/codex-execve-wrapper")
  ("Direct"))

!(assertEqualToResult
  (codex:unified-exec-shell-mode-for-session
    True
    (codex:shell-command-backend-config-zsh-fork)
    (codex:tool-user-shell-type-zsh)
    "relative-zsh"
    "/opt/codex/codex-execve-wrapper")
  ("Direct"))

!(assertEqualToResult
  (codex:tools-config-unified-exec-shell-mode
    (codex:tools-config-with-unified-exec-shell-mode-for-session
      (codex:tools-config-new
        (codex:tools-config-new-params
          (codex-tool-config-default-model)
          (codex-tool-config-zsh-fork-features)
          False
          (codex:tool-config-sandbox-policy-danger-full-access)
          (codex:windows-sandbox-level-disabled)))
      True
      (codex:tool-user-shell-type-zsh)
      "/opt/codex/zsh"
      "/opt/codex/codex-execve-wrapper"))
  ((CodexUnifiedExecShellModeZshFork
     "/opt/codex/zsh"
     "/opt/codex/codex-execve-wrapper")))

!(assertEqualToResult
  (codex:tools-config-apply-patch-tool-type
    (codex:tools-config-new
      (codex:tools-config-new-params
        (codex-tool-config-explicit-function-model)
        (codex-tool-config-default-features)
        False
        (codex:tool-config-sandbox-policy-danger-full-access)
        (codex:windows-sandbox-level-disabled))))
  ("Function"))

!(assertEqualToResult
  (codex:tools-config-can-request-original-image-detail
    (codex:tools-config-new
      (codex:tools-config-new-params
        (codex-tool-config-explicit-function-model)
        (codex-tool-config-default-features)
        False
        (codex:tool-config-sandbox-policy-danger-full-access)
        (codex:windows-sandbox-level-disabled))))
  (True))

!(assertEqualToResult
  (codex:tools-config-request-permissions-tool-enabled
    (codex:tools-config-new
      (codex:tools-config-new-params
        (codex-tool-config-default-model)
        (codex-tool-config-request-permissions-features)
        False
        (codex:tool-config-sandbox-policy-danger-full-access)
        (codex:windows-sandbox-level-disabled))))
  (True))

!(assertEqualToResult
  (codex:tools-config-default-mode-request-user-input
    (codex:tools-config-new
      (codex:tools-config-new-params
        (codex-tool-config-default-model)
        (codex-tool-config-request-permissions-features)
        False
        (codex:tool-config-sandbox-policy-danger-full-access)
       (codex:windows-sandbox-level-disabled))))
  (True))

!(assertEqualToResult
  (codex:tools-config-js-repl-enabled
    (codex-tool-config-default-config))
  (False))

!(assertEqualToResult
  (codex:tools-config-js-repl-enabled
    (codex:tools-config-new
      (codex:tools-config-new-params
        (codex-tool-config-default-model)
        (codex-tool-config-js-repl-features)
        False
        (codex:tool-config-sandbox-policy-danger-full-access)
        (codex:windows-sandbox-level-disabled))))
  (True))

!(assertEqualToResult
  (codex:tools-config-js-repl-tools-only
    (codex:tools-config-new
      (codex:tools-config-new-params
        (codex-tool-config-default-model)
        (codex-tool-config-js-repl-features)
        False
        (codex:tool-config-sandbox-policy-danger-full-access)
        (codex:windows-sandbox-level-disabled))))
  (False))

!(assertEqualToResult
  (codex:tools-config-js-repl-tools-only
    (codex:tools-config-new
      (codex:tools-config-new-params
        (codex-tool-config-default-model)
        (codex-tool-config-js-repl-tools-only-features)
        False
        (codex:tool-config-sandbox-policy-danger-full-access)
        (codex:windows-sandbox-level-disabled))))
  (True))

!(assertEqualToResult
  (codex:tools-config-has-environment
    (codex:tools-config-with-has-environment
      (codex-tool-config-default-config)
      False))
  (False))

!(assertEqualToResult
  (codex:tools-config-allow-login-shell
    (codex:tools-config-with-allow-login-shell
      (codex-tool-config-default-config)
      False))
  (False))
