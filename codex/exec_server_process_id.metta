; Rust-faithful exec-server ProcessId slice.
;
; This ports the visible transparent wrapper behavior from:
; - openai-codex/codex-rs/exec-server/src/process_id.rs
;   - ProcessId::new
;   - ProcessId::as_str
;   - ProcessId::into_inner
;   - Display / From<String> / From<&str> transparent string behavior
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust implements standard traits (`Deref`, `Borrow<str>`, `AsRef<str>`,
;   `Display`, and `From`). CeTTa has no direct trait-impl surface here, so
;   this module exposes equivalent named projections over the same transparent
;   string constructor.

(= (codex:exec-server-process-id-new $value)
   (CodexExecServerProcessId $value))

(= (codex:exec-server-process-id-as-str
      (CodexExecServerProcessId $value))
   $value)

(= (codex:exec-server-process-id-into-inner
      (CodexExecServerProcessId $value))
   $value)

(= (codex:exec-server-process-id-display $process-id)
   (codex:exec-server-process-id-as-str $process-id))

(= (codex:exec-server-process-id-from-string $value)
   (CodexExecServerProcessId $value))
