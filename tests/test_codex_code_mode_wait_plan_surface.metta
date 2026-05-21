!(register-module! ../codex)
!(import! &self codex:code_mode_wait_plan)
!(import! &self codex:tool_name)

(= (test:minimal-wait-args)
   (codex:code-mode-wait-parse-result-value
     (codex:parse-code-mode-wait-arguments
       "{\"cell_id\":\"cell-1\"}")))

(= (test:full-wait-args)
   (codex:code-mode-wait-parse-result-value
     (codex:parse-code-mode-wait-arguments
       "{\"cell_id\":\"cell-2\",\"yield_time_ms\":25,\"max_tokens\":5,\"terminate\":true,\"ignored\":1}")))

!(assertEqualToResult
  (codex:code-mode-wait-tool-name)
  ("wait"))

!(assertEqualToResult
  (codex:code-mode-default-wait-yield-time-ms)
  (10000))

!(assertEqualToResult
  (test:minimal-wait-args)
  ((CodexCodeModeWaitArgs
     "cell-1"
     10000
     CodexAbsent
     False)))

!(assertEqualToResult
  (test:full-wait-args)
  ((CodexCodeModeWaitArgs
     "cell-2"
     25
     5
     True)))

!(assertEqualToResult
  (codex:code-mode-wait-args-max-tokens
    (codex:code-mode-wait-parse-result-value
      (codex:parse-code-mode-wait-arguments
        "{\"cell_id\":\"cell-3\",\"max_tokens\":null}")))
  (CodexAbsent))

!(assertEqualToResult
  (codex:code-mode-wait-parse-result-error
    (codex:parse-code-mode-wait-arguments "{}"))
  ("failed to parse function arguments: missing field `cell_id`"))

!(assertEqualToResult
  (codex:code-mode-wait-parse-result-error
    (codex:parse-code-mode-wait-arguments
      "{\"cell_id\":\"cell-4\",\"terminate\":null}"))
  ("failed to parse function arguments: invalid type for field `terminate`: expected bool"))

!(assertEqualToResult
  (codex:code-mode-wait-invocation-plan-request
    (codex:plan-code-mode-wait-invocation
      (codex:plain-tool-name "wait")
      (CodexToolPayloadFunction
        "{\"cell_id\":\"cell-5\",\"terminate\":true}")))
  ((CodexCodeModeWaitRequest "cell-5" 10000 True)))

!(assertEqualToResult
  (codex:code-mode-wait-invocation-plan-max-tokens
    (codex:plan-code-mode-wait-invocation
      (codex:plain-tool-name "wait")
      (CodexToolPayloadFunction
        "{\"cell_id\":\"cell-5\",\"max_tokens\":7}")))
  (7))

!(assertEqualToResult
  (codex:plan-code-mode-wait-invocation
    (codex:plain-tool-name "exec")
    (CodexToolPayloadFunction "{}"))
  ((CodexFunctionCallErrorRespondToModel
     "wait expects JSON arguments")))

!(assertEqualToResult
  (codex:plan-code-mode-wait-invocation
    (codex:plain-tool-name "wait")
    (CodexToolPayloadCustom "{}"))
  ((CodexFunctionCallErrorRespondToModel
     "wait expects JSON arguments")))

!(assertEqualToResult
  (codex:code-mode-wait-completion-plan-output
    (codex:complete-code-mode-wait-response
      (test:full-wait-args)
      (codex:code-mode-wait-outcome-live-cell
        (codex:code-mode-runtime-response-yielded
          "cell-2"
          ((codex:code-mode-input-text "more output"))))
      "turn-1"
      True
      1.11))
  ((CodexToolOutputFunction
     ((CodexInputText
        "Script running with cell ID cell-2\nWall time 1.1 seconds\nOutput:\n")
      (CodexInputText "more output"))
     True
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-wait-completion-plan-actions
    (codex:complete-code-mode-wait-response
      (test:full-wait-args)
      (codex:code-mode-wait-outcome-live-cell
        (codex:code-mode-runtime-response-yielded
          "cell-2"
          ()))
      "turn-1"
      True
      1.11))
  (()))

!(assertEqualToResult
  (codex:code-mode-wait-completion-plan-actions
    (codex:complete-code-mode-wait-response
      (test:minimal-wait-args)
      (codex:code-mode-wait-outcome-live-cell
        (codex:code-mode-runtime-response-terminated
          "cell-3"
          ()))
      "turn-1"
      True
      2.0))
  (((CodexCodeModeWaitActionRecordEnded
      "turn-1"
      "cell-3"
      (CodexCodeModeRuntimeResponseTerminated "cell-3" ())))))

!(assertEqualToResult
  (codex:code-mode-wait-completion-plan-output
    (codex:complete-code-mode-wait-response
      (test:minimal-wait-args)
      (codex:code-mode-wait-outcome-missing-cell
        (codex:code-mode-wait-missing-cell-response "gone"))
      "turn-2"
      True
      0.24))
  ((CodexToolOutputFunction
     ((CodexInputText
        "Script failed\nWall time 0.2 seconds\nOutput:\n")
      (CodexInputText "Script error:\nexec cell gone not found"))
     False
     CodexAbsent)))

!(assertEqualToResult
  (codex:code-mode-wait-completion-plan-actions
    (codex:complete-code-mode-wait-response
      (test:minimal-wait-args)
      (codex:code-mode-wait-outcome-missing-cell
        (codex:code-mode-wait-missing-cell-response "gone"))
      "turn-2"
      True
      0.24))
  (((CodexCodeModeRuntimeActionReplaceStoredValues ()))))
