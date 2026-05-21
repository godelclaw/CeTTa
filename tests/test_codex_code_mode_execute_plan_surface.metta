!(register-module! ../codex)
!(import! &self codex:code_mode_execute_plan)
!(import! &self codex:tool_name)

(= (test:enabled-tools)
   ((CodexCodeModeToolDefinition
      "exec_command"
      (CodexToolName "exec_command" CodexAbsent)
      "Run shell command"
      CodexCodeModeToolKindFunction
      CodexAbsent
      CodexAbsent)))

(= (test:stored-values)
   ((JsonPair "previous" (JsonString "value"))))

(= (test:plain-plan)
   (codex:plan-code-mode-execute-invocation
     (codex:plain-tool-name "exec")
     (CodexToolPayloadCustom "text('hi')")
     "call-1"
     "turn-1"
     (test:enabled-tools)
     (test:stored-values)
     "cell-1"))

(= (test:pragma-plan)
   (codex:plan-code-mode-execute-invocation
     (codex:plain-tool-name "exec")
     (CodexToolPayloadCustom
       "// @exec: {\"yield_time_ms\": 12, \"max_output_tokens\": 4}\ntext('hi')")
     "call-2"
     "turn-1"
     (test:enabled-tools)
     ()
     "cell-2"))

!(assertEqualToResult
  (codex:code-mode-execute-public-tool-name)
  ("exec"))

!(assertEqualToResult
  (codex:code-mode-execute-is-tool-name
    (codex:plain-tool-name "exec"))
  (True))

!(assertEqualToResult
  (codex:code-mode-execute-is-tool-name
    (CodexToolName "exec" "mcp__server__"))
  (False))

!(assertEqualToResult
  (codex:code-mode-execute-invocation-plan-request
    (test:plain-plan))
  ((CodexCodeModeExecuteRequest
     "cell-1"
     "call-1"
     ((CodexCodeModeToolDefinition
        "exec_command"
        (CodexToolName "exec_command" CodexAbsent)
        "Run shell command"
        CodexCodeModeToolKindFunction
        CodexAbsent
        CodexAbsent))
     "text('hi')"
     ((JsonPair "previous" (JsonString "value")))
     CodexAbsent
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-execute-invocation-plan-actions
    (test:plain-plan))
  (((CodexCodeModeExecuteActionStartTrace
      "turn-1"
      "cell-1"
      "call-1"
      "text('hi')"))))

!(assertEqualToResult
  (codex:code-mode-execute-request-yield-time-ms
    (codex:code-mode-execute-invocation-plan-request
      (test:pragma-plan)))
  (12))

!(assertEqualToResult
  (codex:code-mode-execute-request-max-output-tokens
    (codex:code-mode-execute-invocation-plan-request
      (test:pragma-plan)))
  (4))

!(assertEqualToResult
  (codex:plan-code-mode-execute-invocation
    (codex:plain-tool-name "exec")
    (CodexToolPayloadCustom "")
    "call-empty"
    "turn-1"
    ()
    ()
    "cell-empty")
  ((CodexFunctionCallErrorRespondToModel
     "exec expects raw JavaScript source text (non-empty). Provide JS only, optionally with first-line `// @exec: {\"yield_time_ms\": 10000, \"max_output_tokens\": 1000}`.")))

!(assertEqualToResult
  (codex:plan-code-mode-execute-invocation
    (codex:plain-tool-name "wait")
    (CodexToolPayloadCustom "text('hi')")
    "call-wrong"
    "turn-1"
    ()
    ()
    "cell-wrong")
  ((CodexFunctionCallErrorRespondToModel
     "exec expects raw JavaScript source text")))

!(assertEqualToResult
  (codex:plan-code-mode-execute-invocation
    (codex:plain-tool-name "exec")
    (CodexToolPayloadFunction "{}")
    "call-function"
    "turn-1"
    ()
    ()
    "cell-function")
  ((CodexFunctionCallErrorRespondToModel
     "exec expects raw JavaScript source text")))

!(assertEqualToResult
  (codex:code-mode-execute-completion-plan-output
    (codex:complete-code-mode-execute-response
      (test:plain-plan)
      (codex:code-mode-runtime-response-yielded
        "cell-1"
        ((codex:code-mode-input-text "partial")))
      0.06
      True))
  ((CodexToolOutputFunction
     ((CodexInputText
        "Script running with cell ID cell-1\nWall time 0.1 seconds\nOutput:\n")
      (CodexInputText "partial"))
     True
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-execute-completion-plan-actions
    (codex:complete-code-mode-execute-response
      (test:plain-plan)
      (codex:code-mode-runtime-response-yielded
        "cell-1"
        ())
      0.06
      True))
  (((CodexCodeModeExecuteActionRecordInitialResponse
      "cell-1"
      (CodexCodeModeRuntimeResponseYielded "cell-1" ())))))

!(assertEqualToResult
  (codex:code-mode-execute-completion-plan-output
    (codex:complete-code-mode-execute-response
      (test:pragma-plan)
      (codex:code-mode-runtime-response-result
        "cell-2"
        ((codex:code-mode-input-text "done"))
        ((JsonPair "answer" (JsonNumber "42")))
        CodexAbsent)
      2.0
      True))
  ((CodexToolOutputFunction
     ((CodexInputText
        "Script completed\nWall time 2.0 seconds\nOutput:\n")
      (CodexInputText "done"))
     True
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-execute-completion-plan-actions
    (codex:complete-code-mode-execute-response
      (test:pragma-plan)
      (codex:code-mode-runtime-response-result
        "cell-2"
        ((codex:code-mode-input-text "done"))
        ((JsonPair "answer" (JsonNumber "42")))
        CodexAbsent)
      2.0
      True))
  (((CodexCodeModeExecuteActionRecordInitialResponse
      "cell-2"
      (CodexCodeModeRuntimeResponseResult
        "cell-2"
        ((CodexCodeModeInputText "done"))
        ((JsonPair "answer" (JsonNumber "42")))
        CodexAbsent))
     (CodexCodeModeExecuteActionRecordEnded
      "cell-2"
      (CodexCodeModeRuntimeResponseResult
        "cell-2"
        ((CodexCodeModeInputText "done"))
        ((JsonPair "answer" (JsonNumber "42")))
        CodexAbsent))
     (CodexCodeModeRuntimeActionReplaceStoredValues
      ((JsonPair "answer" (JsonNumber "42")))))))
