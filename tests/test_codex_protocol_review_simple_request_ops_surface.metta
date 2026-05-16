!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:review-op
      (codex:review-request
        (codex:review-target-uncommitted-changes)
        CodexAbsent)))
  ("review"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:review-op
        (codex:review-request
          (codex:review-target-base-branch "main")
          "check migrations"))))
  ("{\"type\":\"review\",\"target\":{\"type\":\"baseBranch\",\"branch\":\"main\"},\"user_facing_hint\":\"check migrations\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:shutdown-op))
  ("shutdown"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:shutdown-op)))
  ("{\"type\":\"shutdown\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:run-user-shell-command-op "git status --short"))
  ("run_user_shell_command"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:run-user-shell-command-op "git status --short")))
  ("{\"type\":\"run_user_shell_command\",\"command\":\"git status --short\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:list-models-op))
  ("list_models"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:list-models-op)))
  ("{\"type\":\"list_models\"}"))
