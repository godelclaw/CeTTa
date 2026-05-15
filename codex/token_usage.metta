; Narrow Rust-faithful token-usage helper slice for the restarted Codex port.
;
; This ports the visible pure logic from:
; - openai-codex/codex-rs/protocol/src/protocol.rs
;   TokenUsage methods
;   FinalOutput From<TokenUsage> + Display
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust's `add_assign(&mut self, other)` mutates in place. The current CeTTa
;   restart surface ports the same visible result through a pure constructor
;   helper `codex:token-usage-add`.
; - Rust stores these methods on protocol structs directly. The current CeTTa
;   restart keeps the record shape in `protocol.metta` and ports the pure math
;   and render helpers in this companion module.
; - The current CeTTa profile's builtin `decimal-string-to-number` boundary is
;   not reliably reducing in nested helper paths. This slice therefore ports
;   the same local digit-parser pattern already used elsewhere in the restart
;   subset to recover Rust-visible integer result shapes.

!(import! &self num_format)
!(import! &self protocol)

(= (codex:baseline-tokens)
   12000)

(= (codex:token-usage-decimal-digit-value "0")
   0)

(= (codex:token-usage-decimal-digit-value "1")
   1)

(= (codex:token-usage-decimal-digit-value "2")
   2)

(= (codex:token-usage-decimal-digit-value "3")
   3)

(= (codex:token-usage-decimal-digit-value "4")
   4)

(= (codex:token-usage-decimal-digit-value "5")
   5)

(= (codex:token-usage-decimal-digit-value "6")
   6)

(= (codex:token-usage-decimal-digit-value "7")
   7)

(= (codex:token-usage-decimal-digit-value "8")
   8)

(= (codex:token-usage-decimal-digit-value "9")
   9)

(= (codex:token-usage-decimal-string-to-number $text)
   (if (== $text "")
       0
       (codex:token-usage-decimal-string-to-number-from $text 0 0)))

(= (codex:token-usage-decimal-string-to-number-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:token-usage-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10) (codex:token-usage-decimal-digit-value $digit-char))))))

(= (codex:token-usage-normalize-whole-number $value)
   (codex:token-usage-decimal-string-to-number
     (codex:num-format-number-text $value)))

(= (codex:is-zero-token-usage? $usage)
   (== (codex:token-usage-total-tokens $usage) 0))

(= (codex:token-usage-cached-input $usage)
   (let $cached (codex:token-usage-cached-input-tokens $usage)
     (if (< $cached 0) 0 $cached)))

(= (codex:token-usage-non-cached-input $usage)
   (let $value
     (- (codex:token-usage-input-tokens $usage)
        (codex:token-usage-cached-input $usage))
     (if (< $value 0) 0 $value)))

(= (codex:token-usage-blended-total $usage)
   (let $output
     (codex:token-usage-output-tokens $usage)
     (let $positive-output (if (< $output 0) 0 $output)
       (let $value (+ (codex:token-usage-non-cached-input $usage) $positive-output)
         (if (< $value 0) 0 $value)))))

(= (codex:token-usage-tokens-in-context-window $usage)
   (codex:token-usage-total-tokens $usage))

(= (codex:token-usage-percent-of-context-window-remaining $usage $context-window)
   (if (<= $context-window (codex:baseline-tokens))
       0
       (let $effective-window (- $context-window (codex:baseline-tokens))
         (let $used-raw
           (- (codex:token-usage-tokens-in-context-window $usage)
              (codex:baseline-tokens))
           (let $used
             (if (< $used-raw 0) 0 $used-raw)
             (let $remaining-raw
               (- $effective-window $used)
               (let $remaining
                 (if (< $remaining-raw 0) 0 $remaining-raw)
                 (let $rounded
                 (trunc-math
                   (round-math
                     (* (/ $remaining $effective-window) 100.0)))
                   (let $normalized
                     (codex:token-usage-normalize-whole-number $rounded)
                     (if (< $normalized 0)
                         0
                         (if (> $normalized 100)
                             100
                             $normalized)))))))))))

(= (codex:token-usage-add $left $right)
   (codex:token-usage
     (+ (codex:token-usage-input-tokens $left)
        (codex:token-usage-input-tokens $right))
     (+ (codex:token-usage-cached-input-tokens $left)
        (codex:token-usage-cached-input-tokens $right))
     (+ (codex:token-usage-output-tokens $left)
        (codex:token-usage-output-tokens $right))
     (+ (codex:token-usage-reasoning-output-tokens $left)
        (codex:token-usage-reasoning-output-tokens $right))
     (+ (codex:token-usage-total-tokens $left)
        (codex:token-usage-total-tokens $right))))

(= (codex:final-output-from-token-usage $token-usage)
   (codex:final-output $token-usage))

(= (codex:render-final-output $final-output)
   (let $token-usage (codex:final-output-token-usage $final-output)
     (let $cached-fragment
       (if (> (codex:token-usage-cached-input $token-usage) 0)
           (str-concat
             " (+ "
             (str-concat
               (codex:format-with-separators
                 (codex:token-usage-cached-input $token-usage))
               " cached)"))
           "")
       (let $reasoning-fragment
         (if (> (codex:token-usage-reasoning-output-tokens $token-usage) 0)
             (str-concat
               " (reasoning "
               (str-concat
                 (codex:format-with-separators
                   (codex:token-usage-reasoning-output-tokens $token-usage))
                 ")"))
             "")
         (format-args
           "Token usage: total={} input={}{} output={}{}"
           ((codex:format-with-separators
               (codex:token-usage-blended-total $token-usage))
            (codex:format-with-separators
              (codex:token-usage-non-cached-input $token-usage))
            $cached-fragment
            (codex:format-with-separators
              (codex:token-usage-output-tokens $token-usage))
            $reasoning-fragment))))))
