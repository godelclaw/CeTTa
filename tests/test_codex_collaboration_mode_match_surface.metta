!(register-module! ../codex)
!(import! &self codex:context_fragment)

!(assertEqualToResult
  (codex:collaboration-mode-instructions-matches-text
    "<COLLABORATION_MODE>body</collaboration_mode>")
  (True))
