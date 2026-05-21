!(register-module! ../codex)
!(import! &self codex:code_mode_exec_source)
!(import! &self codex:tool_name)

!(assertEqual
  (codex:code-mode-exec-source-parse-result-value
    (codex:parse-code-mode-exec-source "text('hi')"))
  (CodexCodeModeParsedExecSource
    "text('hi')"
    CodexAbsent
    CodexAbsent))

!(assertEqual
  (codex:code-mode-exec-source-parse-result-value
    (codex:parse-code-mode-exec-source
      "// @exec: {\"yield_time_ms\": 10}\ntext('hi')"))
  (CodexCodeModeParsedExecSource
    "text('hi')"
    10
    CodexAbsent))

!(assertEqual
  (codex:code-mode-exec-source-parse-result-value
    (codex:parse-code-mode-exec-source
      "   // @exec: {\"yield_time_ms\": 15000, \"max_output_tokens\": 2000}\noutput_text('ok');"))
  (CodexCodeModeParsedExecSource
    "output_text('ok');"
    15000
    2000))

!(assertEqual
  (codex:code-mode-exec-source-parse-result-error
    (codex:parse-code-mode-exec-source "  \n\t"))
  (codex:code-mode-exec-source-empty-input-message))

!(assertEqual
  (codex:code-mode-exec-source-parse-result-error
    (codex:parse-code-mode-exec-source
      "// @exec: {\"yield_time_ms\": 10}"))
  "exec pragma must be followed by JavaScript source on subsequent lines")

!(assertEqual
  (codex:code-mode-exec-source-parse-result-error
    (codex:parse-code-mode-exec-source
      "// @exec:\ntext('hi')"))
  (codex:code-mode-exec-source-object-message))

!(assertEqual
  (codex:code-mode-exec-source-parse-result-error
    (codex:parse-code-mode-exec-source
      "// @exec: []\ntext('hi')"))
  (codex:code-mode-exec-source-object-message))

!(assertEqual
  (codex:code-mode-exec-source-parse-result-error
    (codex:parse-code-mode-exec-source
      "// @exec: {bad}\ntext('hi')"))
  "exec pragma must be valid JSON with supported fields `yield_time_ms` and `max_output_tokens`: expected JSON string")

!(assertEqual
  (codex:code-mode-exec-source-parse-result-error
    (codex:parse-code-mode-exec-source
      "// @exec: {\"nope\": 1}\ntext('hi')"))
  "exec pragma only supports `yield_time_ms` and `max_output_tokens`; got `nope`")

!(assertEqual
  (codex:code-mode-exec-source-parse-result-error
    (codex:parse-code-mode-exec-source
      "// @exec: {\"yield_time_ms\": 9007199254740992}\ntext('hi')"))
  "exec pragma field `yield_time_ms` must be a non-negative safe integer")

!(assertEqual
  (codex:code-mode-exec-source-parse-result-error
    (codex:parse-code-mode-exec-source
      "// @exec: {\"max_output_tokens\": -1}\ntext('hi')"))
  (codex:code-mode-exec-source-fields-message))

!(assertEqual
  (codex:code-mode-exec-source-parse-result-value
    (codex:parse-code-mode-exec-source
      "// @exec: {\"yield_time_ms\": null, \"max_output_tokens\": null}\ntext('hi')"))
  (CodexCodeModeParsedExecSource
    "text('hi')"
    CodexAbsent
    CodexAbsent))

!(assertEqual
  (codex:code-mode-execute-handler-kind)
  "function")

!(assertEqual
  (codex:code-mode-execute-handler-matches-kind
    (CodexToolPayloadCustom "text('hi')"))
  True)

!(assertEqual
  (codex:code-mode-execute-handler-matches-kind
    (CodexToolPayloadFunction "{}"))
  False)

!(assertEqual
  (codex:code-mode-execute-handler-result-value
    (codex:code-mode-execute-handler-plan
      "call-exec"
      (codex:plain-tool-name "exec")
      (CodexToolPayloadCustom
        "// @exec: {\"yield_time_ms\": 10}\ntext('hi')")))
  (CodexCodeModeExecutePlan
    "call-exec"
    (CodexCodeModeParsedExecSource
      "text('hi')"
      10
      CodexAbsent)))

!(assertEqual
  (codex:code-mode-execute-handler-result-error
    (codex:code-mode-execute-handler-plan
      "call-other"
      (codex:plain-tool-name "other")
      (CodexToolPayloadCustom "text('hi')")))
  (CodexFunctionCallErrorRespondToModel
    "exec expects raw JavaScript source text"))
