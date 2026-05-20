; Pure codex-mcp helper slice for the Codex port.
;
; Ports deterministic behavior from:
; - openai-codex/codex-rs/codex-mcp/src/mcp/mod.rs
;
; Covered in this increment:
; - `mcp_permission_prompt_is_auto_approved`
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust receives `AskForApproval` and `SandboxPolicy` enum values by value or
;   reference. This CeTTa helper receives the already-materialized approval and
;   sandbox policy values. It intentionally compares the materialized approval
;   slice representation directly so modules that only need this predicate do
;   not inherit unrelated approval reducers.

(= (codex:mcp-permission-prompt-is-auto-approved
      $approval-policy
      $sandbox-policy)
   (and
     (== $approval-policy "never")
     (or
       (== $sandbox-policy (CodexApprovalSandboxPolicyDangerFullAccess))
       (== $sandbox-policy (CodexApprovalSandboxPolicyExternalSandbox)))))
