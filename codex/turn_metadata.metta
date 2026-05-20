; Rust-faithful pure turn-metadata helper slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/turn_metadata.rs
;
; Covered in this increment:
; - WorkspaceGitMetadata emptiness
; - TurnMetadataWorkspace / TurnMetadataBag JSON header projection
; - build_turn_metadata_bag
; - build_turn_metadata_header after git metadata has been materialized
; - responsesapi_client_metadata merge without replacing reserved/base keys
; - TurnMetadataState base-header/current-header behavior
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust discovers the git repo root and git metadata asynchronously, then stores
;   enriched headers behind locks. This pure CeTTa boundary receives the repo
;   root and git metadata as explicit values, and returns updated state values.
; - Rust serializes BTreeMap fields in sorted key order. This CeTTa slice uses
;   caller-supplied ordered entry lists for map-like fields; single-workspace
;   construction matches Rust directly, and multi-entry callers must provide the
;   already-sorted BTreeMap iteration order.

!(import! &self json)
!(import! &self protocol)
!(import! &self sandbox_tags)

(= (codex:turn-metadata-remote-url $name $url)
   (CodexTurnMetadataRemoteUrl $name $url))

(= (codex:turn-metadata-remote-url-name
      (CodexTurnMetadataRemoteUrl $name $url))
   $name)

(= (codex:turn-metadata-remote-url-url
      (CodexTurnMetadataRemoteUrl $name $url))
   $url)

(= (codex:turn-metadata-workspace-git-metadata
      $associated-remote-urls
      $latest-git-commit-hash
      $has-changes)
   (CodexTurnMetadataWorkspaceGitMetadata
     $associated-remote-urls
     $latest-git-commit-hash
     $has-changes))

(= (codex:turn-metadata-workspace-git-metadata-associated-remote-urls
      (CodexTurnMetadataWorkspaceGitMetadata
        $associated-remote-urls
        $latest-git-commit-hash
        $has-changes))
   $associated-remote-urls)

(= (codex:turn-metadata-workspace-git-metadata-latest-git-commit-hash
      (CodexTurnMetadataWorkspaceGitMetadata
        $associated-remote-urls
        $latest-git-commit-hash
        $has-changes))
   $latest-git-commit-hash)

(= (codex:turn-metadata-workspace-git-metadata-has-changes
      (CodexTurnMetadataWorkspaceGitMetadata
        $associated-remote-urls
        $latest-git-commit-hash
        $has-changes))
   $has-changes)

(= (codex:turn-metadata-workspace-git-metadata-is-empty
      (CodexTurnMetadataWorkspaceGitMetadata
        $associated-remote-urls
        $latest-git-commit-hash
        $has-changes))
   (and
     (== $associated-remote-urls CodexAbsent)
     (and
       (== $latest-git-commit-hash CodexAbsent)
       (== $has-changes CodexAbsent))))

(= (codex:turn-metadata-workspace $associated-remote-urls $latest-git-commit-hash $has-changes)
   (CodexTurnMetadataWorkspace
     $associated-remote-urls
     $latest-git-commit-hash
     $has-changes))

(= (codex:turn-metadata-workspace-from-git-metadata
      (CodexTurnMetadataWorkspaceGitMetadata
        $associated-remote-urls
        $latest-git-commit-hash
        $has-changes))
   (CodexTurnMetadataWorkspace
     $associated-remote-urls
     $latest-git-commit-hash
     $has-changes))

(= (codex:turn-metadata-workspace-entry $path $workspace)
   (CodexTurnMetadataWorkspaceEntry $path $workspace))

(= (codex:turn-metadata-workspace-entry-path
      (CodexTurnMetadataWorkspaceEntry $path $workspace))
   $path)

(= (codex:turn-metadata-workspace-entry-workspace
      (CodexTurnMetadataWorkspaceEntry $path $workspace))
   $workspace)

(= (codex:turn-metadata-bag
      $session-id
      $thread-source
      $turn-id
      $workspaces
      $sandbox)
   (CodexTurnMetadataBag
     $session-id
     $thread-source
     $turn-id
     $workspaces
     $sandbox))

(= (codex:turn-metadata-bag-session-id
      (CodexTurnMetadataBag
        $session-id
        $thread-source
        $turn-id
        $workspaces
        $sandbox))
   $session-id)

