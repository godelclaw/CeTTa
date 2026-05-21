!(register-module! ../codex)
!(import! &self codex:agent_jobs_active)
!(import! &self codex:protocol)

!(assertEqual
  (codex:agent-job-active-item-status
    (codex:agent-job-active-item
      "item-1"
      10
      (codex:agent-job-status-rx
        True
        (codex:protocol-agent-status-completed "done")))
    (codex:protocol-agent-status-running))
  (codex:protocol-agent-status-completed "done"))

!(assertEqual
  (codex:agent-job-active-item-status
    (codex:agent-job-active-item
      "item-1"
      10
      (codex:agent-job-status-rx
        False
        (codex:protocol-agent-status-completed "done")))
    (codex:protocol-agent-status-running))
  (codex:protocol-agent-status-running))

!(assertEqual
  (codex:agent-job-find-finished-threads
    ((codex:agent-job-active-observation
       "thread-a"
       (codex:agent-job-active-item
         "item-a"
         10
         (codex:agent-job-status-rx
           True
           (codex:protocol-agent-status-completed "done")))
       (codex:protocol-agent-status-running))
     (codex:agent-job-active-observation
       "thread-b"
       (codex:agent-job-active-item "item-b" 20 CodexAbsent)
       (codex:protocol-agent-status-running))
     (codex:agent-job-active-observation
       "thread-c"
       (codex:agent-job-active-item
         "item-c"
         30
         (codex:agent-job-status-rx
           False
           (codex:protocol-agent-status-running)))
       (codex:protocol-agent-status-errored "boom"))))
  ((codex:agent-job-finished-thread "thread-a" "item-a")
   (codex:agent-job-finished-thread "thread-c" "item-c")))

!(assertEqual
  (codex:agent-job-wait-for-status-change-plan
    ((codex:agent-job-active-item "item-a" 10 CodexAbsent)
     (codex:agent-job-active-item "item-b" 20 CodexAbsent)))
  (codex:agent-job-wait-for-status-change-sleep 250))

!(assertEqual
  (codex:agent-job-wait-for-status-change-plan
    ((codex:agent-job-active-item
       "item-a"
       10
       (codex:agent-job-status-rx
         True
         (codex:protocol-agent-status-running)))
     (codex:agent-job-active-item "item-b" 20 CodexAbsent)
     (codex:agent-job-active-item
       "item-c"
       30
       (codex:agent-job-status-rx
         False
         (codex:protocol-agent-status-running)))))
  (codex:agent-job-wait-for-status-change-watch 250 2))

!(assertEqual
  (codex:agent-job-active-item-stale 100 90 10)
  True)

!(assertEqual
  (codex:agent-job-active-item-stale 99 100 10)
  False)

!(assertEqual
  (codex:agent-job-reap-stale-active-items
    "job-1"
    ((codex:agent-job-active-observation
       "thread-old"
       (codex:agent-job-active-item "item-old" 10 CodexAbsent)
       (codex:protocol-agent-status-running))
     (codex:agent-job-active-observation
       "thread-fresh"
       (codex:agent-job-active-item "item-fresh" 95 CodexAbsent)
       (codex:protocol-agent-status-running)))
    100
    90)
  (codex:agent-job-reap-stale-active-result
    True
    ((codex:agent-job-reap-stale-active-action
       "job-1"
       "thread-old"
       "item-old"
       "worker exceeded max runtime of 90s"))))

!(assertEqual
  (codex:agent-job-reap-stale-active-items
    "job-1"
    ((codex:agent-job-active-observation
       "thread-fresh"
       (codex:agent-job-active-item "item-fresh" 95 CodexAbsent)
       (codex:protocol-agent-status-running)))
    100
    90)
  (codex:agent-job-reap-stale-active-result False ()))
