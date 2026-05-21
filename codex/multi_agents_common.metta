; Rust-faithful pure multi-agent handler common helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/multi_agents_common.rs
; - openai-codex/codex-rs/core/src/tools/handlers/multi_agents.rs
;
; Covered in this increment:
; - wait timeout constants
; - wait timeout normalization
; - parse_agent_id_target / parse_agent_id_targets
; - function_arguments
; - build_wait_agent_statuses ordering
; - collab_spawn_error / collab_agent_error display mapping
; - thread_spawn_source
; - parse_collab_input
; - reject_full_fork_spawn_overrides
; - find_spawn_agent_model_name / validate_spawn_agent_reasoning_effort
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust receives `HashMap<ThreadId, AgentStatus>` for status lookup. This pure
;   CeTTa slice uses `CodexMultiAgentStatusEntry` lists with the same lookup
;   contract; duplicate keys are outside Rust `HashMap` semantics.
; - Rust receives full `CodexErr` and model preset structs. This slice exposes
;   the concrete error variants and model/reasoning strings needed by the
;   ported branch table, preserving the exact visible `FunctionCallError`
;   messages.
; - Rust mutates `Config` for runtime/model overrides. Those side-effecting
;   helpers remain with a later config/session port; this slice covers the
;   pure validation helpers those branches call.
; - CeTTa currently does not reliably reduce the separate `thread_id` helper
;   after the large protocol surface is imported into the same space. The
;   parse_agent_id_target helpers therefore repeat the same deterministic
;   ThreadId parser-form logic locally instead of delegating across modules.

!(import! &self agent_path)
!(import! &self context)
!(import! &self function_tool)
!(import! &self json)
!(import! &self list)
!(import! &self protocol)
!(import! &self str)

(= (codex:multi-agent-min-wait-timeout-ms)
   10000)

(= (codex:multi-agent-default-wait-timeout-ms)
   30000)

(= (codex:multi-agent-max-wait-timeout-ms)
   3600000)

(= (codex:multi-agent-normalize-wait-timeout-ms $timeout-ms)
   (case $timeout-ms
     ((CodexAbsent
       (codex:multi-agent-common-ok
         (codex:multi-agent-default-wait-timeout-ms)))
      ($ms
       (if (< $ms 1)
           (codex:multi-agent-common-err
             (codex:function-call-error-respond-to-model
               "timeout_ms must be greater than zero"))
           (if (< $ms (codex:multi-agent-min-wait-timeout-ms))
               (codex:multi-agent-common-ok
                 (codex:multi-agent-min-wait-timeout-ms))
               (if (> $ms (codex:multi-agent-max-wait-timeout-ms))
                   (codex:multi-agent-common-ok
                     (codex:multi-agent-max-wait-timeout-ms))
                   (codex:multi-agent-common-ok $ms))))))))

(= (codex:multi-agent-common-ok $value)
   (CodexMultiAgentCommonOk $value))

(= (codex:multi-agent-common-err $error)
   (CodexMultiAgentCommonErr $error))

(= (codex:multi-agent-thread-id-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:multi-agent-thread-id-is-ascii-hex-char $char)
   (let $found (str-find "0123456789abcdefABCDEF" $char)
     (if (== $found Empty) False True)))

(= (codex:multi-agent-thread-id-are-ascii-hex-chars $text)
   (if (== (str-length $text) 32)
       (codex:multi-agent-thread-id-are-hex4-groups-from $text 0)
       False))

(= (codex:multi-agent-thread-id-are-hex4-groups-from $text $start)
   (if (== $start 32)
       True
       (case (codex:multi-agent-thread-id-is-hex4-at $text $start)
         ((False False)
          (True
           (codex:multi-agent-thread-id-are-hex4-groups-from
             $text
             (+ $start 4)))))))

(= (codex:multi-agent-thread-id-is-hex4-at $text $start)
   (let $c0
     (codex:multi-agent-thread-id-is-ascii-hex-char
       (str-slice $text $start (+ $start 1)))
     (if $c0
         (let $c1
           (codex:multi-agent-thread-id-is-ascii-hex-char
             (str-slice $text (+ $start 1) (+ $start 2)))
           (if $c1
               (let $c2
                 (codex:multi-agent-thread-id-is-ascii-hex-char
                   (str-slice $text (+ $start 2) (+ $start 3)))
                 (if $c2
                     (codex:multi-agent-thread-id-is-ascii-hex-char
                       (str-slice $text (+ $start 3) (+ $start 4)))
                     False))
               False))
         False)))

