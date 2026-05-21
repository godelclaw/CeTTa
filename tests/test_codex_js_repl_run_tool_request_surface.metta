!(register-module! ../codex)
!(import! &self codex:js_repl_run_tool_request)

(= (test:internal-request)
   (codex:js-repl-kernel-to-host-run-tool
     "tool-1"
     "exec-1"
     "js_repl"
     "{\"code\":\"1 + 1\"}"))

(= (test:internal-result)
   (codex:js-repl-run-tool-request-guard-step
     (test:internal-request)))

!(assertEqual
  (codex:js-repl-run-tool-request-step-result-status
    (test:internal-result))
  CodexJsReplRunToolRequestStatusRejectedInternal)

!(assertEqual
  (codex:js-repl-run-tool-request-step-result-run-tool-result
    (test:internal-result))
  (CodexJsReplRunToolResult
    "tool-1"
    False
    CodexAbsent
    "js_repl cannot invoke itself"))

!(assertEqual
  (codex:js-repl-run-tool-request-step-result-actions
    (test:internal-result))
  ((CodexJsReplRunToolRequestActionLogToolCallResponse
     "js_repl nested tool call completed"
     "exec-1"
     "tool-1"
     "js_repl"
     False
     (CodexJsReplToolCallResponseSummary
       CodexAbsent
       (CodexJsReplToolCallPayloadKindError)
       "js_repl cannot invoke itself"
       28
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent)
     CodexAbsent
     "js_repl cannot invoke itself")))

!(assertEqual
  (codex:js-repl-run-tool-request-step-result-status
    (codex:js-repl-run-tool-request-guard-step
      (codex:js-repl-kernel-to-host-run-tool
        "tool-2"
        "exec-1"
        "js_repl_reset"
        "{}")))
  CodexJsReplRunToolRequestStatusRejectedInternal)

(= (test:continue-result)
   (codex:js-repl-run-tool-request-guard-step
     (codex:js-repl-kernel-to-host-run-tool
       "tool-3"
       "exec-1"
       "shell"
       "{\"cmd\":\"pwd\"}")))

!(assertEqual
  (codex:js-repl-run-tool-request-step-result-status
    (test:continue-result))
  CodexJsReplRunToolRequestStatusContinue)

!(assertEqual
  (codex:js-repl-run-tool-request-step-result-run-tool-result
    (test:continue-result))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-run-tool-request-step-result-actions
    (test:continue-result))
  ())
