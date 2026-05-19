; Rust-faithful pure thread rollout truncation slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/thread_rollout_truncation.rs
; - the `is_user_turn_boundary` dependency from
;   openai-codex/codex-rs/core/src/context_manager/history.rs
; - the InterAgentCommunication message-content predicate from
;   openai-codex/codex-rs/protocol/src/protocol.rs
;
; Covered in this increment:
; - InitialHistory::scan_rollout_items use for prior user-turn detection
; - user_message_positions_in_rollout
; - fork_turn_positions_in_rollout
; - truncate_rollout_before_nth_user_message_from_start
; - truncate_rollout_to_last_n_fork_turns
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust carries RolloutItem, ResumedHistory, and InitialHistory in the protocol
;   crate. The current CeTTa protocol surface has not yet exposed those wire
;   enums, so this slice introduces local constructors with the same variant
;   boundaries needed by the truncation algorithms.
; - Rust's `usize::MAX` is platform-sized. This port runs with the target
;   Linux/x86_64 Codex environment and exposes the corresponding value through
;   `codex:thread-rollout-usize-max`.
; - Rust pushes positions onto Vecs in chronological order. The fork-turn
;   helper accumulates positions in reverse and reverses once at the boundary;
;   this is the same ordering/rollback algorithm expressed in a reducer-stable
;   form for CeTTa list terms.

!(import! &self agent_path)
!(import! &self event_mapping)
!(import! &self json)
!(import! &self list)
!(import! &self protocol)

(= (codex:thread-rollout-usize-max)
   18446744073709551615)

(= (codex:rollout-response-item $item)
   (CodexRolloutItemResponseItem $item))

(= (codex:rollout-event-msg $event)
   (CodexRolloutItemEventMsg $event))

(= (codex:rollout-session-meta $meta)
   (CodexRolloutItemSessionMeta $meta))

(= (codex:rollout-compacted $item)
   (CodexRolloutItemCompacted $item))

(= (codex:rollout-turn-context $item)
   (CodexRolloutItemTurnContext $item))

(= (codex:resumed-history $conversation-id $history $rollout-path)
   (CodexResumedHistory $conversation-id $history $rollout-path))

(= (codex:initial-history-new)
   (CodexInitialHistoryNew))

(= (codex:initial-history-cleared)
   (CodexInitialHistoryCleared))

(= (codex:initial-history-resumed $resumed)
   (CodexInitialHistoryResumed $resumed))

(= (codex:initial-history-forked $items)
   (CodexInitialHistoryForked $items))

(= (codex:thread-rollout-append-item () $item)
   ($item))

(= (codex:thread-rollout-append-item $items $item)
   (let ($head $tail) (decons-atom $items)
     (case (codex:thread-rollout-append-item $tail $item)
       (($rest
          (cons-atom $head $rest))))))

(= (codex:thread-rollout-take () $count)
   ())

(= (codex:thread-rollout-take $items $count)
   (case (<= $count 0)
     ((True ())
      (False
       (let ($head $tail) (decons-atom $items)
         (case (codex:thread-rollout-take $tail (- $count 1))
           (($rest
              (cons-atom $head $rest)))))))))

(= (codex:thread-rollout-drop () $count)
   ())

(= (codex:thread-rollout-drop $items $count)
   (case (<= $count 0)
     ((True $items)
      (False
       (let ($head $tail) (decons-atom $items)
         (case (codex:thread-rollout-drop $tail (- $count 1))
           (($result $result))))))))

(= (codex:thread-rollout-retain-less-than () $limit)
   ())

(= (codex:thread-rollout-retain-less-than $positions $limit)
   (let ($head $tail) (decons-atom $positions)
     (case (codex:thread-rollout-retain-less-than $tail $limit)
       (($rest
          (case (< $head $limit)
            ((True (cons-atom $head $rest))
             (False $rest))))))))

(= (codex:thread-rollout-saturating-sub $lhs $rhs)
   (if (> $lhs $rhs)
       (- $lhs $rhs)
       0))

(= (codex:thread-rollout-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:thread-rollout-json-object-required-string $object $key)
   (case (json-object-get $object $key)
     (((JsonString $text) $text)
      ($other Empty))))

