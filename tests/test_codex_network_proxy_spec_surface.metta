!(register-module! ../codex)
!(import! &self codex:network_proxy_spec)

(= (read-only-sandbox)
   (CodexSessionSandboxPolicyReadOnly () ()))

(= (workspace-sandbox)
   (CodexSessionSandboxPolicyWorkspaceWrite () () False False))

(= (danger-full-access-sandbox)
   (CodexSessionSandboxPolicyDangerFullAccess))

(= (domain-permissions $entries)
   (codex:network-domain-permissions $entries))

(= (allow-entry $pattern)
   (codex:network-domain-permission-entry
     $pattern
     (codex:network-domain-permission-allow)))

(= (deny-entry $pattern)
   (codex:network-domain-permission-entry
     $pattern
     (codex:network-domain-permission-deny)))

(= (unix-allow-entry $path)
   (codex:network-unix-socket-permission-entry
     $path
     (codex:network-unix-socket-permission-allow)))

(= (unix-none-entry $path)
   (codex:network-unix-socket-permission-entry
     $path
     (codex:network-unix-socket-permission-none)))

(= (default-config)
   (codex:network-proxy-config-default))

(= (spec-value $config $requirements $sandbox-policy)
   (codex:network-proxy-spec-result-value
     (codex:network-proxy-spec-from-config-and-constraints
       $config
       $requirements
       $sandbox-policy)))

!(assertEqual
  (codex:network-domain-permissions-allowed-domains
    (domain-permissions
      ((allow-entry "api.example.com")
       (deny-entry "api.example.com"))))
  CodexAbsent)

!(assertEqual
  (codex:network-domain-permissions-denied-domains
    (domain-permissions
      ((allow-entry "api.example.com")
       (deny-entry "api.example.com"))))
  ("api.example.com"))

!(assertEqual
  (codex:network-proxy-config-allowed-domains
    (codex:network-proxy-config-set-allowed-domains
      (codex:network-proxy-config-set-denied-domains
        (default-config)
        ("api.example.com"))
      ("api.example.com")))
  CodexAbsent)

(= (managed-allow-requirements)
   (codex:network-constraints-with-domains
     (codex:network-constraints-default)
     (domain-permissions
       ((allow-entry "*.example.com")))))

(= (allowed-baseline-spec)
   (spec-value
     (codex:network-proxy-config-set-allowed-domains
       (default-config)
       ("api.example.com"))
     (managed-allow-requirements)
     (read-only-sandbox)))

!(assertEqual
  (codex:network-proxy-config-allowed-domains
    (codex:network-proxy-spec-config
      (allowed-baseline-spec)))
  ("*.example.com" "api.example.com"))

!(assertEqual
  (codex:network-proxy-constraints-allowed-domains
    (codex:network-proxy-spec-constraints
      (allowed-baseline-spec)))
  ("*.example.com"))

!(assertEqual
  (codex:network-proxy-constraints-allowlist-expansion-enabled
    (codex:network-proxy-spec-constraints
      (allowed-baseline-spec)))
  True)

(= (deny-overrides-managed-allow-spec)
   (spec-value
     (codex:network-proxy-config-set-denied-domains
       (default-config)
       ("api.example.com"))
     (codex:network-constraints-with-domains
       (codex:network-constraints-default)
       (domain-permissions
         ((allow-entry "api.example.com"))))
     (workspace-sandbox)))

!(assertEqual
  (codex:network-proxy-config-allowed-domains
    (codex:network-proxy-spec-config
      (deny-overrides-managed-allow-spec)))
  CodexAbsent)

!(assertEqual
  (codex:network-proxy-config-denied-domains
    (codex:network-proxy-spec-config
      (deny-overrides-managed-allow-spec)))
  ("api.example.com"))

(= (full-access-pinned-spec)
   (spec-value
     (codex:network-proxy-config-set-denied-domains
       (codex:network-proxy-config-set-allowed-domains
         (default-config)
         ("evil.com"))
       ("more-blocked.example.com"))
     (codex:network-constraints-with-domains
       (codex:network-constraints-default)
       (domain-permissions
         ((allow-entry "*.example.com")
          (deny-entry "blocked.example.com"))))
     (danger-full-access-sandbox)))

!(assertEqual
  (codex:network-proxy-config-allowed-domains
    (codex:network-proxy-spec-config
      (full-access-pinned-spec)))
  ("*.example.com"))

