!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:item-type
    (codex:list-skills-response-event ()))
  ("list_skills_response"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:list-skills-response-event
        ((codex:skills-list-entry
           "/repo"
           ((codex:skill-metadata
              "imagegen"
              "Generate images"
              CodexAbsent
              CodexAbsent
              CodexAbsent
              "/skills/imagegen"
              (codex:skill-scope-system)
              True)
            (codex:skill-metadata
              "plugin-skill"
              "From plugin"
              "Short"
              (codex:skill-interface
                "Plugin Skill"
                CodexAbsent
                CodexAbsent
                CodexAbsent
                "#00AA88"
                CodexAbsent)
              (codex:skill-dependencies
                ((codex:skill-tool-dependency
                   "mcp"
                   "server:tool"
                   "Uses MCP"
                   "stdio"
                   CodexAbsent
                   CodexAbsent)))
              "/skills/plugin"
              (codex:skill-scope-repo)
              False))
           ((codex:skill-error-info
              "/repo/.codex/bad-skill"
              "Failed to parse SKILL.md")))))))
  ("{\"type\":\"list_skills_response\",\"skills\":[{\"cwd\":\"/repo\",\"skills\":[{\"name\":\"imagegen\",\"description\":\"Generate images\",\"path\":\"/skills/imagegen\",\"scope\":\"system\",\"enabled\":true},{\"name\":\"plugin-skill\",\"description\":\"From plugin\",\"short_description\":\"Short\",\"interface\":{\"display_name\":\"Plugin Skill\",\"short_description\":null,\"icon_small\":null,\"icon_large\":null,\"brand_color\":\"#00AA88\",\"default_prompt\":null},\"dependencies\":{\"tools\":[{\"type\":\"mcp\",\"value\":\"server:tool\",\"description\":\"Uses MCP\",\"transport\":\"stdio\"}]},\"path\":\"/skills/plugin\",\"scope\":\"repo\",\"enabled\":false}],\"errors\":[{\"path\":\"/repo/.codex/bad-skill\",\"message\":\"Failed to parse SKILL.md\"}]}]}"))
