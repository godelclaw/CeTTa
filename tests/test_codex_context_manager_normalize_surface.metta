!(register-module! ../codex)
!(import! &self codex:context_manager_normalize)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:ensure-call-outputs-present
    ((CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1")
     (CodexResponseItemCustomToolCall "custom-1" "patch" "{}")
     (CodexResponseItemToolSearchCall
       CodexAbsent
       "search-1"
       "completed"
       "client"
       "{}")
     (CodexResponseItemLocalShellCall
       CodexAbsent
       "local-1"
       "completed"
       (CodexLocalShellExecAction ("pwd")))))
  (((CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1")
    (CodexResponseItemFunctionCallOutput
      "fn-1"
      (CodexFunctionCallOutputText "aborted"))
    (CodexResponseItemCustomToolCall "custom-1" "patch" "{}")
    (CodexResponseItemCustomToolCallOutput
      "custom-1"
      CodexAbsent
      (CodexFunctionCallOutputText "aborted"))
    (CodexResponseItemToolSearchCall
      CodexAbsent
      "search-1"
      "completed"
      "client"
      "{}")
    (CodexResponseItemToolSearchOutput
      "search-1"
      "completed"
      "client"
      ())
    (CodexResponseItemLocalShellCall
      CodexAbsent
      "local-1"
      "completed"
      (CodexLocalShellExecAction ("pwd")))
    (CodexResponseItemFunctionCallOutput
      "local-1"
      (CodexFunctionCallOutputText "aborted")))))

