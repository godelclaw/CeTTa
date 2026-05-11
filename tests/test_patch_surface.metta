!(import! &self fs)
!(import! &self list)
!(import! &self patch)
(= (patch-test-cwd) "/home/zarclaw/repos/CeTTa")

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/patch-existing.txt" "one\ntwo\nthree\n")
!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/patch-delete.txt" "gone\n")

!(assertEqualToResult
  (let $result
       (patch-apply
         (patch-test-cwd)
         "*** Begin Patch\n*** Add File: runtime/patch-added.txt\n+alpha\n+beta\n*** Update File: runtime/patch-existing.txt\n@@\n one\n-two\n+TWO\n three\n*** Delete File: runtime/patch-delete.txt\n*** End Patch")
    (patch-result-ok? $result))
  (True))

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/patch-added.txt")
  ("alpha\nbeta\n"))

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/patch-existing.txt")
  ("one\nTWO\nthree\n"))

!(assertEqual
  (fs-exists? "/home/zarclaw/repos/CeTTa/runtime/patch-delete.txt")
  False)

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/patch-move-source.txt" "old\n")

!(assertEqualToResult
  (patch-result-ok?
    (patch-apply
      (patch-test-cwd)
      "*** Begin Patch\n*** Update File: runtime/patch-move-source.txt\n*** Move to: runtime/patch-moved/dest.txt\n@@\n-old\n+new\n*** End Patch"))
  (True))

!(assertEqual
  (fs-exists? "/home/zarclaw/repos/CeTTa/runtime/patch-move-source.txt")
  False)

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/patch-moved/dest.txt")
  ("new\n"))

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/patch-inspect-source.txt" "before\n")

!(assertEqualToResult
  (patch-inspect-ok?
    (patch-inspect
      (patch-test-cwd)
      "*** Begin Patch\n*** Add File: runtime/patch-inspect-added.txt\n+alpha\n*** Update File: runtime/patch-inspect-source.txt\n*** Move to: runtime/patch-inspect-moved.txt\n@@\n-before\n+after\n*** End Patch"))
  (True))

!(let $inspection
    (patch-inspect
      (patch-test-cwd)
      "*** Begin Patch\n*** Add File: runtime/patch-inspect-added.txt\n+alpha\n*** Update File: runtime/patch-inspect-source.txt\n*** Move to: runtime/patch-inspect-moved.txt\n@@\n-before\n+after\n*** End Patch")
  (let $changes (patch-action-changes (patch-inspect-action $inspection))
    (assertEqualToResult
      (patch-action-change-kind (list:first $changes))
      ("add"))))

!(let $inspection
    (patch-inspect
      (patch-test-cwd)
      "*** Begin Patch\n*** Add File: runtime/patch-inspect-added.txt\n+alpha\n*** Update File: runtime/patch-inspect-source.txt\n*** Move to: runtime/patch-inspect-moved.txt\n@@\n-before\n+after\n*** End Patch")
  (let $changes (patch-action-changes (patch-inspect-action $inspection))
    (assertEqualToResult
      (patch-action-change-move-path (list:at $changes 1))
      ("runtime/patch-inspect-moved.txt"))))

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/patch-inspect-source.txt")
  ("before\n"))

!(assertEqualToResult
  (patch-result-ok?
    (patch-apply
      (patch-test-cwd)
      "*** Begin Patch\n*** Add File: ../outside.txt\n+no\n*** End Patch"))
  (False))

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/patch-shell-target.txt" "shell-before\n")

!(assertEqualToResult
  (patch-shell-intercept-matched?
    (patch-intercept-shell-command
      (patch-test-cwd)
      "apply_patch <<'PATCH'\n*** Begin Patch\n*** Update File: runtime/patch-shell-target.txt\n@@\n-shell-before\n+shell-after\n*** End Patch\nPATCH"))
  (True))

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/patch-shell-target.txt")
  ("shell-after\n"))

!(assertEqualToResult
  (patch-shell-intercept-matched?
    (patch-intercept-shell-command
      (patch-test-cwd)
      "printf not-a-patch"))
  (False))

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/patch-shell-cd-target.txt" "cd-before\n")

!(assertEqualToResult
  (patch-result-ok?
    (patch-shell-intercept-result
      (patch-intercept-shell-command
        (patch-test-cwd)
        "cd runtime && apply_patch <<'PATCH'\n*** Begin Patch\n*** Update File: patch-shell-cd-target.txt\n@@\n-cd-before\n+cd-after\n*** End Patch\nPATCH")))
  (True))

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/patch-shell-cd-target.txt")
  ("cd-after\n"))

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/patch-shell-inspect-target.txt" "inspect-before\n")

!(assertEqualToResult
  (patch-shell-inspect-matched?
    (patch-inspect-shell-command
      (patch-test-cwd)
      "cd runtime && apply_patch <<'PATCH'\n*** Begin Patch\n*** Update File: patch-shell-inspect-target.txt\n@@\n-inspect-before\n+inspect-after\n*** End Patch\nPATCH"))
  (True))

!(assertEqualToResult
  (patch-shell-inspect-effective-cwd
    (patch-inspect-shell-command
      (patch-test-cwd)
      "cd runtime && apply_patch <<'PATCH'\n*** Begin Patch\n*** Update File: patch-shell-inspect-target.txt\n@@\n-inspect-before\n+inspect-after\n*** End Patch\nPATCH"))
  ("/home/zarclaw/repos/CeTTa/runtime"))

!(assertEqualToResult
  (patch-inspect-ok?
    (patch-shell-inspect-result
      (patch-inspect-shell-command
        (patch-test-cwd)
        "cd runtime && apply_patch <<'PATCH'\n*** Begin Patch\n*** Update File: patch-shell-inspect-target.txt\n@@\n-inspect-before\n+inspect-after\n*** End Patch\nPATCH")))
  (True))

!(assertEqualToResult
  (fs-read-text "/home/zarclaw/repos/CeTTa/runtime/patch-shell-inspect-target.txt")
  ("inspect-before\n"))
