!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:turn)

!(println! "=== Codex fixture turn demo ===")
!(println!
  (json-stringify
    (codex:fixture-turn-json
      (codex:run-fixture-turn
        ((codex:fixture-user-step "Summarize the repo state.")
         (codex:fixture-commentary-step "Inspecting the workspace.")
         (codex:fixture-tool-call-step "call_1" "exec_command" "{\"cmd\":\"pwd\"}")
         (codex:fixture-tool-result-step "call_1" "{\"stdout\":\"/home/zarclaw/repos/CeTTa\\n\"}")
         (codex:fixture-final-step "The workspace root is /home/zarclaw/repos/CeTTa."))))))
