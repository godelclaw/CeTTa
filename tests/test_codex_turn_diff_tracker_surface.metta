!(register-module! ../codex)
!(import! &self codex:turn_diff_tracker)

; --- constants and file modes -------------------------------------------

!(assertEqualToResult
  (codex:turn-diff-zero-oid)
  ("0000000000000000000000000000000000000000"))

!(assertEqualToResult
  (codex:turn-diff-dev-null)
  ("/dev/null"))

!(assertEqualToResult
  (codex:turn-diff-context-radius)
  (3))

!(assertEqualToResult
  (codex:turn-diff-file-mode-str (codex:turn-diff-file-mode-regular))
  ("100644"))

!(assertEqualToResult
  (codex:turn-diff-file-mode-str (codex:turn-diff-file-mode-executable))
  ("100755"))

!(assertEqualToResult
  (codex:turn-diff-file-mode-str (codex:turn-diff-file-mode-symlink))
  ("120000"))

; --- line splitting -------------------------------------------------------

!(assertEqualToResult
  (codex:turn-diff-split-lines "a\nb\nc\n")
  (("a" "b" "c")))

!(assertEqualToResult
  (codex:turn-diff-split-lines "a\nb")
  (("a" "b")))

!(assertEqualToResult
  (codex:turn-diff-split-lines "")
  (()))

!(assertEqualToResult
  (codex:turn-diff-ends-with-newline "a\n")
  (True))

!(assertEqualToResult
  (codex:turn-diff-ends-with-newline "a")
  (False))

; --- LCS line ops ----------------------------------------------------------

!(assertEqualToResult
  (codex:turn-diff-line-ops ("a" "b" "c") ("a" "x" "c"))
  (((CodexTurnDiffOpEqual "a")
    (CodexTurnDiffOpDelete "b")
    (CodexTurnDiffOpInsert "x")
    (CodexTurnDiffOpEqual "c"))))

!(assertEqualToResult
  (codex:turn-diff-line-ops () ("a"))
  (((CodexTurnDiffOpInsert "a"))))

!(assertEqualToResult
  (codex:turn-diff-line-ops ("a") ())
  (((CodexTurnDiffOpDelete "a"))))

; --- string ordering -------------------------------------------------------

!(assertEqualToResult
  (codex:turn-diff-str-lt "apple" "banana")
  (True))

!(assertEqualToResult
  (codex:turn-diff-str-lt "b" "a")
  (False))

!(assertEqualToResult
  (codex:turn-diff-str-lt "x" "x")
  (False))

!(assertEqualToResult
  (codex:turn-diff-str-lt "ab" "abc")
  (True))

; --- unified hunks ---------------------------------------------------------

!(assertEqualToResult
  (codex:turn-diff-unified "a\nb\nc\n" "a\nx\nc\n" "a/f" "b/f")
  ("--- a/f\n+++ b/f\n@@ -1,3 +1,3 @@\n a\n-b\n+x\n c\n"))

!(assertEqualToResult
  (codex:turn-diff-unified
    "l1\nl2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\nl10\nl11\n"
    "l1\nX2\nl3\nl4\nl5\nl6\nl7\nl8\nl9\nX10\nl11\n"
    "a/m" "b/m")
  ("--- a/m\n+++ b/m\n@@ -1,5 +1,5 @@\n l1\n-l2\n+X2\n l3\n l4\n l5\n@@ -7,5 +7,5 @@\n l7\n l8\n l9\n-l10\n+X10\n l11\n"))

!(assertEqualToResult
  (codex:turn-diff-unified "a" "b" "a/f" "b/f")
  ("--- a/f\n+++ b/f\n@@ -1 +1 @@\n-a\n\\ No newline at end of file\n+b\n\\ No newline at end of file\n"))

; --- tracker state and on_patch_begin ---------------------------------------

!(assertEqualToResult
  (codex:turn-diff-tracker-new)
  ((CodexTurnDiffTracker 0 () () () ())))

!(assertEqualToResult
  (codex:turn-diff-on-patch-begin-with-probes
    (codex:turn-diff-tracker-new)
    ((codex:turn-diff-patch-entry
       "/r/a.txt"
       (CodexFileChangeUpdate "d" CodexAbsent)
       (codex:turn-diff-baseline-probe-present
         (codex:turn-diff-file-mode-regular)
         (codex:turn-diff-blob-text "old\n")
         "1111111111111111111111111111111111111111"))))
  ((CodexTurnDiffTracker
     1
     (("/r/a.txt" "turn-diff-internal-0"))
     (("turn-diff-internal-0"
       (CodexTurnDiffBaselineFileInfo
         "/r/a.txt"
         (CodexTurnDiffBlobText "old\n")
         (CodexTurnDiffFileModeRegular)
         "1111111111111111111111111111111111111111")))
     (("turn-diff-internal-0" "/r/a.txt"))
     ())))

