; Narrow Rust-faithful core-skills render slice.
;
; This ports:
; - openai-codex/codex-rs/core-skills/src/render.rs
;
; Covered in this increment:
; - `SkillMetadataBudget`
; - `SkillRenderReport`
; - `AvailableSkills` rendering shape
; - default metadata budget selection
; - model-visible skill-line ordering by scope, name, then path
; - full, truncated, and minimum skill-line rendering under a budget
; - truncation/omission warning text
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust accepts a `SkillRenderSideEffects` telemetry handle. This CeTTa slice
;   ports the pure render result and warning behavior only; telemetry emission
;   remains outside this pure boundary until a shared telemetry surface exists.
; - Rust computes token costs from UTF-8 byte lengths and sorts names/paths by
;   Rust string ordering. The current CeTTa string surface exposes character
;   slicing/length, so this slice is byte-identical for ASCII skill names,
;   paths, and descriptions, which are the supported skill metadata surface in
;   this increment. Non-ASCII byte-accurate rendering needs a later byte-string
;   helper before it can be claimed equivalent.

!(import! &self list)
!(import! &self num_format)
!(import! &self str)

(= (codex:default-skill-metadata-char-budget)
   8000)

(= (codex:skill-metadata-context-window-percent)
   2)

(= (codex:skill-description-truncation-warning-threshold-chars)
   10)

(= (codex:skill-render-approx-bytes-per-token)
   4)

(= (codex:skill-description-truncated-warning-prefix)
   "Warning: Exceeded skills context budget. Loaded skill descriptions were truncated by an average of")

(= (codex:skill-descriptions-removed-warning-prefix)
   "Warning: Exceeded skills context budget. All skill descriptions were removed and")

(= (codex:skill-metadata-budget-tokens $limit)
   (CodexSkillMetadataBudgetTokens $limit))

(= (codex:skill-metadata-budget-characters $limit)
   (CodexSkillMetadataBudgetCharacters $limit))

(= (codex:skill-metadata-budget-limit
      (CodexSkillMetadataBudgetTokens $limit))
   $limit)

(= (codex:skill-metadata-budget-limit
      (CodexSkillMetadataBudgetCharacters $limit))
   $limit)

(= (codex:is-skill-metadata-budget-tokens
      (CodexSkillMetadataBudgetTokens $limit))
   True)

(= (codex:is-skill-metadata-budget-tokens
      (CodexSkillMetadataBudgetCharacters $limit))
   False)

(= (codex:skill-render-report
      $total-count
      $included-count
      $omitted-count
      $truncated-description-chars
      $truncated-description-count)
   (CodexSkillRenderReport
     $total-count
     $included-count
     $omitted-count
     $truncated-description-chars
     $truncated-description-count))

(= (codex:skill-render-report-total-count
      (CodexSkillRenderReport
        $total-count
        $included-count
        $omitted-count
        $truncated-description-chars
        $truncated-description-count))
   $total-count)

(= (codex:skill-render-report-included-count
      (CodexSkillRenderReport
        $total-count
        $included-count
        $omitted-count
        $truncated-description-chars
        $truncated-description-count))
   $included-count)

(= (codex:skill-render-report-omitted-count
      (CodexSkillRenderReport
        $total-count
        $included-count
        $omitted-count
        $truncated-description-chars
        $truncated-description-count))
   $omitted-count)

(= (codex:skill-render-report-truncated-description-chars
      (CodexSkillRenderReport
        $total-count
        $included-count
        $omitted-count
        $truncated-description-chars
        $truncated-description-count))
   $truncated-description-chars)

(= (codex:skill-render-report-truncated-description-count
      (CodexSkillRenderReport
        $total-count
        $included-count
        $omitted-count
        $truncated-description-chars
        $truncated-description-count))
   $truncated-description-count)

(= (codex:skill-render-available-skills $skill-lines $report $warning-message)
   (CodexRenderedAvailableSkills $skill-lines $report $warning-message))