(= (codex:thread-rollout-json-object-required-bool $object $key)
   (case (json-object-get $object $key)
     (((JsonBool $value) $value)
      ($other Empty))))

(= (codex:thread-rollout-json-object-optional-array $object $key)
   (case (codex:thread-rollout-json-object-optional-value $object $key)
     ((CodexAbsent ())
      ((JsonArray $items) $items)
      ($other Empty))))

(= (codex:thread-rollout-agent-path-from-json $value)
   (case $value
     (((JsonString $path)
       (case (codex:agent-path-from-string $path)
         (((CodexAgentPathOk $agent-path) $agent-path)
          ($other Empty))))
      ($other Empty))))

(= (codex:thread-rollout-agent-paths-from-json-items ())
   ())

(= (codex:thread-rollout-agent-paths-from-json-items $items)
   (let ($head $tail) (decons-atom $items)
     (case (codex:thread-rollout-agent-path-from-json $head)
       ((Empty Empty)
        ($path
         (case
           (codex:thread-rollout-agent-paths-from-json-items $tail)
           ((Empty Empty)
            ($rest
             (cons-atom $path $rest)))))))))

(= (codex:thread-rollout-inter-agent-communication-from-object $object)
   (case
     (codex:thread-rollout-agent-path-from-json
       (json-object-get $object "author"))
     ((Empty Empty)
      ($author
       (case
         (codex:thread-rollout-agent-path-from-json
           (json-object-get $object "recipient"))
         ((Empty Empty)
          ($recipient
           (case
             (codex:thread-rollout-json-object-optional-array
               $object
               "other_recipients")
             ((Empty Empty)
              ($other-recipient-items
               (case
                 (codex:thread-rollout-agent-paths-from-json-items
                   $other-recipient-items)
                 ((Empty Empty)
                  ($other-recipients
                   (let $content
                     (codex:thread-rollout-json-object-required-string
                       $object
                       "content")
                     (if (== $content Empty)
                         Empty
                         (let $trigger-turn
                           (codex:thread-rollout-json-object-required-bool
                             $object
                             "trigger_turn")
                           (if (== $trigger-turn Empty)
                               Empty
                               (CodexInterAgentCommunication
                                 $author
                                 $recipient
                                 $other-recipients
                                 $content
                                 $trigger-turn))))))))))))))))))

(= (codex:thread-rollout-inter-agent-communication-from-text $text)
   (case (catch (eval (json-parse $text)))
     (((catch (JsonObject $pairs))
       (codex:thread-rollout-inter-agent-communication-from-object
         (JsonObject $pairs)))
      ($other Empty))))

(= (codex:thread-rollout-inter-agent-communication-from-content $content)
   (case $content
     ((((CodexInputText $text))
       (codex:thread-rollout-inter-agent-communication-from-text $text))
      (((CodexOutputText $text))
       (codex:thread-rollout-inter-agent-communication-from-text $text))
      ($other Empty))))

(= (codex:is-thread-rollout-inter-agent-instruction-content $content)
   (case
     (codex:thread-rollout-inter-agent-communication-from-content $content)
     ((Empty False)
      ($communication True))))

(= (codex:thread-rollout-inter-agent-response-message
      $author
      $recipient
      $other-recipients
      $content
      $trigger-turn)
   (let $communication
     (CodexInterAgentCommunication
       $author
       $recipient
       $other-recipients
       $content
       $trigger-turn)
     (CodexResponseItemMessage
       "assistant"
       ((CodexOutputText
          (json-stringify (codex:inter-agent-communication-json $communication))))
       CodexAbsent)))

(= (codex:is-thread-rollout-user-turn-boundary $item)
   (case (once (eval $item))
     (((CodexResponseItemMessage "user" $content $phase)
       (not (codex:is-contextual-user-message-content $content)))
      ((CodexResponseItemMessageWithId $id "user" $content $phase)
       (not (codex:is-contextual-user-message-content $content)))
      ((CodexResponseItemMessage "assistant" $content $phase)
       (codex:is-thread-rollout-inter-agent-instruction-content $content))
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       (codex:is-thread-rollout-inter-agent-instruction-content $content))
      ($other False))))

(= (codex:rollout-item-is-user-turn-boundary $item)
   (case (once (eval $item))
     (((CodexRolloutItemResponseItem $response-item)
       (codex:is-thread-rollout-user-turn-boundary $response-item))
      ($other False))))

