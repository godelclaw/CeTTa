!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:context)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-output-to-response-item
        (codex:function-tool-output-from-text "ok" True)
        "fn-1"
        (codex:function-payload "{}"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"fn-1\",\"output\":\"ok\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:tool-output-to-response-item
        (codex:function-tool-output-from-text "patched" True)
        "call-42"
        (codex:custom-payload "patch"))))
  ("{\"type\":\"custom_tool_call_output\",\"call_id\":\"call-42\",\"output\":\"patched\"}"))

!(assertEqualToResult
  (codex:tool-payload-log-payload
    (codex:local-shell-payload ("bash" "-lc" "pwd")))
  ("bash -lc pwd"))

!(assertEqualToResult
  (json-stringify
    (codex:response-input-to-code-mode-result
      (CodexResponseItemMessage
        "assistant"
        ((CodexOutputText "line 1")
         (CodexInputImage "data:image/png;base64,AAA" CodexAbsent)
         (CodexOutputText "line 2"))
        CodexAbsent)))
  ("\"line 1\\ndata:image/png;base64,AAA\\nline 2\""))

!(assertEqualToResult
  (json-stringify
    (codex:tool-output-code-mode-result
      (codex:apply-patch-tool-output-from-text "done")
      (codex:custom-payload "patch")))
  ("{}"))

!(assertEqualToResult
  (codex:tool-output-success-for-logging
    (codex:function-tool-output-from-text "ok" CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:tool-output-success-for-logging
    (codex:aborted-tool-output "cancelled"))
  (False))
