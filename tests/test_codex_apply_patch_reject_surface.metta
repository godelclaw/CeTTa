!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:apply_patch)

(= (codex-apply-test-cwd) "/home/zarclaw/repos/CeTTa")

!(assertEqualToResult
  (let $parsed
       (codex:maybe-parse-apply-patch-input
         (codex-apply-test-cwd)
         "*** Begin Patch\n*** Add File: runtime/codex-apply-reject.txt\n+outside-policy\n*** End Patch")
    (json-stringify
      (codex:internal-apply-patch-invocation-json
        (codex:apply-patch
          (codex:ask-for-approval-granular False)
          (codex:patch-sandbox-workspace-write)
          (codex:patch-fs-policy ("/tmp") () ())
          (codex:maybe-apply-patch-patch-text $parsed)
          (codex:maybe-apply-patch-action $parsed)
          False))))
  ("{\"type\":\"output\",\"text\":\"patch rejected: writing outside of the project; rejected by user approval settings\"}"))
