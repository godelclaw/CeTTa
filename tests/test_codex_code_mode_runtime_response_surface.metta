!(register-module! ../codex)
!(import! &self codex:code_mode_runtime_response)

!(assertEqualToResult
  (codex:code-mode-format-script-status
    (codex:code-mode-runtime-response-yielded
      "cell-1"
      ()))
  ("Script running with cell ID cell-1"))

!(assertEqualToResult
  (codex:code-mode-format-script-status
    (codex:code-mode-runtime-response-terminated
      "cell-1"
      ()))
  ("Script terminated"))

!(assertEqualToResult
  (codex:code-mode-format-script-status
    (codex:code-mode-runtime-response-result
      "cell-1"
      ()
      ()
      CodexAbsent))
  ("Script completed"))

!(assertEqualToResult
  (codex:code-mode-format-script-status
    (codex:code-mode-runtime-response-result
      "cell-1"
      ()
      ()
      "boom"))
  ("Script failed"))

!(assertEqualToResult
  (codex:code-mode-runtime-response-header
    "Script completed"
    1.24)
  ("Script completed\nWall time 1.2 seconds\nOutput:\n"))

!(assertEqualToResult
  (codex:code-mode-runtime-response-plan-output
    (codex:handle-code-mode-runtime-response
      (codex:code-mode-runtime-response-yielded
        "cell-7"
        ((codex:code-mode-input-text "partial output")))
      True
      CodexAbsent
      0.04))
  ((CodexToolOutputFunction
     ((CodexInputText
        "Script running with cell ID cell-7\nWall time 0.0 seconds\nOutput:\n")
      (CodexInputText "partial output"))
     True
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-runtime-response-plan-output
    (codex:handle-code-mode-runtime-response
      (codex:code-mode-runtime-response-terminated
        "cell-8"
        ())
      True
      CodexAbsent
      2.66))
  ((CodexToolOutputFunction
     ((CodexInputText
        "Script terminated\nWall time 2.7 seconds\nOutput:\n"))
     True
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-runtime-response-plan-output
    (codex:handle-code-mode-runtime-response
      (codex:code-mode-runtime-response-result
        "cell-9"
        ((codex:code-mode-input-text "done"))
        ((JsonPair "answer" (JsonNumber "42")))
        CodexAbsent)
      True
      CodexAbsent
      3.0))
  ((CodexToolOutputFunction
     ((CodexInputText
        "Script completed\nWall time 3.0 seconds\nOutput:\n")
      (CodexInputText "done"))
     True
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-runtime-response-plan-actions
    (codex:handle-code-mode-runtime-response
      (codex:code-mode-runtime-response-result
        "cell-9"
        ((codex:code-mode-input-text "done"))
        ((JsonPair "answer" (JsonNumber "42")))
        CodexAbsent)
      True
      CodexAbsent
      3.0))
  (((CodexCodeModeRuntimeActionReplaceStoredValues
      ((JsonPair "answer" (JsonNumber "42")))))))

!(assertEqualToResult
  (codex:code-mode-runtime-response-plan-output
    (codex:handle-code-mode-runtime-response
      (codex:code-mode-runtime-response-result
        "cell-10"
        ((codex:code-mode-input-text "before error"))
        ()
        "ReferenceError: x is not defined")
      True
      CodexAbsent
      4.01))
  ((CodexToolOutputFunction
     ((CodexInputText
        "Script failed\nWall time 4.0 seconds\nOutput:\n")
      (CodexInputText "before error")
      (CodexInputText
        "Script error:\nReferenceError: x is not defined"))
     False
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-runtime-response-plan-output
    (codex:handle-code-mode-runtime-response
      (codex:code-mode-runtime-response-yielded
        "cell-11"
        ((codex:code-mode-input-image
           "data:image/png;base64,AAA"
           "original")))
      False
      CodexAbsent
      0.0))
  ((CodexToolOutputFunction
     ((CodexInputText
        "Script running with cell ID cell-11\nWall time 0.0 seconds\nOutput:\n")
      (CodexInputImage "data:image/png;base64,AAA" "high"))
     True
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-truncate-runtime-result
    ((CodexInputText "abcdefghij"))
    1)
  (((CodexInputText "Total output lines: 1\n\nab…2 tokens truncated…ij"))))
