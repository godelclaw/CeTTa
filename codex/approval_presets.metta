; Rust-faithful built-in approval presets slice.
;
; This ports:
; - openai-codex/codex-rs/utils/approval-presets/src/lib.rs
;
; Covered in this increment:
; - ApprovalPreset data shape
; - builtin_approval_presets order and field values
;
; Required CeTTa deviations for audit:
; - Rust returns `Vec<ApprovalPreset>` with struct fields. CeTTa represents the
;   same ordered vector as a list of record atoms with explicit accessors.

!(import! &self protocol)

(= (codex:approval-preset $id $label $description $approval $sandbox)
   (CodexApprovalPreset $id $label $description $approval $sandbox))

(= (codex:approval-preset-id
      (CodexApprovalPreset $id $label $description $approval $sandbox))
   $id)

(= (codex:approval-preset-label
      (CodexApprovalPreset $id $label $description $approval $sandbox))
   $label)

(= (codex:approval-preset-description
      (CodexApprovalPreset $id $label $description $approval $sandbox))
   $description)

(= (codex:approval-preset-approval
      (CodexApprovalPreset $id $label $description $approval $sandbox))
   $approval)

(= (codex:approval-preset-sandbox
      (CodexApprovalPreset $id $label $description $approval $sandbox))
   $sandbox)

(= (codex:approval-preset-read-only)
   (codex:approval-preset
     "read-only"
     "Read Only"
     "Codex can read files in the current workspace. Approval is required to edit files or access the internet."
     (codex:session-approval-policy-on-request)
     (codex:session-sandbox-policy-read-only
       (codex:session-read-only-access-full)
       False)))

(= (codex:approval-preset-auto)
   (codex:approval-preset
     "auto"
     "Default"
     "Codex can read and edit files in the current workspace, and run commands. Approval is required to access the internet or edit other files. (Identical to Agent mode)"
     (codex:session-approval-policy-on-request)
     (codex:session-sandbox-policy-workspace-write
       ()
       (codex:session-read-only-access-full)
       False
       False
       False)))

(= (codex:approval-preset-full-access)
   (codex:approval-preset
     "full-access"
     "Full Access"
     "Codex can edit files outside this workspace and access the internet without asking for approval. Exercise caution when using."
     (codex:session-approval-policy-never)
     (codex:session-sandbox-policy-danger-full-access)))

(= (codex:builtin-approval-presets)
   ((codex:approval-preset-read-only)
    (codex:approval-preset-auto)
    (codex:approval-preset-full-access)))
