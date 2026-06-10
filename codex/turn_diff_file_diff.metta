; Rust-faithful turn diff tracker slice: per-file diff assembly.
;
; This ports the get_file_diff/get_unified_diff assembly surface from:
; - openai-codex/codex-rs/core/src/turn_diff_tracker.rs
;
; Split out of turn_diff_tracker.metta because the evaluator degrades on
; large single modules (see deviation notes in turn_diff_tracker.metta,
; which documents all slice-local Rust deviations).

!(import! &self list)
!(import! &self str)
!(import! &self turn_diff_lines)

; --- constants ---------------------------------------------------------

(= (codex:turn-diff-zero-oid)
   "0000000000000000000000000000000000000000")

(= (codex:turn-diff-dev-null)
   "/dev/null")


; --- file modes --------------------------------------------------------

(= (codex:turn-diff-file-mode-regular)
   (CodexTurnDiffFileModeRegular))

(= (codex:turn-diff-file-mode-executable)
   (CodexTurnDiffFileModeExecutable))

(= (codex:turn-diff-file-mode-symlink)
   (CodexTurnDiffFileModeSymlink))

(= (codex:turn-diff-file-mode-str (CodexTurnDiffFileModeRegular))
   "100644")

(= (codex:turn-diff-file-mode-str (CodexTurnDiffFileModeExecutable))
   "100755")

(= (codex:turn-diff-file-mode-str (CodexTurnDiffFileModeSymlink))
   "120000")

; --- blobs -------------------------------------------------------------

(= (codex:turn-diff-blob-text $text)
   (CodexTurnDiffBlobText $text))

; Binary blobs carry an opaque content token: Rust compares raw bytes in
; the identical-content fast path, so distinct binary contents must compare
; unequal here too.
(= (codex:turn-diff-blob-binary $token)
   (CodexTurnDiffBlobBinary $token))

(= (codex:turn-diff-blob-is-text (CodexTurnDiffBlobText $text))
   True)

(= (codex:turn-diff-blob-is-text (CodexTurnDiffBlobBinary $token))
   False)

(= (codex:turn-diff-blob-text-value (CodexTurnDiffBlobText $text))
   $text)


; --- string ordering ----------------------------------------------------

; Deviation: explicit printable-ASCII rank table; see header.
(= (codex:turn-diff-char-table)
   " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~")

; The char-table call is materialized first; passing the zero-arg helper
; straight into str-find loses its value after earlier evaluations (same
; evaluator behavior documented in specs/codex_known_red_surfaces.md).
(= (codex:turn-diff-char-rank $ch)
   (case (collapse (codex:turn-diff-char-table))
     ((($table)
       (case (collapse (str-find $table $ch))
         ((()
           -1)
          (($rank)
           $rank)))))))

(= (codex:turn-diff-str-lt $a $b)
   (codex:turn-diff-str-lt-at $a $b 0))

(= (codex:turn-diff-str-lt-at $a $b $i)
   (if (>= $i (str-length $a))
       (if (>= (str-length $a) (str-length $b))
           False
           True)
       (if (>= $i (str-length $b))
           False
           (let $ca (str-slice $a $i (+ $i 1))
             (let $cb (str-slice $b $i (+ $i 1))
               (if (== $ca $cb)
                   (codex:turn-diff-str-lt-at $a $b (+ $i 1))
                   (case (collapse (codex:turn-diff-char-rank $ca))
                     ((($rank-a)
                       (case (collapse (codex:turn-diff-char-rank $cb))
                         ((($rank-b)
                           (< $rank-a $rank-b)))))))))))))

; --- per-file diff assembly ----------------------------------------------

(= (codex:turn-diff-effective-blob $present $blob)
   (if $present $blob CodexAbsent))

(= (codex:turn-diff-blob-text-or-empty CodexAbsent)
   "")

(= (codex:turn-diff-blob-text-or-empty (CodexTurnDiffBlobText $text))
   $text)

(= (codex:turn-diff-blob-is-text-option CodexAbsent)
   False)

(= (codex:turn-diff-blob-is-text-option (CodexTurnDiffBlobText $text))
   True)

(= (codex:turn-diff-blob-is-text-option (CodexTurnDiffBlobBinary $token))
   False)

(= (codex:turn-diff-blob-present CodexAbsent)
   False)

(= (codex:turn-diff-blob-present (CodexTurnDiffBlobText $text))
   True)

(= (codex:turn-diff-blob-present (CodexTurnDiffBlobBinary $token))
   True)

