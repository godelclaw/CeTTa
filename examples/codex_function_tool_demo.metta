!(register-module! ../codex)
!(import! &self codex:function_tool)

!(println! "=== Codex function tool demo ===")
!(println!
  (codex:function-call-error-display
    (codex:function-call-error-respond-to-model "bad input")))
!(println!
  (codex:function-call-error-display
    (codex:function-call-error-missing-local-shell-call-id)))
!(println!
  (codex:function-call-error-display
    (codex:function-call-error-fatal "disk failed")))