(= (codex:skill-render-available-skills-lines
      (CodexRenderedAvailableSkills $skill-lines $report $warning-message))
   $skill-lines)

(= (codex:skill-render-available-skills-report
      (CodexRenderedAvailableSkills $skill-lines $report $warning-message))
   $report)

(= (codex:skill-render-available-skills-warning-message
      (CodexRenderedAvailableSkills $skill-lines $report $warning-message))
   $warning-message)

(= (codex:skill-render-result $skill-lines $report)
   (CodexSkillRenderResult $skill-lines $report))

(= (codex:skill-render-result-lines
      (CodexSkillRenderResult $skill-lines $report))
   $skill-lines)

(= (codex:skill-render-result-report
      (CodexSkillRenderResult $skill-lines $report))
   $report)

(= (codex:skill-line $name $description $path)
   (CodexSkillLine $name $description $path))

(= (codex:skill-line-name
      (CodexSkillLine $name $description $path))
   $name)

(= (codex:skill-line-description
      (CodexSkillLine $name $description $path))
   $description)

(= (codex:skill-line-path
      (CodexSkillLine $name $description $path))
   $path)

(= (codex:rendered-skill-line $line $truncated-chars)
   (CodexRenderedSkillLine $line $truncated-chars))

(= (codex:rendered-skill-line-line
      (CodexRenderedSkillLine $line $truncated-chars))
   $line)

(= (codex:rendered-skill-line-truncated-chars
      (CodexRenderedSkillLine $line $truncated-chars))
   $truncated-chars)

(= (codex:description-budget-line $line $description-char-count $extra-costs)
   (CodexDescriptionBudgetLine $line $description-char-count $extra-costs))

(= (codex:description-budget-line-line
      (CodexDescriptionBudgetLine $line $description-char-count $extra-costs))
   $line)

(= (codex:description-budget-line-description-char-count
      (CodexDescriptionBudgetLine $line $description-char-count $extra-costs))
   $description-char-count)

(= (codex:description-budget-line-extra-costs
      (CodexDescriptionBudgetLine $line $description-char-count $extra-costs))
   $extra-costs)

(= (codex:description-budget-allocation $budget-line $description-chars $extra-cost)
   (CodexDescriptionBudgetAllocation $budget-line $description-chars $extra-cost))

(= (codex:description-budget-allocation-line
      (CodexDescriptionBudgetAllocation $budget-line $description-chars $extra-cost))
   $budget-line)

(= (codex:description-budget-allocation-description-chars
      (CodexDescriptionBudgetAllocation $budget-line $description-chars $extra-cost))
   $description-chars)

(= (codex:description-budget-allocation-extra-cost
      (CodexDescriptionBudgetAllocation $budget-line $description-chars $extra-cost))
   $extra-cost)

(= (codex:description-budget-pass $allocations $remaining $changed)
   (CodexDescriptionBudgetPass $allocations $remaining $changed))

(= (codex:description-budget-pass-allocations
      (CodexDescriptionBudgetPass $allocations $remaining $changed))
   $allocations)

(= (codex:description-budget-pass-remaining
      (CodexDescriptionBudgetPass $allocations $remaining $changed))
   $remaining)

(= (codex:description-budget-pass-changed
      (CodexDescriptionBudgetPass $allocations $remaining $changed))
   $changed)

(= (codex:skill-render-decimal-digit-value "0") 0)
(= (codex:skill-render-decimal-digit-value "1") 1)
(= (codex:skill-render-decimal-digit-value "2") 2)
(= (codex:skill-render-decimal-digit-value "3") 3)
(= (codex:skill-render-decimal-digit-value "4") 4)
(= (codex:skill-render-decimal-digit-value "5") 5)
(= (codex:skill-render-decimal-digit-value "6") 6)
(= (codex:skill-render-decimal-digit-value "7") 7)
(= (codex:skill-render-decimal-digit-value "8") 8)
(= (codex:skill-render-decimal-digit-value "9") 9)

