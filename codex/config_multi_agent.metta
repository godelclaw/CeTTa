; Rust-faithful multi-agent v2 config slice.
;
; This ports the MultiAgentV2Config struct surface from:
; - openai-codex/codex-rs/core/src/config/mod.rs (MultiAgentV2Config)
;
; Covered in this increment:
; - the record constructor in exact Rust field order
; - per-field getters via full-constructor destructuring
; - the Default impl: usage_hint_enabled true, usage_hint_text None,
;   hide_spawn_agent_metadata false

(= (codex:multi-agent-v2-config
      $usage-hint-enabled
      $usage-hint-text
      $hide-spawn-agent-metadata)
   (CodexMultiAgentV2Config
     $usage-hint-enabled
     $usage-hint-text
     $hide-spawn-agent-metadata))

(= (codex:multi-agent-v2-config-default)
   (CodexMultiAgentV2Config
     True
     CodexAbsent
     False))

(= (codex:multi-agent-v2-config-usage-hint-enabled
      (CodexMultiAgentV2Config
        $usage-hint-enabled
        $usage-hint-text
        $hide-spawn-agent-metadata))
   $usage-hint-enabled)

(= (codex:multi-agent-v2-config-usage-hint-text
      (CodexMultiAgentV2Config
        $usage-hint-enabled
        $usage-hint-text
        $hide-spawn-agent-metadata))
   $usage-hint-text)

(= (codex:multi-agent-v2-config-hide-spawn-agent-metadata
      (CodexMultiAgentV2Config
        $usage-hint-enabled
        $usage-hint-text
        $hide-spawn-agent-metadata))
   $hide-spawn-agent-metadata)
