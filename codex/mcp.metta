; Pure codex-mcp helper slice for the Codex port.
;
; Ports deterministic behavior from:
; - openai-codex/codex-rs/codex-mcp/src/mcp/mod.rs
; - openai-codex/codex-rs/codex-mcp/src/mcp/auth.rs
;
; Covered in this increment:
; - `mcp_permission_prompt_is_auto_approved`
; - `McpOAuthLoginConfig`
; - `McpOAuthLoginSupport`
; - `resolve_oauth_scopes`
; - `should_retry_without_scopes`
; - `OAuthProviderError` display behavior needed by MCP dependency login warnings
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust receives `AskForApproval` and `SandboxPolicy` enum values by value or
;   reference. This CeTTa helper receives the already-materialized approval and
;   sandbox policy values. It intentionally compares the materialized approval
;   slice representation directly so modules that only need this predicate do
;   not inherit unrelated approval reducers.
; - Rust uses `Option<Vec<String>>` for OAuth scope inputs. This CeTTa slice
;   uses the repo-wide `CodexAbsent` sentinel for `None`, and list atoms for
;   present vectors, including an explicitly present empty list.
; - Rust tests `anyhow::Error` with `downcast_ref::<OAuthProviderError>()` in
;   `should_retry_without_scopes`. This pure CeTTa boundary represents that
;   downcastable error as the tagged `CodexMcpOAuthProviderError` value.

(= (codex:mcp-oauth-login-config
      $url
      $http-headers
      $env-http-headers
      $discovered-scopes)
   (CodexMcpOAuthLoginConfig
     $url
     $http-headers
     $env-http-headers
     $discovered-scopes))

(= (codex:mcp-oauth-login-config-url
      (CodexMcpOAuthLoginConfig
        $url
        $http-headers
        $env-http-headers
        $discovered-scopes))
   $url)

(= (codex:mcp-oauth-login-config-http-headers
      (CodexMcpOAuthLoginConfig
        $url
        $http-headers
        $env-http-headers
        $discovered-scopes))
   $http-headers)

(= (codex:mcp-oauth-login-config-env-http-headers
      (CodexMcpOAuthLoginConfig
        $url
        $http-headers
        $env-http-headers
        $discovered-scopes))
   $env-http-headers)

(= (codex:mcp-oauth-login-config-discovered-scopes
      (CodexMcpOAuthLoginConfig
        $url
        $http-headers
        $env-http-headers
        $discovered-scopes))
   $discovered-scopes)

(= (codex:mcp-oauth-login-support-supported $config)
   (CodexMcpOAuthLoginSupportSupported $config))

(= (codex:mcp-oauth-login-support-unsupported)
   CodexMcpOAuthLoginSupportUnsupported)

(= (codex:mcp-oauth-login-support-unknown $error)
   (CodexMcpOAuthLoginSupportUnknown $error))

(= (codex:mcp-oauth-login-support-supported-config
      (CodexMcpOAuthLoginSupportSupported $config))
   $config)

(= (codex:mcp-oauth-scopes-source-explicit)
   CodexMcpOAuthScopesSourceExplicit)

(= (codex:mcp-oauth-scopes-source-configured)
   CodexMcpOAuthScopesSourceConfigured)

(= (codex:mcp-oauth-scopes-source-discovered)
   CodexMcpOAuthScopesSourceDiscovered)

(= (codex:mcp-oauth-scopes-source-empty)
   CodexMcpOAuthScopesSourceEmpty)

(= (codex:resolved-mcp-oauth-scopes $scopes $source)
   (CodexResolvedMcpOAuthScopes $scopes $source))

(= (codex:resolved-mcp-oauth-scopes-scopes
      (CodexResolvedMcpOAuthScopes $scopes $source))
   $scopes)

(= (codex:resolved-mcp-oauth-scopes-source
      (CodexResolvedMcpOAuthScopes $scopes $source))
   $source)

(= (codex:mcp-oauth-provider-error $error $error-description)
   (CodexMcpOAuthProviderError $error $error-description))

(= (codex:mcp-oauth-provider-error-display
      (CodexMcpOAuthProviderError $error $error-description))
   (if (not (== $error CodexAbsent))
       (if (not (== $error-description CodexAbsent))
           (format-args
             "OAuth provider returned `{}`: {}"
             ($error $error-description))
           (format-args "OAuth provider returned `{}`" ($error)))
       (if (not (== $error-description CodexAbsent))
           (format-args "OAuth error: {}" ($error-description))
           "OAuth provider returned an error")))

(= (codex:is-mcp-oauth-provider-error $error)
   (case $error
     (((CodexMcpOAuthProviderError $provider-error $provider-description) True)
      ($other False))))

(= (codex:resolve-mcp-oauth-scopes
      $explicit-scopes
      $configured-scopes
      $discovered-scopes)
   (if (not (== $explicit-scopes CodexAbsent))
       (codex:resolved-mcp-oauth-scopes
         $explicit-scopes
         (codex:mcp-oauth-scopes-source-explicit))
       (if (not (== $configured-scopes CodexAbsent))
           (codex:resolved-mcp-oauth-scopes
             $configured-scopes
             (codex:mcp-oauth-scopes-source-configured))
           (if (and
                 (not (== $discovered-scopes CodexAbsent))
                 (not (== $discovered-scopes ())))
               (codex:resolved-mcp-oauth-scopes
                 $discovered-scopes
                 (codex:mcp-oauth-scopes-source-discovered))
               (codex:resolved-mcp-oauth-scopes
                 ()
                 (codex:mcp-oauth-scopes-source-empty))))))

(= (codex:mcp-oauth-should-retry-without-scopes $resolved-scopes $error)
   (and
     (== (codex:resolved-mcp-oauth-scopes-source $resolved-scopes)
         (codex:mcp-oauth-scopes-source-discovered))
     (codex:is-mcp-oauth-provider-error $error)))

(= (codex:mcp-permission-prompt-is-auto-approved
      $approval-policy
      $sandbox-policy)
   (and
     (== $approval-policy "never")
     (or
       (== $sandbox-policy (CodexApprovalSandboxPolicyDangerFullAccess))
       (== $sandbox-policy (CodexApprovalSandboxPolicyExternalSandbox)))))
