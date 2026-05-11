!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:tools)
!(import! &self codex:request_permissions)

!(assertEqualToResult
  (once
    (json-stringify
      (codex:request-permission-profile-json
        (codex:exec-command-additional-permissions
          (codex:parse-exec-command-args
            "{\"cmd\":\"printf ok\",\"workdir\":\"runtime\",\"login\":false,\"sandbox_permissions\":\"with_additional_permissions\",\"additional_permissions\":{\"file_system\":{\"write\":[\"./relative.txt\"]}}}")))))
  ("{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime/relative.txt\"]}}"))

!(assertEqualToResult
  (once
    (codex:exec-command-sandbox-permissions
      (codex:parse-exec-command-args
        "{\"cmd\":\"printf ok\",\"workdir\":\"runtime\",\"login\":false,\"sandbox_permissions\":\"with_additional_permissions\",\"additional_permissions\":{\"file_system\":{\"write\":[\"./relative.txt\"]}}}")))
  ("with_additional_permissions"))
