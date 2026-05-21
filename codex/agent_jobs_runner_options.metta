; Rust-faithful pure agent job runner-options slice.
;
; This ports the deterministic control-flow boundary from:
; - openai-codex/codex-rs/core/src/tools/handlers/agent_jobs.rs
; - openai-codex/codex-rs/core/src/agent/registry.rs
;
; Covered in this increment:
; - required_state_db absent/present behavior
; - session_depth / next_thread_spawn_depth
; - exceeds_thread_spawn_depth_limit
; - build_runner_options depth gate, concurrency normalization, and
;   spawn-config result propagation
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust obtains `base_instructions` asynchronously and calls
;   `build_agent_spawn_config(&base_instructions, turn)`. This pure boundary
;   accepts that already-computed `CodexAgentJobOk` / `CodexAgentJobErr`
;   spawn-config result and preserves Rust's surrounding order: depth rejection
;   happens before the spawn-config result is observed, then the result is
;   propagated unchanged or wrapped into `JobRunnerOptions`.
; - Rust's `session_depth(...).saturating_add(1)` saturates at `i32::MAX`.
;   This helper names that bound explicitly and implements the same saturation.

!(import! &self agent_jobs)
!(import! &self function_tool)
!(import! &self protocol)

(= (codex:agent-job-runner-options $max-concurrency $spawn-config)
   (CodexAgentJobRunnerOptions $max-concurrency $spawn-config))

(= (codex:agent-job-runner-options-max-concurrency
      (CodexAgentJobRunnerOptions $max-concurrency $spawn-config))
   $max-concurrency)

(= (codex:agent-job-runner-options-spawn-config
      (CodexAgentJobRunnerOptions $max-concurrency $spawn-config))
   $spawn-config)

(= (codex:agent-job-required-state-db $state-db)
   (if (== $state-db CodexAbsent)
       (codex:agent-job-err
         (codex:function-call-error-fatal
           "sqlite state db is unavailable for this session"))
       (codex:agent-job-ok $state-db)))

(= (codex:agent-job-session-depth $session-source)
   (case $session-source
     (((CodexSessionSourceSubAgent
         (CodexSubAgentSourceThreadSpawn
           $parent-thread-id
           $depth
           $agent-path
           $agent-nickname
           $agent-role))
       $depth)
      ($other 0))))

(= (codex:agent-job-i32-max)
   2147483647)

(= (codex:agent-job-saturating-add-one-i32 $value)
   (if (>= $value (codex:agent-job-i32-max))
       (codex:agent-job-i32-max)
       (+ $value 1)))

(= (codex:agent-job-next-thread-spawn-depth $session-source)
   (codex:agent-job-saturating-add-one-i32
     (codex:agent-job-session-depth $session-source)))

(= (codex:agent-job-exceeds-thread-spawn-depth-limit $depth $max-depth)
   (> $depth $max-depth))

(= (codex:agent-job-depth-limit-error)
   (codex:function-call-error-respond-to-model
     "agent depth limit reached; this session cannot spawn more subagents"))

(= (codex:agent-job-build-runner-options
      $session-source
      $agent-max-depth
      $agent-max-threads
      $requested-concurrency
      $spawn-config-result)
   (let $child-depth
     (codex:agent-job-next-thread-spawn-depth $session-source)
     (if (codex:agent-job-exceeds-thread-spawn-depth-limit
           $child-depth
           $agent-max-depth)
         (codex:agent-job-err (codex:agent-job-depth-limit-error))
         (case $spawn-config-result
           (((CodexAgentJobErr $error)
             (codex:agent-job-err $error))
            ((CodexAgentJobOk $spawn-config)
             (codex:agent-job-ok
               (codex:agent-job-runner-options
                 (codex:agent-job-normalize-concurrency
                   $requested-concurrency
                   $agent-max-threads)
                 $spawn-config))))))))
