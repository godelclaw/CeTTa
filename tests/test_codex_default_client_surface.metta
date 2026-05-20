!(register-module! ../codex)
!(import! &self codex:default_client)

!(assertEqualToResult
  (codex:default-client-default-originator)
  ("codex_cli_rs"))

!(assertEqualToResult
  (codex:default-client-originator-override-env-var)
  ("CODEX_INTERNAL_ORIGINATOR_OVERRIDE"))

!(assertEqualToResult
  (codex:default-client-is-first-party-originator
    (codex:default-client-default-originator))
  (True))

!(assertEqualToResult
  (codex:default-client-is-first-party-originator "codex-tui")
  (True))

!(assertEqualToResult
  (codex:default-client-is-first-party-originator "codex_vscode")
  (True))

!(assertEqualToResult
  (codex:default-client-is-first-party-originator "Codex Something Else")
  (True))

!(assertEqualToResult
  (codex:default-client-is-first-party-originator "codex_cli")
  (False))

!(assertEqualToResult
  (codex:default-client-is-first-party-originator "Other")
  (False))

!(assertEqualToResult
  (codex:default-client-is-first-party-chat-originator "codex_atlas")
  (True))

!(assertEqualToResult
  (codex:default-client-is-first-party-chat-originator
    "codex_chatgpt_desktop")
  (True))

!(assertEqualToResult
  (codex:default-client-is-first-party-chat-originator
    (codex:default-client-default-originator))
  (False))

!(assertEqualToResult
  (codex:default-client-is-first-party-chat-originator "codex_vscode")
  (False))
