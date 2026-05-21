!(register-module! ../codex)
!(import! &self codex:error)

!(assertEqual
  (codex:error-display
    (codex:error-thread-not-found
      "67e55044-10b1-426f-9247-bb680e5fe0c8"))
  "no thread with id: 67e55044-10b1-426f-9247-bb680e5fe0c8")

!(assertEqual
  (codex:error-display (codex:error-agent-limit-reached 3))
  "agent thread limit reached (max 3)")

!(assertEqual
  (codex:error-display (codex:error-internal-agent-died))
  "internal error; agent loop died unexpectedly")

!(assertEqual
  (codex:error-display
    (codex:error-unsupported-operation "no available agent nicknames"))
  "unsupported operation: no available agent nicknames")
