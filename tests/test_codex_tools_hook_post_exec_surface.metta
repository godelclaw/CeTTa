!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:tools)

!(assertEqualToResult
  (json-stringify
    (codex:post-tool-use-payload-json
      (codex:exec-command-post-tool-use-payload
        "call-43"
        "{\"cmd\":\"echo three\",\"tty\":false}"
        (CodexExecCommandRun
          "call-43"
          "chunk-1"
          "echo three"
          10000
          False
          0
          True
          0
          "three"
          ""
          "three"
          498
          1
          "Chunk ID: chunk-1\nWall time: 0.4980 seconds\nProcess exited with code 0\nOriginal token count: 1\nOutput:\nthree"))))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_use_id\":\"call-43\",\"tool_input\":{\"command\":\"echo three\"},\"tool_response\":\"three\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:post-tool-use-payload-json
      (codex:exec-command-post-tool-use-payload
        "call-44"
        "{\"cmd\":\"echo three\",\"tty\":true}"
        (CodexExecCommandRun
          "call-44"
          "chunk-1"
          "echo three"
          10000
          False
          0
          True
          0
          "three"
          ""
          "three"
          498
          1
          "Chunk ID: chunk-1\nWall time: 0.4980 seconds\nProcess exited with code 0\nOriginal token count: 1\nOutput:\nthree"))))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_use_id\":\"call-44\",\"tool_input\":{\"command\":\"echo three\"},\"tool_response\":\"three\"}"))

!(assertEqual
  (codex:exec-command-post-tool-use-payload
    "call-45"
    "{\"cmd\":\"echo three\",\"tty\":false}"
    (CodexExecCommandRun
      "event-45"
      "chunk-1"
      "echo three"
      10000
      True
      45
      False
      0
      "three"
      ""
      "three"
      498
      1
      "Chunk ID: chunk-1\nWall time: 0.4980 seconds\nProcess running with session ID 45\nOriginal token count: 1\nOutput:\nthree"))
  Empty)
