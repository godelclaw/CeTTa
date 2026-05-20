; Pure Rust-faithful CLI argument enum mapping slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/utils/cli/src/approval_mode_cli_arg.rs
; - openai-codex/codex-rs/utils/cli/src/sandbox_mode_cli_arg.rs
; - openai-codex/codex-rs/protocol/src/config_types.rs `SandboxMode`
;
; Covered in this increment:
; - ApprovalModeCliArg variants and `From<ApprovalModeCliArg> for AskForApproval`
; - SandboxModeCliArg variants and `From<SandboxModeCliArg> for SandboxMode`
; - clap `rename_all = "kebab-case"` display/parse surfaces for these enums
;
; Required CeTTa representation notes for audit:
; - Rust derives clap `ValueEnum`; this pure helper exposes the same kebab-case
;   string names as deterministic parse/display predicates for the runtime CLI
;   parser boundary to call.

!(import! &self approval)

(= (codex:approval-mode-cli-arg-untrusted)
   (CodexApprovalModeCliArgUntrusted))

(= (codex:approval-mode-cli-arg-on-failure)
   (CodexApprovalModeCliArgOnFailure))

(= (codex:approval-mode-cli-arg-on-request)
   (CodexApprovalModeCliArgOnRequest))

(= (codex:approval-mode-cli-arg-never)
   (CodexApprovalModeCliArgNever))

(= (codex:approval-mode-cli-arg-to-ask-for-approval
      (CodexApprovalModeCliArgUntrusted))
   (codex:ask-for-approval-unless-trusted))

(= (codex:approval-mode-cli-arg-to-ask-for-approval
      (CodexApprovalModeCliArgOnFailure))
   (codex:ask-for-approval-on-failure))

(= (codex:approval-mode-cli-arg-to-ask-for-approval
      (CodexApprovalModeCliArgOnRequest))
   (codex:ask-for-approval-on-request))

(= (codex:approval-mode-cli-arg-to-ask-for-approval
      (CodexApprovalModeCliArgNever))
   (codex:ask-for-approval-never))

(= (codex:approval-mode-cli-arg-kebab
      (CodexApprovalModeCliArgUntrusted))
   "untrusted")

(= (codex:approval-mode-cli-arg-kebab
      (CodexApprovalModeCliArgOnFailure))
   "on-failure")

(= (codex:approval-mode-cli-arg-kebab
      (CodexApprovalModeCliArgOnRequest))
   "on-request")

(= (codex:approval-mode-cli-arg-kebab
      (CodexApprovalModeCliArgNever))
   "never")

(= (codex:approval-mode-cli-arg-from-kebab $text)
   (case $text
     (("untrusted" (codex:approval-mode-cli-arg-untrusted))
      ("on-failure" (codex:approval-mode-cli-arg-on-failure))
      ("on-request" (codex:approval-mode-cli-arg-on-request))
      ("never" (codex:approval-mode-cli-arg-never))
      ($other CodexAbsent))))

(= (codex:sandbox-mode-read-only)
   (CodexSandboxModeReadOnly))

(= (codex:sandbox-mode-workspace-write)
   (CodexSandboxModeWorkspaceWrite))

(= (codex:sandbox-mode-danger-full-access)
   (CodexSandboxModeDangerFullAccess))

(= (codex:sandbox-mode-kebab (CodexSandboxModeReadOnly))
   "read-only")

(= (codex:sandbox-mode-kebab (CodexSandboxModeWorkspaceWrite))
   "workspace-write")

(= (codex:sandbox-mode-kebab (CodexSandboxModeDangerFullAccess))
   "danger-full-access")

(= (codex:sandbox-mode-cli-arg-read-only)
   (CodexSandboxModeCliArgReadOnly))

(= (codex:sandbox-mode-cli-arg-workspace-write)
   (CodexSandboxModeCliArgWorkspaceWrite))

(= (codex:sandbox-mode-cli-arg-danger-full-access)
   (CodexSandboxModeCliArgDangerFullAccess))

(= (codex:sandbox-mode-cli-arg-to-sandbox-mode
      (CodexSandboxModeCliArgReadOnly))
   (codex:sandbox-mode-read-only))

(= (codex:sandbox-mode-cli-arg-to-sandbox-mode
      (CodexSandboxModeCliArgWorkspaceWrite))
   (codex:sandbox-mode-workspace-write))

(= (codex:sandbox-mode-cli-arg-to-sandbox-mode
      (CodexSandboxModeCliArgDangerFullAccess))
   (codex:sandbox-mode-danger-full-access))

(= (codex:sandbox-mode-cli-arg-kebab
      (CodexSandboxModeCliArgReadOnly))
   "read-only")

(= (codex:sandbox-mode-cli-arg-kebab
      (CodexSandboxModeCliArgWorkspaceWrite))
   "workspace-write")

(= (codex:sandbox-mode-cli-arg-kebab
      (CodexSandboxModeCliArgDangerFullAccess))
   "danger-full-access")

(= (codex:sandbox-mode-cli-arg-from-kebab $text)
   (case $text
     (("read-only" (codex:sandbox-mode-cli-arg-read-only))
      ("workspace-write" (codex:sandbox-mode-cli-arg-workspace-write))
      ("danger-full-access" (codex:sandbox-mode-cli-arg-danger-full-access))
      ($other CodexAbsent))))
