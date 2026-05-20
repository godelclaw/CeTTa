!(register-module! ../codex)
!(import! &self codex:skill_config_rules)

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
  (codex:skill-config-rule-selector-from-entry
    (codex:skill-config-entry CodexAbsent " demo-skill " False))
  ((CodexSkillConfigRuleSelectorName "demo-skill")))

!(assertEqualToResult
  (codex:skill-config-rule-selector-from-entry
    (codex:skill-config-entry "/tmp/skills/../skills/demo/SKILL.md" CodexAbsent False))
  ((CodexSkillConfigRuleSelectorPath "/tmp/skills/demo/SKILL.md")))

!(assertEqualToResult
  (codex:skill-config-rule-selector-from-entry
    (codex:skill-config-entry CodexAbsent "   " False))
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-config-rule-selector-from-entry
    (codex:skill-config-entry "/tmp/demo/SKILL.md" "demo" False))
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-config-rules-entries
    (codex:skill-config-rules-from-layers
      ((codex:skill-config-layer
         (codex:skill-config-layer-source-project)
         ((codex:skill-config-entry CodexAbsent "ignored" False)))
       (codex:skill-config-layer
         (codex:skill-config-layer-source-user)
         ((codex:skill-config-entry CodexAbsent "demo" False)))
       (codex:skill-config-layer
         (codex:skill-config-layer-source-session-flags)
         ((codex:skill-config-entry CodexAbsent "demo" True)
          (codex:skill-config-entry "/tmp/alpha/SKILL.md" CodexAbsent False))))))
  (((CodexSkillConfigRule
      (CodexSkillConfigRuleSelectorName "demo")
      True)
    (CodexSkillConfigRule
      (CodexSkillConfigRuleSelectorPath "/tmp/alpha/SKILL.md")
      False))))

!(assertEqualToResult
  (codex:resolve-disabled-skill-paths
    ((codex-test-skill "demo" "/tmp/demo/SKILL.md")
     (codex-test-skill "other" "/tmp/other/SKILL.md"))
    (codex:skill-config-rules
      ((codex:skill-config-rule
         (codex:skill-config-rule-selector-name "demo")
         False)
       (codex:skill-config-rule
         (codex:skill-config-rule-selector-path "/tmp/other/SKILL.md")
         False))))
  (("/tmp/demo/SKILL.md" "/tmp/other/SKILL.md")))

!(assertEqualToResult
  (codex:resolve-disabled-skill-paths
    ((codex-test-skill "demo" "/tmp/demo/SKILL.md"))
    (codex:skill-config-rules
      ((codex:skill-config-rule
         (codex:skill-config-rule-selector-path "/tmp/demo/SKILL.md")
         False)
       (codex:skill-config-rule
         (codex:skill-config-rule-selector-name "demo")
         True))))
  (()))

!(assertEqualToResult
  (codex:resolve-disabled-skill-paths
    ((codex-test-skill "demo" "/tmp/demo/SKILL.md"))
    (codex:skill-config-rules
      ((codex:skill-config-rule
         (codex:skill-config-rule-selector-name "demo")
         False)
       (codex:skill-config-rule
         (codex:skill-config-rule-selector-path "/tmp/demo/SKILL.md")
         True))))
  (()))
