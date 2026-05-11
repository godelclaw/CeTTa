!(register-module! ../codex)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)

!(assertEqualToResult
  (codex:approval-requirement-type
    (codex:approval-for-command
      (codex:ask-for-approval-unless-trusted)
      (codex:file-system-sandbox-restricted)
      (codex:policy ())
      ("rg" "-n" "TODO" "src")))
  ("skip"))
