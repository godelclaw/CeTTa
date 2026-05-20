!(register-module! ../codex)
!(import! &self codex:skill_manager)
!(import! &self codex:skill_model)

(= (codex-test-manager-skill $name $path $policy $scope)
   (codex:core-skill-metadata
     $name
     "desc"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     $policy
     $path
     $scope))

(= (codex-test-manager-outcome $skills)
   (codex:core-skill-load-outcome
     $skills
     ((codex:core-skill-error "/tmp/bad/SKILL.md" "bad skill"))
     ()
     ((codex:skill-file-system-entry "/tmp/enabled/SKILL.md" FsEnabled)
      (codex:skill-file-system-entry "/tmp/disabled/SKILL.md" FsDisabled)
      (codex:skill-file-system-entry "/tmp/implicit-false/SKILL.md" FsImplicitFalse)
      (codex:skill-file-system-entry "/tmp/atlas/SKILL.md" FsAtlas))
     ((codex:core-skill-path-index-entry "/stale/scripts" StaleSkill))
     ((codex:core-skill-path-index-entry "/stale/SKILL.md" StaleSkill))))

!(assertEqualToResult
  (codex:skill-manager-scope-rank (CodexSkillScopeRepo))
  (0))

!(assertEqualToResult
  (codex:skill-manager-scope-rank (CodexSkillScopeUser))
  (1))

!(assertEqualToResult
  (codex:skill-manager-scope-rank (CodexSkillScopeSystem))
  (2))

!(assertEqualToResult
  (codex:skill-manager-scope-rank (CodexSkillScopeAdmin))
  (3))

!(assertEqualToResult
  (codex:config-skills-cache-key
    ((codex:skill-root "/repo/skills" (CodexSkillScopeRepo) FsRepo)
     (codex:skill-root "/user/skills" (CodexSkillScopeUser) FsUser)
     (codex:skill-root "/system/skills" (CodexSkillScopeSystem) FsSystem)
     (codex:skill-root "/admin/skills" (CodexSkillScopeAdmin) FsAdmin))
    DemoRules)
  ((CodexConfigSkillsCacheKey
     ((CodexSkillManagerRootCacheKey "/repo/skills" 0)
      (CodexSkillManagerRootCacheKey "/user/skills" 1)
      (CodexSkillManagerRootCacheKey "/system/skills" 2)
      (CodexSkillManagerRootCacheKey "/admin/skills" 3))
     DemoRules)))

!(assertEqualToResult
  (codex:dedupe-skill-roots-by-path
    ((codex:skill-root "/same" (CodexSkillScopeRepo) FsFirst)
     (codex:skill-root "/other" (CodexSkillScopeUser) FsOther)
     (codex:skill-root "/same" (CodexSkillScopeAdmin) FsSecond)))
  (((CodexSkillRoot "/same" (CodexSkillScopeRepo) FsFirst)
    (CodexSkillRoot "/other" (CodexSkillScopeUser) FsOther))))

!(assertEqualToResult
  (codex:normalize-extra-user-roots
    ("/tmp/b"
     "/tmp/a"
     "/tmp/b/../b"
     "/tmp/a/./"))
  (("/tmp/a" "/tmp/b")))

!(assertEqualToResult
  (let $enabled
    (codex-test-manager-skill
      "enabled"
      "/tmp/enabled/SKILL.md"
      CodexAbsent
      (CodexSkillScopeRepo))
    (let $disabled
      (codex-test-manager-skill
        "disabled"
        "/tmp/disabled/SKILL.md"
        CodexAbsent
        (CodexSkillScopeRepo))
      (let $implicit-false
        (codex-test-manager-skill
          "implicit-false"
          "/tmp/implicit-false/SKILL.md"
          (codex:core-skill-policy False ())
          (CodexSkillScopeRepo))
        (let $outcome
          (codex-test-manager-outcome
            ($enabled $disabled $implicit-false))
          (codex:core-skill-load-outcome-implicit-skills-by-scripts-dir
            (codex:skill-manager-finalize-skill-outcome
              $outcome
              ("/tmp/disabled/SKILL.md")))))))
  (((CodexCoreSkillPathIndexEntry
      "/tmp/enabled/scripts"
      (CodexCoreSkillMetadata
        "enabled"
        "desc"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        "/tmp/enabled/SKILL.md"
        (CodexSkillScopeRepo))))))

