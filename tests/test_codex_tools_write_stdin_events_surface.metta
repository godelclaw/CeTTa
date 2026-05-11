!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqualToResult
  (json-stringify
    (codex:items-json
      (codex:write-stdin-result-event-items
        (codex:parse-write-stdin-args
          "{\"session_id\":45,\"chars\":\"exit\\n\"}")
        (CodexWriteStdinResultSuccess
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
            "done\n")))))
  ("[{\"type\":\"terminal_interaction\",\"call_id\":\"exec-call-45\",\"process_id\":\"45\",\"stdin\":\"exit\\n\"},{\"type\":\"exec_command_output_delta\",\"call_id\":\"exec-call-45\",\"stream\":\"stdout\",\"chunk\":\"ZG9uZQo=\"}]"))
