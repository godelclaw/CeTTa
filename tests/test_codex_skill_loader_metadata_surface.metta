!(register-module! ../codex)
!(import! &self codex:skill_loader_metadata)

!(assertEqualToResult
  (codex:skill-loader-sanitize-single-line "  alpha\n beta\t gamma  ")
  ("alpha beta gamma"))

!(assertEqualToResult
  (codex:skill-loader-default-skill-name "/tmp/demo-skill/SKILL.md")
  ("demo-skill"))

!(assertEqualToResult
  (codex:skill-loader-default-skill-name "/SKILL.md")
  ("skill"))

!(assertEqualToResult
  (codex:skill-loader-default-skill-name "/tmp/  spaced\nname  /SKILL.md")
  ("spaced name"))

!(assertEqualToResult
  (codex:skill-loader-validate-len "demo" 4 "name")
  ((CodexSkillLoaderOk ())))

!(assertEqualToResult
  (codex:skill-loader-parse-error-message
    (codex:skill-loader-parse-error-missing-field "name"))
  ("missing field `name`"))

!(assertEqualToResult
  (codex:skill-loader-parse-error-message
    (codex:skill-loader-parse-error-invalid-field
      "description"
      (codex:skill-loader-invalid-length-reason 3)))
  ("invalid description: exceeds maximum length of 3 characters"))

!(assertEqualToResult
  (codex:skill-loader-validate-len "" 4 "name")
  ((CodexSkillLoaderErr (CodexSkillParseErrorMissingField "name"))))

!(assertEqualToResult
  (codex:skill-loader-validate-len "abcde" 4 "name")
  ((CodexSkillLoaderErr
     (CodexSkillParseErrorInvalidField
       "name"
       "exceeds maximum length of 4 characters"))))

!(assertEqualToResult
  (codex:skill-loader-extract-frontmatter
    "---\nname: demo\r\ndescription: hello\n---\nbody\n")
  ("name: demo\ndescription: hello"))

!(assertEqualToResult
  (codex:skill-loader-extract-frontmatter
    "name: demo\n---\nbody\n")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-extract-frontmatter "---\n---\nbody\n")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-extract-frontmatter "---\nname: demo\nbody\n")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-str "  hello\nworld  " 20 "description")
  ("hello world"))

!(assertEqualToResult
  (codex:skill-loader-resolve-str "     " 20 "description")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-str "abcde" 4 "description")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-color-str " #A0b9Ff " "interface.brand_color")
  ("#A0b9Ff"))

!(assertEqualToResult
  (codex:skill-loader-resolve-color-str "#12xz89" "interface.brand_color")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-asset-path
    "/tmp/skill"
    "interface.icon_small"
    "./assets/icons/icon.png")
  ("/tmp/skill/assets/icons/icon.png"))

!(assertEqualToResult
  (codex:skill-loader-resolve-asset-path
    "/tmp/skill"
    "interface.icon_small"
    "assets/../secret.png")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-asset-path
    "/tmp/skill"
    "interface.icon_small"
    "/tmp/icon.png")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-asset-path
    "/tmp/skill"
    "interface.icon_small"
    "icons/icon.png")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-interface
    (codex:skill-loader-interface
      " Demo "
      "  Short\nsummary "
      "assets/small.png"
      CodexAbsent
      "#112233"
      "  Prompt text ")
    "/tmp/skill")
  ((CodexSkillInterface
     "Demo"
     "Short summary"
     "/tmp/skill/assets/small.png"
     CodexAbsent
     "#112233"
     "Prompt text")))

!(assertEqualToResult
  (codex:skill-loader-resolve-interface
    (codex:skill-loader-interface
      "   "
      CodexAbsent
      "outside/icon.png"
      CodexAbsent
      "blue"
      CodexAbsent)
    "/tmp/skill")
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-dependency-tool
    (codex:skill-loader-dependency-tool
      " env_var "
      " API_KEY "
      "  API\nkey "
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  ((CodexSkillToolDependency
     "env_var"
     "API_KEY"
     "API key"
     CodexAbsent
     CodexAbsent
     CodexAbsent)))

!(assertEqualToResult
  (codex:skill-loader-resolve-dependency-tool
    (codex:skill-loader-dependency-tool
      CodexAbsent
      "API_KEY"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-dependencies
    (codex:skill-loader-dependencies
      ((codex:skill-loader-dependency-tool
         "env_var"
         "API_KEY"
         "API key"
         CodexAbsent
         CodexAbsent
         CodexAbsent)
       (codex:skill-loader-dependency-tool
         "env_var"
         "   "
         CodexAbsent
         CodexAbsent
         CodexAbsent
         CodexAbsent))))
  ((CodexSkillDependencies
     ((CodexSkillToolDependency
        "env_var"
        "API_KEY"
        "API key"
        CodexAbsent
        CodexAbsent
        CodexAbsent)))))

!(assertEqualToResult
  (codex:skill-loader-resolve-dependencies
    (codex:skill-loader-dependencies
      ((codex:skill-loader-dependency-tool
         "env_var"
         "   "
         CodexAbsent
         CodexAbsent
         CodexAbsent
         CodexAbsent))))
  (CodexAbsent))

!(assertEqualToResult
  (codex:skill-loader-resolve-policy
    (codex:skill-loader-policy False ((CodexProductCodex))))
  ((CodexCoreSkillPolicy False ((CodexProductCodex)))))

!(assertEqualToResult
  (codex:skill-loader-resolve-loaded-metadata
    "/tmp/skill"
    (codex:skill-loader-interface
      "Demo"
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent
      CodexAbsent)
    (codex:skill-loader-dependencies
      ((codex:skill-loader-dependency-tool
         "env_var"
         "API_KEY"
         CodexAbsent
         CodexAbsent
         CodexAbsent
         CodexAbsent)))
    (codex:skill-loader-policy CodexAbsent ()))
  ((CodexSkillLoaderLoadedMetadata
     (CodexSkillInterface
       "Demo"
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent)
     (CodexSkillDependencies
       ((CodexSkillToolDependency
          "env_var"
          "API_KEY"
          CodexAbsent
          CodexAbsent
          CodexAbsent
          CodexAbsent)))
     (CodexCoreSkillPolicy CodexAbsent ()))))
