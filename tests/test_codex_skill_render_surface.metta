!(register-module! ../codex)
!(import! &self codex:skill_render)

(= (codex-test-skill $name $scope)
   (CodexSkillMetadata
     $name
     "desc"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (str-concat (str-concat "/tmp/" $name) "/SKILL.md")
     $scope
     True))

(= (codex-test-skill-with-description $name $scope $description)
   (CodexSkillMetadata
     $name
     $description
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (str-concat (str-concat "/tmp/" $name) "/SKILL.md")
     $scope
     True))

(= (codex-test-skill-line $skill $description)
   (codex:skill-line-render-with-description
     (codex:skill-line-from-skill $skill)
     $description))

(= (codex-test-minimum-cost $skills)
   (codex:skill-render-lines-minimum-cost
     (codex:skill-lines-from-skills (codex:ordered-skills-for-budget $skills))
     (codex:skill-metadata-budget-characters 999999)
     0))

(= (codex-test-full-cost $skills)
   (codex:skill-render-lines-full-cost
     (codex:skill-lines-from-skills (codex:ordered-skills-for-budget $skills))
     (codex:skill-metadata-budget-characters 999999)
     0))

!(assertEqualToResult
  (codex:default-skill-metadata-budget 200000)
  ((CodexSkillMetadataBudgetTokens 4000)))

!(assertEqualToResult
  (codex:default-skill-metadata-budget 99)
  ((CodexSkillMetadataBudgetTokens 1)))

!(assertEqualToResult
  (codex:default-skill-metadata-budget CodexAbsent)
  ((CodexSkillMetadataBudgetCharacters 8000)))

!(assertEqualToResult
  (codex:default-skill-metadata-budget -1)
  ((CodexSkillMetadataBudgetCharacters 8000)))

!(assertEqualToResult
  (codex:skill-render-available-skills-lines
    (codex:build-available-skills
      ((codex-test-skill "user-skill" (CodexSkillScopeUser))
       (codex-test-skill "repo-skill" (CodexSkillScopeRepo))
       (codex-test-skill "system-skill" (CodexSkillScopeSystem))
       (codex-test-skill "admin-skill" (CodexSkillScopeAdmin)))
      (codex:skill-metadata-budget-characters 999999)))
  (("- system-skill: desc (file: /tmp/system-skill/SKILL.md)"
    "- admin-skill: desc (file: /tmp/admin-skill/SKILL.md)"
    "- repo-skill: desc (file: /tmp/repo-skill/SKILL.md)"
    "- user-skill: desc (file: /tmp/user-skill/SKILL.md)")))

!(assertEqualToResult
  (codex:build-available-skills () (codex:skill-metadata-budget-characters 100))
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-line-render-full
    (codex:skill-line-from-skill
      (CodexSkillMetadata
        "win-skill"
        "desc"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        "C:\\tmp\\win-skill\\SKILL.md"
        (CodexSkillScopeUser)
        True)))
  ("- win-skill: desc (file: C:/tmp/win-skill/SKILL.md)"))

!(assertEqualToResult
  (let $alpha
    (codex-test-skill-with-description "alpha-skill" (CodexSkillScopeRepo) "abcdef")
    (let $beta
      (codex-test-skill-with-description "beta-skill" (CodexSkillScopeRepo) "uvwxyz")
      (let $budget
        (codex:skill-metadata-budget-characters
          (+ (codex-test-minimum-cost ($alpha $beta)) 6))
        (codex:skill-render-available-skills-lines
          (codex:build-available-skills ($beta $alpha) $budget)))))
  (("- alpha-skill: ab (file: /tmp/alpha-skill/SKILL.md)"
    "- beta-skill: uv (file: /tmp/beta-skill/SKILL.md)")))

!(assertEqualToResult
  (let $alpha
    (codex-test-skill-with-description "alpha-skill" (CodexSkillScopeRepo) "abcdef")
    (let $beta
      (codex-test-skill-with-description "beta-skill" (CodexSkillScopeRepo) "uvwxyz")
      (let $budget
        (codex:skill-metadata-budget-characters
          (+ (codex-test-minimum-cost ($alpha $beta)) 6))
        (codex:skill-render-available-skills-report
          (codex:build-available-skills ($beta $alpha) $budget)))))
  ((CodexSkillRenderReport 2 2 0 8 2)))

