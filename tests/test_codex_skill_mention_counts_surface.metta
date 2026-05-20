!(register-module! ../codex)
!(import! &self codex:skill_mention_counts)

(= (codex-test-skill $name $path)
   (CodexSkillMetadata
     $name
     "test"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     $path
     (CodexSkillScopeUser)
     True))

!(assertEqualToResult
  (codex:skill-mention-counts-ascii-lower-text "Alpha-BETA_123")
  ("alpha-beta_123"))

!(assertEqualToResult
  (codex:skill-name-count-list-get
    ((codex:skill-name-count "alpha" 2)
     (codex:skill-name-count "beta" 1))
    "alpha")
  (2))

!(assertEqualToResult
  (codex:skill-name-count-list-get
    ((codex:skill-name-count "alpha" 2))
    "missing")
  (0))

!(assertEqualToResult
  (codex:skill-name-counts-exact
    (codex:build-skill-name-counts
      ((codex-test-skill "alpha" "/skills/a/SKILL.md")
       (codex-test-skill "Alpha" "/skills/b/SKILL.md")
       (codex-test-skill "alpha" "/skills/disabled/SKILL.md")
       (codex-test-skill "beta" "/skills/c/SKILL.md"))
      ("/skills/disabled/SKILL.md")))
  (((CodexSkillNameCount "alpha" 1)
    (CodexSkillNameCount "Alpha" 1)
    (CodexSkillNameCount "beta" 1))))

!(assertEqualToResult
  (codex:skill-name-counts-lower
    (codex:build-skill-name-counts
      ((codex-test-skill "alpha" "/skills/a/SKILL.md")
       (codex-test-skill "Alpha" "/skills/b/SKILL.md")
       (codex-test-skill "alpha" "/skills/disabled/SKILL.md")
       (codex-test-skill "beta" "/skills/c/SKILL.md"))
      ("/skills/disabled/SKILL.md")))
  (((CodexSkillNameCount "alpha" 2)
    (CodexSkillNameCount "beta" 1))))

!(assertEqualToResult
  (codex:skill-name-counts-exact
    (codex:build-skill-name-counts
      ((codex-test-skill "alpha" "/skills/a/SKILL.md"))
      ("/skills/a/SKILL.md")))
  (()))
