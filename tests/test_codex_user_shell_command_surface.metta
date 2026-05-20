!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:user_shell_command)

(= (test-user-shell-output
      $exit-code
      $stdout
      $stderr
      $aggregated-output
      $duration-ms
      $timed-out)
   (codex:exec-tool-call-output
     $exit-code
     $stdout
     $stderr
     $aggregated-output
     $duration-ms
     $timed-out))

!(assertEqualToResult
  (codex:user-shell-command-matches-text
    "<user_shell_command>\necho hi\n</user_shell_command>")
  (True))

!(assertEqualToResult
  (codex:user-shell-command-matches-text "echo hi")
  (False))

!(assertEqualToResult
  (codex:format-user-shell-command-record
    "echo hi"
    (test-user-shell-output 0 "hi" "" "hi" 1000 False)
    10000)
  ("<user_shell_command>\n<command>\necho hi\n</command>\n<result>\nExit code: 0\nDuration: 1.0000 seconds\nOutput:\nhi\n</result>\n</user_shell_command>"))

!(assertEqualToResult
  (codex:format-user-shell-command-record
    "false"
    (test-user-shell-output
      42
      "stdout-only"
      "stderr-only"
      "combined output wins"
      120
      False)
    10000)
  ("<user_shell_command>\n<command>\nfalse\n</command>\n<result>\nExit code: 42\nDuration: 0.1200 seconds\nOutput:\ncombined output wins\n</result>\n</user_shell_command>"))

!(assertEqualToResult
  (codex:format-user-shell-command-record
    "sleep 2"
    (test-user-shell-output
      -1
      ""
      "partial stderr"
      "partial output"
      1500
      True)
    10000)
  ("<user_shell_command>\n<command>\nsleep 2\n</command>\n<result>\nExit code: -1\nDuration: 1.5000 seconds\nOutput:\ncommand timed out after 1500 milliseconds\npartial output\n</result>\n</user_shell_command>"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:user-shell-command-record-item
        "pwd"
        (test-user-shell-output 0 "out" "" "out" 250 False)
        10000)))
  ("{\"type\":\"message\",\"role\":\"user\",\"content\":[{\"type\":\"input_text\",\"text\":\"<user_shell_command>\\n<command>\\npwd\\n</command>\\n<result>\\nExit code: 0\\nDuration: 0.2500 seconds\\nOutput:\\nout\\n</result>\\n</user_shell_command>\"}]}"))

!(assertEqualToResult
  (codex:user-shell-format-exec-output-str
    (test-user-shell-output
      0
      ""
      ""
      "alpha\nbeta\ngamma\ndelta\n"
      50
      False)
    2)
  ("Total output lines: 4\n\nalph…4 tokens truncated…lta\n"))