(= (codex:multi-agent-thread-id-lower-char-at $text $index)
   (codex:multi-agent-thread-id-ascii-lower-char
     (str-slice $text $index (+ $index 1))))

(= (codex:multi-agent-thread-id-lower4-at $text $start)
   (let $c0 (codex:multi-agent-thread-id-lower-char-at $text $start)
     (let $c1
       (codex:multi-agent-thread-id-lower-char-at $text (+ $start 1))
       (let $c2
         (codex:multi-agent-thread-id-lower-char-at $text (+ $start 2))
         (let $c3
           (codex:multi-agent-thread-id-lower-char-at $text (+ $start 3))
           (str-concat
             $c0
             (str-concat $c1 (str-concat $c2 $c3))))))))

(= (codex:multi-agent-thread-id-lower8-at $text $start)
   (case (codex:multi-agent-thread-id-lower4-at $text $start)
     (($left
       (case (codex:multi-agent-thread-id-lower4-at $text (+ $start 4))
         (($right (str-concat $left $right))))))))

(= (codex:multi-agent-thread-id-simple-to-hyphenated $simple)
   (case (codex:multi-agent-thread-id-lower8-at $simple 0)
     (($g0
       (case (codex:multi-agent-thread-id-lower4-at $simple 8)
         (($g1
           (case (codex:multi-agent-thread-id-lower4-at $simple 12)
             (($g2
               (case (codex:multi-agent-thread-id-lower4-at $simple 16)
                 (($g3
                   (case (codex:multi-agent-thread-id-lower4-at $simple 20)
                     (($g4a
                       (case
                         (codex:multi-agent-thread-id-lower8-at $simple 24)
                         (($g4b
                           (format-args
                             "{}-{}-{}-{}-{}{}"
                             ($g0 $g1 $g2 $g3 $g4a $g4b)))))))))))))))))))))

(= (codex:multi-agent-thread-id-hyphenated-to-simple $text)
   (str-concat
     (str-slice $text 0 8)
     (str-concat
       (str-slice $text 9 13)
       (str-concat
         (str-slice $text 14 18)
         (str-concat
           (str-slice $text 19 23)
           (str-slice $text 24 36))))))

(= (codex:multi-agent-thread-id-is-hyphenated-shape $text)
   (if (== (str-length $text) 36)
       (and
         (== (str-slice $text 8 9) "-")
         (and
           (== (str-slice $text 13 14) "-")
           (and
             (== (str-slice $text 18 19) "-")
             (== (str-slice $text 23 24) "-"))))
       False))

(= (codex:multi-agent-thread-id-canonicalize-simple $text)
   (if (and
         (== (str-length $text) 32)
         (codex:multi-agent-thread-id-are-ascii-hex-chars $text))
       (codex:multi-agent-thread-id-simple-to-hyphenated
         $text)
       CodexAbsent))

(= (codex:multi-agent-thread-id-canonicalize-hyphenated $text)
   (if (codex:multi-agent-thread-id-is-hyphenated-shape $text)
       (codex:multi-agent-thread-id-canonicalize-simple
         (codex:multi-agent-thread-id-hyphenated-to-simple $text))
       CodexAbsent))

(= (codex:multi-agent-thread-id-canonicalize-braced $text)
   (if (and
         (== (str-length $text) 38)
         (and
           (== (str-slice $text 0 1) "{")
           (== (str-slice $text 37 38) "}")))
       (codex:multi-agent-thread-id-canonicalize-hyphenated
         (str-slice $text 1 37))
       CodexAbsent))

(= (codex:multi-agent-thread-id-canonicalize-urn $text)
   (if (and
         (== (str-length $text) 45)
         (str-starts-with? $text "urn:uuid:"))
       (codex:multi-agent-thread-id-canonicalize-hyphenated
         (str-slice $text 9 45))
       CodexAbsent))

