; Rust-faithful pure network-proxy-loader slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/network_proxy_loader.rs
; - openai-codex/codex-rs/config/src/permissions_toml.rs
;   - `NetworkToml::apply_to_network_proxy_config`
;   - `overlay_network_domain_permissions`
;
; Covered in this increment:
; - user-controlled config layer classification
; - permission profile network table selection
; - ordered network table application to `NetworkProxyConfig`
; - trusted-layer `NetworkProxyConstraints` materialization
; - exec-policy compiled network-domain overlay
;
; Required CeTTa representation notes for audit:
; - Rust obtains `NetworkTablesToml`, `PermissionsToml`, and `NetworkToml`
;   through serde TOML deserialization. This slice starts from equivalent
;   constructor values; text TOML parsing remains with the future config parser
;   boundary.
; - Rust's async mtime reloader reads filesystem metadata and rebuilds live
;   proxy state. CeTTa does not yet have that runtime boundary, so this slice
;   ports only the pure config/constraint selection logic used by the reloader.

!(import! &self exec_policy)
!(import! &self list)
!(import! &self network_proxy_spec)
!(import! &self str)

(= (codex:network-proxy-loader-result-ok $value)
   (CodexNetworkProxyLoaderOk $value))

(= (codex:network-proxy-loader-result-error $message)
   (CodexNetworkProxyLoaderError $message))

(= (codex:network-proxy-loader-result-value
      (CodexNetworkProxyLoaderOk $value))
   $value)

(= (codex:network-proxy-loader-result-error-message
      (CodexNetworkProxyLoaderError $message))
   $message)

(= (codex:config-layer-source-system $file)
   (CodexConfigLayerSourceSystem $file))

(= (codex:config-layer-source-user $file)
   (CodexConfigLayerSourceUser $file))

(= (codex:config-layer-source-project $dot-codex-folder)
   (CodexConfigLayerSourceProject $dot-codex-folder))

(= (codex:config-layer-source-legacy-managed-config-toml-from-file $file)
   (CodexConfigLayerSourceLegacyManagedConfigTomlFromFile $file))

(= (codex:config-layer-source-session-flags)
   (CodexConfigLayerSourceSessionFlags))

(= (codex:config-layer-source-cloud)
   (CodexConfigLayerSourceCloud))

(= (codex:network-proxy-loader-is-user-controlled-layer $layer)
   (case $layer
     (((CodexConfigLayerSourceUser $file) True)
      ((CodexConfigLayerSourceProject $dot-codex-folder) True)
      ((CodexConfigLayerSourceSessionFlags) True)
      ($other False))))

(= (codex:network-proxy-loader-layer $source $network-tables)
   (CodexNetworkProxyLoaderLayer $source $network-tables True))

(= (codex:network-proxy-loader-layer $source $network-tables $enabled)
   (CodexNetworkProxyLoaderLayer $source $network-tables $enabled))

(= (codex:network-proxy-loader-layer-source
      (CodexNetworkProxyLoaderLayer $source $network-tables $enabled))
   $source)

(= (codex:network-proxy-loader-layer-network-tables
      (CodexNetworkProxyLoaderLayer $source $network-tables $enabled))
   $network-tables)

(= (codex:network-proxy-loader-layer-enabled
      (CodexNetworkProxyLoaderLayer $source $network-tables $enabled))
   $enabled)

(= (codex:network-toml
      $enabled
      $proxy-url
      $enable-socks5
      $socks-url
      $enable-socks5-udp
      $allow-upstream-proxy
      $dangerously-allow-non-loopback-proxy
      $dangerously-allow-all-unix-sockets
      $mode
      $domains
      $unix-sockets
      $allow-local-binding)
   (CodexNetworkToml
     $enabled
     $proxy-url
     $enable-socks5
     $socks-url
     $enable-socks5-udp
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $mode
     $domains
     $unix-sockets
     $allow-local-binding))

(= (codex:network-toml-default)
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
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:network-toml-enabled
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $enabled)

