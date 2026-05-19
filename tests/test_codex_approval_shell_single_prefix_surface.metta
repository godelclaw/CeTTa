!(register-module! ../codex)
!(import! &self json)
!(import! &self shell)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)

!(assertEqual
  (shell-single-command-prefix
    "zsh"
    "-lc"
    "python3 <<'PY'\nprint('hello')\nPY")
  ("python3"))

!(assertEqual
  (shell-single-command-prefix
    "bash"
    "-lc"
    "python3 -u <<'PY' > /tmp/out.txt\nprint('hello')\nPY")
  ("python3" "-u"))

!(assertEqualToResult
  (shell-single-command-prefix
    "bash"
    "-lc"
    "python3 <<'PY'\nprint('hello')\nPY\necho done")
  (Empty))

!(assertEqualToResult
  (shell-single-command-prefix
    "bash"
    "-lc"
    "python3 <<'PY' extra-arg\nprint('hello')\nPY")
  (Empty))

!(assertEqualToResult
  (shell-single-command-prefix
    "bash"
    "-lc"
    "python3\n<<'PY'\nprint('hello')\nPY")
  (Empty))

!(assertEqualToResult
  (shell-single-command-prefix
    "bash"
    "-lc"
    "echo hello > /tmp/out.txt")
  (Empty))

!(assertEqual
  (codex:commands-for-exec-policy
    ("zsh" "-lc" "python3 <<'PY'\nprint('hello')\nPY"))
  (CodexExecPolicyCommands (("python3")) True))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-on-request)
        (codex:file-system-sandbox-restricted)
        (codex:policy ())
        ("bash" "-lc" "python3 <<'PY'\nprint('hello')\nPY"))))
  ("{\"type\":\"skip\",\"bypass_sandbox\":false,\"proposed_execpolicy_amendment\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-on-request)
        (codex:file-system-sandbox-restricted)
        (codex:policy ())
        ("bash" "-lc" "rm -rf /tmp/codex <<'EOF'\nignored\nEOF"))))
  ("{\"type\":\"needs_approval\",\"reason\":null,\"proposed_execpolicy_amendment\":null}"))
