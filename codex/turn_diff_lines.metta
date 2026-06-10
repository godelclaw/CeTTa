; Rust-faithful turn diff tracker slice: unified line-diff engine.
;
; This ports the similar::TextDiff usage surface from:
; - openai-codex/codex-rs/core/src/turn_diff_tracker.rs
;
; Split out of turn_diff_tracker.metta because the evaluator degrades on
; large single modules (see deviation notes in turn_diff_tracker.metta,
; which documents all slice-local Rust deviations).

!(import! &self list)
!(import! &self str)

(= (codex:turn-diff-context-radius)
   3)

; --- line splitting -----------------------------------------------------

(= (codex:turn-diff-ends-with-newline $text)
   (str-ends-with? $text "\n"))

(= (codex:turn-diff-drop-trailing-empty $parts)
   (let $rev (list:reverse $parts)
     (let ($head $tail) (decons-atom $rev)
       (if (== $head "")
           (list:reverse $tail)
           $parts))))

(= (codex:turn-diff-split-lines $text)
   (if (== $text "")
       ()
       (codex:turn-diff-drop-trailing-empty (str-split "\n" $text))))

; --- LCS line diff ------------------------------------------------------

(= (codex:turn-diff-max $a $b)
   (if (> $a $b) $a $b))

(= (codex:turn-diff-lcs-zero-row $m)
   (list:repeat (+ $m 1) 0))

(= (codex:turn-diff-lcs-rows $left $right)
   (case (collapse (codex:turn-diff-lcs-zero-row (list:len $right)))
     ((($zero-row)
       (codex:turn-diff-lcs-rows-acc
         (list:reverse $left)
         $right
         ($zero-row))))))

(= (codex:turn-diff-lcs-rows-acc $left-rev $right $acc)
   (if (== $left-rev ())
       $acc
       (let ($l-line $rest) (decons-atom $left-rev)
         (let $next-row (list:first $acc)
           (case (collapse
                   (codex:turn-diff-lcs-row $l-line $right $next-row))
             ((($row)
               (codex:turn-diff-lcs-rows-acc
                 $rest
                 $right
                 (cons-atom $row $acc)))))))))

(= (codex:turn-diff-lcs-row $l-line $right $next-row)
   (codex:turn-diff-lcs-row-acc
     $l-line
     (list:reverse $right)
     (list:reverse $next-row)
     (0)))

(= (codex:turn-diff-lcs-row-acc $l-line $rrev $nrev $acc)
   (if (== $rrev ())
       $acc
       (let ($r-line $r-rest) (decons-atom $rrev)
         (let ($next-j1 $n-rest) (decons-atom $nrev)
           (let $next-j (list:first $n-rest)
             (let $row-j1 (list:first $acc)
               (let $value (if (== $l-line $r-line)
                               (+ $next-j1 1)
                               (codex:turn-diff-max $next-j $row-j1))
                 (codex:turn-diff-lcs-row-acc
                   $l-line
                   $r-rest
                   $n-rest
                   (cons-atom $value $acc)))))))))

(= (codex:turn-diff-line-ops $left $right)
   (case (collapse (codex:turn-diff-lcs-rows $left $right))
     ((($rows)
       (codex:turn-diff-ops-at $left $right $rows 0 0)))))

(= (codex:turn-diff-ops-tail-inserts $right $j)
   (if (>= $j (list:len $right))
       ()
       (case (collapse (list:at $right $j))
         ((($line)
           (case (collapse (codex:turn-diff-ops-tail-inserts $right (+ $j 1)))
             ((($rest)
               (cons-atom (CodexTurnDiffOpInsert $line) $rest)))))))))

(= (codex:turn-diff-ops-delete-step $left $right $rows $i $j)
   (case (collapse (list:at $left $i))
     ((($line)
       (case (collapse
               (codex:turn-diff-ops-at $left $right $rows (+ $i 1) $j))
         ((($rest)
           (cons-atom (CodexTurnDiffOpDelete $line) $rest))))))))

(= (codex:turn-diff-ops-insert-step $left $right $rows $i $j)
   (case (collapse (list:at $right $j))
     ((($line)
       (case (collapse
               (codex:turn-diff-ops-at $left $right $rows $i (+ $j 1)))
         ((($rest)
           (cons-atom (CodexTurnDiffOpInsert $line) $rest))))))))

(= (codex:turn-diff-ops-equal-step $left $right $rows $i $j)
   (case (collapse (list:at $left $i))
     ((($line)
       (case (collapse
               (codex:turn-diff-ops-at $left $right $rows (+ $i 1) (+ $j 1)))
         ((($rest)
           (cons-atom (CodexTurnDiffOpEqual $line) $rest))))))))

