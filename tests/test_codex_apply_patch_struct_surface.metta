!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:apply_patch)

(= (codex-apply-test-cwd) "/home/zarclaw/repos/CeTTa")

!(assertEqualToResult
  (let $parsed
       (codex:maybe-parse-apply-patch-input
         (codex-apply-test-cwd)
         "*** Begin Patch\n*** Add File: runtime/codex-apply-struct.txt\n+hello\n*** End Patch")
    (json-stringify
      (codex:internal-apply-patch-invocation-json
        (codex:apply-patch
          (codex:ask-for-approval-on-request)
          (codex:patch-sandbox-danger-full-access)
          (codex:patch-fs-policy-unrestricted)
          (codex:maybe-apply-patch-patch-text $parsed)
          (codex:maybe-apply-patch-action $parsed)
          False))))
  ("{\"type\":\"delegate_to_runtime\",\"runtime\":{\"auto_approved\":true,\"exec_approval_requirement\":{\"type\":\"skip\",\"bypass_sandbox\":false,\"proposed_execpolicy_amendment\":null}}}"))
