!(register-module! ../codex)
!(import! &self codex:agent_role)
!(import! &self str)

(= (test:custom-role-config)
   (codex:agent-role-config
     "Custom role."
     "/tmp/custom-role.toml"
     ("Ada" "Grace")))

(= (test:custom-role-entry)
   (codex:agent-role-entry "custom" (test:custom-role-config)))

(= (test:custom-role-layer)
   (codex:agent-role-layer-entry
     "/tmp/custom-role.toml"
     (codex:agent-role-layer-toml "role-model" "high")))

(= (test:custom-role-formatted)
   "custom: {
Custom role.
- This role's model is set to `role-model` and its reasoning effort is set to `high`. These settings cannot be changed.
}")

(= (test:minimal-built-ins)
   ((codex:agent-role-entry
      "default"
      (codex:agent-role-config "Default agent." CodexAbsent CodexAbsent))
    (codex:agent-role-entry
      "worker"
      (codex:agent-role-config "Worker role." CodexAbsent CodexAbsent))))

(= (test:user-worker-override)
   ((codex:agent-role-entry
      "worker"
      (codex:agent-role-config "User worker." CodexAbsent CodexAbsent))))

!(assertEqualToResult
  (codex:agent-role-default-role-name)
  ("default"))

!(assertEqualToResult
  (codex:agent-role-unavailable-error)
  ("agent type is currently not available"))

!(assertEqualToResult
  (codex:agent-role-config-description (test:custom-role-config))
  ("Custom role."))

!(assertEqualToResult
  (codex:agent-role-config-config-file (test:custom-role-config))
  ("/tmp/custom-role.toml"))

!(assertEqualToResult
  (codex:agent-role-config-nickname-candidates (test:custom-role-config))
  (("Ada" "Grace")))

!(assertEqualToResult
  (codex:agent-role-entry-list-get
    ((test:custom-role-entry))
    "missing")
  (CodexAbsent))

!(assertEqualToResult
  (codex:agent-role-config-description
    (codex:agent-role-entry-list-get
      ((test:custom-role-entry))
      "custom"))
  ("Custom role."))

!(assertEqualToResult
  (codex:agent-role-config-description
    (codex:agent-role-resolve-role-config-with-built-ins
      ()
      "default"))
  ("Default agent."))

!(assertEqualToResult
  (codex:agent-role-resolve-selected-role-config
    ()
    "missing")
  (CodexAbsent))

!(assertEqualToResult
  (codex:agent-role-config-description
    (codex:agent-role-resolve-selected-role-config
      ()
      CodexAbsent))
  ("Default agent."))

!(assertEqualToResult
  (codex:agent-role-locked-settings-note-from-layer
    (codex:agent-role-layer-toml "role-model" "high"))
  ("\n- This role's model is set to `role-model` and its reasoning effort is set to `high`. These settings cannot be changed."))

!(assertEqualToResult
  (codex:agent-role-locked-settings-note-from-layer
    (codex:agent-role-layer-toml "role-model" CodexAbsent))
  ("\n- This role's model is set to `role-model` and cannot be changed."))

!(assertEqualToResult
  (codex:agent-role-locked-settings-note-from-layer
    (codex:agent-role-layer-toml CodexAbsent "low"))
  ("\n- This role's reasoning effort is set to `low` and cannot be changed."))

!(assertEqual
  (codex:agent-role-format-role
    "custom"
    (test:custom-role-config)
    ((test:custom-role-layer)))
  (test:custom-role-formatted))

!(assertEqualToResult
  (codex:agent-role-format-role
    "anon"
    (codex:agent-role-config CodexAbsent CodexAbsent CodexAbsent)
    ())
  ("anon: no description"))

!(assertEqualToResult
  (codex:agent-role-spawn-tool-spec-build-from-configs
    (test:minimal-built-ins)
    ((test:custom-role-entry))
    ((test:custom-role-layer)))
  ("Optional type name for the new agent. If omitted, `default` is used.\nAvailable roles:\ncustom: {\nCustom role.\n- This role's model is set to `role-model` and its reasoning effort is set to `high`. These settings cannot be changed.\n}\ndefault: {\nDefault agent.\n}\nworker: {\nWorker role.\n}"))

!(assertEqualToResult
  (codex:agent-role-spawn-tool-spec-build-from-configs
    (test:minimal-built-ins)
    (test:user-worker-override)
    ())
  ("Optional type name for the new agent. If omitted, `default` is used.\nAvailable roles:\nworker: {\nUser worker.\n}\ndefault: {\nDefault agent.\n}"))

!(assertEqual
  (case (str-find
          (codex:agent-role-spawn-tool-spec-build ())
          "explorer: {\nUse `explorer` for specific codebase questions.")
    ((Empty False)
     ($offset True)))
  True)

!(assertEqual
  (case (str-find
          (codex:agent-role-spawn-tool-spec-build ())
          "worker: {\nUse for execution and production work.")
    ((Empty False)
     ($offset True)))
  True)