!(assertEqualToResult
  (let $alpha
    (codex-test-skill-with-description
      "alpha-skill"
      (CodexSkillScopeRepo)
      "abcdefghijklmnop")
    (let $beta
      (codex-test-skill-with-description
        "beta-skill"
        (CodexSkillScopeRepo)
        "uvwxyzabcdefghij")
      (let $budget
        (codex:skill-metadata-budget-characters
          (+ (codex-test-minimum-cost ($alpha $beta)) 6))
        (codex:skill-render-available-skills-warning-message
          (codex:build-available-skills ($alpha $beta) $budget)))))
  ("Warning: Exceeded skills context budget. Loaded skill descriptions were truncated by an average of 14 characters per skill."))

!(assertEqualToResult
  (let $short
    (codex-test-skill-with-description "short-skill" (CodexSkillScopeRepo) "x")
    (let $long
      (codex-test-skill-with-description "long-skill" (CodexSkillScopeRepo) "abcdefghi")
      (let $budget
        (codex:skill-metadata-budget-characters
          (+ (codex-test-minimum-cost ($short $long)) 11))
        (codex:skill-render-available-skills-lines
          (codex:build-available-skills ($short $long) $budget)))))
  (("- long-skill: abcdefgh (file: /tmp/long-skill/SKILL.md)"
    "- short-skill: x (file: /tmp/short-skill/SKILL.md)")))

!(assertEqualToResult
  (let $system (codex-test-skill "system-skill" (CodexSkillScopeSystem))
    (let $user (codex-test-skill "user-skill" (CodexSkillScopeUser))
      (let $repo (codex-test-skill "repo-skill" (CodexSkillScopeRepo))
        (let $admin (codex-test-skill "admin-skill" (CodexSkillScopeAdmin))
          (let $budget
            (codex:skill-metadata-budget-characters
              (+ (codex:skill-line-minimum-cost
                   (codex:skill-line-from-skill $system)
                   (codex:skill-metadata-budget-characters 999999))
                 (codex:skill-line-minimum-cost
                   (codex:skill-line-from-skill $admin)
                   (codex:skill-metadata-budget-characters 999999))))
            (codex:skill-render-available-skills-lines
              (codex:build-available-skills
                ($system $user $repo $admin)
                $budget)))))))
  (("- system-skill: (file: /tmp/system-skill/SKILL.md)"
    "- admin-skill: (file: /tmp/admin-skill/SKILL.md)")))

!(assertEqualToResult
  (let $system (codex-test-skill "system-skill" (CodexSkillScopeSystem))
    (let $user (codex-test-skill "user-skill" (CodexSkillScopeUser))
      (let $repo (codex-test-skill "repo-skill" (CodexSkillScopeRepo))
        (let $admin (codex-test-skill "admin-skill" (CodexSkillScopeAdmin))
          (let $budget
            (codex:skill-metadata-budget-characters
              (+ (codex:skill-line-minimum-cost
                   (codex:skill-line-from-skill $system)
                   (codex:skill-metadata-budget-characters 999999))
                 (codex:skill-line-minimum-cost
                   (codex:skill-line-from-skill $admin)
                   (codex:skill-metadata-budget-characters 999999))))
            (codex:skill-render-available-skills-warning-message
              (codex:build-available-skills
                ($system $user $repo $admin)
                $budget)))))))
  ("Warning: Exceeded skills context budget. All skill descriptions were removed and 2 additional skills were not included in the model-visible skills list."))

!(assertEqualToResult
  (let $oversized
    (codex-test-skill-with-description
      "oversized-system-skill"
      (CodexSkillScopeSystem)
      "desc desc desc desc desc desc desc desc desc desc desc desc desc desc desc desc desc desc desc desc ")
    (let $repo (codex-test-skill "repo-skill" (CodexSkillScopeRepo))
      (let $budget
        (codex:skill-metadata-budget-characters
          (codex:skill-line-full-cost
            (codex:skill-line-from-skill $repo)
            (codex:skill-metadata-budget-characters 999999)))
        (codex:skill-render-available-skills-lines
          (codex:build-available-skills ($oversized $repo) $budget)))))
  (("- repo-skill: (file: /tmp/repo-skill/SKILL.md)")))
