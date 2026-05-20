!(register-module! ../codex)
!(import! &self codex:format_env_display)

!(assertEqualToResult
  (codex:format-env-display CodexAbsent ())
  ("-"))

!(assertEqualToResult
  (codex:format-env-display () ())
  ("-"))

!(assertEqualToResult
  (codex:format-env-display
    ((codex:format-env-display-entry "B" "two")
     (codex:format-env-display-entry "A" "one"))
    ())
  ("A=*****, B=*****"))

!(assertEqualToResult
  (codex:format-env-display
    CodexAbsent
    ("TOKEN" "PATH"))
  ("TOKEN=*****, PATH=*****"))

!(assertEqualToResult
  (codex:format-env-display
    ((codex:format-env-display-entry "HOME" "/tmp"))
    ("TOKEN"))
  ("HOME=*****, TOKEN=*****"))

!(assertEqualToResult
  (codex:format-env-display-entry-key
    (codex:format-env-display-entry "HOME" "/tmp"))
  ("HOME"))

!(assertEqualToResult
  (codex:format-env-display-entry-value
    (codex:format-env-display-entry "HOME" "/tmp"))
  ("/tmp"))
