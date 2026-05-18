!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:account)
!(import! &self codex:protocol)

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:exec-command-output-delta-event
        "call21"
        "stdout"
        "hello")))
  ("{\"type\":\"exec_command_output_delta\",\"call_id\":\"call21\",\"stream\":\"stdout\",\"chunk\":\"aGVsbG8=\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:terminal-interaction-event
        "exec-call-45"
        "45"
        "exit\n")))
  ("{\"type\":\"terminal_interaction\",\"call_id\":\"exec-call-45\",\"process_id\":\"45\",\"stdin\":\"exit\\n\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:agent-message-event
      "Inspecting the workspace."
      CodexAbsent
      CodexAbsent))
  ("agent_message"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-message-event
        "Inspecting the workspace."
        (codex:message-phase-commentary)
        (codex:memory-citation
          ((codex:memory-citation-entry "MEMORY.md" 1 2 "summary"))
          ("rollout-1")))))
  ("{\"type\":\"agent_message\",\"message\":\"Inspecting the workspace.\",\"phase\":\"commentary\",\"memory_citation\":{\"entries\":[{\"path\":\"MEMORY.md\",\"lineStart\":1,\"lineEnd\":2,\"note\":\"summary\"}],\"rolloutIds\":[\"rollout-1\"]}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-message-event
        "Done."
        CodexAbsent
        CodexAbsent)))
  ("{\"type\":\"agent_message\",\"message\":\"Done.\",\"phase\":null,\"memory_citation\":null}"))

!(assertEqualToResult
  (codex:item-type
    (codex:user-message-event
      "hello"
      CodexAbsent
      ()
      ()))
  ("user_message"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:user-message-event
        "hello"
        CodexAbsent
        ()
        ())))
  ("{\"type\":\"user_message\",\"message\":\"hello\",\"local_images\":[],\"text_elements\":[]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:user-message-event
        "look here [Image #1]"
        ("data:image/png;base64,AAA")
        ("/tmp/local.png")
        ((codex:text-element
           (codex:byte-range 10 19)
           CodexAbsent)))))
  ("{\"type\":\"user_message\",\"message\":\"look here [Image #1]\",\"images\":[\"data:image/png;base64,AAA\"],\"local_images\":[\"/tmp/local.png\"],\"text_elements\":[{\"byte_range\":{\"start\":10,\"end\":19},\"placeholder\":null}]}"))

