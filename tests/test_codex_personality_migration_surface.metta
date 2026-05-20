!(register-module! ../codex)
!(import! &self codex:personality_migration)

!(assertEqual
  (codex:personality-migration-filename)
  ".personality_migration")

!(assertEqualToResult
  (let $result
    (codex:personality-migration-decision
      True
      (codex:personality-migration-profile-error "missing profile")
      CodexAbsent
      CodexAbsent
      False
      False)
    ((codex:personality-migration-result-status $result)
     (codex:personality-migration-result-should-create-marker $result)
     (codex:personality-migration-result-persist-personality $result)
     (codex:personality-migration-result-model-provider-id $result)
     (codex:personality-migration-result-checked-active-sessions $result)
     (codex:personality-migration-result-checked-archived-sessions $result)
     (codex:personality-migration-result-error $result)))
  (((CodexPersonalityMigrationStatusSkippedMarker)
    False
    CodexAbsent
    CodexAbsent
    False
    False
    CodexAbsent)))

!(assertEqualToResult
  (let $result
    (codex:personality-migration-decision
      False
      (codex:personality-migration-profile-error "missing profile")
      CodexAbsent
      CodexAbsent
      False
      False)
    ((codex:personality-migration-result-status $result)
     (codex:personality-migration-result-should-create-marker $result)
     (codex:personality-migration-result-persist-personality $result)
     (codex:personality-migration-result-model-provider-id $result)
     (codex:personality-migration-result-checked-active-sessions $result)
     (codex:personality-migration-result-checked-archived-sessions $result)
     (codex:personality-migration-result-error $result)))
  ((CodexAbsent
    False
    CodexAbsent
    CodexAbsent
    False
    False
    (CodexPersonalityMigrationErrorInvalidProfile "missing profile"))))

!(assertEqualToResult
  (let $result
    (codex:personality-migration-decision
      False
      (codex:personality-migration-profile CodexAbsent CodexAbsent)
      CodexAbsent
      CodexAbsent
      False
      False)
    ((codex:personality-migration-result-status $result)
     (codex:personality-migration-result-should-create-marker $result)
     (codex:personality-migration-result-persist-personality $result)
     (codex:personality-migration-result-model-provider-id $result)
     (codex:personality-migration-result-checked-active-sessions $result)
     (codex:personality-migration-result-checked-archived-sessions $result)
     (codex:personality-migration-result-error $result)))
  (((CodexPersonalityMigrationStatusSkippedNoSessions)
    True
    CodexAbsent
    "openai"
    True
    True
    CodexAbsent)))

!(assertEqualToResult
  (let $result
    (codex:personality-migration-decision
      False
      (codex:personality-migration-profile CodexAbsent CodexAbsent)
      CodexAbsent
      CodexAbsent
      True
      True)
    ((codex:personality-migration-result-status $result)
     (codex:personality-migration-result-should-create-marker $result)
     (codex:personality-migration-result-persist-personality $result)
     (codex:personality-migration-result-model-provider-id $result)
     (codex:personality-migration-result-checked-active-sessions $result)
     (codex:personality-migration-result-checked-archived-sessions $result)
     (codex:personality-migration-result-error $result)))
  (((CodexPersonalityMigrationStatusApplied)
    True
    (CodexPersonalityPragmatic)
    "openai"
    True
    False
    CodexAbsent)))

!(assertEqualToResult
  (let $result
    (codex:personality-migration-decision
      False
      (codex:personality-migration-profile CodexAbsent CodexAbsent)
      CodexAbsent
      CodexAbsent
      False
      True)
    ((codex:personality-migration-result-status $result)
     (codex:personality-migration-result-should-create-marker $result)
     (codex:personality-migration-result-persist-personality $result)
     (codex:personality-migration-result-model-provider-id $result)
     (codex:personality-migration-result-checked-active-sessions $result)
     (codex:personality-migration-result-checked-archived-sessions $result)
     (codex:personality-migration-result-error $result)))
  (((CodexPersonalityMigrationStatusApplied)
    True
    (CodexPersonalityPragmatic)
    "openai"
    True
    True
    CodexAbsent)))

!(assertEqualToResult
  (let $result
    (codex:personality-migration-decision
      False
      (codex:personality-migration-profile CodexAbsent CodexAbsent)
      (codex:personality-friendly)
      CodexAbsent
      True
      True)
    ((codex:personality-migration-result-status $result)
     (codex:personality-migration-result-should-create-marker $result)
     (codex:personality-migration-result-persist-personality $result)
     (codex:personality-migration-result-model-provider-id $result)
     (codex:personality-migration-result-checked-active-sessions $result)
     (codex:personality-migration-result-checked-archived-sessions $result)
     (codex:personality-migration-result-error $result)))
  (((CodexPersonalityMigrationStatusSkippedExplicitPersonality)
    True
    CodexAbsent
    CodexAbsent
    False
    False
    CodexAbsent)))

!(assertEqualToResult
  (let $result
    (codex:personality-migration-decision
      False
      (codex:personality-migration-profile (codex:personality-friendly) CodexAbsent)
      CodexAbsent
      CodexAbsent
      True
      True)
    ((codex:personality-migration-result-status $result)
     (codex:personality-migration-result-should-create-marker $result)
     (codex:personality-migration-result-persist-personality $result)
     (codex:personality-migration-result-model-provider-id $result)
     (codex:personality-migration-result-checked-active-sessions $result)
     (codex:personality-migration-result-checked-archived-sessions $result)
     (codex:personality-migration-result-error $result)))
  (((CodexPersonalityMigrationStatusSkippedExplicitPersonality)
    True
    CodexAbsent
    CodexAbsent
    False
    False
    CodexAbsent)))

!(assertEqual
  (codex:personality-migration-select-model-provider
    "profile-provider"
    "config-provider")
  "profile-provider")

!(assertEqual
  (codex:personality-migration-select-model-provider
    CodexAbsent
    "config-provider")
  "config-provider")

!(assertEqual
  (codex:personality-migration-select-model-provider
    CodexAbsent
    CodexAbsent)
  "openai")
