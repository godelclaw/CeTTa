!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:tools)
!(import! &self codex:request_permissions)

!(assertEqualToResult
  (once
    (json-stringify
      (codex:request-permission-profile-json
        (codex:request-permission-profile
          CodexAbsent
          (codex:request-permissions-file-system
            ()
            ("/home/zarclaw/repos/CeTTa/runtime/relative.txt"))))))
  ("{\"file_system\":{\"write\":[\"/home/zarclaw/repos/CeTTa/runtime/relative.txt\"]}}"))

!(assertEqualToResult
  (once
    (codex:resolve-sandbox-permissions "with_additional_permissions"))
  ("with_additional_permissions"))
