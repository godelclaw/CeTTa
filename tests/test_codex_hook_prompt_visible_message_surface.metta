!(register-module! ../codex)
!(import! &self codex:context_fragment)

!(assertEqualToResult
  (codex:parse-visible-hook-prompt-message
    "msg-1"
    ((CodexInputText "<environment_context>ctx</environment_context>")
     (CodexInputText
       "<hook_prompt hook_run_id=\"hook-run-1\">Retry with care &amp; joy.</hook_prompt>")))
  ((CodexHookPromptItem
      "msg-1"
      ((CodexHookPromptFragment "Retry with care & joy." "hook-run-1")))))