!(assertEqualToResult
  (let $enabled
    (codex-test-manager-skill
      "enabled"
      "/tmp/enabled/SKILL.md"
      CodexAbsent
      (CodexSkillScopeRepo))
    (let $disabled
      (codex-test-manager-skill
        "disabled"
        "/tmp/disabled/SKILL.md"
        CodexAbsent
        (CodexSkillScopeRepo))
      (let $implicit-false
        (codex-test-manager-skill
          "implicit-false"
          "/tmp/implicit-false/SKILL.md"
          (codex:core-skill-policy False ())
          (CodexSkillScopeRepo))
        (let $outcome
          (codex-test-manager-outcome
            ($enabled $disabled $implicit-false))
          (codex:core-skill-load-outcome-implicit-skills-by-doc-path
            (codex:skill-manager-finalize-skill-outcome
              $outcome
              ("/tmp/disabled/SKILL.md")))))))
  (((CodexCoreSkillPathIndexEntry
      "/tmp/enabled/SKILL.md"
      (CodexCoreSkillMetadata
        "enabled"
        "desc"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        "/tmp/enabled/SKILL.md"
        (CodexSkillScopeRepo))))))

!(assertEqualToResult
  (let $enabled
    (codex-test-manager-skill
      "enabled"
      "/tmp/enabled/SKILL.md"
      CodexAbsent
      (CodexSkillScopeRepo))
    (let $disabled
      (codex-test-manager-skill
        "disabled"
        "/tmp/disabled/SKILL.md"
        CodexAbsent
        (CodexSkillScopeRepo))
      (let $outcome
        (codex-test-manager-outcome ($enabled $disabled))
        (codex:core-skill-load-outcome-disabled-paths
          (codex:skill-manager-finalize-skill-outcome
            $outcome
            ("/tmp/disabled/SKILL.md"))))))
  (("/tmp/disabled/SKILL.md")))

!(assertEqualToResult
  (let $codex-only
    (codex-test-manager-skill
      "codex-only"
      "/tmp/codex/SKILL.md"
      (codex:core-skill-policy CodexAbsent ((CodexProductCodex)))
      (CodexSkillScopeRepo))
    (let $atlas-only
      (codex-test-manager-skill
        "atlas-only"
        "/tmp/atlas/SKILL.md"
        (codex:core-skill-policy CodexAbsent ((CodexProductAtlas)))
        (CodexSkillScopeRepo))
      (let $loaded
        (codex-test-manager-outcome ($codex-only $atlas-only))
        (codex:core-skill-load-outcome-skills
          (codex:skill-manager-build-skill-outcome-from-loaded-outcome
            $loaded
            (CodexProductCodex)
            ()))))))
  (((CodexCoreSkillMetadata
      "codex-only"
      "desc"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      (CodexCoreSkillPolicy CodexAbsent ((CodexProductCodex)))
      "/tmp/codex/SKILL.md"
      (CodexSkillScopeRepo))))

!(assertEqualToResult
  (let $codex-only
    (codex-test-manager-skill
      "codex-only"
      "/tmp/codex/SKILL.md"
      (codex:core-skill-policy CodexAbsent ((CodexProductCodex)))
      (CodexSkillScopeRepo))
    (let $atlas-only
      (codex-test-manager-skill
        "atlas-only"
        "/tmp/atlas/SKILL.md"
        (codex:core-skill-policy CodexAbsent ((CodexProductAtlas)))
        (CodexSkillScopeRepo))
      (let $loaded
        (codex-test-manager-outcome ($codex-only $atlas-only))
        (codex:core-skill-load-outcome-implicit-skills-by-doc-path
          (codex:skill-manager-build-skill-outcome-from-loaded-outcome
            $loaded
            (CodexProductCodex)
            ()))))))
  (((CodexCoreSkillPathIndexEntry
      "/tmp/codex/SKILL.md"
      (CodexCoreSkillMetadata
        "codex-only"
        "desc"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        (CodexCoreSkillPolicy CodexAbsent ((CodexProductCodex)))
        "/tmp/codex/SKILL.md"
        (CodexSkillScopeRepo)))))