; addition: absent probe snapshots a zero-oid empty baseline
!(assertEqualToResult
  (codex:turn-diff-on-patch-begin-with-probes
    (codex:turn-diff-tracker-new)
    ((codex:turn-diff-patch-entry
       "/r/new.txt"
       (CodexFileChangeAdd "hi\n")
       (codex:turn-diff-baseline-probe-absent))))
  ((CodexTurnDiffTracker
     1
     (("/r/new.txt" "turn-diff-internal-0"))
     (("turn-diff-internal-0"
       (CodexTurnDiffBaselineFileInfo
         "/r/new.txt"
         (CodexTurnDiffBlobText "")
         (CodexTurnDiffFileModeRegular)
         "0000000000000000000000000000000000000000")))
     (("turn-diff-internal-0" "/r/new.txt"))
     ())))

; rename: update with move-path remaps the current path and forward mapping
!(assertEqualToResult
  (codex:turn-diff-on-patch-begin-with-probes
    (codex:turn-diff-tracker-new)
    ((codex:turn-diff-patch-entry
       "/r/a.txt"
       (CodexFileChangeUpdate "d" "/r/b.txt")
       (codex:turn-diff-baseline-probe-present
         (codex:turn-diff-file-mode-regular)
         (codex:turn-diff-blob-text "old\n")
         "1111111111111111111111111111111111111111"))))
  ((CodexTurnDiffTracker
     1
     (("/r/b.txt" "turn-diff-internal-0"))
     (("turn-diff-internal-0"
       (CodexTurnDiffBaselineFileInfo
         "/r/a.txt"
         (CodexTurnDiffBlobText "old\n")
         (CodexTurnDiffFileModeRegular)
         "1111111111111111111111111111111111111111")))
     (("turn-diff-internal-0" "/r/b.txt"))
     ())))

!(assertEqualToResult
  (codex:turn-diff-path-for-internal
    (CodexTurnDiffTracker
      1
      (("/r/b.txt" "turn-diff-internal-0"))
      (("turn-diff-internal-0"
        (CodexTurnDiffBaselineFileInfo
          "/r/a.txt"
          (CodexTurnDiffBlobText "old\n")
          (CodexTurnDiffFileModeRegular)
          "1111111111111111111111111111111111111111")))
      (("turn-diff-internal-0" "/r/b.txt"))
      ())
    "turn-diff-internal-0")
  ("/r/b.txt"))

; --- git root cache and display ----------------------------------------------

!(assertEqualToResult
  (codex:turn-diff-git-root-cache-lookup ("/repo") "/repo/sub/dir")
  ("/repo"))

!(assertEqualToResult
  (codex:turn-diff-git-root-cache-lookup ("/repo") "/repository")
  (CodexAbsent))

!(assertEqualToResult
  (codex:turn-diff-git-root-cache-insert ("/repo") "/repo")
  (("/repo")))

!(assertEqualToResult
  (codex:turn-diff-git-root-cache-insert ("/repo") "/other")
  (("/repo" "/other")))

!(assertEqualToResult
  (codex:turn-diff-display-relative "/repo/sub/f.txt" "/repo")
  ("sub/f.txt"))

!(assertEqualToResult
  (codex:turn-diff-display-relative "/elsewhere/f.txt" CodexAbsent)
  ("/elsewhere/f.txt"))

; --- per-file diffs ------------------------------------------------------------

; modify
!(assertEqualToResult
  (codex:turn-diff-file-diff "f.txt" "f.txt"
    (codex:turn-diff-file-mode-regular)
    "1111111111111111111111111111111111111111"
    (codex:turn-diff-blob-text "a\nb\nc\n")
    (codex:turn-diff-file-mode-regular)
    "2222222222222222222222222222222222222222"
    (codex:turn-diff-blob-text "a\nx\nc\n"))
  ("diff --git a/f.txt b/f.txt\nindex 1111111111111111111111111111111111111111..2222222222222222222222222222222222222222\n--- a/f.txt\n+++ b/f.txt\n@@ -1,3 +1,3 @@\n a\n-b\n+x\n c\n"))