!(assertEqualToResult
  (codex:item-type
    (codex:terminal-interaction-event "exec-call-45" "45" "exit\n"))
  ("terminal_interaction"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-message-delta-event "delta text")))
  ("{\"type\":\"agent_message_delta\",\"delta\":\"delta text\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-reasoning-event "reasoning text")))
  ("{\"type\":\"agent_reasoning\",\"text\":\"reasoning text\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-reasoning-raw-content-event "raw text")))
  ("{\"type\":\"agent_reasoning_raw_content\",\"text\":\"raw text\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-reasoning-raw-content-delta-event "raw delta")))
  ("{\"type\":\"agent_reasoning_raw_content_delta\",\"delta\":\"raw delta\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-reasoning-section-break-event "item-7" 2)))
  ("{\"type\":\"agent_reasoning_section_break\",\"item_id\":\"item-7\",\"summary_index\":2}"))

!(assertEqualToResult
  (codex:item-type
    (codex:agent-reasoning-delta-event "step"))
  ("agent_reasoning_delta"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:mcp-tool-call-begin-event
        "mcp-call-1"
        (codex:mcp-invocation
          "memory"
          "create_entities"
          (JsonObject
            ((JsonPair "id" (JsonNumber 1)))))
        "app://memory")))
  ("{\"type\":\"mcp_tool_call_begin\",\"call_id\":\"mcp-call-1\",\"invocation\":{\"server\":\"memory\",\"tool\":\"create_entities\",\"arguments\":{\"id\":1}},\"mcp_app_resource_uri\":\"app://memory\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:mcp-tool-call-begin-event
      "mcp-call-2"
      (codex:mcp-invocation "images" "image" (JsonObject ()))
      CodexAbsent))
  ("mcp_tool_call_begin"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:mcp-startup-update-event
        "memory"
        (codex:mcp-startup-status-failed "oauth expired"))))
  ("{\"type\":\"mcp_startup_update\",\"server\":\"memory\",\"status\":{\"state\":\"failed\",\"error\":\"oauth expired\"}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:mcp-startup-complete-event
      ("memory" "images")
      ((codex:mcp-startup-failure "docs" "not logged in"))
      ("calendar")))
  ("mcp_startup_complete"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:mcp-startup-complete-event
        ("memory" "images")
        ((codex:mcp-startup-failure "docs" "not logged in"))
        ("calendar"))))
  ("{\"type\":\"mcp_startup_complete\",\"ready\":[\"memory\",\"images\"],\"failed\":[{\"server\":\"docs\",\"error\":\"not logged in\"}],\"cancelled\":[\"calendar\"]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:thread-name-updated-event
        "thread-123"
        "Buckminster notes")))
  ("{\"type\":\"thread_name_updated\",\"thread_id\":\"thread-123\",\"thread_name\":\"Buckminster notes\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:thread-name-updated-event
      "thread-456"
      CodexAbsent))
  ("thread_name_updated"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:thread-rolled-back-event 3)))
  ("{\"type\":\"thread_rolled_back\",\"num_turns\":3}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:warning-event "network unstable")))
  ("{\"type\":\"warning\",\"message\":\"network unstable\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:guardian-warning-event "approval reviewer timeout")))
  ("{\"type\":\"guardian_warning\",\"message\":\"approval reviewer timeout\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:model-reroute-event
      "gpt-5"
      "gpt-5-safe"
      (codex:model-reroute-reason-high-risk-cyber-activity)))
  ("model_reroute"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:model-reroute-event
        "gpt-5"
        "gpt-5-safe"
        (codex:model-reroute-reason-high-risk-cyber-activity))))
  ("{\"type\":\"model_reroute\",\"from_model\":\"gpt-5\",\"to_model\":\"gpt-5-safe\",\"reason\":\"high_risk_cyber_activity\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:context-compacted-event)))
  ("{\"type\":\"context_compacted\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:model-verification-event
      ((codex:model-verification-trusted-access-for-cyber))))
  ("model_verification"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:model-verification-event
        ((codex:model-verification-trusted-access-for-cyber)))))
  ("{\"type\":\"model_verification\",\"verifications\":[\"trusted_access_for_cyber\"]}"))

!(assertEqualToResult
  (codex:item-type
    (codex:turn-started-event
      "turn-8"
      1712345600
      400000
      (codex:mode-kind-default)))
  ("task_started"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:turn-started-event
        "turn-8"
        1712345600
        400000
        (codex:mode-kind-default))))
  ("{\"type\":\"task_started\",\"turn_id\":\"turn-8\",\"started_at\":1712345600,\"model_context_window\":400000,\"collaboration_mode_kind\":\"default\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:turn-started-event
        "turn-11"
        CodexAbsent
        CodexAbsent
        (codex:mode-kind-plan))))
  ("{\"type\":\"task_started\",\"turn_id\":\"turn-11\",\"model_context_window\":null,\"collaboration_mode_kind\":\"plan\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:turn-complete-event
      "turn-9"
      "final answer"
      1712345678
      240
      80))
  ("task_complete"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:turn-complete-event
        "turn-9"
        "final answer"
        1712345678
        240
        80)))
  ("{\"type\":\"task_complete\",\"turn_id\":\"turn-9\",\"last_agent_message\":\"final answer\",\"completed_at\":1712345678,\"duration_ms\":240,\"time_to_first_token_ms\":80}"))

