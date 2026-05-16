!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:user-input-op
      ((codex:user-input-text "Hello from user."))))
  ("user_input"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:user-input-op
        ((codex:user-input-text "Hello from user.")))))
  ("{\"type\":\"user_input\",\"items\":[{\"type\":\"text\",\"text\":\"Hello from user.\",\"text_elements\":[]}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:user-input-op
        ((codex:user-input-text
           "See image"
           ((codex:text-element
              (codex:byte-range 0 3)
              CodexAbsent)))
         (codex:user-input-image "data:image/png;base64,AAAA")
         (codex:user-input-local-image "/repo/screenshot.png")
         (codex:user-input-skill "planner" "/repo/.codex/skills/planner/SKILL.md")
         (codex:user-input-mention "calendar" "app://calendar")))))
  ("{\"type\":\"user_input\",\"items\":[{\"type\":\"text\",\"text\":\"See image\",\"text_elements\":[{\"byte_range\":{\"start\":0,\"end\":3},\"placeholder\":null}]},{\"type\":\"image\",\"image_url\":\"data:image/png;base64,AAAA\"},{\"type\":\"local_image\",\"path\":\"/repo/screenshot.png\"},{\"type\":\"skill\",\"name\":\"planner\",\"path\":\"/repo/.codex/skills/planner/SKILL.md\"},{\"type\":\"mention\",\"name\":\"calendar\",\"path\":\"app://calendar\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:turn-environment-selections-json
      ((codex:turn-environment-selection "env_1" "/repo"))))
  ("[{\"environment_id\":\"env_1\",\"cwd\":\"/repo\"}]"))

!(assertEqualToResult
  (json-stringify
    (JsonObject
      ((JsonPair "type" (JsonString "object"))
       (JsonPair
         "required"
         (JsonArray
           ((JsonString "answer")))))))
  ("{\"type\":\"object\",\"required\":[\"answer\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:responsesapi-client-metadata-json
      ((codex:responsesapi-client-metadata-entry "origin" "chat")
       (codex:responsesapi-client-metadata-entry "session" "abc123"))))
  ("{\"origin\":\"chat\",\"session\":\"abc123\"}"))
