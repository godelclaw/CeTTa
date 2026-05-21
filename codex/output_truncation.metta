; Rust-faithful output truncation helper slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/utils/output-truncation/src/lib.rs
; - openai-codex/codex-rs/protocol/src/protocol.rs `TruncationPolicy`
;
; Covered in this increment:
; - policy-driven text truncation
; - formatted line-count prefixes for truncated text
; - formatted truncation over function-call content-item lists
; - per-item function output truncation with omitted-text summaries
; - signed byte-count token approximation helper
;
; Required CeTTa representation notes for audit:
; - Rust returns `(Vec<FunctionCallOutputContentItem>, Option<usize>)` from
;   `formatted_truncate_text_content_items_with_policy`. This helper returns
;   `CodexOutputTruncationContentItemsResult`, using `CodexAbsent` for `None`.
; - Rust reexports `TruncationPolicy` from `codex_protocol`. This slice uses
;   the same `CodexTruncationPolicyBytes` / `CodexTruncationPolicyTokens`
;   constructors already ported in `codex:protocol`.
; - Rust saturates fixed-width conversions. CeTTa integers are unbounded in the
;   current profile, so the same arithmetic recurrence is used without
;   fixed-width overflow saturation.

!(import! &self list)
!(import! &self str)
!(import! &self codex:string_truncate)

(= (codex:output-truncation-policy-bytes $bytes)
   (CodexTruncationPolicyBytes $bytes))

(= (codex:output-truncation-policy-tokens $tokens)
   (CodexTruncationPolicyTokens $tokens))

(= (codex:output-truncation-content-items-result
      $items
      $original-token-count)
   (CodexOutputTruncationContentItemsResult
     $items
     $original-token-count))

(= (codex:output-truncation-content-items-result-items
      (CodexOutputTruncationContentItemsResult
        $items
        $original-token-count))
   $items)

(= (codex:output-truncation-content-items-result-original-token-count
      (CodexOutputTruncationContentItemsResult
        $items
        $original-token-count))
   $original-token-count)

(= (codex:output-truncation-approx-token-count $text)
   (codex:string-truncate-approx-token-count $text))

(= (codex:output-truncation-approx-bytes-for-tokens $tokens)
   (codex:string-truncate-approx-bytes-for-tokens $tokens))

(= (codex:output-truncation-approx-tokens-from-byte-count $bytes)
   (codex:string-truncate-approx-tokens-from-byte-count $bytes))

(= (codex:output-truncation-approx-tokens-from-byte-count-i64 $bytes)
   (if (<= $bytes 0)
       0
       (codex:output-truncation-approx-tokens-from-byte-count
         $bytes)))

(= (codex:output-truncation-policy-token-budget
      (CodexTruncationPolicyBytes $bytes))
   (codex:output-truncation-approx-tokens-from-byte-count $bytes))

(= (codex:output-truncation-policy-token-budget
      (CodexTruncationPolicyTokens $tokens))
   $tokens)

(= (codex:output-truncation-policy-byte-budget
      (CodexTruncationPolicyBytes $bytes))
   $bytes)

(= (codex:output-truncation-policy-byte-budget
      (CodexTruncationPolicyTokens $tokens))
   (codex:output-truncation-approx-bytes-for-tokens $tokens))

(= (codex:output-truncation-count-lines $text)
   (if (== $text "")
       0
       (let $parts (str-split "\n" $text)
         (if (str-ends-with? $text "\n")
             (- (list:len $parts) 1)
             (list:len $parts)))))

(= (codex:output-truncation-truncate-text
      $content
      (CodexTruncationPolicyBytes $bytes))
   (codex:string-truncate-middle-chars $content $bytes))

(= (codex:output-truncation-truncate-text
      $content
      (CodexTruncationPolicyTokens $tokens))
   (codex:string-truncate-middle-with-token-budget-text
     $content
     $tokens))

(= (codex:output-truncation-formatted-truncate-text
      $content
      $policy)
   (if (<= (str-length $content)
           (codex:output-truncation-policy-byte-budget $policy))
       $content
       (str-concat
         (format-args
           "Total output lines: {}\n\n"
           ((codex:output-truncation-count-lines $content)))
         (codex:output-truncation-truncate-text $content $policy))))

(= (codex:output-truncation-text-segments ())
   ())

(= (codex:output-truncation-text-segments $items)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (case $head
         (((CodexInputText $text)
           (list:cons
             $text
             (codex:output-truncation-text-segments $tail)))
          ((CodexInputImage $image-url $detail)
           (codex:output-truncation-text-segments $tail)))))))

(= (codex:output-truncation-combine-text-segments $segments)
   (codex:output-truncation-combine-text-segments-from $segments ""))

(= (codex:output-truncation-combine-text-segments-from () $acc)
   $acc)

