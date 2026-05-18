; Rust-faithful external bearer auth slice.
;
; This ports the visible behavior from:
; - openai-codex/codex-rs/login/src/auth/external_bearer.rs
; - the external-bearer AuthManager path in login/src/auth/manager.rs
;
; Covered in this increment:
; - BearerTokenRefresher shape over ModelProviderAuthInfo
; - provider auth command path resolution
; - provider auth command execution and stdout trimming
; - cached token reuse by refresh_interval_ms
; - explicit refresh replacing the cached token
; - external-bearer UnauthorizedRecovery refresh step
;
; Required CeTTa representation notes for audit:
; - Rust uses Arc<Mutex<State>> and Instant::now(). CeTTa does not yet expose a
;   monotonic-clock primitive, so resolver/refresh functions take `now-ms` and
;   return an updated refresher value. This preserves the cache algorithm while
;   making state threading explicit.
; - Rust's Tokio Command inherits the parent environment. This slice builds the
;   command env with `process-default-shell-env-policy` to preserve that behavior.
; - The current CeTTa process runner requires an output byte cap and returns text
;   strings after native process decoding. This slice uses a large cap and cannot
;   distinguish Rust's non-UTF-8 stdout error until the process lib exposes raw
;   bytes.

!(import! &self list)
!(import! &self login_auth)
!(import! &self model_provider_info)
!(import! &self process)
!(import! &self str)

(= (codex:external-bearer-command-max-bytes)
   1048576)

(= (codex:external-auth-tokens-access-token-only $access-token)
   (CodexExternalAuthTokens $access-token CodexAbsent))

(= (codex:external-auth-tokens-access-token
      (CodexExternalAuthTokens $access-token $chatgpt-metadata))
   $access-token)

(= (codex:external-auth-tokens-chatgpt-metadata
      (CodexExternalAuthTokens $access-token $chatgpt-metadata))
   $chatgpt-metadata)

(= (codex:external-auth-refresh-reason-unauthorized)
   (CodexExternalAuthRefreshReasonUnauthorized))

(= (codex:external-auth-refresh-context $reason $previous-account-id)
   (CodexExternalAuthRefreshContext $reason $previous-account-id))

(= (codex:unauthorized-recovery-mode-external)
   (CodexUnauthorizedRecoveryModeExternal))

(= (codex:unauthorized-recovery-step-external-refresh)
   (CodexUnauthorizedRecoveryStepExternalRefresh))

(= (codex:unauthorized-recovery-step-done)
   (CodexUnauthorizedRecoveryStepDone))

(= (codex:unauthorized-recovery $manager $expected-account-id $mode $step)
   (CodexUnauthorizedRecovery $manager $expected-account-id $mode $step))

(= (codex:unauthorized-recovery-manager
      (CodexUnauthorizedRecovery $manager $expected-account-id $mode $step))
   $manager)

(= (codex:unauthorized-recovery-step
      (CodexUnauthorizedRecovery $manager $expected-account-id $mode $step))
   $step)

(= (codex:unauthorized-recovery-step-result $auth-state-changed)
   (CodexUnauthorizedRecoveryStepResult $auth-state-changed))

(= (codex:unauthorized-recovery-step-result-auth-state-changed
      (CodexUnauthorizedRecoveryStepResult $auth-state-changed))
   $auth-state-changed)

(= (codex:unauthorized-recovery-next-ok $recovery $step-result)
   (CodexUnauthorizedRecoveryNextOk $recovery $step-result))

(= (codex:unauthorized-recovery-next-err $recovery $message)
   (CodexUnauthorizedRecoveryNextErr $recovery $message))

(= (codex:unauthorized-recovery-next-result-recovery
      (CodexUnauthorizedRecoveryNextOk $recovery $step-result))
   $recovery)

(= (codex:unauthorized-recovery-next-result-recovery
      (CodexUnauthorizedRecoveryNextErr $recovery $message))
   $recovery)

(= (codex:unauthorized-recovery-next-result-step-result
      (CodexUnauthorizedRecoveryNextOk $recovery $step-result))
   $step-result)