!(assertEqualToResult
  (codex:ensure-call-outputs-present
    ((CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1")
     (CodexResponseItemFunctionCallOutput
       "fn-1"
       (CodexFunctionCallOutputText "ok"))))
  (((CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1")
    (CodexResponseItemFunctionCallOutput
      "fn-1"
      (CodexFunctionCallOutputText "ok")))))

!(assertEqualToResult
  (codex:remove-orphan-outputs
    ((CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1")
     (CodexResponseItemFunctionCallOutput
       "fn-1"
       (CodexFunctionCallOutputText "ok"))
     (CodexResponseItemFunctionCallOutput
       "orphan-fn"
       (CodexFunctionCallOutputText "drop"))
     (CodexResponseItemLocalShellCall
       CodexAbsent
       "local-1"
       "completed"
       (CodexLocalShellExecAction ("pwd")))
     (CodexResponseItemFunctionCallOutput
       "local-1"
       (CodexFunctionCallOutputText "ok"))
     (CodexResponseItemCustomToolCall "custom-1" "patch" "{}")
     (CodexResponseItemCustomToolCallOutput
       "custom-1"
       CodexAbsent
       (CodexFunctionCallOutputText "ok"))
     (CodexResponseItemCustomToolCallOutput
       "orphan-custom"
       CodexAbsent
       (CodexFunctionCallOutputText "drop"))
     (CodexResponseItemToolSearchCall
       CodexAbsent
       "search-1"
       "completed"
       "client"
       "{}")
     (CodexResponseItemToolSearchOutput
       "search-1"
       "completed"
       "client"
       ())
     (CodexResponseItemToolSearchOutput
       "orphan-search"
       "completed"
       "client"
       ())
     (CodexResponseItemToolSearchOutput
       CodexAbsent
       "completed"
       "client"
       ())
     (CodexResponseItemToolSearchOutput
       "server-search"
       "completed"
       "server"
       ())))
  (((CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1")
    (CodexResponseItemFunctionCallOutput
      "fn-1"
      (CodexFunctionCallOutputText "ok"))
    (CodexResponseItemLocalShellCall
      CodexAbsent
      "local-1"
      "completed"
      (CodexLocalShellExecAction ("pwd")))
    (CodexResponseItemFunctionCallOutput
      "local-1"
      (CodexFunctionCallOutputText "ok"))
    (CodexResponseItemCustomToolCall "custom-1" "patch" "{}")
    (CodexResponseItemCustomToolCallOutput
      "custom-1"
      CodexAbsent
      (CodexFunctionCallOutputText "ok"))
    (CodexResponseItemToolSearchCall
      CodexAbsent
      "search-1"
      "completed"
      "client"
      "{}")
    (CodexResponseItemToolSearchOutput
      "search-1"
      "completed"
      "client"
      ())
    (CodexResponseItemToolSearchOutput
      CodexAbsent
      "completed"
      "client"
      ())
    (CodexResponseItemToolSearchOutput
      "server-search"
      "completed"
      "server"
      ()))))

!(assertEqualToResult
  (codex:remove-corresponding-for
    ((CodexResponseItemFunctionCallOutput
       "fn-1"
       (CodexFunctionCallOutputText "drop"))
     (CodexResponseItemFunctionCallOutput
       "fn-2"
       (CodexFunctionCallOutputText "keep")))
    (CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "fn-1"))
  (((CodexResponseItemFunctionCallOutput
      "fn-2"
      (CodexFunctionCallOutputText "keep")))))

!(assertEqualToResult
  (codex:remove-corresponding-for
    ((CodexResponseItemFunctionCall CodexAbsent "shell" CodexAbsent "{}" "shared")
     (CodexResponseItemLocalShellCall
       CodexAbsent
       "shared"
       "completed"
       (CodexLocalShellExecAction ("pwd"))))
    (CodexResponseItemFunctionCallOutput
      "shared"
      (CodexFunctionCallOutputText "done")))
  (((CodexResponseItemLocalShellCall
      CodexAbsent
      "shared"
      "completed"
      (CodexLocalShellExecAction ("pwd"))))))

!(assertEqualToResult
  (codex:remove-corresponding-for
    ((CodexResponseItemLocalShellCall
       CodexAbsent
       "shared"
       "completed"
       (CodexLocalShellExecAction ("pwd"))))
    (CodexResponseItemFunctionCallOutput
      "shared"
      (CodexFunctionCallOutputText "done")))
  (()))

!(assertEqualToResult
  (codex:remove-corresponding-for
    ((CodexResponseItemToolSearchCall
       CodexAbsent
       "search-1"
       "completed"
       "client"
       "{}")
     (CodexResponseItemToolSearchOutput
       "search-1"
       "completed"
       "client"
       ()))
    (CodexResponseItemToolSearchOutput
      "search-1"
      "completed"
      "client"
      ()))
  (((CodexResponseItemToolSearchOutput
      "search-1"
      "completed"
      "client"
      ()))))

!(assertEqualToResult
  (codex:remove-corresponding-for
    ((CodexResponseItemCustomToolCallOutput
       "custom-1"
       CodexAbsent
       (CodexFunctionCallOutputText "drop"))
     (CodexResponseItemCustomToolCallOutput
       "custom-2"
       CodexAbsent
       (CodexFunctionCallOutputText "keep")))
    (CodexResponseItemCustomToolCall "custom-1" "patch" "{}"))
  (((CodexResponseItemCustomToolCallOutput
      "custom-2"
      CodexAbsent
      (CodexFunctionCallOutputText "keep")))))

!(assertEqualToResult
  (codex:strip-images-when-unsupported
    ((CodexInputModalityText) (CodexInputModalityImage))
    ((CodexResponseItemMessage
       "user"
       ((CodexInputImage "data:image/png;base64,AAA" "high"))
       CodexAbsent)))
  (((CodexResponseItemMessage
      "user"
      ((CodexInputImage "data:image/png;base64,AAA" "high"))
      CodexAbsent))))

!(assertEqualToResult
  (codex:strip-images-when-unsupported
    ((CodexInputModalityText))
    ((CodexResponseItemMessage
       "user"
       ((CodexInputText "before")
        (CodexInputImage "data:image/png;base64,AAA" "high"))
       CodexAbsent)
     (CodexResponseItemFunctionCallOutput
       "fn-1"
       (CodexFunctionCallOutputContentItems
         ((CodexInputImage "data:image/png;base64,BBB" "low")
          (CodexInputText "after"))))
     (CodexResponseItemCustomToolCallOutput
       "custom-1"
       CodexAbsent
       (CodexFunctionCallOutputContentItems
         ((CodexInputImage "data:image/png;base64,CCC" "original"))))
     (CodexResponseItemImageGenerationCall
       "img-1"
       "completed"
       CodexAbsent
       "data:image/png;base64,DDD")))
  (((CodexResponseItemMessage
      "user"
      ((CodexInputText "before")
       (CodexInputText
         "image content omitted because you do not support image input"))
      CodexAbsent)
    (CodexResponseItemFunctionCallOutput
      "fn-1"
      (CodexFunctionCallOutputContentItems
        ((CodexInputText
           "image content omitted because you do not support image input")
         (CodexInputText "after"))))
    (CodexResponseItemCustomToolCallOutput
      "custom-1"
      CodexAbsent
      (CodexFunctionCallOutputContentItems
        ((CodexInputText
           "image content omitted because you do not support image input"))))
    (CodexResponseItemImageGenerationCall
      "img-1"
      "completed"
      CodexAbsent
      ""))))
