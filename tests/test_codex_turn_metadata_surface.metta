!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:tool_config)
!(import! &self codex:sandbox_tags)
!(import! &self codex:turn_metadata)

(= (turn-metadata-test-state $session-source)
   (codex:turn-metadata-state-new
     "session-a"
     $session-source
     "turn-a"
     "/tmp/work"
     (codex:tool-config-sandbox-policy-read-only)
     "Disabled"
     (codex:host-platform-linux)
     CodexAbsent))

!(assertEqualToResult
  (codex:turn-metadata-workspace-git-metadata-is-empty
    (codex:turn-metadata-workspace-git-metadata
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  (True))

!(assertEqualToResult
  (codex:turn-metadata-workspace-git-metadata-is-empty
    (codex:turn-metadata-workspace-git-metadata
      ()
      CodexAbsent
      CodexAbsent))
  (False))

!(assertEqualToResult
  (codex:build-turn-metadata-header-from-git
    CodexAbsent
    CodexAbsent
    (codex:turn-metadata-workspace-git-metadata
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  (CodexAbsent))

!(assertEqualToResult
  (codex:build-turn-metadata-header-from-git
    "none"
    CodexAbsent
    (codex:turn-metadata-workspace-git-metadata
      CodexAbsent
      CodexAbsent
      CodexAbsent))
  ("{\"sandbox\":\"none\"}"))

!(assertEqualToResult
  (codex:build-turn-metadata-header-from-git
    "none"
    "/tmp/repo"
    (codex:turn-metadata-workspace-git-metadata
      CodexAbsent
      CodexAbsent
      False))
  ("{\"workspaces\":{\"/tmp/repo\":{\"has_changes\":false}},\"sandbox\":\"none\"}"))

!(assertEqualToResult
  (codex:build-turn-metadata-header-from-git
    CodexAbsent
    CodexAbsent
    (codex:turn-metadata-workspace-git-metadata
      CodexAbsent
      CodexAbsent
      True))
  ("{}"))

!(assertEqualToResult
  (codex:build-turn-metadata-header-from-git
    CodexAbsent
    "/tmp/repo"
    (codex:turn-metadata-workspace-git-metadata
      ((codex:turn-metadata-remote-url "origin" "git@example.com:repo.git"))
      "abc123"
      True))
  ("{\"workspaces\":{\"/tmp/repo\":{\"associated_remote_urls\":{\"origin\":\"git@example.com:repo.git\"},\"latest_git_commit_hash\":\"abc123\",\"has_changes\":true}}}"))

!(assertEqualToResult
  (codex:turn-metadata-state-current-header-value
    (turn-metadata-test-state (codex:session-source-exec)))
  ("{\"session_id\":\"session-a\",\"thread_source\":\"user\",\"turn_id\":\"turn-a\",\"sandbox\":\"seccomp\"}"))

!(let $state
    (turn-metadata-test-state
      (codex:session-source-subagent
        (codex:subagent-source-review)))
  (assertEqualToResult
    (json-string-value
      (json-object-get
        (codex:turn-metadata-state-current-meta-value $state)
        "thread_source"))
    ("subagent")))

!(let $state
    (codex:turn-metadata-state-with-responsesapi-client-metadata
      (turn-metadata-test-state (codex:session-source-exec))
      ((codex:turn-metadata-client-metadata "fiber_run_id" "fiber-123")
       (codex:turn-metadata-client-metadata "session_id" "client-supplied")
       (codex:turn-metadata-client-metadata "thread_source" "client-supplied")))
  (let $json (codex:turn-metadata-state-current-meta-value $state)
    (assertEqualToResult
      (json-string-value (json-object-get $json "fiber_run_id"))
      ("fiber-123"))))

!(let $state
    (codex:turn-metadata-state-with-responsesapi-client-metadata
      (turn-metadata-test-state (codex:session-source-exec))
      ((codex:turn-metadata-client-metadata "fiber_run_id" "fiber-123")
       (codex:turn-metadata-client-metadata "session_id" "client-supplied")
       (codex:turn-metadata-client-metadata "thread_source" "client-supplied")))
  (let $json (codex:turn-metadata-state-current-meta-value $state)
    (assertEqualToResult
      (json-string-value (json-object-get $json "session_id"))
      ("session-a"))))

!(let $state
    (codex:turn-metadata-state-with-responsesapi-client-metadata
      (turn-metadata-test-state (codex:session-source-exec))
      ((codex:turn-metadata-client-metadata "fiber_run_id" "fiber-123")
       (codex:turn-metadata-client-metadata "session_id" "client-supplied")
       (codex:turn-metadata-client-metadata "thread_source" "client-supplied")))
  (let $json (codex:turn-metadata-state-current-meta-value $state)
    (assertEqualToResult
      (json-string-value (json-object-get $json "thread_source"))
      ("user"))))

!(let $state
    (codex:turn-metadata-state-spawn-git-enrichment-task
      (codex:turn-metadata-state-new
        "session-a"
        (codex:session-source-exec)
        "turn-a"
        "/tmp/work"
        (codex:tool-config-sandbox-policy-read-only)
        "Disabled"
        (codex:host-platform-linux)
        "/tmp/repo")
      (codex:turn-metadata-workspace-git-metadata
        CodexAbsent
        CodexAbsent
        False))
  (assertEqualToResult
    (codex:turn-metadata-state-current-header-value $state)
    ("{\"session_id\":\"session-a\",\"thread_source\":\"user\",\"turn_id\":\"turn-a\",\"workspaces\":{\"/tmp/repo\":{\"has_changes\":false}},\"sandbox\":\"seccomp\"}")))

!(let $state
    (codex:turn-metadata-state-cancel-git-enrichment-task
      (codex:turn-metadata-state-spawn-git-enrichment-task
        (codex:turn-metadata-state-new
          "session-a"
          (codex:session-source-exec)
          "turn-a"
          "/tmp/work"
          (codex:tool-config-sandbox-policy-read-only)
          "Disabled"
          (codex:host-platform-linux)
          "/tmp/repo")
        (codex:turn-metadata-workspace-git-metadata
          CodexAbsent
          CodexAbsent
          False)))
  (assertEqualToResult
    (codex:turn-metadata-state-enrichment-task-started $state)
    (False)))
