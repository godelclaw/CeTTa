!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context)
!(import! &self codex:multi_agents_results)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:multi-agent-spawn-agent-result-json
      (codex:multi-agent-spawn-agent-result
        "67e55044-10b1-426f-9247-bb680e5fe0c8"
        "Scout")))
  ("{\"agent_id\":\"67e55044-10b1-426f-9247-bb680e5fe0c8\",\"nickname\":\"Scout\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:multi-agent-spawn-agent-result-json
      (codex:multi-agent-spawn-agent-result
        "67e55044-10b1-426f-9247-bb680e5fe0c8"
        CodexAbsent)))
  ("{\"agent_id\":\"67e55044-10b1-426f-9247-bb680e5fe0c8\",\"nickname\":null}"))

!(assertEqualToResult
  (codex:multi-agent-spawn-agent-result-log-preview
    (codex:multi-agent-spawn-agent-result "thread-a" "Scout"))
  ("{\"agent_id\":\"thread-a\",\"nickname\":\"Scout\"}"))

!(assertEqual
  (codex:multi-agent-spawn-agent-result-success-for-logging
    (codex:multi-agent-spawn-agent-result "thread-a" "Scout"))
  True)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:multi-agent-spawn-agent-result-to-response-item
        (codex:multi-agent-spawn-agent-result "thread-a" "Scout")
        "call-spawn"
        (codex:function-payload "{}"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"call-spawn\",\"output\":\"{\\\"agent_id\\\":\\\"thread-a\\\",\\\"nickname\\\":\\\"Scout\\\"}\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:multi-agent-spawn-agent-result-code-mode-result
      (codex:multi-agent-spawn-agent-result "thread-a" CodexAbsent)))
  ("{\"agent_id\":\"thread-a\",\"nickname\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:multi-agent-send-input-result-json
      (codex:multi-agent-send-input-result "submission-1")))
  ("{\"submission_id\":\"submission-1\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:multi-agent-send-input-result-to-response-item
        (codex:multi-agent-send-input-result "submission-1")
        "call-send"
        (codex:function-payload "{}"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"call-send\",\"output\":\"{\\\"submission_id\\\":\\\"submission-1\\\"}\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:multi-agent-wait-agent-result-json
      (codex:multi-agent-wait-agent-result
        ((codex:multi-agent-wait-status-entry
           "/root/scout"
           (codex:protocol-agent-status-running))
         (codex:multi-agent-wait-status-entry
           "/root/reviewer"
           (codex:protocol-agent-status-errored "tool failed")))
        False)))
  ("{\"status\":{\"/root/scout\":\"running\",\"/root/reviewer\":{\"errored\":\"tool failed\"}},\"timed_out\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:multi-agent-wait-agent-result-json
      (codex:multi-agent-wait-agent-result () True)))
  ("{\"status\":{},\"timed_out\":true}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:multi-agent-wait-agent-result-to-response-item
        (codex:multi-agent-wait-agent-result () True)
        "call-wait"
        (codex:function-payload "{}"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"call-wait\",\"output\":\"{\\\"status\\\":{},\\\"timed_out\\\":true}\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:multi-agent-wait-agent-result-code-mode-result
      (codex:multi-agent-wait-agent-result
        ((codex:multi-agent-wait-status-entry
           "/root/scout"
           (codex:protocol-agent-status-completed "done")))
        False)))
  ("{\"status\":{\"/root/scout\":{\"completed\":\"done\"}},\"timed_out\":false}"))

!(assertEqualToResult
  (json-stringify
    (codex:multi-agent-resume-agent-result-json
      (codex:multi-agent-resume-agent-result
        (codex:protocol-agent-status-shutdown))))
  ("{\"status\":\"shutdown\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:multi-agent-resume-agent-result-to-response-item
        (codex:multi-agent-resume-agent-result
          (codex:protocol-agent-status-running))
        "call-resume"
        (codex:function-payload "{}"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"call-resume\",\"output\":\"{\\\"status\\\":\\\"running\\\"}\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:multi-agent-close-agent-result-json
      (codex:multi-agent-close-agent-result
        (codex:protocol-agent-status-interrupted))))
  ("{\"previous_status\":\"interrupted\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:multi-agent-close-agent-result-to-response-item
        (codex:multi-agent-close-agent-result
          (codex:protocol-agent-status-not-found))
        "call-close"
        (codex:function-payload "{}"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"call-close\",\"output\":\"{\\\"previous_status\\\":\\\"not_found\\\"}\"}"))
