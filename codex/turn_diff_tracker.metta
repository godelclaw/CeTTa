; Rust-faithful turn diff tracker slice.
;
; This ports the algorithm surface from:
; - openai-codex/codex-rs/core/src/turn_diff_tracker.rs
;
; Covered in this increment:
; - zero-oid/dev-null constants and git file-mode display strings
; - baseline file-info snapshots keyed by stable internal names
; - tracker state transitions for on_patch_begin, including rename/move
;   remapping and the rare unmapped-move-source branch
; - aggregated unified-diff assembly: stable repo-relative path ordering,
;   add/delete/mode-change headers, index lines, text hunks, binary fallback
; - an LCS line-diff engine emitting unified hunks with context radius 3
; - git-root cache lookup/insert helpers and repo-relative display strings
; - thin runtime wrappers over fs natives, git-repo-root, and
;   process-run-shell for baseline/current probes
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust keys baselines by Uuid::new_v4 strings. CeTTa has no uuid source,
;   so the tracker derives internal names from a deterministic counter.
;   Internal names never appear in any externally visible output.
; - Rust reads the filesystem and invokes git inside on_patch_begin and
;   get_unified_diff. This slice splits each into a pure core over explicit
;   probe/view values plus thin runtime wrappers, mirroring the
;   shell_snapshot slice split.
; - Rust detects binary blobs by UTF-8-validating raw bytes and file modes
;   via unix metadata bits. CeTTa fs natives only surface text, so blob
;   values carry an explicit text/binary kind, and the runtime mode probe
;   returns the regular mode exactly like Rust's cfg(not(unix)) fallback.
; - Rust diffs with similar::TextDiff (Myers). This slice implements an LCS
;   line diff with the deletions-before-insertions tie-break; inputs with
;   several minimal edit scripts may pick a different minimal hunk interior
;   than `similar` while remaining a correct unified diff. Hunk grouping
;   uses interval merging that splits hunks exactly when the equal run
;   between changes exceeds 2*radius, matching similar's grouped ops.
; - Rust computes blob oids with `git hash-object` and an in-process sha1
;   fallback. CeTTa has no sha1 native, so the runtime probe shells out to
;   git and falls back to the zero oid when git is unavailable.
; - Rust iterates on_patch_begin changes in HashMap order. CeTTa processes
;   the change list in input order; per-path transitions are independent, so
;   the resulting tracker state is the same.
; - Rust orders files with sort_by_key over strings and compares cached git
;   roots with Path::starts_with. CeTTa has no string-ordering native, so
;   this slice ranks characters through an explicit printable-ASCII table
;   (characters outside the table sort first), and root-prefix checks
;   compare against the root plus a "/" separator to stay component-wise.
; - Rust rewrites Windows path separators in display strings. CeTTa targets
;   unix paths in this lane, so the rewrite is omitted.
; - on_patch_begin consumes protocol FileChange constructor terms
;   (CodexFileChangeAdd/Delete/Update) pattern-matched directly without
;   importing codex:protocol: loading that module alongside this slice
;   currently breaks the line-diff recursion (evaluator pressure, same
;   family as the known-red notes), and the constructors are inert terms
;   that need no import to match.

!(import! &self fs)
!(import! &self git)
!(import! &self list)
!(import! &self path)
!(import! &self process)
!(import! &self turn_diff_file_diff)
!(import! &self str)

; --- baseline file info -------------------------------------------------

(= (codex:turn-diff-baseline-file-info $path $blob $mode $oid)
   (CodexTurnDiffBaselineFileInfo $path $blob $mode $oid))

(= (codex:turn-diff-baseline-file-info-path
      (CodexTurnDiffBaselineFileInfo $path $blob $mode $oid))
   $path)

(= (codex:turn-diff-baseline-file-info-blob
      (CodexTurnDiffBaselineFileInfo $path $blob $mode $oid))
   $blob)

