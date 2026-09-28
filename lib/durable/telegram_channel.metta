!(import! &self durable:telegram_agent)

; Fixed service program, telegram-channel/1. The client is an agent's own
; long-lived loop: it reads deliveries and receipts as worker tasks, answers
; each task only to acknowledge it, and acts through keyed submissions. The
; per-chat sending state machine is telegram-agent/1's. Client text is data,
; never code, a destination, a grant or a scope.
;
; Every observation is a JSON array built from lane IDs, fixed kinds, roles,
; numbers and exact serialized provider objects, none of which need escaping:
;   ["input", lane, kind, role, update]
;   ["input-too-large", lane, kind, role]
;   ["delivery", key, position, count, result]
;   ["rejected", key, reason]
;   ["released", lane, key, position]
; with result ["delivered", message-id] | ["failed", code] |
; ["not-sent"] | ["uncertain", reason].

(= (tg-channel:limit) 65536)

; Actor records carry the version of the program that wrote them. A chat
; actor written by any other program version is held, never reinterpreted.
(= (tg-channel:state)
   (case (collapse (match &self (host:record 1 $key $record) $record))
     ((() (tg-agent:idle))
      (((host:actor 1 "telegram-channel/1" $state)) $state)
      ($other (tg-agent:held invalid-actor)))))

; Dispatch query: view 0 = accepted intent, 1 = current actor. Only the
; expected position is eligible; native admission also checks attempts/outcomes.
(= (tg-channel:dispatchable)
   (match &self (host:record 0 $key (host:intent 1 "telegram.action" "1" $action
     (tg-agent:sent 1 $source $lane $batch $position $count)))
     (case (tg-channel:state)
       (((tg-agent:sending $batch $position $count) True)
        ($other False)))))

; Incoming input: views 2 = received record. Channel 0 = the client worker.
; The chat's sending actor is not involved: reading never makes a draft stale
; and never waits for cognition. Non-routed input uses the audit actor.
(= (tg-channel:receive $worker $source $lane)
   (match &self (host:record 0 $key (host:input 1 $source $id $ledger $lane $disposition))
     (match &self (host:record 2 $ledger (host:received 1 $source $id $lane $disposition $input))
       (if (== $disposition routed)
         (case $input
           (((telegram:input 1 $kind $chat $thread $sender $role $update)
             (let $update-json (json:stringify $update)
               (let $full (format-args "[\"input\",\"{}\",\"{}\",\"{}\",{}]" ($lane $kind $role $update-json))
                 (let $observation
                      (if (> (str:length $full) (tg-channel:limit))
                        (format-args "[\"input-too-large\",\"{}\",\"{}\",\"{}\"]" ($lane $kind $role))
                        $full)
                   (host:transition (tg-channel:intake) ()
                     ((durable:worker:request 0 $worker $observation
                        (tg-channel:delivered 1 $source $lane $id))))))))
            ($bad Empty)))
         (host:transition (tg-agent:ignored $source $id $disposition) () ())))))

; The client answered a delivery or receipt task. Any body only acknowledges
; it: actions are never taken from an acknowledgment.
(= (tg-channel:ack $worker)
   (match &self (host:record 0 $key (host:worker-result 1 $worker $task $revision $body))
     (host:transition (tg-channel:intake) () ())))

; A keyed submission for one lane. Views 2 = the writable decision key
; (grant 0), 3 = this lane's pending submissions. Channels: 0 = Telegram actions,
; 1 = the client worker. The native host passes whether this is the lane's
; oldest pending submission in the ticket's own snapshot; a younger one waits.
; Destinations come from the key's lane, never from the client's JSON.
(= (tg-channel:submit $worker $source $lane $chat $thread $oldest)
   (match &self (host:record 0 $input (host:worker-submission 1 $worker $key $body))
     (if (not $oldest) Empty
       (case (tg-channel:state)
         (((tg-agent:idle)
           (case (tg-agent:batch $body $chat $thread)
             (((tg-agent:actions $actions)
               (let $count (size-atom $actions)
                 (host:transition (if (== $count 0) (tg-agent:idle) (tg-agent:sending $key 0 $count))
                   ((host:put 0 $key (tg-channel:decision 1 accepted $count)))
                   (tg-agent:intents $actions $source $lane $key 0 $count))))
              ($other (tg-channel:reject $worker $source $key invalid-command-batch)))))
          ($busy Empty))))))

