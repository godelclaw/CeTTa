; Rust-faithful string truncation helper slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/utils/string/src/truncate.rs
;
; Covered in this increment:
; - approximate token/byte conversions
; - UTF-8-boundary middle splitting wrapper
; - token-budget middle truncation with original token count reporting
; - byte-budget middle truncation with character-count markers
;
; Required CeTTa representation notes for audit:
; - Rust returns `(String, Option<u64>)` for token-budget truncation. This
;   helper returns `CodexStringTruncateResult`, using `CodexAbsent` for `None`.
; - Rust saturates at fixed `usize`/`u64` bounds. CeTTa integers are unbounded
;   in the current profile, so the arithmetic is the same recurrence without
;   fixed-width overflow saturation.
; - Rust's private `split_string` is exposed here as
;   `codex:string-truncate-split-string` so the port can pin its surface tests
;   to the same edge cases.

!(import! &self str)
!(import! &self str_middle)

(= (codex:string-truncate-approx-bytes-per-token)
   4)

(= (codex:string-truncate-result $text $original-token-count)
   (CodexStringTruncateResult $text $original-token-count))

(= (codex:string-truncate-result-text
      (CodexStringTruncateResult $text $original-token-count))
   $text)

(= (codex:string-truncate-result-original-token-count
      (CodexStringTruncateResult $text $original-token-count))
   $original-token-count)

(= (codex:string-truncate-strip-trailing-dot-zero $text)
   (if (str-ends-with? $text ".0")
       (str-slice $text 0 (- (str-length $text) 2))
       $text))

(= (codex:string-truncate-number-text $value)
   (codex:string-truncate-strip-trailing-dot-zero
     (format-args "{}" ($value))))

(= (codex:string-truncate-decimal-digit-value "0")
   0)

(= (codex:string-truncate-decimal-digit-value "1")
   1)

(= (codex:string-truncate-decimal-digit-value "2")
   2)

(= (codex:string-truncate-decimal-digit-value "3")
   3)

(= (codex:string-truncate-decimal-digit-value "4")
   4)

(= (codex:string-truncate-decimal-digit-value "5")
   5)

(= (codex:string-truncate-decimal-digit-value "6")
   6)

(= (codex:string-truncate-decimal-digit-value "7")
   7)

(= (codex:string-truncate-decimal-digit-value "8")
   8)

(= (codex:string-truncate-decimal-digit-value "9")
   9)

(= (codex:string-truncate-decimal-string-to-number $text)
   (if (== $text "")
       0
       (codex:string-truncate-decimal-string-to-number-from
         $text
         0
         0)))

(= (codex:string-truncate-decimal-string-to-number-from
      $text
      $index
      $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:string-truncate-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10)
              (codex:string-truncate-decimal-digit-value
                $digit-char))))))

(= (codex:string-truncate-normalize-whole-number $value)
   (codex:string-truncate-decimal-string-to-number
     (codex:string-truncate-number-text $value)))

(= (codex:string-truncate-approx-token-count $text)
   (codex:string-truncate-approx-tokens-from-byte-count
     (str-length $text)))

(= (codex:string-truncate-approx-bytes-for-tokens $tokens)
   (* $tokens (codex:string-truncate-approx-bytes-per-token)))

(= (codex:string-truncate-approx-tokens-from-byte-count $bytes)
   (codex:string-truncate-normalize-whole-number
     (trunc-math
       (/
         (+ $bytes
            (- (codex:string-truncate-approx-bytes-per-token) 1))
         (codex:string-truncate-approx-bytes-per-token)))))

(= (codex:string-truncate-split-budget $budget)
   (let $left
     (codex:string-truncate-normalize-whole-number
       (trunc-math (/ $budget 2)))
     (CodexStringTruncateSplitBudget $left (- $budget $left))))

(= (codex:string-truncate-split-string
      $text
      $beginning-bytes
      $end-bytes)
   (str-split-middle-bytes $text $beginning-bytes $end-bytes))

(= (codex:string-truncate-char-count $text)
   (case (codex:string-truncate-split-string $text 0 0)
     (((StrMiddleSplit $removed-chars $prefix $suffix)
       $removed-chars))))

(= (codex:string-truncate-format-truncation-marker
      $use-tokens
      $removed-count)
   (str-concat
     "…"
     (str-concat
       (codex:string-truncate-number-text $removed-count)
       (if $use-tokens
           " tokens truncated…"
           " chars truncated…"))))

(= (codex:string-truncate-removed-units
      $use-tokens
      $removed-bytes
      $removed-chars)
   (if $use-tokens
       (codex:string-truncate-approx-tokens-from-byte-count
         $removed-bytes)
       $removed-chars))

(= (codex:string-truncate-assemble-truncated-output
      $prefix
      $suffix
      $marker)
   (str-concat $prefix (str-concat $marker $suffix)))

(= (codex:string-truncate-with-byte-estimate
      $text
      $max-bytes
      $use-tokens)
   (if (== $text "")
       ""
       (let $total-bytes (str-length $text)
         (if (== $max-bytes 0)
             (codex:string-truncate-format-truncation-marker
               $use-tokens
               (codex:string-truncate-removed-units
                 $use-tokens
                 $total-bytes
                 (codex:string-truncate-char-count $text)))
             (if (<= $total-bytes $max-bytes)
                 $text
                 (case (codex:string-truncate-split-budget $max-bytes)
                   (((CodexStringTruncateSplitBudget
                       $left-budget
                       $right-budget)
                     (case (codex:string-truncate-split-string
                             $text
                             $left-budget
                             $right-budget)
                       (((StrMiddleSplit
                           $removed-chars
                           $prefix
                           $suffix)
                         (let $marker
                           (codex:string-truncate-format-truncation-marker
                             $use-tokens
                             (codex:string-truncate-removed-units
                               $use-tokens
                               (- $total-bytes $max-bytes)
                               $removed-chars))
                           (codex:string-truncate-assemble-truncated-output
                             $prefix
                             $suffix
                             $marker)))))))))))))

(= (codex:string-truncate-middle-chars $text $max-bytes)
   (codex:string-truncate-with-byte-estimate
     $text
     $max-bytes
     False))

(= (codex:string-truncate-middle-with-token-budget
      $text
      $max-tokens)
   (if (== $text "")
       (codex:string-truncate-result "" CodexAbsent)
       (if (and
             (> $max-tokens 0)
             (<= (str-length $text)
                 (codex:string-truncate-approx-bytes-for-tokens
                   $max-tokens)))
           (codex:string-truncate-result $text CodexAbsent)
           (let $truncated
             (codex:string-truncate-with-byte-estimate
               $text
               (codex:string-truncate-approx-bytes-for-tokens
                 $max-tokens)
               True)
             (let $total-tokens
               (codex:string-truncate-approx-token-count $text)
               (if (== $truncated $text)
                   (codex:string-truncate-result
                     $truncated
                     CodexAbsent)
                   (codex:string-truncate-result
                     $truncated
                     $total-tokens)))))))

(= (codex:string-truncate-middle-with-token-budget-text
      $text
      $max-tokens)
   (codex:string-truncate-result-text
     (codex:string-truncate-middle-with-token-budget
       $text
       $max-tokens)))
