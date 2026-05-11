!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(println! "=== Codex tools hooks demo ===")
!(println!
  (json-stringify
    (codex:pre-tool-use-payload-json
      (codex:exec-command-pre-tool-use-payload
        (codex:tool-call
          "call-hook-demo"
          "exec_command"
          "{\"cmd\":\"printf hook demo\"}")))))
!(println!
  (json-stringify
    (codex:post-tool-use-payload-json
      (codex:exec-command-post-tool-use-payload
        "call-hook-demo"
        "{\"cmd\":\"printf hook demo\"}"
        (CodexExecCommandRun
          "call-hook-demo"
          "chunk-d"
          "printf hook demo"
          10000
          False
          0
          True
          0
          "hook demo"
          ""
          "hook demo"
          12
          2
          "Chunk ID: chunk-d\nWall time: 0.0120 seconds\nProcess exited with code 0\nOriginal token count: 2\nOutput:\nhook demo")))))
