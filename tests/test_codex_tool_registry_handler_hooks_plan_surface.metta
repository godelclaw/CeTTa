!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:tool_registry_handler_hooks_plan)
!(import! &self codex:tool_registry_plan)
!(import! &self codex:tool_router_dispatch_plan)
!(import! &self codex:tools)

(= (test:hooks-binding-exec)
   (CodexToolRegistryHandlerBinding
     "exec_command"
     (codex:tool-handler-kind-unified-exec)))

(= (test:hooks-binding-apply-patch)
   (CodexToolRegistryHandlerBinding
     "apply_patch"
     (codex:tool-handler-kind-apply-patch)))

(= (test:hooks-binding-plan)
   (CodexToolRegistryHandlerBinding
     "update_plan"
     (codex:tool-handler-kind-plan)))

(= (test:hooks-invocation $call-id $tool-name $payload)
   (codex:tool-router-tool-invocation
     test-session
     test-turn
     test-cancellation-token
     test-tracker
     $call-id
     (codex:plain-tool-name $tool-name)
     (codex:tool-router-dispatch-source-direct)
     $payload))

(= (test:hooks-exec-output
      $event-call-id
      $process-id
      $hook-command)
   (CodexToolOutputExecCommand
     $event-call-id
     "chunk-1"
     125
     "exec output"
     10000
     $process-id
     0
     2
     $hook-command))

(= (test:hooks-apply-patch-sample)
   "*** Begin Patch\n*** Add File: hello.txt\n+hello\n*** End Patch")

(= (test:hooks-apply-patch-function-json)
   "{\"input\":\"*** Begin Patch\\n*** Add File: hello.txt\\n+hello\\n*** End Patch\"}")

!(assertEqualToResult
  (json-stringify
    (codex:pre-tool-use-payload-json
      (codex:tool-registry-handler-pre-tool-use-payload
        (test:hooks-binding-exec)
        (test:hooks-invocation
          "call-exec"
          "exec_command"
          (codex:tool-router-dispatch-function-payload
            "{\"cmd\":\"echo hi\"}")))))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_input\":{\"command\":\"echo hi\"}}"))

!(assertEqual
  (codex:tool-registry-handler-pre-tool-use-payload
    (test:hooks-binding-exec)
    (test:hooks-invocation
      "call-write"
      "write_stdin"
      (codex:tool-router-dispatch-function-payload
        "{\"session_id\":1,\"chars\":\"x\"}")))
  Empty)

!(assertEqualToResult
  (json-stringify
    (codex:pre-tool-use-payload-json
      (codex:tool-registry-handler-pre-tool-use-payload
        (test:hooks-binding-apply-patch)
        (test:hooks-invocation
          "call-patch"
          "apply_patch"
          (codex:tool-router-dispatch-custom-payload
            (test:hooks-apply-patch-sample))))))
  ("{\"tool_name\":{\"name\":\"apply_patch\",\"matcher_aliases\":[\"Write\",\"Edit\"]},\"tool_input\":{\"command\":\"*** Begin Patch\\n*** Add File: hello.txt\\n+hello\\n*** End Patch\"}}"))

!(assertEqual
  (codex:tool-registry-handler-pre-tool-use-payload
    (test:hooks-binding-plan)
    (test:hooks-invocation
      "call-plan"
      "update_plan"
      (codex:tool-router-dispatch-function-payload "{}")))
  Empty)

!(assertEqualToResult
  (json-stringify
    (codex:post-tool-use-payload-json
      (codex:tool-registry-handler-post-tool-use-payload
        (test:hooks-binding-exec)
        (test:hooks-invocation
          "call-exec"
          "exec_command"
          (codex:tool-router-dispatch-function-payload
            "{\"cmd\":\"echo hi\"}"))
        (test:hooks-exec-output
          ""
          CodexAbsent
          "echo hi"))))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_use_id\":\"call-exec\",\"tool_input\":{\"command\":\"echo hi\"},\"tool_response\":\"exec output\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:post-tool-use-payload-json
      (codex:tool-registry-handler-post-tool-use-payload
        (test:hooks-binding-exec)
        (test:hooks-invocation
          "call-exec"
          "exec_command"
          (codex:tool-router-dispatch-function-payload
            "{\"cmd\":\"echo hi\"}"))
        (test:hooks-exec-output
          "event-call"
          CodexAbsent
          "echo hi"))))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_use_id\":\"event-call\",\"tool_input\":{\"command\":\"echo hi\"},\"tool_response\":\"exec output\"}"))

!(assertEqual
  (codex:tool-registry-handler-post-tool-use-payload
    (test:hooks-binding-exec)
    (test:hooks-invocation
      "call-running"
      "exec_command"
      (codex:tool-router-dispatch-function-payload
        "{\"cmd\":\"sleep 10\"}"))
    (test:hooks-exec-output
      "event-call"
      77
      "sleep 10"))
  Empty)

!(assertEqual
  (codex:tool-registry-handler-post-tool-use-payload
    (test:hooks-binding-exec)
    (test:hooks-invocation
      "call-no-hook"
      "exec_command"
      (codex:tool-router-dispatch-function-payload
        "{\"cmd\":\"echo hi\"}"))
    (test:hooks-exec-output
      ""
      CodexAbsent
      CodexAbsent))
  Empty)

!(assertEqualToResult
  (json-stringify
    (codex:post-tool-use-payload-json
      (codex:tool-registry-handler-post-tool-use-payload
        (test:hooks-binding-apply-patch)
        (test:hooks-invocation
          "call-patch"
          "apply_patch"
          (codex:tool-router-dispatch-function-payload
            (test:hooks-apply-patch-function-json)))
        (CodexToolOutputApplyPatch "Success. Updated files."))))
  ("{\"tool_name\":{\"name\":\"apply_patch\",\"matcher_aliases\":[\"Write\",\"Edit\"]},\"tool_use_id\":\"call-patch\",\"tool_input\":{\"command\":\"*** Begin Patch\\n*** Add File: hello.txt\\n+hello\\n*** End Patch\"},\"tool_response\":\"Success. Updated files.\"}"))
