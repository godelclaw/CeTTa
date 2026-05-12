!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:function-tool-result
        "call_fn_1"
        (codex:function-call-output-text "ok"))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"call_fn_1\",\"output\":\"ok\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:function-tool-result
      "call_fn_1"
      (codex:function-call-output-text "ok")))
  ("function_call_output"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:function-tool-result
        "call_fn_2"
        (codex:function-call-output-content-items
          ((CodexInputText "line 1")
           (codex:input-image "data:image/png;base64,AAA" "original")
           (CodexInputText "line 2"))))))
  ("{\"type\":\"function_call_output\",\"call_id\":\"call_fn_2\",\"output\":[{\"type\":\"input_text\",\"text\":\"line 1\"},{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,AAA\",\"detail\":\"original\"},{\"type\":\"input_text\",\"text\":\"line 2\"}]}"))
