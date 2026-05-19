!(register-module! ../codex)
!(import! &self codex:sandbox_manager)

(= (sandbox-manager)
   (codex:sandbox-manager-new))

(= (full-write-policy)
   (codex:file-system-sandbox-policy-restricted
     ((codex:file-system-sandbox-entry
        (codex:file-system-path-special
          (codex:file-system-special-path-root))
        (codex:file-system-access-write)))))

!(assertEqual
  (codex:should-require-platform-sandbox
    (codex:file-system-sandbox-policy-default)
    (codex:network-sandbox-policy-enabled)
    False)
  True)

!(assertEqual
  (codex:should-require-platform-sandbox
    (full-write-policy)
    (codex:network-sandbox-policy-enabled)
    False)
  False)

!(assertEqual
  (codex:should-require-platform-sandbox
    (codex:file-system-sandbox-policy-external-sandbox)
    (codex:network-sandbox-policy-restricted)
    False)
  False)

!(assertEqual
  (codex:should-require-platform-sandbox
    (codex:file-system-sandbox-policy-unrestricted)
    (codex:network-sandbox-policy-enabled)
    True)
  True)

!(assertEqual
  (codex:sandbox-manager-select-initial
    (sandbox-manager)
    (codex:file-system-sandbox-policy-default)
    (codex:network-sandbox-policy-enabled)
    (codex:sandboxable-preference-forbid)
    (codex:windows-sandbox-level-disabled)
    True
    (codex:host-platform-linux))
  (codex:sandbox-type-none))

!(assertEqual
  (codex:sandbox-manager-select-initial
    (sandbox-manager)
    (codex:file-system-sandbox-policy-unrestricted)
    (codex:network-sandbox-policy-enabled)
    (codex:sandboxable-preference-require)
    (codex:windows-sandbox-level-disabled)
    False
    (codex:host-platform-linux))
  (codex:sandbox-type-linux-seccomp))

!(assertEqual
  (codex:sandbox-manager-select-initial
    (sandbox-manager)
    (codex:file-system-sandbox-policy-unrestricted)
    (codex:network-sandbox-policy-enabled)
    (codex:sandboxable-preference-auto)
    (codex:windows-sandbox-level-disabled)
    False
    (codex:host-platform-linux))
  (codex:sandbox-type-none))

!(assertEqual
  (codex:sandbox-manager-select-initial
    (sandbox-manager)
    (codex:file-system-sandbox-policy-default)
    (codex:network-sandbox-policy-restricted)
    (codex:sandboxable-preference-auto)
    (codex:windows-sandbox-level-disabled)
    False
    (codex:host-platform-linux))
  (codex:sandbox-type-linux-seccomp))

!(assertEqual
  (codex:sandbox-manager-select-initial
    (sandbox-manager)
    (codex:file-system-sandbox-policy-default)
    (codex:network-sandbox-policy-restricted)
    (codex:sandboxable-preference-require)
    (codex:windows-sandbox-level-disabled)
    False
    (codex:host-platform-windows))
  (codex:sandbox-type-none))

!(assertEqual
  (codex:sandbox-manager-select-initial
    (sandbox-manager)
    (codex:file-system-sandbox-policy-default)
    (codex:network-sandbox-policy-restricted)
    (codex:sandboxable-preference-require)
    (codex:windows-sandbox-level-restricted-token)
    False
    (codex:host-platform-windows))
  (codex:sandbox-type-windows-restricted-token))
