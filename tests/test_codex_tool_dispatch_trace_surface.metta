!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context)
!(import! &self codex:tool_dispatch_trace)
!(import! &self codex:tool_name)

!(assertEqualToResult
  (codex:tool-dispatch-invocation-from-input
    (codex:tool-dispatch-invocation-input
      "thread-1"
      "turn-1"
      "call-1"
      (codex:plain-tool-name "exec_command")
      (codex:tool-call-source-direct)
      (codex:function-payload "{\"cmd\":\"pwd\"}")))
  ((CodexToolDispatchInvocation
     "thread-1"
     "turn-1"
     "call-1"
     "exec_command"
     CodexAbsent
     (CodexToolDispatchRequesterModel "call-1")
     (CodexToolDispatchPayloadFunction "{\"cmd\":\"pwd\"}"))))

!(assertEqualToResult
  (codex:tool-dispatch-invocation-from-input
    (codex:tool-dispatch-invocation-input
      "thread-1"
      "turn-1"
      "call-2"
      (codex:namespaced-tool-name "mcp__server" "read_file")
      (codex:tool-call-source-code-mode "cell-1" "runtime-tool-1")
      (codex:mcp-payload "server" "read_file" "{}")))
  ((CodexToolDispatchInvocation
     "thread-1"
     "turn-1"
     "call-2"
     "read_file"
     "mcp__server"
     (CodexToolDispatchRequesterCodeCell "cell-1" "runtime-tool-1")
     (CodexToolDispatchPayloadMcp "server" "read_file" "{}"))))

!(assertEqual
  (codex:tool-dispatch-invocation-from-input
    (codex:tool-dispatch-invocation-input
      "thread-1"
      "turn-1"
      "call-js"
      (codex:plain-tool-name "test_tool")
      (codex:tool-call-source-js-repl)
      (codex:function-payload "{}")))
  CodexAbsent)

!(assertEqual
  (codex:tool-dispatch-suppresses-trace
    (codex:tool-dispatch-invocation
      "thread-1"
      "turn-1"
      "call-1"
      "exec"
      CodexAbsent
      (codex:tool-dispatch-requester-model "call-1")
      (codex:tool-dispatch-custom-payload "1 + 1")))
  True)

!(assertEqual
  (codex:tool-dispatch-suppresses-trace
    (codex:tool-dispatch-invocation
      "thread-1"
      "turn-1"
      "call-2"
      "custom_tool"
      CodexAbsent
      (codex:tool-dispatch-requester-model "call-2")
      (codex:tool-dispatch-custom-payload "payload")))
  False)

!(assertEqual
  (codex:tool-dispatch-suppresses-trace
    (codex:tool-dispatch-invocation
      "thread-1"
      "turn-1"
      "call-3"
      "exec"
      "mcp__server"
      (codex:tool-dispatch-requester-model "call-3")
      (codex:tool-dispatch-custom-payload "payload")))
  False)

!(assertEqualToResult
  ((codex:tool-dispatch-kind
     "anything"
     (codex:tool-dispatch-mcp-payload "server" "search" "{}"))
   (codex:tool-dispatch-kind
     "shell_command"
     (codex:tool-dispatch-function-payload "{}"))
   (codex:tool-dispatch-kind
     "wait_agent"
     (codex:tool-dispatch-function-payload "{}"))
   (codex:tool-dispatch-kind
     "unknown_tool"
     (codex:tool-dispatch-function-payload "{}")))
  (((CodexToolDispatchKindMcp "server" "search")
    (CodexToolDispatchKindExecCommand)
    (CodexToolDispatchKindWaitAgent)
    (CodexToolDispatchKindOther "unknown_tool"))))

!(assertEqualToResult
  ((codex:tool-dispatch-label
     "ignored"
     CodexAbsent
     (codex:tool-dispatch-mcp-payload "server" "search" "{}"))
   (codex:tool-dispatch-label
     "read_file"
     "mcp__server"
     (codex:tool-dispatch-function-payload "{}"))
   (codex:tool-dispatch-label
     "exec_command"
     CodexAbsent
     (codex:tool-dispatch-function-payload "{}")))
  (("mcp:server:search" "mcp__server.read_file" "exec_command")))

