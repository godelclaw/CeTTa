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

(= (codex:token-usage-percent-clamp $value)
   (if (< $value 0)
       0
       (if (> $value 100)
           100
           $value)))

(= (codex:token-usage-percent-rounded $effective-window $remaining)
   (case
     (round-math
       (* (/ $remaining $effective-window) 100.0))
     (($rounded-float
       (case (trunc-math $rounded-float)
         (($rounded
           (case
             (codex:token-usage-normalize-whole-number $rounded)
             (($normalized
               (codex:token-usage-percent-clamp $normalized)))))))))))

(= (codex:token-usage-percent-from-remaining-raw
      $effective-window
      $remaining-raw)
   (let $remaining
     (if (< $remaining-raw 0) 0 $remaining-raw)
     (codex:token-usage-percent-rounded $effective-window $remaining)))

(= (codex:token-usage-percent-from-used-raw
      $effective-window
      $used-raw)
   (let $used
     (if (< $used-raw 0) 0 $used-raw)
     (codex:token-usage-percent-from-remaining-raw
       $effective-window
       (- $effective-window $used))))

(= (codex:token-usage-percent-from-effective-window
      $usage
      $effective-window)
   (case
     (- (codex:token-usage-tokens-in-context-window $usage)
        (codex:baseline-tokens))
     (($used-raw
       (codex:token-usage-percent-from-used-raw
         $effective-window
         $used-raw)))))

(= (codex:token-usage-percent-of-context-window-remaining $usage $context-window)
   ; CeTTa evaluation accommodation: stage Rust's formula through explicit
   ; materialization points. This preserves the TokenUsage method semantics
   ; while avoiding order-sensitive collapse after earlier token-usage calls.
   (if (<= $context-window (codex:baseline-tokens))
       0
       (case (- $context-window (codex:baseline-tokens))
         (($effective-window
           (codex:token-usage-percent-from-effective-window
             $usage
             $effective-window))))))

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

(= (codex:token-usage-cached-fragment-from $cached)
   (if (> $cached 0)
       (case (codex:format-with-separators $cached)
         (($cached-text
           (format-args " (+ {} cached)" ($cached-text)))))
       ""))

(= (codex:token-usage-cached-fragment $token-usage)
   (case (codex:token-usage-cached-input $token-usage)
     (($cached
       (codex:token-usage-cached-fragment-from $cached)))))

(= (codex:token-usage-reasoning-fragment-from $reasoning)
   (if (> $reasoning 0)
       (case (codex:format-with-separators $reasoning)
         (($reasoning-text
           (format-args " (reasoning {})" ($reasoning-text)))))
       ""))

(= (codex:token-usage-reasoning-fragment $token-usage)
   (case (codex:token-usage-reasoning-output-tokens $token-usage)
     (($reasoning
       (codex:token-usage-reasoning-fragment-from $reasoning)))))

(= (codex:render-final-output-with-reasoning
      $total-text
      $input-text
      $cached-fragment
      $output-text
      $reasoning-fragment)
   (format-args
     "Token usage: total={} input={}{} output={}{}"
     ($total-text
      $input-text
      $cached-fragment
      $output-text
      $reasoning-fragment)))

(= (codex:render-final-output-with-output
      $token-usage
      $total-text
      $input-text
      $cached-fragment
      $output-text)
   (case (codex:token-usage-reasoning-fragment $token-usage)
     (($reasoning-fragment
       (codex:render-final-output-with-reasoning
         $total-text
         $input-text
         $cached-fragment
         $output-text
         $reasoning-fragment)))))

(= (codex:render-final-output-with-cached
      $token-usage
      $total-text
      $input-text
      $cached-fragment)
   (case (codex:token-usage-output-tokens $token-usage)
     (($output
       (case (codex:format-with-separators $output)
         (($output-text
           (codex:render-final-output-with-output
             $token-usage
             $total-text
             $input-text
             $cached-fragment
             $output-text))))))))

(= (codex:render-final-output-with-input
      $token-usage
      $total-text
      $input-text)
   (case (codex:token-usage-cached-fragment $token-usage)
     (($cached-fragment
       (codex:render-final-output-with-cached
         $token-usage
         $total-text
         $input-text
         $cached-fragment)))))

(= (codex:render-final-output-with-total $token-usage $total-text)
   (case (codex:token-usage-non-cached-input $token-usage)
     (($input
       (case (codex:format-with-separators $input)
         (($input-text
           (codex:render-final-output-with-input
             $token-usage
             $total-text
             $input-text))))))))

(= (codex:render-final-output-token-usage $token-usage)
   (case (codex:token-usage-blended-total $token-usage)
     (($total
       (case (codex:format-with-separators $total)
         (($total-text
           (codex:render-final-output-with-total
             $token-usage
             $total-text))))))))

(= (codex:render-final-output $final-output)
   ; CeTTa evaluation accommodation: keep Rust's Display formula but materialize
   ; each formatted component before the final format-args call.
   (case (codex:final-output-token-usage $final-output)
     (($token-usage
       (codex:render-final-output-token-usage $token-usage)))))
