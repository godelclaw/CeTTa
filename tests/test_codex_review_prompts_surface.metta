!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:review_prompts)

!(assertEqual
  (codex:review-prompt-result-value
    (codex:review-prompt
      (codex:review-target-uncommitted-changes)
      CodexAbsent))
  "Review the current code changes (staged, unstaged, and untracked files) and provide prioritized findings.")

!(assertEqual
  (codex:review-prompt-result-value
    (codex:review-prompt
      (codex:review-target-base-branch "main")
      CodexAbsent))
  "Review the code changes against the base branch 'main'. Start by finding the merge diff between the current branch and main's upstream e.g. (`git merge-base HEAD \"$(git rev-parse --abbrev-ref \"main@{upstream}\")\"`), then run `git diff` against that SHA to see what changes we would merge into the main branch. Provide prioritized, actionable findings.")

!(assertEqual
  (codex:review-prompt-result-value
    (codex:review-prompt
      (codex:review-target-base-branch "main")
      "abc123"))
  "Review the code changes against the base branch 'main'. The merge base commit for this comparison is abc123. Run `git diff abc123` to inspect the changes relative to main. Provide prioritized, actionable findings.")

!(assertEqual
  (codex:review-prompt-result-value
    (codex:review-prompt
      (codex:review-target-commit "deadbeef" CodexAbsent)
      CodexAbsent))
  "Review the code changes introduced by commit deadbeef. Provide prioritized, actionable findings.")

!(assertEqual
  (codex:review-prompt-result-value
    (codex:review-prompt
      (codex:review-target-commit "deadbeef" "Fix bug")
      CodexAbsent))
  "Review the code changes introduced by commit deadbeef (\"Fix bug\"). Provide prioritized, actionable findings.")

!(assertEqual
  (codex:review-prompt-result-value
    (codex:review-prompt
      (codex:review-target-custom "  Check only migrations.  ")
      CodexAbsent))
  "Check only migrations.")

!(assertEqual
  (codex:review-prompt-result-kind
    (codex:review-prompt
      (codex:review-target-custom "   ")
      CodexAbsent))
  err)

!(assertEqual
  (codex:review-prompt-result-message
    (codex:review-prompt
      (codex:review-target-custom "   ")
      CodexAbsent))
  "Review prompt cannot be empty")

!(assertEqual
  (codex:review-prompts-user-facing-hint
    (codex:review-target-uncommitted-changes))
  "current changes")

!(assertEqual
  (codex:review-prompts-user-facing-hint
    (codex:review-target-base-branch "main"))
  "changes against 'main'")

!(assertEqual
  (codex:review-prompts-user-facing-hint
    (codex:review-target-commit "deadbeefcafebabe" CodexAbsent))
  "commit deadbee")

!(assertEqual
  (codex:review-prompts-user-facing-hint
    (codex:review-target-commit "deadbeefcafebabe" "Fix bug"))
  "commit deadbee: Fix bug")

!(assertEqual
  (codex:review-prompts-user-facing-hint
    (codex:review-target-custom "  custom hint  "))
  "custom hint")

!(assertEqual
  (codex:resolved-review-request-prompt
    (codex:review-prompt-result-value
      (codex:resolve-review-request-with-merge-base
        (codex:review-request
          (codex:review-target-base-branch "trunk")
          CodexAbsent)
        "ff00aa")))
  "Review the code changes against the base branch 'trunk'. The merge base commit for this comparison is ff00aa. Run `git diff ff00aa` to inspect the changes relative to trunk. Provide prioritized, actionable findings.")

!(assertEqual
  (codex:resolved-review-request-user-facing-hint
    (codex:review-prompt-result-value
      (codex:resolve-review-request-with-merge-base
        (codex:review-request
          (codex:review-target-base-branch "trunk")
          CodexAbsent)
        "ff00aa")))
  "changes against 'trunk'")

!(assertEqual
  (codex:resolved-review-request-user-facing-hint
    (codex:review-prompt-result-value
      (codex:resolve-review-request-with-merge-base
        (codex:review-request
          (codex:review-target-base-branch "trunk")
          "check migrations")
        "ff00aa")))
  "check migrations")

!(assertEqual
  (codex:resolved-review-request-to-review-request
    (codex:review-prompt-result-value
      (codex:resolve-review-request-with-merge-base
        (codex:review-request
          (codex:review-target-commit "123456789" CodexAbsent)
          CodexAbsent)
        CodexAbsent)))
  (codex:review-request
    (codex:review-target-commit "123456789" CodexAbsent)
    "commit 1234567"))
