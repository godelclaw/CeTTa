!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(println! "=== Codex tools demo ===")

!(let $run
    (codex:run-exec-command
      "call_demo"
      "{\"cmd\":\"printf codex-tools-demo\",\"login\":false,\"yield_time_ms\":1000}")
  (println! (codex:exec-command-run-text $run)))

!(let $item
    (codex:run-tool-call-item
      (codex:tool-call
        "call_demo"
        "exec_command"
        "{\"cmd\":\"printf codex-tools-demo\",\"login\":false,\"yield_time_ms\":1000}"))
  (println! (json-stringify (codex:item-json $item))))