!(assertEqualToResult
  (codex:item-type
    (codex:token-count-event
      CodexAbsent
      CodexAbsent))
  ("token_count"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:token-count-event
        (codex:token-usage-info
          (codex:token-usage 100 20 30 4 130)
          (codex:token-usage 10 2 3 1 13)
          32000)
        (codex:rate-limit-snapshot
          "limit-1"
          "gpt-5"
          (codex:rate-limit-window 50.0 60 1712349999)
          CodexAbsent
          (codex:credits-snapshot True False "$12.34")
          (codex:plan-type-plus)
          (codex:rate-limit-reached-type-rate-limit-reached)))))
  ("{\"type\":\"token_count\",\"info\":{\"total_token_usage\":{\"input_tokens\":100,\"cached_input_tokens\":20,\"output_tokens\":30,\"reasoning_output_tokens\":4,\"total_tokens\":130},\"last_token_usage\":{\"input_tokens\":10,\"cached_input_tokens\":2,\"output_tokens\":3,\"reasoning_output_tokens\":1,\"total_tokens\":13},\"model_context_window\":32000},\"rate_limits\":{\"limit_id\":\"limit-1\",\"limit_name\":\"gpt-5\",\"primary\":{\"used_percent\":50,\"window_minutes\":60,\"resets_at\":1712349999},\"secondary\":null,\"credits\":{\"has_credits\":true,\"unlimited\":false,\"balance\":\"$12.34\"},\"plan_type\":\"plus\",\"rate_limit_reached_type\":\"rate_limit_reached\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:token-count-event
        CodexAbsent
        CodexAbsent)))
  ("{\"type\":\"token_count\",\"info\":null,\"rate_limits\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:stream-info-event "retrying model stream")))
  ("{\"type\":\"stream_info\",\"message\":\"retrying model stream\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:undo-started-event CodexAbsent))
  ("undo_started"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:undo-started-event "rolling back last turn")))
  ("{\"type\":\"undo_started\",\"message\":\"rolling back last turn\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:undo-completed-event True "rollback applied")))
  ("{\"type\":\"undo_completed\",\"success\":true,\"message\":\"rollback applied\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:web-search-begin-event "search-17")))
  ("{\"type\":\"web_search_begin\",\"call_id\":\"search-17\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:web-search-end-event
        "search-17"
        "buckminster fuller"
        (codex:web-search-action-find-in-page
          "https://example.com"
          "geodesic"))))
  ("{\"type\":\"web_search_end\",\"call_id\":\"search-17\",\"query\":\"buckminster fuller\",\"action\":{\"type\":\"find_in_page\",\"url\":\"https://example.com\",\"pattern\":\"geodesic\"}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:image-generation-begin-event "img-22"))
  ("image_generation_begin"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:image-generation-end-event
        "img-22"
        "completed"
        "blueprint night skyline"
        "ok"
        "/tmp/out.png")))
  ("{\"type\":\"image_generation_end\",\"call_id\":\"img-22\",\"status\":\"completed\",\"revised_prompt\":\"blueprint night skyline\",\"result\":\"ok\",\"saved_path\":\"/tmp/out.png\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:view-image-tool-call-event
      "view-17"
      "/tmp/picture.png"))
  ("view_image_tool_call"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:view-image-tool-call-event
        "view-17"
        "/tmp/picture.png")))
  ("{\"type\":\"view_image_tool_call\",\"call_id\":\"view-17\",\"path\":\"/tmp/picture.png\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:background-event-event
        "waiting on remote worker")))
  ("{\"type\":\"background_event\",\"message\":\"waiting on remote worker\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:deprecation-notice-event
      "legacy profile support"
      CodexAbsent))
  ("deprecation_notice"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:deprecation-notice-event
        "legacy profile support"
        "use he_extended instead")))
  ("{\"type\":\"deprecation_notice\",\"summary\":\"legacy profile support\",\"details\":\"use he_extended instead\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:skills-update-available-event))
  ("skills_update_available"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:skills-update-available-event)))
  ("{\"type\":\"skills_update_available\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:shutdown-complete-event))
  ("shutdown_complete"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:shutdown-complete-event)))
  ("{\"type\":\"shutdown_complete\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:plan-update-event
      "Tool harness check"
      ((CodexUpdatePlanStep
         "Inspect workspace"
         (CodexUpdatePlanStepStatusInProgress))
       (CodexUpdatePlanStep
         "Report results"
         (CodexUpdatePlanStepStatusPending)))))
  ("plan_update"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:plan-update-event
        "Tool harness check"
        ((CodexUpdatePlanStep
           "Inspect workspace"
           (CodexUpdatePlanStepStatusInProgress))
         (CodexUpdatePlanStep
           "Report results"
           (CodexUpdatePlanStepStatusPending))))))
  ("{\"type\":\"plan_update\",\"explanation\":\"Tool harness check\",\"plan\":[{\"step\":\"Inspect workspace\",\"status\":\"in_progress\"},{\"step\":\"Report results\",\"status\":\"pending\"}]}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:plan-update-event
        CodexAbsent
        ())))
  ("{\"type\":\"plan_update\",\"explanation\":null,\"plan\":[]}"))