!(assertEqual
  (codex:network-proxy-config-denied-domains
    (codex:network-proxy-spec-config
      (full-access-pinned-spec)))
  ("blocked.example.com"))

!(assertEqual
  (codex:network-proxy-constraints-allowlist-expansion-enabled
    (codex:network-proxy-spec-constraints
      (full-access-pinned-spec)))
  False)

!(assertEqual
  (codex:network-proxy-constraints-denylist-expansion-enabled
    (codex:network-proxy-spec-constraints
      (full-access-pinned-spec)))
  False)

(= (managed-only-requirements)
   (codex:network-constraints-with-managed-allowed-domains-only
     (codex:network-constraints-with-domains
       (codex:network-constraints-default)
       (domain-permissions
         ((allow-entry "managed.example.com"))))
     True))

(= (managed-only-spec)
   (spec-value
     (codex:network-proxy-config-set-allowed-domains
       (default-config)
       ("api.example.com"))
     (managed-only-requirements)
     (workspace-sandbox)))

!(assertEqual
  (codex:network-proxy-config-allowed-domains
    (codex:network-proxy-spec-config
      (managed-only-spec)))
  ("managed.example.com"))

!(assertEqual
  (codex:network-proxy-spec-hard-deny-allowlist-misses
    (managed-only-spec))
  True)

(= (managed-only-empty-spec)
   (spec-value
     (codex:network-proxy-config-set-allowed-domains
       (default-config)
       ("api.example.com"))
     (codex:network-constraints-with-managed-allowed-domains-only
       (codex:network-constraints-default)
       True)
     (workspace-sandbox)))

!(assertEqual
  (codex:network-proxy-config-allowed-domains
    (codex:network-proxy-spec-config
      (managed-only-empty-spec)))
  CodexAbsent)

!(assertEqual
  (codex:network-proxy-constraints-allowed-domains
    (codex:network-proxy-spec-constraints
      (managed-only-empty-spec)))
  ())

!(assertEqual
  (codex:network-proxy-constraints-allowlist-expansion-enabled
    (codex:network-proxy-spec-constraints
      (managed-only-empty-spec)))
  False)

(= (deny-only-spec)
   (spec-value
     (codex:network-proxy-config-set-allowed-domains
       (default-config)
       ("api.example.com"))
     (codex:network-constraints-with-domains
       (codex:network-constraints-default)
       (domain-permissions
         ((deny-entry "managed-blocked.example.com"))))
     (danger-full-access-sandbox)))

!(assertEqual
  (codex:network-proxy-config-allowed-domains
    (codex:network-proxy-spec-config
      (deny-only-spec)))
  ("api.example.com"))

!(assertEqual
  (codex:network-proxy-constraints-allowed-domains
    (codex:network-proxy-spec-constraints
      (deny-only-spec)))
  CodexAbsent)

!(assertEqual
  (codex:network-proxy-config-denied-domains
    (codex:network-proxy-spec-config
      (deny-only-spec)))
  ("managed-blocked.example.com"))

(= (allow-only-spec)
   (spec-value
     (codex:network-proxy-config-set-denied-domains
       (default-config)
       ("blocked.example.com"))
     (codex:network-constraints-with-domains
       (codex:network-constraints-default)
       (domain-permissions
         ((allow-entry "managed.example.com"))))
     (danger-full-access-sandbox)))

!(assertEqual
  (codex:network-proxy-config-allowed-domains
    (codex:network-proxy-spec-config
      (allow-only-spec)))
  ("managed.example.com"))

!(assertEqual
  (codex:network-proxy-config-denied-domains
    (codex:network-proxy-spec-config
      (allow-only-spec)))
  ("blocked.example.com"))

!(assertEqual
  (codex:network-proxy-constraints-denied-domains
    (codex:network-proxy-spec-constraints
      (allow-only-spec)))
  CodexAbsent)

(= (denied-baseline-spec)
   (spec-value
     (codex:network-proxy-config-set-denied-domains
       (default-config)
       ("blocked.example.com"))
     (codex:network-constraints-with-domains
       (codex:network-constraints-default)
       (domain-permissions
         ((deny-entry "managed-blocked.example.com"))))
     (workspace-sandbox)))

!(assertEqual
  (codex:network-proxy-config-denied-domains
    (codex:network-proxy-spec-config
      (denied-baseline-spec)))
  ("managed-blocked.example.com" "blocked.example.com"))

