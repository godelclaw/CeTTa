!(register-module! ../codex)
!(import! &self codex:memory_citation)
!(import! &self codex:protocol)
!(import! &self codex:stream_events_utils)

(= (stream-events-memory-citation-fixture)
   "hello<oai-mem-citation><citation_entries>\nMEMORY.md:1-2|note=[x]\n</citation_entries>\n<rollout_ids>\n019cc2ea-1dff-7902-8d40-c8f6e5d83cc4\n</rollout_ids></oai-mem-citation> world")

!(assertEqual
  (codex:image-generation-artifact-path
    "/tmp/codex"
    "session-1"
    "../ig/..")
  "/tmp/codex/generated_images/session-1/___ig___.png")

!(assertEqual
  (codex:image-generation-artifact-path "/tmp/codex" "" "")
  "/tmp/codex/generated_images/generated_image/generated_image.png")

!(assertEqual
  (codex:strip-hidden-assistant-markup
    "before<oai-mem-citation>doc1</oai-mem-citation>\n<proposed_plan>\n- x\n</proposed_plan>\nafter"
    True)
  "before\nafter")

!(assertEqual
  (codex:stream-events-hidden-markup-result-visible
    (codex:strip-hidden-assistant-markup-and-parse-memory-citation
      (stream-events-memory-citation-fixture)
      False))
  "hello world")

!(assertEqual
  (codex:thread-ids-from-memory-citation
    (codex:stream-events-hidden-markup-result-memory-citation
      (codex:strip-hidden-assistant-markup-and-parse-memory-citation
        (stream-events-memory-citation-fixture)
        False)))
  ("019cc2ea-1dff-7902-8d40-c8f6e5d83cc4"))

!(assertEqual
  (codex:raw-assistant-output-text-from-item
    (CodexResponseItemMessageWithId
      "msg-1"
      "assistant"
      ((CodexOutputText "a")
       (CodexInputText "ignored")
       (CodexOutputText "b"))
      CodexAbsent))
  "ab")

!(assertEqual
  (codex:raw-assistant-output-text-from-item
    (codex:user-message "plain user text"))
  CodexAbsent)

!(assertEqual
  (codex:last-assistant-message-from-item
    (codex:assistant-message
      "before<oai-mem-citation>doc1</oai-mem-citation>\n<proposed_plan>\n- x\n</proposed_plan>\nafter")
    True)
  "before\nafter")

!(assertEqual
  (codex:last-assistant-message-from-item
    (codex:assistant-message
      "<oai-mem-citation>doc1</oai-mem-citation>")
    False)
  CodexAbsent)

!(assertEqual
  (codex:last-assistant-message-from-item
    (codex:assistant-message "<proposed_plan>\n- x\n</proposed_plan>")
    True)
  CodexAbsent)

!(assertEqual
  (codex:completed-item-defers-mailbox-delivery-to-next-turn
    (codex:assistant-message "final answer")
    False)
  True)

!(assertEqual
  (codex:completed-item-defers-mailbox-delivery-to-next-turn
    (codex:commentary-message "still working")
    False)
  False)

!(assertEqual
  (codex:completed-item-defers-mailbox-delivery-to-next-turn
    (codex:image-generation-call-response-item
      "ig-1"
      "completed"
      CodexAbsent
      "Zm9v")
    False)
  True)

!(assertEqual
  (codex:response-item-may-include-external-context
    (codex:web-search-call-response-item
      CodexAbsent
      "completed"
      CodexAbsent))
  True)

!(assertEqual
  (codex:response-item-may-include-external-context
    (CodexResponseItemToolSearchCall
      CodexAbsent
      "search-1"
      CodexAbsent
      "client"
      "{\"query\":\"calendar\"}"))
  True)

!(assertEqual
  (codex:response-item-may-include-external-context
    (codex:tool-search-output "search-1" "completed" "client" ()))
  True)

!(assertEqual
  (codex:response-item-may-include-external-context
    (codex:function-call-response-item "shell" "{}" "call-1"))
  False)

!(assertEqual
  (codex:response-item-may-include-external-context
    (codex:tool-call "custom-1" "apply_patch" "*** Begin Patch\n*** End Patch\n"))
  False)