(= (codex:multi-agent-thread-id-canonicalize-uuid $text)
   (let $len (str-length $text)
     (if (== $len 32)
         (codex:multi-agent-thread-id-canonicalize-simple $text)
         (if (== $len 36)
             (codex:multi-agent-thread-id-canonicalize-hyphenated $text)
             (if (== $len 38)
                 (codex:multi-agent-thread-id-canonicalize-braced $text)
                 (if (== $len 45)
                     (codex:multi-agent-thread-id-canonicalize-urn $text)
                     CodexAbsent))))))

(= (codex:multi-agent-thread-id-parse-subject $text)
   (let $len (str-length $text)
     (if (and
           (== $len 38)
           (and
             (== (str-slice $text 0 1) "{")
             (== (str-slice $text 37 38) "}")))
         (CodexMultiAgentThreadIdParseSubject (str-slice $text 1 37) 1 False)
         (if (and
               (== $len 45)
               (str-starts-with? $text "urn:uuid:"))
             (CodexMultiAgentThreadIdParseSubject
               (str-slice $text 9 45)
               9
               False)
             (CodexMultiAgentThreadIdParseSubject $text 0 True)))))

(= (codex:multi-agent-thread-id-is-error-scan-char $char)
   (if (== $char "-")
       True
       (codex:multi-agent-thread-id-is-ascii-hex-char $char)))

(= (codex:multi-agent-thread-id-first-invalid-char-from $text $offset $index)
   (if (== $index (str-length $text))
       CodexAbsent
       (let $char (str-slice $text $index (+ $index 1))
         (if (codex:multi-agent-thread-id-is-error-scan-char $char)
             (case
               (codex:multi-agent-thread-id-first-invalid-char-from
                 $text
                 $offset
                 (+ $index 1))
               (($result $result)))
             (CodexMultiAgentThreadIdInvalidChar
               $char
               (+ (+ $offset $index) 1))))))

(= (codex:multi-agent-thread-id-hyphen-count-from $text $index)
   (if (== $index (str-length $text))
       0
       (case
         (codex:multi-agent-thread-id-hyphen-count-from $text (+ $index 1))
         (($tail-count
           (if (== (str-slice $text $index (+ $index 1)) "-")
               (+ 1 $tail-count)
               $tail-count))))))

(= (codex:multi-agent-thread-id-hyphen-index-at
      $text
      $target-count
      $index
      $seen)
   (if (== $index (str-length $text))
       CodexAbsent
       (if (== (str-slice $text $index (+ $index 1)) "-")
           (if (== $seen $target-count)
               $index
               (case
                 (codex:multi-agent-thread-id-hyphen-index-at
                   $text
                   $target-count
                   (+ $index 1)
                   (+ $seen 1))
                 (($result $result))))
           (case
             (codex:multi-agent-thread-id-hyphen-index-at
               $text
               $target-count
               (+ $index 1)
               $seen)
             (($result $result))))))

(= (codex:multi-agent-thread-id-parse-char-debug $char $index)
   (str-concat
     "Error(ParseChar { character: '"
     (str-concat
       $char
       (str-concat
         "', index: "
         (str-concat (format-args "{}" ($index)) " })")))))

(= (codex:multi-agent-thread-id-parse-simple-length-debug $len)
   (str-concat
     "Error(ParseSimpleLength { len: "
     (str-concat (format-args "{}" ($len)) " })")))

(= (codex:multi-agent-thread-id-parse-group-count-debug $count)
   (str-concat
     "Error(ParseGroupCount { count: "
     (str-concat (format-args "{}" ($count)) " })")))

(= (codex:multi-agent-thread-id-parse-group-length-debug $group $len $index)
   (str-concat
     "Error(ParseGroupLength { group: "
     (str-concat
       (format-args "{}" ($group))
       (str-concat
         ", len: "
         (str-concat
           (format-args "{}" ($len))
           (str-concat
             ", index: "
             (str-concat (format-args "{}" ($index)) " })")))))))

(= (codex:multi-agent-thread-id-parse-group-length-check
      $text
      $offset
      $group
      $block-start
      $expected-hyphen-index)
   (let $hyphen-index
     (codex:multi-agent-thread-id-hyphen-index-at $text $group 0 0)
     (if (== $hyphen-index $expected-hyphen-index)
         CodexAbsent
         (codex:multi-agent-thread-id-parse-group-length-debug
           $group
           (- $hyphen-index $block-start)
           (+ $offset (+ $block-start 1))))))

