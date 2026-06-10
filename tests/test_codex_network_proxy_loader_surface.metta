!(register-module! ../codex)
!(import! &self codex:exec_policy)
!(import! &self codex:network_proxy_loader)
!(import! &self codex:network_proxy_spec)

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

(= (domain-permissions $entries)
   (codex:network-domain-permissions $entries))

(= (unix-socket-permissions $entries)
   (codex:network-unix-socket-permissions $entries))

(= (network-with-domains $entries)
   (codex:network-toml
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     (domain-permissions $entries)
     CodexAbsent
     CodexAbsent))

(= (network-with-allow-all-unix-sockets)
   (codex:network-toml
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent
     True
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (network-with-scalars)
   (codex:network-toml
     True
     "http://127.0.0.1:9000"
     False
     "http://127.0.0.1:9001"
     False
     False
     True
     True
     (codex:network-mode-full)
     (domain-permissions
       ((allow-entry "scalar.example.com")))
     (unix-socket-permissions
       ((unix-allow-entry "/tmp/allow.sock")
        (unix-none-entry "/tmp/none.sock")))
     True))

(= (tables-for-network $network)
   (codex:network-tables-toml
     "workspace"
     (codex:permissions-toml
       ((codex:permissions-toml-entry
          "workspace"
          (codex:permission-profile-toml $network))))))

(= (apply-tables-value $config $tables)
   (codex:network-proxy-loader-result-value
     (codex:network-proxy-loader-apply-network-tables
       $config
       $tables)))

(= (selected-network-value $tables)
   (codex:network-proxy-loader-result-value
     (codex:network-proxy-loader-selected-network-from-tables
       $tables)))

(= (trusted-constraints-value $layers)
   (codex:network-proxy-loader-result-value
     (codex:network-proxy-loader-network-constraints-from-trusted-layers
       $layers)))

(= (config-from-layers-value $layers $exec-policy)
   (codex:network-proxy-loader-result-value
     (codex:network-proxy-loader-config-from-layers
       $layers
       $exec-policy)))

(= (assert-value-equal $value $expected)
   (let $actual $value
     (assertEqual $actual $expected)))

!(assertEqual
  (codex:network-proxy-loader-is-user-controlled-layer
    (codex:config-layer-source-user "/home/me/.codex/config.toml"))
  True)

!(assertEqual
  (codex:network-proxy-loader-is-user-controlled-layer
    (codex:config-layer-source-project "/repo/.codex"))
  True)

!(assertEqual
  (codex:network-proxy-loader-is-user-controlled-layer
    (codex:config-layer-source-session-flags))
  True)

!(assertEqual
  (codex:network-proxy-loader-is-user-controlled-layer
    (codex:config-layer-source-system "/etc/codex/config.toml"))
  False)

(= (overlay-lower-tables)
   (tables-for-network
     (network-with-domains
       ((deny-entry "blocked.example.com")
        (allow-entry "lower.example.com")))))

(= (overlay-higher-tables)
   (tables-for-network
     (network-with-domains
       ((allow-entry "higher.example.com")))))

(= (overlay-config)
   (apply-tables-value
     (apply-tables-value
       (codex:network-proxy-config-default)
       (overlay-lower-tables))
     (overlay-higher-tables)))

!(assert-value-equal
  (codex:network-proxy-config-allowed-domains
    (overlay-config))
  ("lower.example.com" "higher.example.com"))

!(assert-value-equal
  (codex:network-proxy-config-denied-domains
    (overlay-config))
  ("blocked.example.com"))

(= (override-lower-tables)
   (tables-for-network
     (network-with-domains
       ((allow-entry "other.example.com")
        (deny-entry "shared.example.com")))))

(= (override-higher-tables)
   (tables-for-network
     (network-with-domains
       ((allow-entry "shared.example.com")))))

(= (override-config)
   (apply-tables-value
     (apply-tables-value
       (codex:network-proxy-config-default)
       (override-lower-tables))
     (override-higher-tables)))

!(assert-value-equal
  (codex:network-proxy-config-allowed-domains
    (override-config))
  ("other.example.com" "shared.example.com"))

!(assert-value-equal
  (codex:network-proxy-config-denied-domains
    (override-config))
  CodexAbsent)

(= (exec-policy-overlay-config)
   (codex:network-proxy-loader-apply-exec-policy-network-rules
     (codex:network-proxy-config-set-denied-domains
       (codex:network-proxy-config-set-allowed-domains
         (codex:network-proxy-config-default)
         ("config.example.com"))
       ("blocked.example.com"))
     (codex:policy-with-network-rules
       ()
       ((codex:network-rule
          "blocked.example.com"
          (codex:network-rule-protocol-https)
          (codex:decision-allow))
        (codex:network-rule
          "api.example.com"
          (codex:network-rule-protocol-http)
          (codex:decision-forbidden))))))

!(assert-value-equal
  (codex:network-proxy-config-allowed-domains
    (exec-policy-overlay-config))
  ("config.example.com" "blocked.example.com"))

!(assert-value-equal
  (codex:network-proxy-config-denied-domains
    (exec-policy-overlay-config))
  ("api.example.com"))

!(assertEqual
  (codex:network-proxy-constraints-dangerously-allow-all-unix-sockets
    (codex:network-proxy-loader-apply-network-constraints
      (selected-network-value
        (tables-for-network (network-with-allow-all-unix-sockets)))
      (codex:network-proxy-constraints-default)))
  True)

(= (managed-allow-constraints)
   (codex:network-proxy-loader-apply-network-constraints
     (selected-network-value
       (tables-for-network
         (network-with-domains
           ((allow-entry "managed.example.com")))))
     (codex:network-proxy-constraints-default)))

!(assert-value-equal
  (codex:network-proxy-constraints-allowed-domains
    (managed-allow-constraints))
  ("managed.example.com"))

!(assert-value-equal
  (codex:network-proxy-constraints-denied-domains
    (managed-allow-constraints))
  CodexAbsent)

(= (constraint-overlay)
   (codex:network-proxy-loader-apply-network-constraints
     (selected-network-value
       (tables-for-network
         (network-with-domains
           ((allow-entry "api.example.com")))))
     (codex:network-proxy-loader-apply-network-constraints
       (selected-network-value
         (tables-for-network
           (network-with-domains
             ((deny-entry "blocked.example.com")))))
       (codex:network-proxy-constraints-default))))

!(assert-value-equal
  (codex:network-proxy-constraints-allowed-domains
    (constraint-overlay))
  ("api.example.com"))

!(assert-value-equal
  (codex:network-proxy-constraints-denied-domains
    (constraint-overlay))
  ("blocked.example.com"))

(= (scalar-config)
   (apply-tables-value
     (codex:network-proxy-config-default)
     (tables-for-network (network-with-scalars))))

!(assert-value-equal
  (codex:network-proxy-config-enabled (scalar-config))
  True)

!(assert-value-equal
  (codex:network-proxy-config-proxy-url (scalar-config))
  "http://127.0.0.1:9000")

!(assert-value-equal
  (codex:network-proxy-config-enable-socks5 (scalar-config))
  False)

!(assert-value-equal
  (codex:network-proxy-config-socks-url (scalar-config))
  "http://127.0.0.1:9001")

!(assert-value-equal
  (codex:network-proxy-config-enable-socks5-udp (scalar-config))
  False)

!(assert-value-equal
  (codex:network-proxy-config-allow-upstream-proxy (scalar-config))
  False)

!(assert-value-equal
  (codex:network-proxy-config-dangerously-allow-non-loopback-proxy
    (scalar-config))
  True)

!(assert-value-equal
  (codex:network-proxy-config-dangerously-allow-all-unix-sockets
    (scalar-config))
  True)

!(assert-value-equal
  (codex:network-proxy-config-mode (scalar-config))
  (codex:network-mode-full))

!(assert-value-equal
  (codex:network-proxy-config-allowed-domains (scalar-config))
  ("scalar.example.com"))

!(assert-value-equal
  (codex:network-proxy-config-allow-unix-sockets (scalar-config))
  ("/tmp/allow.sock"))

!(assert-value-equal
  (codex:network-proxy-config-allow-local-binding (scalar-config))
  True)

(= (trusted-layer-constraints)
   (trusted-constraints-value
     ((codex:network-proxy-loader-layer
        (codex:config-layer-source-system "/etc/codex/config.toml")
        (tables-for-network
          (network-with-domains
            ((allow-entry "managed.example.com")))))
      (codex:network-proxy-loader-layer
        (codex:config-layer-source-user "/home/me/.codex/config.toml")
        (tables-for-network
          (network-with-domains
            ((allow-entry "user.example.com")))))
      (codex:network-proxy-loader-layer
        (codex:config-layer-source-legacy-managed-config-toml-from-file
          "/etc/codex/managed.toml")
        (tables-for-network
          (network-with-domains
            ((deny-entry "managed-blocked.example.com"))))
        False))))

!(assert-value-equal
  (codex:network-proxy-constraints-allowed-domains
    (trusted-layer-constraints))
  ("managed.example.com"))

!(assert-value-equal
  (codex:network-proxy-constraints-denied-domains
    (trusted-layer-constraints))
  CodexAbsent)

(= (config-from-all-layers)
   (config-from-layers-value
     ((codex:network-proxy-loader-layer
        (codex:config-layer-source-system "/etc/codex/config.toml")
        (tables-for-network
          (network-with-domains
            ((allow-entry "managed.example.com")))))
      (codex:network-proxy-loader-layer
        (codex:config-layer-source-user "/home/me/.codex/config.toml")
        (tables-for-network
          (network-with-domains
            ((allow-entry "user.example.com"))))))
     (codex:policy-with-network-rules
       ()
       ((codex:network-rule
          "policy-blocked.example.com"
          (codex:network-rule-protocol-https)
          (codex:decision-forbidden))))))

!(assert-value-equal
  (codex:network-proxy-config-allowed-domains
    (config-from-all-layers))
  ("managed.example.com" "user.example.com"))

!(assert-value-equal
  (codex:network-proxy-config-denied-domains
    (config-from-all-layers))
  ("policy-blocked.example.com"))

!(assertEqual
  (selected-network-value
    (codex:network-tables-toml
      CodexAbsent
      (codex:permissions-toml
        ((codex:permissions-toml-entry
           "workspace"
           (codex:permission-profile-toml (network-with-scalars)))))))
  CodexAbsent)

!(assertEqual
  (codex:network-proxy-loader-result-error-message
    (codex:network-proxy-loader-selected-network-from-tables
      (codex:network-tables-toml "workspace" CodexAbsent)))
  "default_permissions requires a `[permissions]` table for network settings")

!(assertEqual
  (codex:network-proxy-loader-result-error-message
    (codex:network-proxy-loader-selected-network-from-tables
      (codex:network-tables-toml
        "missing"
        (codex:permissions-toml
          ((codex:permissions-toml-entry
             "workspace"
             (codex:permission-profile-toml CodexAbsent)))))))
  "default_permissions refers to undefined profile `missing`")