!(assertEqualToResult
  (codex:item-type
    (codex:turn-aborted-event
      CodexAbsent
      (codex:turn-abort-reason-interrupted)
      CodexAbsent
      CodexAbsent))
  ("turn_aborted"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:turn-aborted-event
        CodexAbsent
        (codex:turn-abort-reason-interrupted)
        CodexAbsent
        CodexAbsent)))
  ("{\"type\":\"turn_aborted\",\"reason\":\"interrupted\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:turn-aborted-event
        "turn-42"
        (codex:turn-abort-reason-review-ended)
        1712346000
        250)))
  ("{\"type\":\"turn_aborted\",\"turn_id\":\"turn-42\",\"reason\":\"review_ended\",\"completed_at\":1712346000,\"duration_ms\":250}"))

!(assertEqualToResult
  (codex:item-type
    (codex:stream-error-event
      "retrying model stream"
      CodexAbsent
      CodexAbsent))
  ("stream_error"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:stream-error-event
        "retrying model stream"
        CodexAbsent
        CodexAbsent)))
  ("{\"type\":\"stream_error\",\"message\":\"retrying model stream\",\"codex_error_info\":null,\"additional_details\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:stream-error-event
        "cannot steer this turn"
        (codex:codex-error-info-active-turn-not-steerable
          (codex:non-steerable-turn-kind-review))
        "wait for the review turn to finish")))
  ("{\"type\":\"stream_error\",\"message\":\"cannot steer this turn\",\"codex_error_info\":{\"active_turn_not_steerable\":{\"turn_kind\":\"review\"}},\"additional_details\":\"wait for the review turn to finish\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:stream-error-event
        "connection dropped"
        (codex:codex-error-info-response-stream-disconnected CodexAbsent)
        CodexAbsent)))
  ("{\"type\":\"stream_error\",\"message\":\"connection dropped\",\"codex_error_info\":{\"response_stream_disconnected\":{\"http_status_code\":null}},\"additional_details\":null}"))

!(assertEqualToResult
  (codex:item-type
    (codex:error-event
      "workspace rollback failed"
      (codex:codex-error-info-thread-rollback-failed)))
  ("error"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:error-event
        "workspace rollback failed"
        (codex:codex-error-info-thread-rollback-failed))))
  ("{\"type\":\"error\",\"message\":\"workspace rollback failed\",\"codex_error_info\":\"thread_rollback_failed\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:error-event
        "generic error"
        CodexAbsent)))
  ("{\"type\":\"error\",\"message\":\"generic error\",\"codex_error_info\":null}"))

