!(register-module! ../codex)
!(import! &self codex:skill_invocation)

(= (codex-test-skill $name $path $dependencies)
   (CodexSkillMetadata
     $name
     "test"
     CodexAbsent
     CodexAbsent
     $dependencies
     $path
     (CodexSkillScopeUser)
     True))

(= (codex-test-tool-dependency $type $value $description)
   (CodexSkillToolDependency
     $type
     $value
     $description
     CodexAbsent
     CodexAbsent
     CodexAbsent))

!(assertEqualToResult
  (codex:skill-invocation-tokenize-command
    "python3 -u scripts/fetch_comments.py")
  (("python3" "-u" "scripts/fetch_comments.py")))

!(assertEqualToResult
  (codex:script-run-token
    ("python3" "-u" "scripts/fetch_comments.py"))
  ("scripts/fetch_comments.py"))

!(assertEqualToResult
  (codex:script-run-token
    ("python3" "-c" "print(1)"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:script-run-token
    ("/usr/bin/PYTHON3.EXE" "scripts/fetch_comments.PY"))
  ("scripts/fetch_comments.PY"))

!(assertEqualToResult
  (codex:script-run-token
    ("python3" "scripts/fetch_comments.txt"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:command-reads-file ("cat" "SKILL.md"))
  (True))

!(assertEqualToResult
  (codex:command-reads-file ("python3" "scripts/fetch_comments.py"))
  (False))

!(assertEqualToResult
  (codex:implicit-skill-path-indexes-by-scripts-dir
    (codex:build-implicit-skill-path-indexes
      ((codex-test-skill "test-skill" "/tmp/skill-test/SKILL.md" CodexAbsent))))
  (((CodexSkillPathIndexEntry
      "/tmp/skill-test/scripts"
      (CodexSkillMetadata
        "test-skill"
        "test"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        "/tmp/skill-test/SKILL.md"
        (CodexSkillScopeUser)
        True)))))

!(assertEqualToResult
  (codex:skill-metadata-name
    (codex:detect-implicit-skill-invocation-for-command
      (codex:skill-load-outcome-from-skills
        ((codex-test-skill "test-skill" "/tmp/skill-test/SKILL.md" CodexAbsent)))
      "python3 -u scripts/fetch_comments.py"
      "/tmp/skill-test"))
  ("test-skill"))

!(assertEqualToResult
  (codex:skill-metadata-name
    (codex:detect-implicit-skill-invocation-for-command
      (codex:skill-load-outcome-from-skills
        ((codex-test-skill "test-skill" "/tmp/skill-test/SKILL.md" CodexAbsent)))
      "python3 /tmp/skill-test/scripts/nested/fetch_comments.py"
      "/tmp/other"))
  ("test-skill"))

!(assertEqualToResult
  (codex:skill-metadata-name
    (codex:detect-implicit-skill-invocation-for-command
      (codex:skill-load-outcome-from-skills
        ((codex-test-skill "test-skill" "/tmp/skill-test/SKILL.md" CodexAbsent)))
      "cat /tmp/skill-test/SKILL.md | head"
      "/tmp"))
  ("test-skill"))

!(assertEqualToResult
  (codex:detect-implicit-skill-invocation-for-command
    (codex:skill-load-outcome-from-skills
      ((codex-test-skill "test-skill" "/tmp/skill-test/SKILL.md" CodexAbsent)))
    "python3 scripts/fetch_comments.txt"
    "/tmp/skill-test")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-metadata-name
    (codex:detect-implicit-skill-invocation-for-command
      (codex:skill-load-outcome-from-skills
        ((codex-test-skill "first-skill" "/tmp/skill-test/SKILL.md" CodexAbsent)
         (codex-test-skill "second-skill" "/tmp/skill-test/SKILL.md" CodexAbsent)))
      "cat /tmp/skill-test/SKILL.md"
      "/tmp"))
  ("second-skill"))

!(assertEqualToResult
  (codex:collect-env-var-dependencies
    ((codex-test-skill
       "test-skill"
       "/tmp/skill-test/SKILL.md"
       (CodexSkillDependencies
         ((codex-test-tool-dependency "env_var" "API_KEY" "API token")
          (codex-test-tool-dependency "mcp" "server" "ignored")
          (codex-test-tool-dependency "env_var" "" "ignored"))))
     (codex-test-skill "plain-skill" "/tmp/plain/SKILL.md" CodexAbsent)))
  (((CodexSkillDependencyInfo "test-skill" "API_KEY" "API token"))))
