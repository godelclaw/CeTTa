!(register-module! ../codex)
!(import! &self codex:context_manager_history)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:context-manager-history-is-api-message
    (CodexResponseItemMessage "user" ((CodexInputText "hello")) CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:context-manager-history-is-api-message
    (CodexResponseItemMessage "system" ((CodexInputText "hidden")) CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:context-manager-history-is-api-message
    (CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1"))
  (True))

!(assertEqualToResult
  (codex:context-manager-history-is-api-message
    (CodexResponseItemGhostSnapshot "commit-1"))
  (False))

!(assertEqualToResult
  (codex:context-manager-history-is-api-message
    (CodexResponseItemOther))
  (False))

!(assertEqualToResult
  (codex:context-manager-history-is-model-generated-item
    (CodexResponseItemMessage "assistant" ((CodexOutputText "ok")) CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:context-manager-history-is-model-generated-item
    (CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1"))
  (True))

!(assertEqualToResult
  (codex:context-manager-history-is-model-generated-item
    (CodexResponseItemFunctionCallOutput
      "fn-1"
      (CodexFunctionCallOutputText "ok")))
  (False))

!(assertEqualToResult
  (codex:is-codex-generated-item
    (CodexResponseItemFunctionCallOutput
      "fn-1"
      (CodexFunctionCallOutputText "ok")))
  (True))

!(assertEqualToResult
  (codex:is-codex-generated-item
    (CodexResponseItemMessage "developer" ((CodexInputText "ctx")) CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:is-codex-generated-item
    (CodexResponseItemMessage "user" ((CodexInputText "prompt")) CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:is-user-turn-boundary
    (CodexResponseItemMessage "user" ((CodexInputText "prompt")) CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:is-user-turn-boundary
    (CodexResponseItemMessage
      "user"
      ((CodexInputText
         "<environment_context>\n  <cwd>/repo</cwd>\n  <shell>bash</shell>\n</environment_context>"))
      CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:is-user-turn-boundary
    (CodexResponseItemMessage
      "assistant"
      ((CodexOutputText
         "{\"author\":\"/root/a\",\"recipient\":\"/root/b\",\"content\":\"continue\",\"trigger_turn\":true}"))
      CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:is-user-turn-boundary
    (CodexResponseItemMessage
      "assistant"
      ((CodexOutputText
         "{\"author\":\"/root/a\",\"recipient\":\"/root/b\",\"content\":\"continue\",\"trigger_turn\":true,\"other_recipients\":[\"/root/c\"]}"))
      CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:is-user-turn-boundary
    (CodexResponseItemMessage
      "assistant"
      ((CodexOutputText
         "{\"author\":\"/root/a\",\"recipient\":\"/root/b\",\"content\":\"continue\"}"))
      CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:is-user-turn-boundary
    (CodexResponseItemMessage
      "assistant"
      ((CodexOutputText "ordinary assistant text"))
      CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:context-manager-history-user-message-positions
    ((CodexResponseItemMessage "system" ((CodexInputText "hidden")) CodexAbsent)
     (CodexResponseItemMessage "user" ((CodexInputText "first")) CodexAbsent)
     (CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1")
     (CodexResponseItemMessage
       "assistant"
       ((CodexOutputText
          "{\"author\":\"/root/a\",\"recipient\":\"/root/b\",\"content\":\"continue\",\"trigger_turn\":false}"))
       CodexAbsent)
     (CodexResponseItemMessage
       "user"
       ((CodexInputText
          "<environment_context>\n  <shell>bash</shell>\n</environment_context>"))
       CodexAbsent)))
  ((1 3)))

!(assertEqualToResult
  (codex:context-manager-history-items-after-last-model-generated-item
    ((CodexResponseItemMessage "user" ((CodexInputText "before")) CodexAbsent)
     (CodexResponseItemFunctionCallOutput
       "old"
       (CodexFunctionCallOutputText "old-output"))
     (CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1")
     (CodexResponseItemFunctionCallOutput
       "fn-1"
       (CodexFunctionCallOutputText "new-output"))
     (CodexResponseItemCustomToolCallOutput
       "custom-1"
       CodexAbsent
       (CodexFunctionCallOutputText "new-custom"))))
  (((CodexResponseItemFunctionCallOutput
      "fn-1"
      (CodexFunctionCallOutputText "new-output"))
    (CodexResponseItemCustomToolCallOutput
      "custom-1"
      CodexAbsent
      (CodexFunctionCallOutputText "new-custom")))))

!(assertEqualToResult
  (codex:context-manager-history-items-after-last-model-generated-item
    ((CodexResponseItemMessage "user" ((CodexInputText "all")) CodexAbsent)
     (CodexResponseItemFunctionCallOutput
       "fn-1"
       (CodexFunctionCallOutputText "kept"))))
  (()))
