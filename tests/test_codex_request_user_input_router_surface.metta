!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:tools)

(= (codex-request-user-input-router-input)
   "{\"questions\":[{\"id\":\"choice\",\"header\":\"Pick\",\"question\":\"Choose one.\",\"options\":[{\"label\":\"A (Recommended)\",\"description\":\"Prefer the stable path.\"}]}]}")

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-tool-call-item
        (CodexResponseItemCustomToolCall
          "call-rui-raw"
          "request_user_input"
          (codex-request-user-input-router-input)))))
  ("request_user_input is unavailable in Default mode"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-tool-call-item
        (codex:tool-call
          "call-rui-helper"
          "request_user_input"
          (codex-request-user-input-router-input)))))
  ("request_user_input is unavailable in Default mode"))