(= (codex:multi-agent-thread-id-parse-group-length-debug-for $text $offset)
   (let $group-0
     (codex:multi-agent-thread-id-parse-group-length-check $text $offset 0 0 8)
     (if (not (== $group-0 CodexAbsent))
         $group-0
         (let $group-1
           (codex:multi-agent-thread-id-parse-group-length-check
             $text
             $offset
             1
             9
             13)
           (if (not (== $group-1 CodexAbsent))
               $group-1
               (let $group-2
                 (codex:multi-agent-thread-id-parse-group-length-check
                   $text
                   $offset
                   2
                   14
                   18)
                 (if (not (== $group-2 CodexAbsent))
                     $group-2
                     (let $group-3
                       (codex:multi-agent-thread-id-parse-group-length-check
                         $text
                         $offset
                         3
                         19
                         23)
                       (if (not (== $group-3 CodexAbsent))
                           $group-3
                           (codex:multi-agent-thread-id-parse-group-length-debug
                             4
                             (- (str-length $text) 24)
                             (+ $offset 25)))))))))))

(= (codex:multi-agent-thread-id-parse-error-debug-from-subject
      (CodexMultiAgentThreadIdParseSubject $text $offset $simple)
      $original-len)
   (case
     (codex:multi-agent-thread-id-first-invalid-char-from $text $offset 0)
     (((CodexMultiAgentThreadIdInvalidChar $char $index)
       (codex:multi-agent-thread-id-parse-char-debug $char $index))
      (CodexAbsent
       (let $hyphen-count
         (codex:multi-agent-thread-id-hyphen-count-from $text 0)
         (if (and (== $hyphen-count 0) $simple)
             (codex:multi-agent-thread-id-parse-simple-length-debug
               $original-len)
             (if (not (== $hyphen-count 4))
                 (codex:multi-agent-thread-id-parse-group-count-debug
                   (+ $hyphen-count 1))
                 (codex:multi-agent-thread-id-parse-group-length-debug-for
                   $text
                   $offset))))))))

(= (codex:multi-agent-thread-id-parse-error-debug $text)
   (codex:multi-agent-thread-id-parse-error-debug-from-subject
     (codex:multi-agent-thread-id-parse-subject $text)
     (str-length $text)))

(= (codex:multi-agent-parse-agent-id-target $target)
   (case (codex:multi-agent-thread-id-canonicalize-uuid $target)
     ((CodexAbsent
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           (str-concat
             "invalid agent id "
             (str-concat
               $target
               (str-concat
                 ": "
                 (codex:multi-agent-thread-id-parse-error-debug
                   $target)))))))
      ($thread-id
       (codex:multi-agent-common-ok $thread-id)))))

(= (codex:multi-agent-parse-agent-id-targets-rest ())
   (codex:multi-agent-common-ok ()))

(= (codex:multi-agent-parse-agent-id-targets-rest $targets)
   (let ($head $tail) (decons-atom $targets)
     (case (codex:multi-agent-parse-agent-id-target $head)
       (((CodexMultiAgentCommonErr $error)
         (codex:multi-agent-common-err $error))
        ((CodexMultiAgentCommonOk $thread-id)
         (case (codex:multi-agent-parse-agent-id-targets-rest $tail)
           (((CodexMultiAgentCommonErr $error)
             (codex:multi-agent-common-err $error))
            ((CodexMultiAgentCommonOk $thread-ids)
             (codex:multi-agent-common-ok
               (cons-atom $thread-id $thread-ids))))))))))

(= (codex:multi-agent-parse-agent-id-targets $targets)
   (if (== $targets ())
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           "agent ids must be non-empty"))
       (codex:multi-agent-parse-agent-id-targets-rest $targets)))

(= (codex:multi-agent-function-arguments $payload)
   (case $payload
     (((CodexToolPayloadFunction $arguments)
       (codex:multi-agent-common-ok $arguments))
      ($other
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           "collab handler received unsupported payload"))))))

(= (codex:multi-agent-tool-output-json-text $json $tool-name)
   ; Rust's generic helper serializes `T: Serialize` and falls back to a JSON
   ; string containing `failed to serialize {tool_name} result: ...`. This
   ; CeTTa layer receives already-projected JSON atoms, so `json-stringify`
   ; has no equivalent serde failure branch.
   (json-stringify $json))