(= (codex:skill-render-decimal-string-to-number $text)
   (if (== $text "")
       0
       (codex:skill-render-decimal-string-to-number-from $text 0 0)))

(= (codex:skill-render-decimal-string-to-number-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:skill-render-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10)
              (codex:skill-render-decimal-digit-value $digit-char))))))

(= (codex:skill-render-normalize-whole-number $value)
   (codex:skill-render-decimal-string-to-number
     (codex:num-format-number-text $value)))

(= (codex:skill-render-floor-div $numerator $denominator)
   (codex:skill-render-normalize-whole-number
     (trunc-math (/ $numerator $denominator))))

(= (codex:skill-render-max $lhs $rhs)
   (if (> $lhs $rhs) $lhs $rhs))

(= (codex:skill-render-saturating-sub $lhs $rhs)
   (if (< $lhs $rhs) 0 (- $lhs $rhs)))

(= (codex:skill-render-approx-token-count-from-bytes $bytes)
   (codex:skill-render-floor-div
     (+ $bytes (- (codex:skill-render-approx-bytes-per-token) 1))
     (codex:skill-render-approx-bytes-per-token)))

(= (codex:skill-metadata-budget-cost
      (CodexSkillMetadataBudgetTokens $limit)
      $text)
   (codex:skill-render-approx-token-count-from-bytes (str-length $text)))

(= (codex:skill-metadata-budget-cost
      (CodexSkillMetadataBudgetCharacters $limit)
      $text)
   (str-length $text))

(= (codex:skill-metadata-budget-cost-from-counts
      (CodexSkillMetadataBudgetTokens $limit)
      $chars
      $bytes)
   (codex:skill-render-approx-token-count-from-bytes $bytes))

(= (codex:skill-metadata-budget-cost-from-counts
      (CodexSkillMetadataBudgetCharacters $limit)
      $chars
      $bytes)
   $chars)

(= (codex:default-skill-metadata-budget $context-window)
   (if (== $context-window CodexAbsent)
       (codex:skill-metadata-budget-characters
         (codex:default-skill-metadata-char-budget))
       (if (> $context-window 0)
           (codex:skill-metadata-budget-tokens
             (codex:skill-render-max
               1
               (codex:skill-render-floor-div
                 (* $context-window
                    (codex:skill-metadata-context-window-percent))
                 100)))
           (codex:skill-metadata-budget-characters
             (codex:default-skill-metadata-char-budget)))))

(= (codex:skill-render-report-average-truncated-description-chars
      (CodexSkillRenderReport
        $total-count
        $included-count
        $omitted-count
        $truncated-description-chars
        $truncated-description-count))
   (if (== $truncated-description-count 0)
       0
       (codex:skill-render-floor-div
         (+ $truncated-description-chars
            (- $truncated-description-count 1))
         $truncated-description-count)))

