!(register-module! ../codex)
!(import! &self codex:js_repl)

!(assertEqual
  (codex:js-repl-handler-kind)
  "function")

!(assertEqual
  (codex:js-repl-reset-handler-kind)
  "function")

!(assertEqual
  (codex:js-repl-handler-matches-kind
    (CodexToolPayloadFunction "{\"code\":\"console.log(1)\"}"))
  True)

!(assertEqual
  (codex:js-repl-handler-matches-kind
    (CodexToolPayloadCustom "console.log(1)"))
  True)

!(assertEqual
  (codex:js-repl-handler-matches-kind
    (CodexToolPayloadToolSearch "calendar" CodexAbsent))
  False)

!(assertEqual
  (codex:parse-js-repl-function-args
    "{\"code\":\"console.log(1)\",\"timeout_ms\":25}")
  (CodexJsReplParseOk
    (CodexJsReplArgs "console.log(1)" 25)))

!(assertEqual
  (codex:parse-js-repl-function-args
    "{\"code\":\"console.log(1)\",\"timeout_ms\":null}")
  (CodexJsReplParseOk
    (CodexJsReplArgs "console.log(1)" CodexAbsent)))

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-function-args "{}"))
  "failed to parse function arguments: missing field `code`")

!(assertEqual
  (codex:js-repl-parse-result-error
    (codex:parse-js-repl-function-args
      "{\"code\":\"console.log(1)\",\"extra\":true}"))
  "failed to parse function arguments: unknown field `extra`, expected `code` or `timeout_ms`")

!(assertEqual
  (codex:js-repl-handler-result-value
    (codex:run-js-repl-handler
      True
      (CodexToolPayloadFunction
        "{\"code\":\"console.log(1)\",\"timeout_ms\":25}")))
  (CodexJsReplExecPlan
    (CodexJsReplArgs "console.log(1)" 25)))

!(assertEqual
  (codex:js-repl-handler-result-value
    (codex:run-js-repl-handler
      True
      (CodexToolPayloadCustom "console.log(1)")))
  (CodexJsReplExecPlan
    (CodexJsReplArgs "console.log(1)" CodexAbsent)))

!(assertEqual
  (codex:js-repl-handler-result-error
    (codex:run-js-repl-handler
      False
      (CodexToolPayloadCustom "console.log(1)")))
  (CodexFunctionCallErrorRespondToModel
    (codex:js-repl-disabled-message)))

!(assertEqual
  (codex:js-repl-handler-result-error
    (codex:run-js-repl-handler
      True
      (CodexToolPayloadToolSearch "calendar" CodexAbsent)))
  (CodexFunctionCallErrorRespondToModel
    (codex:js-repl-unsupported-payload-message)))

!(assertEqual
  (codex:js-repl-handler-result-value
    (codex:run-js-repl-reset-handler True))
  (CodexToolOutputFunction
    ((CodexInputText "js_repl kernel reset"))
    True
    CodexAbsent))

!(assertEqual
  (codex:js-repl-handler-result-error
    (codex:run-js-repl-reset-handler False))
  (CodexFunctionCallErrorRespondToModel
    (codex:js-repl-disabled-message)))
