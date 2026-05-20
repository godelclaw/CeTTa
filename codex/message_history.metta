; Rust-faithful message history retention helper slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/message_history.rs
;   - HISTORY_FILENAME
;   - HISTORY_SOFT_CAP_RATIO
;   - MAX_RETRIES
;   - RETRY_SLEEP
;   - trim_target_bytes
;   - enforce_history_limit's oldest-line trimming loop
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust opens ~/.codex/history.jsonl, uses advisory file locks, appends with a
;   single write, enforces Unix mode 0600, reads newline-delimited byte lengths,
;   truncates the file, writes the retained tail, and flushes it. CeTTa has no
;   lock/chmod/sync/file-rewrite API in this layer, so this slice exposes the
;   pure retention plan over the current file length and per-line byte lengths.
;   A future runtime wrapper must apply the returned rewrite plan while holding
;   the same Rust lock.
; - Rust computes floor(max_bytes * 0.8) through f64. The ratio is exactly 4/5,
;   so this slice computes the same floor for integer byte counts as
;   floor(max_bytes * 8 / 10), avoiding CeTTa float-to-integer cast ambiguity.

!(import! &self list)

(= (codex:message-history-filename)
   "history.jsonl")

(= (codex:message-history-soft-cap-ratio-numerator)
   8)

(= (codex:message-history-soft-cap-ratio-denominator)
   10)

(= (codex:message-history-max-retries)
   10)

(= (codex:message-history-retry-sleep-ms)
   100)

(= (codex:message-history-floor-div-nonnegative $numerator $denominator)
   (/ (- $numerator (% $numerator $denominator)) $denominator))

(= (codex:message-history-clamp $value $min-value $max-value)
   (if (< $value $min-value)
       $min-value
       (if (> $value $max-value)
           $max-value
           $value)))

(= (codex:message-history-max $lhs $rhs)
   (if (> $lhs $rhs) $lhs $rhs))

(= (codex:message-history-soft-cap-bytes $max-bytes)
   (codex:message-history-clamp
     (codex:message-history-floor-div-nonnegative
       (* $max-bytes (codex:message-history-soft-cap-ratio-numerator))
       (codex:message-history-soft-cap-ratio-denominator))
     1
     $max-bytes))

(= (codex:message-history-trim-target-bytes
      $max-bytes
      $newest-entry-len)
   (codex:message-history-max
     (codex:message-history-soft-cap-bytes $max-bytes)
     $newest-entry-len))

(= (codex:message-history-line-lengths-sum $line-lengths)
   (if (== $line-lengths ())
       0
       (let $head (list:first $line-lengths)
         (let $tail (list:rest $line-lengths)
           (+ $head (codex:message-history-line-lengths-sum $tail))))))

(= (codex:message-history-line-lengths-last $line-lengths)
   (if (== $line-lengths ())
       CodexAbsent
       (if (== (list:rest $line-lengths) ())
       (list:first $line-lengths)
       (codex:message-history-line-lengths-last
           (list:rest $line-lengths)))))

(= (codex:message-history-line-lengths-init $line-lengths)
   (if (or (== $line-lengths ())
           (== (list:rest $line-lengths) ()))
       ()
       (list:cons
         (list:first $line-lengths)
         (codex:message-history-line-lengths-init
           (list:rest $line-lengths)))))

(= (codex:message-history-drop-line-lengths $line-lengths $count)
   (if (or (== $count 0)
           (== $line-lengths ()))
       $line-lengths
       (codex:message-history-drop-line-lengths
         (list:rest $line-lengths)
         (- $count 1))))

(= (codex:message-history-trim-loop
      $older-line-lengths
      $current-len
      $trim-target
      $drop-count
      $drop-bytes)
   (if (or (== $older-line-lengths ())
           (<= $current-len $trim-target))
       (CodexMessageHistoryTrimLoop
         $drop-count
         $drop-bytes
         $current-len)
       (let $head (list:first $older-line-lengths)
         (codex:message-history-trim-loop
           (list:rest $older-line-lengths)
           (- $current-len $head)
           $trim-target
           (+ $drop-count 1)
           (+ $drop-bytes $head)))))

(= (codex:message-history-limit-plan-from-current-len
      $current-len
      $line-lengths
      $max-bytes)
   (if (or (== $max-bytes CodexAbsent)
           (== $max-bytes 0))
       (CodexMessageHistoryLimitUnchanged $line-lengths $current-len)
       (if (<= $current-len $max-bytes)
           (CodexMessageHistoryLimitUnchanged $line-lengths $current-len)
           (if (== $line-lengths ())
               (CodexMessageHistoryLimitUnchanged $line-lengths $current-len)
               (let $newest-entry-len
                 (codex:message-history-line-lengths-last $line-lengths)
                 (let $trim-target
                   (codex:message-history-trim-target-bytes
                     $max-bytes
                     $newest-entry-len)
                   (case
                     (codex:message-history-trim-loop
                       (codex:message-history-line-lengths-init $line-lengths)
                       $current-len
                       $trim-target
                       0
                       0)
                     (((CodexMessageHistoryTrimLoop
                         $drop-count
                         $drop-bytes
                         $retained-len)
                       (if (== $drop-bytes 0)
                           (CodexMessageHistoryLimitUnchanged
                             $line-lengths
                             $current-len)
                           (CodexMessageHistoryLimitRewrite
                             $drop-count
                             $drop-bytes
                             $retained-len
                             (codex:message-history-drop-line-lengths
                               $line-lengths
                               $drop-count))))))))))))

(= (codex:message-history-limit-plan $line-lengths $max-bytes)
   (codex:message-history-limit-plan-from-current-len
     (codex:message-history-line-lengths-sum $line-lengths)
     $line-lengths
     $max-bytes))

(= (codex:message-history-limit-plan-action
      (CodexMessageHistoryLimitUnchanged $line-lengths $current-len))
   "unchanged")

(= (codex:message-history-limit-plan-action
      (CodexMessageHistoryLimitRewrite
        $drop-count
        $drop-bytes
        $retained-len
        $retained-line-lengths))
   "rewrite")

(= (codex:message-history-limit-plan-retained-line-lengths
      (CodexMessageHistoryLimitUnchanged $line-lengths $current-len))
   $line-lengths)

(= (codex:message-history-limit-plan-retained-line-lengths
      (CodexMessageHistoryLimitRewrite
        $drop-count
        $drop-bytes
        $retained-len
        $retained-line-lengths))
   $retained-line-lengths)

(= (codex:message-history-limit-plan-drop-count
      (CodexMessageHistoryLimitUnchanged $line-lengths $current-len))
   0)

(= (codex:message-history-limit-plan-drop-count
      (CodexMessageHistoryLimitRewrite
        $drop-count
        $drop-bytes
        $retained-len
        $retained-line-lengths))
   $drop-count)

(= (codex:message-history-limit-plan-drop-bytes
      (CodexMessageHistoryLimitUnchanged $line-lengths $current-len))
   0)

(= (codex:message-history-limit-plan-drop-bytes
      (CodexMessageHistoryLimitRewrite
        $drop-count
        $drop-bytes
        $retained-len
        $retained-line-lengths))
   $drop-bytes)

(= (codex:message-history-limit-plan-retained-bytes
      (CodexMessageHistoryLimitUnchanged $line-lengths $current-len))
   $current-len)

(= (codex:message-history-limit-plan-retained-bytes
      (CodexMessageHistoryLimitRewrite
        $drop-count
        $drop-bytes
        $retained-len
        $retained-line-lengths))
   $retained-len)