(= (tg-channel:reject $worker $source $key $reason)
   (host:transition (tg-agent:idle)
     ((host:put 0 $key (tg-channel:decision 1 rejected $reason)))
     ((durable:worker:request 1 $worker (format-args "[\"rejected\",\"{}\",\"{}\"]" ($key $reason))
        (tg-channel:notified 1 $source $key)))))

; The host selects this branch only after a complete proposal fails its
; immutable action permissions. It uses the same observation and grants.
(= (tg-channel:reject-invalid-submission $worker $source)
   (match &self (host:record 0 $input (host:worker-submission 1 $worker $key $body))
     (tg-channel:reject $worker $source $key action-not-permitted)))

(= (tg-channel:result-json $result)
   (case $result
     (((tg-agent:delivered $id) (format-args "[\"delivered\",{}]" ($id)))
      ((tg-agent:failed $code) (format-args "[\"failed\",{}]" ($code)))
      ((tg-agent:not-sent) "[\"not-sent\"]")
      ((tg-agent:uncertain $reason) (format-args "[\"uncertain\",\"{}\"]" ($reason)))
      ($other "[\"uncertain\",\"unclassified\"]"))))

; A definitive outcome (delivered, failed with a 4xx, or never started)
; advances the lane and is reported. Only uncertain delivery holds the lane:
; the next message to that chat must not overtake one that may have arrived.
(= (tg-channel:advances $result)
   (case $result
     (((tg-agent:uncertain $reason) False)
      ($other True))))

; Completion views: 2 original intent, 3 outcome, 4 writable delivery key
; (grant 2). Channel 0 = the client worker, for the receipt only.
(= (tg-channel:complete $worker)
   (match &self (host:record 0 $input (host:completion 1 $effect $outkey))
    (match &self (host:record 2 $outkey (host:intent 1 "telegram.action" "1" $action
      (tg-agent:sent 1 $source $lane $batch $position $count)))
     (match &self (host:record 3 $outkey (host:outcome 1 $effect $attempt $kind $metadata $body))
      (case (tg-channel:state)
       (((tg-agent:sending $batch $position $count)
         (let $result (tg-agent:outcome (host:outcome 1 $effect $attempt $kind $metadata $body) $action)
           (let $result-json (tg-channel:result-json $result)
            (let $receipt (format-args "[\"delivery\",\"{}\",{},{},{}]"
                            ($batch $position $count $result-json))
             (host:transition
               (if (tg-channel:advances $result)
                 (if (== (+ $position 1) $count) (tg-agent:idle) (tg-agent:sending $batch (+ $position 1) $count))
                 (tg-agent:held $batch $position $count $result))
               ((host:put 2 $outkey (tg-agent:delivery 1 $batch $position $result)))
               ((durable:worker:request 0 $worker $receipt
                  (tg-channel:notified 1 $source $outkey))))))))
        ($other Empty)))))))

; An operator releases a lane held by uncertain delivery. Views 2 = the
; immutable request, 3 = its result key (grant 1). Channel 0 = the client,
; for the notice only. The uncertain action stays uncertain; the rest of its
; batch is abandoned and the lane takes the next submission. The client is
; told which action it was, so it can say so rather than assume either way.
(= (tg-channel:control $worker)
   (match &self (host:record 0 $input (host:telegram-control 1 $source $id $lane "release-worker" $batch))
     (match &self (host:record 2 $id (host:telegram-control 1 $source $id $lane "release-worker" $batch))
       (let $state (tg-channel:state)
         (if (or (== $state (tg-agent:held invalid-actor))
                 (not (== (collapse (match &self (host:record 3 $id $prior) True)) ()))) Empty
           (case $state
             (((tg-agent:held $batch $position $count $result)
               (let $notice (format-args "[\"released\",\"{}\",\"{}\",{}]" ($lane $batch $position))
                 (host:transition (tg-agent:idle)
                   ((host:put 1 $id (tg-agent:control-result 1 released $batch)))
                   ((durable:worker:request 0 $worker $notice (tg-channel:notified 1 $source $id))))))
              ($other (host:transition $state
                 ((host:put 1 $id (tg-agent:control-result 1 refused $batch))) ())))))))))
