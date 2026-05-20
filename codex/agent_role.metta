; Rust-faithful pure agent-role helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/agent/role.rs
;
; Covered in this increment:
; - DEFAULT_ROLE_NAME and unavailable-role error text
; - AgentRoleConfig data shape used by role resolution and spawn-tool docs
; - built-in default/explorer/worker role declarations
; - resolve_role_config user-before-built-in lookup behavior
; - spawn_tool_spec::build_from_configs ordering, dedupe, and role formatting
;
; Required CeTTa representation notes for audit:
; - Rust stores role maps in BTreeMap. This pure CeTTa boundary receives ordered
;   entry lists; callers at the TOML/config boundary must feed entries in Rust
;   BTreeMap order.
; - Rust format_role reads a role config file, parses TOML, and looks for
;   `model` / `model_reasoning_effort`. CeTTa has no TOML parser in this slice,
;   so the file/TOML boundary is represented by pre-parsed
;   CodexAgentRoleLayerToml entries. The string-formatting branch behavior is
;   kept identical once those parsed fields are available.

!(import! &self list)
!(import! &self str)

(= (codex:agent-role-default-role-name)
   "default")

(= (codex:agent-role-unavailable-error)
   "agent type is currently not available")

(= (codex:agent-role-config
      $description
      $config-file
      $nickname-candidates)
   (CodexAgentRoleConfig
     $description
     $config-file
     $nickname-candidates))

(= (codex:agent-role-config-description
      (CodexAgentRoleConfig $description $config-file $nickname-candidates))
   $description)

(= (codex:agent-role-config-config-file
      (CodexAgentRoleConfig $description $config-file $nickname-candidates))
   $config-file)

(= (codex:agent-role-config-nickname-candidates
      (CodexAgentRoleConfig $description $config-file $nickname-candidates))
   $nickname-candidates)

(= (codex:agent-role-entry $name $config)
   (CodexAgentRoleEntry $name $config))

(= (codex:agent-role-entry-name (CodexAgentRoleEntry $name $config))
   $name)

(= (codex:agent-role-entry-config (CodexAgentRoleEntry $name $config))
   $config)

(= (codex:agent-role-layer-toml $model $model-reasoning-effort)
   (CodexAgentRoleLayerToml $model $model-reasoning-effort))

(= (codex:agent-role-layer-toml-model
      (CodexAgentRoleLayerToml $model $model-reasoning-effort))
   $model)

(= (codex:agent-role-layer-toml-model-reasoning-effort
      (CodexAgentRoleLayerToml $model $model-reasoning-effort))
   $model-reasoning-effort)

(= (codex:agent-role-layer-entry $config-file $layer-toml)
   (CodexAgentRoleLayerEntry $config-file $layer-toml))

(= (codex:agent-role-layer-entry-config-file
      (CodexAgentRoleLayerEntry $config-file $layer-toml))
   $config-file)

(= (codex:agent-role-layer-entry-layer-toml
      (CodexAgentRoleLayerEntry $config-file $layer-toml))
   $layer-toml)

(= (codex:agent-role-builtin-default-description)
   "Default agent.")