(= (codex:multi-agent-tool-output-response-item
      $call-id
      $payload
      $json
      $success
      $tool-name)
   (codex:tool-output-to-response-item
     (codex:function-tool-output-from-text
       (codex:multi-agent-tool-output-json-text $json $tool-name)
       $success)
     $call-id
     $payload))

(= (codex:multi-agent-tool-output-code-mode-result $json $tool-name)
   ; Same representation note as `multi-agent-tool-output-json-text`: callers
   ; pass the projected JsonValue directly, matching Rust's `serde_json::to_value`
   ; success path.
   $json)

(= (codex:multi-agent-status-map-entry $thread-id $status)
   (CodexMultiAgentStatusEntry $thread-id $status))

(= (codex:multi-agent-status-map-entry-thread-id
      (CodexMultiAgentStatusEntry $thread-id $status))
   $thread-id)

(= (codex:multi-agent-status-map-entry-status
      (CodexMultiAgentStatusEntry $thread-id $status))
   $status)

(= (codex:multi-agent-status-lookup () $thread-id)
   CodexAbsent)

(= (codex:multi-agent-status-lookup $statuses $thread-id)
   (let $head (list:first $statuses)
     (let $tail (list:rest $statuses)
       (if (== (codex:multi-agent-status-map-entry-thread-id $head) $thread-id)
           (codex:multi-agent-status-map-entry-status $head)
           (codex:multi-agent-status-lookup $tail $thread-id)))))

(= (codex:multi-agent-string-list-contains () $needle)
   False)

(= (codex:multi-agent-string-list-contains $items $needle)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (if (== $head $needle)
           True
           (codex:multi-agent-string-list-contains $tail $needle)))))

(= (codex:multi-agent-receiver-thread-ids ())
   ())

(= (codex:multi-agent-receiver-thread-ids $receiver-agents)
   (let ($head $tail) (decons-atom $receiver-agents)
     (case (codex:multi-agent-receiver-thread-ids $tail)
       (($tail-thread-ids
         ; CeTTa evaluation accommodation: materialize the recursive tail
         ; before consing so imported callers receive a concrete list, matching
         ; Rust's Vec collection behavior.
         (case $head
           (((CodexCollabAgentRef $thread-id $agent-nickname $agent-role)
             (cons-atom $thread-id $tail-thread-ids))
            ((codex:collab-agent-ref $thread-id $agent-nickname $agent-role)
             (cons-atom $thread-id $tail-thread-ids)))))))))

(= (codex:multi-agent-receiver-status-entries () $statuses)
   ())

(= (codex:multi-agent-receiver-status-entry-from-ref
      (CodexCollabAgentRef $thread-id $agent-nickname $agent-role)
      $statuses
      $tail-entries)
   (case (codex:multi-agent-status-lookup $statuses $thread-id)
     ((CodexAbsent $tail-entries)
      ($status
       (cons-atom
         (codex:collab-agent-status-entry
           $thread-id
           $agent-nickname
           $agent-role
           $status)
         $tail-entries)))))

(= (codex:multi-agent-receiver-status-entry-from-ref
      (codex:collab-agent-ref $thread-id $agent-nickname $agent-role)
      $statuses
      $tail-entries)
   (case (codex:multi-agent-status-lookup $statuses $thread-id)
     ((CodexAbsent $tail-entries)
      ($status
       (cons-atom
         (codex:collab-agent-status-entry
           $thread-id
           $agent-nickname
           $agent-role
           $status)
         $tail-entries)))))

(= (codex:multi-agent-receiver-status-entries $receiver-agents $statuses)
   (let ($head $tail) (decons-atom $receiver-agents)
     (case (codex:multi-agent-receiver-status-entries $tail $statuses)
       (($tail-entries
         (codex:multi-agent-receiver-status-entry-from-ref
           $head
           $statuses
           $tail-entries))))))

(= (codex:multi-agent-extra-status-thread-ids () $seen-thread-ids)
   ())

(= (codex:multi-agent-extra-status-thread-ids $statuses $seen-thread-ids)
   (let ($head $tail) (decons-atom $statuses)
     (let $thread-id
       (codex:multi-agent-status-map-entry-thread-id $head)
       (case (codex:multi-agent-extra-status-thread-ids $tail $seen-thread-ids)
         (($rest
           (case
             (codex:multi-agent-string-list-contains
               $seen-thread-ids
               $thread-id)
             ((True $rest)
              (False (cons-atom $thread-id $rest))))))))))

