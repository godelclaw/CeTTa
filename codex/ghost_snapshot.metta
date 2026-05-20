; Rust-faithful ghost-snapshot warning formatter slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tasks/ghost_snapshot.rs
;
; Covered in this increment:
; - GhostSnapshotReport / LargeUntrackedDir / IgnoredUntrackedFile surfaces
; - snapshot warning formatting for large untracked dirs and files
; - byte-size formatting used by those warnings
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust obtains GhostSnapshotReport values from async git snapshot creation and
;   emits warnings through session events. This CeTTa slice only formats warnings
;   from already-materialized report data; runtime snapshot creation and event
;   dispatch belong to a later runtime slice.
; - Rust paths use Display. CeTTa represents those display paths directly as
;   strings in this pure formatter boundary.

!(import! &self list)
!(import! &self str)

(= (codex:ghost-snapshot-report $large-untracked-dirs $ignored-untracked-files)
   (CodexGhostSnapshotReport $large-untracked-dirs $ignored-untracked-files))

(= (codex:ghost-snapshot-report-large-untracked-dirs
      (CodexGhostSnapshotReport $large-untracked-dirs $ignored-untracked-files))
   $large-untracked-dirs)

(= (codex:ghost-snapshot-report-ignored-untracked-files
      (CodexGhostSnapshotReport $large-untracked-dirs $ignored-untracked-files))
   $ignored-untracked-files)

(= (codex:large-untracked-dir $path $file-count)
   (CodexLargeUntrackedDir $path $file-count))

(= (codex:large-untracked-dir-path (CodexLargeUntrackedDir $path $file-count))
   $path)

(= (codex:large-untracked-dir-file-count
      (CodexLargeUntrackedDir $path $file-count))
   $file-count)

(= (codex:ignored-untracked-file $path $byte-size)
   (CodexIgnoredUntrackedFile $path $byte-size))

(= (codex:ignored-untracked-file-path
      (CodexIgnoredUntrackedFile $path $byte-size))
   $path)

(= (codex:ignored-untracked-file-byte-size
      (CodexIgnoredUntrackedFile $path $byte-size))
   $byte-size)

(= (codex:ghost-snapshot-max-large-dirs)
   3)

(= (codex:ghost-snapshot-max-ignored-files)
   3)

(= (codex:ghost-snapshot-kib)
   1024)

(= (codex:ghost-snapshot-mib)
   1048576)

(= (codex:ghost-snapshot-div-floor-pos $n $d)
   (codex:ghost-snapshot-div-floor-pos-acc $n $d 0))

(= (codex:ghost-snapshot-div-floor-pos-acc $n $d $acc)
   (if (< $n $d)
       $acc
       (codex:ghost-snapshot-div-floor-pos-acc
         (- $n $d)
         $d
         (+ $acc 1))))

(= (codex:ghost-snapshot-format-bytes $bytes)
   (if (>= $bytes (codex:ghost-snapshot-mib))
       (format-args
         "{} MiB"
         ((codex:ghost-snapshot-div-floor-pos
            $bytes
            (codex:ghost-snapshot-mib))))
       (if (>= $bytes (codex:ghost-snapshot-kib))
           (format-args
             "{} KiB"
             ((codex:ghost-snapshot-div-floor-pos
                $bytes
                (codex:ghost-snapshot-kib))))
           (format-args "{} B" ($bytes)))))

(= (codex:ghost-snapshot-large-dir-part
      (CodexLargeUntrackedDir $path $file-count))
   (format-args "{} ({} files)" ($path $file-count)))

(= (codex:ghost-snapshot-large-dir-parts-take $dirs $remaining)
   (if (== $dirs ())
       ()
       (if (<= $remaining 0)
           ()
           (let ($head $tail) (decons-atom $dirs)
             (let $rest
               (eval
                 (codex:ghost-snapshot-large-dir-parts-take
                   $tail
                   (- $remaining 1)))
               (cons-atom
                 (codex:ghost-snapshot-large-dir-part $head)
                 $rest))))))