(= (codex:turn-diff-baseline-file-info-mode
      (CodexTurnDiffBaselineFileInfo $path $blob $mode $oid))
   $mode)

(= (codex:turn-diff-baseline-file-info-oid
      (CodexTurnDiffBaselineFileInfo $path $blob $mode $oid))
   $oid)

; --- association-list helpers -------------------------------------------

(= (codex:turn-diff-alist-get $alist $key)
   (if (== $alist ())
       CodexAbsent
       (let ($head $tail) (decons-atom $alist)
         (let ($k $v) $head
           (if (== $k $key)
               $v
               (codex:turn-diff-alist-get $tail $key))))))

(= (codex:turn-diff-alist-insert $alist $key $value)
   (if (== $alist ())
       (($key $value))
       (let ($head $tail) (decons-atom $alist)
         (let ($k $v) $head
           (if (== $k $key)
               (cons-atom ($key $value) $tail)
               (case (collapse (codex:turn-diff-alist-insert $tail $key $value))
                 ((($rest)
                   (cons-atom $head $rest)))))))))

(= (codex:turn-diff-alist-remove $alist $key)
   (if (== $alist ())
       ()
       (let ($head $tail) (decons-atom $alist)
         (let ($k $v) $head
           (if (== $k $key)
               $tail
               (case (collapse (codex:turn-diff-alist-remove $tail $key))
                 ((($rest)
                   (cons-atom $head $rest)))))))))

; --- tracker state ------------------------------------------------------

(= (codex:turn-diff-tracker-new)
   (CodexTurnDiffTracker 0 () () () ()))

(= (codex:turn-diff-tracker-next-internal-id
      (CodexTurnDiffTracker $next-id $ext $base $cur $roots))
   $next-id)

(= (codex:turn-diff-tracker-external-to-temp
      (CodexTurnDiffTracker $next-id $ext $base $cur $roots))
   $ext)

(= (codex:turn-diff-tracker-baseline-info
      (CodexTurnDiffTracker $next-id $ext $base $cur $roots))
   $base)

(= (codex:turn-diff-tracker-temp-to-current
      (CodexTurnDiffTracker $next-id $ext $base $cur $roots))
   $cur)

(= (codex:turn-diff-tracker-git-root-cache
      (CodexTurnDiffTracker $next-id $ext $base $cur $roots))
   $roots)

; Deviation: deterministic counter instead of Uuid::new_v4; see header.
(= (codex:turn-diff-internal-name $id)
   (format-args "turn-diff-internal-{}" ($id)))

; --- baseline probes ----------------------------------------------------

(= (codex:turn-diff-baseline-probe-present $mode $blob $oid)
   (CodexTurnDiffBaselineProbePresent $mode $blob $oid))

(= (codex:turn-diff-baseline-probe-absent)
   (CodexTurnDiffBaselineProbeAbsent))

(= (codex:turn-diff-baseline-from-probe
      $path
      (CodexTurnDiffBaselineProbePresent $mode $blob $oid))
   (codex:turn-diff-baseline-file-info $path $blob $mode $oid))

(= (codex:turn-diff-baseline-from-probe
      $path
      (CodexTurnDiffBaselineProbeAbsent))
   (codex:turn-diff-baseline-file-info
     $path
     (codex:turn-diff-blob-text "")
     (codex:turn-diff-file-mode-regular)
     (codex:turn-diff-zero-oid)))

; --- on_patch_begin -----------------------------------------------------

(= (codex:turn-diff-patch-entry $path $change $probe)
   (CodexTurnDiffPatchEntry $path $change $probe))

(= (codex:turn-diff-on-patch-begin-with-probes $tracker $entries)
   (if (== $entries ())
       $tracker
       (let ($head $tail) (decons-atom $entries)
         (codex:turn-diff-on-patch-begin-with-probes
           (codex:turn-diff-apply-patch-entry $tracker $head)
           $tail))))