!(assertEqualToResult
  (codex:item-type
    (codex:raw-response-item-event
      (codex:commentary-message "Inspecting response items.")))
  ("raw_response_item"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:raw-response-item-event
        (codex:commentary-message "Inspecting response items."))))
  ("{\"type\":\"raw_response_item\",\"item\":{\"type\":\"message\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"Inspecting response items.\"}],\"phase\":\"commentary\"}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:agent-message-content-delta-event
      "thread-1"
      "turn-1"
      "item-1"
      "delta block"))
  ("agent_message_content_delta"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:agent-message-content-delta-event
        "thread-1"
        "turn-1"
        "item-1"
        "delta block")))
  ("{\"type\":\"agent_message_content_delta\",\"thread_id\":\"thread-1\",\"turn_id\":\"turn-1\",\"item_id\":\"item-1\",\"delta\":\"delta block\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:plan-delta-event
        "thread-2"
        "turn-2"
        "item-2"
        "plan delta")))
  ("{\"type\":\"plan_delta\",\"thread_id\":\"thread-2\",\"turn_id\":\"turn-2\",\"item_id\":\"item-2\",\"delta\":\"plan delta\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:reasoning-content-delta-event
        "thread-3"
        "turn-3"
        "item-3"
        "reasoning delta"
        2)))
  ("{\"type\":\"reasoning_content_delta\",\"thread_id\":\"thread-3\",\"turn_id\":\"turn-3\",\"item_id\":\"item-3\",\"delta\":\"reasoning delta\",\"summary_index\":2}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:reasoning-raw-content-delta-event
        "thread-4"
        "turn-4"
        "item-4"
        "raw reasoning delta"
        0)))
  ("{\"type\":\"reasoning_raw_content_delta\",\"thread_id\":\"thread-4\",\"turn_id\":\"turn-4\",\"item_id\":\"item-4\",\"delta\":\"raw reasoning delta\",\"content_index\":0}"))

!(assertEqualToResult
  (codex:item-type
    (codex:exited-review-mode-event CodexAbsent))
  ("exited_review_mode"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:exited-review-mode-event CodexAbsent)))
  ("{\"type\":\"exited_review_mode\",\"review_output\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:exited-review-mode-event
        (codex:review-output-event
          ((codex:review-finding
             "Missing guard"
             "The code path does not check the returned permission."
             0.75
             1
             (codex:review-code-location
               "/tmp/example.rs"
               (codex:review-line-range 20 24))))
          "patch is not correct"
          "One high-confidence issue remains."
          0.75))))
  ("{\"type\":\"exited_review_mode\",\"review_output\":{\"findings\":[{\"title\":\"Missing guard\",\"body\":\"The code path does not check the returned permission.\",\"confidence_score\":0.75,\"priority\":1,\"code_location\":{\"absolute_file_path\":\"/tmp/example.rs\",\"line_range\":{\"start\":20,\"end\":24}}}],\"overall_correctness\":\"patch is not correct\",\"overall_explanation\":\"One high-confidence issue remains.\",\"overall_confidence_score\":0.75}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:entered-review-mode-event
      (codex:review-request
        (codex:review-target-uncommitted-changes)
        CodexAbsent)))
  ("entered_review_mode"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:entered-review-mode-event
        (codex:review-request
          (codex:review-target-uncommitted-changes)
          CodexAbsent))))
  ("{\"type\":\"entered_review_mode\",\"target\":{\"type\":\"uncommittedChanges\"}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:entered-review-mode-event
        (codex:review-request
          (codex:review-target-base-branch "main")
          "changes against main"))))
  ("{\"type\":\"entered_review_mode\",\"target\":{\"type\":\"baseBranch\",\"branch\":\"main\"},\"user_facing_hint\":\"changes against main\"}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:entered-review-mode-event
        (codex:review-request
          (codex:review-target-commit
            "abc123"
            CodexAbsent)
          CodexAbsent))))
  ("{\"type\":\"entered_review_mode\",\"target\":{\"type\":\"commit\",\"sha\":\"abc123\",\"title\":null}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:entered-review-mode-event
        (codex:review-request
          (codex:review-target-custom "check only auth flows")
          "focused pass"))))
  ("{\"type\":\"entered_review_mode\",\"target\":{\"type\":\"custom\",\"instructions\":\"check only auth flows\"},\"user_facing_hint\":\"focused pass\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:turn-diff-event "--- a/file\n+++ b/file\n@@ -1 +1 @@\n-old\n+new"))
  ("turn_diff"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:turn-diff-event "--- a/file\n+++ b/file\n@@ -1 +1 @@\n-old\n+new")))
  ("{\"type\":\"turn_diff\",\"unified_diff\":\"--- a/file\\n+++ b/file\\n@@ -1 +1 @@\\n-old\\n+new\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:get-history-entry-response-event 7 42 CodexAbsent))
  ("get_history_entry_response"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:get-history-entry-response-event
        7
        42
        CodexAbsent)))
  ("{\"type\":\"get_history_entry_response\",\"offset\":7,\"log_id\":42}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:get-history-entry-response-event
        8
        42
        (codex:history-entry
          "thread-123"
          1712345678
          "assistant: done"))))
  ("{\"type\":\"get_history_entry_response\",\"offset\":8,\"log_id\":42,\"entry\":{\"conversation_id\":\"thread-123\",\"ts\":1712345678,\"text\":\"assistant: done\"}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:list-skills-response-event ()))
  ("list_skills_response"))

