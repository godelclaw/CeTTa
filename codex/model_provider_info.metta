; Rust-faithful model-provider-info auth slice.
;
; This ports the auth-relevant parts of:
; - openai-codex/codex-rs/model-provider-info/src/lib.rs
; - openai-codex/codex-rs/protocol/src/config_types.rs ModelProviderAuthInfo
;
; Covered in this increment:
; - auth-relevant ModelProviderInfo fields
; - ModelProviderAuthInfo data shape used by command-backed provider auth
; - ModelProviderInfo::api_key env-key lookup semantics
;
; Required CeTTa representation notes for audit:
; - Rust ModelProviderInfo has many request/provider fields. This module keeps
;   the auth-relevant projection only; unrelated fields remain in future slices.
; - Rust returns Result<Option<String>, CodexErr>. CeTTa represents that as
;   `CodexModelProviderApiKeyOk` with `CodexAbsent` for None, or
;   `CodexModelProviderApiKeyErr`.

!(import! &self error)
!(import! &self str)
!(import! &self system)

(= (codex:model-provider-auth-info
      $command
      $args
      $timeout-ms
      $refresh-interval-ms
      $cwd)
   (CodexModelProviderAuthInfo
     $command
     $args
     $timeout-ms
     $refresh-interval-ms
     $cwd))

(= (codex:model-provider-auth-info-command
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $command)

(= (codex:model-provider-auth-info-args
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $args)

(= (codex:model-provider-auth-info-timeout-ms
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $timeout-ms)

(= (codex:model-provider-auth-info-refresh-interval-ms
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $refresh-interval-ms)

(= (codex:model-provider-auth-info-cwd
      (CodexModelProviderAuthInfo
        $command
        $args
        $timeout-ms
        $refresh-interval-ms
        $cwd))
   $cwd)

(= (codex:model-provider-info
      $env-key
      $env-key-instructions
      $experimental-bearer-token
      $auth)
   (CodexModelProviderInfo
     $env-key
     $env-key-instructions
     $experimental-bearer-token
     $auth))

(= (codex:default-model-provider-info)
   (codex:model-provider-info
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:model-provider-info-env-key
      (CodexModelProviderInfo
        $env-key
        $env-key-instructions
        $experimental-bearer-token
        $auth))
   $env-key)

(= (codex:model-provider-info-env-key-instructions
      (CodexModelProviderInfo
        $env-key
        $env-key-instructions
        $experimental-bearer-token
        $auth))
   $env-key-instructions)

(= (codex:model-provider-info-experimental-bearer-token
      (CodexModelProviderInfo
        $env-key
        $env-key-instructions
        $experimental-bearer-token
        $auth))
   $experimental-bearer-token)

(= (codex:model-provider-info-auth
      (CodexModelProviderInfo
        $env-key
        $env-key-instructions
        $experimental-bearer-token
        $auth))
   $auth)

(= (codex:model-provider-api-key-ok $value)
   (CodexModelProviderApiKeyOk $value))

(= (codex:model-provider-api-key-err $error)
   (CodexModelProviderApiKeyErr $error))

(= (codex:model-provider-api-key-result-value
      (CodexModelProviderApiKeyOk $value))
   $value)

(= (codex:model-provider-api-key-result-error
      (CodexModelProviderApiKeyErr $error))
   $error)

(= (codex:model-provider-api-key-from-env-value $provider $env-value)
   (let $env-key (codex:model-provider-info-env-key $provider)
     (if (== $env-key CodexAbsent)
         (codex:model-provider-api-key-ok CodexAbsent)
         (let $instructions
           (codex:model-provider-info-env-key-instructions $provider)
           (if (== $env-value CodexAbsent)
               (codex:model-provider-api-key-err
                 (codex:error-env-var
                   (codex:env-var-error $env-key $instructions)))
               (if (== (str-trim $env-value) "")
                   (codex:model-provider-api-key-err
                     (codex:error-env-var
                       (codex:env-var-error $env-key $instructions)))
                   (codex:model-provider-api-key-ok $env-value)))))))

(= (codex:model-provider-api-key $provider)
   (let $env-key (codex:model-provider-info-env-key $provider)
     (if (== $env-key CodexAbsent)
         (codex:model-provider-api-key-ok CodexAbsent)
         (case (system-getenv-or-default $env-key CodexAbsent)
           (($env-value
             (codex:model-provider-api-key-from-env-value
               $provider
               $env-value)))))))