(= (codex:unauthorized-recovery-next-result-message
      (CodexUnauthorizedRecoveryNextErr $recovery $message))
   $message)

(= (codex:unauthorized-recovery-mode-name
      (CodexUnauthorizedRecovery
        $manager
        $expected-account-id
        (CodexUnauthorizedRecoveryModeExternal)
        $step))
   "external")

(= (codex:unauthorized-recovery-step-name
      (CodexUnauthorizedRecovery
        $manager
        $expected-account-id
        $mode
        (CodexUnauthorizedRecoveryStepExternalRefresh)))
   "external_refresh")

(= (codex:unauthorized-recovery-step-name
      (CodexUnauthorizedRecovery
        $manager
        $expected-account-id
        $mode
        (CodexUnauthorizedRecoveryStepDone)))
   "done")

(= (codex:unauthorized-recovery-has-next
      (CodexUnauthorizedRecovery
        $manager
        $expected-account-id
        (CodexUnauthorizedRecoveryModeExternal)
        $step))
   (not (== $step (codex:unauthorized-recovery-step-done))))

(= (codex:unauthorized-recovery-unavailable-reason
      (CodexUnauthorizedRecovery
        $manager
        $expected-account-id
        (CodexUnauthorizedRecoveryModeExternal)
        $step))
   (if (== $step (codex:unauthorized-recovery-step-done))
       "recovery_exhausted"
       "ready"))

(= (codex:cached-external-bearer-token $access-token $fetched-at-ms)
   (CodexCachedExternalBearerToken $access-token $fetched-at-ms))

(= (codex:cached-external-bearer-token-access-token
      (CodexCachedExternalBearerToken $access-token $fetched-at-ms))
   $access-token)

(= (codex:cached-external-bearer-token-fetched-at-ms
      (CodexCachedExternalBearerToken $access-token $fetched-at-ms))
   $fetched-at-ms)

(= (codex:bearer-token-refresher $config $cached-token)
   (CodexBearerTokenRefresher $config $cached-token))

(= (codex:bearer-token-refresher-new $config)
   (codex:bearer-token-refresher $config CodexAbsent))

(= (codex:bearer-token-refresher-config
      (CodexBearerTokenRefresher $config $cached-token))
   $config)

(= (codex:bearer-token-refresher-cached-token
      (CodexBearerTokenRefresher $config $cached-token))
   $cached-token)

(= (codex:external-bearer-run-ok $access-token)
   (CodexExternalBearerRunOk $access-token))

(= (codex:external-bearer-run-err $message)
   (CodexExternalBearerRunErr $message))

(= (codex:external-bearer-run-result-value
      (CodexExternalBearerRunOk $access-token))
   $access-token)

(= (codex:external-bearer-run-result-message
      (CodexExternalBearerRunErr $message))
   $message)

(= (codex:external-bearer-resolve-ok $refresher $tokens)
   (CodexExternalBearerResolveOk $refresher $tokens))

(= (codex:external-bearer-resolve-err $message)
   (CodexExternalBearerResolveErr $message))

(= (codex:external-bearer-resolve-result-refresher
      (CodexExternalBearerResolveOk $refresher $tokens))
   $refresher)

(= (codex:external-bearer-resolve-result-tokens
      (CodexExternalBearerResolveOk $refresher $tokens))
   $tokens)

(= (codex:external-bearer-resolve-result-message
      (CodexExternalBearerResolveErr $message))
   $message)

(= (codex:external-bearer-command-has-path-components $command)
   (> (list:len (str-split "/" $command)) 1))

(= (codex:external-bearer-command-is-absolute $command)
   (str-starts-with? $command "/"))

(= (codex:external-bearer-strip-current-dir-prefix $command)
   (if (str-starts-with? $command "./")
       (str-slice $command 2 (str-length $command))
       $command))

(= (codex:external-bearer-join-cwd-command $cwd $command)
   (let $rel (codex:external-bearer-strip-current-dir-prefix $command)
     (if (str-ends-with? $cwd "/")
         (str-concat $cwd $rel)
         (str-concat (str-concat $cwd "/") $rel))))

