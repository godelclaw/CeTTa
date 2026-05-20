!(register-module! ../codex)
!(import! &self codex:skill_model)

(= (codex-test-core-skill $name $path $policy)
   (codex:core-skill-metadata
     $name
     "desc"
     CodexAbsent
     CodexAbsent
     CodexAbsent
     $policy
     $path
     (CodexSkillScopeRepo)))

(= (codex-test-outcome $skills $disabled-paths)
   (codex:core-skill-load-outcome
     $skills
     ((codex:core-skill-error "/tmp/bad/SKILL.md" "bad skill"))
     $disabled-paths
     ((codex:skill-file-system-entry "/tmp/codex/SKILL.md" FsCodex)
      (codex:skill-file-system-entry "/tmp/atlas/SKILL.md" FsAtlas)
      (codex:skill-file-system-entry "/tmp/free/SKILL.md" FsFree))
     ((codex:core-skill-path-index-entry "/tmp/codex/scripts" (codex-test-core-skill "codex-only" "/tmp/codex/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductCodex)))))
      (codex:core-skill-path-index-entry "/tmp/atlas/scripts" (codex-test-core-skill "atlas-only" "/tmp/atlas/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductAtlas)))))
      (codex:core-skill-path-index-entry "/tmp/free/scripts" (codex-test-core-skill "free" "/tmp/free/SKILL.md" CodexAbsent)))
     ((codex:core-skill-path-index-entry "/tmp/codex/SKILL.md" (codex-test-core-skill "codex-only" "/tmp/codex/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductCodex)))))
      (codex:core-skill-path-index-entry "/tmp/atlas/SKILL.md" (codex-test-core-skill "atlas-only" "/tmp/atlas/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductAtlas)))))
      (codex:core-skill-path-index-entry "/tmp/free/SKILL.md" (codex-test-core-skill "free" "/tmp/free/SKILL.md" CodexAbsent)))))

!(assertEqualToResult
  (codex:core-skill-allow-implicit-invocation
    (codex-test-core-skill "no-policy" "/tmp/no-policy/SKILL.md" CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:core-skill-allow-implicit-invocation
    (codex-test-core-skill
      "default-policy"
      "/tmp/default-policy/SKILL.md"
      (codex:core-skill-policy CodexAbsent ())))
  (True))

!(assertEqualToResult
  (codex:core-skill-allow-implicit-invocation
    (codex-test-core-skill
      "blocked"
      "/tmp/blocked/SKILL.md"
      (codex:core-skill-policy False ())))
  (False))

!(assertEqualToResult
  (codex:core-skill-matches-product-restriction-for-product
    (codex-test-core-skill "no-policy" "/tmp/no-policy/SKILL.md" CodexAbsent)
    CodexAbsent)
  (True))

!(assertEqualToResult
  (codex:core-skill-matches-product-restriction-for-product
    (codex-test-core-skill
      "empty-products"
      "/tmp/empty/SKILL.md"
      (codex:core-skill-policy CodexAbsent ()))
    CodexAbsent)
  (True))

!(assertEqualToResult
  (codex:core-skill-matches-product-restriction-for-product
    (codex-test-core-skill
      "codex-only"
      "/tmp/codex/SKILL.md"
      (codex:core-skill-policy CodexAbsent ((CodexProductCodex))))
    CodexAbsent)
  (False))

!(assertEqualToResult
  (codex:core-skill-matches-product-restriction-for-product
    (codex-test-core-skill
      "codex-only"
      "/tmp/codex/SKILL.md"
      (codex:core-skill-policy CodexAbsent ((CodexProductCodex))))
    (CodexProductCodex))
  (True))

!(assertEqualToResult
  (codex:core-skill-matches-product-restriction-for-product
    (codex-test-core-skill
      "codex-only"
      "/tmp/codex/SKILL.md"
      (codex:core-skill-policy CodexAbsent ((CodexProductCodex))))
    (CodexProductAtlas))
  (False))

!(assertEqualToResult
  (let $enabled (codex-test-core-skill "enabled" "/tmp/enabled/SKILL.md" CodexAbsent)
    (let $disabled
      (codex-test-core-skill
        "disabled"
        "/tmp/disabled/SKILL.md"
        (codex:core-skill-policy False ()))
      (let $outcome
        (codex:core-skill-load-outcome
          ($enabled $disabled)
          ()
          ("/tmp/disabled/SKILL.md")
          ()
          ()
          ())
        (codex:core-skill-load-outcome-allowed-skills-for-implicit-invocation
          $outcome))))
  (((CodexCoreSkillMetadata
      "enabled"
      "desc"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      "/tmp/enabled/SKILL.md"
      (CodexSkillScopeRepo)))))

!(assertEqualToResult
  (let $enabled (codex-test-core-skill "enabled" "/tmp/enabled/SKILL.md" CodexAbsent)
    (let $disabled (codex-test-core-skill "disabled" "/tmp/disabled/SKILL.md" CodexAbsent)
      (let $outcome
        (codex:core-skill-load-outcome
          ($enabled $disabled)
          ()
          ("/tmp/disabled/SKILL.md")
          ()
          ()
          ())
        (codex:core-skill-load-outcome-skills-with-enabled $outcome))))
  (((CodexCoreSkillWithEnabled
      (CodexCoreSkillMetadata
        "enabled"
        "desc"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        "/tmp/enabled/SKILL.md"
        (CodexSkillScopeRepo))
      True)
    (CodexCoreSkillWithEnabled
      (CodexCoreSkillMetadata
        "disabled"
        "desc"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        "/tmp/disabled/SKILL.md"
        (CodexSkillScopeRepo))
      False))))

!(assertEqualToResult
  (let $codex (codex-test-core-skill "codex-only" "/tmp/codex/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductCodex))))
    (let $atlas (codex-test-core-skill "atlas-only" "/tmp/atlas/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductAtlas))))
      (let $free (codex-test-core-skill "free" "/tmp/free/SKILL.md" CodexAbsent)
        (let $filtered
          (codex:filter-skill-load-outcome-for-product
            (codex-test-outcome ($codex $atlas $free) ("/tmp/atlas/SKILL.md"))
            (CodexProductCodex))
          (codex:core-skill-load-outcome-skills $filtered)))))
  (((CodexCoreSkillMetadata
      "codex-only"
      "desc"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      (CodexCoreSkillPolicy CodexAbsent ((CodexProductCodex)))
      "/tmp/codex/SKILL.md"
      (CodexSkillScopeRepo))
    (CodexCoreSkillMetadata
      "free"
      "desc"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      "/tmp/free/SKILL.md"
      (CodexSkillScopeRepo)))))

!(assertEqualToResult
  (let $codex (codex-test-core-skill "codex-only" "/tmp/codex/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductCodex))))
    (let $atlas (codex-test-core-skill "atlas-only" "/tmp/atlas/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductAtlas))))
      (let $free (codex-test-core-skill "free" "/tmp/free/SKILL.md" CodexAbsent)
        (let $filtered
          (codex:filter-skill-load-outcome-for-product
            (codex-test-outcome ($codex $atlas $free) ("/tmp/atlas/SKILL.md"))
            (CodexProductCodex))
          (codex:core-skill-load-outcome-disabled-paths $filtered)))))
  (("/tmp/atlas/SKILL.md")))

!(assertEqualToResult
  (let $codex (codex-test-core-skill "codex-only" "/tmp/codex/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductCodex))))
    (let $atlas (codex-test-core-skill "atlas-only" "/tmp/atlas/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductAtlas))))
      (let $free (codex-test-core-skill "free" "/tmp/free/SKILL.md" CodexAbsent)
        (let $filtered
          (codex:filter-skill-load-outcome-for-product
            (codex-test-outcome ($codex $atlas $free) ("/tmp/atlas/SKILL.md"))
            (CodexProductCodex))
          (codex:core-skill-load-outcome-file-systems-by-skill-path $filtered)))))
  (((CodexSkillFileSystemEntry "/tmp/codex/SKILL.md" FsCodex)
    (CodexSkillFileSystemEntry "/tmp/free/SKILL.md" FsFree))))

!(assertEqualToResult
  (let $codex (codex-test-core-skill "codex-only" "/tmp/codex/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductCodex))))
    (let $atlas (codex-test-core-skill "atlas-only" "/tmp/atlas/SKILL.md" (codex:core-skill-policy CodexAbsent ((CodexProductAtlas))))
      (let $free (codex-test-core-skill "free" "/tmp/free/SKILL.md" CodexAbsent)
        (let $filtered
          (codex:filter-skill-load-outcome-for-product
            (codex-test-outcome ($codex $atlas $free) ("/tmp/atlas/SKILL.md"))
            (CodexProductCodex))
          (codex:core-skill-load-outcome-implicit-skills-by-scripts-dir $filtered)))))
  (((CodexCoreSkillPathIndexEntry
      "/tmp/codex/scripts"
      (CodexCoreSkillMetadata
        "codex-only"
        "desc"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        (CodexCoreSkillPolicy CodexAbsent ((CodexProductCodex)))
        "/tmp/codex/SKILL.md"
        (CodexSkillScopeRepo)))
    (CodexCoreSkillPathIndexEntry
      "/tmp/free/scripts"
      (CodexCoreSkillMetadata
        "free"
        "desc"
        CodexAbsent
        CodexAbsent
        CodexAbsent
        CodexAbsent
        "/tmp/free/SKILL.md"
        (CodexSkillScopeRepo))))))