(= (codex:initial-history-has-prior-user-turns
      (CodexInitialHistoryNew))
   False)

(= (codex:initial-history-has-prior-user-turns
      (CodexInitialHistoryCleared))
   False)

(= (codex:initial-history-has-prior-user-turns
      (CodexInitialHistoryForked $items))
   (codex:thread-rollout-scan-user-turn-boundary $items))

(= (codex:initial-history-has-prior-user-turns
      (CodexInitialHistoryResumed
        (CodexResumedHistory $conversation-id $history $rollout-path)))
   (codex:thread-rollout-scan-user-turn-boundary $history))

(= (codex:thread-rollout-scan-user-turn-boundary ())
   False)

(= (codex:thread-rollout-scan-user-turn-boundary $items)
   (let ($head $tail) (decons-atom $items)
     (case (codex:rollout-item-is-user-turn-boundary $head)
       ((True True)
        (False
         (case (codex:thread-rollout-scan-user-turn-boundary $tail)
           (($result $result))))))))

(= (codex:is-real-user-message-boundary $item)
   (case (codex:parse-turn-item $item)
     (((CodexTurnItemUserMessage $message) True)
      ($other False))))

(= (codex:is-trigger-turn-boundary $item)
   (case (once (eval $item))
     (((CodexResponseItemMessage "assistant" $content $phase)
       (case
         (codex:thread-rollout-inter-agent-communication-from-content $content)
         (((CodexInterAgentCommunication
             $author
             $recipient
             $other-recipients
             $content-text
             $trigger-turn)
           $trigger-turn)
          ($other False))))
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       (case
         (codex:thread-rollout-inter-agent-communication-from-content $content)
         (((CodexInterAgentCommunication
             $author
             $recipient
             $other-recipients
             $content-text
             $trigger-turn)
           $trigger-turn)
          ($other False))))
      ($other False))))

(= (codex:user-message-positions-in-rollout $items)
   (codex:user-message-positions-in-rollout-loop $items 0 ()))

(= (codex:user-message-positions-in-rollout-loop () $idx $positions)
   (case $positions
     (($result $result))))

(= (codex:user-message-positions-in-rollout-loop $items $idx $positions)
   (let ($head $tail) (decons-atom $items)
     (case (once (eval $head))
       (((CodexRolloutItemResponseItem $response-item)
         (case
           (codex:is-real-user-message-boundary $response-item)
           ((True
             (case
               (codex:user-message-positions-in-rollout-loop
                 $tail
                 (+ $idx 1)
                 (codex:thread-rollout-append-item $positions $idx))
               (($result $result))))
            (False
             (case
               (codex:user-message-positions-in-rollout-loop
                 $tail
                 (+ $idx 1)
                 $positions)
               (($result $result)))))))
        ((CodexRolloutItemEventMsg (CodexEventThreadRolledBack $num-turns))
         (let $new-len
           (codex:thread-rollout-saturating-sub
             (list:len $positions)
             $num-turns)
           (case
             (codex:user-message-positions-in-rollout-loop
               $tail
               (+ $idx 1)
               (codex:thread-rollout-take $positions $new-len))
             (($result $result)))))
        ($other
         (case
           (codex:user-message-positions-in-rollout-loop
             $tail
             (+ $idx 1)
             $positions)
           (($result $result))))))))

(= (codex:thread-rollout-last-position ($item))
   $item)

(= (codex:thread-rollout-last-position $items)
   (let ($head $tail) (decons-atom $items)
     (if (== $tail ())
         $head
         (codex:thread-rollout-last-position $tail))))

(= (codex:fork-turn-positions-in-rollout $items)
   (case (codex:fork-turn-positions-in-rollout-rev-loop $items 0 () ())
     (($reversed-positions
       (list:reverse $reversed-positions)))))

(= (codex:fork-turn-positions-in-rollout-rev-loop
      ()
      $idx
      $rollback-turn-positions-rev
      $fork-turn-positions-rev)
   $fork-turn-positions-rev)

