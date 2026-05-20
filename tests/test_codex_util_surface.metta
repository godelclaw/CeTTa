!(register-module! ../codex)
!(import! &self codex:util)

!(assertEqual
  (codex:normalize-thread-name "   ")
  CodexAbsent)

!(assertEqual
  (codex:normalize-thread-name "  my thread  ")
  "my thread")

!(assertEqual
  (codex:resume-command "my-thread" "123e4567-e89b-12d3-a456-426614174000")
  "codex resume my-thread")

!(assertEqual
  (codex:resume-command CodexAbsent "123e4567-e89b-12d3-a456-426614174000")
  "codex resume 123e4567-e89b-12d3-a456-426614174000")

!(assertEqual
  (codex:resume-command CodexAbsent CodexAbsent)
  CodexAbsent)

!(assertEqual
  (codex:resume-command "" "123e4567-e89b-12d3-a456-426614174000")
  "codex resume 123e4567-e89b-12d3-a456-426614174000")

!(assertEqual
  (codex:resume-command "-starts-with-dash" CodexAbsent)
  "codex resume -- -starts-with-dash")

!(assertEqual
  (codex:resume-command "two words" CodexAbsent)
  "codex resume 'two words'")

!(assertEqual
  (codex:resume-command "quote'case" CodexAbsent)
  "codex resume \"quote'case\"")

!(assertEqual
  (codex:resolve-path "/tmp/base" "/abs/file")
  "/abs/file")

!(assertEqual
  (codex:resolve-path "/tmp/base" "rel/file")
  "/tmp/base/rel/file")

!(assertEqual
  (codex:resolve-path "/tmp/base/" "rel/file")
  "/tmp/base/rel/file")

!(assertEqual
  (codex:resolve-path "/tmp/base" "../file")
  "/tmp/base/../file")
