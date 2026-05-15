!(register-module! ../codex)
!(import! &self codex:context_fragment)

!(assertEqualToResult
  (codex:apps-instructions-matches-text
    " <APPS_INSTRUCTIONS>\nbody\n</apps_instructions> ")
  (True))