(= (codex:turn-metadata-bag-thread-source
      (CodexTurnMetadataBag
        $session-id
        $thread-source
        $turn-id
        $workspaces
        $sandbox))
   $thread-source)

(= (codex:turn-metadata-bag-turn-id
      (CodexTurnMetadataBag
        $session-id
        $thread-source
        $turn-id
        $workspaces
        $sandbox))
   $turn-id)

(= (codex:turn-metadata-bag-workspaces
      (CodexTurnMetadataBag
        $session-id
        $thread-source
        $turn-id
        $workspaces
        $sandbox))
   $workspaces)

(= (codex:turn-metadata-bag-sandbox
      (CodexTurnMetadataBag
        $session-id
        $thread-source
        $turn-id
        $workspaces
        $sandbox))
   $sandbox)

(= (codex:turn-metadata-client-metadata $key $value)
   (CodexTurnMetadataClientMetadata $key $value))

(= (codex:turn-metadata-json-prepend-pair $pairs $key $value)
   (cons-atom (JsonPair $key $value) $pairs))

(= (codex:turn-metadata-json-prepend-optional-bool-pair $pairs $key $value)
   (if (== $value CodexAbsent)
       $pairs
       (codex:turn-metadata-json-prepend-pair
         $pairs
         $key
         (JsonBool $value))))

(= (codex:turn-metadata-json-prepend-optional-string-pair $pairs $key $value)
   (if (== $value CodexAbsent)
       $pairs
       (codex:turn-metadata-json-prepend-pair
         $pairs
         $key
         (JsonString $value))))

(= (codex:turn-metadata-remote-urls-json-pairs ())
   ())

(= (codex:turn-metadata-remote-urls-json-pairs $remote-urls)
   (let ($head $tail) (decons-atom $remote-urls)
     (let $rest (codex:turn-metadata-remote-urls-json-pairs $tail)
       (cons-atom
         (JsonPair
           (codex:turn-metadata-remote-url-name $head)
           (JsonString (codex:turn-metadata-remote-url-url $head)))
         $rest))))

(= (codex:turn-metadata-workspace-json
      (CodexTurnMetadataWorkspace
        $associated-remote-urls
        $latest-git-commit-hash
        $has-changes))
   (let $pairs-after-has-changes
     (codex:turn-metadata-json-prepend-optional-bool-pair
       ()
       "has_changes"
       $has-changes)
     (let $pairs-after-hash
       (codex:turn-metadata-json-prepend-optional-string-pair
         $pairs-after-has-changes
         "latest_git_commit_hash"
         $latest-git-commit-hash)
       (JsonObject
         (if (== $associated-remote-urls CodexAbsent)
             $pairs-after-hash
             (cons-atom
               (JsonPair
                 "associated_remote_urls"
                 (JsonObject
                   (codex:turn-metadata-remote-urls-json-pairs
                     $associated-remote-urls)))
               $pairs-after-hash))))))

(= (codex:turn-metadata-workspaces-json-pairs ())
   ())

(= (codex:turn-metadata-workspaces-json-pairs $workspaces)
   (let ($head $tail) (decons-atom $workspaces)
     (let $rest (codex:turn-metadata-workspaces-json-pairs $tail)
       (cons-atom
         (JsonPair
           (codex:turn-metadata-workspace-entry-path $head)
           (codex:turn-metadata-workspace-json
             (codex:turn-metadata-workspace-entry-workspace $head)))
         $rest))))

(= (codex:turn-metadata-json-prepend-workspaces-pair $pairs $workspaces)
   (if (== $workspaces ())
       $pairs
       (cons-atom
         (JsonPair
           "workspaces"
           (JsonObject (codex:turn-metadata-workspaces-json-pairs $workspaces)))
         $pairs)))

(= (codex:turn-metadata-bag-json
      (CodexTurnMetadataBag
        $session-id
        $thread-source
        $turn-id
        $workspaces
        $sandbox))
   (let $pairs-after-sandbox
     (codex:turn-metadata-json-prepend-optional-string-pair
       ()
       "sandbox"
       $sandbox)
     (let $pairs-after-workspaces
       (codex:turn-metadata-json-prepend-workspaces-pair
         $pairs-after-sandbox
         $workspaces)
       (let $pairs-after-turn
         (codex:turn-metadata-json-prepend-optional-string-pair
           $pairs-after-workspaces
           "turn_id"
           $turn-id)
         (let $pairs-after-thread
           (codex:turn-metadata-json-prepend-optional-string-pair
             $pairs-after-turn
             "thread_source"
             $thread-source)
           (JsonObject
             (codex:turn-metadata-json-prepend-optional-string-pair
               $pairs-after-thread
               "session_id"
               $session-id)))))))

