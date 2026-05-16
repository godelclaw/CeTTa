!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:op-type
    (codex:list-skills-op () False))
  ("list_skills"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:list-skills-op () False)))
  ("{\"type\":\"list_skills\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:list-skills-op
        ("/repo" "/repo/subdir")
        True)))
  ("{\"type\":\"list_skills\",\"cwds\":[\"/repo\",\"/repo/subdir\"],\"force_reload\":true}"))

!(assertEqualToResult
  (json-stringify
    (codex:op-json
      (codex:list-skills-op
        ("/repo")
        False)))
  ("{\"type\":\"list_skills\",\"cwds\":[\"/repo\"]}"))
