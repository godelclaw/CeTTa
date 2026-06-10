!(register-module! ../codex)
!(import! &self codex:turn_diff_tracker)

!(println! "=== Codex turn_diff_tracker demo ===")

; Track a patch that renames a.txt to b.txt while editing it.
!(println!
  (codex:turn-diff-on-patch-begin-with-probes
    (codex:turn-diff-tracker-new)
    ((codex:turn-diff-patch-entry
       "/repo/a.txt"
       (CodexFileChangeUpdate "@@ demo @@" "/repo/b.txt")
       (codex:turn-diff-baseline-probe-present
         (codex:turn-diff-file-mode-regular)
         (codex:turn-diff-blob-text "alpha\nbeta\ngamma\n")
         "1111111111111111111111111111111111111111")))))

; Aggregated unified diff for one modified and one added file.
!(println!
  (codex:turn-diff-aggregate-views
    ((codex:turn-diff-file-view "b.txt" "a.txt" "b.txt"
       (codex:turn-diff-file-mode-regular)
       "1111111111111111111111111111111111111111"
       (codex:turn-diff-blob-text "alpha\nbeta\ngamma\n")
       (codex:turn-diff-file-mode-regular)
       "2222222222222222222222222222222222222222"
       (codex:turn-diff-blob-text "alpha\nBETA\ngamma\n"))
     (codex:turn-diff-file-view "new.txt" "new.txt" "new.txt"
       (codex:turn-diff-file-mode-regular)
       "0000000000000000000000000000000000000000"
       (codex:turn-diff-blob-text "")
       (codex:turn-diff-file-mode-regular)
       "3333333333333333333333333333333333333333"
       (codex:turn-diff-blob-text "hello\n")))))

; The aggregated diff is checked end to end.
!(assertEqualToResult
  (codex:turn-diff-aggregate-views
    ((codex:turn-diff-file-view "b.txt" "a.txt" "b.txt"
       (codex:turn-diff-file-mode-regular)
       "1111111111111111111111111111111111111111"
       (codex:turn-diff-blob-text "alpha\nbeta\ngamma\n")
       (codex:turn-diff-file-mode-regular)
       "2222222222222222222222222222222222222222"
       (codex:turn-diff-blob-text "alpha\nBETA\ngamma\n"))))
  ("diff --git a/a.txt b/b.txt\nindex 1111111111111111111111111111111111111111..2222222222222222222222222222222222222222\n--- a/a.txt\n+++ b/b.txt\n@@ -1,3 +1,3 @@\n alpha\n-beta\n+BETA\n gamma\n"))

!(println! "=== demo complete ===")
