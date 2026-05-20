; Rust-faithful pure network-proxy-spec slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/config/network_proxy_spec.rs
; - openai-codex/codex-rs/network-proxy/src/config.rs
; - openai-codex/codex-rs/network-proxy/src/state.rs
;
; Covered in this increment:
; - NetworkProxyConfig/Settings domain permission helpers
; - NetworkProxyConstraints/NetworkConstraints data shape
; - NetworkProxySpec::from_config_and_constraints domain/scalar requirement
;   application
; - NetworkProxySpec::enabled, proxy_host_and_port, socks_enabled
; - NetworkProxySpec::start_proxy builder decisions as a pure start plan
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust builds and runs an async NetworkProxy and returns a live handle.
;   CeTTa does not yet have the proxy runtime, so `start-proxy-plan` preserves
;   the same builder-side decisions as explicit data: derived state, selected
;   policy decider, and blocked-request observer.
; - Rust validation supports full URL/glob parsing through `url` and `globset`.
;   This slice ports the constraint branches used by NetworkProxySpec's managed
;   domain merge flow and leaves complete network-proxy policy matching for the
;   future proxy-runtime slice.

!(import! &self list)
!(import! &self str)

(= (codex:network-mode-limited)
   (CodexNetworkModeLimited))

(= (codex:network-mode-full)
   (CodexNetworkModeFull))

(= (codex:network-domain-permission-none)
   (CodexNetworkDomainPermissionNone))

(= (codex:network-domain-permission-allow)
   (CodexNetworkDomainPermissionAllow))

(= (codex:network-domain-permission-deny)
   (CodexNetworkDomainPermissionDeny))

(= (codex:network-domain-permission-rank
      (CodexNetworkDomainPermissionNone))
   0)

(= (codex:network-domain-permission-rank
      (CodexNetworkDomainPermissionAllow))
   1)

(= (codex:network-domain-permission-rank
      (CodexNetworkDomainPermissionDeny))
   2)

(= (codex:network-domain-permission-max $left $right)
   (if (>
         (codex:network-domain-permission-rank $left)
         (codex:network-domain-permission-rank $right))
       $left
       $right))

(= (codex:network-domain-permission-entry $pattern $permission)
   (CodexNetworkDomainPermissionEntry $pattern $permission))

(= (codex:network-domain-permission-entry-pattern
      (CodexNetworkDomainPermissionEntry $pattern $permission))
   $pattern)

(= (codex:network-domain-permission-entry-permission
      (CodexNetworkDomainPermissionEntry $pattern $permission))
   $permission)

(= (codex:network-domain-permissions $entries)
   (CodexNetworkDomainPermissions $entries))

(= (codex:network-domain-permissions-entries
      (CodexNetworkDomainPermissions $entries))
   $entries)

(= (codex:network-proxy-ascii-lower-char $char)
   (case $char
     (("A" "a") ("B" "b") ("C" "c") ("D" "d") ("E" "e")
      ("F" "f") ("G" "g") ("H" "h") ("I" "i") ("J" "j")
      ("K" "k") ("L" "l") ("M" "m") ("N" "n") ("O" "o")
      ("P" "p") ("Q" "q") ("R" "r") ("S" "s") ("T" "t")
      ("U" "u") ("V" "v") ("W" "w") ("X" "x") ("Y" "y")
      ("Z" "z") ($char $char))))

(= (codex:network-proxy-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:network-proxy-ascii-lower-char
           (str-slice $text 0 1))
         (codex:network-proxy-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:network-proxy-eq-ignore-ascii-case $left $right)
   (==
     (codex:network-proxy-ascii-lower-text $left)
     (codex:network-proxy-ascii-lower-text $right)))

(= (codex:network-proxy-trim-trailing-dot $text)
   (if (== $text "")
       ""
       (if (str-ends-with? $text ".")
           (codex:network-proxy-trim-trailing-dot
             (str-slice $text 0 (- (str-length $text) 1)))
           $text)))

(= (codex:network-proxy-normalize-host $host)
   (let $trimmed (str-trim $host)
     (if (str-starts-with? $trimmed "[")
         (case (str-find $trimmed "]")
           ((Empty
             (codex:network-proxy-ascii-lower-text
               (codex:network-proxy-trim-trailing-dot $trimmed)))
            ($close-index
             (codex:network-proxy-ascii-lower-text
               (codex:network-proxy-trim-trailing-dot
                 (str-slice $trimmed 1 $close-index))))))
         (let $parts (str-split ":" $trimmed)
           (let $candidate
             (if (== (list:len $parts) 2)
                 (list:first $parts)
                 $trimmed)
             (codex:network-proxy-ascii-lower-text
               (codex:network-proxy-trim-trailing-dot $candidate)))))))

(= (codex:network-domain-permission-entry-same-pattern
      $entry
      $candidate)
   (==
     (codex:network-domain-permission-entry-pattern $entry)
     (codex:network-domain-permission-entry-pattern $candidate)))

(= (codex:network-domain-permissions-upsert-effective-entry
      $entries
      $entry)
   (if (== $entries ())
       ($entry)
       (let ($head $tail) (decons-atom $entries)
         (if (codex:network-domain-permission-entry-same-pattern
               $head
               $entry)
             (cons-atom
               (codex:network-domain-permission-entry
                 (codex:network-domain-permission-entry-pattern $head)
                 (codex:network-domain-permission-max
                   (codex:network-domain-permission-entry-permission $head)
                   (codex:network-domain-permission-entry-permission $entry)))
               $tail)
             (cons-atom
               $head
               (codex:network-domain-permissions-upsert-effective-entry
                 $tail
                 $entry))))))

(= (codex:network-domain-permissions-effective-entries-acc
      $entries
      $acc)
   (if (== $entries ())
       $acc
       (let ($head $tail) (decons-atom $entries)
         (codex:network-domain-permissions-effective-entries-acc
           $tail
           (codex:network-domain-permissions-upsert-effective-entry
             $acc
             $head)))))

(= (codex:network-domain-permissions-effective-entries
      CodexAbsent)
   ())

(= (codex:network-domain-permissions-effective-entries
      (CodexNetworkDomainPermissions $entries))
   (codex:network-domain-permissions-effective-entries-acc
     $entries
     ()))

(= (codex:network-domain-permissions-filter-patterns
      $entries
      $permission)
   (if (== $entries ())
       ()
       (let ($head $tail) (decons-atom $entries)
         (let $rest
           (codex:network-domain-permissions-filter-patterns
             $tail
             $permission)
           (if (==
                 (codex:network-domain-permission-entry-permission $head)
                 $permission)
               (cons-atom
                 (codex:network-domain-permission-entry-pattern $head)
                 $rest)
               $rest)))))

