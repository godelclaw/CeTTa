!(register-module! ../codex)
!(import! &self codex:event_mapping)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:parse-turn-item
    (codex:response-message
      "msg-1"
      "user"
      ((CodexInputText
          "<hook_prompt hook_run_id=\"hook-run-1\">Retry with tests.</hook_prompt>"))
      CodexAbsent))
  ((CodexTurnItemHookPrompt
      (CodexHookPromptItem
        "msg-1"
        ((CodexHookPromptFragment "Retry with tests." "hook-run-1"))))))

!(assertEqualToResult
  (codex:parse-turn-item
    (codex:response-message
      CodexAbsent
      "user"
      ((CodexInputText "<environment_context>ctx</environment_context>")
       (CodexInputText
         "<hook_prompt hook_run_id=\"hook-run-1\">Retry with care &amp; joy.</hook_prompt>"))
      CodexAbsent))
  ((CodexTurnItemHookPrompt
      (CodexHookPromptItem
        CodexAbsent
        ((CodexHookPromptFragment "Retry with care & joy." "hook-run-1"))))))
