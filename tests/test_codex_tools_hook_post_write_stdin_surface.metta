!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:tools)

!(assertEqualToResult
  (json-stringify
    (codex:post-tool-use-payload-json
      (codex:write-stdin-post-tool-use-payload
        "write-stdin-call"
        "{\"session_id\":45,\"chars\":\"\"}"
        (CodexExecCommandRun
          "exec-call-45"
          "chunk-2"
          "sleep 1; echo finished"
          10000
          False
          0
          True
          0
          "finished\n"
          ""
          "finished\n"
          498
          3
          "Chunk ID: chunk-2\nWall time: 0.4980 seconds\nProcess exited with code 0\nOriginal token count: 3\nOutput:\nfinished\n"))))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_use_id\":\"exec-call-45\",\"tool_input\":{\"command\":\"sleep 1; echo finished\"},\"tool_response\":\"finished\\n\"}"))

!(assertEqualToResult
  (json-stringify
    (JsonArray
      ((codex:post-tool-use-payload-json
         (codex:write-stdin-post-tool-use-payload
           "write-call-b"
           "{\"session_id\":45,\"chars\":\"\"}"
           (CodexExecCommandRun
             "exec-call-b"
             "chunk-b"
             "sleep 1; echo beta"
             10000
             False
             0
             True
             0
             "beta\n"
             ""
             "beta\n"
             498
             2
             "Chunk ID: chunk-b\nWall time: 0.4980 seconds\nProcess exited with code 0\nOriginal token count: 2\nOutput:\nbeta\n")))
       (codex:post-tool-use-payload-json
         (codex:write-stdin-post-tool-use-payload
           "write-call-a"
           "{\"session_id\":45,\"chars\":\"\"}"
           (CodexExecCommandRun
             "exec-call-a"
             "chunk-a"
             "sleep 2; echo alpha"
             10000
             False
             0
             True
             0
             "alpha\n"
             ""
             "alpha\n"
             498
             2
             "Chunk ID: chunk-a\nWall time: 0.4980 seconds\nProcess exited with code 0\nOriginal token count: 2\nOutput:\nalpha\n"))))))
  ("[{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_use_id\":\"exec-call-b\",\"tool_input\":{\"command\":\"sleep 1; echo beta\"},\"tool_response\":\"beta\\n\"},{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_use_id\":\"exec-call-a\",\"tool_input\":{\"command\":\"sleep 2; echo alpha\"},\"tool_response\":\"alpha\\n\"}]"))
