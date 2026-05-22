!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:protocol)
!(import! &self codex:tool_registry_builder_plan)
!(import! &self codex:tool_registry_diff_consumer_plan)

(= (test:tool-registry-diff-consumer-registry)
   (codex:tool-registry
     ((codex:tool-registry-handler-binding
        "exec_command"
        (codex:tool-handler-kind-unified-exec))
      (codex:tool-registry-handler-binding
        "apply_patch"
        (codex:tool-handler-kind-apply-patch)))))

(= (test:tool-registry-diff-consumer $name)
   (codex:tool-registry-create-diff-consumer
     (test:tool-registry-diff-consumer-registry)
     (codex:plain-tool-name $name)))

(= (test:tool-registry-diff-consumer-event-json $event)
   (json-stringify (codex:item-json $event)))

!(assertEqualToResult
  (test:tool-registry-diff-consumer "missing")
  (CodexAbsent))

!(assertEqualToResult
  (test:tool-registry-diff-consumer "exec_command")
  (CodexAbsent))

!(assertEqualToResult
  (codex:tool-argument-diff-consumer-kind
    (test:tool-registry-diff-consumer "apply_patch"))
  ("ApplyPatch"))

!(let $result
    (codex:tool-argument-diff-consumer-consume-diff-at
      False
      (test:tool-registry-diff-consumer "apply_patch")
      "call-disabled"
      "*** Begin Patch\n*** Add File: hello.txt\n+hello"
      0)
  (assertEqualToResult
    (codex:apply-patch-argument-diff-consumer-state-input
      (codex:tool-argument-diff-consumer-apply-patch-state
        (codex:tool-argument-diff-consumer-result-consumer $result)))
    ("")))

!(let $begin
    (codex:tool-argument-diff-consumer-consume-diff-at
      True
      (test:tool-registry-diff-consumer "apply_patch")
      "call-registry-diff"
      "*** Begin Patch\n"
      0)
  (let $progress
      (codex:tool-argument-diff-consumer-consume-diff-at
        True
        (codex:tool-argument-diff-consumer-result-consumer $begin)
        "call-registry-diff"
        "*** Add File: hello.txt\n+hello"
        0)
    (assertEqualToResult
      (test:tool-registry-diff-consumer-event-json
        (codex:tool-argument-diff-consumer-result-event $progress))
      ("{\"type\":\"patch_apply_updated\",\"call_id\":\"call-registry-diff\",\"changes\":{\"hello.txt\":{\"type\":\"add\",\"content\":\"hello\\n\"}}}"))))

!(let $begin
    (codex:tool-argument-diff-consumer-consume-diff-at
      True
      (test:tool-registry-diff-consumer "apply_patch")
      "call-registry-flush"
      "*** Begin Patch\n"
      0)
  (let $progress
      (codex:tool-argument-diff-consumer-consume-diff-at
        True
        (codex:tool-argument-diff-consumer-result-consumer $begin)
        "call-registry-flush"
        "*** Add File: hello.txt\n+hello"
        0)
    (let $buffered
        (codex:tool-argument-diff-consumer-consume-diff-at
          True
          (codex:tool-argument-diff-consumer-result-consumer $progress)
          "call-registry-flush"
          "\n+world"
          100)
      (let $flushed
          (codex:tool-argument-diff-consumer-flush-on-complete-at
            (codex:tool-argument-diff-consumer-result-consumer $buffered)
            100)
        (assertEqualToResult
          (test:tool-registry-diff-consumer-event-json
            (codex:tool-argument-diff-consumer-result-event $flushed))
          ("{\"type\":\"patch_apply_updated\",\"call_id\":\"call-registry-flush\",\"changes\":{\"hello.txt\":{\"type\":\"add\",\"content\":\"hello\\nworld\\n\"}}}"))))))