(= (codex:network-domain-permissions-patterns-for
      $domains
      $permission)
   (let $patterns
     (codex:network-domain-permissions-filter-patterns
       (codex:network-domain-permissions-effective-entries $domains)
       $permission)
     (if (== $patterns ())
         CodexAbsent
         $patterns)))

(= (codex:network-domain-permissions-allowed-domains $domains)
   (codex:network-domain-permissions-patterns-for
     $domains
     (codex:network-domain-permission-allow)))

(= (codex:network-domain-permissions-denied-domains $domains)
   (codex:network-domain-permissions-patterns-for
     $domains
     (codex:network-domain-permission-deny)))

(= (codex:network-unix-socket-permission-none)
   (CodexNetworkUnixSocketPermissionNone))

(= (codex:network-unix-socket-permission-allow)
   (CodexNetworkUnixSocketPermissionAllow))

(= (codex:network-unix-socket-permission-entry $path $permission)
   (CodexNetworkUnixSocketPermissionEntry $path $permission))

(= (codex:network-unix-socket-permission-entry-path
      (CodexNetworkUnixSocketPermissionEntry $path $permission))
   $path)

(= (codex:network-unix-socket-permission-entry-permission
      (CodexNetworkUnixSocketPermissionEntry $path $permission))
   $permission)

(= (codex:network-unix-socket-permissions $entries)
   (CodexNetworkUnixSocketPermissions $entries))

(= (codex:network-unix-socket-permissions-entries
      (CodexNetworkUnixSocketPermissions $entries))
   $entries)

(= (codex:network-unix-socket-permissions-filter-paths
      $entries
      $permission)
   (if (== $entries ())
       ()
       (let ($head $tail) (decons-atom $entries)
         (let $rest
           (codex:network-unix-socket-permissions-filter-paths
             $tail
             $permission)
           (if (==
                 (codex:network-unix-socket-permission-entry-permission
                   $head)
                 $permission)
               (let $path
                 (codex:network-unix-socket-permission-entry-path $head)
                 (cons-atom $path $rest))
               $rest)))))

(= (codex:network-unix-socket-permissions-allow-unix-sockets
      CodexAbsent)
   ())

(= (codex:network-unix-socket-permissions-allow-unix-sockets
      (CodexNetworkUnixSocketPermissions $entries))
   (codex:network-unix-socket-permissions-filter-paths
     $entries
     (codex:network-unix-socket-permission-allow)))

(= (codex:network-unix-socket-remove-permission
      $entries
      $permission)
   (if (== $entries ())
       ()
       (let ($head $tail) (decons-atom $entries)
         (let $rest
           (codex:network-unix-socket-remove-permission
             $tail
             $permission)
           (if (==
                 (codex:network-unix-socket-permission-entry-permission
                   $head)
                 $permission)
               $rest
               (cons-atom $head $rest))))))

(= (codex:network-unix-socket-add-paths
      $entries
      $paths
      $permission)
   (if (== $paths ())
       $entries
       (let ($head $tail) (decons-atom $paths)
         (codex:network-unix-socket-add-paths
           (list:push
             $entries
             (codex:network-unix-socket-permission-entry
               $head
               $permission))
           $tail
           $permission))))

(= (codex:network-unix-socket-permissions-set-entries
      CodexAbsent
      $paths
      $permission)
   (codex:network-unix-socket-permissions-set-entries
     (codex:network-unix-socket-permissions ())
     $paths
     $permission))

(= (codex:network-unix-socket-permissions-set-entries
      (CodexNetworkUnixSocketPermissions $entries)
      $paths
      $permission)
   (let $retained
     (codex:network-unix-socket-remove-permission
       $entries
       $permission)
     (let $updated
       (codex:network-unix-socket-add-paths
         $retained
         $paths
         $permission)
       (if (== $updated ())
           CodexAbsent
           (codex:network-unix-socket-permissions $updated)))))

(= (codex:network-domain-entry-exists
      $entries
      $pattern
      $permission)
   (if (== $entries ())
       False
       (let ($head $tail) (decons-atom $entries)
         (if (and
               (==
                 (codex:network-domain-permission-entry-pattern $head)
                 $pattern)
               (==
                 (codex:network-domain-permission-entry-permission $head)
                 $permission))
             True
             (codex:network-domain-entry-exists
               $tail
               $pattern
               $permission)))))

(= (codex:network-domain-remove-permission
      $entries
      $permission)
   (if (== $entries ())
       ()
       (let ($head $tail) (decons-atom $entries)
         (let $rest
           (codex:network-domain-remove-permission $tail $permission)
           (if (==
                 (codex:network-domain-permission-entry-permission $head)
                 $permission)
               $rest
               (cons-atom $head $rest))))))

(= (codex:network-domain-add-patterns
      $entries
      $patterns
      $permission)
   (if (== $patterns ())
       $entries
       (let ($head $tail) (decons-atom $patterns)
         (let $next
           (if (codex:network-domain-entry-exists
                 $entries
                 $head
                 $permission)
               $entries
               (list:push
                 $entries
                 (codex:network-domain-permission-entry
                   $head
                   $permission)))
           (codex:network-domain-add-patterns
             $next
             $tail
             $permission)))))

(= (codex:network-domain-permissions-set-domain-entries
      CodexAbsent
      $patterns
      $permission)
   (codex:network-domain-permissions-set-domain-entries
     (codex:network-domain-permissions ())
     $patterns
     $permission))

(= (codex:network-domain-permissions-set-domain-entries
      (CodexNetworkDomainPermissions $entries)
      $patterns
      $permission)
   (let $retained
     (codex:network-domain-remove-permission
       $entries
       $permission)
     (let $updated
       (codex:network-domain-add-patterns
         $retained
         $patterns
         $permission)
       (if (== $updated ())
           CodexAbsent
           (codex:network-domain-permissions $updated)))))

(= (codex:network-domain-remove-normalized-host
      $entries
      $normalized-host)
   (if (== $entries ())
       ()
       (let ($head $tail) (decons-atom $entries)
         (let $rest
           (codex:network-domain-remove-normalized-host
             $tail
             $normalized-host)
           (if (==
                 (codex:network-proxy-normalize-host
                   (codex:network-domain-permission-entry-pattern $head))
                 $normalized-host)
               $rest
               (cons-atom $head $rest))))))

