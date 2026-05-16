!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:add-to-history-op "Remember this note."))
  ("add_to_history"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:add-to-history-op "Remember this note.")))
  ("{\"type\":\"add_to_history\",\"text\":\"Remember this note.\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:get-history-entry-request-op 7 42))
  ("get_history_entry_request"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:get-history-entry-request-op 7 42)))
  ("{\"type\":\"get_history_entry_request\",\"offset\":7,\"log_id\":42}"))

!(assertEqualToResult
  (codex:op-type
    (codex:list-mcp-tools-op))
  ("list_mcp_tools"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:list-mcp-tools-op)))
  ("{\"type\":\"list_mcp_tools\"}"))

!(assertEqualToResult
  (codex:op-type
    (codex:reload-user-config-op))
  ("reload_user_config"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:reload-user-config-op)))
  ("{\"type\":\"reload_user_config\"}"))