; Mirrors Rust's can_text_diff match arms:
; (Some, Some, _, _) | (_, Some, add, _) | (Some, _, _, delete)
(= (codex:turn-diff-can-text-diff $left-text? $right-text? $is-add $is-delete)
   (if (if $left-text? $right-text? False)
       True
       (if (if $right-text? $is-add False)
           True
           (if $left-text? $is-delete False))))

(= (codex:turn-diff-old-header $left-present $left-display)
   (if $left-present
       (str-concat "a/" $left-display)
       (case (collapse (codex:turn-diff-dev-null))
         ((($dev-null)
           $dev-null)))))

(= (codex:turn-diff-new-header $right-present $right-display)
   (if $right-present
       (str-concat "b/" $right-display)
       (case (collapse (codex:turn-diff-dev-null))
         ((($dev-null)
           $dev-null)))))

; Mode strings are materialized before formatting; a mode-str call placed
; straight inside a format-args argument tuple loses its value once later
; definitions are present (same evaluator behavior as the known-red notes).
(= (codex:turn-diff-mode-header $is-add $is-delete $left-mode $right-mode)
   (case (collapse (codex:turn-diff-file-mode-str $left-mode))
     ((($left-mode-str)
       (case (collapse (codex:turn-diff-file-mode-str $right-mode))
         ((($right-mode-str)
           (if $is-add
               (format-args "new file mode {}\n" ($right-mode-str))
               (if $is-delete
                   (format-args "deleted file mode {}\n" ($left-mode-str))
                   (if (== $left-mode $right-mode)
                       ""
                       (format-args
                         "old mode {}\nnew mode {}\n"
                         ($left-mode-str $right-mode-str))))))))))))

(= (codex:turn-diff-left-present $left-oid)
   (case (collapse (codex:turn-diff-zero-oid))
     ((($zero-oid)
       (if (== $left-oid $zero-oid) False True)))))

; The Rust get_file_diff body is staged into materialized helper steps and
; threads the aggregate prefix; the equivalent single let-chain loses
; intermediate values once later definitions are present (same evaluator
; behavior as the known-red notes).
(= (codex:turn-diff-file-diff-with-prefix
      $prefix
      $left-display
      $right-display
      $left-mode
      $left-oid
      $left-blob
      $right-mode
      $right-oid
      $right-blob)
   (case (collapse (codex:turn-diff-left-present $left-oid))
     ((($left-present)
       (case (collapse
               (codex:turn-diff-effective-blob $left-present $left-blob))
         ((($effective-left)
           (if (== $effective-left $right-blob)
               $prefix
               (codex:turn-diff-file-diff-changed
                 $prefix
                 $left-display
                 $right-display
                 $left-mode
                 $left-oid
                 $effective-left
                 $right-mode
                 $right-oid
                 $right-blob
                 $left-present)))))))))

(= (codex:turn-diff-file-diff
      $left-display
      $right-display
      $left-mode
      $left-oid
      $left-blob
      $right-mode
      $right-oid
      $right-blob)
   (codex:turn-diff-file-diff-with-prefix
     ""
     $left-display
     $right-display
     $left-mode
     $left-oid
     $left-blob
     $right-mode
     $right-oid
     $right-blob))

(= (codex:turn-diff-file-diff-changed
      $prefix
      $left-display
      $right-display
      $left-mode
      $left-oid
      $effective-left
      $right-mode
      $right-oid
      $right-blob
      $left-present)
   (case (collapse (codex:turn-diff-blob-present $right-blob))
     ((($right-present)
       (let $is-add (if $left-present False $right-present)
         (let $is-delete (if $left-present
                             (if $right-present False True)
                             False)
           (case (collapse
                   (codex:turn-diff-mode-header
                     $is-add $is-delete $left-mode $right-mode))
             ((($mode-header)
               (case (collapse
                       (codex:turn-diff-old-header
                         $left-present $left-display))
                 ((($old-header)
                   (case (collapse
                           (codex:turn-diff-new-header
                             $right-present $right-display))
                     ((($new-header)
                       (codex:turn-diff-file-diff-render
                         $prefix
                         $left-display
                         $right-display
                         $left-oid
                         $effective-left
                         $right-oid
                         $right-blob
                         $is-add
                         $is-delete
                         $mode-header
                         $old-header
                         $new-header))))))))))))))))

; The text/binary fork dispatches on the can-text-diff boolean through
; equation matching; an `if` at this nesting depth throws
; IncorrectNumberOfArguments even though the same expression evaluates at
; the top level (same evaluator family as the known-red notes).
(= (codex:turn-diff-file-diff-body
      True $head-index $effective-left $right-blob $old-header $new-header)
   (case (collapse (codex:turn-diff-blob-text-or-empty $effective-left))
     ((($left-text)
       (case (collapse (codex:turn-diff-blob-text-or-empty $right-blob))
         ((($right-text)
           (codex:turn-diff-unified-with-prefix
             $head-index
             $left-text
             $right-text
             $old-header
             $new-header))))))))

