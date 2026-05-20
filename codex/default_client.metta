; Pure Rust-faithful default_client helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/login/src/auth/default_client.rs
;
; Covered in this increment:
; - DEFAULT_ORIGINATOR
; - CODEX_INTERNAL_ORIGINATOR_OVERRIDE_ENV_VAR
; - is_first_party_originator
; - is_first_party_chat_originator
;
; Required CeTTa representation notes for audit:
; - Rust stores the originator as a process-global `Originator` that also
;   contains a validated `HeaderValue`. This pure helper only exposes constants
;   and predicates over already-materialized originator text. Header validation
;   and global mutation remain runtime-library work.

!(import! &self str)

(= (codex:default-client-default-originator)
   "codex_cli_rs")

(= (codex:default-client-originator-override-env-var)
   "CODEX_INTERNAL_ORIGINATOR_OVERRIDE")

(= (codex:default-client-is-first-party-originator $originator-value)
   (or
     (== $originator-value "codex_cli_rs")
     (or
       (== $originator-value "codex-tui")
       (or
         (== $originator-value "codex_vscode")
         (str-starts-with? $originator-value "Codex ")))))

(= (codex:default-client-is-first-party-chat-originator $originator-value)
   (or
     (== $originator-value "codex_atlas")
     (== $originator-value "codex_chatgpt_desktop")))
