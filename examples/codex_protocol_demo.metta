; Visible first-step Codex protocol demo.
!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(println! "=== Codex protocol demo ===")
!(println!
  (json-stringify
    (codex:items-json
      ((codex:user-message "Summarize the repo state.")
       (codex:assistant-message "Inspecting the workspace.")
       (codex:tool-call "call_1" "exec_command" "{\"cmd\":\"pwd\"}")
       (codex:tool-result "call_1" "{\"stdout\":\"/home/zarclaw/repos/CeTTa\\n\"}")
       (codex:final-response "The workspace root is /home/zarclaw/repos/CeTTa.")))))