!(assertEqual
  (codex:network-proxy-constraints-denylist-expansion-enabled
    (codex:network-proxy-spec-constraints
      (denied-baseline-spec)))
  True)

(= (candidate-after-user-deny)
   (codex:network-proxy-config-upsert-domain-permission
     (codex:network-proxy-spec-config
       (allowed-baseline-spec))
     "api.example.com"
     (codex:network-domain-permission-deny)))

!(assertEqual
  (codex:network-proxy-config-allowed-domains
    (candidate-after-user-deny))
  ("*.example.com"))

!(assertEqual
  (codex:network-proxy-config-denied-domains
    (candidate-after-user-deny))
  ("api.example.com"))

!(assertEqual
  (codex:network-proxy-validate-policy-against-constraints
    (candidate-after-user-deny)
    (codex:network-proxy-spec-constraints
      (allowed-baseline-spec)))
  (codex:network-proxy-validation-ok))

!(assertEqual
  (codex:network-proxy-spec-proxy-host-and-port
    (allowed-baseline-spec))
  "127.0.0.1:3128")

!(assertEqual
  (codex:network-proxy-host-and-port-from-network-addr
    "http://127.0.0.1"
    3128)
  "127.0.0.1:3128")

!(assertEqual
  (codex:network-proxy-spec-socks-enabled
    (allowed-baseline-spec))
  True)

(= (scalar-requirements-spec)
   (spec-value
     (default-config)
     (codex:network-constraints
       True
       9090
       10090
       False
       True
       True
       CodexAbsent
       CodexAbsent
       (codex:network-unix-socket-permissions
         ((unix-allow-entry "/tmp/allow.sock")
          (unix-none-entry "/tmp/none.sock")))
       True)
     (danger-full-access-sandbox)))

!(assertEqual
  (codex:network-proxy-spec-enabled
    (scalar-requirements-spec))
  True)

!(assertEqual
  (codex:network-proxy-spec-proxy-host-and-port
    (scalar-requirements-spec))
  "127.0.0.1:9090")

!(assertEqual
  (codex:network-proxy-config-allow-unix-sockets
    (codex:network-proxy-spec-config
      (scalar-requirements-spec)))
  ("/tmp/allow.sock"))

!(assertEqual
  (codex:network-proxy-constraints-allow-unix-sockets
    (codex:network-proxy-spec-constraints
      (scalar-requirements-spec)))
  ("/tmp/allow.sock"))

(= (audit-metadata)
   (codex:network-proxy-audit-metadata
     "conversation-1"
     "1.2.3"
     "acct-1"))

(= (fallback-plan)
   (codex:network-proxy-spec-start-proxy-plan
     (allowed-baseline-spec)
     (read-only-sandbox)
     CodexAbsent
     CodexAbsent
     True
     (audit-metadata)))

!(assertEqual
  (codex:network-proxy-start-plan-policy-decider
    (fallback-plan))
  (codex:network-proxy-fallback-ask-decider))

!(assertEqual
  (codex:network-proxy-state-audit-metadata
    (codex:network-proxy-start-plan-state
      (fallback-plan)))
  (audit-metadata))

!(assertEqual
  (codex:network-proxy-start-plan-policy-decider
    (codex:network-proxy-spec-start-proxy-plan
      (allowed-baseline-spec)
      (read-only-sandbox)
      custom-decider
      observer-1
      True
      (codex:network-proxy-audit-metadata-default)))
  custom-decider)

!(assertEqual
  (codex:network-proxy-start-plan-blocked-request-observer
    (codex:network-proxy-spec-start-proxy-plan
      (allowed-baseline-spec)
      (read-only-sandbox)
      custom-decider
      observer-1
      True
      (codex:network-proxy-audit-metadata-default)))
  observer-1)

!(assertEqual
  (codex:network-proxy-start-plan-policy-decider
    (codex:network-proxy-spec-start-proxy-plan
      (managed-only-spec)
      (workspace-sandbox)
      custom-decider
      observer-1
      True
      (codex:network-proxy-audit-metadata-default)))
  CodexAbsent)

!(assertEqual
  (codex:network-proxy-start-plan-policy-decider
    (codex:network-proxy-spec-start-proxy-plan
      (allowed-baseline-spec)
      (danger-full-access-sandbox)
      CodexAbsent
      CodexAbsent
      True
      (codex:network-proxy-audit-metadata-default)))
  CodexAbsent)