(= (codex:network-toml-proxy-url
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $proxy-url)

(= (codex:network-toml-enable-socks5
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $enable-socks5)

(= (codex:network-toml-socks-url
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $socks-url)

(= (codex:network-toml-enable-socks5-udp
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $enable-socks5-udp)

(= (codex:network-toml-allow-upstream-proxy
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $allow-upstream-proxy)

(= (codex:network-toml-dangerously-allow-non-loopback-proxy
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $dangerously-allow-non-loopback-proxy)

(= (codex:network-toml-dangerously-allow-all-unix-sockets
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $dangerously-allow-all-unix-sockets)

(= (codex:network-toml-mode
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $mode)

(= (codex:network-toml-domains
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $domains)

(= (codex:network-toml-unix-sockets
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $unix-sockets)

(= (codex:network-toml-allow-local-binding
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding))
   $allow-local-binding)

(= (codex:permission-profile-toml $network)
   (CodexPermissionProfileToml CodexAbsent $network))

(= (codex:permission-profile-toml $filesystem $network)
   (CodexPermissionProfileToml $filesystem $network))

(= (codex:permission-profile-toml-network
      (CodexPermissionProfileToml $filesystem $network))
   $network)

(= (codex:permissions-toml-entry $name $profile)
   (CodexPermissionsTomlEntry $name $profile))

(= (codex:permissions-toml-entry-name
      (CodexPermissionsTomlEntry $name $profile))
   $name)

(= (codex:permissions-toml-entry-profile
      (CodexPermissionsTomlEntry $name $profile))
   $profile)

(= (codex:permissions-toml $entries)
   (CodexPermissionsToml $entries))

(= (codex:permissions-toml-entries
      (CodexPermissionsToml $entries))
   $entries)

(= (codex:network-tables-toml $default-permissions $permissions)
   (CodexNetworkTablesToml $default-permissions $permissions))

(= (codex:network-tables-toml-default-permissions
      (CodexNetworkTablesToml $default-permissions $permissions))
   $default-permissions)

(= (codex:network-tables-toml-permissions
      (CodexNetworkTablesToml $default-permissions $permissions))
   $permissions)

(= (codex:network-proxy-loader-resolve-permission-profile-entries
      $entries
      $profile-name)
   (if (== $entries ())
       (codex:network-proxy-loader-result-error
         (str-concat
           "default_permissions refers to undefined profile `"
           (str-concat $profile-name "`")))
       (let $head (list:first $entries)
         (let $tail (list:rest $entries)
           (if (== (codex:permissions-toml-entry-name $head) $profile-name)
               (codex:network-proxy-loader-result-ok
                 (codex:permissions-toml-entry-profile $head))
               (codex:network-proxy-loader-resolve-permission-profile-entries
                 $tail
                 $profile-name))))))

(= (codex:network-proxy-loader-resolve-permission-profile
      (CodexPermissionsToml $entries)
      $profile-name)
   (codex:network-proxy-loader-resolve-permission-profile-entries
     $entries
     $profile-name))

(= (codex:network-proxy-loader-selected-network-from-tables
      (CodexNetworkTablesToml $default-permissions $permissions))
   (if (== $default-permissions CodexAbsent)
       (codex:network-proxy-loader-result-ok CodexAbsent)
       (if (== $permissions CodexAbsent)
           (codex:network-proxy-loader-result-error
             "default_permissions requires a `[permissions]` table for network settings")
           (case
             (codex:network-proxy-loader-resolve-permission-profile
               $permissions
               $default-permissions)
             (((CodexNetworkProxyLoaderOk $profile)
               (codex:network-proxy-loader-result-ok
                 (codex:permission-profile-toml-network $profile)))
              ((CodexNetworkProxyLoaderError $message)
               (codex:network-proxy-loader-result-error $message)))))))

(= (codex:network-proxy-loader-overlay-domain-permission-entries
      $config
      $entries)
   (if (== $entries ())
       $config
       (let $head (list:first $entries)
         (let $tail (list:rest $entries)
           (let $next-config
             (eval
               (codex:network-proxy-config-upsert-domain-permission
                 $config
                 (codex:network-domain-permission-entry-pattern $head)
                 (codex:network-domain-permission-entry-permission $head)))
             (codex:network-proxy-loader-overlay-domain-permission-entries
               $next-config
               $tail))))))

(= (codex:network-proxy-loader-overlay-network-domain-permissions
      $config
      CodexAbsent)
   $config)

(= (codex:network-proxy-loader-overlay-network-domain-permissions
      $config
      (CodexNetworkDomainPermissions $entries))
   (codex:network-proxy-loader-overlay-domain-permission-entries
     $config
     $entries))

(= (codex:network-proxy-loader-unix-socket-remove-path
      $entries
      $path)
   (if (== $entries ())
       ()
       (let $head (list:first $entries)
         (let $tail (list:rest $entries)
           (let $rest
             (codex:network-proxy-loader-unix-socket-remove-path
               $tail
               $path)
             (if (==
                   (codex:network-unix-socket-permission-entry-path $head)
                   $path)
                 $rest
                 (cons-atom $head $rest)))))))

(= (codex:network-proxy-loader-upsert-unix-socket-permission
      CodexAbsent
      $entry)
   (codex:network-unix-socket-permissions ($entry)))

(= (codex:network-proxy-loader-upsert-unix-socket-permission
      (CodexNetworkUnixSocketPermissions $entries)
      $entry)
   (codex:network-unix-socket-permissions
     (list:push
       (codex:network-proxy-loader-unix-socket-remove-path
         $entries
         (codex:network-unix-socket-permission-entry-path $entry))
       $entry)))

(= (codex:network-proxy-loader-overlay-unix-socket-entries
      $permissions
      $entries)
   (if (== $entries ())
       $permissions
       (let $head (list:first $entries)
         (let $tail (list:rest $entries)
           (codex:network-proxy-loader-overlay-unix-socket-entries
             (codex:network-proxy-loader-upsert-unix-socket-permission
               $permissions
               $head)
             $tail)))))

(= (codex:network-proxy-loader-overlay-unix-socket-permissions
      $config
      CodexAbsent)
   $config)

(= (codex:network-proxy-loader-overlay-unix-socket-permissions
      $config
      (CodexNetworkUnixSocketPermissions $entries))
   (codex:network-proxy-config-set-unix-sockets
     $config
     (codex:network-proxy-loader-overlay-unix-socket-entries
       (codex:network-proxy-config-unix-sockets $config)
       $entries)))

(= (codex:network-toml-apply-to-network-proxy-config
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding)
      $config)
   (let $config-1
     (if (== $enabled CodexAbsent)
         $config
         (codex:network-proxy-config-set-enabled $config $enabled))
     (let $config-2
       (if (== $proxy-url CodexAbsent)
           $config-1
           (codex:network-proxy-config-set-proxy-url $config-1 $proxy-url))
       (let $config-3
         (if (== $enable-socks5 CodexAbsent)
             $config-2
             (codex:network-proxy-config-set-enable-socks5
               $config-2
               $enable-socks5))
         (let $config-4
           (if (== $socks-url CodexAbsent)
               $config-3
               (codex:network-proxy-config-set-socks-url
                 $config-3
                 $socks-url))
           (let $config-5
             (if (== $enable-socks5-udp CodexAbsent)
                 $config-4
                 (codex:network-proxy-config-set-enable-socks5-udp
                   $config-4
                   $enable-socks5-udp))
             (let $config-6
               (if (== $allow-upstream-proxy CodexAbsent)
                   $config-5
                   (codex:network-proxy-config-set-allow-upstream-proxy
                     $config-5
                     $allow-upstream-proxy))
               (let $config-7
                 (if (== $dangerously-allow-non-loopback-proxy CodexAbsent)
                     $config-6
                     (codex:network-proxy-config-set-dangerously-allow-non-loopback-proxy
                       $config-6
                       $dangerously-allow-non-loopback-proxy))
                 (let $config-8
                   (if (== $dangerously-allow-all-unix-sockets CodexAbsent)
                       $config-7
                       (codex:network-proxy-config-set-dangerously-allow-all-unix-sockets
                         $config-7
                         $dangerously-allow-all-unix-sockets))
                   (let $config-9
                     (if (== $mode CodexAbsent)
                         $config-8
                         (codex:network-proxy-config-set-mode
                           $config-8
                           $mode))
                     (let $config-10
                       (if (== $domains CodexAbsent)
                           $config-9
                           (codex:network-proxy-loader-overlay-network-domain-permissions
                             $config-9
                             $domains))
                       (let $config-11
                         (if (== $unix-sockets CodexAbsent)
                             $config-10
                             (codex:network-proxy-loader-overlay-unix-socket-permissions
                               $config-10
                               $unix-sockets))
                         (if (== $allow-local-binding CodexAbsent)
                             $config-11
                             (codex:network-proxy-config-set-allow-local-binding
                               $config-11
                               $allow-local-binding))))))))))))))

(= (codex:network-proxy-loader-apply-network-tables
      $config
      $tables)
   (case (collapse $config)
     ((($materialized-config)
       (case (codex:network-proxy-loader-selected-network-from-tables $tables)
         (((CodexNetworkProxyLoaderOk $network)
           (if (== $network CodexAbsent)
               (codex:network-proxy-loader-result-ok $materialized-config)
               (codex:network-proxy-loader-result-ok
                 (codex:network-toml-apply-to-network-proxy-config
                   $network
                   $materialized-config))))
          ((CodexNetworkProxyLoaderError $message)
           (codex:network-proxy-loader-result-error $message))))))))

(= (codex:network-proxy-loader-config-from-layers
      $layers
      $exec-policy)
   (case
     (codex:network-proxy-loader-config-from-layers-acc
       $layers
       (codex:network-proxy-config-default))
     (((CodexNetworkProxyLoaderOk $config)
       (codex:network-proxy-loader-result-ok
         (codex:network-proxy-loader-apply-exec-policy-network-rules
           $config
           $exec-policy)))
      ((CodexNetworkProxyLoaderError $message)
       (codex:network-proxy-loader-result-error $message)))))

(= (codex:network-proxy-loader-config-from-layers-acc
      $layers
      $config)
   (if (== $layers ())
       (codex:network-proxy-loader-result-ok $config)
       (let $layer (list:first $layers)
         (let $tail (list:rest $layers)
           (if (codex:network-proxy-loader-layer-enabled $layer)
               (case
                 (codex:network-proxy-loader-apply-network-tables
                   $config
                   (codex:network-proxy-loader-layer-network-tables $layer))
                 (((CodexNetworkProxyLoaderOk $next-config)
                   (codex:network-proxy-loader-config-from-layers-acc
                     $tail
                     $next-config))
                  ((CodexNetworkProxyLoaderError $message)
                   (codex:network-proxy-loader-result-error $message))))
               (codex:network-proxy-loader-config-from-layers-acc
                 $tail
                 $config))))))

(= (codex:network-proxy-loader-upsert-network-domains
      $config
      $domains
      $permission)
   (if (== $domains ())
       $config
       (let $head (list:first $domains)
         (let $tail (list:rest $domains)
           (let $next-config
             (eval
               (codex:network-proxy-config-upsert-domain-permission
                 $config
                 $head
                 $permission))
             (codex:network-proxy-loader-upsert-network-domains
               $next-config
               $tail
               $permission))))))

(= (codex:network-proxy-loader-apply-exec-policy-network-rules
      $config
      $exec-policy)
   (let $compiled (codex:compiled-network-domains $exec-policy)
     (let $config-with-allowed
       (codex:network-proxy-loader-upsert-network-domains
         $config
         (codex:compiled-network-domains-allowed $compiled)
         (codex:network-domain-permission-allow))
       (codex:network-proxy-loader-upsert-network-domains
         $config-with-allowed
         (codex:compiled-network-domains-denied $compiled)
         (codex:network-domain-permission-deny)))))

(= (codex:network-proxy-loader-seed-constraints-domain-config
      $constraints)
   (let $base-config (codex:network-proxy-config-default)
     (let $allowed-domains
       (codex:network-proxy-constraints-allowed-domains $constraints)
       (let $allowed-config
         (if (== $allowed-domains CodexAbsent)
             $base-config
             (codex:network-proxy-config-set-allowed-domains
               $base-config
               $allowed-domains))
         (let $denied-domains
           (codex:network-proxy-constraints-denied-domains $constraints)
           (if (== $denied-domains CodexAbsent)
               $allowed-config
               (codex:network-proxy-config-set-denied-domains
                 $allowed-config
                 $denied-domains)))))))

(= (codex:network-proxy-loader-apply-constraint-domain-overlay
      $constraints
      $domains)
   (let $domain-config
     (codex:network-proxy-loader-overlay-network-domain-permissions
       (codex:network-proxy-loader-seed-constraints-domain-config
         $constraints)
       $domains)
     (codex:network-proxy-constraints-set-denied-domains
       (codex:network-proxy-constraints-set-allowed-domains
         $constraints
         (codex:network-proxy-config-allowed-domains $domain-config)
         (codex:network-proxy-constraints-allowlist-expansion-enabled
           $constraints))
       (codex:network-proxy-config-denied-domains $domain-config)
       (codex:network-proxy-constraints-denylist-expansion-enabled
         $constraints))))

(= (codex:network-proxy-loader-apply-network-constraints
      (CodexNetworkToml
        $enabled
        $proxy-url
        $enable-socks5
        $socks-url
        $enable-socks5-udp
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $mode
        $domains
        $unix-sockets
        $allow-local-binding)
      $constraints)
   (let $constraints-1
     (if (== $enabled CodexAbsent)
         $constraints
         (codex:network-proxy-constraints-set-enabled
           $constraints
           $enabled))
     (let $constraints-2
       (if (== $mode CodexAbsent)
           $constraints-1
           (codex:network-proxy-constraints-set-mode
             $constraints-1
             $mode))
       (let $constraints-3
         (if (== $allow-upstream-proxy CodexAbsent)
             $constraints-2
             (codex:network-proxy-constraints-set-allow-upstream-proxy
               $constraints-2
               $allow-upstream-proxy))
         (let $constraints-4
           (if (== $dangerously-allow-non-loopback-proxy CodexAbsent)
               $constraints-3
               (codex:network-proxy-constraints-set-dangerously-allow-non-loopback-proxy
                 $constraints-3
                 $dangerously-allow-non-loopback-proxy))
           (let $constraints-5
             (if (== $dangerously-allow-all-unix-sockets CodexAbsent)
                 $constraints-4
                 (codex:network-proxy-constraints-set-dangerously-allow-all-unix-sockets
                   $constraints-4
                   $dangerously-allow-all-unix-sockets))
             (let $constraints-6
               (if (== $domains CodexAbsent)
                   $constraints-5
                   (codex:network-proxy-loader-apply-constraint-domain-overlay
                     $constraints-5
                     $domains))
               (let $constraints-7
                 (if (== $unix-sockets CodexAbsent)
                     $constraints-6
                     (codex:network-proxy-constraints-set-allow-unix-sockets
                       $constraints-6
                       (codex:network-unix-socket-permissions-allow-unix-sockets
                         $unix-sockets)))
                 (if (== $allow-local-binding CodexAbsent)
                     $constraints-7
                     (codex:network-proxy-constraints-set-allow-local-binding
                       $constraints-7
                       $allow-local-binding))))))))))

(= (codex:network-proxy-loader-network-constraints-from-trusted-layers
      $layers)
   (codex:network-proxy-loader-network-constraints-from-trusted-layers-acc
     $layers
     (codex:network-proxy-constraints-default)))

(= (codex:network-proxy-loader-network-constraints-from-trusted-layers-acc
      $layers
      $constraints)
   (if (== $layers ())
       (codex:network-proxy-loader-result-ok $constraints)
       (let $layer (list:first $layers)
         (let $tail (list:rest $layers)
           (if (not (codex:network-proxy-loader-layer-enabled $layer))
               (codex:network-proxy-loader-network-constraints-from-trusted-layers-acc
                 $tail
                 $constraints)
               (if (codex:network-proxy-loader-is-user-controlled-layer
                     (codex:network-proxy-loader-layer-source $layer))
                   (codex:network-proxy-loader-network-constraints-from-trusted-layers-acc
                     $tail
                     $constraints)
                   (case
                     (codex:network-proxy-loader-selected-network-from-tables
                       (codex:network-proxy-loader-layer-network-tables $layer))
                     (((CodexNetworkProxyLoaderOk $network)
                       (if (== $network CodexAbsent)
                           (codex:network-proxy-loader-network-constraints-from-trusted-layers-acc
                             $tail
                             $constraints)
                           (codex:network-proxy-loader-network-constraints-from-trusted-layers-acc
                             $tail
                             (codex:network-proxy-loader-apply-network-constraints
                               $network
                               $constraints))))
                      ((CodexNetworkProxyLoaderError $message)
                       (codex:network-proxy-loader-result-error $message))))))))))
