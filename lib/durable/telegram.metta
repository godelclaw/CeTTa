!(import! &self json)
!(import! &self str)

; Pure provider policy. Data enters as a screened, durable poll observation.
; No function here sends, polls, reads a clock or updates durable state.
; Policy: (telegram:policy 1 (chat-ids...) allow-private (operators...) (wake-peers...)).

; Canonical JSON is inert data. In particular, passing a string between policy
; functions must not evaluate each of its Unicode scalar cells again.
(: JsonObjectV1 (-> Atom Atom))
(: JsonArrayV1 (-> Atom Atom))
(: JsonStringV1 (-> Atom Atom))
(: JsonNumberV1 (-> Atom Atom))
(: JsonBoolV1 (-> Atom Atom))
(: JsonMemberV1 (-> Atom Atom Atom Atom Atom))

(= (telegram:field $object $key)
   (case (json:get-all $object $key)
     (((JsonMatchesV1 ($value)) (tg:some $value))
      ((JsonMatchesV1 ()) tg:none)
      ($other tg:bad))))

; Parse only decimal integer lexemes. Never pass provider text to MeTTa parse,
; which could intern a nonnumeric symbol permanently. Accumulate negatively to
; include INT64_MIN without an overflowing intermediate positive integer.
(= (telegram:integer $value)
   (case $value
     (((JsonNumberV1 $text)
       (let $length (str:length $text)
         (if (or (== $length 0) (> $length 20)) tg:bad
           (let $negative (str:starts-with $text "-")
             (let $start (if $negative 1 0)
               (if (== $start $length) tg:bad
                 (telegram:digits $text $start $length 0 $negative)))))))
      ($other tg:bad))))

(= (telegram:digits $text $pos $end $acc $negative)
   (if (== $pos $end)
     (tg:integer (if $negative $acc (- 0 $acc)))
     (let $digit (case (str:slice $text $pos (+ $pos 1))
                   (("0" 0) ("1" 1) ("2" 2) ("3" 3) ("4" 4)
                    ("5" 5) ("6" 6) ("7" 7) ("8" 8) ("9" 9) ($bad -1)))
       (if (or (< $digit 0)
               (or (< $acc -922337203685477580)
                   (and (== $acc -922337203685477580) (> $digit (if $negative 8 7)))))
         tg:bad
         (telegram:digits $text (+ $pos 1) $end (- (* $acc 10) $digit) $negative)))))

(= (telegram:cons-ok $head $tail)
   (case $tail
     (((tg:ok $items) (tg:ok (cons-atom $head $items)))
      ($bad tg:bad))))

; Normalize provider objects for deduplication: reject duplicate keys, sort
; keys independently of their values, renumber members and erase source spans.
; Arrays, Unicode scalars and number lexemes retain their meanings and order.
(= (telegram:normalize $value $depth)
   (if (> $depth 64) tg:bad
     (case $value
       (((JsonObjectV1 $members)
         (if (> (size-atom $members) 256) tg:bad
           (let $keys (telegram:member-keys $members)
             (let $unique (unique-atom $keys)
              (if (not (== (size-atom $keys) (size-atom $unique))) tg:bad
               (case (telegram:object-members $members (sort-atom $keys) 0 (+ $depth 1))
                 (((tg:ok $normalized) (tg:ok (JsonObjectV1 $normalized)))
                  ($bad tg:bad))))))))
        ((JsonArrayV1 $items)
         (if (> (size-atom $items) 4096) tg:bad
           (case (telegram:normalize-list $items (+ $depth 1))
             (((tg:ok $normalized) (tg:ok (JsonArrayV1 $normalized)))
              ($bad tg:bad)))))
        ((JsonStringV1 $scalars) (tg:ok $value))
        ((JsonNumberV1 $lexeme) (tg:ok $value))
        ((JsonBoolV1 $truth) (tg:ok $value))
        (JsonNullV1 (tg:ok JsonNullV1))
        ($other tg:bad)))))

