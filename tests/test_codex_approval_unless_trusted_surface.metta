!(register-module! /home/zarclaw/repos/CeTTa/codex)
!(import! &self codex:approval)

!(assertEqualToResult
  (codex:approval-requirement-type
    (codex:approval-for-command
      (codex:ask-for-approval-unless-trusted)
      (codex:file-system-sandbox-restricted)
      (codex:policy ())
      ("rg" "-n" "TODO" "src")))
  ("skip"))