(= (codex:multi-agent-extra-status-entries-from-thread-ids
      $statuses
      ())
   ())

(= (codex:multi-agent-extra-status-entries-from-thread-ids
      $statuses
      $thread-ids)
   (let ($thread-id $tail) (decons-atom $thread-ids)
     (case (codex:multi-agent-extra-status-entries-from-thread-ids
             $statuses
             $tail)
       (($tail-entries
         (case (codex:multi-agent-status-lookup $statuses $thread-id)
           ((CodexAbsent $tail-entries)
            ($status
             (cons-atom
               (codex:collab-agent-status-entry
                 $thread-id
                 CodexAbsent
                 CodexAbsent
                 $status)
               $tail-entries)))))))))

(= (codex:multi-agent-extra-status-entries $statuses $receiver-agents)
   (let $seen-thread-ids
     (once (eval (codex:multi-agent-receiver-thread-ids $receiver-agents)))
     (let $extra-thread-ids
       (once
         (eval
           (codex:multi-agent-extra-status-thread-ids
             $statuses
             $seen-thread-ids)))
       (case (sort-strings $extra-thread-ids)
         (($sorted-thread-ids
           (codex:multi-agent-extra-status-entries-from-thread-ids
             $statuses
             $sorted-thread-ids)))))))

(= (codex:multi-agent-build-wait-agent-statuses
      ()
      $receiver-agents)
   ())

(= (codex:multi-agent-build-wait-agent-statuses
      $statuses
      $receiver-agents)
   (let $receiver-entries
     (once
       (eval
         (codex:multi-agent-receiver-status-entries
           $receiver-agents
           $statuses)))
     (let $extra-entries
       (once
         (eval
           (codex:multi-agent-extra-status-entries
             $statuses
             $receiver-agents)))
       (list:append $receiver-entries $extra-entries))))

(= (codex:multi-agent-codex-err-unsupported-operation $message)
   (CodexErrUnsupportedOperation $message))

(= (codex:multi-agent-codex-err-thread-not-found $thread-id)
   (CodexErrThreadNotFound $thread-id))

(= (codex:multi-agent-codex-err-internal-agent-died)
   (CodexErrInternalAgentDied))

(= (codex:multi-agent-codex-err-other $display)
   (CodexErrOther $display))

(= (codex:multi-agent-codex-err-display
      (CodexErrUnsupportedOperation $message))
   (str-concat "unsupported operation: " $message))

(= (codex:multi-agent-codex-err-display
      (CodexErrThreadNotFound $thread-id))
   (str-concat "no thread with id: " $thread-id))

(= (codex:multi-agent-codex-err-display
      (CodexErrInternalAgentDied))
   "internal error; agent loop died unexpectedly")

(= (codex:multi-agent-codex-err-display
      (CodexErrOther $display))
   $display)

(= (codex:multi-agent-collab-spawn-error $err)
   (case $err
     (((CodexErrUnsupportedOperation "thread manager dropped")
       (codex:function-call-error-respond-to-model
         "collab manager unavailable"))
      ((CodexErrUnsupportedOperation $message)
       (codex:function-call-error-respond-to-model $message))
      ($other
       (codex:function-call-error-respond-to-model
         (str-concat
           "collab spawn failed: "
           (codex:multi-agent-codex-err-display $other)))))))

(= (codex:multi-agent-collab-agent-error $agent-id $err)
   (case $err
     (((CodexErrThreadNotFound $thread-id)
       (codex:function-call-error-respond-to-model
         (str-concat "agent with id " (str-concat $thread-id " not found"))))
      ((CodexErrInternalAgentDied)
       (codex:function-call-error-respond-to-model
         (str-concat "agent with id " (str-concat $agent-id " is closed"))))
      ((CodexErrUnsupportedOperation $message)
       (codex:function-call-error-respond-to-model
         "collab manager unavailable"))
      ($other
       (codex:function-call-error-respond-to-model
         (str-concat
           "collab tool failed: "
           (codex:multi-agent-codex-err-display $other)))))))

