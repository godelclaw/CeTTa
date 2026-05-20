; Rust-faithful personality migration decision slice.
;
; This ports deterministic branch behavior from:
; - openai-codex/codex-rs/core/src/personality_migration.rs
;
; Covered in this increment:
; - PERSONALITY_MIGRATION_FILENAME
; - PersonalityMigrationStatus
; - maybe_migrate_personality branch order and visible outcomes
; - model provider precedence used before recorded-session lookup
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust resolves ConfigToml profiles, reads the migration marker, queries
;   LocalThreadStore, edits config.toml, and creates the marker file. CeTTa
;   currently keeps this layer pure, so callers supply those observed inputs
;   explicitly and receive the same status plus planned effects.
; - Rust returns io::Result<PersonalityMigrationStatus>. This slice represents
;   the InvalidData profile-resolution error as a result record with
;   `codex:personality-migration-error-invalid-profile`; all successful
;   branches keep the Rust status atom.

!(import! &self protocol)

(= (codex:personality-migration-filename)
   ".personality_migration")

(= (codex:personality-migration-status-skipped-marker)
   (CodexPersonalityMigrationStatusSkippedMarker))

(= (codex:personality-migration-status-skipped-explicit-personality)
   (CodexPersonalityMigrationStatusSkippedExplicitPersonality))

(= (codex:personality-migration-status-skipped-no-sessions)
   (CodexPersonalityMigrationStatusSkippedNoSessions))

(= (codex:personality-migration-status-applied)
   (CodexPersonalityMigrationStatusApplied))

(= (codex:personality-migration-error-invalid-profile $message)
   (CodexPersonalityMigrationErrorInvalidProfile $message))

(= (codex:personality-migration-profile $personality $model-provider)
   (CodexPersonalityMigrationProfile $personality $model-provider))

(= (codex:personality-migration-profile-error $message)
   (CodexPersonalityMigrationProfileError $message))

(= (codex:personality-migration-result
      $status
      $should-create-marker
      $persist-personality
      $model-provider-id
      $checked-active-sessions
      $checked-archived-sessions
      $error)
   (CodexPersonalityMigrationResult
     $status
     $should-create-marker
     $persist-personality
     $model-provider-id
     $checked-active-sessions
     $checked-archived-sessions
     $error))

(= (codex:personality-migration-result-status
      (CodexPersonalityMigrationResult
        $status
        $should-create-marker
        $persist-personality
        $model-provider-id
        $checked-active-sessions
        $checked-archived-sessions
        $error))
   $status)

(= (codex:personality-migration-result-should-create-marker
      (CodexPersonalityMigrationResult
        $status
        $should-create-marker
        $persist-personality
        $model-provider-id
        $checked-active-sessions
        $checked-archived-sessions
        $error))
   $should-create-marker)

(= (codex:personality-migration-result-persist-personality
      (CodexPersonalityMigrationResult
        $status
        $should-create-marker
        $persist-personality
        $model-provider-id
        $checked-active-sessions
        $checked-archived-sessions
        $error))
   $persist-personality)

(= (codex:personality-migration-result-model-provider-id
      (CodexPersonalityMigrationResult
        $status
        $should-create-marker
        $persist-personality
        $model-provider-id
        $checked-active-sessions
        $checked-archived-sessions
        $error))
   $model-provider-id)

(= (codex:personality-migration-result-checked-active-sessions
      (CodexPersonalityMigrationResult
        $status
        $should-create-marker
        $persist-personality
        $model-provider-id
        $checked-active-sessions
        $checked-archived-sessions
        $error))
   $checked-active-sessions)

(= (codex:personality-migration-result-checked-archived-sessions
      (CodexPersonalityMigrationResult
        $status
        $should-create-marker
        $persist-personality
        $model-provider-id
        $checked-active-sessions
        $checked-archived-sessions
        $error))
   $checked-archived-sessions)

(= (codex:personality-migration-result-error
      (CodexPersonalityMigrationResult
        $status
        $should-create-marker
        $persist-personality
        $model-provider-id
        $checked-active-sessions
        $checked-archived-sessions
        $error))
   $error)

(= (codex:personality-migration-select-model-provider
      $profile-model-provider
      $config-model-provider)
   (if (== $profile-model-provider CodexAbsent)
       (if (== $config-model-provider CodexAbsent)
           "openai"
           $config-model-provider)
       $profile-model-provider))

(= (codex:personality-migration-has-recorded-sessions
      True
      $has-archived-sessions)
   True)

(= (codex:personality-migration-has-recorded-sessions
      False
      True)
   True)

(= (codex:personality-migration-has-recorded-sessions
      False
      False)
   False)

(= (codex:personality-migration-checked-archived-sessions
      True
      $has-archived-sessions)
   False)

(= (codex:personality-migration-checked-archived-sessions
      False
      $has-archived-sessions)
   True)

(= (codex:personality-migration-after-profile
      (CodexPersonalityMigrationProfileError $message)
      $config-personality
      $config-model-provider
      $has-active-sessions
      $has-archived-sessions)
   (codex:personality-migration-result
     CodexAbsent
     False
     CodexAbsent
     CodexAbsent
     False
     False
     (codex:personality-migration-error-invalid-profile $message)))

(= (codex:personality-migration-after-profile
      (CodexPersonalityMigrationProfile $profile-personality $profile-model-provider)
      $config-personality
      $config-model-provider
      $has-active-sessions
      $has-archived-sessions)
   (if (or
         (not (== $config-personality CodexAbsent))
         (not (== $profile-personality CodexAbsent)))
       (codex:personality-migration-result
         (codex:personality-migration-status-skipped-explicit-personality)
         True
         CodexAbsent
         CodexAbsent
         False
         False
         CodexAbsent)
       (let $model-provider-id
         (codex:personality-migration-select-model-provider
           $profile-model-provider
           $config-model-provider)
         (let $has-recorded-sessions
           (codex:personality-migration-has-recorded-sessions
             $has-active-sessions
             $has-archived-sessions)
           (let $checked-archived-sessions
             (codex:personality-migration-checked-archived-sessions
               $has-active-sessions
               $has-archived-sessions)
             (if $has-recorded-sessions
                 (codex:personality-migration-result
                   (codex:personality-migration-status-applied)
                   True
                   (codex:personality-pragmatic)
                   $model-provider-id
                   True
                   $checked-archived-sessions
                   CodexAbsent)
                 (codex:personality-migration-result
                   (codex:personality-migration-status-skipped-no-sessions)
                   True
                   CodexAbsent
                   $model-provider-id
                   True
                   $checked-archived-sessions
                   CodexAbsent)))))))

(= (codex:personality-migration-decision
      True
      $profile-resolution
      $config-personality
      $config-model-provider
      $has-active-sessions
      $has-archived-sessions)
   (codex:personality-migration-result
     (codex:personality-migration-status-skipped-marker)
     False
     CodexAbsent
     CodexAbsent
     False
     False
     CodexAbsent))

(= (codex:personality-migration-decision
      False
      $profile-resolution
      $config-personality
      $config-model-provider
      $has-active-sessions
      $has-archived-sessions)
   (codex:personality-migration-after-profile
     $profile-resolution
     $config-personality
     $config-model-provider
     $has-active-sessions
     $has-archived-sessions))