(= (codex:network-domain-permissions-upsert-domain-permission
      CodexAbsent
      $host
      $permission)
   (codex:network-domain-permissions
     ((codex:network-domain-permission-entry $host $permission))))

(= (codex:network-domain-permissions-upsert-domain-permission
      (CodexNetworkDomainPermissions $entries)
      $host
      $permission)
   (let $normalized-host (codex:network-proxy-normalize-host $host)
     (let $retained
       (codex:network-domain-remove-normalized-host
         $entries
         $normalized-host)
       (codex:network-domain-permissions
         (list:push
           $retained
           (codex:network-domain-permission-entry
             $host
             $permission))))))

(= (codex:network-proxy-settings
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
      $allow-local-binding
      $mitm)
   (CodexNetworkProxySettings
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
     $allow-local-binding
     $mitm))

(= (codex:network-proxy-settings-default)
   (codex:network-proxy-settings
     False
     "http://127.0.0.1:3128"
     True
     "http://127.0.0.1:8081"
     True
     True
     False
     False
     (codex:network-mode-limited)
     CodexAbsent
     CodexAbsent
     False
     False))

(= (codex:network-proxy-config $network)
   (CodexNetworkProxyConfig $network))

(= (codex:network-proxy-config-default)
   (codex:network-proxy-config
     (codex:network-proxy-settings-default)))

(= (codex:network-proxy-config-network
      (CodexNetworkProxyConfig $network))
   $network)

(= (codex:network-proxy-settings-enabled
      (CodexNetworkProxySettings
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
        $allow-local-binding
        $mitm))
   $enabled)

(= (codex:network-proxy-settings-proxy-url
      (CodexNetworkProxySettings
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
        $allow-local-binding
        $mitm))
   $proxy-url)

(= (codex:network-proxy-settings-enable-socks5
      (CodexNetworkProxySettings
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
        $allow-local-binding
        $mitm))
   $enable-socks5)

(= (codex:network-proxy-settings-domains
      (CodexNetworkProxySettings
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
        $allow-local-binding
        $mitm))
   $domains)

(= (codex:network-proxy-settings-unix-sockets
      (CodexNetworkProxySettings
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
        $allow-local-binding
        $mitm))
   $unix-sockets)

(= (codex:network-proxy-settings-allowed-domains $settings)
   (codex:network-domain-permissions-allowed-domains
     (codex:network-proxy-settings-domains $settings)))

(= (codex:network-proxy-settings-denied-domains $settings)
   (codex:network-domain-permissions-denied-domains
     (codex:network-proxy-settings-domains $settings)))

(= (codex:network-proxy-settings-allow-unix-sockets $settings)
   (codex:network-unix-socket-permissions-allow-unix-sockets
     (codex:network-proxy-settings-unix-sockets $settings)))

(= (codex:network-proxy-settings-set-domains
      (CodexNetworkProxySettings
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
        $allow-local-binding
        $mitm)
      $next-domains)
   (CodexNetworkProxySettings
     $enabled
     $proxy-url
     $enable-socks5
     $socks-url
     $enable-socks5-udp
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $mode
     $next-domains
     $unix-sockets
     $allow-local-binding
     $mitm))

(= (codex:network-proxy-settings-set-allowed-domains
      $settings
      $allowed-domains)
   (codex:network-proxy-settings-set-domains
     $settings
     (codex:network-domain-permissions-set-domain-entries
       (codex:network-proxy-settings-domains $settings)
       $allowed-domains
       (codex:network-domain-permission-allow))))

(= (codex:network-proxy-settings-set-denied-domains
      $settings
      $denied-domains)
   (codex:network-proxy-settings-set-domains
     $settings
     (codex:network-domain-permissions-set-domain-entries
       (codex:network-proxy-settings-domains $settings)
       $denied-domains
       (codex:network-domain-permission-deny))))

(= (codex:network-proxy-settings-set-allow-unix-sockets
      (CodexNetworkProxySettings
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
        $allow-local-binding
        $mitm)
      $allow-unix-sockets)
   (CodexNetworkProxySettings
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
     (codex:network-unix-socket-permissions-set-entries
       $unix-sockets
       $allow-unix-sockets
       (codex:network-unix-socket-permission-allow))
     $allow-local-binding
     $mitm))

(= (codex:network-proxy-settings-upsert-domain-permission
      $settings
      $host
      $permission)
   (codex:network-proxy-settings-set-domains
     $settings
     (codex:network-domain-permissions-upsert-domain-permission
       (codex:network-proxy-settings-domains $settings)
       $host
       $permission)))

(= (codex:network-proxy-config-set-network
      (CodexNetworkProxyConfig $network)
      $next-network)
   (CodexNetworkProxyConfig $next-network))

(= (codex:network-proxy-config-set-allowed-domains
      $config
      $allowed-domains)
   (codex:network-proxy-config-set-network
     $config
     (codex:network-proxy-settings-set-allowed-domains
       (codex:network-proxy-config-network $config)
       $allowed-domains)))

(= (codex:network-proxy-config-set-denied-domains
      $config
      $denied-domains)
   (codex:network-proxy-config-set-network
     $config
     (codex:network-proxy-settings-set-denied-domains
       (codex:network-proxy-config-network $config)
       $denied-domains)))

(= (codex:network-proxy-config-upsert-domain-permission
      $config
      $host
      $permission)
   (codex:network-proxy-config-set-network
     $config
     (codex:network-proxy-settings-upsert-domain-permission
       (codex:network-proxy-config-network $config)
       $host
       $permission)))

(= (codex:network-proxy-config-set-allow-unix-sockets
      $config
      $allow-unix-sockets)
   (codex:network-proxy-config-set-network
     $config
     (codex:network-proxy-settings-set-allow-unix-sockets
       (codex:network-proxy-config-network $config)
       $allow-unix-sockets)))

(= (codex:network-proxy-config-allowed-domains $config)
   (codex:network-proxy-settings-allowed-domains
     (codex:network-proxy-config-network $config)))

(= (codex:network-proxy-config-denied-domains $config)
   (codex:network-proxy-settings-denied-domains
     (codex:network-proxy-config-network $config)))

(= (codex:network-proxy-config-allow-unix-sockets $config)
   (codex:network-proxy-settings-allow-unix-sockets
     (codex:network-proxy-config-network $config)))

(= (codex:network-proxy-config-set-enabled
      (CodexNetworkProxyConfig
        (CodexNetworkProxySettings
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
          $allow-local-binding
          $mitm))
      $next-enabled)
   (CodexNetworkProxyConfig
     (CodexNetworkProxySettings
       $next-enabled
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
       $allow-local-binding
       $mitm)))

