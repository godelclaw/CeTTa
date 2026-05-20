!(register-module! ../codex)
!(import! &self codex:skill_remote)

!(assertEqualToResult
  (codex:remote-skills-api-timeout-secs)
  (30))

!(assertEqualToResult
  (codex:remote-skill-as-query-scope
    (codex:remote-skill-scope-workspace-shared))
  ("workspace-shared"))

!(assertEqualToResult
  (codex:remote-skill-as-query-scope
    (codex:remote-skill-scope-all-shared))
  ("all-shared"))

!(assertEqualToResult
  (codex:remote-skill-as-query-scope
    (codex:remote-skill-scope-personal))
  ("personal"))

!(assertEqualToResult
  (codex:remote-skill-as-query-scope
    (codex:remote-skill-scope-example))
  ("example"))

!(assertEqualToResult
  (codex:remote-skill-as-query-product-surface
    (codex:remote-skill-product-surface-chatgpt))
  ("chatgpt"))

!(assertEqualToResult
  (codex:remote-skill-as-query-product-surface
    (codex:remote-skill-product-surface-codex))
  ("codex"))

!(assertEqualToResult
  (codex:remote-skill-as-query-product-surface
    (codex:remote-skill-product-surface-api))
  ("api"))

!(assertEqualToResult
  (codex:remote-skill-as-query-product-surface
    (codex:remote-skill-product-surface-atlas))
  ("atlas"))

!(assertEqualToResult
  (codex:remote-skill-ensure-codex-backend-auth CodexAbsent)
  ((CodexRemoteSkillErr
     "chatgpt authentication required for remote skill scopes")))

!(assertEqualToResult
  (codex:remote-skill-ensure-codex-backend-auth
    (CodexAuthApiKey "sk-test"))
  ((CodexRemoteSkillErr
     "chatgpt authentication required for remote skill scopes; api key auth is not supported")))

!(assertEqualToResult
  (codex:remote-skill-ensure-codex-backend-auth
    (CodexAuthChatgpt "token-data"))
  ((CodexRemoteSkillOk (CodexAuthChatgpt "token-data"))))

!(assertEqualToResult
  (codex:remote-skill-list-request-from-parts
    "https://chatgpt.example.test///"
    (codex:remote-skill-scope-personal)
    (codex:remote-skill-product-surface-codex)
    True)
  ((CodexRemoteSkillListRequest
     "https://chatgpt.example.test/hazelnuts"
     ((CodexRemoteSkillQueryParam "product_surface" "codex")
      (CodexRemoteSkillQueryParam "scope" "personal")
      (CodexRemoteSkillQueryParam "enabled" "true")))))

!(assertEqualToResult
  (codex:remote-skill-list-request-from-parts
    "https://chatgpt.example.test"
    (codex:remote-skill-scope-example)
    (codex:remote-skill-product-surface-atlas)
    CodexAbsent)
  ((CodexRemoteSkillListRequest
     "https://chatgpt.example.test/hazelnuts"
     ((CodexRemoteSkillQueryParam "product_surface" "atlas")
      (CodexRemoteSkillQueryParam "scope" "example")))))

!(assertEqualToResult
  (codex:remote-skill-export-request-from-parts
    "https://chatgpt.example.test/"
    "/home/user/.codex"
    "skill-123")
  ((CodexRemoteSkillExportRequest
     "https://chatgpt.example.test/hazelnuts/skill-123/export"
     "/home/user/.codex/skills/skill-123")))

!(assertEqualToResult
  (codex:is-remote-skill-zip-payload (80 75 3 4 10))
  (True))

!(assertEqualToResult
  (codex:is-remote-skill-zip-payload (80 75 5 6))
  (True))

!(assertEqualToResult
  (codex:is-remote-skill-zip-payload (80 75 7 8 99))
  (True))

!(assertEqualToResult
  (codex:is-remote-skill-zip-payload (80 75 1 2))
  (False))

!(assertEqualToResult
  (codex:remote-skill-safe-join "/tmp/out" "dir/SKILL.md")
  ((CodexRemoteSkillOk "/tmp/out/dir/SKILL.md")))

!(assertEqualToResult
  (codex:remote-skill-safe-join "/tmp/out" "dir/./SKILL.md")
  ((CodexRemoteSkillOk "/tmp/out/dir/./SKILL.md")))

!(assertEqualToResult
  (codex:remote-skill-safe-join "/tmp/out" "dir//SKILL.md")
  ((CodexRemoteSkillOk "/tmp/out/dir//SKILL.md")))

!(assertEqualToResult
  (codex:remote-skill-safe-join "/tmp/out" ".")
  ((CodexRemoteSkillErr
     "Invalid file path in remote skill payload: .")))

!(assertEqualToResult
  (codex:remote-skill-safe-join "/tmp/out" "./dir/SKILL.md")
  ((CodexRemoteSkillErr
     "Invalid file path in remote skill payload: ./dir/SKILL.md")))

!(assertEqualToResult
  (codex:remote-skill-safe-join "/tmp/out" "../dir/SKILL.md")
  ((CodexRemoteSkillErr
     "Invalid file path in remote skill payload: ../dir/SKILL.md")))

!(assertEqualToResult
  (codex:remote-skill-safe-join "/tmp/out" "dir/../SKILL.md")
  ((CodexRemoteSkillErr
     "Invalid file path in remote skill payload: dir/../SKILL.md")))

!(assertEqualToResult
  (codex:remote-skill-safe-join "/tmp/out" "/dir/SKILL.md")
  ((CodexRemoteSkillErr
     "Invalid file path in remote skill payload: /dir/SKILL.md")))

!(assertEqualToResult
  (codex:remote-skill-normalize-zip-name
    "././skill-123/SKILL.md"
    ("skill-123"))
  ("SKILL.md"))

!(assertEqualToResult
  (codex:remote-skill-normalize-zip-name
    "other/SKILL.md"
    ("" "skill-123"))
  ("other/SKILL.md"))

!(assertEqualToResult
  (codex:remote-skill-normalize-zip-name
    "skill-123/"
    ("skill-123"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:remote-skill-normalize-zip-name
    "./"
    ("skill-123"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:remote-skill-summary-name
    (codex:remote-skill-summary "id-1" "imagegen" "Generate images"))
  ("imagegen"))

!(assertEqualToResult
  (codex:remote-skill-download-result-path
    (codex:remote-skill-download-result "id-1" "/tmp/id-1"))
  ("/tmp/id-1"))
