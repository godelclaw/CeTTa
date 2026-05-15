!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context_fragment)
!(import! &self codex:protocol)

!(assertEqual
  (codex:contextual-fragment-render
    (codex:environment-context-fragment
      (codex:environment-context
        "/repo"
        "bash"
        "2026-02-26"
        "America/Los_Angeles"
        CodexAbsent
        CodexAbsent)))
  "<environment_context>\n  <cwd>/repo</cwd>\n  <shell>bash</shell>\n  <current_date>2026-02-26</current_date>\n  <timezone>America/Los_Angeles</timezone>\n</environment_context>")

!(assertEqual
  (codex:contextual-fragment-render
    (codex:environment-context-fragment
      (codex:environment-context
        "/repo"
        "bash"
        "2026-02-26"
        "America/Los_Angeles"
        (codex:environment-network-context
          ("api.example.com" "*.openai.com")
          ("blocked.example.com"))
        CodexAbsent)))
  "<environment_context>\n  <cwd>/repo</cwd>\n  <shell>bash</shell>\n  <current_date>2026-02-26</current_date>\n  <timezone>America/Los_Angeles</timezone>\n  <network enabled=\"true\">\n    <allowed>api.example.com</allowed>\n    <allowed>*.openai.com</allowed>\n    <denied>blocked.example.com</denied>\n  </network>\n</environment_context>")

!(assertEqual
  (codex:contextual-fragment-render
    (codex:environment-context-fragment
      (codex:environment-context
        CodexAbsent
        "bash"
        "2026-02-26"
        "America/Los_Angeles"
        CodexAbsent
        CodexAbsent)))
  "<environment_context>\n  <shell>bash</shell>\n  <current_date>2026-02-26</current_date>\n  <timezone>America/Los_Angeles</timezone>\n</environment_context>")

!(assertEqual
  (codex:contextual-fragment-render
    (codex:environment-context-fragment
      (codex:environment-context-with-subagents
        (codex:environment-context
          "/repo"
          "bash"
          "2026-02-26"
          "America/Los_Angeles"
          CodexAbsent
          CodexAbsent)
        "- agent-1: atlas\n- agent-2")))
  "<environment_context>\n  <cwd>/repo</cwd>\n  <shell>bash</shell>\n  <current_date>2026-02-26</current_date>\n  <timezone>America/Los_Angeles</timezone>\n  <subagents>\n    - agent-1: atlas\n    - agent-2\n  </subagents>\n</environment_context>")

!(assertEqualToResult
  (codex:environment-context-with-subagents
    (codex:environment-context
      "/repo"
      "bash"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    "")
  ((CodexEnvironmentContext
      "/repo"
      "bash"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent)))

!(assertEqualToResult
  (codex:environment-context-equals-except-shell
    (codex:environment-context
      "/repo1"
      "bash"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    (codex:environment-context
      "/repo2"
      "bash"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:environment-context-equals-except-shell
    (codex:environment-context
      "/repo"
      "bash"
      "2026-02-26"
      "America/Los_Angeles"
      CodexAbsent
      CodexAbsent)
    (codex:environment-context
      "/repo"
      "zsh"
      "2026-02-26"
      "America/Los_Angeles"
      CodexAbsent
      CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:environment-context-matches-text
    " <ENVIRONMENT_CONTEXT>\n  <cwd>/repo</cwd>\n</environment_context> ")
  (True))

!(assertEqualToResult
  (codex:is-contextual-user-fragment
    (CodexInputText
      "<environment_context>\n  <cwd>/repo</cwd>\n  <shell>bash</shell>\n</environment_context>"))
  (True))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:contextual-fragment-response-item
        (codex:environment-context-fragment
          (codex:environment-context
            "/repo"
            "bash"
            CodexAbsent
            CodexAbsent
            CodexAbsent
            CodexAbsent)))))
  ("{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"<environment_context>\\n  <cwd>/repo</cwd>\\n  <shell>bash</shell>\\n</environment_context>\"}]}"))
