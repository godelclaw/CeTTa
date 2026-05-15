; Narrow Rust-faithful num-format slice for the restarted Codex port.
;
; This ports:
; - openai-codex/codex-rs/protocol/src/num_format.rs
;
; Required slice-local deviation from Rust, documented for later audit:
; - Rust prefers locale-aware ICU decimal formatting and falls back to `en-US`
;   when host locale discovery or formatter construction fails. The current
;   CeTTa restart surface has no ICU/sys-locale layer, so this slice ports the
;   guaranteed visible fallback behavior directly: comma separators with `.` as
;   the decimal point, matching Rust's `en-US` fallback and unit tests.

!(import! &self str)

(= (codex:num-format-strip-trailing-dot-zero $text)
   (let $len (str-length $text)
     (if (< $len 2)
         $text
         (if (== (str-slice $text (- $len 2) $len) ".0")
             (str-slice $text 0 (- $len 2))
             $text))))

(= (codex:num-format-number-text $value)
   (codex:num-format-strip-trailing-dot-zero (format-args "{}" ($value))))

(= (codex:num-format-pad-left-to-width $text $width)
   (if (>= (str-length $text) $width)
       $text
       (codex:num-format-pad-left-to-width
         (str-concat "0" $text)
         $width)))

(= (codex:format-with-separators-positive $n)
   (if (< $n 1000)
       (codex:num-format-number-text $n)
       (let $prefix
         (trunc-math (/ $n 1000))
         (let $suffix (% $n 1000)
           (str-concat
             (codex:format-with-separators-positive $prefix)
             (str-concat
               ","
               (codex:num-format-pad-left-to-width
                 (codex:num-format-number-text $suffix)
                 3)))))))

(= (codex:format-with-separators $n)
   (if (< $n 0)
       (str-concat
         "-"
         (codex:format-with-separators-positive (- 0 $n)))
       (codex:format-with-separators-positive $n)))

(= (codex:num-format-pow10 $digits)
   (pow-math 10 $digits))

(= (codex:num-format-round-to-int $value)
   (trunc-math (round-math $value)))

(= (codex:num-format-format-scaled-integer $scaled $frac-digits)
   (if (== $frac-digits 0)
       (codex:format-with-separators $scaled)
       (let $frac-scale (codex:num-format-pow10 $frac-digits)
         (let $whole
           (trunc-math (/ $scaled $frac-scale))
           (let $fractional (% $scaled $frac-scale)
             (str-concat
               (codex:format-with-separators $whole)
               (str-concat
                 "."
                 (codex:num-format-pad-left-to-width
                   (codex:num-format-number-text $fractional)
                   $frac-digits))))))))

(= (codex:num-format-format-scaled $n $scale $frac-digits)
   (let $pow10 (codex:num-format-pow10 $frac-digits)
     (let $scaled
       (codex:num-format-round-to-int (/ (* $n $pow10) $scale))
       (codex:num-format-format-scaled-integer $scaled $frac-digits))))

(= (codex:num-format-format-unit $n $scale $suffix)
   (let $hundredths-rounded
     (codex:num-format-round-to-int (/ (* 100 $n) $scale))
     (if (< $hundredths-rounded 1000)
         (str-concat
           (codex:num-format-format-scaled $n $scale 2)
           $suffix)
         (let $tenths-rounded
           (codex:num-format-round-to-int (/ (* 10 $n) $scale))
           (if (< $tenths-rounded 1000)
               (str-concat
                 (codex:num-format-format-scaled $n $scale 1)
                 $suffix)
               (let $ones-rounded
                 (codex:num-format-round-to-int (/ $n $scale))
                 (if (< $ones-rounded 1000)
                     (str-concat
                       (codex:num-format-format-scaled $n $scale 0)
                       $suffix)
                     CodexAbsent)))))))

(= (codex:format-si-suffix $n)
   (let $clamped (if (< $n 0) 0 $n)
     (if (< $clamped 1000)
         (codex:format-with-separators $clamped)
         (let $thousands
           (codex:num-format-format-unit $clamped 1000 "K")
           (if (not (== $thousands CodexAbsent))
               $thousands
               (let $millions
                 (codex:num-format-format-unit $clamped 1000000 "M")
                 (if (not (== $millions CodexAbsent))
                     $millions
                     (let $billions
                       (codex:num-format-format-unit $clamped 1000000000 "G")
                       (if (not (== $billions CodexAbsent))
                           $billions
                           (str-concat
                             (codex:format-with-separators
                               (codex:num-format-round-to-int
                                 (/ $clamped 1000000000)))
                             "G"))))))))))
