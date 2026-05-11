!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqualToResult
  (codex:duration-ms-to-seconds-text 1250)
  ("1.2500"))
