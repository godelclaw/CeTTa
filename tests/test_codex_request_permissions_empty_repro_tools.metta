!(register-module! ../codex)
!(import! &self codex:request_permissions_repro_tools)

!(assertEqual
  (once (codex:request-permissions-repro-tools-handler-output-text))
  Empty)

!(assertEqual
  (once (codex:request-permissions-repro-tools-tool-output-text))
  Empty)