(= (codex:turn-diff-ops-at $left $right $rows $i $j)
   (if (>= $i (list:len $left))
       (codex:turn-diff-ops-tail-inserts $right $j)
       (if (>= $j (list:len $right))
           (codex:turn-diff-ops-delete-step $left $right $rows $i $j)
           (if (== (list:at $left $i) (list:at $right $j))
               (codex:turn-diff-ops-equal-step $left $right $rows $i $j)
               (if (>= (list:at (list:at $rows (+ $i 1)) $j)
                       (list:at (list:at $rows $i) (+ $j 1)))
                   (codex:turn-diff-ops-delete-step $left $right $rows $i $j)
                   (codex:turn-diff-ops-insert-step
                     $left $right $rows $i $j))))))

(= (codex:turn-diff-op-is-equal (CodexTurnDiffOpEqual $line))
   True)

(= (codex:turn-diff-op-is-equal (CodexTurnDiffOpDelete $line))
   False)

(= (codex:turn-diff-op-is-equal (CodexTurnDiffOpInsert $line))
   False)

(= (codex:turn-diff-op-consumes-old (CodexTurnDiffOpEqual $line))
   True)

(= (codex:turn-diff-op-consumes-old (CodexTurnDiffOpDelete $line))
   True)

(= (codex:turn-diff-op-consumes-old (CodexTurnDiffOpInsert $line))
   False)

(= (codex:turn-diff-op-consumes-new (CodexTurnDiffOpEqual $line))
   True)

(= (codex:turn-diff-op-consumes-new (CodexTurnDiffOpDelete $line))
   False)

(= (codex:turn-diff-op-consumes-new (CodexTurnDiffOpInsert $line))
   True)

(= (codex:turn-diff-op-prefix (CodexTurnDiffOpEqual $line))
   " ")

(= (codex:turn-diff-op-prefix (CodexTurnDiffOpDelete $line))
   "-")

(= (codex:turn-diff-op-prefix (CodexTurnDiffOpInsert $line))
   "+")

(= (codex:turn-diff-op-line (CodexTurnDiffOpEqual $line))
   $line)

(= (codex:turn-diff-op-line (CodexTurnDiffOpDelete $line))
   $line)

(= (codex:turn-diff-op-line (CodexTurnDiffOpInsert $line))
   $line)

; --- hunk grouping ------------------------------------------------------

(= (codex:turn-diff-change-indices $ops)
   (codex:turn-diff-change-indices-at $ops 0))

(= (codex:turn-diff-change-indices-at $ops $i)
   (if (== $ops ())
       ()
       (let ($head $tail) (decons-atom $ops)
         (if (codex:turn-diff-op-is-equal $head)
             (codex:turn-diff-change-indices-at $tail (+ $i 1))
             (case (collapse (codex:turn-diff-change-indices-at $tail (+ $i 1)))
               ((($rest)
                 (cons-atom $i $rest))))))))

(= (codex:turn-diff-clamp-low $value)
   (if (< $value 0) 0 $value))

(= (codex:turn-diff-clamp-high $value $max)
   (if (> $value $max) $max $value))

(= (codex:turn-diff-intervals $indices $len $radius)
   (codex:turn-diff-intervals-acc $indices $len $radius ()))

(= (codex:turn-diff-intervals-acc $indices $len $radius $acc)
   (if (== $indices ())
       (list:reverse $acc)
       (let ($c $rest) (decons-atom $indices)
         (let $lo (codex:turn-diff-clamp-low (- $c $radius))
           (let $hi (codex:turn-diff-clamp-high (+ $c $radius) (- $len 1))
             (if (== $acc ())
                 (codex:turn-diff-intervals-acc $rest $len $radius (($lo $hi)))
                 (let ($last $older) (decons-atom $acc)
                   (let ($l $h) $last
                     (if (<= $lo (+ $h 1))
                         (let $merged-hi (codex:turn-diff-max $h $hi)
                           (codex:turn-diff-intervals-acc
                             $rest $len $radius
                             (cons-atom ($l $merged-hi) $older)))
                         (codex:turn-diff-intervals-acc
                           $rest $len $radius
                           (cons-atom ($lo $hi) $acc)))))))))))

(= (codex:turn-diff-count-old-before $ops $end)
   (codex:turn-diff-count-old-before-at $ops $end 0 0))

(= (codex:turn-diff-count-old-before-at $ops $end $i $count)
   (if (>= $i $end)
       $count
       (codex:turn-diff-count-old-before-at
         $ops $end (+ $i 1)
         (if (codex:turn-diff-op-consumes-old (list:at $ops $i))
             (+ $count 1)
             $count))))

(= (codex:turn-diff-count-new-before $ops $end)
   (codex:turn-diff-count-new-before-at $ops $end 0 0))

(= (codex:turn-diff-count-new-before-at $ops $end $i $count)
   (if (>= $i $end)
       $count
       (codex:turn-diff-count-new-before-at
         $ops $end (+ $i 1)
         (if (codex:turn-diff-op-consumes-new (list:at $ops $i))
             (+ $count 1)
             $count))))

(= (codex:turn-diff-range-str $start $count)
   (if (== $count 1)
       (format-args "{}" ($start))
       (format-args "{},{}" ($start $count))))

(= (codex:turn-diff-hunk-start $before $count)
   (if (== $count 0)
       $before
       (+ $before 1)))

