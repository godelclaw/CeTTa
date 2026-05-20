!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:client_common)
!(import! &self codex:protocol)
!(import! &self codex:tool_registry_plan)

(= (client-common-raw-success)
   "{\"output\":\"hello\",\"metadata\":{\"exit_code\":0,\"duration_seconds\":0.5}}")

(= (client-common-raw-total-lines)
   "{\"output\":\"Total output lines: 12\\n\\nalpha\\nbeta\",\"metadata\":{\"exit_code\":1,\"duration_seconds\":2}}")

(= (client-common-raw-valid-second)
   "{\"output\":\"second\",\"metadata\":{\"exit_code\":0,\"duration_seconds\":1}}")

!(assertEqualToResult
  (codex:client-common-is-shell-tool-name "shell")
  (True))

!(assertEqualToResult
  (codex:client-common-is-shell-tool-name "container.exec")
  (True))

!(assertEqualToResult
  (codex:client-common-is-shell-tool-name "python")
  (False))

!(assertEqualToResult
  (codex:client-common-parse-structured-shell-output
    (client-common-raw-success))
  ("Exit code: 0\nWall time: 0.5 seconds\nOutput:\nhello"))

!(assertEqualToResult
  (codex:client-common-parse-structured-shell-output
    (client-common-raw-total-lines))
  ("Exit code: 1\nWall time: 2 seconds\nTotal output lines: 12\nOutput:\nalpha\nbeta"))

!(assertEqualToResult
  (codex:client-common-parse-structured-shell-output
    "{\"output\":\"bad\",\"metadata\":{\"exit_code\":1.5,\"duration_seconds\":1}}")
  (CodexAbsent))

!(assertEqualToResult
  (codex:client-common-parse-structured-shell-output
    "not json")
  (CodexAbsent))

!(assertEqualToResult
  (codex:client-common-reserialize-shell-outputs
    ((CodexResponseItemFunctionCall
       "fc-1"
       "shell"
       CodexAbsent
       "{}"
       "call-shell")
     (CodexResponseItemFunctionCallOutput
       "call-shell"
       (CodexFunctionCallOutputText (client-common-raw-success)))
     (CodexResponseItemCustomToolCall
       "call-patch"
       "apply_patch"
       "*** Begin Patch\n*** End Patch\n")
     (CodexResponseItemCustomToolCallOutput
       "call-patch"
       CodexAbsent
       (CodexFunctionCallOutputText (client-common-raw-total-lines)))))
  (((CodexResponseItemFunctionCall
      "fc-1"
      "shell"
      CodexAbsent
      "{}"
      "call-shell")
    (CodexResponseItemFunctionCallOutput
      "call-shell"
      (CodexFunctionCallOutputText
        "Exit code: 0\nWall time: 0.5 seconds\nOutput:\nhello"))
    (CodexResponseItemCustomToolCall
      "call-patch"
      "apply_patch"
      "*** Begin Patch\n*** End Patch\n")
    (CodexResponseItemCustomToolCallOutput
      "call-patch"
      CodexAbsent
      (CodexFunctionCallOutputText
        "Exit code: 1\nWall time: 2 seconds\nTotal output lines: 12\nOutput:\nalpha\nbeta")))))

!(assertEqualToResult
  (codex:client-common-prompt-formatted-input
    (codex:client-common-prompt
      ((CodexResponseItemFunctionCall
         "fc-2"
         "shell"
         CodexAbsent
         "{}"
         "call-gated")
       (CodexResponseItemFunctionCallOutput
         "call-gated"
         (CodexFunctionCallOutputText (client-common-raw-success))))
      ()
      False
      CodexBaseInstructionsDefault
      CodexAbsent
      CodexAbsent
      True))
  (((CodexResponseItemFunctionCall
      "fc-2"
      "shell"
      CodexAbsent
      "{}"
      "call-gated")
    (CodexResponseItemFunctionCallOutput
      "call-gated"
      (CodexFunctionCallOutputText
        "{\"output\":\"hello\",\"metadata\":{\"exit_code\":0,\"duration_seconds\":0.5}}")))))