(= (codex:network-proxy-config-set-proxy-url
      (CodexNetworkProxyConfig
        (CodexNetworkProxySettings
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
          $allow-local-binding
          $mitm))
      $next-proxy-url)
   (CodexNetworkProxyConfig
     (CodexNetworkProxySettings
       $enabled
       $next-proxy-url
       $enable-socks5
       $socks-url
       $enable-socks5-udp
       $allow-upstream-proxy
       $dangerously-allow-non-loopback-proxy
       $dangerously-allow-all-unix-sockets
       $mode
       $domains
       $unix-sockets
       $allow-local-binding
       $mitm)))

(= (codex:network-proxy-config-set-socks-url
      (CodexNetworkProxyConfig
        (CodexNetworkProxySettings
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
          $allow-local-binding
          $mitm))
      $next-socks-url)
   (CodexNetworkProxyConfig
     (CodexNetworkProxySettings
       $enabled
       $proxy-url
       $enable-socks5
       $next-socks-url
       $enable-socks5-udp
       $allow-upstream-proxy
       $dangerously-allow-non-loopback-proxy
       $dangerously-allow-all-unix-sockets
       $mode
       $domains
       $unix-sockets
       $allow-local-binding
       $mitm)))

(= (codex:network-proxy-config-set-allow-upstream-proxy
      (CodexNetworkProxyConfig
        (CodexNetworkProxySettings
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
          $allow-local-binding
          $mitm))
      $next-allow-upstream-proxy)
   (CodexNetworkProxyConfig
     (CodexNetworkProxySettings
       $enabled
       $proxy-url
       $enable-socks5
       $socks-url
       $enable-socks5-udp
       $next-allow-upstream-proxy
       $dangerously-allow-non-loopback-proxy
       $dangerously-allow-all-unix-sockets
       $mode
       $domains
       $unix-sockets
       $allow-local-binding
       $mitm)))

(= (codex:network-proxy-config-set-dangerously-allow-non-loopback-proxy
      (CodexNetworkProxyConfig
        (CodexNetworkProxySettings
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
          $allow-local-binding
          $mitm))
      $next-dangerously-allow-non-loopback-proxy)
   (CodexNetworkProxyConfig
     (CodexNetworkProxySettings
       $enabled
       $proxy-url
       $enable-socks5
       $socks-url
       $enable-socks5-udp
       $allow-upstream-proxy
       $next-dangerously-allow-non-loopback-proxy
       $dangerously-allow-all-unix-sockets
       $mode
       $domains
       $unix-sockets
       $allow-local-binding
       $mitm)))

(= (codex:network-proxy-config-set-dangerously-allow-all-unix-sockets
      (CodexNetworkProxyConfig
        (CodexNetworkProxySettings
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
          $allow-local-binding
          $mitm))
      $next-dangerously-allow-all-unix-sockets)
   (CodexNetworkProxyConfig
     (CodexNetworkProxySettings
       $enabled
       $proxy-url
       $enable-socks5
       $socks-url
       $enable-socks5-udp
       $allow-upstream-proxy
       $dangerously-allow-non-loopback-proxy
       $next-dangerously-allow-all-unix-sockets
       $mode
       $domains
       $unix-sockets
       $allow-local-binding
       $mitm)))

(= (codex:network-proxy-config-set-allow-local-binding
      (CodexNetworkProxyConfig
        (CodexNetworkProxySettings
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
          $allow-local-binding
          $mitm))
      $next-allow-local-binding)
   (CodexNetworkProxyConfig
     (CodexNetworkProxySettings
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
       $next-allow-local-binding
       $mitm)))

(= (codex:network-proxy-constraints
      $enabled
      $mode
      $allow-upstream-proxy
      $dangerously-allow-non-loopback-proxy
      $dangerously-allow-all-unix-sockets
      $allowed-domains
      $allowlist-expansion-enabled
      $denied-domains
      $denylist-expansion-enabled
      $allow-unix-sockets
      $allow-local-binding)
   (CodexNetworkProxyConstraints
     $enabled
     $mode
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $allowed-domains
     $allowlist-expansion-enabled
     $denied-domains
     $denylist-expansion-enabled
     $allow-unix-sockets
     $allow-local-binding))

(= (codex:network-proxy-constraints-default)
   (codex:network-proxy-constraints
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

(= (codex:network-proxy-constraints-allowed-domains
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding))
   $allowed-domains)

(= (codex:network-proxy-constraints-allowlist-expansion-enabled
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding))
   $allowlist-expansion-enabled)

(= (codex:network-proxy-constraints-denied-domains
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding))
   $denied-domains)

(= (codex:network-proxy-constraints-denylist-expansion-enabled
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding))
   $denylist-expansion-enabled)

(= (codex:network-proxy-constraints-allow-unix-sockets
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding))
   $allow-unix-sockets)

(= (codex:network-proxy-constraints-set-allowed-domains
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding)
      $next-allowed-domains
      $next-allowlist-expansion-enabled)
   (CodexNetworkProxyConstraints
     $enabled
     $mode
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $next-allowed-domains
     $next-allowlist-expansion-enabled
     $denied-domains
     $denylist-expansion-enabled
     $allow-unix-sockets
     $allow-local-binding))

(= (codex:network-proxy-constraints-set-denied-domains
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding)
      $next-denied-domains
      $next-denylist-expansion-enabled)
   (CodexNetworkProxyConstraints
     $enabled
     $mode
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $allowed-domains
     $allowlist-expansion-enabled
     $next-denied-domains
     $next-denylist-expansion-enabled
     $allow-unix-sockets
     $allow-local-binding))

(= (codex:network-proxy-constraints-set-enabled
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding)
      $next-enabled)
   (CodexNetworkProxyConstraints
     $next-enabled
     $mode
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $allowed-domains
     $allowlist-expansion-enabled
     $denied-domains
     $denylist-expansion-enabled
     $allow-unix-sockets
     $allow-local-binding))

(= (codex:network-proxy-constraints-set-allow-upstream-proxy
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding)
      $next-allow-upstream-proxy)
   (CodexNetworkProxyConstraints
     $enabled
     $mode
     $next-allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $allowed-domains
     $allowlist-expansion-enabled
     $denied-domains
     $denylist-expansion-enabled
     $allow-unix-sockets
     $allow-local-binding))

