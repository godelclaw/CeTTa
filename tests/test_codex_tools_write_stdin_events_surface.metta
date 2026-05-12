!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqual
  (json-stringify
    (codex:items-json
      ((codex:terminal-interaction-event
          "exec-call-45"
          "45"
          "exit\n"))))
  "[{\"type\":\"terminal_interaction\",\"call_id\":\"exec-call-45\",\"process_id\":\"45\",\"stdin\":\"exit\\n\"}]")

!(assertEqual
  (json-stringify
    (codex:items-json
      (codex:exec-command-run-output-delta-items
        (CodexExecCommandRun
          "exec-call-45"
          "chunk-2"
          "cat"
          10000
          False
          0
          True
          0
          "done\n"
          ""
          "done\n"
          498
          2
          "done\n"))))
  "[{\"type\":\"exec_command_output_delta\",\"call_id\":\"exec-call-45\",\"stream\":\"stdout\",\"chunk\":\"ZG9uZQo=\"}]")
