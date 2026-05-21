!(register-module! ../codex)
!(import! &self codex:function_tool)

!(assertEqual
  (codex:function-call-error-respond-to-model "bad input")
  (CodexFunctionCallErrorRespondToModel "bad input"))

!(assertEqual
  (codex:function-call-error-missing-local-shell-call-id)
  (CodexFunctionCallErrorMissingLocalShellCallId))

!(assertEqual
  (codex:function-call-error-fatal "disk failed")
  (CodexFunctionCallErrorFatal "disk failed"))

!(assertEqual
  (codex:function-call-error-display
    (codex:function-call-error-respond-to-model "bad input"))
  "bad input")

!(assertEqual
  (codex:function-call-error-display
    (codex:function-call-error-missing-local-shell-call-id))
  "LocalShellCall without call_id or id")

!(assertEqual
  (codex:function-call-error-display
    (codex:function-call-error-fatal "disk failed"))
  "Fatal error: disk failed")
