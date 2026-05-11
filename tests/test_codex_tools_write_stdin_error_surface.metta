!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:tools)

!(assertEqualToResult
  (codex:write-stdin-result-text
    (CodexWriteStdinResultError
      "write_stdin failed: Unknown process id 99999"))
  ("write_stdin failed: Unknown process id 99999"))

!(assertEqualToResult
  (codex:tool-result-output-text
    (codex:tool-result
      "call_write"
      "write_stdin failed: Unknown process id 99999"))
  ("write_stdin failed: Unknown process id 99999"))