(= (codex:turn-diff-apply-patch-entry
      $tracker
      (CodexTurnDiffPatchEntry $path $change $probe))
   (codex:turn-diff-apply-move
     (codex:turn-diff-ensure-baseline $tracker $path $probe)
     $path
     $change))

(= (codex:turn-diff-ensure-baseline
      (CodexTurnDiffTracker $next-id $ext $base $cur $roots)
      $path
      $probe)
   (if (== (codex:turn-diff-alist-get $ext $path) CodexAbsent)
       (let $internal (codex:turn-diff-internal-name $next-id)
         (CodexTurnDiffTracker
           (+ $next-id 1)
           (codex:turn-diff-alist-insert $ext $path $internal)
           (codex:turn-diff-alist-insert
             $base
             $internal
             (codex:turn-diff-baseline-from-probe $path $probe))
           (codex:turn-diff-alist-insert $cur $internal $path)
           $roots))
       (CodexTurnDiffTracker $next-id $ext $base $cur $roots)))

(= (codex:turn-diff-apply-move $tracker $path (CodexFileChangeAdd $content))
   $tracker)

(= (codex:turn-diff-apply-move $tracker $path (CodexFileChangeDelete $content))
   $tracker)

(= (codex:turn-diff-apply-move
      $tracker
      $path
      (CodexFileChangeUpdate $unified-diff $move-path))
   (if (== $move-path CodexAbsent)
       $tracker
       (codex:turn-diff-apply-move-known $tracker $path $move-path)))

(= (codex:turn-diff-apply-move-known
      (CodexTurnDiffTracker $next-id $ext $base $cur $roots)
      $path
      $dest)
   (let $existing (codex:turn-diff-alist-get $ext $path)
     (if (== $existing CodexAbsent)
         (let $internal (codex:turn-diff-internal-name $next-id)
           (CodexTurnDiffTracker
             (+ $next-id 1)
             (codex:turn-diff-alist-insert
               (codex:turn-diff-alist-remove $ext $path)
               $dest
               $internal)
             (codex:turn-diff-alist-insert
               $base
               $internal
               (codex:turn-diff-baseline-file-info
                 $path
                 (codex:turn-diff-blob-text "")
                 (codex:turn-diff-file-mode-regular)
                 (codex:turn-diff-zero-oid)))
             (codex:turn-diff-alist-insert $cur $internal $dest)
             $roots))
         (CodexTurnDiffTracker
           $next-id
           (codex:turn-diff-alist-insert
             (codex:turn-diff-alist-remove $ext $path)
             $dest
             $existing)
           $base
           (codex:turn-diff-alist-insert $cur $existing $dest)
           $roots))))

(= (codex:turn-diff-path-for-internal
      (CodexTurnDiffTracker $next-id $ext $base $cur $roots)
      $internal)
   (let $current (codex:turn-diff-alist-get $cur $internal)
     (if (== $current CodexAbsent)
         (let $info (codex:turn-diff-alist-get $base $internal)
           (if (== $info CodexAbsent)
               CodexAbsent
               (codex:turn-diff-baseline-file-info-path $info)))
         $current)))

; --- git root cache -----------------------------------------------------

; Deviation: component-wise prefix via "<root>/" string check; see header.
(= (codex:turn-diff-git-root-cache-lookup $roots $dir)
   (if (== $roots ())
       CodexAbsent
       (let ($head $tail) (decons-atom $roots)
         (if (== $dir $head)
             $head
             (if (str-starts-with? $dir (str-concat $head "/"))
                 $head
                 (codex:turn-diff-git-root-cache-lookup $tail $dir))))))

(= (codex:turn-diff-git-root-cache-contains $roots $root)
   (if (== $roots ())
       False
       (let ($head $tail) (decons-atom $roots)
         (if (== $head $root)
             True
             (codex:turn-diff-git-root-cache-contains $tail $root)))))

(= (codex:turn-diff-git-root-cache-insert $roots $root)
   (if (codex:turn-diff-git-root-cache-contains $roots $root)
       $roots
       (list:push $roots $root)))

