!(register-module! ../codex)
!(import! &self codex:tools)

!(assertEqualToResult
  (codex:is-string-contains
    (codex:format-exec-command-output
      "call_1"
      1000
      False
      0
      True
      0
      "hello"
      10000
      2)
    "Process exited with code 0")
  (True))
