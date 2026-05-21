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

!(assertEqualToResult
  (codex:resolve-workdir-base-path
    "{\"cmd\":\"pwd\"}"
    "/repo/project")
  ((CodexParseFunctionArgumentsObjectOk "/repo/project")))

!(assertEqualToResult
  (codex:resolve-workdir-base-path
    "{\"workdir\":\"\"}"
    "/repo/project")
  ((CodexParseFunctionArgumentsObjectOk "/repo/project")))

!(assertEqualToResult
  (codex:resolve-workdir-base-path
    "{\"workdir\":null}"
    "/repo/project")
  ((CodexParseFunctionArgumentsObjectOk "/repo/project")))

!(assertEqualToResult
  (codex:resolve-workdir-base-path
    "{\"workdir\":false}"
    "/repo/project")
  ((CodexParseFunctionArgumentsObjectOk "/repo/project")))

!(assertEqualToResult
  (codex:resolve-workdir-base-path
    "{\"workdir\":\"sub/../crate\"}"
    "/repo/project")
  ((CodexParseFunctionArgumentsObjectOk "/repo/project/crate")))

!(assertEqualToResult
  (codex:resolve-workdir-base-path
    "{\"workdir\":\"/tmp/work\"}"
    "/repo/project")
  ((CodexParseFunctionArgumentsObjectOk "/tmp/work")))

!(assertEqualToResult
  (codex:resolve-workdir-base-path
    "\"oops\""
    "/repo/project")
  ((CodexParseFunctionArgumentsObjectError
     "invalid type: expected object")))