(= (telegram:normalize-list $items $depth)
   (if (== $items ()) (tg:ok ())
     (let ($head $tail) (decons-atom $items)
       (case (telegram:normalize $head $depth)
         (((tg:ok $value) (telegram:cons-ok $value (telegram:normalize-list $tail $depth)))
          ($bad tg:bad))))))

(= (telegram:member-keys $members)
   (if (== $members ()) ()
     (let ((JsonMemberV1 $i $key $v $span) $rest) (decons-atom $members)
       (let $tail (telegram:member-keys $rest) (cons-atom $key $tail)))))

(= (telegram:member $key $members)
   (if (== $members ()) tg:bad
     (let ((JsonMemberV1 $i $name $value $span) $rest) (decons-atom $members)
       (if (== $key $name) (tg:some $value) (telegram:member $key $rest)))))

(= (telegram:object-members $members $keys $index $depth)
   (if (== $keys ()) (tg:ok ())
     (let ($key $tail) (decons-atom $keys)
       (case (telegram:member $key $members)
         (((tg:some $value)
           (case (telegram:normalize $value $depth)
             (((tg:ok $normalized)
               (telegram:cons-ok (JsonMemberV1 $index $key $normalized JsonNoSourceSpanV1)
                 (telegram:object-members $members $tail (+ $index 1) $depth)))
              ($bad tg:bad))))
          ($bad tg:bad))))))

(= (telegram:contains $value $items)
   (if (== $items ()) False
     (let ($head $tail) (decons-atom $items)
       (if (== $value $head) True (telegram:contains $value $tail)))))

(= (telegram:kind $update $names)
   (if (== $names ()) tg:none
     (let ($head $tail) (decons-atom $names)
       (case (telegram:field $update $head)
         (((tg:some $value) (tg:kind $head $value))
          (tg:none (telegram:kind $update $tail))
          ($bad tg:bad))))))

(= (telegram:optional-id $object $key $default)
   (case (telegram:field $object $key)
     ((tg:none (tg:integer $default))
      ((tg:some $value) (telegram:integer $value))
      ($bad tg:bad))))

(= (telegram:sender $message)
   (case (telegram:field $message "from")
     ((tg:none (tg:integer 0))
      ((tg:some $sender)
       (case (telegram:field $sender "id")
         (((tg:some $id) (telegram:integer $id)) ($bad tg:bad))))
      ($bad tg:bad))))

(= (telegram:route $id $kind $message $sender $update $policy)
   (case ($policy (telegram:field $message "chat") (telegram:optional-id $message "message_thread_id" 0) $sender)
     ((((telegram:policy 1 $chats $private $operators $peers) (tg:some $chat) (tg:integer $thread) (tg:integer $from))
       (case ((telegram:field $chat "id") (telegram:field $chat "type"))
         ((((tg:some $chat-number) (tg:some (JsonStringV1 $type)))
           (case (telegram:integer $chat-number)
             (((tg:integer $chat-id)
               (if (or (== $chat-id 0) (or (< $thread 0) (< $from 0))) tg:bad
                 (let $allowed (or (telegram:contains $chat-id $chats)
                                  (and $private (== $type ((cp 112) (cp 114) (cp 105) (cp 118) (cp 97) (cp 116) (cp 101)))))
                   (let $role (if (and (> $from 0) (telegram:contains $from $operators)) operator
                                (if (and (> $from 0) (telegram:contains $from $peers)) wake-peer ordinary))
                     (tg:item $id (format-args "{}.{}" ($chat-id $thread))
                       (if $allowed routed unauthorized)
                       (telegram:input 1 $kind $chat-id $thread $from $role $update))))))
              ($bad tg:bad))))
          ($bad tg:bad))))
      ($bad tg:bad))))