; --- hunk rendering -----------------------------------------------------

; Renders ops[lo..hi] tracking 1-based old/new line cursors so the
; missing-trailing-newline markers land after the final line of a side.
(= (codex:turn-diff-render-hunk-lines
      $ops $i $hi
      $old-num $new-num
      $old-total $new-total
      $left-nl $right-nl
      $acc)
   (if (> $i $hi)
       $acc
       (let $op (list:at $ops $i)
         (let $old-next (if (codex:turn-diff-op-consumes-old $op)
                            (+ $old-num 1)
                            $old-num)
           (let $new-next (if (codex:turn-diff-op-consumes-new $op)
                              (+ $new-num 1)
                              $new-num)
             (let $line-text
               (str-concat
                 (str-concat (codex:turn-diff-op-prefix $op)
                             (codex:turn-diff-op-line $op))
                 "\n")
               (let $marker
                 (codex:turn-diff-newline-marker
                   $op $old-next $new-next
                   $old-total $new-total $left-nl $right-nl)
                 (codex:turn-diff-render-hunk-lines
                   $ops (+ $i 1) $hi
                   $old-next $new-next
                   $old-total $new-total
                   $left-nl $right-nl
                   (str-concat (str-concat $acc $line-text) $marker)))))))))

(= (codex:turn-diff-newline-marker
      $op $old-next $new-next $old-total $new-total $left-nl $right-nl)
   (if (if (codex:turn-diff-op-consumes-old $op)
           (if (== $old-next $old-total)
               (if $left-nl False True)
               False)
           False)
       "\\ No newline at end of file\n"
       (if (if (codex:turn-diff-op-consumes-new $op)
               (if (== $new-next $new-total)
                   (if $right-nl False True)
                   False)
               False)
           "\\ No newline at end of file\n"
           "")))

(= (codex:turn-diff-render-hunk
      $ops $interval $old-total $new-total $left-nl $right-nl)
   (let ($lo $hi) $interval
     (let $old-before (codex:turn-diff-count-old-before $ops $lo)
       (let $new-before (codex:turn-diff-count-new-before $ops $lo)
         (let $old-count (- (codex:turn-diff-count-old-before $ops (+ $hi 1))
                            $old-before)
           (let $new-count (- (codex:turn-diff-count-new-before $ops (+ $hi 1))
                              $new-before)
             (case (collapse
                     (codex:turn-diff-range-str
                       (codex:turn-diff-hunk-start $old-before $old-count)
                       $old-count))
               ((($old-range)
                 (case (collapse
                         (codex:turn-diff-range-str
                           (codex:turn-diff-hunk-start $new-before $new-count)
                           $new-count))
                   ((($new-range)
                     (codex:turn-diff-render-hunk-lines
                       $ops $lo $hi
                       $old-before $new-before
                       $old-total $new-total
                       $left-nl $right-nl
                       (format-args "@@ -{} +{} @@\n"
                                    ($old-range $new-range)))))))))))))))

(= (codex:turn-diff-render-hunks
      $ops $intervals $old-total $new-total $left-nl $right-nl $acc)
   (if (== $intervals ())
       $acc
       (let ($head $tail) (decons-atom $intervals)
         (codex:turn-diff-render-hunks
           $ops $tail $old-total $new-total $left-nl $right-nl
           (str-concat
             $acc
             (codex:turn-diff-render-hunk
               $ops $head $old-total $new-total $left-nl $right-nl))))))

; The renderer threads an accumulator prefix instead of post-concatenating
; its result: collapsing the deeply nested rendered string from an outer
; call loses the value (same evaluator behavior as the known-red notes),
; and prefix threading also mirrors Rust's aggregated.push_str flow.
(= (codex:turn-diff-unified-with-prefix
      $prefix $left-text $right-text $old-header $new-header)
   (case (collapse (codex:turn-diff-split-lines $left-text))
     ((($left-lines)
       (case (collapse (codex:turn-diff-split-lines $right-text))
         ((($right-lines)
           (case (collapse
                   (codex:turn-diff-line-ops $left-lines $right-lines))
             ((($ops)
               (case (collapse (codex:turn-diff-change-indices $ops))
                 ((($indices)
                   (case (collapse
                           (codex:turn-diff-intervals
                             $indices
                             (list:len $ops)
                             (codex:turn-diff-context-radius)))
                     ((($intervals)
                       (if (== $intervals ())
                           $prefix
                           (codex:turn-diff-render-hunks
                             $ops
                             $intervals
                             (list:len $left-lines)
                             (list:len $right-lines)
                             (codex:turn-diff-ends-with-newline $left-text)
                             (codex:turn-diff-ends-with-newline $right-text)
                             (str-concat
                               $prefix
                               (format-args
                                 "--- {}\n+++ {}\n"
                                 ($old-header $new-header)))))))))))))))))))))

(= (codex:turn-diff-unified $left-text $right-text $old-header $new-header)
   (codex:turn-diff-unified-with-prefix
     "" $left-text $right-text $old-header $new-header))

