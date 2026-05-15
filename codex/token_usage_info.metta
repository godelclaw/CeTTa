; Narrow Rust-faithful token-usage-info helper slice for the restarted Codex port.
;
; This ports the visible pure logic from:
; - openai-codex/codex-rs/protocol/src/protocol.rs
;   TokenUsageInfo methods
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust uses `Option<TokenUsageInfo>`, `Option<TokenUsage>`, and
;   `Option<i64>`. The current CeTTa restart surface preserves the same visible
;   behavior with `CodexAbsent` as the internal absent marker.
; - Rust mutates `self` in `append_last_usage()` and `fill_to_context_window()`.
;   The current CeTTa restart surface ports the same visible result through
;   pure constructor helpers.

!(import! &self protocol)
!(import! &self token_usage)

(= (codex:default-token-usage-info)
   (codex:token-usage-info
     (codex:default-token-usage)
     (codex:default-token-usage)
     CodexAbsent))

(= (codex:token-usage-info-append-last-usage $info $last)
   (codex:token-usage-info
     (codex:token-usage-add
       (codex:token-usage-info-total-token-usage $info)
       $last)
     $last
     (codex:token-usage-info-model-context-window $info)))

(= (codex:token-usage-info-fill-to-context-window $info $context-window)
   (let $previous-total
     (codex:token-usage-total-tokens
       (codex:token-usage-info-total-token-usage $info))
     (let $delta-raw (- $context-window $previous-total)
       (let $delta (if (< $delta-raw 0) 0 $delta-raw)
         (codex:token-usage-info
           (codex:token-usage 0 0 0 0 $context-window)
           (codex:token-usage 0 0 0 0 $delta)
           $context-window)))))

(= (codex:full-token-usage-context-window $context-window)
   (codex:token-usage-info-fill-to-context-window
     (codex:token-usage-info
       (codex:default-token-usage)
       (codex:default-token-usage)
       $context-window)
     $context-window))

(= (codex:token-usage-info-new-or-append $info $last $model-context-window)
   (if (and (== $info CodexAbsent) (== $last CodexAbsent))
       CodexAbsent
       (let $seed
         (if (== $info CodexAbsent)
             (codex:token-usage-info
               (codex:default-token-usage)
               (codex:default-token-usage)
               $model-context-window)
             $info)
         (let $with-last
           (if (== $last CodexAbsent)
               $seed
               (codex:token-usage-info-append-last-usage $seed $last))
           (if (== $model-context-window CodexAbsent)
               $with-last
               (codex:token-usage-info
                 (codex:token-usage-info-total-token-usage $with-last)
                 (codex:token-usage-info-last-token-usage $with-last)
                 $model-context-window))))))