(= (codex:resolve-provider-auth-program $command $cwd)
   (case (codex:external-bearer-command-is-absolute $command)
     ((True $command)
      (False
       (case (codex:external-bearer-command-has-path-components $command)
         ((True (codex:external-bearer-join-cwd-command $cwd $command))
          (False $command)))))))

(= (codex:external-bearer-argv $program $args)
   (cons-atom $program $args))

(= (codex:external-bearer-status-text $exit-code)
   (format-args "exit status: {}" ($exit-code)))

(= (codex:external-bearer-stderr-suffix $stderr)
   (if (== $stderr "")
       ""
       (str-concat ": " $stderr)))

(= (codex:run-provider-auth-command $config)
   (let $command (codex:model-provider-auth-info-command $config)
     (let $program
       (codex:resolve-provider-auth-program
         $command
         (codex:model-provider-auth-info-cwd $config))
       (let $result
         (process-run-cmd-cwd-env-timeout-cap-bytes
           (codex:external-bearer-argv
             $program
             (codex:model-provider-auth-info-args $config))
           (codex:model-provider-auth-info-cwd $config)
           (process-create-shell-env-no-thread
             (process-default-shell-env-policy))
           (codex:model-provider-auth-info-timeout-ms $config)
           (codex:external-bearer-command-max-bytes))
         (if (process-result-timed-out? $result)
             (codex:external-bearer-run-err
               (format-args
                 "provider auth command `{}` timed out after {} ms"
                 ($command (codex:model-provider-auth-info-timeout-ms $config))))
             (if (== (process-result-exit-code $result) 0)
                 (let $access-token (str-trim (process-result-stdout $result))
                   (if (== $access-token "")
                       (codex:external-bearer-run-err
                         (format-args
                           "provider auth command `{}` produced an empty token"
                           ($command)))
                       (codex:external-bearer-run-ok $access-token)))
                 (codex:external-bearer-run-err
                   (format-args
                     "provider auth command `{}` exited with status {}{}"
                     ($command
                      (codex:external-bearer-status-text
                        (process-result-exit-code $result))
                      (codex:external-bearer-stderr-suffix
                        (str-trim (process-result-stderr $result))))))))))))

(= (codex:external-bearer-cached-token-fresh?
      (CodexCachedExternalBearerToken $access-token $fetched-at-ms)
      $refresh-interval-ms
      $now-ms)
   (if (== $refresh-interval-ms 0)
       True
       (< (- $now-ms $fetched-at-ms) $refresh-interval-ms)))

(= (codex:bearer-token-refresher-refresh-config-at $config $now-ms)
   (case (codex:run-provider-auth-command $config)
     (((CodexExternalBearerRunErr $message)
       (codex:external-bearer-resolve-err $message))
      ((CodexExternalBearerRunOk $access-token)
       (let $next-cached
         (codex:cached-external-bearer-token $access-token $now-ms)
         (codex:external-bearer-resolve-ok
           (codex:bearer-token-refresher $config $next-cached)
           (codex:external-auth-tokens-access-token-only
             $access-token)))))))

(= (codex:bearer-token-refresher-resolve-at
      (CodexBearerTokenRefresher $config $cached-token)
      $now-ms)
   (if (== $cached-token CodexAbsent)
       (codex:bearer-token-refresher-refresh-config-at $config $now-ms)
       (if (codex:external-bearer-cached-token-fresh?
             $cached-token
             (codex:model-provider-auth-info-refresh-interval-ms $config)
             $now-ms)
           (codex:external-bearer-resolve-ok
             (codex:bearer-token-refresher $config $cached-token)
             (codex:external-auth-tokens-access-token-only
               (codex:cached-external-bearer-token-access-token $cached-token)))
           (codex:bearer-token-refresher-refresh-config-at $config $now-ms))))

(= (codex:bearer-token-refresher-refresh-at $refresher $now-ms)
   (let $config (codex:bearer-token-refresher-config $refresher)
     (codex:bearer-token-refresher-refresh-config-at $config $now-ms)))

