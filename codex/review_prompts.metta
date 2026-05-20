; Narrow Rust-faithful review-prompts slice.
;
; This ports the pure prompt-rendering and request-resolution behavior from:
; - openai-codex/codex-rs/core/src/review_prompts.rs
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust calls `merge_base_with_head(cwd, branch)` inside `review_prompt` for
;   base-branch reviews. This CeTTa slice takes that optional merge-base SHA as
;   an explicit input so the prompt-selection algorithm remains pure and
;   testable until the git lookup layer is ported.

!(import! &self protocol)
!(import! &self str)

(= (codex:resolved-review-request $target $prompt $user-facing-hint)
   (CodexResolvedReviewRequest $target $prompt $user-facing-hint))

(= (codex:resolved-review-request-target
      (CodexResolvedReviewRequest $target $prompt $user-facing-hint))
   $target)

(= (codex:resolved-review-request-prompt
      (CodexResolvedReviewRequest $target $prompt $user-facing-hint))
   $prompt)

(= (codex:resolved-review-request-user-facing-hint
      (CodexResolvedReviewRequest $target $prompt $user-facing-hint))
   $user-facing-hint)

(= (codex:review-prompt-result-ok $prompt)
   (CodexReviewPromptOk $prompt))

(= (codex:review-prompt-result-err $message)
   (CodexReviewPromptErr $message))

(= (codex:review-prompt-result-kind (CodexReviewPromptOk $prompt))
   ok)

(= (codex:review-prompt-result-kind (CodexReviewPromptErr $message))
   err)

(= (codex:review-prompt-result-value (CodexReviewPromptOk $prompt))
   $prompt)

(= (codex:review-prompt-result-message (CodexReviewPromptErr $message))
   $message)

(= (codex:review-prompts-uncommitted-prompt)
   "Review the current code changes (staged, unstaged, and untracked files) and provide prioritized findings.")

(= (codex:review-prompts-custom-empty-error)
   "Review prompt cannot be empty")

(= (codex:review-prompts-base-branch-backup-prompt $branch)
   (str-concat
     (str-concat
       (str-concat
         (str-concat
           (str-concat
             "Review the code changes against the base branch '"
             $branch)
           "'. Start by finding the merge diff between the current branch and ")
         $branch)
       "'s upstream e.g. (`git merge-base HEAD \"$(git rev-parse --abbrev-ref \"")
     (str-concat
       (str-concat
         (str-concat
           (str-concat
             $branch
             "@{upstream}\")\"`), then run `git diff` against that SHA to see what changes we would merge into the ")
           $branch)
         " branch. Provide prioritized, actionable findings.")
       "")))

(= (codex:review-prompts-base-branch-prompt $branch $merge-base-sha)
   (format-args
     "Review the code changes against the base branch '{}'. The merge base commit for this comparison is {}. Run `git diff {}` to inspect the changes relative to {}. Provide prioritized, actionable findings."
     ($branch $merge-base-sha $merge-base-sha $branch)))

(= (codex:review-prompts-commit-prompt $sha $title)
   (if (== $title CodexAbsent)
       (format-args
         "Review the code changes introduced by commit {}. Provide prioritized, actionable findings."
         ($sha))
       (format-args
         "Review the code changes introduced by commit {} (\"{}\"). Provide prioritized, actionable findings."
         ($sha $title))))

(= (codex:review-prompt
      (CodexReviewTargetUncommittedChanges)
      $merge-base-sha)
   (codex:review-prompt-result-ok
     (codex:review-prompts-uncommitted-prompt)))

(= (codex:review-prompt
      (CodexReviewTargetBaseBranch $branch)
      $merge-base-sha)
   (codex:review-prompt-result-ok
     (if (== $merge-base-sha CodexAbsent)
         (codex:review-prompts-base-branch-backup-prompt $branch)
         (codex:review-prompts-base-branch-prompt
           $branch
           $merge-base-sha))))

(= (codex:review-prompt
      (CodexReviewTargetCommit $sha $title)
      $merge-base-sha)
   (codex:review-prompt-result-ok
     (codex:review-prompts-commit-prompt $sha $title)))

(= (codex:review-prompt
      (CodexReviewTargetCustom $instructions)
      $merge-base-sha)
   (let $prompt (str-trim $instructions)
     (if (== $prompt "")
         (codex:review-prompt-result-err
           (codex:review-prompts-custom-empty-error))
         (codex:review-prompt-result-ok $prompt))))

(= (codex:review-prompts-short-sha $sha)
   (let $len (str-length $sha)
     (if (< $len 7)
         $sha
         (str-slice $sha 0 7))))

(= (codex:review-prompts-user-facing-hint
      (CodexReviewTargetUncommittedChanges))
   "current changes")

(= (codex:review-prompts-user-facing-hint
      (CodexReviewTargetBaseBranch $branch))
   (format-args "changes against '{}'" ($branch)))

(= (codex:review-prompts-user-facing-hint
      (CodexReviewTargetCommit $sha $title))
   (if (== $title CodexAbsent)
       (format-args
         "commit {}"
         ((codex:review-prompts-short-sha $sha)))
       (format-args
         "commit {}: {}"
         ((codex:review-prompts-short-sha $sha) $title))))

(= (codex:review-prompts-user-facing-hint
      (CodexReviewTargetCustom $instructions))
   (str-trim $instructions))

(= (codex:resolve-review-request-with-merge-base
      (CodexReviewRequest $target $user-facing-hint)
      $merge-base-sha)
   (let $prompt-result (codex:review-prompt $target $merge-base-sha)
     (case $prompt-result
       (((CodexReviewPromptOk $prompt)
         (codex:review-prompt-result-ok
           (codex:resolved-review-request
             $target
             $prompt
             (if (== $user-facing-hint CodexAbsent)
                 (codex:review-prompts-user-facing-hint $target)
                 $user-facing-hint))))
        ((CodexReviewPromptErr $message)
         (codex:review-prompt-result-err $message))))))

(= (codex:resolved-review-request-to-review-request
      (CodexResolvedReviewRequest $target $prompt $user-facing-hint))
   (codex:review-request $target $user-facing-hint))