!(assertEqualToResult
  (codex:item-type
    (codex:realtime-conversation-list-voices-response-event
      (codex:realtime-voices-list-builtin)))
  ("realtime_conversation_list_voices_response"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:realtime-conversation-list-voices-response-event
        (codex:realtime-voices-list-builtin))))
  ("{\"type\":\"realtime_conversation_list_voices_response\",\"voices\":{\"v1\":[\"juniper\",\"maple\",\"spruce\",\"ember\",\"vale\",\"breeze\",\"arbor\",\"sol\",\"cove\"],\"v2\":[\"alloy\",\"ash\",\"ballad\",\"coral\",\"echo\",\"sage\",\"shimmer\",\"verse\",\"marin\",\"cedar\"],\"defaultV1\":\"cove\",\"defaultV2\":\"marin\"}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:patch-apply-begin-event
      "patch-1"
      "turn-1"
      True
      ((codex:patch-apply-file-change-add
         "/tmp/a.txt"
         "hello\n"))))
  ("patch_apply_begin"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:patch-apply-begin-event
        "patch-1"
        "turn-1"
        True
        ((codex:patch-apply-file-change-add
           "/tmp/a.txt"
           "hello\n")
         (codex:patch-apply-file-change-update
           "/tmp/b.txt"
           "@@ -1 +1 @@\n-old\n+new\n"
           CodexAbsent)))))
  ("{\"type\":\"patch_apply_begin\",\"call_id\":\"patch-1\",\"turn_id\":\"turn-1\",\"auto_approved\":true,\"changes\":{\"/tmp/a.txt\":{\"type\":\"add\",\"content\":\"hello\\n\"},\"/tmp/b.txt\":{\"type\":\"update\",\"unified_diff\":\"@@ -1 +1 @@\\n-old\\n+new\\n\",\"move_path\":null}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:patch-apply-updated-event
        "patch-1"
        ((codex:patch-apply-file-change-delete
           "/tmp/a.txt"
           "bye\n")))))
  ("{\"type\":\"patch_apply_updated\",\"call_id\":\"patch-1\",\"changes\":{\"/tmp/a.txt\":{\"type\":\"delete\",\"content\":\"bye\\n\"}}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:patch-apply-end-event
        "patch-1"
        "turn-1"
        "Applied patch."
        ""
        True
        ((codex:patch-apply-file-change-update
           "/tmp/c.txt"
           "@@ -1 +1 @@\n-a\n+b\n"
           "/tmp/d.txt"))
        (codex:patch-apply-status-completed))))
  ("{\"type\":\"patch_apply_end\",\"call_id\":\"patch-1\",\"turn_id\":\"turn-1\",\"stdout\":\"Applied patch.\",\"stderr\":\"\",\"success\":true,\"changes\":{\"/tmp/c.txt\":{\"type\":\"update\",\"unified_diff\":\"@@ -1 +1 @@\\n-a\\n+b\\n\",\"move_path\":\"/tmp/d.txt\"}},\"status\":\"completed\"}"))

