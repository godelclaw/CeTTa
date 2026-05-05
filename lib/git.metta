(= (git-repo-root $cwd)
   (function
     (case (__cetta_lib_git_repo_root $cwd)
       (($result (return $result))))))

(= (git-current-branch $cwd)
   (function
     (case (__cetta_lib_git_current_branch $cwd)
       (($result (return $result))))))

(= (git-default-branch $cwd)
   (function
     (case (__cetta_lib_git_default_branch $cwd)
       (($result (return $result))))))

(= (git-head-commit $cwd)
   (function
     (case (__cetta_lib_git_head_commit $cwd)
       (($result (return $result))))))

(= (git-remote-url $cwd $remote)
   (function
     (case (__cetta_lib_git_remote_url $cwd $remote)
       (($result (return $result))))))

(= (git-has-changes? $cwd)
   (function
     (case (__cetta_lib_git_has_changes $cwd)
       (($result (return $result))))))

(= (git-status-porcelain $cwd)
   (function
     (case (__cetta_lib_git_status_porcelain $cwd)
       (($result (return $result))))))

(= (git-diff $cwd)
   (function
     (case (__cetta_lib_git_diff $cwd)
       (($result (return $result))))))

(= (git-diff-against $cwd $revspec)
   (function
     (case (__cetta_lib_git_diff_against $cwd $revspec)
       (($result (return $result))))))

(= (git-show $cwd $revspec)
   (function
     (case (__cetta_lib_git_show $cwd $revspec)
       (($result (return $result))))))

(= (git-recent-commits $cwd $limit)
   (function
     (case (__cetta_lib_git_recent_commits $cwd $limit)
       (($result (return $result))))))

(= (git-local-branches $cwd)
   (function
     (case (__cetta_lib_git_local_branches $cwd)
       (($result (return $result))))))

(= (git-merge-base-with-head $cwd $branch)
   (function
     (case (__cetta_lib_git_merge_base_with_head $cwd $branch)
       (($result (return $result))))))

(= (git-collect-info $cwd)
   (function
     (case (__cetta_lib_git_collect_info $cwd)
       (($result (return $result))))))

(= (git-repo-root-ok? (GitRepoRoot $ok $root))
   $ok)

(= (git-repo-root-path (GitRepoRoot $ok $root))
   $root)

(= (git-value-ok? (GitValue $ok $value $stderr))
   $ok)

(= (git-value-text (GitValue $ok $value $stderr))
   $value)

(= (git-value-stderr (GitValue $ok $value $stderr))
   $stderr)

(= (git-bool-ok? (GitBool $ok $value $stderr))
   $ok)

(= (git-bool-value (GitBool $ok $value $stderr))
   $value)

(= (git-command-ok? (GitCommandResult $ok $exit-code $stdout $stderr $timed-out))
   $ok)

(= (git-command-exit-code (GitCommandResult $ok $exit-code $stdout $stderr $timed-out))
   $exit-code)

(= (git-command-stdout (GitCommandResult $ok $exit-code $stdout $stderr $timed-out))
   $stdout)

(= (git-command-stderr (GitCommandResult $ok $exit-code $stdout $stderr $timed-out))
   $stderr)

(= (git-command-timed-out? (GitCommandResult $ok $exit-code $stdout $stderr $timed-out))
   $timed-out)

(= (git-commit-sha (GitCommit $sha $timestamp $subject))
   $sha)

(= (git-commit-timestamp (GitCommit $sha $timestamp $subject))
   $timestamp)

(= (git-commit-subject (GitCommit $sha $timestamp $subject))
   $subject)

(= (git-first-commit ((GitCommit $sha $timestamp $subject) $rest))
   (GitCommit $sha $timestamp $subject))

(= (git-second-commit ((GitCommit $sha1 $timestamp1 $subject1) (GitCommit $sha2 $timestamp2 $subject2)))
   (GitCommit $sha2 $timestamp2 $subject2))

(= (git-info-ok? (GitInfo $ok $repo-root $head-commit $branch $remote-url $has-changes))
   $ok)

(= (git-info-repo-root (GitInfo $ok $repo-root $head-commit $branch $remote-url $has-changes))
   $repo-root)

(= (git-info-head-commit (GitInfo $ok $repo-root $head-commit $branch $remote-url $has-changes))
   $head-commit)

(= (git-info-branch (GitInfo $ok $repo-root $head-commit $branch $remote-url $has-changes))
   $branch)

(= (git-info-remote-url (GitInfo $ok $repo-root $head-commit $branch $remote-url $has-changes))
   $remote-url)

(= (git-info-has-changes? (GitInfo $ok $repo-root $head-commit $branch $remote-url $has-changes))
   $has-changes)