(= (codex:turn-metadata-bag-to-header-value $bag)
   (json-stringify (codex:turn-metadata-bag-json $bag)))

(= (codex:build-turn-metadata-workspaces $repo-root $workspace-git-metadata)
   (if (== $repo-root CodexAbsent)
       ()
       (if (== $workspace-git-metadata CodexAbsent)
           ()
           (if (codex:turn-metadata-workspace-git-metadata-is-empty
                 $workspace-git-metadata)
               ()
               ((codex:turn-metadata-workspace-entry
                  $repo-root
                  (codex:turn-metadata-workspace-from-git-metadata
                    $workspace-git-metadata)))))))

(= (codex:build-turn-metadata-bag
      $session-id
      $thread-source
      $turn-id
      $sandbox
      $repo-root
      $workspace-git-metadata)
   (codex:turn-metadata-bag
     $session-id
     $thread-source
     $turn-id
     (codex:build-turn-metadata-workspaces
       $repo-root
       $workspace-git-metadata)
     $sandbox))

(= (codex:build-turn-metadata-header-from-git
      $sandbox
      $repo-root
      $workspace-git-metadata)
   (if (== $sandbox CodexAbsent)
       (if (== $workspace-git-metadata CodexAbsent)
           CodexAbsent
           (if (codex:turn-metadata-workspace-git-metadata-is-empty
                 $workspace-git-metadata)
               CodexAbsent
               (codex:turn-metadata-bag-to-header-value
                 (codex:build-turn-metadata-bag
                   CodexAbsent
                   CodexAbsent
                   CodexAbsent
                   $sandbox
                   $repo-root
                   $workspace-git-metadata))))
       (codex:turn-metadata-bag-to-header-value
         (codex:build-turn-metadata-bag
           CodexAbsent
           CodexAbsent
           CodexAbsent
           $sandbox
           $repo-root
           $workspace-git-metadata))))

(= (codex:turn-metadata-json-pairs-has-key () $key)
   False)

(= (codex:turn-metadata-json-pairs-has-key $pairs $key)
   (let ($head $tail) (decons-atom $pairs)
     (case $head
       (((JsonPair $pair-key $value)
         (if (== $pair-key $key)
             True
             (codex:turn-metadata-json-pairs-has-key $tail $key)))))))

(= (codex:turn-metadata-merge-client-metadata-pairs $pairs ())
   $pairs)

(= (codex:turn-metadata-merge-client-metadata-pairs $pairs $metadata)
   (let ($head $tail) (decons-atom $metadata)
     (case $head
       (((CodexTurnMetadataClientMetadata $key $value)
         (let $next-pairs
           (if (codex:turn-metadata-json-pairs-has-key $pairs $key)
               $pairs
               (codex:turn-metadata-json-prepend-pair
                 $pairs
                 $key
                 (JsonString $value)))
           (codex:turn-metadata-merge-client-metadata-pairs
             $next-pairs
             $tail)))))))

(= (codex:turn-metadata-merge-responsesapi-client-metadata $header $metadata)
   (if (== $metadata CodexAbsent)
       CodexAbsent
       (case (json-parse $header)
         (((JsonObject $pairs)
           (json-stringify
             (JsonObject
               (codex:turn-metadata-merge-client-metadata-pairs
                 $pairs
                 $metadata))))
          ($other CodexAbsent)))))

(= (codex:turn-metadata-state
      $cwd
      $repo-root
      $base-metadata
      $base-header
      $enriched-header
      $responsesapi-client-metadata
      $enrichment-task-started)
   (CodexTurnMetadataState
     $cwd
     $repo-root
     $base-metadata
     $base-header
     $enriched-header
     $responsesapi-client-metadata
     $enrichment-task-started))