(= (telegram:update $update $policy)
   (case $update
     (((JsonObjectV1 $members)
       (if (or (< (size-atom $members) 1) (> (size-atom $members) 2)) tg:bad
         (case (telegram:field $update "update_id")
           (((tg:some $number)
             (case (telegram:integer $number)
               (((tg:integer $id)
                 (if (or (< $id 0) (>= $id 9223372036854775807)) tg:bad
                   (case (telegram:kind $update ("message" "edited_message" "channel_post" "edited_channel_post" "callback_query"))
                     (((tg:kind "callback_query" $callback)
                       (case (telegram:field $callback "message")
                         (((tg:some $message)
                           (telegram:route $id "callback_query" $message (telegram:sender $callback) $update $policy))
                          (tg:none (tg:item $id "unsupported" unsupported $update))
                          ($bad tg:bad))))
                      ((tg:kind $kind $message) (telegram:route $id $kind $message (telegram:sender $message) $update $policy))
                      (tg:none (tg:item $id "unsupported" unsupported $update))
                      ($bad tg:bad)))))
                ($bad tg:bad))))
            ($bad tg:bad)))))
      ($bad tg:bad))))

(= (telegram:updates $items $policy)
   (if (== $items ()) (tg:ok ())
     (let ($head $tail) (decons-atom $items)
       (case (telegram:update $head $policy)
         (((tg:item $id $lane $disposition $value)
           (telegram:cons-ok (tg:item $id $lane $disposition $value) (telegram:updates $tail $policy)))
          ($bad tg:bad))))))

(= (telegram:decode $body $policy)
   (if (> (str:length $body) 262144) (telegram:hold 1 body-limit)
     (case (json:parse $body)
       (((JsonFailureV1 $phase JsonResourceLimitV1 $source $detail) (telegram:hold 1 parser-limit))
        ($parsed (telegram:decode-value $parsed $policy))))))

; Only the native intake ticket supplies this screened, durably recorded
; envelope. HTTP success alone does not imply a successful Bot API result.
(= (telegram:poll $observation $policy)
   (case $observation
     (((host:poll 1 $source $offset observed (True False 0 200 $known $bytes False False False) $body)
       (telegram:decode $body $policy))
      ((host:poll 1 $source $offset observed (True False 0 429 $known $bytes False False False) $body)
       (case (telegram:decode $body $policy)
         (((telegram:retry 1 $seconds rate-limit) (telegram:retry 1 $seconds rate-limit))
          ($bad (telegram:hold 1 invalid-retry-delay)))))
      ((host:poll 1 $source $offset observed (True False 0 409 $known $bytes False False False) $body)
       (telegram:hold 1 conflicting-poller))
      ($other (telegram:hold 1 transport-outcome)))))

(= (telegram:decode-value $parsed $policy)
     (case (telegram:normalize $parsed 0)
       (((tg:ok $response)
         (case (telegram:field $response "ok")
           (((tg:some (JsonBoolV1 True))
             (case (telegram:field $response "result")
               (((tg:some (JsonArrayV1 $updates))
                 (if (> (size-atom $updates) 100) (telegram:hold 1 batch-limit)
                   (case (telegram:updates $updates $policy)
                     (((tg:ok $items) (telegram:batch 1 $items))
                      ($bad (telegram:hold 1 malformed-update))))))
                ($bad (telegram:hold 1 malformed-response)))))
            ((tg:some (JsonBoolV1 False)) (telegram:api-error $response))
            ($bad (telegram:hold 1 malformed-response)))))
        ($bad (telegram:hold 1 malformed-json)))))

(= (telegram:api-error $response)
   (case (telegram:field $response "error_code")
     (((tg:some (JsonNumberV1 "429"))
       (case (telegram:field $response "parameters")
         (((tg:some $parameters)
           (case (telegram:field $parameters "retry_after")
             (((tg:some $delay)
               (case (telegram:integer $delay)
                 (((tg:integer $seconds)
                   (if (and (> $seconds 0) (<= $seconds 86400))
                     (telegram:retry 1 $seconds rate-limit) (telegram:hold 1 invalid-retry-delay)))
                  ($bad (telegram:hold 1 invalid-retry-delay)))))
              ($bad (telegram:hold 1 invalid-retry-delay)))))
          ($bad (telegram:hold 1 invalid-retry-delay)))))
      ((tg:some (JsonNumberV1 "409")) (telegram:hold 1 conflicting-poller))
      ($other (telegram:hold 1 api-error)))))
