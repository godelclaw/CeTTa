!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:exec-command-output-delta-event
        "call21"
        "stdout"
        "hello")))
  ("{\"type\":\"exec_command_output_delta\",\"call_id\":\"call21\",\"stream\":\"stdout\",\"chunk\":\"aGVsbG8=\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:terminal-interaction-event
        "exec-call-45"
        "45"
        "exit\n")))
  ("{\"type\":\"terminal_interaction\",\"call_id\":\"exec-call-45\",\"process_id\":\"45\",\"stdin\":\"exit\\n\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:terminal-interaction-event "exec-call-45" "45" "exit\n"))
  ("terminal_interaction"))
