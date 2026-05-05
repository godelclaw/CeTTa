!(import! &self git)
!(import! &self process)
!(import! &self str)

(= (git-test-root) "/home/zarclaw/repos/CeTTa/runtime/git-surface-repo")

!(process-run-shell-cwd-timeout-ms
   "rm -rf runtime/git-surface-repo && mkdir -p runtime/git-surface-repo && cd runtime/git-surface-repo && git init -q -b main && git config user.email test@example.invalid && git config user.name Test && printf 'one\n' > file.txt && git add file.txt && git commit -q -m initial && printf 'two\n' >> file.txt && git add file.txt && git commit -q -m second && git remote add origin https://example.invalid/repo.git && git update-ref refs/remotes/origin/main HEAD && git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main && git branch zed && printf 'three\n' >> file.txt && printf 'extra\n' > extra.txt"
   "/home/zarclaw/repos/CeTTa"
   5000)

!(assertEqualToResult
  (git-repo-root-path (git-repo-root (git-test-root)))
  ("/home/zarclaw/repos/CeTTa/runtime/git-surface-repo"))

!(assertEqualToResult
  (git-value-text (git-current-branch (git-test-root)))
  ("main"))

!(assertEqualToResult
  (git-value-text (git-default-branch (git-test-root)))
  ("main"))

!(assertEqualToResult
  (git-value-ok? (git-head-commit (git-test-root)))
  (True))

!(assertEqualToResult
  (> (str-length (git-value-text (git-head-commit (git-test-root)))) 0)
  (True))

!(assertEqualToResult
  (git-value-text (git-remote-url (git-test-root) "origin"))
  ("https://example.invalid/repo.git"))

!(assertEqualToResult
  (git-bool-value (git-has-changes? (git-test-root)))
  (True))

!(assertEqualToResult
  (git-command-stdout (git-status-porcelain (git-test-root)))
  (" M file.txt\n?? extra.txt\n"))

!(assertEqualToResult
  (git-command-ok? (git-diff (git-test-root)))
  (True))

!(assertEqualToResult
  (str-starts-with?
    (git-command-stdout (git-diff (git-test-root)))
    "diff --git a/file.txt b/file.txt")
  (True))

!(assertEqualToResult
  (git-command-ok? (git-diff-against (git-test-root) "HEAD"))
  (True))

!(assertEqualToResult
  (> (str-find (git-command-stdout (git-diff-against (git-test-root) "HEAD")) "extra.txt") 0)
  (True))

!(assertEqualToResult
  (git-command-stdout (git-show (git-test-root) "HEAD:file.txt"))
  ("one\ntwo\n"))

!(assertEqualToResult
  (git-commit-subject
    (git-first-commit (git-recent-commits (git-test-root) 2)))
  ("second"))

!(assertEqualToResult
  (git-commit-subject
    (git-second-commit (git-recent-commits (git-test-root) 2)))
  ("initial"))

!(assertEqualToResult
  (git-local-branches (git-test-root))
  (("main" "zed")))

!(assertEqual
  (git-value-text (git-merge-base-with-head (git-test-root) "main"))
  (git-value-text (git-head-commit (git-test-root))))

!(assertEqualToResult
  (git-info-branch (git-collect-info (git-test-root)))
  ("main"))

!(assertEqualToResult
  (git-info-remote-url (git-collect-info (git-test-root)))
  ("https://example.invalid/repo.git"))

!(assertEqualToResult
  (git-info-has-changes? (git-collect-info (git-test-root)))
  (True))
