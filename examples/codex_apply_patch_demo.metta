!(register-module! ../codex)
!(import! &self fs)
!(import! &self json)
!(import! &self codex:apply_patch)
!(import! &self codex:protocol)
!(import! &self codex:tools)

(= (codex-apply-demo-cwd) "/home/zarclaw/repos/CeTTa")

!(println! "=== Codex apply_patch demo ===")

!(let $parsed
    (codex:maybe-parse-apply-patch-input
      (codex-apply-demo-cwd)
      "*** Begin Patch\n*** Add File: runtime/codex-apply-demo-struct.txt\n+demo\n*** End Patch")
  (println!
    (json-stringify
      (codex:internal-apply-patch-invocation-json
        (codex:apply-patch
          (codex:ask-for-approval-on-request)
          (codex:patch-sandbox-danger-full-access)
          (codex:patch-fs-policy-unrestricted)
          (codex:maybe-apply-patch-patch-text $parsed)
          (codex:maybe-apply-patch-action $parsed)
          False)))))

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-demo-direct.txt" "before\n")

!(let $item
    (codex:run-tool-call-item
      (codex:tool-call
        "call_demo_apply"
        "apply_patch"
        "*** Begin Patch\n*** Update File: runtime/codex-apply-demo-direct.txt\n@@\n-before\n+after\n*** End Patch"))
  (println! (json-stringify (codex:item-json $item))))

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-apply-demo-shell.txt" "shell-before\n")

!(let $item
    (codex:run-tool-call-item
      (codex:tool-call
        "call_demo_shell"
        "exec_command"
        "{\"cmd\":\"cd runtime && apply_patch <<'PATCH'\\n*** Begin Patch\\n*** Update File: codex-apply-demo-shell.txt\\n@@\\n-shell-before\\n+shell-after\\n*** End Patch\\nPATCH\",\"login\":false,\"yield_time_ms\":1000}"))
  (println! (json-stringify (codex:item-json $item))))
