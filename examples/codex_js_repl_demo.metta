!(register-module! ../codex)
!(import! &self codex:js_repl)

!(println! "=== Codex js_repl demo ===")
!(println!
  (codex:run-js-repl-handler
    True
    (CodexToolPayloadCustom "console.log('ok');")))
!(println!
  (codex:emit-js-repl-exec-end-event
    "call-js"
    "turn-js"
    "/repo"
    "ok"
    CodexAbsent
    12))