(= (codex:agent-role-builtin-explorer-description)
   "Use `explorer` for specific codebase questions.
Explorers are fast and authoritative.
They must be used to ask specific, well-scoped questions on the codebase.
Rules:
- In order to avoid redundant work, you should avoid exploring the same problem that explorers have already covered. Typically, you should trust the explorer results without additional verification. You are still allowed to inspect the code yourself to gain the needed context!
- You are encouraged to spawn up multiple explorers in parallel when you have multiple distinct questions to ask about the codebase that can be answered independently. This allows you to get more information faster without waiting for one question to finish before asking the next. While waiting for the explorer results, you can continue working on other local tasks that do not depend on those results. This parallelism is a key advantage of delegation, so use it whenever you have multiple questions to ask.
- Reuse existing explorers for related questions.")

(= (codex:agent-role-builtin-worker-description)
   "Use for execution and production work.
Typical tasks:
- Implement part of a feature
- Fix tests or bugs
- Split large refactors into independent chunks
Rules:
- Explicitly assign **ownership** of the task (files / responsibility). When the subtask involves code changes, you should clearly specify which files or modules the worker is responsible for. This helps avoid merge conflicts and ensures accountability. For example, you can say \"Worker 1 is responsible for updating the authentication module, while Worker 2 will handle the database layer.\" By defining clear ownership, you can delegate more effectively and reduce coordination overhead.
- Always tell workers they are **not alone in the codebase**, and they should not revert the edits made by others, and they should adjust their implementation to accommodate the changes made by others. This is important because there may be multiple workers making changes in parallel, and they need to be aware of each other's work to avoid conflicts and ensure a cohesive final product.")

(= (codex:agent-role-built-in-configs)
   ((codex:agent-role-entry
      (codex:agent-role-default-role-name)
      (codex:agent-role-config
        (codex:agent-role-builtin-default-description)
        CodexAbsent
        CodexAbsent))
    (codex:agent-role-entry
      "explorer"
      (codex:agent-role-config
        (codex:agent-role-builtin-explorer-description)
        "explorer.toml"
        CodexAbsent))
    (codex:agent-role-entry
      "worker"
      (codex:agent-role-config
        (codex:agent-role-builtin-worker-description)
        CodexAbsent
        CodexAbsent))))

(= (codex:agent-role-built-in-layer-tomls)
   ((codex:agent-role-layer-entry
      "explorer.toml"
      (codex:agent-role-layer-toml CodexAbsent CodexAbsent))
    (codex:agent-role-layer-entry
      "awaiter.toml"
      (codex:agent-role-layer-toml CodexAbsent "low"))))

(= (codex:agent-role-entry-list-get () $name)
   CodexAbsent)

(= (codex:agent-role-entry-list-get $entries $name)
   (let $entry (list:first $entries)
     (if (== (codex:agent-role-entry-name $entry) $name)
         (codex:agent-role-entry-config $entry)
         (codex:agent-role-entry-list-get
           (list:rest $entries)
           $name))))

(= (codex:agent-role-resolve-role-config
      $user-defined-roles
      $built-in-roles
      $role-name)
   (let $user-role
     (codex:agent-role-entry-list-get $user-defined-roles $role-name)
     (if (== $user-role CodexAbsent)
         (codex:agent-role-entry-list-get $built-in-roles $role-name)
         $user-role)))

(= (codex:agent-role-resolve-role-config-with-built-ins
      $user-defined-roles
      $role-name)
   (codex:agent-role-resolve-role-config
     $user-defined-roles
     (codex:agent-role-built-in-configs)
     $role-name))

(= (codex:agent-role-select-role-name $role-name)
   (if (== $role-name CodexAbsent)
       (codex:agent-role-default-role-name)
       $role-name))

(= (codex:agent-role-resolve-selected-role-config
      $user-defined-roles
      $role-name)
   (codex:agent-role-resolve-role-config-with-built-ins
     $user-defined-roles
     (codex:agent-role-select-role-name $role-name)))

(= (codex:agent-role-name-seen $seen $name)
   (if (== $seen ())
       False
       (if (== (list:first $seen) $name)
           True
           (codex:agent-role-name-seen (list:rest $seen) $name))))

(= (codex:agent-role-layer-toml-for-config-file () $config-file)
   CodexAbsent)

(= (codex:agent-role-layer-toml-for-config-file $layers $config-file)
   (let $entry (list:first $layers)
     (if (== (codex:agent-role-layer-entry-config-file $entry) $config-file)
         (codex:agent-role-layer-entry-layer-toml $entry)
         (codex:agent-role-layer-toml-for-config-file
           (list:rest $layers)
           $config-file))))

(= (codex:agent-role-locked-settings-note-from-layer $layer-toml)
   (let $model (codex:agent-role-layer-toml-model $layer-toml)
     (let $reasoning-effort
       (codex:agent-role-layer-toml-model-reasoning-effort $layer-toml)
       (if (== $model CodexAbsent)
           (if (== $reasoning-effort CodexAbsent)
               ""
               (str-concat
                 "\n- This role's reasoning effort is set to `"
                 (str-concat
                   $reasoning-effort
                   "` and cannot be changed.")))
           (if (== $reasoning-effort CodexAbsent)
               (str-concat
                 "\n- This role's model is set to `"
                 (str-concat
                   $model
                   "` and cannot be changed."))
               (str-concat
                 "\n- This role's model is set to `"
                 (str-concat
                   $model
                   (str-concat
                     "` and its reasoning effort is set to `"
                     (str-concat
                       $reasoning-effort
                       "`. These settings cannot be changed.")))))))))

(= (codex:agent-role-locked-settings-note $config-file $layers)
   (if (== $config-file CodexAbsent)
       ""
       (let $layer-toml
         (codex:agent-role-layer-toml-for-config-file $layers $config-file)
         (if (== $layer-toml CodexAbsent)
             ""
             (codex:agent-role-locked-settings-note-from-layer $layer-toml)))))

(= (codex:agent-role-format-role $name $config $layers)
   (let $description (codex:agent-role-config-description $config)
     (if (== $description CodexAbsent)
         (str-concat $name ": no description")
         (str-concat
           $name
           (str-concat
             ": {\n"
             (str-concat
               $description
               (str-concat
                 (codex:agent-role-locked-settings-note
                   (codex:agent-role-config-config-file $config)
                   $layers)
                 "\n}")))))))

(= (codex:agent-role-spawn-tool-spec-collect
      ()
      $seen
      $layers)
   ())

(= (codex:agent-role-spawn-tool-spec-collect
      $entries
      $seen
      $layers)
   (let $entry (list:first $entries)
     (let $tail (list:rest $entries)
       (let $name (codex:agent-role-entry-name $entry)
         (if (codex:agent-role-name-seen $seen $name)
             (codex:agent-role-spawn-tool-spec-collect
               $tail
               $seen
               $layers)
             (let $formatted
               (codex:agent-role-format-role
                 $name
                 (codex:agent-role-entry-config $entry)
                 $layers)
               (let $rest
                 (codex:agent-role-spawn-tool-spec-collect
                   $tail
                   (list:push $seen $name)
                   $layers)
                 (cons-atom $formatted $rest))))))))

(= (codex:agent-role-spawn-tool-spec-build-from-configs
      $built-in-roles
      $user-defined-roles
      $config-layers)
   (let $roles
     (codex:agent-role-spawn-tool-spec-collect
       (list:append $user-defined-roles $built-in-roles)
       ()
       $config-layers)
     (str-concat
       "Optional type name for the new agent. If omitted, `default` is used.\nAvailable roles:\n"
       (str-join "\n" $roles))))

(= (codex:agent-role-spawn-tool-spec-build $user-defined-roles)
   (codex:agent-role-spawn-tool-spec-build-from-configs
     (codex:agent-role-built-in-configs)
     $user-defined-roles
     (codex:agent-role-built-in-layer-tomls)))