(= (codex:external-bearer-auth-manager $refresher)
   (CodexAuthManagerExternalBearerOnly $refresher))

(= (codex:auth-manager-unauthorized-recovery
      (CodexAuthManagerExternalBearerOnly $refresher))
   (codex:unauthorized-recovery
     (CodexAuthManagerExternalBearerOnly $refresher)
     CodexAbsent
     (codex:unauthorized-recovery-mode-external)
     (codex:unauthorized-recovery-step-external-refresh)))

(= (codex:external-bearer-auth-manager-auth-ok $manager $auth)
   (CodexExternalBearerAuthManagerAuthOk $manager $auth))

(= (codex:external-bearer-auth-manager-auth-manager
      (CodexExternalBearerAuthManagerAuthOk $manager $auth))
   $manager)

(= (codex:external-bearer-auth-manager-auth-auth
      (CodexExternalBearerAuthManagerAuthOk $manager $auth))
   $auth)

(= (codex:external-bearer-auth-manager-auth-at
      (CodexAuthManagerExternalBearerOnly $refresher)
      $now-ms)
   (case (codex:bearer-token-refresher-resolve-at $refresher $now-ms)
     (((CodexExternalBearerResolveErr $message)
       (codex:external-bearer-auth-manager-auth-ok
         (CodexAuthManagerExternalBearerOnly $refresher)
         CodexAbsent))
      ((CodexExternalBearerResolveOk $next-refresher $tokens)
       (codex:external-bearer-auth-manager-auth-ok
         (CodexAuthManagerExternalBearerOnly $next-refresher)
         (codex:codex-auth-api-key
           (codex:external-auth-tokens-access-token $tokens)))))))

(= (codex:external-bearer-auth-manager-refresh-at
      (CodexAuthManagerExternalBearerOnly $refresher)
      $now-ms)
   (case (codex:bearer-token-refresher-refresh-at $refresher $now-ms)
     (((CodexExternalBearerResolveErr $message)
       (codex:external-bearer-resolve-err $message))
      ((CodexExternalBearerResolveOk $next-refresher $tokens)
       (codex:external-bearer-resolve-ok
         (CodexAuthManagerExternalBearerOnly $next-refresher)
         $tokens)))))

(= (codex:unauthorized-recovery-next-at
      (CodexUnauthorizedRecovery
        (CodexAuthManagerExternalBearerOnly $refresher)
        $expected-account-id
        (CodexUnauthorizedRecoveryModeExternal)
        (CodexUnauthorizedRecoveryStepExternalRefresh))
      $now-ms)
   (case (codex:external-bearer-auth-manager-refresh-at
           (CodexAuthManagerExternalBearerOnly $refresher)
           $now-ms)
     (((CodexExternalBearerResolveErr $message)
       (codex:unauthorized-recovery-next-err
         (codex:unauthorized-recovery
           (CodexAuthManagerExternalBearerOnly $refresher)
           $expected-account-id
           (codex:unauthorized-recovery-mode-external)
           (codex:unauthorized-recovery-step-external-refresh))
         $message))
      ((CodexExternalBearerResolveOk $next-manager $tokens)
       (codex:unauthorized-recovery-next-ok
         (codex:unauthorized-recovery
           $next-manager
           $expected-account-id
           (codex:unauthorized-recovery-mode-external)
           (codex:unauthorized-recovery-step-done))
         (codex:unauthorized-recovery-step-result True))))))

(= (codex:unauthorized-recovery-next-at
      (CodexUnauthorizedRecovery
        (CodexAuthManagerExternalBearerOnly $refresher)
        $expected-account-id
        (CodexUnauthorizedRecoveryModeExternal)
        (CodexUnauthorizedRecoveryStepDone))
      $now-ms)
   (codex:unauthorized-recovery-next-err
     (codex:unauthorized-recovery
       (CodexAuthManagerExternalBearerOnly $refresher)
       $expected-account-id
       (codex:unauthorized-recovery-mode-external)
       (codex:unauthorized-recovery-step-done))
     "No more recovery steps available."))
