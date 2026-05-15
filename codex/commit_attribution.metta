; Narrow Rust-faithful commit-attribution slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/commit_attribution.rs
;
; Covered in this increment:
; - resolve_attribution_value
; - build_commit_message_trailer
; - commit_message_trailer_instruction
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust returns `Option<String>`. The current CeTTa port preserves the same
;   visible strings and uses `Empty` for the absent `Option` case.

!(import! &self str)

(= (codex:default-commit-attribution-value)
   "Codex <noreply@openai.com>")

(= (codex:resolve-attribution-value $config-attribution)
   (if (== $config-attribution CodexAbsent)
       (codex:default-commit-attribution-value)
       (let $trimmed (str-trim $config-attribution)
         (if (== $trimmed "")
             Empty
             $trimmed))))

(= (codex:build-commit-message-trailer $config-attribution)
   (case (codex:resolve-attribution-value $config-attribution)
     ((Empty Empty)
      ($value
       (format-args "Co-authored-by: {}" ($value))))))

(= (codex:commit-message-trailer-instruction $config-attribution)
   (case (codex:build-commit-message-trailer $config-attribution)
     ((Empty Empty)
      ($trailer
       (format-args
         "When you write or edit a git commit message, ensure the message ends with this trailer exactly once:\n{}\n\nRules:\n- Keep existing trailers and append this trailer at the end if missing.\n- Do not duplicate this trailer if it already exists.\n- Keep one blank line between the commit body and trailer block."
         ($trailer)))))) 
