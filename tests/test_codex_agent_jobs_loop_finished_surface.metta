!(register-module! ../codex)
!(import! &self codex:agent_jobs_loop)

!(assertEqualToResult
  (codex:agent-job-loop-finished-plan
    "job-1"
    ((CodexAgentJobFinishedThread "thread-a" "item-a")
     (CodexAgentJobFinishedThread "thread-b" "item-b")))
  ((CodexAgentJobLoopFinishedPlan
     ((CodexAgentJobLoopFinalizeFinishedItem
        "job-1"
        "item-a"
        "thread-a")
      (CodexAgentJobLoopRemoveActiveThread "thread-a")
      (CodexAgentJobLoopLoadProgress "job-1")
      (CodexAgentJobLoopEmitLoadedProgress "job-1" False)
      (CodexAgentJobLoopFinalizeFinishedItem
        "job-1"
        "item-b"
        "thread-b")
      (CodexAgentJobLoopRemoveActiveThread "thread-b")
      (CodexAgentJobLoopLoadProgress "job-1")
      (CodexAgentJobLoopEmitLoadedProgress "job-1" False)))))