(= (codex:network-proxy-constraints-set-dangerously-allow-non-loopback-proxy
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding)
      $next-dangerously-allow-non-loopback-proxy)
   (CodexNetworkProxyConstraints
     $enabled
     $mode
     $allow-upstream-proxy
     $next-dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $allowed-domains
     $allowlist-expansion-enabled
     $denied-domains
     $denylist-expansion-enabled
     $allow-unix-sockets
     $allow-local-binding))

(= (codex:network-proxy-constraints-set-dangerously-allow-all-unix-sockets
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding)
      $next-dangerously-allow-all-unix-sockets)
   (CodexNetworkProxyConstraints
     $enabled
     $mode
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $next-dangerously-allow-all-unix-sockets
     $allowed-domains
     $allowlist-expansion-enabled
     $denied-domains
     $denylist-expansion-enabled
     $allow-unix-sockets
     $allow-local-binding))

(= (codex:network-proxy-constraints-set-allow-local-binding
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding)
      $next-allow-local-binding)
   (CodexNetworkProxyConstraints
     $enabled
     $mode
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $allowed-domains
     $allowlist-expansion-enabled
     $denied-domains
     $denylist-expansion-enabled
     $allow-unix-sockets
     $next-allow-local-binding))

(= (codex:network-proxy-constraints-set-allow-unix-sockets
      (CodexNetworkProxyConstraints
        $enabled
        $mode
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $allowed-domains
        $allowlist-expansion-enabled
        $denied-domains
        $denylist-expansion-enabled
        $allow-unix-sockets
        $allow-local-binding)
      $next-allow-unix-sockets)
   (CodexNetworkProxyConstraints
     $enabled
     $mode
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $allowed-domains
     $allowlist-expansion-enabled
     $denied-domains
     $denylist-expansion-enabled
     $next-allow-unix-sockets
     $allow-local-binding))

(= (codex:network-constraints
      $enabled
      $http-port
      $socks-port
      $allow-upstream-proxy
      $dangerously-allow-non-loopback-proxy
      $dangerously-allow-all-unix-sockets
      $domains
      $managed-allowed-domains-only
      $unix-sockets
      $allow-local-binding)
   (CodexNetworkConstraints
     $enabled
     $http-port
     $socks-port
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $domains
     $managed-allowed-domains-only
     $unix-sockets
     $allow-local-binding))