(= (codex:fork-turn-positions-in-rollout-rev-next
      $tail
      $idx
      $rollback-turn-positions-rev
      $fork-turn-positions-rev)
   (case
     (codex:fork-turn-positions-in-rollout-rev-loop
       $tail
       (+ $idx 1)
       $rollback-turn-positions-rev
       $fork-turn-positions-rev)
     (($result $result))))

(= (codex:fork-turn-positions-in-rollout-rev-loop
      $items
      $idx
      $rollback-turn-positions-rev
      $fork-turn-positions-rev)
   (let ($head $tail) (decons-atom $items)
     (case (once (eval $head))
       (((CodexRolloutItemResponseItem $response-item)
         (case (codex:is-thread-rollout-user-turn-boundary $response-item)
           ((True
             (case
               (or (codex:is-real-user-message-boundary $response-item)
                   (codex:is-trigger-turn-boundary $response-item))
               ((True
                 (codex:fork-turn-positions-in-rollout-rev-next
                   $tail
                   $idx
                   (cons-atom $idx $rollback-turn-positions-rev)
                   (cons-atom $idx $fork-turn-positions-rev)))
                (False
                 (codex:fork-turn-positions-in-rollout-rev-next
                   $tail
                   $idx
                   (cons-atom $idx $rollback-turn-positions-rev)
                   $fork-turn-positions-rev)))))
            (False
             (case
               (or (codex:is-real-user-message-boundary $response-item)
                   (codex:is-trigger-turn-boundary $response-item))
               ((True
                 (codex:fork-turn-positions-in-rollout-rev-next
                   $tail
                   $idx
                   $rollback-turn-positions-rev
                   (cons-atom $idx $fork-turn-positions-rev)))
                (False
                 (codex:fork-turn-positions-in-rollout-rev-next
                   $tail
                   $idx
                   $rollback-turn-positions-rev
                   $fork-turn-positions-rev))))))))
        ((CodexRolloutItemEventMsg (CodexEventThreadRolledBack $num-turns))
         (if (== $num-turns 0)
             (codex:fork-turn-positions-in-rollout-rev-next
               $tail
               $idx
               $rollback-turn-positions-rev
               $fork-turn-positions-rev)
             (if (== $rollback-turn-positions-rev ())
                 (codex:fork-turn-positions-in-rollout-rev-next
                   $tail
                   $idx
                   $rollback-turn-positions-rev
                   $fork-turn-positions-rev)
                 (let $rollback-turn-count
                   (list:len $rollback-turn-positions-rev)
                   (let $rollback-start-idx
                     (if (< $rollback-turn-count $num-turns)
                         (codex:thread-rollout-last-position
                           $rollback-turn-positions-rev)
                         (list:at
                           $rollback-turn-positions-rev
                           (- $num-turns 1)))
                     (codex:fork-turn-positions-in-rollout-rev-next
                       $tail
                       $idx
                       (codex:thread-rollout-drop
                         $rollback-turn-positions-rev
                         $num-turns)
                       (codex:thread-rollout-retain-less-than
                         $fork-turn-positions-rev
                         $rollback-start-idx)))))))
        ($other
         (codex:fork-turn-positions-in-rollout-rev-next
           $tail
           $idx
           $rollback-turn-positions-rev
           $fork-turn-positions-rev))))))

(= (codex:truncate-rollout-before-nth-user-message-from-start
      $items
      $n-from-start)
   (if (== $n-from-start (codex:thread-rollout-usize-max))
       $items
       (case (codex:user-message-positions-in-rollout $items)
         (($user-positions
           (case (<= (list:len $user-positions) $n-from-start)
             ((True $items)
              (False
               (let $cut-idx (list:at $user-positions $n-from-start)
                 (case (codex:thread-rollout-take $items $cut-idx)
                   (($result $result))))))))))))

(= (codex:truncate-rollout-to-last-n-fork-turns $items 0)
   ())

(= (codex:truncate-rollout-to-last-n-fork-turns $items $n-from-end)
   (case (codex:fork-turn-positions-in-rollout $items)
     (($fork-turn-positions
       (case (<= (list:len $fork-turn-positions) $n-from-end)
         ((True $items)
          (False
           (let $keep-idx
             (list:at
               $fork-turn-positions
               (- (list:len $fork-turn-positions) $n-from-end))
             (case (codex:thread-rollout-drop $items $keep-idx)
               (($result $result)))))))))))