!(assertEqualToResult
  (codex:client-common-prompt-formatted-input
    (codex:client-common-prompt
      ((CodexResponseItemFunctionCall
         "fc-3"
         "shell"
         CodexAbsent
         "{}"
         "call-freeform")
       (CodexResponseItemFunctionCallOutput
         "call-freeform"
         (CodexFunctionCallOutputText (client-common-raw-success))))
      ((codex:create-apply-patch-freeform-tool))
      False
      CodexBaseInstructionsDefault
      CodexAbsent
      CodexAbsent
      True))
  (((CodexResponseItemFunctionCall
      "fc-3"
      "shell"
      CodexAbsent
      "{}"
      "call-freeform")
    (CodexResponseItemFunctionCallOutput
      "call-freeform"
      (CodexFunctionCallOutputText
        "Exit code: 0\nWall time: 0.5 seconds\nOutput:\nhello")))))

!(assertEqualToResult
  (codex:client-common-prompt-formatted-input
    (codex:client-common-prompt
      ((CodexResponseItemFunctionCall
         "fc-4"
         "shell"
         CodexAbsent
         "{}"
         "call-function-tool")
       (CodexResponseItemFunctionCallOutput
         "call-function-tool"
         (CodexFunctionCallOutputText (client-common-raw-success))))
      ((codex:tool-spec-function
         (codex:responses-api-tool
           "apply_patch"
           "json apply patch"
           False
           False
           (JsonObject ())
           CodexAbsent)))
      False
      CodexBaseInstructionsDefault
      CodexAbsent
      CodexAbsent
      True))
  (((CodexResponseItemFunctionCall
      "fc-4"
      "shell"
      CodexAbsent
      "{}"
      "call-function-tool")
    (CodexResponseItemFunctionCallOutput
      "call-function-tool"
      (CodexFunctionCallOutputText
        "{\"output\":\"hello\",\"metadata\":{\"exit_code\":0,\"duration_seconds\":0.5}}")))))

!(assertEqualToResult
  (codex:client-common-reserialize-shell-outputs
    ((CodexResponseItemFunctionCall
       "fc-apply"
       "apply_patch"
       CodexAbsent
       "*** Begin Patch\n*** End Patch\n"
       "call-apply-function")
     (CodexResponseItemFunctionCallOutput
       "call-apply-function"
       (CodexFunctionCallOutputText (client-common-raw-success)))))
  (((CodexResponseItemFunctionCall
      "fc-apply"
      "apply_patch"
      CodexAbsent
      "*** Begin Patch\n*** End Patch\n"
      "call-apply-function")
    (CodexResponseItemFunctionCallOutput
      "call-apply-function"
      (CodexFunctionCallOutputText
        "Exit code: 0\nWall time: 0.5 seconds\nOutput:\nhello")))))

!(assertEqualToResult
  (codex:client-common-reserialize-shell-outputs
    ((CodexResponseItemFunctionCall
       "fc-5"
       "shell"
       CodexAbsent
       "{}"
       "call-once")
     (CodexResponseItemFunctionCallOutput
       "call-once"
       (CodexFunctionCallOutputText "not json"))
     (CodexResponseItemFunctionCallOutput
       "call-once"
       (CodexFunctionCallOutputText (client-common-raw-valid-second)))))
  (((CodexResponseItemFunctionCall
      "fc-5"
      "shell"
      CodexAbsent
      "{}"
      "call-once")
    (CodexResponseItemFunctionCallOutput
      "call-once"
      (CodexFunctionCallOutputText "not json"))
    (CodexResponseItemFunctionCallOutput
      "call-once"
      (CodexFunctionCallOutputText
        "{\"output\":\"second\",\"metadata\":{\"exit_code\":0,\"duration_seconds\":1}}")))))

!(assertEqualToResult
  (codex:client-common-reserialize-shell-outputs
    ((CodexResponseItemLocalShellCall
       "local-id"
       CodexAbsent
       "completed"
       CodexAbsent)
     (CodexResponseItemFunctionCallOutput
       "local-id"
       (CodexFunctionCallOutputText (client-common-raw-success)))))
  (((CodexResponseItemLocalShellCall
      "local-id"
      CodexAbsent
      "completed"
      CodexAbsent)
    (CodexResponseItemFunctionCallOutput
      "local-id"
      (CodexFunctionCallOutputText
        "Exit code: 0\nWall time: 0.5 seconds\nOutput:\nhello")))))