; addition
!(assertEqualToResult
  (codex:turn-diff-file-diff "n.txt" "n.txt"
    (codex:turn-diff-file-mode-regular)
    "0000000000000000000000000000000000000000"
    (codex:turn-diff-blob-text "")
    (codex:turn-diff-file-mode-regular)
    "3333333333333333333333333333333333333333"
    (codex:turn-diff-blob-text "hi\n"))
  ("diff --git a/n.txt b/n.txt\nnew file mode 100644\nindex 0000000000000000000000000000000000000000..3333333333333333333333333333333333333333\n--- /dev/null\n+++ b/n.txt\n@@ -0,0 +1 @@\n+hi\n"))

; deletion
!(assertEqualToResult
  (codex:turn-diff-file-diff "d.txt" "d.txt"
    (codex:turn-diff-file-mode-regular)
    "4444444444444444444444444444444444444444"
    (codex:turn-diff-blob-text "bye\n")
    (codex:turn-diff-file-mode-regular)
    "0000000000000000000000000000000000000000"
    CodexAbsent)
  ("diff --git a/d.txt b/d.txt\ndeleted file mode 100644\nindex 4444444444444444444444444444444444444444..0000000000000000000000000000000000000000\n--- a/d.txt\n+++ /dev/null\n@@ -1 +0,0 @@\n-bye\n"))

; binary fallback
!(assertEqualToResult
  (codex:turn-diff-file-diff "b.bin" "b.bin"
    (codex:turn-diff-file-mode-regular)
    "5555555555555555555555555555555555555555"
    (codex:turn-diff-blob-binary "B1")
    (codex:turn-diff-file-mode-regular)
    "6666666666666666666666666666666666666666"
    (codex:turn-diff-blob-binary "B2"))
  ("diff --git a/b.bin b/b.bin\nindex 5555555555555555555555555555555555555555..6666666666666666666666666666666666666666\n--- a/b.bin\n+++ b/b.bin\nBinary files differ\n"))

; identical content short-circuits to an empty diff
!(assertEqualToResult
  (codex:turn-diff-file-diff "s.txt" "s.txt"
    (codex:turn-diff-file-mode-regular)
    "7777777777777777777777777777777777777777"
    (codex:turn-diff-blob-text "same\n")
    (codex:turn-diff-file-mode-regular)
    "7777777777777777777777777777777777777777"
    (codex:turn-diff-blob-text "same\n"))
  (""))

; --- aggregated diff -------------------------------------------------------------

; files are ordered by sort key and each diff ends with a newline
!(assertEqualToResult
  (codex:turn-diff-aggregate-views
    ((codex:turn-diff-file-view "z.txt" "z.txt" "z.txt"
       (codex:turn-diff-file-mode-regular)
       "1111111111111111111111111111111111111111"
       (codex:turn-diff-blob-text "1\n")
       (codex:turn-diff-file-mode-regular)
       "2222222222222222222222222222222222222222"
       (codex:turn-diff-blob-text "2\n"))
     (codex:turn-diff-file-view "a.txt" "a.txt" "a.txt"
       (codex:turn-diff-file-mode-regular)
       "3333333333333333333333333333333333333333"
       (codex:turn-diff-blob-text "3\n")
       (codex:turn-diff-file-mode-regular)
       "4444444444444444444444444444444444444444"
       (codex:turn-diff-blob-text "4\n"))))
  ("diff --git a/a.txt b/a.txt\nindex 3333333333333333333333333333333333333333..4444444444444444444444444444444444444444\n--- a/a.txt\n+++ b/a.txt\n@@ -1 +1 @@\n-3\n+4\ndiff --git a/z.txt b/z.txt\nindex 1111111111111111111111111111111111111111..2222222222222222222222222222222222222222\n--- a/z.txt\n+++ b/z.txt\n@@ -1 +1 @@\n-1\n+2\n"))

; all-unchanged trackers produce no diff
!(assertEqualToResult
  (codex:turn-diff-aggregate-views
    ((codex:turn-diff-file-view "s.txt" "s.txt" "s.txt"
       (codex:turn-diff-file-mode-regular)
       "7777777777777777777777777777777777777777"
       (codex:turn-diff-blob-text "same\n")
       (codex:turn-diff-file-mode-regular)
       "7777777777777777777777777777777777777777"
       (codex:turn-diff-blob-text "same\n"))))
  (CodexAbsent))
