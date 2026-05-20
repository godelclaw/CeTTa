!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:apply_patch)
!(import! &self codex:protocol)

(= (codex-diff-consumer-event-json $event)
   (json-stringify (codex:item-json $event)))

(= (codex-diff-consumer-event $result)
   (codex:apply-patch-argument-diff-consumer-result-event $result))

(= (codex-diff-consumer-state $result)
   (codex:apply-patch-argument-diff-consumer-result-consumer $result))

!(let $result
    (codex:apply-patch-argument-diff-consumer-push-delta-at
      (codex:apply-patch-argument-diff-consumer-new)
      "call-1"
      "{\"input\":\"*** Begin Patch\\n"
      0)
  (assertEqual
    (codex-diff-consumer-event $result)
    CodexAbsent))

!(let $first
    (codex:apply-patch-argument-diff-consumer-push-delta-at
      (codex:apply-patch-argument-diff-consumer-new)
      "call-1"
      "{\"input\":\"*** Begin Patch\\n"
      0)
  (let $second
      (codex:apply-patch-argument-diff-consumer-push-delta-at
        (codex-diff-consumer-state $first)
        "call-1"
        "*** Add File: hello.txt\\n+hello\\n*** End Patch\\n\"}"
        1000)
    (assertEqual
      (codex-diff-consumer-event $second)
      CodexAbsent)))

!(let $begin
    (codex:apply-patch-argument-diff-consumer-push-delta-at
      (codex:apply-patch-argument-diff-consumer-new)
      "call-1"
      "*** Begin Patch\n"
      0)
  (assertEqual
    (codex-diff-consumer-event $begin)
    CodexAbsent))

!(let $flushed
    (codex:apply-patch-argument-diff-consumer-flush-on-complete-at
      (codex:apply-patch-argument-diff-consumer-new)
      0)
  (assertEqual
    (codex-diff-consumer-event $flushed)
    CodexAbsent))

!(let $begin
    (codex:apply-patch-argument-diff-consumer-push-delta-at
      (codex:apply-patch-argument-diff-consumer-new)
      "call-1"
      "*** Begin Patch\n"
      0)
  (let $progress
      (codex:apply-patch-argument-diff-consumer-push-delta-at
        (codex-diff-consumer-state $begin)
        "call-1"
        "*** Add File: hello.txt\n+hello"
        0)
    (assertEqualToResult
      (codex-diff-consumer-event-json
        (codex-diff-consumer-event $progress))
      ("{\"type\":\"patch_apply_updated\",\"call_id\":\"call-1\",\"changes\":{\"hello.txt\":{\"type\":\"add\",\"content\":\"hello\\n\"}}}"))))

!(let $begin
    (codex:apply-patch-argument-diff-consumer-push-delta-at
      (codex:apply-patch-argument-diff-consumer-new)
      "call-1"
      "*** Begin Patch\n"
      0)
  (let $progress
      (codex:apply-patch-argument-diff-consumer-push-delta-at
        (codex-diff-consumer-state $begin)
        "call-1"
        "*** Add File: hello.txt\n+hello"
        0)
    (let $buffered
        (codex:apply-patch-argument-diff-consumer-push-delta-at
          (codex-diff-consumer-state $progress)
          "call-1"
          "\n+world"
          100)
      (assertEqual
        (codex-diff-consumer-event $buffered)
        CodexAbsent))))

!(let $begin
    (codex:apply-patch-argument-diff-consumer-push-delta-at
      (codex:apply-patch-argument-diff-consumer-new)
      "call-1"
      "*** Begin Patch\n"
      0)
  (let $progress
      (codex:apply-patch-argument-diff-consumer-push-delta-at
        (codex-diff-consumer-state $begin)
        "call-1"
        "*** Add File: hello.txt\n+hello"
        0)
    (let $buffered
        (codex:apply-patch-argument-diff-consumer-push-delta-at
          (codex-diff-consumer-state $progress)
          "call-1"
          "\n+world"
          100)
      (let $flushed
          (codex:apply-patch-argument-diff-consumer-flush-on-complete-at
            (codex-diff-consumer-state $buffered)
            100)
        (assertEqualToResult
          (codex-diff-consumer-event-json
            (codex-diff-consumer-event $flushed))
          ("{\"type\":\"patch_apply_updated\",\"call_id\":\"call-1\",\"changes\":{\"hello.txt\":{\"type\":\"add\",\"content\":\"hello\\nworld\\n\"}}}"))))))

!(let $begin
    (codex:apply-patch-argument-diff-consumer-push-delta-at
      (codex:apply-patch-argument-diff-consumer-new)
      "call-1"
      "*** Begin Patch\n"
      0)
  (let $progress
      (codex:apply-patch-argument-diff-consumer-push-delta-at
        (codex-diff-consumer-state $begin)
        "call-1"
        "*** Add File: hello.txt\n+hello"
        0)
    (let $second
        (codex:apply-patch-argument-diff-consumer-push-delta-at
          (codex-diff-consumer-state $progress)
          "call-1"
          "\n+world"
          500)
      (assertEqualToResult
        (codex-diff-consumer-event-json
          (codex-diff-consumer-event $second))
        ("{\"type\":\"patch_apply_updated\",\"call_id\":\"call-1\",\"changes\":{\"hello.txt\":{\"type\":\"add\",\"content\":\"hello\\nworld\\n\"}}}")))))

!(let $result
    (codex:apply-patch-argument-diff-consumer-consume-diff-at
      False
      (codex:apply-patch-argument-diff-consumer-new)
      "call-disabled"
      "*** Begin Patch\n*** Add File: hello.txt\n+hello"
      0)
  (assertEqual
    (codex:apply-patch-argument-diff-consumer-state-input
      (codex-diff-consumer-state $result))
    ""))