(= (codex:network-constraints-default)
   (codex:network-constraints
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

(= (codex:network-constraints-domains
      (CodexNetworkConstraints
        $enabled
        $http-port
        $socks-port
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $domains
        $managed-allowed-domains-only
        $unix-sockets
        $allow-local-binding))
   $domains)

(= (codex:network-constraints-managed-allowed-domains-only
      (CodexNetworkConstraints
        $enabled
        $http-port
        $socks-port
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $domains
        $managed-allowed-domains-only
        $unix-sockets
        $allow-local-binding))
   $managed-allowed-domains-only)

(= (codex:network-constraints-with-domains
      (CodexNetworkConstraints
        $enabled
        $http-port
        $socks-port
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $domains
        $managed-allowed-domains-only
        $unix-sockets
        $allow-local-binding)
      $next-domains)
   (CodexNetworkConstraints
     $enabled
     $http-port
     $socks-port
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $next-domains
     $managed-allowed-domains-only
     $unix-sockets
     $allow-local-binding))

(= (codex:network-constraints-with-managed-allowed-domains-only
      (CodexNetworkConstraints
        $enabled
        $http-port
        $socks-port
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $domains
        $managed-allowed-domains-only
        $unix-sockets
        $allow-local-binding)
      $next-managed-allowed-domains-only)
   (CodexNetworkConstraints
     $enabled
     $http-port
     $socks-port
     $allow-upstream-proxy
     $dangerously-allow-non-loopback-proxy
     $dangerously-allow-all-unix-sockets
     $domains
     $next-managed-allowed-domains-only
     $unix-sockets
     $allow-local-binding))

(= (codex:network-proxy-spec
      $base-config
      $requirements
      $config
      $constraints
      $hard-deny-allowlist-misses)
   (CodexNetworkProxySpec
     $base-config
     $requirements
     $config
     $constraints
     $hard-deny-allowlist-misses))

(= (codex:network-proxy-spec-config
      (CodexNetworkProxySpec
        $base-config
        $requirements
        $config
        $constraints
        $hard-deny-allowlist-misses))
   $config)

(= (codex:network-proxy-spec-constraints
      (CodexNetworkProxySpec
        $base-config
        $requirements
        $config
        $constraints
        $hard-deny-allowlist-misses))
   $constraints)

(= (codex:network-proxy-spec-hard-deny-allowlist-misses
      (CodexNetworkProxySpec
        $base-config
        $requirements
        $config
        $constraints
        $hard-deny-allowlist-misses))
   $hard-deny-allowlist-misses)

(= (codex:network-proxy-spec-result-ok $spec)
   (CodexNetworkProxySpecResultOk $spec))

(= (codex:network-proxy-spec-result-error $message)
   (CodexNetworkProxySpecResultError $message))

(= (codex:network-proxy-spec-result-value
      (CodexNetworkProxySpecResultOk $spec))
   $spec)

(= (codex:network-proxy-spec-enabled $spec)
   (codex:network-proxy-settings-enabled
     (codex:network-proxy-config-network
       (codex:network-proxy-spec-config $spec))))

(= (codex:network-proxy-spec-socks-enabled $spec)
   (codex:network-proxy-settings-enable-socks5
     (codex:network-proxy-config-network
       (codex:network-proxy-spec-config $spec))))

(= (codex:network-proxy-host-and-port-from-network-addr
      $addr
      $default-port)
   (let $without-scheme
     (if (str-starts-with? $addr "http://")
         (str-slice $addr 7 (str-length $addr))
         $addr)
     (let $host-and-rest (list:first (str-split "/" $without-scheme))
       (let $parts (str-split ":" $host-and-rest)
         (if (== (list:len $parts) 1)
             (str-concat
               $host-and-rest
               (format-args ":{}" ($default-port)))
             $host-and-rest)))))

(= (codex:network-proxy-spec-proxy-host-and-port $spec)
   (codex:network-proxy-host-and-port-from-network-addr
     (codex:network-proxy-settings-proxy-url
       (codex:network-proxy-config-network
         (codex:network-proxy-spec-config $spec)))
     3128))

(= (codex:network-proxy-spec-managed-allowed-domains-only
      $requirements)
   (if (== $requirements CodexAbsent)
       False
       (let $managed
         (codex:network-constraints-managed-allowed-domains-only
           $requirements)
         (if (== $managed CodexAbsent)
             False
             $managed))))

(= (codex:network-proxy-spec-allowlist-expansion-enabled
      $sandbox-policy
      $hard-deny-allowlist-misses)
   (case $sandbox-policy
     (((CodexSessionSandboxPolicyReadOnly $access $network-access)
       (not $hard-deny-allowlist-misses))
      ((CodexSessionSandboxPolicyWorkspaceWrite
         $writable-roots
         $network-access
         $exclude-tmpdir-env-var
         $exclude-slash-tmp)
       (not $hard-deny-allowlist-misses))
      ($other False))))

(= (codex:network-proxy-spec-denylist-expansion-enabled
      $sandbox-policy)
   (case $sandbox-policy
     (((CodexSessionSandboxPolicyReadOnly $access $network-access)
       True)
      ((CodexSessionSandboxPolicyWorkspaceWrite
         $writable-roots
         $network-access
         $exclude-tmpdir-env-var
         $exclude-slash-tmp)
       True)
      ($other False))))

(= (codex:network-proxy-domain-list-contains-ignore-case
      $entries
      $entry)
   (if (== $entries ())
       False
       (let ($head $tail) (decons-atom $entries)
         (if (codex:network-proxy-eq-ignore-ascii-case $head $entry)
             True
             (codex:network-proxy-domain-list-contains-ignore-case
               $tail
               $entry)))))

(= (codex:network-proxy-merge-domain-lists
      $managed
      $user-entries)
   (if (== $user-entries ())
       $managed
       (let ($head $tail) (decons-atom $user-entries)
         (let $next
           (if (codex:network-proxy-domain-list-contains-ignore-case
                 $managed
                 $head)
               $managed
               (list:push $managed $head))
           (codex:network-proxy-merge-domain-lists
             $next
             $tail)))))

(= (codex:network-proxy-optional-list-or-empty $entries)
   (if (== $entries CodexAbsent)
       ()
       $entries))

(= (codex:network-proxy-optional-list-from-empty $entries)
   (if (== $entries ())
       CodexAbsent
       $entries))

(= (codex:network-proxy-apply-managed-allowed-domains
      $config
      $constraints
      $managed-allowed-domains
      $allowlist-expansion-enabled)
   (let $effective-allowed-domains
     (if $allowlist-expansion-enabled
         (codex:network-proxy-merge-domain-lists
           $managed-allowed-domains
           (codex:network-proxy-optional-list-or-empty
             (codex:network-proxy-config-allowed-domains $config)))
         $managed-allowed-domains)
     (CodexNetworkProxySpecApplyPair
       (codex:network-proxy-config-set-allowed-domains
         $config
         $effective-allowed-domains)
       (codex:network-proxy-constraints-set-allowed-domains
         $constraints
         $managed-allowed-domains
         $allowlist-expansion-enabled))))

(= (codex:network-proxy-apply-managed-denied-domains
      $config
      $constraints
      $managed-denied-domains
      $denylist-expansion-enabled)
   (let $effective-denied-domains
     (if $denylist-expansion-enabled
         (codex:network-proxy-merge-domain-lists
           $managed-denied-domains
           (codex:network-proxy-optional-list-or-empty
             (codex:network-proxy-config-denied-domains $config)))
         $managed-denied-domains)
     (CodexNetworkProxySpecApplyPair
       (codex:network-proxy-config-set-denied-domains
         $config
         $effective-denied-domains)
       (codex:network-proxy-constraints-set-denied-domains
         $constraints
         $managed-denied-domains
         $denylist-expansion-enabled))))

(= (codex:network-proxy-spec-apply-pair-config
      (CodexNetworkProxySpecApplyPair $config $constraints))
   $config)

(= (codex:network-proxy-spec-apply-pair-constraints
      (CodexNetworkProxySpecApplyPair $config $constraints))
   $constraints)

(= (codex:network-proxy-apply-scalar-requirements
      $config
      $constraints
      (CodexNetworkConstraints
        $enabled
        $http-port
        $socks-port
        $allow-upstream-proxy
        $dangerously-allow-non-loopback-proxy
        $dangerously-allow-all-unix-sockets
        $domains
        $managed-allowed-domains-only
        $unix-sockets
        $allow-local-binding))
   (let $config-1
     (if (== $enabled CodexAbsent)
         $config
         (codex:network-proxy-config-set-enabled $config $enabled))
     (let $constraints-1
       (if (== $enabled CodexAbsent)
           $constraints
           (codex:network-proxy-constraints-set-enabled
             $constraints
             $enabled))
       (let $config-2
         (if (== $http-port CodexAbsent)
             $config-1
             (codex:network-proxy-config-set-proxy-url
               $config-1
               (format-args "http://127.0.0.1:{}" ($http-port))))
         (let $config-3
           (if (== $socks-port CodexAbsent)
               $config-2
               (codex:network-proxy-config-set-socks-url
                 $config-2
                 (format-args "http://127.0.0.1:{}" ($socks-port))))
           (let $config-4
             (if (== $allow-upstream-proxy CodexAbsent)
                 $config-3
                 (codex:network-proxy-config-set-allow-upstream-proxy
                   $config-3
                   $allow-upstream-proxy))
             (let $constraints-4
               (if (== $allow-upstream-proxy CodexAbsent)
                   $constraints-1
                   (codex:network-proxy-constraints-set-allow-upstream-proxy
                     $constraints-1
                     $allow-upstream-proxy))
               (let $config-5
                 (if (== $dangerously-allow-non-loopback-proxy CodexAbsent)
                     $config-4
                     (codex:network-proxy-config-set-dangerously-allow-non-loopback-proxy
                       $config-4
                       $dangerously-allow-non-loopback-proxy))
                 (let $constraints-5
                   (if (== $dangerously-allow-non-loopback-proxy CodexAbsent)
                       $constraints-4
                       (codex:network-proxy-constraints-set-dangerously-allow-non-loopback-proxy
                         $constraints-4
                         $dangerously-allow-non-loopback-proxy))
                   (let $config-6
                     (if (== $dangerously-allow-all-unix-sockets CodexAbsent)
                         $config-5
                         (codex:network-proxy-config-set-dangerously-allow-all-unix-sockets
                           $config-5
                           $dangerously-allow-all-unix-sockets))
                     (let $constraints-6
                       (if (== $dangerously-allow-all-unix-sockets CodexAbsent)
                           $constraints-5
                           (codex:network-proxy-constraints-set-dangerously-allow-all-unix-sockets
                             $constraints-5
                             $dangerously-allow-all-unix-sockets))
                       (let $allow-unix-sockets
                         (if (== $unix-sockets CodexAbsent)
                             CodexAbsent
                             (codex:network-unix-socket-permissions-allow-unix-sockets
                               $unix-sockets))
                         (let $config-7
                           (if (== $allow-unix-sockets CodexAbsent)
                               $config-6
                               (codex:network-proxy-config-set-allow-unix-sockets
                                 $config-6
                                 $allow-unix-sockets))
                           (let $constraints-7
                             (if (== $allow-unix-sockets CodexAbsent)
                                 $constraints-6
                                 (codex:network-proxy-constraints-set-allow-unix-sockets
                                   $constraints-6
                                   $allow-unix-sockets))
                             (let $config-8
                               (if (== $allow-local-binding CodexAbsent)
                                   $config-7
                                   (codex:network-proxy-config-set-allow-local-binding
                                     $config-7
                                     $allow-local-binding))
                               (let $constraints-8
                                 (if (== $allow-local-binding CodexAbsent)
                                     $constraints-7
                                     (codex:network-proxy-constraints-set-allow-local-binding
                                       $constraints-7
                                       $allow-local-binding))
                                 (CodexNetworkProxySpecApplyPair
                                   $config-8
                                   $constraints-8)))))))))))))))))

(= (codex:network-proxy-apply-requirements
      $config
      $requirements
      $sandbox-policy
      $hard-deny-allowlist-misses)
   (let $scalar-pair
     (codex:network-proxy-apply-scalar-requirements
       $config
       (codex:network-proxy-constraints-default)
       $requirements)
     (let $config-1
       (codex:network-proxy-spec-apply-pair-config $scalar-pair)
       (let $constraints-1
         (codex:network-proxy-spec-apply-pair-constraints $scalar-pair)
         (let $allowlist-expansion-enabled
           (codex:network-proxy-spec-allowlist-expansion-enabled
             $sandbox-policy
             $hard-deny-allowlist-misses)
           (let $denylist-expansion-enabled
             (codex:network-proxy-spec-denylist-expansion-enabled
               $sandbox-policy)
             (let $managed-allowed-domains-raw
               (if $hard-deny-allowlist-misses
                   (codex:network-proxy-optional-list-or-empty
                     (codex:network-domain-permissions-allowed-domains
                       (codex:network-constraints-domains $requirements)))
                   (codex:network-domain-permissions-allowed-domains
                     (codex:network-constraints-domains $requirements)))
               (let $allowed-pair
                 (if (== $managed-allowed-domains-raw CodexAbsent)
                     (CodexNetworkProxySpecApplyPair
                       $config-1
                       $constraints-1)
                     (codex:network-proxy-apply-managed-allowed-domains
                       $config-1
                       $constraints-1
                       $managed-allowed-domains-raw
                       $allowlist-expansion-enabled))
                 (let $config-2
                   (codex:network-proxy-spec-apply-pair-config
                     $allowed-pair)
                   (let $constraints-2
                     (codex:network-proxy-spec-apply-pair-constraints
                       $allowed-pair)
                     (let $managed-denied-domains
                       (codex:network-domain-permissions-denied-domains
                         (codex:network-constraints-domains $requirements))
                       (if (== $managed-denied-domains CodexAbsent)
                           (CodexNetworkProxySpecApplyPair
                             $config-2
                             $constraints-2)
                           (codex:network-proxy-apply-managed-denied-domains
                             $config-2
                             $constraints-2
                             $managed-denied-domains
                             $denylist-expansion-enabled)))))))))))))

(= (codex:network-proxy-validation-ok)
   (CodexNetworkProxyValidationOk))

(= (codex:network-proxy-validation-error $message)
   (CodexNetworkProxyValidationError $message))

(= (codex:network-proxy-list-subset-ignore-case
      $candidate
      $allowed)
   (if (== $candidate ())
       True
       (let ($head $tail) (decons-atom $candidate)
         (if (codex:network-proxy-domain-list-contains-ignore-case
               $allowed
               $head)
             (codex:network-proxy-list-subset-ignore-case
               $tail
               $allowed)
             False))))

(= (codex:network-proxy-list-eq-ignore-case-as-set
      $left
      $right)
   (and
     (codex:network-proxy-list-subset-ignore-case $left $right)
     (codex:network-proxy-list-subset-ignore-case $right $left)))

(= (codex:network-proxy-remove-denied-overrides
      $required
      $denied-domains)
   (if (== $required ())
       ()
       (let ($head $tail) (decons-atom $required)
         (let $rest
           (codex:network-proxy-remove-denied-overrides
             $tail
             $denied-domains)
           (if (codex:network-proxy-domain-list-contains-ignore-case
                 $denied-domains
                 $head)
               $rest
               (cons-atom $head $rest))))))

(= (codex:network-proxy-validate-allowed-domains
      $required
      $allowlist-expansion-enabled
      $config-allowed-domains
      $config-denied-domains)
   (case ($required $allowlist-expansion-enabled)
     (((CodexAbsent $any)
       (codex:network-proxy-validation-ok))
      (($managed True)
       (let $candidate
         (codex:network-proxy-optional-list-or-empty $config-allowed-domains)
         (let $allowed-or-denied
           (codex:network-proxy-merge-domain-lists
             $candidate
             (codex:network-proxy-optional-list-or-empty
               $config-denied-domains))
           (if (codex:network-proxy-list-subset-ignore-case
                 $managed
                 $allowed-or-denied)
               (codex:network-proxy-validation-ok)
               (codex:network-proxy-validation-error
                 "missing managed allowed_domains entries")))))
      (($managed False)
       (let $expected
         (codex:network-proxy-remove-denied-overrides
           $managed
           (codex:network-proxy-optional-list-or-empty
             $config-denied-domains))
         (let $candidate
           (codex:network-proxy-optional-list-or-empty $config-allowed-domains)
           (if (codex:network-proxy-list-eq-ignore-case-as-set
                 $candidate
                 $expected)
               (codex:network-proxy-validation-ok)
               (codex:network-proxy-validation-error
                 "must match managed allowed_domains")))))
      (($managed CodexAbsent)
       (if (codex:network-proxy-list-subset-ignore-case
             (codex:network-proxy-optional-list-or-empty $config-allowed-domains)
             $managed)
           (codex:network-proxy-validation-ok)
           (codex:network-proxy-validation-error
             "subset of managed allowed_domains"))))))

(= (codex:network-proxy-validate-denied-domains
      $required
      $denylist-expansion-enabled
      $config-denied-domains)
   (case ($required $denylist-expansion-enabled)
     (((CodexAbsent $any)
       (codex:network-proxy-validation-ok))
      (($managed False)
       (let $candidate
         (codex:network-proxy-optional-list-or-empty $config-denied-domains)
         (if (codex:network-proxy-list-eq-ignore-case-as-set
               $candidate
               $managed)
             (codex:network-proxy-validation-ok)
             (codex:network-proxy-validation-error
               "must match managed denied_domains"))))
      (($managed $other)
       (let $candidate
         (codex:network-proxy-optional-list-or-empty $config-denied-domains)
         (if (codex:network-proxy-list-subset-ignore-case
               $managed
               $candidate)
             (codex:network-proxy-validation-ok)
             (codex:network-proxy-validation-error
               "missing managed denied_domains entries")))))))

(= (codex:network-proxy-validate-policy-against-constraints
      $config
      $constraints)
   (let $allowed-validation
     (codex:network-proxy-validate-allowed-domains
       (codex:network-proxy-constraints-allowed-domains
         $constraints)
       (codex:network-proxy-constraints-allowlist-expansion-enabled
         $constraints)
       (codex:network-proxy-config-allowed-domains $config)
       (codex:network-proxy-config-denied-domains $config))
     (case $allowed-validation
       (((CodexNetworkProxyValidationError $message)
         $allowed-validation)
        ((CodexNetworkProxyValidationOk)
         (codex:network-proxy-validate-denied-domains
           (codex:network-proxy-constraints-denied-domains
             $constraints)
           (codex:network-proxy-constraints-denylist-expansion-enabled
             $constraints)
           (codex:network-proxy-config-denied-domains $config)))))))

(= (codex:network-proxy-spec-from-config-and-constraints
      $config
      CodexAbsent
      $sandbox-policy)
   (codex:network-proxy-spec-result-ok
     (codex:network-proxy-spec
       $config
       CodexAbsent
       $config
       (codex:network-proxy-constraints-default)
       False)))

(= (codex:network-proxy-spec-from-config-and-constraints
      $config
      $requirements
      $sandbox-policy)
   (let $base-config $config
     (let $hard-deny-allowlist-misses
       (codex:network-proxy-spec-managed-allowed-domains-only
         $requirements)
       (let $applied
         (codex:network-proxy-apply-requirements
           $config
           $requirements
           $sandbox-policy
           $hard-deny-allowlist-misses)
         (let $next-config
           (codex:network-proxy-spec-apply-pair-config $applied)
           (let $constraints
             (codex:network-proxy-spec-apply-pair-constraints
               $applied)
             (case
               (codex:network-proxy-validate-policy-against-constraints
                 $next-config
                 $constraints)
               (((CodexNetworkProxyValidationOk)
                 (codex:network-proxy-spec-result-ok
                   (codex:network-proxy-spec
                     $base-config
                     $requirements
                     $next-config
                     $constraints
                     $hard-deny-allowlist-misses)))
                ((CodexNetworkProxyValidationError $message)
                 (codex:network-proxy-spec-result-error
                   (str-concat
                     "network proxy constraints are invalid: "
                     $message)))))))))))

(= (codex:network-proxy-audit-metadata
      $conversation-id
      $app-version
      $user-account-id)
   (CodexNetworkProxyAuditMetadata
     $conversation-id
     $app-version
     $user-account-id))

(= (codex:network-proxy-audit-metadata-default)
   (codex:network-proxy-audit-metadata
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:network-proxy-config-state
      $config
      $constraints)
   (CodexNetworkProxyConfigState $config $constraints))

(= (codex:network-proxy-state
      $config-state
      $audit-metadata)
   (CodexNetworkProxyState $config-state $audit-metadata))

(= (codex:network-proxy-state-audit-metadata
      (CodexNetworkProxyState $config-state $audit-metadata))
   $audit-metadata)

(= (codex:network-proxy-spec-build-config-state-for-spec
      $spec)
   (codex:network-proxy-config-state
     (codex:network-proxy-spec-config $spec)
     (codex:network-proxy-spec-constraints $spec)))

(= (codex:network-proxy-spec-build-state-with-audit-metadata
      $spec
      $audit-metadata)
   (codex:network-proxy-state
     (codex:network-proxy-spec-build-config-state-for-spec $spec)
     $audit-metadata))

(= (codex:network-proxy-fallback-ask-decider)
   (CodexNetworkProxyFallbackAskDecider "not_allowed"))

(= (codex:network-proxy-spec-should-install-fallback-decider
      $sandbox-policy)
   (case $sandbox-policy
     (((CodexSessionSandboxPolicyReadOnly $access $network-access)
       True)
      ((CodexSessionSandboxPolicyWorkspaceWrite
         $writable-roots
         $network-access
         $exclude-tmpdir-env-var
         $exclude-slash-tmp)
       True)
      ($other False))))

(= (codex:network-proxy-spec-selected-policy-decider
      $spec
      $sandbox-policy
      $policy-decider
      $enable-network-approval-flow)
   (if (and
         $enable-network-approval-flow
         (not
           (codex:network-proxy-spec-hard-deny-allowlist-misses
             $spec)))
       (if (== $policy-decider CodexAbsent)
           (if (codex:network-proxy-spec-should-install-fallback-decider
                 $sandbox-policy)
               (codex:network-proxy-fallback-ask-decider)
               CodexAbsent)
           $policy-decider)
       CodexAbsent))

(= (codex:network-proxy-start-plan
      $state
      $policy-decider
      $blocked-request-observer)
   (CodexNetworkProxyStartPlan
     $state
     $policy-decider
     $blocked-request-observer))

(= (codex:network-proxy-start-plan-policy-decider
      (CodexNetworkProxyStartPlan
        $state
        $policy-decider
        $blocked-request-observer))
   $policy-decider)

(= (codex:network-proxy-start-plan-blocked-request-observer
      (CodexNetworkProxyStartPlan
        $state
        $policy-decider
        $blocked-request-observer))
   $blocked-request-observer)

(= (codex:network-proxy-start-plan-state
      (CodexNetworkProxyStartPlan
        $state
        $policy-decider
        $blocked-request-observer))
   $state)

(= (codex:network-proxy-spec-start-proxy-plan
      $spec
      $sandbox-policy
      $policy-decider
      $blocked-request-observer
      $enable-network-approval-flow
      $audit-metadata)
   (codex:network-proxy-start-plan
     (codex:network-proxy-spec-build-state-with-audit-metadata
       $spec
       $audit-metadata)
     (codex:network-proxy-spec-selected-policy-decider
       $spec
       $sandbox-policy
       $policy-decider
       $enable-network-approval-flow)
     $blocked-request-observer))