!(assertEqual
  (codex:tool-dispatch-truncate-preview
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
  "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa...")

!(assertEqual
  (json-stringify
    (codex:tool-dispatch-payload-json
      (codex:tool-dispatch-tool-search-payload "calendar" CodexAbsent)))
  "{\"type\":\"tool_search\",\"arguments\":{\"query\":\"calendar\"}}")

!(assertEqual
  (json-stringify
    (codex:tool-dispatch-payload-json
      (codex:tool-dispatch-local-shell-payload
        ("pwd")
        "/tmp"
        1000
        "require_escalated"
        ("pwd")
        (JsonObject
          ((JsonPair "network"
             (JsonObject
               ((JsonPair "enabled" (JsonBool True)))))))
        "need cwd")))
  "{\"type\":\"local_shell\",\"command\":[\"pwd\"],\"workdir\":\"/tmp\",\"timeout_ms\":1000,\"sandbox_permissions\":\"require_escalated\",\"prefix_rule\":[\"pwd\"],\"additional_permissions\":{\"network\":{\"enabled\":true}},\"justification\":\"need cwd\"}")

!(assertEqualToResult
  (codex:tool-dispatch-start-trace
    (codex:tool-dispatch-invocation
      "thread-1"
      "turn-1"
      "call-1"
      "exec_command"
      CodexAbsent
      (codex:tool-dispatch-requester-model "call-1")
      (codex:tool-dispatch-function-payload "{\"cmd\":\"pwd\"}")))
  ((CodexToolDispatchStartedEvent
     (CodexToolDispatchKindExecCommand)
     "exec_command"
     "{\"cmd\":\"pwd\"}"
     (CodexToolDispatchRequesterFields
       "call-1"
       CodexAbsent
       (CodexToolDispatchRawRequesterModel))
     (JsonObject
       ((JsonPair "type" (JsonString "function"))
        (JsonPair "arguments" (JsonString "{\"cmd\":\"pwd\"}")))))))

!(assertEqual
  (codex:tool-dispatch-start-trace
    (codex:tool-dispatch-invocation
      "thread-1"
      "turn-1"
      "call-1"
      "exec"
      CodexAbsent
      (codex:tool-dispatch-requester-model "call-1")
      (codex:tool-dispatch-custom-payload "1 + 1")))
  CodexAbsent)

!(assertEqualToResult
  (codex:tool-dispatch-record-completed
    True
    (codex:tool-call-source-direct)
    "call-1"
    (codex:function-payload "{}")
    (codex:function-tool-output-from-text "ok" True))
  ((CodexToolDispatchCompletedEvent
     (CodexToolDispatchExecutionStatusCompleted)
     (CodexToolDispatchResultDirectResponse
       (CodexResponseItemFunctionCallOutput
         "call-1"
         (CodexFunctionCallOutputText "ok"))))))

!(assertEqualToResult
  (codex:tool-dispatch-record-completed
    True
    (codex:tool-call-source-code-mode "cell-1" "runtime-tool-1")
    "call-1"
    (codex:function-payload "{}")
    (codex:function-tool-output-from-text "ok" False))
  ((CodexToolDispatchCompletedEvent
     (CodexToolDispatchExecutionStatusFailed)
     (CodexToolDispatchResultCodeModeResponse
       (JsonString "ok")))))

!(assertEqual
  (codex:tool-dispatch-record-completed
    False
    (codex:tool-call-source-direct)
    "call-1"
    (codex:function-payload "{}")
    (codex:function-tool-output-from-text "ok" True))
  CodexAbsent)

!(assertEqual
  (codex:tool-dispatch-record-completed
    True
    (codex:tool-call-source-js-repl)
    "call-1"
    (codex:function-payload "{}")
    (codex:function-tool-output-from-text "ok" True))
  CodexAbsent)

!(assertEqualToResult
  (codex:tool-dispatch-record-failed True "missing tool")
  ((CodexToolDispatchCompletedEvent
     (CodexToolDispatchExecutionStatusFailed)
     (CodexToolDispatchResultError "missing tool"))))
