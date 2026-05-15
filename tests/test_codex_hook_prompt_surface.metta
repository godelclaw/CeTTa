!(register-module! ../codex)
!(import! &self json)
!(import! &self str)
!(import! &self codex:context_fragment)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:serialize-hook-prompt-fragment
    (codex:hook-prompt-fragment
      "Retry with care & joy."
      "hook-run-1"))
  ("<hook_prompt hook_run_id=\"hook-run-1\">Retry with care &amp; joy.</hook_prompt>"))

!(assertEqualToResult
  (codex:parse-hook-prompt-fragment
    "<hook_prompt hook_run_id=\"hook-run-1\">Retry with tests.</hook_prompt>")
  ((CodexHookPromptFragment "Retry with tests." "hook-run-1")))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:build-hook-prompt-message
        ((codex:hook-prompt-fragment
            "Retry with care & joy."
            "hook-run-1")))))
  ("{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"<hook_prompt hook_run_id=\\\"hook-run-1\\\">Retry with care &amp; joy.</hook_prompt>\"}]}"))

!(assertEqual
  (str-find
    (codex:message-text
      (codex:build-hook-prompt-message
        ((codex:hook-prompt-fragment
            "Retry with \"waves\" & <tides>"
            "hook-run-1"))))
    "&quot;waves&quot; & <tides>")
  Empty)

!(assertEqualToResult
  (codex:parse-hook-prompt-fragment
    (codex:message-text
      (codex:build-hook-prompt-message
        ((codex:hook-prompt-fragment
            "Retry with \"waves\" & <tides>"
            "hook-run-1")))))
  ((CodexHookPromptFragment "Retry with \"waves\" & <tides>" "hook-run-1")))

!(assertEqualToResult
  (codex:parse-visible-hook-prompt-message
    "msg-1"
    ((CodexInputText "<environment_context>ctx</environment_context>")
     (CodexInputText
       "<hook_prompt hook_run_id=\"hook-run-1\">Retry with care &amp; joy.</hook_prompt>")))
  ((CodexHookPromptItem
      "msg-1"
      ((CodexHookPromptFragment "Retry with care & joy." "hook-run-1")))))

!(assertEqualToResult
  (codex:parse-visible-hook-prompt-message
    CodexAbsent
    ((CodexInputText
        "<hook_prompt hook_run_id=\"hook-run-1\">Retry with tests.</hook_prompt>")
     (CodexInputText
       "<hook_prompt hook_run_id=\"hook-run-2\">Then summarize cleanly.</hook_prompt>")))
  ((CodexHookPromptItem
      CodexAbsent
      ((CodexHookPromptFragment "Retry with tests." "hook-run-1")
       (CodexHookPromptFragment "Then summarize cleanly." "hook-run-2")))))

!(assertEqualToResult
  (codex:is-contextual-user-fragment
    (CodexInputText
      "<hook_prompt hook_run_id=\"hook-run-1\">Retry with tests.</hook_prompt>"))
  (True))

!(assertEqualToResult
  (codex:is-memory-excluded-contextual-user-fragment
    (CodexInputText
      "<hook_prompt hook_run_id=\"hook-run-1\">Retry with tests.</hook_prompt>"))
  (False))

!(assertEqual
  (codex:parse-visible-hook-prompt-message
    "msg-1"
    ((CodexInputImage "data:image/png;base64,Zm9v" CodexAbsent)))
  Empty)

!(assertEqual
  (codex:build-hook-prompt-message
    ((codex:hook-prompt-fragment "ignored" "  ")))
  Empty)
