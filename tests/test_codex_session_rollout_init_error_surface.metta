!(register-module! ../codex)
!(import! &self codex:error)
!(import! &self codex:session_rollout_init_error)

!(assertEqualToResult
  (codex:sessions-subdir)
  ("sessions"))

!(assertEqualToResult
  (codex:error-display
    (codex:error-fatal "boom"))
  ("Fatal error: boom"))

!(assertEqualToResult
  (codex:error-fatal-message
    (codex:map-rollout-io-error
      (codex:io-error
        (codex:io-error-kind-permission-denied)
        "permission denied")
      "/tmp/codex-home"))
  ("Codex cannot access session files at /tmp/codex-home/sessions (permission denied). If sessions were created using sudo, fix ownership: sudo chown -R $(whoami) /tmp/codex-home (underlying error: permission denied)"))

!(assertEqualToResult
  (codex:error-fatal-message
    (codex:map-rollout-io-error
      (codex:io-error
        (codex:io-error-kind-not-found)
        "entity not found")
      "/tmp/codex-home"))
  ("Session storage missing at /tmp/codex-home/sessions. Create the directory or choose a different Codex home. (underlying error: entity not found)"))

!(assertEqualToResult
  (codex:error-fatal-message
    (codex:map-rollout-io-error
      (codex:io-error
        (codex:io-error-kind-already-exists)
        "file exists")
      "/tmp/codex-home"))
  ("Session storage path /tmp/codex-home/sessions is blocked by an existing file. Remove or rename it so Codex can create sessions. (underlying error: file exists)"))

!(assertEqualToResult
  (codex:error-fatal-message
    (codex:map-rollout-io-error
      (codex:io-error
        (codex:io-error-kind-invalid-data)
        "bad data")
      "/tmp/codex-home"))
  ("Session data under /tmp/codex-home/sessions looks corrupt or unreadable. Clearing the sessions directory may help (this will remove saved threads). (underlying error: bad data)"))

!(assertEqualToResult
  (codex:error-fatal-message
    (codex:map-rollout-io-error
      (codex:io-error
        (codex:io-error-kind-not-a-directory)
        "not a directory")
      "/tmp/codex-home"))
  ("Session storage path /tmp/codex-home/sessions has an unexpected type. Ensure it is a directory Codex can use for session files. (underlying error: not a directory)"))

!(assertEqualToResult
  (codex:map-rollout-io-error
    (codex:io-error
      (codex:io-error-kind-other)
      "some other io error")
    "/tmp/codex-home")
  (CodexAbsent))

!(assertEqualToResult
  (codex:error-fatal-message
    (codex:map-session-init-error
      "top failure"
      ((codex:session-init-cause-other "wrapper")
       (codex:session-init-cause-io
         (codex:io-error
           (codex:io-error-kind-other)
           "ignored"))
       (codex:session-init-cause-io
         (codex:io-error
           (codex:io-error-kind-invalid-input)
           "bad input")))
      "/tmp/codex-home"))
  ("Session data under /tmp/codex-home/sessions looks corrupt or unreadable. Clearing the sessions directory may help (this will remove saved threads). (underlying error: bad input)"))

!(assertEqualToResult
  (codex:error-fatal-message
    (codex:map-session-init-error
      "top failure"
      ((codex:session-init-cause-other "wrapper")
       (codex:session-init-cause-io
         (codex:io-error
           (codex:io-error-kind-other)
           "ignored")))
      "/tmp/codex-home"))
  ("Failed to initialize session: top failure"))
