!(register-module! ../codex)
!(import! &self codex:tool_mentions)

(= (codex-tool-mentions-plugin $config-name $display-name)
   (CodexPluginCapabilitySummary
     $config-name
     $display-name
     CodexAbsent
     True
     ()
     ()))

!(assertEqualToResult
  (codex:tool-mention-sigil)
  ("$"))

!(assertEqualToResult
  (codex:plugin-text-mention-sigil)
  ("@"))

!(assertEqualToResult
  (codex:tool-kind-for-path "app://calendar")
  ((CodexToolMentionKindApp)))

!(assertEqualToResult
  (codex:tool-kind-for-path "mcp://docs")
  ((CodexToolMentionKindMcp)))

!(assertEqualToResult
  (codex:tool-kind-for-path "plugin://sample@test")
  ((CodexToolMentionKindPlugin)))

!(assertEqualToResult
  (codex:tool-kind-for-path "skill://team/alpha")
  ((CodexToolMentionKindSkill)))

!(assertEqualToResult
  (codex:tool-kind-for-path "/tmp/skill.md")
  ((CodexToolMentionKindSkill)))

!(assertEqualToResult
  (codex:tool-kind-for-path "/tmp/file.txt")
  ((CodexToolMentionKindOther)))

!(assertEqualToResult
  (codex:app-id-from-path "app://calendar")
  ("calendar"))

!(assertEqualToResult
  (codex:app-id-from-path "app://")
  (Empty))

!(assertEqualToResult
  (codex:plugin-config-name-from-path "plugin://sample@test")
  ("sample@test"))

!(assertEqualToResult
  (codex:normalize-skill-path "skill://team/alpha")
  ("team/alpha"))

!(assertEqualToResult
  (codex:tool-mentions-names
    (codex:extract-tool-mentions
      "use $alpha and [$beta](/tmp/beta)"))
  (("alpha" "beta")))

!(assertEqualToResult
  (codex:tool-mentions-paths
    (codex:extract-tool-mentions
      "use $alpha and [$beta](/tmp/beta)"))
  (("/tmp/beta")))

!(assertEqualToResult
  (codex:tool-mentions-plain-names
    (codex:extract-tool-mentions
      "use $alpha and [$beta](/tmp/beta)"))
  (("alpha")))

!(assertEqualToResult
  (codex:tool-mentions-names
    (codex:extract-tool-mentions
      "use $PATH and $alpha and [$HOME](/tmp/skill) and $XDG_CONFIG_HOME"))
  (("alpha")))

!(assertEqualToResult
  (codex:tool-mentions-paths
    (codex:extract-tool-mentions
      "use $PATH and $alpha and [$HOME](/tmp/skill) and $XDG_CONFIG_HOME"))
  (()))

!(assertEqualToResult
  (codex:tool-mentions-names
    (codex:extract-tool-mentions "[$beta] /tmp/beta and [$gamma]()"))
  (("beta" "gamma")))

!(assertEqualToResult
  (codex:tool-mentions-paths
    (codex:extract-tool-mentions "use [$beta]   ( /tmp/beta )"))
  (("/tmp/beta")))

!(assertEqualToResult
  (codex:tool-mentions-names
    (codex:extract-tool-mentions "use $alpha.skill and $beta_extra"))
  (("alpha" "beta_extra")))

!(assertEqualToResult
  (codex:tool-mentions-names
    (codex:extract-tool-mentions "use $slack:search and $alpha"))
  (("slack:search" "alpha")))

!(assertEqualToResult
  (codex:text-mentions-skill "use $notion-research-doc please" "notion-research-doc")
  (True))

!(assertEqualToResult
  (codex:text-mentions-skill "$notion-research-docs" "notion-research-doc")
  (False))

!(assertEqualToResult
  (codex:text-mentions-skill "$alpha-skillx and later $alpha-skill " "alpha-skill")
  (True))

!(assertEqualToResult
  (codex:text-mentions-skill "$$$$$ not-a-mention" "alpha-skill")
  (False))

!(assertEqualToResult
  (codex:collect-explicit-app-ids
    ((CodexUserInputText "use [$calendar](app://calendar)" ())
     (CodexUserInputMention "calendar" "app://calendar")))
  (("calendar")))

!(assertEqualToResult
  (codex:collect-explicit-app-ids
    ((CodexUserInputText
       "use [$docs](mcp://docs) and [$skill](skill://team/skill) and [$file](/tmp/file.txt)")
       ()
     (CodexUserInputMention "docs" "mcp://docs")
     (CodexUserInputMention "skill" "skill://team/skill")
     (CodexUserInputMention "file" "/tmp/file.txt")))
  (()))

!(assertEqualToResult
  (codex:collect-explicit-plugin-mentions
    ((CodexUserInputMention "sample" "plugin://sample@test"))
    ((codex-tool-mentions-plugin "sample@test" "sample")
     (codex-tool-mentions-plugin "other@test" "other")))
  (((CodexPluginCapabilitySummary
      "sample@test"
      "sample"
      CodexAbsent
      True
      ()
      ()))))

!(assertEqualToResult
  (codex:collect-explicit-plugin-mentions
    ((CodexUserInputText "use [@sample](plugin://sample@test)" ())
     (CodexUserInputMention "sample" "plugin://sample@test"))
    ((codex-tool-mentions-plugin "sample@test" "sample")
     (codex-tool-mentions-plugin "other@test" "other")))
  (((CodexPluginCapabilitySummary
      "sample@test"
      "sample"
      CodexAbsent
      True
      ()
      ()))))

!(assertEqualToResult
  (codex:collect-explicit-plugin-mentions
    ((CodexUserInputText "use [$sample](plugin://sample@test)" ()))
    ((codex-tool-mentions-plugin "sample@test" "sample")))
  (()))
