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
        CodexAbsent
        "bash"
        "2026-02-26"
        "America/Los_Angeles"
        CodexAbsent
        CodexAbsent)))
  "<environment_context>\n  <shell>bash</shell>\n  <current_date>2026-02-26</current_date>\n  <timezone>America/Los_Angeles</timezone>\n</environment_context>")

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