(= (codex:turn-diff-file-diff-body
      False $head-index $effective-left $right-blob $old-header $new-header)
   (str-concat
     $head-index
     (format-args
       "--- {}\n+++ {}\nBinary files differ\n"
       ($old-header $new-header))))

(= (codex:turn-diff-file-diff-render
      $prefix
      $left-display
      $right-display
      $left-oid
      $effective-left
      $right-oid
      $right-blob
      $is-add
      $is-delete
      $mode-header
      $old-header
      $new-header)
   (let $head
     (str-concat
       $prefix
       (str-concat
         (format-args "diff --git a/{} b/{}\n" ($left-display $right-display))
         $mode-header))
     (let $index-line (format-args "index {}..{}\n" ($left-oid $right-oid))
       (case (collapse (codex:turn-diff-blob-is-text-option $effective-left))
         ((($left-is-text)
           (case (collapse (codex:turn-diff-blob-is-text-option $right-blob))
             ((($right-is-text)
               (case (collapse
                       (codex:turn-diff-can-text-diff
                         $left-is-text $right-is-text $is-add $is-delete))
                 ((($can-text-diff)
                   (codex:turn-diff-file-diff-body
                     $can-text-diff
                     (str-concat $head $index-line)
                     $effective-left
                     $right-blob
                     $old-header
                     $new-header)))))))))))))

; --- aggregated diff -----------------------------------------------------

(= (codex:turn-diff-file-view
      $sort-key
      $left-display
      $right-display
      $left-mode
      $left-oid
      $left-blob
      $right-mode
      $right-oid
      $right-blob)
   (CodexTurnDiffFileView
     $sort-key
     $left-display
     $right-display
     $left-mode
     $left-oid
     $left-blob
     $right-mode
     $right-oid
     $right-blob))

(= (codex:turn-diff-view-sort-key
      (CodexTurnDiffFileView
        $sort-key
        $left-display
        $right-display
        $left-mode
        $left-oid
        $left-blob
        $right-mode
        $right-oid
        $right-blob))
   $sort-key)

(= (codex:turn-diff-file-diff-view-with-prefix
      $prefix
      (CodexTurnDiffFileView
        $sort-key
        $left-display
        $right-display
        $left-mode
        $left-oid
        $left-blob
        $right-mode
        $right-oid
        $right-blob))
   (codex:turn-diff-file-diff-with-prefix
     $prefix
     $left-display
     $right-display
     $left-mode
     $left-oid
     $left-blob
     $right-mode
     $right-oid
     $right-blob))

(= (codex:turn-diff-file-diff-view $view)
   (codex:turn-diff-file-diff-view-with-prefix "" $view))

(= (codex:turn-diff-insert-view $sorted $view)
   (if (== $sorted ())
       ($view)
       (let ($head $tail) (decons-atom $sorted)
         (if (codex:turn-diff-str-lt
               (codex:turn-diff-view-sort-key $view)
               (codex:turn-diff-view-sort-key $head))
             (cons-atom $view $sorted)
             (case (collapse (codex:turn-diff-insert-view $tail $view))
               ((($rest)
                 (cons-atom $head $rest))))))))

(= (codex:turn-diff-sort-views $views)
   (codex:turn-diff-sort-views-acc $views ()))

(= (codex:turn-diff-sort-views-acc $views $acc)
   (if (== $views ())
       $acc
       (let ($head $tail) (decons-atom $views)
         (codex:turn-diff-sort-views-acc
           $tail
           (codex:turn-diff-insert-view $acc $head)))))

; Mirrors Rust's per-file append: push diff, then ensure a trailing newline.
(= (codex:turn-diff-ensure-trailing-newline $text)
   (if (str-ends-with? $text "\n")
       $text
       (str-concat $text "\n")))

(= (codex:turn-diff-render-views $views $acc)
   (if (== $views ())
       $acc
       (let ($head $tail) (decons-atom $views)
         (codex:turn-diff-render-views
           $tail
           (codex:turn-diff-ensure-trailing-newline
             (codex:turn-diff-file-diff-view-with-prefix $acc $head))))))

(= (codex:turn-diff-finish-aggregate $text)
   (if (== (str-trim $text) "")
       CodexAbsent
       $text))

(= (codex:turn-diff-aggregate-views $views)
   (case (collapse (codex:turn-diff-sort-views $views))
     ((($sorted)
       (codex:turn-diff-finish-aggregate
         (codex:turn-diff-render-views $sorted ""))))))