(= (codex:turn-metadata-state-new
      $session-id
      $session-source
      $turn-id
      $cwd
      $sandbox-policy
      $windows-sandbox-level
      $host-platform
      $repo-root)
   (let $thread-source
     (once (eval (codex:session-source-thread-source-name $session-source)))
     (let $sandbox
       (once
         (eval
           (codex:sandbox-tag
             $sandbox-policy
             $windows-sandbox-level
             $host-platform)))
       (let $base-metadata
         (codex:build-turn-metadata-bag
           $session-id
           $thread-source
           $turn-id
           $sandbox
           CodexAbsent
           CodexAbsent)
         (codex:turn-metadata-state
           $cwd
           $repo-root
           $base-metadata
           (once (eval (codex:turn-metadata-bag-to-header-value $base-metadata)))
           CodexAbsent
           CodexAbsent
           False)))))

(= (codex:turn-metadata-state-cwd
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started))
   $cwd)

(= (codex:turn-metadata-state-repo-root
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started))
   $repo-root)

(= (codex:turn-metadata-state-base-metadata
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started))
   $base-metadata)

(= (codex:turn-metadata-state-base-header
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started))
   $base-header)

(= (codex:turn-metadata-state-enriched-header
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started))
   $enriched-header)

(= (codex:turn-metadata-state-responsesapi-client-metadata
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started))
   $responsesapi-client-metadata)

(= (codex:turn-metadata-state-enrichment-task-started
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started))
   $enrichment-task-started)

(= (codex:turn-metadata-state-current-header-base $base-header $enriched-header)
   (if (== $enriched-header CodexAbsent)
       $base-header
       $enriched-header))

(= (codex:turn-metadata-state-current-header-value
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started))
   (let $header
     (codex:turn-metadata-state-current-header-base
       $base-header
       $enriched-header)
     (let $merged
       (codex:turn-metadata-merge-responsesapi-client-metadata
         $header
         $responsesapi-client-metadata)
       (if (== $merged CodexAbsent)
           $header
           $merged))))

(= (codex:turn-metadata-state-current-meta-value $state)
   (json-parse (codex:turn-metadata-state-current-header-value $state)))

(= (codex:turn-metadata-state-with-responsesapi-client-metadata
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started)
      $new-metadata)
   (CodexTurnMetadataState
     $cwd
     $repo-root
     $base-metadata
     $base-header
     $enriched-header
     $new-metadata
     $enrichment-task-started))

(= (codex:turn-metadata-state-with-enriched-header
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started)
      $new-enriched-header)
   (CodexTurnMetadataState
     $cwd
     $repo-root
     $base-metadata
     $base-header
     $new-enriched-header
     $responsesapi-client-metadata
     $enrichment-task-started))

(= (codex:turn-metadata-state-cancel-git-enrichment-task
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started))
   (CodexTurnMetadataState
     $cwd
     $repo-root
     $base-metadata
     $base-header
     $enriched-header
     $responsesapi-client-metadata
     False))

(= (codex:turn-metadata-state-spawn-git-enrichment-task
      (CodexTurnMetadataState
        $cwd
        $repo-root
        $base-metadata
        $base-header
        $enriched-header
        $responsesapi-client-metadata
        $enrichment-task-started)
      $workspace-git-metadata)
   (if (== $repo-root CodexAbsent)
       (CodexTurnMetadataState
         $cwd
         $repo-root
         $base-metadata
         $base-header
         $enriched-header
         $responsesapi-client-metadata
         $enrichment-task-started)
       (if $enrichment-task-started
           (CodexTurnMetadataState
             $cwd
             $repo-root
             $base-metadata
             $base-header
             $enriched-header
             $responsesapi-client-metadata
             $enrichment-task-started)
           (let $enriched-metadata
             (codex:build-turn-metadata-bag
               (codex:turn-metadata-bag-session-id $base-metadata)
               (codex:turn-metadata-bag-thread-source $base-metadata)
               (codex:turn-metadata-bag-turn-id $base-metadata)
               (codex:turn-metadata-bag-sandbox $base-metadata)
               $repo-root
               $workspace-git-metadata)
             (if (== (codex:turn-metadata-bag-workspaces $enriched-metadata) ())
                 (CodexTurnMetadataState
                   $cwd
                   $repo-root
                   $base-metadata
                   $base-header
                   $enriched-header
                   $responsesapi-client-metadata
                   True)
                 (CodexTurnMetadataState
                   $cwd
                   $repo-root
                   $base-metadata
                   $base-header
                   (codex:turn-metadata-bag-to-header-value $enriched-metadata)
                   $responsesapi-client-metadata
                   True))))))
