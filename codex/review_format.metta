; Narrow Rust-faithful review-format slice.
;
; This ports the pure string-formatting behavior from:
; - openai-codex/codex-rs/core/src/review_format.rs
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores review code locations as `PathBuf`. The current CeTTa slice
;   carries the same visible value as a plain path string.
; - Rust uses `str::lines()`. CeTTa's native `str-split "\n"` preserves a
;   trailing empty segment, so this slice normalizes the split to keep Rust's
;   trailing-newline behavior and trims `\r` from CRLF lines.

!(import! &self list)
!(import! &self protocol)
!(import! &self str)

(= (codex:review-fallback-message)
   "Reviewer failed to output a response.")

(= (codex:format-review-location $item)
   (let $code-location (codex:review-finding-code-location $item)
     (let $path
       (codex:review-code-location-absolute-file-path $code-location)
       (let $line-range
         (codex:review-code-location-line-range $code-location)
         (format-args
           "{}:{}-{}"
           ($path
            (codex:review-line-range-start $line-range)
            (codex:review-line-range-end $line-range)))))))

(= (codex:review-strip-trailing-cr $text)
   (if (str-ends-with? $text "\r")
       (str-slice $text 0 (- (str-length $text) 1))
       $text))

(= (codex:review-normalize-split-lines () $drop-final-empty)
   ())

(= (codex:review-normalize-split-lines $parts $drop-final-empty)
   (let ($head $tail) (decons-atom $parts)
     (if (== $tail ())
         (if (and $drop-final-empty (== $head ""))
             ()
             ((codex:review-strip-trailing-cr $head)))
         (let $rest
           (codex:review-normalize-split-lines $tail $drop-final-empty)
           (cons-atom (codex:review-strip-trailing-cr $head) $rest)))))

(= (codex:review-body-lines $body)
   (if (== $body "")
       ()
       (codex:review-normalize-split-lines
         (str-split "\n" $body)
         (str-ends-with? $body "\n"))))

(= (codex:review-indent-lines ())
   ())

(= (codex:review-indent-lines $lines)
   (let ($head $tail) (decons-atom $lines)
     (let $rest (codex:review-indent-lines $tail)
       (cons-atom (str-concat "  " $head) $rest))))

(= (codex:review-selection-head CodexAbsent)
   CodexAbsent)

(= (codex:review-selection-head ())
   CodexAbsent)

(= (codex:review-selection-head $selection)
   (list:first $selection))

(= (codex:review-selection-tail CodexAbsent)
   CodexAbsent)

(= (codex:review-selection-tail ())
   ())

(= (codex:review-selection-tail $selection)
   (list:rest $selection))

(= (codex:review-finding-line $item)
   (format-args
     "- {} — {}"
     ((codex:review-finding-title $item)
      (codex:format-review-location $item))))

(= (codex:review-finding-line $item $selection-head)
   (let $checked
     (if (== $selection-head CodexAbsent)
         True
         $selection-head)
     (let $marker (if $checked "[x]" "[ ]")
       (format-args
         "- {} {} — {}"
         ($marker
          (codex:review-finding-title $item)
          (codex:format-review-location $item))))))

(= (codex:review-finding-block-lines () $selection)
   ())

(= (codex:review-finding-block-lines $findings $selection)
   (let ($head $tail) (decons-atom $findings)
     (let $selection-head (codex:review-selection-head $selection)
       (let $selection-tail (codex:review-selection-tail $selection)
         (let $item-line
           (if (== $selection CodexAbsent)
               (codex:review-finding-line $head)
               (codex:review-finding-line $head $selection-head))
           (let $body-lines
             (codex:review-indent-lines
               (codex:review-body-lines
                 (codex:review-finding-body $head)))
             (let $tail-lines
               (codex:review-finding-block-lines $tail $selection-tail)
               (list:append
                 (list:append
                   ("")
                   ($item-line))
                 (list:append $body-lines $tail-lines)))))))))

(= (codex:format-review-findings-block $findings)
   (codex:format-review-findings-block $findings CodexAbsent))

(= (codex:format-review-findings-block $findings $selection)
   (let $header
     (if (> (list:len $findings) 1)
         "Full review comments:"
         "Review comment:")
     (str-join
       "\n"
       (list:append
         (list:append
           ("")
           ($header))
         (codex:review-finding-block-lines $findings $selection)))))

(= (codex:render-review-output-text $output)
   (let $explanation
     (str-trim (codex:review-output-event-overall-explanation $output))
     (let $findings (codex:review-output-event-findings $output)
       (if (and (== $explanation "") (== $findings ()))
           (codex:review-fallback-message)
           (if (== $findings ())
               $explanation
               (let $findings-text
                 (str-trim (codex:format-review-findings-block $findings))
                 (if (== $explanation "")
                     $findings-text
                     (str-concat
                       (str-concat $explanation "\n\n")
                       $findings-text))))))))
