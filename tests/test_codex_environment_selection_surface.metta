!(register-module! ../codex)
!(import! &self codex:environment_selection)
!(import! &self codex:error)
!(import! &self codex:protocol)

(= (test-env-manager)
   (codex:environment-manager
     "remote"
     ((codex:environment-manager-entry
        "local"
        (codex:environment "local" False CodexAbsent))
      (codex:environment-manager-entry
        "remote"
        (codex:environment "remote" True "ws://127.0.0.1:8765")))))

!(assertEqualToResult
  (codex:local-environment-id)
  ("local"))

!(assertEqualToResult
  (codex:remote-environment-id)
  ("remote"))

!(assertEqualToResult
  (codex:environment-normalize-exec-server-url CodexAbsent)
  ((CodexEnvironmentNormalizedExecServerUrl CodexAbsent False)))

!(assertEqualToResult
  (codex:environment-normalize-exec-server-url "  ")
  ((CodexEnvironmentNormalizedExecServerUrl CodexAbsent False)))

!(assertEqualToResult
  (codex:environment-normalize-exec-server-url " NoNe ")
  ((CodexEnvironmentNormalizedExecServerUrl CodexAbsent True)))

!(assertEqualToResult
  (codex:environment-normalize-exec-server-url " ws://127.0.0.1:8765 ")
  ((CodexEnvironmentNormalizedExecServerUrl "ws://127.0.0.1:8765" False)))

!(assertEqualToResult
  (codex:environment-manager-default-environment-id
    (codex:environment-manager-from-exec-server-url CodexAbsent))
  ("local"))

!(assertEqualToResult
  (codex:environment-manager-default-environment-id
    (codex:environment-manager-from-exec-server-url "ws://127.0.0.1:8765"))
  ("remote"))

!(assertEqualToResult
  (codex:environment-manager-default-environment-id
    (codex:environment-manager-from-exec-server-url "none"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:environment-is-remote
    (codex:environment-manager-default-environment
      (codex:environment-manager-from-exec-server-url "ws://127.0.0.1:8765")))
  (True))

!(assertEqualToResult
  (codex:environment-manager-get-environment
    (codex:environment-manager-from-exec-server-url "none")
    "local")
  ((CodexEnvironment "local" False CodexAbsent)))

!(assertEqualToResult
  (codex:default-thread-environment-selections
    (codex:environment-manager-from-exec-server-url "ws://127.0.0.1:8765")
    "/repo")
  (((CodexTurnEnvironmentSelection "remote" "/repo"))))

!(assertEqualToResult
  (codex:default-thread-environment-selections
    (codex:environment-manager-from-exec-server-url "none")
    "/repo")
  (()))

!(assertEqualToResult
  (codex:validate-environment-selections
    (test-env-manager)
    ((codex:turn-environment-selection "remote" "/repo")
     (codex:turn-environment-selection "local" "/repo")))
  ((CodexEnvironmentSelectionOk ())))

!(assertEqualToResult
  (codex:error-display
    (codex:environment-selection-result-error
      (codex:validate-environment-selections
        (test-env-manager)
        ((codex:turn-environment-selection "missing" "/repo")))))
  ("unknown turn environment id `missing`"))

!(assertEqualToResult
  (codex:selected-primary-environment
    (test-env-manager)
    ())
  ((CodexEnvironmentSelectionOk CodexAbsent)))

!(assertEqualToResult
  (codex:environment-id
    (codex:environment-selection-result-value
      (codex:selected-primary-environment
        (test-env-manager)
        ((codex:turn-environment-selection "remote" "/repo")
         (codex:turn-environment-selection "local" "/repo")))))
  ("remote"))

!(assertEqualToResult
  (codex:error-display
    (codex:environment-selection-result-error
      (codex:selected-primary-environment
        (test-env-manager)
        ((codex:turn-environment-selection "missing" "/repo")))))
  ("unknown turn environment id `missing`"))

!(assertEqualToResult
  (codex:error-display
    (codex:error-invalid-request "bad request"))
  ("bad request"))
