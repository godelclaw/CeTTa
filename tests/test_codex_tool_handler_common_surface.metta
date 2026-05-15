!(register-module! ../codex)
!(import! &self codex:tool_handler_common)

!(assertEqualToResult
  (codex:function-arguments-parse-error-prefix)
  ("failed to parse function arguments: "))

!(assertEqualToResult
  (codex:function-arguments-parse-error-message "missing field `plan`")
  ("failed to parse function arguments: missing field `plan`"))

!(assertEqualToResult
  (case (codex:parse-function-arguments-object "{\"x\":1}")
    (((CodexParseFunctionArgumentsObjectOk $object)
      (json-stringify $object))
     ((CodexParseFunctionArgumentsObjectError $message)
      $message)))
  ("{\"x\":1}"))

!(assertEqualToResult
  (codex:parse-function-arguments-object "\"oops\"")
  ((CodexParseFunctionArgumentsObjectError
     "invalid type: expected object")))