!(assertEqualToResult
  (codex:item-type
    (codex:hook-started-event
      CodexAbsent
      (codex:hook-run-summary
        "hook-run-1"
        (codex:hook-event-name-pre-tool-use)
        (codex:hook-handler-type-command)
        (codex:hook-execution-mode-sync)
        (codex:hook-scope-turn)
        "/tmp/hook.sh"
        (codex:hook-source-project)
        1
        (codex:hook-run-status-running)
        CodexAbsent
        1712345600
        CodexAbsent
        CodexAbsent
        ())
      ))
  ("hook_started"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:hook-started-event
        CodexAbsent
        (codex:hook-run-summary
          "hook-run-1"
          (codex:hook-event-name-pre-tool-use)
          (codex:hook-handler-type-command)
          (codex:hook-execution-mode-sync)
          (codex:hook-scope-turn)
          "/tmp/hook.sh"
          (codex:hook-source-project)
          1
          (codex:hook-run-status-running)
          CodexAbsent
          1712345600
          CodexAbsent
          CodexAbsent
          ()))))
  ("{\"type\":\"hook_started\",\"turn_id\":null,\"run\":{\"id\":\"hook-run-1\",\"event_name\":\"pre_tool_use\",\"handler_type\":\"command\",\"execution_mode\":\"sync\",\"scope\":\"turn\",\"source_path\":\"/tmp/hook.sh\",\"source\":\"project\",\"display_order\":1,\"status\":\"running\",\"status_message\":null,\"started_at\":1712345600,\"completed_at\":null,\"duration_ms\":null,\"entries\":[]}}"))

!(assertEqualToResult
  (json-stringify
    (codex:item-json
      (codex:hook-completed-event
        "turn-9"
        (codex:hook-run-summary
          "hook-run-2"
          (codex:hook-event-name-post-tool-use)
          (codex:hook-handler-type-agent)
          (codex:hook-execution-mode-async)
          (codex:hook-scope-thread)
          "/tmp/post-hook.py"
          (codex:hook-source-system)
          2
          (codex:hook-run-status-completed)
          "ok"
          1712345601
          1712345604
          3000
          ((codex:hook-output-entry
             (codex:hook-output-entry-kind-feedback)
             "All good."))))))
  ("{\"type\":\"hook_completed\",\"turn_id\":\"turn-9\",\"run\":{\"id\":\"hook-run-2\",\"event_name\":\"post_tool_use\",\"handler_type\":\"agent\",\"execution_mode\":\"async\",\"scope\":\"thread\",\"source_path\":\"/tmp/post-hook.py\",\"source\":\"system\",\"display_order\":2,\"status\":\"completed\",\"status_message\":\"ok\",\"started_at\":1712345601,\"completed_at\":1712345604,\"duration_ms\":3000,\"entries\":[{\"kind\":\"feedback\",\"text\":\"All good.\"}]}}"))

!(assertEqualToResult
  (codex:item-type
    (codex:session-configured-event
      "67e55044-10b1-426f-9247-bb680e5fe0c8"
      CodexAbsent
      CodexAbsent
      "codex-mini-latest"
      "openai"
      CodexAbsent
      (codex:session-approval-policy-never)
      (codex:session-approvals-reviewer-user)
      (codex:session-sandbox-policy-read-only
        (codex:session-read-only-access-full)
        False)
      CodexAbsent
      "/home/user/project"
      (codex:session-reasoning-effort-medium)
      0
      0
      CodexAbsent
      CodexAbsent
      "/tmp/rollout.jsonl"))
  ("session_configured"))