(= (codex:ghost-snapshot-large-dir-parts $dirs)
   (let $parts
     (codex:ghost-snapshot-large-dir-parts-take
       $dirs
       (codex:ghost-snapshot-max-large-dirs))
     (if (> (list:len $dirs) (codex:ghost-snapshot-max-large-dirs))
         (list:push
           $parts
           (format-args
             "{} more"
             ((- (list:len $dirs) (codex:ghost-snapshot-max-large-dirs)))))
         $parts)))

(= (codex:ghost-snapshot-ignored-file-part
      (CodexIgnoredUntrackedFile $path $byte-size))
   (format-args
     "{} ({})"
     ($path (codex:ghost-snapshot-format-bytes $byte-size))))

(= (codex:ghost-snapshot-ignored-file-parts-take $files $remaining)
   (if (== $files ())
       ()
       (if (<= $remaining 0)
           ()
           (let ($head $tail) (decons-atom $files)
             (let $rest
               (eval
                 (codex:ghost-snapshot-ignored-file-parts-take
                   $tail
                   (- $remaining 1)))
               (cons-atom
                 (codex:ghost-snapshot-ignored-file-part $head)
                 $rest))))))

(= (codex:ghost-snapshot-ignored-file-parts $files)
   (let $parts
     (codex:ghost-snapshot-ignored-file-parts-take
       $files
       (codex:ghost-snapshot-max-ignored-files))
     (if (> (list:len $files) (codex:ghost-snapshot-max-ignored-files))
         (list:push
           $parts
           (format-args
             "{} more"
             ((- (list:len $files) (codex:ghost-snapshot-max-ignored-files)))))
         $parts)))

(= (codex:ghost-snapshot-format-large-untracked-warning $ignore-large-untracked-dirs $report)
   (let $large-untracked-dirs
     (codex:ghost-snapshot-report-large-untracked-dirs $report)
     (if (== $large-untracked-dirs ())
         CodexAbsent
         (if (== $ignore-large-untracked-dirs CodexAbsent)
             CodexAbsent
             (format-args
               "Repository snapshot ignored large untracked directories (>= {} files): {}. These directories are excluded from snapshots and undo cleanup. Adjust `ghost_snapshot.ignore_large_untracked_dirs` to change this behavior."
               ($ignore-large-untracked-dirs
                (str-join
                  ", "
                  (codex:ghost-snapshot-large-dir-parts
                    $large-untracked-dirs))))))))

(= (codex:ghost-snapshot-format-ignored-untracked-files-warning $ignore-large-untracked-files $report)
   (if (== $ignore-large-untracked-files CodexAbsent)
       CodexAbsent
       (let $ignored-untracked-files
         (codex:ghost-snapshot-report-ignored-untracked-files $report)
         (if (== $ignored-untracked-files ())
             CodexAbsent
             (format-args
               "Repository snapshot ignored untracked files larger than {}: {}. These files are preserved during undo cleanup, but their contents are not captured in the snapshot. Adjust `ghost_snapshot.ignore_large_untracked_files` to change this behavior. To avoid this message in the future, update your `.gitignore`."
               ((codex:ghost-snapshot-format-bytes $ignore-large-untracked-files)
                (str-join
                  ", "
                  (codex:ghost-snapshot-ignored-file-parts
                    $ignored-untracked-files))))))))

(= (codex:ghost-snapshot-append-optional-warning $warnings $message)
   (if (== $message CodexAbsent)
       $warnings
       (list:push $warnings $message)))

(= (codex:ghost-snapshot-format-snapshot-warnings
      $ignore-large-untracked-files
      $ignore-large-untracked-dirs
      $report)
   (let $large-dir-warning
     (codex:ghost-snapshot-format-large-untracked-warning
       $ignore-large-untracked-dirs
       $report)
     (let $warnings
       (codex:ghost-snapshot-append-optional-warning
         ()
         $large-dir-warning)
       (let $ignored-files-warning
         (codex:ghost-snapshot-format-ignored-untracked-files-warning
           $ignore-large-untracked-files
           $report)
         (codex:ghost-snapshot-append-optional-warning
           $warnings
           $ignored-files-warning)))))