(= (codex:turn-diff-display-relative $path $root)
   (if (== $root CodexAbsent)
       $path
       (if (== $path $root)
           ""
           (if (str-starts-with? $path (str-concat $root "/"))
               (str-slice $path (+ (str-length $root) 1) (str-length $path))
               $path))))


; --- runtime wrappers ----------------------------------------------------

(= (codex:turn-diff-runtime-git-root $path)
   (case (collapse (git-repo-root (path-dirname $path)))
     ((((GitRepoRoot True $root))
       $root)
      ($other
       CodexAbsent))))

(= (codex:turn-diff-runtime-git-oid $path)
   (let $root (codex:turn-diff-runtime-git-root $path)
     (if (== $root CodexAbsent)
         (codex:turn-diff-zero-oid)
         (case (collapse
                 (process-run-shell-cwd-timeout-ms
                   (format-args "git hash-object -- '{}'"
                                ((codex:turn-diff-display-relative
                                   $path $root)))
                   $root
                   5000))
           ((((ProcessResult 0 $stdout $stderr $combined $b $timed-out))
             (let $oid (str-trim $stdout)
               (if (== (str-length $oid) 40)
                   $oid
                   (codex:turn-diff-zero-oid))))
            ($other
             (codex:turn-diff-zero-oid)))))))

(= (codex:turn-diff-runtime-baseline-probe $path)
   (if (fs-exists? $path)
       (codex:turn-diff-baseline-probe-present
         (codex:turn-diff-file-mode-regular)
         (codex:turn-diff-blob-text (fs-read-text $path))
         (codex:turn-diff-runtime-git-oid $path))
       (codex:turn-diff-baseline-probe-absent)))

(= (codex:turn-diff-runtime-patch-entry $path $change)
   (codex:turn-diff-patch-entry
     $path
     $change
     (codex:turn-diff-runtime-baseline-probe $path)))

(= (codex:turn-diff-runtime-on-patch-begin $tracker $changes)
   (codex:turn-diff-on-patch-begin-with-probes
     $tracker
     (list:map $changes $entry
       (let ($path $change) $entry
         (codex:turn-diff-runtime-patch-entry $path $change)))))

(= (codex:turn-diff-runtime-display $path)
   (codex:turn-diff-display-relative
     $path
     (codex:turn-diff-runtime-git-root $path)))

(= (codex:turn-diff-runtime-right-blob $path)
   (if (fs-exists? $path)
       (codex:turn-diff-blob-text (fs-read-text $path))
       CodexAbsent))

(= (codex:turn-diff-runtime-right-oid $path)
   (if (fs-exists? $path)
       (codex:turn-diff-runtime-git-oid $path)
       (codex:turn-diff-zero-oid)))

(= (codex:turn-diff-runtime-view-for $tracker $internal)
   (let $info (codex:turn-diff-alist-get
                (codex:turn-diff-tracker-baseline-info $tracker)
                $internal)
     (let $current (codex:turn-diff-path-for-internal $tracker $internal)
       (let $right-display (codex:turn-diff-runtime-display $current)
         (codex:turn-diff-file-view
           $right-display
           (codex:turn-diff-runtime-display
             (codex:turn-diff-baseline-file-info-path $info))
           $right-display
           (codex:turn-diff-baseline-file-info-mode $info)
           (codex:turn-diff-baseline-file-info-oid $info)
           (codex:turn-diff-baseline-file-info-blob $info)
           (codex:turn-diff-file-mode-regular)
           (codex:turn-diff-runtime-right-oid $current)
           (codex:turn-diff-runtime-right-blob $current))))))

(= (codex:turn-diff-runtime-unified-diff $tracker)
   (codex:turn-diff-aggregate-views
     (list:map
       (codex:turn-diff-tracker-baseline-info $tracker)
       $entry
       (let ($internal $info) $entry
         (codex:turn-diff-runtime-view-for $tracker $internal)))))
