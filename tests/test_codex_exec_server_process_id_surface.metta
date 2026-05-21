!(register-module! ../codex)
!(import! &self codex:exec_server_process_id)

!(assertEqual
  (codex:exec-server-process-id-new "proc-1")
  (CodexExecServerProcessId "proc-1"))

!(assertEqual
  (codex:exec-server-process-id-as-str
    (codex:exec-server-process-id-new "proc-1"))
  "proc-1")

!(assertEqual
  (codex:exec-server-process-id-into-inner
    (codex:exec-server-process-id-new "proc-2"))
  "proc-2")

!(assertEqual
  (codex:exec-server-process-id-display
    (codex:exec-server-process-id-from-string "proc-3"))
  "proc-3")

!(assertEqual
  (codex:exec-server-process-id-from-string "proc-4")
  (CodexExecServerProcessId "proc-4"))
