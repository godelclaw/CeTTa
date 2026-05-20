!(register-module! ../codex)
!(import! &self codex:ghost_snapshot)

(= (test:ghost-snapshot-empty-report)
   (codex:ghost-snapshot-report () ()))

(= (test:ghost-snapshot-large-dir-report)
   (codex:ghost-snapshot-report
     ((codex:large-untracked-dir "models" 250))
     ()))

(= (test:ghost-snapshot-many-report)
   (codex:ghost-snapshot-report
     ((codex:large-untracked-dir "models" 250)
      (codex:large-untracked-dir "cache" 201)
      (codex:large-untracked-dir "node_modules" 900)
      (codex:large-untracked-dir "vendor" 450))
     ((codex:ignored-untracked-file "large.bin" 1536)
      (codex:ignored-untracked-file "weights.bin" 1048576)
      (codex:ignored-untracked-file "tiny.dat" 42)
      (codex:ignored-untracked-file "video.mov" 2097152))))

(= (test:ghost-snapshot-large-dir-warning)
   "Repository snapshot ignored large untracked directories (>= 200 files): models (250 files). These directories are excluded from snapshots and undo cleanup. Adjust `ghost_snapshot.ignore_large_untracked_dirs` to change this behavior.")

(= (test:ghost-snapshot-many-dir-warning)
   "Repository snapshot ignored large untracked directories (>= 200 files): models (250 files), cache (201 files), node_modules (900 files), 1 more. These directories are excluded from snapshots and undo cleanup. Adjust `ghost_snapshot.ignore_large_untracked_dirs` to change this behavior.")

(= (test:ghost-snapshot-many-file-warning)
   "Repository snapshot ignored untracked files larger than 1 KiB: large.bin (1 KiB), weights.bin (1 MiB), tiny.dat (42 B), 1 more. These files are preserved during undo cleanup, but their contents are not captured in the snapshot. Adjust `ghost_snapshot.ignore_large_untracked_files` to change this behavior. To avoid this message in the future, update your `.gitignore`.")

!(assertEqualToResult
  (codex:ghost-snapshot-max-large-dirs)
  (3))

!(assertEqualToResult
  (codex:ghost-snapshot-max-ignored-files)
  (3))

!(assertEqualToResult
  (codex:ghost-snapshot-format-bytes 42)
  ("42 B"))

!(assertEqualToResult
  (codex:ghost-snapshot-format-bytes 1536)
  ("1 KiB"))

!(assertEqualToResult
  (codex:ghost-snapshot-format-bytes 1048576)
  ("1 MiB"))

!(assertEqualToResult
  (codex:ghost-snapshot-format-bytes 2097152)
  ("2 MiB"))

!(assertEqualToResult
  (codex:ghost-snapshot-report-large-untracked-dirs
    (test:ghost-snapshot-large-dir-report))
  (((CodexLargeUntrackedDir "models" 250))))

!(assertEqualToResult
  (codex:ghost-snapshot-report-ignored-untracked-files
    (test:ghost-snapshot-many-report))
  (((CodexIgnoredUntrackedFile "large.bin" 1536)
    (CodexIgnoredUntrackedFile "weights.bin" 1048576)
    (CodexIgnoredUntrackedFile "tiny.dat" 42)
    (CodexIgnoredUntrackedFile "video.mov" 2097152))))

!(assertEqualToResult
  (codex:ghost-snapshot-format-large-untracked-warning
    CodexAbsent
    (test:ghost-snapshot-large-dir-report))
  (CodexAbsent))

!(assertEqualToResult
  (codex:ghost-snapshot-format-large-untracked-warning
    200
    (test:ghost-snapshot-empty-report))
  (CodexAbsent))

!(assertEqual
  (codex:ghost-snapshot-format-large-untracked-warning
    200
    (test:ghost-snapshot-large-dir-report))
  (test:ghost-snapshot-large-dir-warning))

!(assertEqual
  (codex:ghost-snapshot-format-large-untracked-warning
    200
    (test:ghost-snapshot-many-report))
  (test:ghost-snapshot-many-dir-warning))

!(assertEqualToResult
  (codex:ghost-snapshot-format-ignored-untracked-files-warning
    CodexAbsent
    (test:ghost-snapshot-many-report))
  (CodexAbsent))

!(assertEqualToResult
  (codex:ghost-snapshot-format-ignored-untracked-files-warning
    1024
    (test:ghost-snapshot-empty-report))
  (CodexAbsent))

!(assertEqual
  (codex:ghost-snapshot-format-ignored-untracked-files-warning
    1536
    (test:ghost-snapshot-many-report))
  (test:ghost-snapshot-many-file-warning))

!(assertEqualToResult
  (codex:ghost-snapshot-format-snapshot-warnings
    1024
    200
    (test:ghost-snapshot-empty-report))
  (()))

!(assertEqual
  (codex:ghost-snapshot-format-snapshot-warnings
    1536
    200
    (test:ghost-snapshot-many-report))
  ((test:ghost-snapshot-many-dir-warning)
   (test:ghost-snapshot-many-file-warning)))