(= (codex:multi-agent-parent-agent-path-or-root $parent-session-source)
   (case (codex:session-source-get-agent-path $parent-session-source)
     ((CodexAbsent (codex:agent-path-root))
      ($agent-path $agent-path))))

(= (codex:multi-agent-thread-spawn-agent-path
      $parent-session-source
      $task-name)
   (case $task-name
     ((CodexAbsent
       (codex:multi-agent-common-ok CodexAbsent))
      ($name
       (let $parent-path
         (codex:multi-agent-parent-agent-path-or-root $parent-session-source)
         (case (codex:agent-path-join $parent-path $name)
           (((CodexAgentPathOk $agent-path)
             (codex:multi-agent-common-ok $agent-path))
            ((CodexAgentPathErr $message)
             (codex:multi-agent-common-err
               (codex:function-call-error-respond-to-model $message))))))))))

(= (codex:multi-agent-thread-spawn-source
      $parent-thread-id
      $parent-session-source
      $depth
      $agent-role
      $task-name)
   (case
     (codex:multi-agent-thread-spawn-agent-path
       $parent-session-source
       $task-name)
     (((CodexMultiAgentCommonOk $agent-path)
       (codex:multi-agent-common-ok
         (codex:session-source-subagent
           (codex:subagent-source-thread-spawn
             $parent-thread-id
             $depth
             $agent-path
             CodexAbsent
             $agent-role))))
      ((CodexMultiAgentCommonErr $error)
       (codex:multi-agent-common-err $error)))))

(= (codex:multi-agent-parse-collab-input $message $items)
   (if (and (not (== $message CodexAbsent))
            (not (== $items CodexAbsent)))
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           "Provide either message or items, but not both"))
       (if (and (== $message CodexAbsent)
                (== $items CodexAbsent))
           (codex:multi-agent-common-err
             (codex:function-call-error-respond-to-model
               "Provide one of: message or items"))
           (if (not (== $message CodexAbsent))
               (if (== (str-trim $message) "")
                   (codex:multi-agent-common-err
                     (codex:function-call-error-respond-to-model
                       "Empty message can't be sent to an agent"))
                   (codex:multi-agent-common-ok
                     (codex:user-input-op
                       ((codex:user-input-text $message)))))
               (if (== $items ())
                   (codex:multi-agent-common-err
                     (codex:function-call-error-respond-to-model
                       "Items can't be empty"))
                   (codex:multi-agent-common-ok
                     (codex:user-input-op $items)))))))

(= (codex:multi-agent-reject-full-fork-spawn-overrides
      $agent-type
      $model
      $reasoning-effort)
   (if (or (not (== $agent-type CodexAbsent))
           (or (not (== $model CodexAbsent))
               (not (== $reasoning-effort CodexAbsent))))
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           "Full-history forked agents inherit the parent agent type, model, and reasoning effort; omit agent_type, model, and reasoning_effort, or spawn without a full-history fork."))
       (codex:multi-agent-common-ok ())))

(= (codex:multi-agent-model-list-contains () $requested-model)
   False)

(= (codex:multi-agent-model-list-contains $available-models $requested-model)
   (let $head (list:first $available-models)
     (let $tail (list:rest $available-models)
       (if (== $head $requested-model)
           True
           (codex:multi-agent-model-list-contains $tail $requested-model)))))

(= (codex:multi-agent-find-spawn-agent-model-name
      $available-models
      $requested-model)
   (case
     (codex:multi-agent-model-list-contains
       $available-models
       $requested-model)
     ((True
       (codex:multi-agent-common-ok $requested-model))
      (False
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           (format-args
             "Unknown model `{}` for spawn_agent. Available models: {}"
             ($requested-model (str-join ", " $available-models)))))))))

(= (codex:multi-agent-validate-spawn-agent-reasoning-effort
      $model
      $supported-reasoning-levels
      $requested-reasoning-effort)
   (case
     (codex:multi-agent-string-list-contains
       $supported-reasoning-levels
       $requested-reasoning-effort)
     ((True
       (codex:multi-agent-common-ok ()))
      (False
       (codex:multi-agent-common-err
         (codex:function-call-error-respond-to-model
           (format-args
             "Reasoning effort `{}` is not supported for model `{}`. Supported reasoning efforts: {}"
             ($requested-reasoning-effort
              $model
              (str-join ", " $supported-reasoning-levels)))))))))
