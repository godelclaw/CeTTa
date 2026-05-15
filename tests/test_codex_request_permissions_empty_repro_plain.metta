!(register-module! ../codex)
!(import! &self codex:request_permissions_repro_plain)

!(assertEqualToResult
  (codex:request-permissions-repro-plain-handler-output-text)
  ("{\"permissions\":{},\"scope\":\"turn\"}"))

!(assertEqualToResult
  (codex:request-permissions-repro-plain-tool-output-text)
  ("{\"permissions\":{},\"scope\":\"turn\"}"))
