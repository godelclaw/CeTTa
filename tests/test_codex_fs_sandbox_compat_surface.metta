!(register-module! ../codex)
!(import! &self codex:fs_sandbox_compat)
!(import! &self codex:permissions)

!(assertEqual
  (codex:fs-sandbox-compat-policy-get-writable-roots-with-cwd
    (codex:file-system-sandbox-policy-restricted
      ((codex:file-system-sandbox-entry
         (codex:file-system-path-special
           (codex:file-system-special-path-root))
         (codex:file-system-access-write))
       (codex:file-system-sandbox-entry
         (codex:file-system-path-path "/workspace/docs")
         (codex:file-system-access-read))))
    "/workspace")
  ((CodexWritableRoot "/" ("/workspace/docs"))))

!(assertEqual
  (codex:fs-sandbox-compatibility-workspace-write-policy
    (codex:file-system-sandbox-policy-restricted
      ((codex:file-system-sandbox-entry
         (codex:file-system-path-special
           (codex:file-system-special-path-root))
         (codex:file-system-access-read))
       (codex:file-system-sandbox-entry
         (codex:file-system-path-special
           (codex:file-system-special-path-current-working-directory))
         (codex:file-system-access-write))))
    "/workspace")
  (CodexSessionSandboxPolicyWorkspaceWrite
    ()
    (CodexSessionReadOnlyAccessFull)
    False
    True
    True))

!(assertEqual
  (codex:fs-sandbox-compatibility-workspace-write-policy
    (codex:file-system-sandbox-policy-restricted
      ((codex:file-system-sandbox-entry
         (codex:file-system-path-special
           (codex:file-system-special-path-minimal))
         (codex:file-system-access-read))
       (codex:file-system-sandbox-entry
         (codex:file-system-path-special
           (codex:file-system-special-path-current-working-directory))
         (codex:file-system-access-write))
       (codex:file-system-sandbox-entry
         (codex:file-system-path-path "/opt/codex")
         (codex:file-system-access-read))))
    "/workspace")
  (CodexSessionSandboxPolicyWorkspaceWrite
    ()
    (CodexSessionReadOnlyAccessRestricted
      True
      ("/workspace" "/opt/codex"))
    False
    True
    True))

!(assertEqual
  (codex:fs-sandbox-compatibility-sandbox-policy
    (codex:file-system-sandbox-policy-unrestricted)
    (codex:network-sandbox-policy-restricted)
    "/workspace")
  (CodexSessionSandboxPolicyExternalSandbox
    (CodexSessionNetworkAccessRestricted)))

!(assertEqual
  (codex:fs-sandbox-compatibility-sandbox-policy
    (codex:file-system-sandbox-policy-restricted
      ((codex:file-system-sandbox-entry
         (codex:file-system-path-special
           (codex:file-system-special-path-root))
         (codex:file-system-access-write))
       (codex:file-system-sandbox-entry
         (codex:file-system-path-path "/workspace/docs")
         (codex:file-system-access-read))))
    (codex:network-sandbox-policy-enabled)
    "/workspace")
  (CodexSessionSandboxPolicyWorkspaceWrite
    ("/")
    (CodexSessionReadOnlyAccessFull)
    False
    True
    True))