(= (codex:skill-render-skill-name
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $name)

(= (codex:skill-render-skill-description
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $description)

(= (codex:skill-render-skill-path
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $path)

(= (codex:skill-render-skill-scope
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $scope)

(= (codex:skill-render-scope-rank (CodexSkillScopeSystem)) 0)
(= (codex:skill-render-scope-rank (CodexSkillScopeAdmin)) 1)
(= (codex:skill-render-scope-rank (CodexSkillScopeRepo)) 2)
(= (codex:skill-render-scope-rank (CodexSkillScopeUser)) 3)

(= (codex:skill-render-ascii-rank $char)
   (case $char
     (("-" 45)
      ("." 46)
      ("/" 47)
      ("0" 48)
      ("1" 49)
      ("2" 50)
      ("3" 51)
      ("4" 52)
      ("5" 53)
      ("6" 54)
      ("7" 55)
      ("8" 56)
      ("9" 57)
      ("A" 65)
      ("B" 66)
      ("C" 67)
      ("D" 68)
      ("E" 69)
      ("F" 70)
      ("G" 71)
      ("H" 72)
      ("I" 73)
      ("J" 74)
      ("K" 75)
      ("L" 76)
      ("M" 77)
      ("N" 78)
      ("O" 79)
      ("P" 80)
      ("Q" 81)
      ("R" 82)
      ("S" 83)
      ("T" 84)
      ("U" 85)
      ("V" 86)
      ("W" 87)
      ("X" 88)
      ("Y" 89)
      ("Z" 90)
      ("\\" 92)
      ("_" 95)
      ("a" 97)
      ("b" 98)
      ("c" 99)
      ("d" 100)
      ("e" 101)
      ("f" 102)
      ("g" 103)
      ("h" 104)
      ("i" 105)
      ("j" 106)
      ("k" 107)
      ("l" 108)
      ("m" 109)
      ("n" 110)
      ("o" 111)
      ("p" 112)
      ("q" 113)
      ("r" 114)
      ("s" 115)
      ("t" 116)
      ("u" 117)
      ("v" 118)
      ("w" 119)
      ("x" 120)
      ("y" 121)
      ("z" 122)
      ($other 10000))))

(= (codex:skill-render-text-le $left $right)
   (codex:skill-render-text-le-from $left $right 0))

(= (codex:skill-render-text-le-from $left $right $index)
   (if (>= $index (str-length $left))
       True
       (if (>= $index (str-length $right))
           False
           (let $left-rank
             (codex:skill-render-ascii-rank
               (str-slice $left $index (+ $index 1)))
             (let $right-rank
               (codex:skill-render-ascii-rank
                 (str-slice $right $index (+ $index 1)))
               (if (< $left-rank $right-rank)
                   True
                   (if (> $left-rank $right-rank)
                       False
                       (codex:skill-render-text-le-from
                         $left
                         $right
                         (+ $index 1)))))))))

(= (codex:skill-render-skill-le $left $right)
   (let $left-rank
     (codex:skill-render-scope-rank (codex:skill-render-skill-scope $left))
     (let $right-rank
       (codex:skill-render-scope-rank (codex:skill-render-skill-scope $right))
       (if (< $left-rank $right-rank)
           True
           (if (> $left-rank $right-rank)
               False
               (let $left-name (codex:skill-render-skill-name $left)
                 (let $right-name (codex:skill-render-skill-name $right)
                   (if (== $left-name $right-name)
                       (codex:skill-render-text-le
                         (codex:skill-render-skill-path $left)
                         (codex:skill-render-skill-path $right))
                       (codex:skill-render-text-le
                         $left-name
                         $right-name)))))))))

(= (codex:ordered-skills-for-budget ())
   ())

(= (codex:ordered-skills-for-budget $skills)
   (let $head (list:first $skills)
     (let $tail (list:rest $skills)
       (let $sorted-tail (codex:ordered-skills-for-budget $tail)
         (codex:skill-render-insert-skill $head $sorted-tail)))))

(= (codex:skill-render-insert-skill $skill ())
   ($skill))

(= (codex:skill-render-insert-skill $skill $sorted)
   (let $head (list:first $sorted)
     (let $tail (list:rest $sorted)
       (if (codex:skill-render-skill-le $skill $head)
           (cons-atom $skill $sorted)
           (let $rest
             (codex:skill-render-insert-skill $skill $tail)
             (cons-atom $head $rest))))))

(= (codex:skill-line-from-skill $skill)
   (codex:skill-line
     (codex:skill-render-skill-name $skill)
     (codex:skill-render-skill-description $skill)
     (str-join "/" (str-split "\\" (codex:skill-render-skill-path $skill)))))

(= (codex:skill-lines-from-skills ())
   ())

(= (codex:skill-lines-from-skills $skills)
   (let $head (list:first $skills)
     (let $tail (list:rest $skills)
       (let $line (codex:skill-line-from-skill $head)
         (let $tail-lines (codex:skill-lines-from-skills $tail)
           (cons-atom $line $tail-lines))))))

(= (codex:skill-line-render-with-description
      (CodexSkillLine $name $description $path)
      $rendered-description)
   (if (== $rendered-description "")
       (str-concat
         (str-concat "- " $name)
         (str-concat ": (file: " (str-concat $path ")")))
       (str-concat
         (str-concat "- " $name)
         (str-concat
           ": "
           (str-concat
             $rendered-description
             (str-concat " (file: " (str-concat $path ")")))))))

(= (codex:skill-line-render-full $line)
   (codex:skill-line-render-with-description
     $line
     (codex:skill-line-description $line)))

(= (codex:skill-line-render-minimum $line)
   (codex:skill-line-render-with-description $line ""))

(= (codex:skill-line-description-char-count $line)
   (str-length (codex:skill-line-description $line)))

(= (codex:skill-line-render-with-description-chars $line $description-chars)
   (if (== $description-chars 0)
       (codex:skill-line-render-minimum $line)
       (codex:skill-line-render-with-description
         $line
         (str-slice
           (codex:skill-line-description $line)
           0
           $description-chars))))

(= (codex:skill-render-line-cost $budget $line-text)
   (codex:skill-metadata-budget-cost
     $budget
     (str-concat $line-text "\n")))

(= (codex:skill-line-full-cost $line $budget)
   (codex:skill-render-line-cost
     $budget
     (codex:skill-line-render-full $line)))

(= (codex:skill-line-minimum-cost $line $budget)
   (codex:skill-render-line-cost
     $budget
     (codex:skill-line-render-minimum $line)))

(= (codex:skill-render-lines-full-cost () $budget $used)
   $used)

(= (codex:skill-render-lines-full-cost $skill-lines $budget $used)
   (let $head (list:first $skill-lines)
     (let $tail (list:rest $skill-lines)
       (codex:skill-render-lines-full-cost
         $tail
         $budget
         (+ $used (codex:skill-line-full-cost $head $budget))))))

(= (codex:skill-render-lines-minimum-cost () $budget $used)
   $used)

(= (codex:skill-render-lines-minimum-cost $skill-lines $budget $used)
   (let $head (list:first $skill-lines)
     (let $tail (list:rest $skill-lines)
       (codex:skill-render-lines-minimum-cost
         $tail
         $budget
         (+ $used (codex:skill-line-minimum-cost $head $budget))))))

(= (codex:skill-render-lines-full ())
   ())

(= (codex:skill-render-lines-full $skill-lines)
   (let $head (list:first $skill-lines)
     (let $tail (list:rest $skill-lines)
       (let $line-text (codex:skill-line-render-full $head)
         (let $tail-lines (codex:skill-render-lines-full $tail)
           (cons-atom $line-text $tail-lines))))))

(= (codex:description-budget-line-extra-costs $line $budget)
   (codex:description-budget-line-extra-costs-from
     $line
     $budget
     (codex:skill-line-description-char-count $line)
     (codex:skill-line-minimum-cost $line $budget)
     (+ (str-length (codex:skill-line-render-minimum $line)) 1)
     0
     (0)))

(= (codex:description-budget-line-extra-costs-from
      $line
      $budget
      $description-char-count
      $minimum-cost
      $minimum-counts
      $prefix-chars
      $extra-costs)
   (if (>= $prefix-chars $description-char-count)
       $extra-costs
       (let $next-prefix-chars (+ $prefix-chars 1)
         (let $rendered-counts (+ $minimum-counts (+ $next-prefix-chars 1))
           (let $next-cost
             (codex:skill-metadata-budget-cost-from-counts
               $budget
               $rendered-counts
               $rendered-counts)
             (codex:description-budget-line-extra-costs-from
               $line
               $budget
               $description-char-count
               $minimum-cost
               $minimum-counts
               $next-prefix-chars
               (list:append
                 $extra-costs
                 ((codex:skill-render-saturating-sub
                    $next-cost
                    $minimum-cost)))))))))

(= (codex:description-budget-line-new $line $budget)
   (codex:description-budget-line
     $line
     (codex:skill-line-description-char-count $line)
     (codex:description-budget-line-extra-costs $line $budget)))

(= (codex:description-budget-lines-new () $budget)
   ())

(= (codex:description-budget-lines-new $skill-lines $budget)
   (let $head (list:first $skill-lines)
     (let $tail (list:rest $skill-lines)
       (let $budget-line (codex:description-budget-line-new $head $budget)
         (let $tail-lines (codex:description-budget-lines-new $tail $budget)
           (cons-atom $budget-line $tail-lines))))))

(= (codex:skill-render-list-nth $items $index)
   (if (== $index 0)
       (list:first $items)
       (codex:skill-render-list-nth (list:rest $items) (- $index 1))))

(= (codex:description-budget-allocations-new ())
   ())

(= (codex:description-budget-allocations-new $budget-lines)
   (let $head (list:first $budget-lines)
     (let $tail (list:rest $budget-lines)
       (let $allocation (codex:description-budget-allocation $head 0 0)
         (let $tail-allocations
           (codex:description-budget-allocations-new $tail)
           (cons-atom $allocation $tail-allocations))))))

(= (codex:description-budget-pass-once () $remaining $changed)
   (codex:description-budget-pass () $remaining $changed))

(= (codex:description-budget-pass-once $allocations $remaining $changed)
   (let $allocation (list:first $allocations)
     (let $tail (list:rest $allocations)
       (let $budget-line
         (codex:description-budget-allocation-line $allocation)
         (let $description-chars
           (codex:description-budget-allocation-description-chars $allocation)
           (let $description-count
             (codex:description-budget-line-description-char-count $budget-line)
             (let $current-cost
               (codex:description-budget-allocation-extra-cost $allocation)
               (let $updated-allocation
                 (if (>= $description-chars $description-count)
                     $allocation
                     (let $next-chars (+ $description-chars 1)
                       (let $next-cost
                         (codex:skill-render-list-nth
                           (codex:description-budget-line-extra-costs $budget-line)
                           $next-chars)
                         (let $delta
                           (codex:skill-render-saturating-sub
                             $next-cost
                             $current-cost)
                           (if (<= $delta $remaining)
                               (codex:description-budget-allocation
                                 $budget-line
                                 $next-chars
                                 $next-cost)
                               $allocation)))))
                 (let $updated-remaining
                   (if (== $updated-allocation $allocation)
                       $remaining
                       (codex:skill-render-saturating-sub
                         $remaining
                         (codex:skill-render-saturating-sub
                           (codex:description-budget-allocation-extra-cost
                             $updated-allocation)
                           $current-cost)))
                   (let $updated-changed
                     (if (== $updated-allocation $allocation)
                         $changed
                         True)
                     (let $tail-pass
                       (codex:description-budget-pass-once
                         $tail
                         $updated-remaining
                         $updated-changed)
                       (let $tail-allocations
                         (codex:description-budget-pass-allocations $tail-pass)
                         (codex:description-budget-pass
                           (cons-atom $updated-allocation $tail-allocations)
                           (codex:description-budget-pass-remaining $tail-pass)
                           (codex:description-budget-pass-changed
                             $tail-pass))))))))))))))

(= (codex:description-budget-distribute $allocations $remaining)
   (let $pass (codex:description-budget-pass-once $allocations $remaining False)
     (if (codex:description-budget-pass-changed $pass)
         (codex:description-budget-distribute
           (codex:description-budget-pass-allocations $pass)
           (codex:description-budget-pass-remaining $pass))
         (codex:description-budget-pass-allocations $pass))))

(= (codex:description-budget-allocations-render ())
   ())

(= (codex:description-budget-allocations-render $allocations)
   (let $allocation (list:first $allocations)
     (let $tail (list:rest $allocations)
       (let $budget-line
         (codex:description-budget-allocation-line $allocation)
         (let $line (codex:description-budget-line-line $budget-line)
           (let $description-count
             (codex:description-budget-line-description-char-count $budget-line)
             (let $description-chars
               (codex:description-budget-allocation-description-chars $allocation)
               (let $truncated
                 (codex:skill-render-saturating-sub
                   $description-count
                   $description-chars)
                 (let $rendered
                   (codex:rendered-skill-line
                     (codex:skill-line-render-with-description-chars
                       $line
                       $description-chars)
                     $truncated)
                   (let $tail-rendered
                     (codex:description-budget-allocations-render $tail)
                     (cons-atom $rendered $tail-rendered)))))))))))

(= (codex:render-lines-with-description-budget $budget $skill-lines $limit)
   (codex:description-budget-allocations-render
     (codex:description-budget-distribute
       (codex:description-budget-allocations-new
         (codex:description-budget-lines-new $skill-lines $budget))
       $limit)))

(= (codex:sum-description-truncation $rendered)
   (codex:sum-description-truncation-from $rendered 0 0))

(= (codex:sum-description-truncation-from () $chars $count)
   (CodexSkillRenderTruncationSum $chars $count))

(= (codex:sum-description-truncation-from $rendered $chars $count)
   (let $head (list:first $rendered)
     (let $tail (list:rest $rendered)
       (let $truncated (codex:rendered-skill-line-truncated-chars $head)
         (if (== $truncated 0)
             (codex:sum-description-truncation-from $tail $chars $count)
             (codex:sum-description-truncation-from
               $tail
               (+ $chars $truncated)
               (+ $count 1)))))))

(= (codex:skill-render-truncation-sum-chars
      (CodexSkillRenderTruncationSum $chars $count))
   $chars)

(= (codex:skill-render-truncation-sum-count
      (CodexSkillRenderTruncationSum $chars $count))
   $count)

(= (codex:rendered-skill-lines-to-lines ())
   ())

(= (codex:rendered-skill-lines-to-lines $rendered)
   (let $head (list:first $rendered)
     (let $tail (list:rest $rendered)
       (let $line (codex:rendered-skill-line-line $head)
         (let $tail-lines (codex:rendered-skill-lines-to-lines $tail)
           (cons-atom $line $tail-lines))))))

(= (codex:render-minimum-skill-lines-until-budget
      $budget
      $skill-lines
      $total-count)
   (codex:render-minimum-skill-lines-until-budget-from
     $budget
     $skill-lines
     $total-count
     0
     ()
     0
     0
     0))

(= (codex:render-minimum-skill-lines-until-budget-from
      $budget
      ()
      $total-count
      $used
      $included
      $omitted-count
      $truncated-description-chars
      $truncated-description-count)
   (codex:skill-render-result
     $included
     (codex:skill-render-report
       $total-count
       (list:len $included)
       $omitted-count
       $truncated-description-chars
       $truncated-description-count)))

(= (codex:render-minimum-skill-lines-until-budget-from
      $budget
      $skill-lines
      $total-count
      $used
      $included
      $omitted-count
      $truncated-description-chars
      $truncated-description-count)
   (let $line (list:first $skill-lines)
     (let $tail (list:rest $skill-lines)
       (let $line-cost (codex:skill-line-minimum-cost $line $budget)
         (let $description-char-count
           (codex:skill-line-description-char-count $line)
           (let $fits
             (<= (+ $used $line-cost)
                 (codex:skill-metadata-budget-limit $budget))
             (codex:render-minimum-skill-lines-until-budget-from
               $budget
               $tail
               $total-count
               (if $fits (+ $used $line-cost) $used)
               (if $fits
                   (list:append
                     $included
                     ((codex:skill-line-render-minimum $line)))
                   $included)
               (if $fits $omitted-count (+ $omitted-count 1))
               (+ $truncated-description-chars $description-char-count)
               (if (> $description-char-count 0)
                   (+ $truncated-description-count 1)
                   $truncated-description-count))))))))

(= (codex:render-skill-lines $skills $budget)
   (let $ordered-skills (codex:ordered-skills-for-budget $skills)
     (let $skill-lines (codex:skill-lines-from-skills $ordered-skills)
       (let $full-cost
         (codex:skill-render-lines-full-cost $skill-lines $budget 0)
         (if (<= $full-cost (codex:skill-metadata-budget-limit $budget))
             (codex:skill-render-result
               (codex:skill-render-lines-full $skill-lines)
               (codex:skill-render-report
                 (list:len $skills)
                 (list:len $skill-lines)
                 0
                 0
                 0))
             (let $minimum-cost
               (codex:skill-render-lines-minimum-cost $skill-lines $budget 0)
               (if (<= $minimum-cost
                       (codex:skill-metadata-budget-limit $budget))
                   (let $rendered
                     (codex:render-lines-with-description-budget
                       $budget
                       $skill-lines
                       (- (codex:skill-metadata-budget-limit $budget)
                          $minimum-cost))
                     (let $truncation
                       (codex:sum-description-truncation $rendered)
                       (codex:skill-render-result
                         (codex:rendered-skill-lines-to-lines $rendered)
                         (codex:skill-render-report
                           (list:len $skills)
                           (list:len $skill-lines)
                           0
                           (codex:skill-render-truncation-sum-chars
                             $truncation)
                           (codex:skill-render-truncation-sum-count
                             $truncation)))))
                   (codex:render-minimum-skill-lines-until-budget
                     $budget
                     $skill-lines
                     (list:len $skills)))))))))

(= (codex:skill-render-budget-warning-prefix
      (CodexSkillMetadataBudgetTokens $limit)
      $prefix)
   (if (== $prefix (codex:skill-descriptions-removed-warning-prefix))
       "Warning: Exceeded skills context budget of 2%. All skill descriptions were removed and"
       "Warning: Exceeded skills context budget of 2%. Loaded skill descriptions were truncated by an average of"))

(= (codex:skill-render-budget-warning-prefix
      (CodexSkillMetadataBudgetCharacters $limit)
      $prefix)
   $prefix)

(= (codex:skill-render-warning-message $budget $report)
   (let $omitted-count
     (codex:skill-render-report-omitted-count $report)
     (if (> $omitted-count 0)
         (let $skill-word (if (== $omitted-count 1) "skill" "skills")
           (let $verb (if (== $omitted-count 1) "was" "were")
             (str-concat
               (str-concat
                 (str-concat
                   (str-concat
                     (str-concat
                       (codex:skill-render-budget-warning-prefix
                         $budget
                         (codex:skill-descriptions-removed-warning-prefix))
                       " ")
                     (codex:num-format-number-text $omitted-count))
                   (str-concat " additional " $skill-word))
                 (str-concat " " $verb))
               " not included in the model-visible skills list.")))
         (let $average
           (codex:skill-render-report-average-truncated-description-chars
             $report)
           (if (> $average
                  (codex:skill-description-truncation-warning-threshold-chars))
               (str-concat
                 (str-concat
                   (str-concat
                     (codex:skill-render-budget-warning-prefix
                       $budget
                       (codex:skill-description-truncated-warning-prefix))
                     " ")
                   (codex:num-format-number-text $average))
                 " characters per skill.")
               CodexAbsent)))))

(= (codex:build-available-skills $skills $budget)
   (if (== $skills ())
       CodexAbsent
       (let $rendered (codex:render-skill-lines $skills $budget)
         (let $report (codex:skill-render-result-report $rendered)
           (codex:skill-render-available-skills
             (codex:skill-render-result-lines $rendered)
             $report
             (codex:skill-render-warning-message $budget $report))))))
