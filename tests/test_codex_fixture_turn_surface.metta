!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:turn)

!(assertEqualToResult
  (codex:fixture-turn-final-response
    (codex:run-fixture-turn
      ((codex:fixture-user-step "u1")
       (codex:fixture-assistant-step "a1"))))
  ("a1"))

!(assertEqualToResult
  (codex:fixture-turn-final-response
    (codex:run-fixture-turn
      ((codex:fixture-user-step "u1")
       (codex:fixture-final-step "final answer")
       (codex:fixture-commentary-step "later commentary"))))
  ("final answer"))

!(assertEqual
  (codex:fixture-turn-final-response
    (codex:run-fixture-turn
      ((codex:fixture-user-step "u1")
       (codex:fixture-commentary-step "commentary only")
       (codex:fixture-tool-call-step "call_1" "exec_command" "{\"cmd\":\"pwd\"}"))))
  Empty)

!(assertEqualToResult
  (let $turn
    (codex:run-fixture-turn
      ((codex:fixture-user-step "Summarize the repo state.")
       (codex:fixture-commentary-step "Inspecting the workspace.")
       (codex:fixture-tool-call-step "call_1" "exec_command" "{\"cmd\":\"pwd\"}")
       (codex:fixture-tool-result-step "call_1" "{\"stdout\":\"/home/zarclaw/repos/CeTTa\\n\"}")
       (codex:fixture-final-step "The workspace root is /home/zarclaw/repos/CeTTa.")))
    (json-stringify (codex:fixture-turn-json $turn)))
  ("{\"items\":[{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"Summarize the repo state.\"}]},{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"Inspecting the workspace.\"}],\"phase\":\"commentary\"},{\"type\":\"custom_tool_call\",\"call_id\":\"call_1\",\"name\":\"exec_command\",\"input\":\"{\\\"cmd\\\":\\\"pwd\\\"}\"},{\"type\":\"custom_tool_call_output\",\"call_id\":\"call_1\",\"output\":\"{\\\"stdout\\\":\\\"/home/zarclaw/repos/CeTTa\\\\n\\\"}\"},{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"The workspace root is /home/zarclaw/repos/CeTTa.\"}],\"phase\":\"final_answer\"}],\"final_response\":\"The workspace root is /home/zarclaw/repos/CeTTa.\"}"))

!(assertEqualToResult
  (let $turn
    (codex:run-fixture-turn
      ((codex:fixture-user-step "u1")
       (codex:fixture-commentary-step "commentary only")))
    (json-stringify (codex:fixture-turn-json $turn)))
  ("{\"items\":[{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"u1\"}]},{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"commentary only\"}],\"phase\":\"commentary\"}],\"final_response\":null}"))