(= (codex:output-truncation-combine-text-segments-from $segments $acc)
   (let $head (list:first $segments)
     (let $tail (list:rest $segments)
       (let $next
         (if (== $acc "")
             $head
             (str-concat $acc (str-concat "\n" $head)))
         (codex:output-truncation-combine-text-segments-from
           $tail
           $next)))))

(= (codex:output-truncation-image-items ())
   ())

(= (codex:output-truncation-image-items $items)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (case $head
         (((CodexInputText $text)
           (codex:output-truncation-image-items $tail))
          ((CodexInputImage $image-url $detail)
           (list:cons
             $head
             (codex:output-truncation-image-items $tail))))))))

(= (codex:output-truncation-formatted-truncate-text-content-items-with-policy
      $items
      $policy)
   (let $text-segments
     (codex:output-truncation-text-segments $items)
     (if (== $text-segments ())
         (codex:output-truncation-content-items-result
           $items
           CodexAbsent)
         (let $combined
           (codex:output-truncation-combine-text-segments
             $text-segments)
           (if (<= (str-length $combined)
                   (codex:output-truncation-policy-byte-budget
                     $policy))
               (codex:output-truncation-content-items-result
                 $items
                 CodexAbsent)
               (codex:output-truncation-content-items-result
                 (list:append
                   ((CodexInputText
                      (codex:output-truncation-formatted-truncate-text
                        $combined
                        $policy)))
                   (codex:output-truncation-image-items $items))
                 (codex:output-truncation-approx-token-count
                   $combined)))))))

(= (codex:output-truncation-policy-initial-remaining-budget
      (CodexTruncationPolicyBytes $bytes))
   $bytes)

(= (codex:output-truncation-policy-initial-remaining-budget
      (CodexTruncationPolicyTokens $tokens))
   $tokens)

(= (codex:output-truncation-policy-text-cost
      $text
      (CodexTruncationPolicyBytes $bytes))
   (str-length $text))

(= (codex:output-truncation-policy-text-cost
      $text
      (CodexTruncationPolicyTokens $tokens))
   (codex:output-truncation-approx-token-count $text))

(= (codex:output-truncation-policy-with-limit
      (CodexTruncationPolicyBytes $bytes)
      $limit)
   (CodexTruncationPolicyBytes $limit))

(= (codex:output-truncation-policy-with-limit
      (CodexTruncationPolicyTokens $tokens)
      $limit)
   (CodexTruncationPolicyTokens $limit))

(= (codex:output-truncation-omitted-text-items-summary $count)
   (str-concat
     "[omitted "
     (str-concat
       (codex:string-truncate-number-text $count)
       " text items ...]")))

(= (codex:output-truncation-finish-function-output-items
      $out
      $omitted-text-items)
   (if (> $omitted-text-items 0)
       (list:append
         $out
         ((CodexInputText
            (codex:output-truncation-omitted-text-items-summary
              $omitted-text-items))))
       $out))

(= (codex:output-truncation-truncate-function-output-items-with-policy
      $items
      $policy)
   (codex:output-truncation-truncate-function-output-items-with-policy-from
     $items
     $policy
     (codex:output-truncation-policy-initial-remaining-budget
       $policy)
     0
     ()))

(= (codex:output-truncation-truncate-function-output-items-with-policy-from
      ()
      $policy
      $remaining-budget
      $omitted-text-items
      $out)
   (codex:output-truncation-finish-function-output-items
     $out
     $omitted-text-items))

(= (codex:output-truncation-truncate-function-output-items-with-policy-from
      $items
      $policy
      $remaining-budget
      $omitted-text-items
      $out)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (case $head
         (((CodexInputText $text)
           (if (== $remaining-budget 0)
               (codex:output-truncation-truncate-function-output-items-with-policy-from
                 $tail
                 $policy
                 $remaining-budget
                 (+ $omitted-text-items 1)
                 $out)
               (let $cost
                 (codex:output-truncation-policy-text-cost
                   $text
                   $policy)
                 (if (<= $cost $remaining-budget)
                     (codex:output-truncation-truncate-function-output-items-with-policy-from
                       $tail
                       $policy
                       (- $remaining-budget $cost)
                       $omitted-text-items
                       (list:append $out ($head)))
                     (let $snippet
                       (codex:output-truncation-truncate-text
                         $text
                         (codex:output-truncation-policy-with-limit
                           $policy
                           $remaining-budget))
                       (codex:output-truncation-truncate-function-output-items-with-policy-from
                         $tail
                         $policy
                         0
                         (if (== $snippet "")
                             (+ $omitted-text-items 1)
                             $omitted-text-items)
                         (if (== $snippet "")
                             $out
                             (list:append
                               $out
                               ((CodexInputText $snippet))))))))))
          ((CodexInputImage $image-url $detail)
           (codex:output-truncation-truncate-function-output-items-with-policy-from
             $tail
             $policy
             $remaining-budget
             $omitted-text-items
             (list:append $out ($head)))))))))
