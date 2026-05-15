!(register-module! ../codex)
!(import! &self codex:event_mapping)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:parse-turn-item
    (codex:response-message
      CodexAbsent
      "user"
      ((CodexInputText
         "# AGENTS.md instructions for test_directory\n\n<INSTRUCTIONS>\ntest_text\n</INSTRUCTIONS>"))
      CodexAbsent))
  (Empty))
