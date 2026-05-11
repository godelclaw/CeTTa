!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqual
  (codex:exec-command-run-output-items
    "call_live_events"
    (CodexExecCommandRun
      "call_live_events"
      "chunk-1"
      "printf hello"
      10000
      False
      0
      True
      0
      "hello"
      ""
      "hello"
      2
      2
      "Chunk ID: chunk-1\nWall time: 0.0020 seconds\nProcess exited with code 0\nOriginal token count: 2\nOutput:\nhello"))
  ((codex:exec-command-output-delta-event
      "call_live_events"
      "stdout"
      "hello")
   (codex:tool-result
      "call_live_events"
      "Chunk ID: chunk-1\nWall time: 0.0020 seconds\nProcess exited with code 0\nOriginal token count: 2\nOutput:\nhello")))
