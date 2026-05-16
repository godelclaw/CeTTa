!(register-module! ../codex)
!(import! &self codex:permissions)
!(import! &self codex:permissions_legacy_bridge)
!(import! &self codex:protocol)
!(import! &self process)

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/workspace /home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/extra /home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/tmpdir"))
  (0))

!(assertEqualToResult
  (once
    (json-stringify
      (codex:session-sandbox-policy-json
        (once
          (codex:file-system-sandbox-policy-to-legacy-result-policy
            (once
              (codex:file-system-sandbox-policy-to-legacy-sandbox-policy
                (codex:file-system-sandbox-policy-external-sandbox)
                (codex:network-sandbox-policy-enabled)
                "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/workspace")))))))
  ("{\"type\":\"external-sandbox\",\"network_access\":\"enabled\"}"))

!(assertEqualToResult
  (once
    (json-stringify
      (codex:session-sandbox-policy-json
        (once
          (codex:file-system-sandbox-policy-to-legacy-result-policy
            (once
              (codex:file-system-sandbox-policy-to-legacy-sandbox-policy
                (codex:file-system-sandbox-policy-unrestricted)
                (codex:network-sandbox-policy-restricted)
                "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/workspace")))))))
  ("{\"type\":\"external-sandbox\",\"network_access\":\"restricted\"}"))

!(assertEqualToResult
  (codex:file-system-sandbox-policy-to-legacy-collect-state
    ((codex:file-system-sandbox-entry
       (codex:file-system-path-special
         (codex:file-system-special-path-unknown
           ":future_special_path"
           CodexAbsent))
       (codex:file-system-access-write)))
    "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/workspace"
    False
    False
    False
    ()
    ()
    False
    False
    False)
  ((CodexFileSystemSandboxPolicyLegacyCollectState
     False
     False
     ()
     ()
     False
     False
     False)))

!(assertEqualToResult
  (codex:file-system-sandbox-policy-to-legacy-collect-state
    ((codex:file-system-sandbox-entry
       (codex:file-system-path-special
         (codex:file-system-special-path-minimal))
       (codex:file-system-access-read))
     (codex:file-system-sandbox-entry
       (codex:file-system-path-special
         (codex:file-system-special-path-current-working-directory))
       (codex:file-system-access-write))
     (codex:file-system-sandbox-entry
       (codex:file-system-path-special
         (codex:file-system-special-path-tmpdir))
       (codex:file-system-access-write))
     (codex:file-system-sandbox-entry
       (codex:file-system-path-path
         "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/extra")
       (codex:file-system-access-write)))
    "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/workspace"
    False
    False
    False
    ()
    ()
    False
    False
    False)
  ((CodexFileSystemSandboxPolicyLegacyCollectState
     True
     True
     ("/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/extra")
     ()
     True
     False
     False)))

!(assertEqualToResult
  (codex:file-system-sandbox-policy-to-legacy-collect-state
    ((codex:file-system-sandbox-entry
       (codex:file-system-path-special
         (codex:file-system-special-path-root))
       (codex:file-system-access-write))
     (codex:file-system-sandbox-entry
       (codex:file-system-path-path
         "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/workspace/docs")
       (codex:file-system-access-read)))
    "/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/workspace"
    False
    False
    False
    ()
    ()
    False
    False
    False)
  ((CodexFileSystemSandboxPolicyLegacyCollectState
     False
     False
     ()
     ("/home/zarclaw/repos/CeTTa/runtime/codex-permissions-legacy/workspace/docs")
     False
     False
     True)))

!(assertEqualToResult
  (codex:file-system-sandbox-policy-to-legacy-error-message)
  ("permissions profile requests filesystem writes outside the workspace root, which is not supported until the runtime enforces FileSystemSandboxPolicy directly"))
