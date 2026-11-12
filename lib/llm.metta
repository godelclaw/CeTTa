; Versioned, buffered LLM protocol kernel. No credentials, retries, history or
; tool execution belong here. Native HTTP and JSON remain separate libraries.
; Pure operations answer (llm:v1:ok VALUE) or (llm:v1:error CODE).
!(import! &self json)
!(import! &self str)
!(import! &self io)

; Normalize one buffered Chat Completions or Anthropic response body. A JSON
; object body passes through; an SSE body needs its protocol terminator.
; Text/tool fragments are provisional until the whole operation succeeds.
; max-bytes bounds the UTF-8 input; no partial body is returned on refusal.
(: __cetta_lib_llm_response_body (-> Atom Atom Atom Atom Atom))
(: llm:v1:response-body (-> %Undefined% %Undefined% %Undefined% %Undefined% Atom))
(= (llm:v1:response-body $protocol $stream $body $max-bytes)
   (function (chain (eval (__cetta_lib_llm_response_body $protocol $stream $body $max-bytes)) $result
     (return $result))))

; Internal JSON values are held data. Explicit lets compute intermediate calls.
; The occurrence-preserving parser rejects duplicate keys before conversion to
; the historical JSON vocabulary used by these pure codecs.
(: llm:v1:object-get (-> Atom Atom Atom))
(= (llm:v1:object-get $object $key)
   (function (chain (eval (__cetta_lib_json_object_get $object $key)) $result
     (return $result))))
(= (llm:v1:get $object $key)
   (case $object (((llm:v1:failure $code) (llm:v1:failure $code))
     ((JsonObject $pairs) (llm:v1:object-get $object $key)) ($other JsonNull))))
(: llm:v1:render-json (-> Atom Atom))
(= (llm:v1:render-json $value)
   (function (chain (eval (__cetta_lib_json_stringify $value)) $result
     (return $result))))
(: llm:v1:render (-> Atom %Undefined%))
(= (llm:v1:render $value)
   (case $value (((llm:v1:failure $code) (llm:v1:failure $code))
     ($other (llm:v1:render-json $value)))))
(: llm:v1:render-outcome (-> Atom %Undefined%))
(= (llm:v1:render-outcome $value)
   (function
     (case (llm:v1:render $value)
       (((llm:v1:failure $code) (return (llm:v1:error $code)))
        ((Error $source $reason) (return (llm:v1:error result-render-error)))
        ((JsonFailureV1 $phase $status $source $reason) (return (llm:v1:error result-render-error)))
        ($text (return (llm:v1:ok $text)))))))

(= (llm:v1:member? $value $items)
   (if (== $items ()) False
     (if (== $value (car-atom $items)) True
       (let $tail (cdr-atom $items) (llm:v1:member? $value $tail)))))
(= (llm:v1:unique-list? $items)
   (if (== $items ()) True
     (let* (($head (car-atom $items)) ($tail (cdr-atom $items))
            ($ok (llm:v1:unique? $head)))
       (if $ok (llm:v1:unique-list? $tail) False))))
(= (llm:v1:unique-members? $members $seen)
   (if (== $members ()) True
     (case (car-atom $members)
       (((JsonMemberV1 $index $key $value $span)
          (let* (($duplicate (llm:v1:member? $key $seen))
                 ($nested (llm:v1:unique? $value))
                 ($tail (cdr-atom $members)) ($next (cons-atom $key $seen)))
            (if (or $duplicate (not $nested)) False
              (llm:v1:unique-members? $tail $next))))
        ($other False)))))
(= (llm:v1:unique? $value)
   (case $value
     (((JsonObjectV1 $members) (llm:v1:unique-members? $members ()))
      ((JsonArrayV1 $items) (llm:v1:unique-list? $items))
      ((JsonFailureV1 $a $b $c $d) False)
      ($scalar True))))
(: llm:v1:historical (-> Atom Atom))
(= (llm:v1:historical $value)
   (function (chain (eval (__cetta_lib_json_to_legacy_v1 $value)) $result
     (return $result))))
(: llm:v1:parsed (-> Atom %Undefined%))
(= (llm:v1:parsed $value)
   (case $value
     (((JsonFailureV1 $phase JsonResourceLimitV1 $call $diagnostic)
       (llm:v1:failure protocol-resource-limit))
      ((JsonFailureV1 $other-phase $other-status $other-call $other-diagnostic)
       (llm:v1:failure invalid-or-ambiguous-json))
      ($converted $converted))))
; A model response is parsed straight to a legacy value whose objects repeat
; no key; a repeated key fails like any other ambiguous response.
(: llm:v1:unique-legacy (-> Atom Atom))
(= (llm:v1:unique-legacy $text)
   (function (chain (eval (__cetta_lib_json_parse $text JsonUniqueKeysV1)) $result
     (return $result))))
(= (llm:v1:parse $text)
   (let $value (llm:v1:unique-legacy $text) (llm:v1:parsed $value)))
(= (llm:v1:object? $value)
   (case $value (((JsonObject $pairs) True) ($other False))))
(= (llm:v1:array $value)
   (case $value (((llm:v1:failure $code) (llm:v1:failure $code))
     ((JsonArray $items) $items) ($other (llm:v1:failure expected-array)))))
(= (llm:v1:text $value)
   (case $value (((llm:v1:failure $code) (llm:v1:failure $code))
     ((JsonString $text) $text) ($other (llm:v1:failure expected-string)))))
(= (llm:v1:required $object $key)
   (let $value (llm:v1:get $object $key) (if (== $value JsonNull) (llm:v1:failure missing-field) $value)))
(: llm:v1:optional-object (-> Atom %Undefined%))
(= (llm:v1:optional-object $value)
   (if (or (== $value JsonNull) (llm:v1:object? $value)) True
     (llm:v1:failure expected-object)))
(: llm:v1:nonempty-text (-> Atom %Undefined%))
(= (llm:v1:nonempty-text $value)
   (let $text (llm:v1:text $value)
     (if (== $text "") (llm:v1:failure expected-nonempty-string) $text)))
(= (llm:v1:with $object $key $value)
   (case
     $object
     (((llm:v1:failure $code) (llm:v1:failure $code))
       ((JsonObject $pairs) (let $rest (llm:v1:without $pairs $key) (JsonObject (cons-atom (JsonPair $key $value) $rest))))
       ($other (llm:v1:failure expected-object)))))
(= (llm:v1:without $pairs $key)
   (if (== $pairs ()) ()
     (case (car-atom $pairs)
       (((JsonPair $name $value)
         (let* (($head (car-atom $pairs)) ($tail (cdr-atom $pairs)) ($rest (llm:v1:without $tail $key)))
           (if (== $name $key) $rest (cons-atom $head $rest))))))))
(= (llm:v1:append $first $second)
   (case $first
     (((llm:v1:failure $code) (llm:v1:failure $code))
      ($left (case $second
        (((llm:v1:failure $code) (llm:v1:failure $code))
         ($right (if (== $first ()) $second
           (let* (($head (car-atom $first)) ($tail (cdr-atom $first))
                  ($rest (llm:v1:append $tail $second))) (cons-atom $head $rest))))))))))
; A list whose rest failed is that failure: cons-atom onto it would splice the
; failure into the list as two plain atoms that no check finds. A failure
; inside the head is earlier, so it comes first.
(= (llm:v1:cons $head $rest)
   (case $rest
     (((llm:v1:failure $code)
       (let $earlier (llm:v1:failure-in $head)
         (case $earlier (((llm:v1:failure $first) (llm:v1:failure $first)) ($none (llm:v1:failure $code))))))
      ($list (cons-atom $head $list)))))
; Newest-first accumulation: items in order go onto a newest-first list, and
; a failure on either side stays the first failure, as llm:v1:append keeps it.
(= (llm:v1:prepend-reversed $items $out)
   (case $out
     (((llm:v1:failure $code) (llm:v1:failure $code))
      ($ready (case $items
        (((llm:v1:failure $code) (llm:v1:failure $code))
         ($list (llm:v1:reverse-onto $list $ready))))))))
(= (llm:v1:in-order $newest-first)
   (case $newest-first
     (((llm:v1:failure $code) (llm:v1:failure $code))
      ($list (llm:v1:reverse-onto $list ())))))
(= (llm:v1:count $value)
   (if
     (== $value JsonNull)
     JsonNull
     (case
       $value
       (((JsonNumber $text) (if (and (not (== $text "")) (str:is-all-in digit $text)) $value (llm:v1:failure invalid-usage)))
         ($other (llm:v1:failure invalid-usage))))))
(= (llm:v1:counter $object $key)
   (let $value (llm:v1:get $object $key) (llm:v1:count $value)))

; Missing counters stay null. Raw provider usage is retained without adding
; cache subtotals or inventing token counts.
(= (llm:v1:usage $protocol $wire)
   (let* (($raw (llm:v1:get $wire "usage"))
          ($input-key (if (== $protocol "chat-completions") "prompt_tokens" "input_tokens"))
          ($output-key (if (== $protocol "chat-completions") "completion_tokens" "output_tokens"))
          ($input (llm:v1:counter $raw $input-key))
          ($output (llm:v1:counter $raw $output-key))
          ($input-details-key (if (== $protocol "chat-completions") "prompt_tokens_details" "input_tokens_details"))
          ($output-details-key (if (== $protocol "chat-completions") "completion_tokens_details" "output_tokens_details"))
          ($input-details (llm:v1:get $raw $input-details-key))
          ($output-details (llm:v1:get $raw $output-details-key))
          ($cache (if (== $protocol "anthropic")
                    (llm:v1:counter $raw "cache_read_input_tokens")
                    (llm:v1:counter $input-details "cached_tokens")))
          ($write (if (== $protocol "anthropic")
                    (llm:v1:counter $raw "cache_creation_input_tokens") JsonNull))
          ($reasoning (llm:v1:counter $output-details "reasoning_tokens")))
     (let* (($raw-ok (llm:v1:optional-object $raw))
            ($input-ok (llm:v1:optional-object $input-details))
            ($output-ok (llm:v1:optional-object $output-details))
            ($result (JsonObject ((JsonPair "input" $input) (JsonPair "output" $output)
              (JsonPair "cache_read" $cache) (JsonPair "cache_write" $write)
              (JsonPair "reasoning" $reasoning) (JsonPair "native" $raw)))))
       (llm:v1:validated ($raw-ok $input-ok $output-ok) $result))))
(= (llm:v1:termination $normalized $raw $details)
   (JsonObject ((JsonPair "normalized" (JsonString $normalized))
     (JsonPair "raw" $raw) (JsonPair "details" $details))))
(= (llm:v1:finish $protocol $raw)
   (if
     (== $raw JsonNull)
     "unknown"
     (let
       $reason
       (llm:v1:text $raw)
       (if
         (== $protocol "anthropic")
         (case
           $reason
           (("max_tokens" "length")
             ("tool_use" "tool_calls")
             ("end_turn" "stop")
             ("stop_sequence" "stop")
             ($other "unknown")))
         (case
           $reason
           (("stop" "stop")
             ("tool_calls" "tool_calls")
             ("length" "length")
             ("content_filter" "refusal")
             ($other-1 "unknown")))))))
(= (llm:v1:version $protocol)
   (case
     $protocol
     (("anthropic" "2023-06-01")
       ("chat-completions" "chat-completions-v1")
       ("responses" "responses-v1")
       ($other (llm:v1:failure unsupported-protocol)))))
(= (llm:v1:part $kind $native)
   (JsonObject ((JsonPair "kind" (JsonString $kind)) (JsonPair "native" $native))))
(= (llm:v1:text-part $kind $text $native)
   (let
     $ignored1
     (llm:v1:text $text)
     (let
       $validated-output-2
       (JsonObject
         ((JsonPair "kind" (JsonString $kind)) (JsonPair "text" $text) (JsonPair "native" $native)))
       (llm:v1:validated ($ignored1) $validated-output-2))))
(= (llm:v1:call-part $id $name $arguments $status $native)
   (let* (($call-id (llm:v1:text $id))
           ($call-name (llm:v1:text $name))
           ($bytes (llm:v1:text $arguments))
           ($ignored2
             (if (or (== $call-id "") (== $call-name "")) (llm:v1:failure invalid-call-identity) True))
           ($ignored3
             (if
               (== $status "completed")
               (let
                 $parsed
                 (llm:v1:parse $bytes)
                 (if (llm:v1:object? $parsed) True (llm:v1:failure invalid-tool-arguments)))
               True)))
     (let
       $validated-output-3
       (JsonObject
         ((JsonPair "kind" (JsonString "tool-call"))
           (JsonPair "call_id" $id)
           (JsonPair "name" $name)
           (JsonPair "arguments" $arguments)
           (JsonPair "status" (JsonString $status))
           (JsonPair "execution_owner" (JsonString "caller"))
           (JsonPair "native" $native)))
       (llm:v1:validated ($ignored2 $ignored3) $validated-output-3))))
(= (llm:v1:blocks $protocol $blocks $status)
   (if (== $blocks ()) ()
     (let* (($head (car-atom $blocks)) ($tail (cdr-atom $blocks))
            ($part (llm:v1:block $protocol $head $status))
            ($rest (llm:v1:blocks $protocol $tail $status))) (llm:v1:cons $part $rest))))
(= (llm:v1:block $protocol $block $status)
   (let* (($type (llm:v1:required $block "type"))
           ($kind (llm:v1:text $type)))
     (case
       $kind
       (("text" (let $text (llm:v1:required $block "text") (llm:v1:text-part "text" $text $block)))
         ("output_text"
           (let $text-7 (llm:v1:required $block "text") (llm:v1:text-part "text" $text-7 $block)))
         ("refusal"
           (let $text-8 (llm:v1:required $block "refusal") (llm:v1:text-part "refusal" $text-8 $block)))
         ("thinking"
           (let* (($text-9 (llm:v1:required $block "thinking"))
                   ($signature (llm:v1:required $block "signature"))
                   ($ignored4 (llm:v1:text $text-9))
                   ($ignored5 (llm:v1:text $signature)))
             (let
               $validated-output-4
               (llm:v1:part "reasoning" $block)
               (llm:v1:validated ($ignored4 $ignored5) $validated-output-4))))
         ("redacted_thinking"
           (let
             $data
             (llm:v1:required $block "data")
             (let
               $ignored6
               (llm:v1:text $data)
               (let
                 $validated-output-5
                 (llm:v1:part "reasoning" $block)
                 (llm:v1:validated ($ignored6) $validated-output-5)))))
         ("tool_use"
           (let* (($id (llm:v1:required $block "id"))
                   ($name (llm:v1:required $block "name"))
                   ($input (llm:v1:required $block "input"))
                   ($ignored7 (if (llm:v1:object? $input) True (llm:v1:failure invalid-tool-arguments)))
                   ($arguments (llm:v1:render $input))
                   ($args (JsonString $arguments)))
             (let
               $validated-output-6
               (llm:v1:call-part $id $name $args $status $block)
               (llm:v1:validated ($ignored7) $validated-output-6))))
         ($unknown (llm:v1:part "opaque" $block))))))
(= (llm:v1:message-item $role $parts $native)
   (let
     $ignored8
     (llm:v1:text $role)
     (let
       $validated-output-10
       (JsonObject
         ((JsonPair "kind" (JsonString "message"))
           (JsonPair "role" $role)
           (JsonPair "parts" (JsonArray $parts))
           (JsonPair "native" $native)))
       (llm:v1:validated ($ignored8) $validated-output-10))))
(= (llm:v1:anthropic-items $wire)
   (let* (($content (llm:v1:required $wire "content")) ($blocks (llm:v1:array $content))
          ($stop (llm:v1:get $wire "stop_reason")) ($finish (llm:v1:finish "anthropic" $stop))
          ($status (if (== $finish "length") "incomplete" "completed"))
          ($parts (llm:v1:blocks "anthropic" $blocks $status))
          ($item (llm:v1:message-item (JsonString "assistant") $parts $wire))) (cons-atom $item ())))
(= (llm:v1:responses-items $items $default-status)
   (if (== $items ()) ()
     (let* (($head (car-atom $items)) ($tail (cdr-atom $items))
            ($item (llm:v1:response-item $head $default-status))
            ($rest (llm:v1:responses-items $tail $default-status)))
       (llm:v1:cons $item $rest))))
(= (llm:v1:response-item $item $default-status)
   (let* (($type (llm:v1:required $item "type")) ($kind (llm:v1:text $type)))
     (case $kind
       (("message" (let* (($role (llm:v1:required $item "role"))
           ($content (llm:v1:required $item "content")) ($blocks (llm:v1:array $content))
           ($parts (llm:v1:blocks "responses" $blocks "completed")))
           (llm:v1:message-item $role $parts $item)))
        ("reasoning" (llm:v1:part "reasoning" $item))
        ("function_call" (let* (($id (llm:v1:required $item "call_id"))
           ($name (llm:v1:required $item "name")) ($args (llm:v1:required $item "arguments"))
           ($raw-status (llm:v1:get $item "status"))
           ($status (if (== $raw-status JsonNull) $default-status (llm:v1:text $raw-status))))
           (llm:v1:call-part $id $name $args $status $item)))
        ($unknown (llm:v1:part "opaque" $item))))))
(= (llm:v1:chat-calls $calls $status)
   (if
     (== $calls ())
     ()
     (let* (($call (car-atom $calls))
             ($tail (cdr-atom $calls))
             ($type (llm:v1:required $call "type"))
             ($ignored9
               (if (== $type (JsonString "function")) True (llm:v1:failure unsupported-tool-kind)))
             ($function (llm:v1:required $call "function"))
             ($id (llm:v1:required $call "id"))
             ($name (llm:v1:required $function "name"))
             ($args (llm:v1:required $function "arguments"))
             ($part (llm:v1:call-part $id $name $args $status $call))
             ($rest (llm:v1:chat-calls $tail $status)))
       (let
         $validated-output-11
         (llm:v1:cons $part $rest)
         (llm:v1:validated ($ignored9) $validated-output-11)))))
(= (llm:v1:optional-array $value)
   (if (== $value JsonNull) () (llm:v1:array $value)))
(= (llm:v1:chat-choice $choice)
   (let* (($message (llm:v1:required $choice "message"))
           ($role (llm:v1:required $message "role"))
           ($ignored10
             (if (== $role (JsonString "assistant")) True (llm:v1:failure invalid-response-role)))
           ($content (llm:v1:get $message "content"))
           ($text
             (if
               (== $content JsonNull)
               ()
               (case
                 $content
                 (((JsonString $s) (let $part (llm:v1:text-part "text" $content $content) (cons-atom $part ())))
                   ((JsonArray $blocks) (llm:v1:blocks "chat-completions" $blocks "completed"))
                   ($bad (llm:v1:failure invalid-content))))))
           ($raw (llm:v1:get $choice "finish_reason"))
           ($finish (llm:v1:finish "chat-completions" $raw))
           ($status (if (== $finish "length") "incomplete" "completed"))
           ($raw-calls (llm:v1:get $message "tool_calls"))
           ($calls (llm:v1:optional-array $raw-calls))
           ($tools (llm:v1:chat-calls $calls $status))
           ($parts (llm:v1:append $text $tools))
           ($refusal (llm:v1:get $message "refusal"))
           ($complete-parts
             (if
               (== $refusal JsonNull)
               $parts
               (let* (($p (llm:v1:text-part "refusal" $refusal $refusal))
                       ($ps (cons-atom $p ())))
                 (llm:v1:append $parts $ps))))
           ($item (llm:v1:message-item $role $complete-parts $message))
           ($index (llm:v1:get $choice "index"))
           ($indexed-item (llm:v1:with $item "choice_index" $index))
           ($termination (llm:v1:termination $finish $raw JsonNull)))
     (let
       $validated-output-12
       (llm:v1:with $indexed-item "termination" $termination)
       (llm:v1:validated ($ignored10) $validated-output-12))))
(= (llm:v1:chat-choices $choices)
   (if (== $choices ()) ()
     (let* (($head (car-atom $choices)) ($tail (cdr-atom $choices))
            ($item (llm:v1:chat-choice $head)) ($rest (llm:v1:chat-choices $tail)))
       (llm:v1:cons $item $rest))))
(= (llm:v1:decoded $protocol $wire)
   (let* (($version (llm:v1:version $protocol))
           ($ignored11 (if (llm:v1:object? $wire) True (llm:v1:failure expected-object)))
           ($items
             (case
               $protocol
               (("anthropic" (llm:v1:anthropic-items $wire))
                 ("responses"
                   (let* (($output (llm:v1:required $wire "output"))
                           ($xs (llm:v1:array $output))
                           ($status (llm:v1:get $wire "status"))
                           ($default-status
                             (if (== $status (JsonString "completed")) "completed" "incomplete")))
                     (llm:v1:responses-items $xs $default-status)))
                 ("chat-completions"
                   (let* (($choices (llm:v1:required $wire "choices"))
                           ($xs-14 (llm:v1:array $choices)))
                     (llm:v1:chat-choices $xs-14))))))
           ($stop-key (if (== $protocol "anthropic") "stop_reason" "status"))
           ($raw (llm:v1:get $wire $stop-key))
           ($details (llm:v1:get $wire "incomplete_details"))
           ($reason (llm:v1:get $details "reason"))
           ($finish
             (if
               (== $protocol "responses")
               (if
                 (== $raw (JsonString "completed"))
                 "stop"
                 (if
                   (and
                     (== $raw (JsonString "incomplete"))
                     (== $reason (JsonString "max_output_tokens")))
                   "length"
                   (if (== $raw (JsonString "failed")) "failure" "unknown")))
               (if (== $protocol "anthropic") (llm:v1:finish $protocol $raw) "per-choice")))
           ($termination (llm:v1:termination $finish $raw $details))
           ($usage (llm:v1:usage $protocol $wire))
           ($id (llm:v1:get $wire "id"))
           ($valid-id (if (== $id JsonNull) True (llm:v1:nonempty-text $id))))
     (let
       $validated-output-13
       (JsonObject
         ((JsonPair "schema" (JsonString "llm-result-v1"))
           (JsonPair "protocol" (JsonString $protocol))
           (JsonPair "protocol_version" (JsonString $version))
           (JsonPair "response_id" $id)
           (JsonPair "items" (JsonArray $items))
           (JsonPair "termination" $termination)
           (JsonPair "usage" $usage)
           (JsonPair "native" $wire)))
       (llm:v1:validated ($version $ignored11 $valid-id) $validated-output-13))))
(= (llm:v1:outcome $result)
   (case
     $result
     (((llm:v1:failure $code) (llm:v1:error $code))
       ((Error $source $reason) (llm:v1:error invalid-protocol-data))
       ($value (llm:v1:ok $value)))))
(= (llm:v1:decode $protocol $text)
   (function
     (case
       (let* (($name (llm:v1:protocol $protocol))
               ($wire (llm:v1:parse $text))
               ($result-15 (llm:v1:decode-parsed $name $wire)))
         (llm:v1:checked $result-15))
       (((llm:v1:failure $code) (return (llm:v1:error $code)))
         ((Error $source $reason) (return (llm:v1:error invalid-protocol-data)))
         ($result (return (llm:v1:ok $result)))))))

; Request codecs consume a JSON conversation envelope. The default preserves
; system/developer roles. Anthropic's developer mapping and legacy forced-tool
; downgrade require explicit caller policies; they are never inferred.
(= (llm:v1:text-blocks $content)
   (if
     (or (== $content JsonNull) (== $content (JsonString "")))
     ()
     (case
       $content
       (((JsonString $text) ((JsonObject ((JsonPair "type" (JsonString "text")) (JsonPair "text" $content)))))
         ((JsonArray $blocks) (llm:v1:checked-text-blocks $blocks))
         ($other (llm:v1:failure unsupported-content))))))
(= (llm:v1:checked-text-blocks $blocks)
   (if
     (== $blocks ())
     ()
     (let* (($head (car-atom $blocks))
             ($tail (cdr-atom $blocks))
             ($kind (llm:v1:required $head "type"))
             ($text (llm:v1:required $head "text"))
             ($ignored (llm:v1:text $text))
             ($rest (llm:v1:checked-text-blocks $tail)))
       (let
         $validated-output-16
         (if (== $kind (JsonString "text")) (llm:v1:cons $head $rest) (llm:v1:failure unsupported-content))
         (llm:v1:validated ($ignored) $validated-output-16)))))
(= (llm:v1:attachment $protocol $value)
   (let* (($source (llm:v1:required $value "protocol"))
           ($version (llm:v1:required $value "protocol_version"))
           ($expected (llm:v1:version $protocol))
           ($native (llm:v1:required $value "value")))
     (let
       $validated-output-17
       (if
         (and (== $source (JsonString $protocol)) (== $version (JsonString $expected)))
         $native
         (llm:v1:failure incompatible-native-attachment))
       (llm:v1:validated ($version) $validated-output-17))))
(= (llm:v1:request-calls $protocol $calls)
   (if
     (== $calls ())
     ()
     (let* (($head (car-atom $calls))
             ($tail (cdr-atom $calls))
             ($function (llm:v1:required $head "function"))
             ($id (llm:v1:required $head "id"))
             ($name (llm:v1:required $function "name"))
             ($args (llm:v1:required $function "arguments"))
             ($checked (llm:v1:call-part $id $name $args "completed" $head))
             ($bytes (llm:v1:text $args))
             ($input (llm:v1:parse $bytes))
             ($item
               (if
                 (== $protocol "anthropic")
                 (JsonObject
                   ((JsonPair "type" (JsonString "tool_use"))
                     (JsonPair "id" $id)
                     (JsonPair "name" $name)
                     (JsonPair "input" $input)))
                 (JsonObject
                   ((JsonPair "type" (JsonString "function_call"))
                     (JsonPair "call_id" $id)
                     (JsonPair "name" $name)
                     (JsonPair "arguments" $args)))))
             ($rest (llm:v1:request-calls $protocol $tail)))
       (let
         $validated-output-18
         (llm:v1:cons $item $rest)
         (llm:v1:validated ($checked) $validated-output-18)))))
(= (llm:v1:reasoning $protocol $blocks)
   (if
     (== $blocks ())
     ()
     (let* (($head (car-atom $blocks))
             ($tail (cdr-atom $blocks))
             ($type (llm:v1:required $head "type"))
             ($accepted
               (if
                 (== $protocol "anthropic")
                 (or (== $type (JsonString "thinking")) (== $type (JsonString "redacted_thinking")))
                 (== $type (JsonString "reasoning"))))
             ($rest (llm:v1:reasoning $protocol $tail)))
       (if $accepted (llm:v1:cons $head $rest) (llm:v1:failure incompatible-reasoning)))))
(= (llm:v1:anthropic-message $message)
   (let* (($raw-role (llm:v1:required $message "role"))
           ($role (llm:v1:text $raw-role))
           ($content (llm:v1:get $message "content"))
           ($attachment (llm:v1:get $message "native_content")))
     (case
       $role
       (("tool" (let* (($id (llm:v1:required $message "tool_call_id")) ($checked (llm:v1:text $id)) ($block (JsonObject ((JsonPair "type" (JsonString "tool_result")) (JsonPair "tool_use_id" $id) (JsonPair "content" $content))))) (let $validated-output-19 (JsonObject ((JsonPair "role" (JsonString "user")) (JsonPair "content" (JsonArray (cons-atom $block ()))))) (llm:v1:validated ($checked) $validated-output-19))))
         ($ordinary
           (if
             (or (== $role "user") (== $role "assistant"))
             (let* (($text
                       (if
                         (== $attachment JsonNull)
                         (llm:v1:text-blocks $content)
                         (let
                           $value
                           (llm:v1:attachment "anthropic" $attachment)
                           (let
                             $validated-output-20
                             (llm:v1:array $value)
                             (llm:v1:validated ($value) $validated-output-20)))))
                     ($reasoning-json (llm:v1:get $message "reasoning_details"))
                     ($reasoning-list (llm:v1:optional-array $reasoning-json))
                     ($reasoning (llm:v1:reasoning "anthropic" $reasoning-list))
                     ($calls-json (llm:v1:get $message "tool_calls"))
                     ($calls (llm:v1:optional-array $calls-json))
                     ($ignored
                       (if
                         (or (== $role "assistant") (and (== $calls ()) (== $reasoning ())))
                         True
                         (llm:v1:failure invalid-message-role)))
                     ($tools (llm:v1:request-calls "anthropic" $calls))
                     ($first (llm:v1:append $reasoning $text))
                     ($blocks (llm:v1:append $first $tools)))
               (let
                 $validated-output-21
                 (if
                   (and
                     (not (== $attachment JsonNull))
                     (or (not (== $reasoning ())) (not (== $calls ()))))
                   (llm:v1:failure ambiguous-native-content)
                   (JsonObject ((JsonPair "role" $raw-role) (JsonPair "content" (JsonArray $blocks)))))
                 (llm:v1:validated ($ignored) $validated-output-21)))
             (llm:v1:failure unsupported-message-role)))))))
; The conversation is built newest first and put in order once, so a message
; costs its own size, however long the conversation. $turns holds finished
; turns newest first. $open is the turn adjacent messages of its role still
; join: (llm:v1:turn FIRST BLOCKS JOINED RESULTS-ONLY), BLOCKS newest first
; (or the turn's first failure), JOINED once a second message has joined it,
; and RESULTS-ONLY while every block is a tool result. A failed message is a
; finished turn of its own, so the first failure in message order is the one
; the wire check finds.
(= (llm:v1:anthropic-conversation $messages $role-policy $system $conversation)
   (llm:v1:anthropic-turns $messages $role-policy $system $conversation ()))
(= (llm:v1:anthropic-turns $messages $role-policy $system $turns $open)
   (if
     (== $messages ())
     (let* (($closed (llm:v1:close-turn $open $turns))
             ($instructions (llm:v1:in-order $system))
             ($conversation (llm:v1:reverse-onto $closed ())))
       (llm:v1:conversation $instructions $conversation))
     (let* (($head (car-atom $messages))
             ($tail (cdr-atom $messages))
             ($raw-role (llm:v1:required $head "role"))
             ($role (llm:v1:text $raw-role)))
       (if
         (or (== $role "system") (== $role "developer"))
         (let
           $refusal
           (llm:v1:instruction-refusal $role $role-policy $turns $open)
           (case
             $refusal
             (((llm:v1:failure $code) (llm:v1:refused-conversation $code $system $turns $open))
               ($admitted
                 (let* (($content (llm:v1:get $head "content"))
                         ($blocks (llm:v1:text-blocks $content))
                         ($next (llm:v1:prepend-reversed $blocks $system)))
                   (llm:v1:anthropic-turns $tail $role-policy $next $turns $open))))))
         (let* (($message (llm:v1:anthropic-message $head))
                 ($joined (llm:v1:join-turn $open $message)))
           (case
             $joined
             (((llm:v1:joined $next-open)
                (llm:v1:anthropic-turns $tail $role-policy $system $turns $next-open))
               ($separate
                 (let* (($next-turns (llm:v1:close-turn $open $turns))
                         ($opened (llm:v1:open-turn $message)))
                   (llm:v1:anthropic-turns $tail $role-policy $system $next-turns $opened))))))))))
(= (llm:v1:instruction-refusal $role $role-policy $turns $open)
   (if
     (not (and (== $turns ()) (== $open ())))
     (llm:v1:failure late-system-instructions)
     (if
       (and (== $role "developer") (not (== $role-policy (JsonString "merge-system-developer"))))
       (llm:v1:failure unsupported-developer-role)
       True)))
; A refused instruction is the outcome unless an earlier message failed: the
; conversation so far then carries that earlier failure to the wire check.
(= (llm:v1:refused-conversation $code $system $turns $open)
   (let* (($closed (llm:v1:close-turn $open $turns))
           ($earlier (llm:v1:failure-in ($system $closed))))
     (case
       $earlier
       (((llm:v1:failure $first)
          (let* (($instructions (llm:v1:in-order $system))
                  ($conversation (llm:v1:reverse-onto $closed ())))
            (llm:v1:conversation $instructions $conversation)))
         ($none (llm:v1:failure $code))))))
(= (llm:v1:open-turn $message)
   (case
     $message
     (((llm:v1:failure $code) (llm:v1:failure $code))
       ($object
         (let* (($content (llm:v1:get $message "content"))
                 ($blocks (llm:v1:array $content))
                 ($results-only (llm:v1:tool-results? $blocks))
                 ($newest-first (llm:v1:prepend-reversed $blocks ())))
           (llm:v1:turn $message $newest-first False $results-only))))))
; Merge only adjacent equal roles; a new tool result cannot follow user text.
; Once the turn holds a failure, that earlier failure is kept.
(= (llm:v1:join-turn $open $message)
   (case
     $open
     (((llm:v1:turn $first $blocks $joined $results-only)
        (let* (($old-role (llm:v1:get $first "role"))
                ($new-role (llm:v1:get $message "role")))
          (if
            (== $old-role $new-role)
            (let* (($content (llm:v1:get $message "content"))
                    ($new (llm:v1:array $content))
                    ($late (llm:v1:late-tool-result? $new-role $new $blocks $results-only))
                    ($next (llm:v1:prepend-reversed $new $blocks))
                    ($next-results-only (if $results-only (llm:v1:tool-results? $new) False)))
              (if
                $late
                (llm:v1:joined (llm:v1:failure late-tool-result))
                (llm:v1:joined (llm:v1:turn $first $next True $next-results-only))))
            separate)))
       ($none separate))))
(= (llm:v1:late-tool-result? $role $new $blocks $results-only)
   (if
     (== $role (JsonString "user"))
     (case
       $new
       (((llm:v1:failure $code) False)
         ($list
           (if
             (== $list ())
             False
             (let* (($first (car-atom $list))
                     ($kind (llm:v1:get $first "type")))
               (if
                 (== $kind (JsonString "tool_result"))
                 (case $blocks (((llm:v1:failure $earlier) False) ($ready (not $results-only))))
                 False))))))
     False))
(= (llm:v1:tool-results? $blocks)
   (case
     $blocks
     (((llm:v1:failure $code) False)
       ($list
         (if
           (== $list ())
           True
           (let* (($head (car-atom $list))
                   ($tail (cdr-atom $list))
                   ($kind (llm:v1:get $head "type")))
             (if (== $kind (JsonString "tool_result")) (llm:v1:tool-results? $tail) False)))))))
(= (llm:v1:close-turn $open $turns)
   (if
     (== $open ())
     $turns
     (let $turn (llm:v1:finished-turn $open) (cons-atom $turn $turns))))
(= (llm:v1:finished-turn $open)
   (case
     $open
     (((llm:v1:turn $first $blocks $joined $results-only)
        (if
          $joined
          (let $in-order (llm:v1:in-order $blocks) (llm:v1:with $first "content" (JsonArray $in-order)))
          $first))
       ($failure $failure))))
(= (llm:v1:response-message $message $role-policy)
   (let* (($role (llm:v1:required $message "role"))
           ($content (llm:v1:get $message "content"))
           ($attachment (llm:v1:get $message "native_items")))
     (if
       (not (== $attachment JsonNull))
       (let
         $value
         (llm:v1:attachment "responses" $attachment)
         (let
           $validated-output-24
           (llm:v1:array $value)
           (llm:v1:validated ($value) $validated-output-24)))
       (if
         (== $role (JsonString "tool"))
         (let* (($id (llm:v1:required $message "tool_call_id"))
                 ($checked (llm:v1:text $id))
                 ($item
                   (JsonObject
                     ((JsonPair "type" (JsonString "function_call_output"))
                       (JsonPair "call_id" $id)
                       (JsonPair "output" $content)))))
           (let
             $validated-output-25
             (cons-atom $item ())
             (llm:v1:validated ($checked) $validated-output-25)))
         (let* (($ignored
                   (if
                     (or
                       (== $role (JsonString "system"))
                       (or
                         (== $role (JsonString "developer"))
                         (or (== $role (JsonString "user")) (== $role (JsonString "assistant")))))
                     True
                     (llm:v1:failure unsupported-message-role)))
                 ($text
                   (if
                     (or (== $content JsonNull) (== $content (JsonString "")))
                     ()
                     (let
                       $checked-28
                       (llm:v1:text $content)
                       (let
                         $validated-output-26
                         ((JsonObject ((JsonPair "role" $role) (JsonPair "content" $content))))
                         (llm:v1:validated ($checked-28) $validated-output-26)))))
                 ($reasoning-json (llm:v1:get $message "reasoning_details"))
                 ($reasoning-list (llm:v1:optional-array $reasoning-json))
                 ($reasoning (llm:v1:reasoning "responses" $reasoning-list))
                 ($calls-json (llm:v1:get $message "tool_calls"))
                 ($calls (llm:v1:optional-array $calls-json))
                 ($ignored-role
                   (if
                     (or (== $role (JsonString "assistant")) (and (== $reasoning ()) (== $calls ())))
                     True
                     (llm:v1:failure invalid-message-role)))
                 ($tools (llm:v1:request-calls "responses" $calls))
                 ($first (llm:v1:append $reasoning $text)))
           (let
             $validated-output-27
             (llm:v1:append $first $tools)
             (llm:v1:validated ($ignored $ignored-role) $validated-output-27)))))))
; Built newest first and put in order once, as the Anthropic conversation is.
(= (llm:v1:response-conversation $messages $role-policy $system $items)
   (if
     (== $messages ())
     (let* (($instructions (llm:v1:reverse-onto $system ()))
             ($input (llm:v1:in-order $items)))
       (llm:v1:conversation $instructions $input))
     (let* (($head (car-atom $messages))
             ($tail (cdr-atom $messages))
             ($role (llm:v1:required $head "role")))
       (if
         (and
           (== $role-policy (JsonString "merge-system-developer"))
           (or (== $role (JsonString "system")) (== $role (JsonString "developer"))))
         (if
           (not (== $items ()))
           (llm:v1:refused-items late-system-instructions $system $items)
           ; This instruction's failure is the outcome, whatever follows.
           (let* (($text (llm:v1:required $head "content"))
                   ($checked (llm:v1:text $text)))
             (case
               $checked
               (((llm:v1:failure $code) (llm:v1:failure $code))
                 ($valid
                   (let $next (cons-atom $text $system)
                     (llm:v1:response-conversation $tail $role-policy $next $items)))))))
         (let* (($new (llm:v1:response-message $head $role-policy))
                 ($next-30 (llm:v1:prepend-reversed $new $items)))
           (llm:v1:response-conversation $tail $role-policy $system $next-30))))))
(= (llm:v1:refused-items $code $system $items)
   (let
     $earlier
     (llm:v1:failure-in $items)
     (case
       $earlier
       (((llm:v1:failure $first)
          (let* (($instructions (llm:v1:reverse-onto $system ()))
                  ($input (llm:v1:in-order $items)))
            (llm:v1:conversation $instructions $input)))
         ($none (llm:v1:failure $code))))))
(= (llm:v1:tools $protocol $tools)
   (if
     (== $tools ())
     ()
     (let* (($head (car-atom $tools))
             ($tail (cdr-atom $tools))
             ($type (llm:v1:required $head "type"))
             ($ignored-type
               (if (== $type (JsonString "function")) True (llm:v1:failure unsupported-tool-kind)))
             ($fn (llm:v1:required $head "function"))
             ($name (llm:v1:required $fn "name"))
             ($checked (llm:v1:text $name))
             ($schema (llm:v1:required $fn "parameters"))
             ($ignored-schema (if (llm:v1:object? $schema) True (llm:v1:failure invalid-tool-schema)))
             ($description (llm:v1:get $fn "description"))
             ($description-value (if (== $description JsonNull) (JsonString "") $description))
             ($item
               (if
                 (== $protocol "anthropic")
                 (JsonObject
                   ((JsonPair "name" $name)
                     (JsonPair "description" $description-value)
                     (JsonPair "input_schema" $schema)))
                 (if (== $protocol "responses") (llm:v1:with $fn "type" (JsonString "function")) $head)))
             ($rest (llm:v1:tools $protocol $tail)))
       (let
         $validated-output-31
         (llm:v1:cons $item $rest)
         (llm:v1:validated ($ignored-type $checked $ignored-schema) $validated-output-31)))))
(= (llm:v1:tool-choice $protocol $choice $policy $thinking)
   (let
     $selected
     (if (== $choice JsonNull) (JsonString "auto") $choice)
     (if
       (== $protocol "anthropic")
       (let
         $kind
         (if (and (== $policy (JsonString "auto-for-thinking")) (not (== $thinking JsonNull)))
           (JsonString "auto") $selected)
         (if
           (and (not (== $thinking JsonNull)) (not (== $kind (JsonString "auto"))))
           (llm:v1:failure unsupported-thinking-tool-choice)
           (case
             $kind
             (((JsonString "auto") (JsonObject ((JsonPair "type" (JsonString "auto")))))
               ((JsonString "none") (JsonObject ((JsonPair "type" (JsonString "none")))))
               ((JsonString "required") (JsonObject ((JsonPair "type" (JsonString "any")))))
               ((JsonObject $pairs)
                 (let* (($type (llm:v1:get $kind "type"))
                         ($fn (llm:v1:get $kind "function"))
                         ($name (llm:v1:required $fn "name"))
                         ($checked (llm:v1:text $name)))
                   (let
                     $validated-output-32
                     (if
                       (== $type (JsonString "function"))
                       (JsonObject ((JsonPair "type" (JsonString "tool")) (JsonPair "name" $name)))
                       (llm:v1:failure unsupported-tool-choice))
                     (llm:v1:validated ($checked) $validated-output-32))))
               ($other (llm:v1:failure unsupported-tool-choice))))))
       $selected)))
(= (llm:v1:cache-marker $ttl)
   (if (== $ttl JsonNull)
     (JsonObject ((JsonPair "type" (JsonString "ephemeral"))))
     (JsonObject ((JsonPair "type" (JsonString "ephemeral")) (JsonPair "ttl" $ttl)))))
(= (llm:v1:cache-last $blocks)
   (let $marker (llm:v1:cache-marker JsonNull) (llm:v1:cache-last-with $marker $blocks)))
; Failed blocks stay that failure; marking would rewrite its code.
(= (llm:v1:cache-last-with $marker $blocks)
   (case $blocks
     (((llm:v1:failure $code) (llm:v1:failure $code))
      ($list (llm:v1:cache-last-list $marker $list)))))
(= (llm:v1:cache-last-list $marker $blocks)
   (if (== $blocks ()) ()
     (let* (($head (car-atom $blocks)) ($tail (cdr-atom $blocks)))
       (if (== $tail ())
         (let $cached (llm:v1:with $head "cache_control" $marker)
           (cons-atom $cached ()))
         (let $rest (llm:v1:cache-last-list $marker $tail) (cons-atom $head $rest))))))
; A growing conversation caches at its newest user message and at the user
; message that ended the previous request, so each call reads the prefix the
; previous call wrote and writes only the new turn.
(= (llm:v1:cache-message $marker $message)
   (if (== (llm:v1:get $message "role") (JsonString "user"))
     (case (llm:v1:get $message "content")
       (((JsonArray $blocks)
         (let $cached (llm:v1:cache-last-with $marker $blocks) (llm:v1:with $message "content" (JsonArray $cached))))
        ($other $message)))
     $message))
(= (llm:v1:reverse-onto $items $out)
   (if (== $items ()) $out
     (let* (($head (car-atom $items)) ($tail (cdr-atom $items)) ($next (cons-atom $head $out)))
       (llm:v1:reverse-onto $tail $next))))
(= (llm:v1:cache-newest $marker $newest-first $position)
   (if (or (== $newest-first ()) (> $position 2)) $newest-first
     (let* (($head (car-atom $newest-first)) ($tail (cdr-atom $newest-first))
            ($marked (if (== $position 1) $head (llm:v1:cache-message $marker $head)))
            ($next (+ $position 1))
            ($rest (llm:v1:cache-newest $marker $tail $next)))
       (cons-atom $marked $rest))))
(= (llm:v1:cache-conversation $marker $conversation)
   (let* (($newest-first (llm:v1:reverse-onto $conversation ()))
          ($marked (llm:v1:cache-newest $marker $newest-first 0)))
     (llm:v1:reverse-onto $marked ())))
(= (llm:v1:reasoning-options $protocol $request $body)
   (let* (($reasoning (llm:v1:get $request "reasoning"))
           ($effort (llm:v1:get $reasoning "effort"))
           ($thinking (llm:v1:get $request "thinking")))
     (if
       (== $protocol "anthropic")
       (let* (($with-effort
                 (if
                   (or
                     (== $effort JsonNull)
                     (or (== $effort (JsonString "")) (== $effort (JsonString "default"))))
                   $body
                   (let* (($text (llm:v1:text $effort))
                           ($valid (llm:v1:member? $text ("low" "medium" "high" "xhigh" "max"))))
                     (if
                       $valid
                       (llm:v1:with $body "output_config" (JsonObject ((JsonPair "effort" $effort))))
                       (llm:v1:failure unsupported-reasoning-effort)))))
               ($result
                 (if
                   (== $thinking JsonNull)
                   $with-effort
                   (llm:v1:with $with-effort "thinking" $thinking))))
         $result)
       (if (== $reasoning JsonNull) $body
         (if (and (== $protocol "chat-completions")
                  (not (== (llm:v1:get $request "chat_profile") (JsonString "compatible"))))
           (if (or (== $effort JsonNull) (or (== $effort (JsonString ""))
                                            (== $effort (JsonString "default")))) $body
             (let* (($chat-effort (llm:v1:text $effort))
                    ($chat-supported (llm:v1:member? $chat-effort ("none" "minimal" "low" "medium" "high" "xhigh" "max"))))
               (if $chat-supported (llm:v1:with $body "reasoning_effort" $effort)
                 (llm:v1:failure unsupported-reasoning-effort))))
           (llm:v1:with $body "reasoning" $reasoning))))))
(= (llm:v1:extensions $pairs $body)
   (if
     (== $pairs ())
     $body
     (case
       (car-atom $pairs)
       (((JsonPair $key $value) (let* (($present (llm:v1:get $body $key)) ($reserved (llm:v1:member? $key ("model" "messages" "input" "max_tokens" "max_completion_tokens" "max_output_tokens" "stream"))) ($tail (cdr-atom $pairs))) (if (or $reserved (not (== $present JsonNull))) (llm:v1:failure conflicting-extension) (let $next (llm:v1:with $body $key $value) (llm:v1:extensions $tail $next)))))))))
(= (llm:v1:wire-value $protocol $request)
   (let* (($version (llm:v1:version $protocol))
           ($model (llm:v1:required $request "model"))
           ($checked-request (llm:v1:request-fields $request))
           ($model-name (llm:v1:text $model))
           ($tokens (llm:v1:required $request "max_tokens"))
           ($count (llm:v1:count $tokens))
           ($token-text (case $count (((JsonNumber $n) $n))))
           ($number (str:string->number $token-text))
           ($ignored-count (if (> $number 0) True (llm:v1:failure invalid-output-limit)))
           ($stream (llm:v1:get $request "stream"))
           ($ignored-stream
             (if
               (or (== $stream JsonNull) (== $stream (JsonBool False)))
               True
               (llm:v1:failure streaming-not-supported)))
           ($messages-json (llm:v1:required $request "messages"))
           ($messages (llm:v1:array $messages-json))
           ($role-policy (llm:v1:get $request "role_policy"))
           ($valid-messages (llm:v1:validate-messages $protocol $messages))
           ($valid-options (llm:v1:validate-options $protocol $request))
           ($tools-json (llm:v1:get $request "tools"))
           ($tools-list (llm:v1:optional-array $tools-json))
           ($tools (llm:v1:tools $protocol $tools-list))
           ($thinking (llm:v1:get $request "thinking"))
           ($choice (llm:v1:get $request "tool_choice"))
           ($choice-policy (llm:v1:get $request "tool_choice_policy"))
           ($choice-value (llm:v1:tool-choice $protocol $choice $choice-policy $thinking))
           ($choice-tools-ready
             (if (or (not (== $tools ()))
                     (or (== $choice JsonNull) (or (== $choice (JsonString "auto"))
                                                 (== $choice (JsonString "none"))))) True
               (llm:v1:failure tool-choice-without-tools)))
           ($cache (llm:v1:get $request "cache_system"))
           ($cache-messages (llm:v1:get $request "cache_messages"))
           ($ttl (llm:v1:get $request "cache_ttl"))
           ($marker (llm:v1:cache-marker $ttl))
           ($chat-profile (llm:v1:get $request "chat_profile"))
           ($chat-limit (if (== $chat-profile (JsonString "compatible")) "max_tokens" "max_completion_tokens"))
           ($base
             (case
               $protocol
               (("chat-completions" (JsonObject ((JsonPair "model" $model) (JsonPair "messages" $messages-json) (JsonPair $chat-limit $tokens))))
                 ("anthropic"
                   (case
                     (llm:v1:anthropic-conversation $messages $role-policy () ())
                     (((llm:v1:conversation $system $conversation) (let* (($cached (if (== $cache (JsonBool False)) $system (llm:v1:cache-last-with $marker $system))) ($turns (if (== $cache-messages (JsonBool True)) (llm:v1:cache-conversation $marker $conversation) $conversation)) ($body (JsonObject ((JsonPair "model" $model) (JsonPair "max_tokens" $tokens) (JsonPair "messages" (JsonArray $turns)))))) (if (== $cached ()) $body (llm:v1:with $body "system" (JsonArray $cached)))))
                       ((llm:v1:failure $failed-conversation) (llm:v1:failure $failed-conversation))
                       ($invalid-conversation (llm:v1:failure invalid-protocol-data)))))
                 ("responses"
                   (case
                     (llm:v1:response-conversation $messages $role-policy () ())
                     (((llm:v1:conversation $system-34 $items) (let* (($body-35 (JsonObject ((JsonPair "model" $model) (JsonPair "input" (JsonArray $items)) (JsonPair "max_output_tokens" $tokens) (JsonPair "store" (JsonBool False)) (JsonPair "include" (JsonArray ((JsonString "reasoning.encrypted_content"))))))) ($text (if (== $system-34 ()) "" (llm:v1:join-text "\n\n" $system-34)))) (if (== $system-34 ()) $body-35 (llm:v1:with $body-35 "instructions" (JsonString $text)))))
                       ((llm:v1:failure $failed-conversation) (llm:v1:failure $failed-conversation))
                       ($invalid-conversation (llm:v1:failure invalid-protocol-data))))))))
           ($with-tools
             (if
               (== $tools ())
               $base
               (let
                 $body-36
                 (llm:v1:with $base "tools" (JsonArray $tools))
                 (llm:v1:with $body-36 "tool_choice" $choice-value))))
           ($with-reasoning (llm:v1:reasoning-options $protocol $request $with-tools))
           ($extensions-json (llm:v1:get $request "extensions"))
           ($extensions
             (if
               (== $extensions-json JsonNull)
               ()
               (case
                 $extensions-json
                 (((JsonObject $pairs) $pairs) ($bad (llm:v1:failure expected-object))))))
           ($wire (llm:v1:extensions $extensions $with-reasoning))
           ($checked-wire (llm:v1:checked $wire))
           ($path
             (case
               $protocol
               (("anthropic" "/messages")
                 ("responses" "/responses")
                 ("chat-completions" "/chat/completions")))))
     (let
       $validated-output-33
       (llm:v1:wire $path $checked-wire)
       (llm:v1:validated
         ($version $checked-request $model-name $ignored-count $ignored-stream $valid-messages $valid-options $choice-tools-ready)
         $validated-output-33))))
(= (llm:v1:join-text $separator $items)
   (if (== $items ()) ""
     (let $texts (llm:v1:texts $items) (str:join $separator $texts))))
(= (llm:v1:texts $items)
   (if (== $items ()) ()
     (let* (($head (car-atom $items)) ($text (llm:v1:text $head)) ($tail (cdr-atom $items))
            ($rest (llm:v1:texts $tail)))
       (llm:v1:cons $text $rest))))
(= (llm:v1:encode $protocol $text)
   (function
     (case
       (let* (($name (llm:v1:protocol $protocol))
               ($request (llm:v1:parse $text))
               ($result (llm:v1:encode-parsed $name $request)))
         (llm:v1:checked $result))
       (((llm:v1:failure $code) (return (llm:v1:error $code)))
         ((Error $source $reason) (return (llm:v1:error invalid-protocol-data)))
         ($encoded (return (llm:v1:ok $encoded)))))))

(= (llm:v1:decode-parsed $protocol $value)
   (case $value (((llm:v1:failure $code) (llm:v1:failure $code))
     ($wire (llm:v1:decoded $protocol $wire)))))
(= (llm:v1:wire-parsed $protocol $value)
   (case $value (((llm:v1:failure $code) (llm:v1:failure $code))
     ($request (let $validation (llm:v1:validate-request $request)
       (case $validation (((llm:v1:failure $code) (llm:v1:failure $code))
         ($ok (llm:v1:wire-value $protocol $request)))))))))
(= (llm:v1:encode-parsed $protocol $value)
   (let $wire (llm:v1:wire-parsed $protocol $value) (llm:v1:rendered $wire)))
; A request's wire is its path and its checked body, still a JSON value. The
; text entries render it here; the value entries hand it to the caller.
(= (llm:v1:encode-value $protocol $request)
   (let $wire (llm:v1:wire-value $protocol $request) (llm:v1:rendered $wire)))
(= (llm:v1:rendered $wire)
   (case $wire
     (((llm:v1:wire $path $body)
       (let $text (llm:v1:render $body) (llm:v1:encoded $path $text)))
      ($failure $failure))))
; A failed body is the wire's failure.
(= (llm:v1:wire-checked $wire)
   (case $wire
     (((llm:v1:wire $path (llm:v1:failure $code)) (llm:v1:failure $code))
      ($other $other))))
; A value entry holds its value to the parser's contract: no object repeats
; a key. Text with a repeated key never parses, so both entries refuse it.
(= (llm:v1:held $value)
   (if (llm:v1:distinct? $value) $value (llm:v1:failure invalid-or-ambiguous-json)))
(= (llm:v1:distinct? $value)
   (case $value
     (((JsonObject $pairs) (llm:v1:distinct-pairs? $pairs ()))
      ((JsonArray $items) (llm:v1:distinct-items? $items))
      ($scalar True))))
(= (llm:v1:distinct-pairs? $pairs $seen)
   (if (== $pairs ()) True
     (case (car-atom $pairs)
       (((JsonPair $key $value)
         (if (llm:v1:member? $key $seen) False
           (if (llm:v1:distinct? $value)
             (let* (($tail (cdr-atom $pairs)) ($next (cons-atom $key $seen)))
               (llm:v1:distinct-pairs? $tail $next))
             False)))
        ($other True)))))
(= (llm:v1:distinct-items? $items)
   (if (== $items ()) True
     (let $head (car-atom $items)
       (if (llm:v1:distinct? $head)
         (let $tail (cdr-atom $items) (llm:v1:distinct-items? $tail))
         False))))
; The wire of a request that is already a JSON value, as llm:v1:parse builds
; it: the body is checked and left unrendered, so a caller that adjusts it
; renders once.
(= (llm:v1:encode-wire $protocol $value)
   (function
     (case
       (let* (($name (llm:v1:protocol $protocol))
               ($request (llm:v1:held $value))
               ($result (llm:v1:wire-parsed $name $request)))
         (llm:v1:wire-checked $result))
       (((llm:v1:failure $code) (return (llm:v1:error $code)))
         ((Error $source $reason) (return (llm:v1:error invalid-protocol-data)))
         ($wire (return (llm:v1:ok $wire)))))))
(= (llm:v1:replay-parsed $value $choice)
   (case $value (((llm:v1:failure $code) (llm:v1:failure $code))
     ($result (llm:v1:replay-value $result $choice)))))
(= (llm:v1:output-limit $value)
   (case $value
     (((JsonNumber $text)
       (if (and (not (== $text "")) (str:is-all-in digit $text))
         (let $number (str:string->number $text)
           (if (> $number 0) True (llm:v1:failure invalid-output-limit)))
         (llm:v1:failure invalid-output-limit)))
      ($other (llm:v1:failure invalid-output-limit)))))
(= (llm:v1:validate-request $request)
   (let* (($fields (llm:v1:request-fields $request))
          ($model (llm:v1:required $request "model")) ($name (llm:v1:nonempty-text $model))
          ($tokens (llm:v1:required $request "max_tokens")) ($limit (llm:v1:output-limit $tokens)))
     (llm:v1:validated ($fields $name $limit) True)))
(: llm:v1:validate-options (-> Atom Atom %Undefined%))
(= (llm:v1:validate-options $protocol $request)
   (let* (($role (llm:v1:get $request "role_policy"))
          ($role-ok (if (or (== $role JsonNull) (or (== $role (JsonString "preserve"))
                       (== $role (JsonString "merge-system-developer")))) True
                     (llm:v1:failure unsupported-role-policy)))
          ($reasoning (llm:v1:get $request "reasoning")) ($reasoning-ok (llm:v1:optional-object $reasoning))
          ($thinking (llm:v1:get $request "thinking")) ($thinking-ok (llm:v1:optional-object $thinking))
          ($cache (llm:v1:get $request "cache_system"))
          ($cache-ok (if (or (== $cache JsonNull) (or (== $cache (JsonBool True)) (== $cache (JsonBool False))))
                       True (llm:v1:failure invalid-cache-policy)))
          ($cache-messages (llm:v1:get $request "cache_messages"))
          ($cache-messages-ok (if (or (== $cache-messages JsonNull) (or (== $cache-messages (JsonBool True))
                                    (== $cache-messages (JsonBool False))))
                                True (llm:v1:failure invalid-cache-policy)))
          ($ttl (llm:v1:get $request "cache_ttl"))
          ($ttl-ok (if (or (== $ttl JsonNull) (or (== $ttl (JsonString "5m")) (== $ttl (JsonString "1h"))))
                     True (llm:v1:failure invalid-cache-policy)))
          ($cache-supported (if (or (== $protocol "anthropic")
                                    (and (== $cache JsonNull) (and (== $cache-messages JsonNull) (== $ttl JsonNull))))
                               True (llm:v1:failure unsupported-provider-option)))
          ($chat-profile (llm:v1:get $request "chat_profile"))
          ($chat-profile-ok (if (or (== $chat-profile JsonNull)
                  (and (== $protocol "chat-completions")
                       (or (== $chat-profile (JsonString "openai")) (== $chat-profile (JsonString "compatible")))))
                     True (llm:v1:failure unsupported-chat-profile)))
          ($reasoning-fields (if (or (== $reasoning JsonNull)
                    (or (== $protocol "responses") (== $chat-profile (JsonString "compatible")))) True
                  (case $reasoning
                    (((JsonObject $pairs) (llm:v1:allowed-fields $pairs ("effort")))
                     ($other (llm:v1:failure expected-object))))))
          ($choice (llm:v1:get $request "tool_choice_policy"))
          ($choice-ok (if (or (== $choice JsonNull) (== $choice (JsonString "auto-for-thinking"))) True
                        (llm:v1:failure unsupported-tool-choice-policy)))
          ($supported (if (or (== $protocol "anthropic") (and (== $thinking JsonNull) (== $choice JsonNull)))
                        True (llm:v1:failure unsupported-provider-option))))
     (llm:v1:validated ($role-ok $reasoning-ok $thinking-ok $cache-ok $cache-messages-ok $ttl-ok $cache-supported $chat-profile-ok $reasoning-fields $choice-ok $supported) True)))
(: llm:v1:validate-messages (-> Atom Atom %Undefined%))
(= (llm:v1:validate-messages $protocol $messages)
   (if (== $messages ()) True
     (let* (($head (car-atom $messages)) ($tail (cdr-atom $messages))
            ($role-json (llm:v1:required $head "role")) ($role (llm:v1:text $role-json))
            ($role-ok (if (llm:v1:member? $role ("system" "developer" "user" "assistant" "tool"))
                        True (llm:v1:failure unsupported-message-role)))
            ($native-content (llm:v1:get $head "native_content"))
            ($native-items (llm:v1:get $head "native_items"))
            ($attachment-ok (if (and
                    (or (== $native-content JsonNull) (== $protocol "anthropic"))
                    (or (== $native-items JsonNull) (== $protocol "responses"))) True
                  (llm:v1:failure incompatible-native-attachment)))
            ($attachment-role (if (or (== $role "assistant")
                      (and (== $native-content JsonNull) (== $native-items JsonNull))) True
                  (llm:v1:failure invalid-message-role)))
            ($calls-json (llm:v1:get $head "tool_calls")) ($calls (llm:v1:optional-array $calls-json))
            ($call-check (llm:v1:request-calls "responses" $calls))
            ($calls-role (if (or (== $role "assistant") (== $calls ())) True
                          (llm:v1:failure invalid-message-role)))
            ($tool-id (if (== $role "tool")
                        (let $id (llm:v1:required $head "tool_call_id") (llm:v1:nonempty-text $id)) True))
            ($rest (llm:v1:validate-messages $protocol $tail)))
       (llm:v1:validated ($role-ok $attachment-ok $attachment-role $call-check $calls-role $tool-id $rest) True))))
(= (llm:v1:protocol $value)
   (case $value ((anthropic "anthropic") (responses "responses")
     (chat-completions "chat-completions") ($other $value))))
; These are codec capabilities, not a promise about any particular model.
(: llm:v1:capabilities (-> %Undefined% %Undefined%))
(= (llm:v1:capabilities $protocol)
   (let* (($name (llm:v1:protocol $protocol)) ($version (llm:v1:version $name)))
     (case $version
       (((llm:v1:failure $code) (llm:v1:error $code))
        ($supported (llm:v1:ok (JsonObject
          ((JsonPair "protocol" (JsonString $name))
           (JsonPair "protocol_version" (JsonString $supported))
           (JsonPair "buffered" (JsonBool True)) (JsonPair "streaming" (JsonBool False))
           (JsonPair "tool_execution" (JsonBool False))
           (JsonPair "native_replay" (JsonBool True))
           (JsonPair "model_capabilities" JsonNull)
           (JsonPair "tool_schema_validation" (JsonString "object-shape-only"))))))))))
(= (llm:v1:request-fields $request)
   (case
     $request
     (((JsonObject $pairs) (llm:v1:allowed-fields $pairs ("model" "messages" "max_tokens" "tools" "tool_choice" "reasoning" "thinking" "cache_system" "cache_messages" "cache_ttl" "role_policy" "tool_choice_policy" "chat_profile" "stream" "extensions")))
       ($other (llm:v1:failure expected-object)))))
(= (llm:v1:allowed-fields $pairs $allowed)
   (if
     (== $pairs ())
     True
     (case
       (car-atom $pairs)
       (((JsonPair $key $value) (let* (($valid (llm:v1:member? $key $allowed)) ($tail (cdr-atom $pairs))) (if $valid (llm:v1:allowed-fields $tail $allowed) (llm:v1:failure unsupported-request-field))))))))

; Replay keeps native grouping and signatures. Choice is explicit; incomplete
; output cannot become a new executable assistant turn through this operation.
(: llm:v1:replay-items-ready (-> Atom %Undefined%))
(= (llm:v1:replay-items-ready $items)
   (if (== $items ()) True
     (let* (($item (car-atom $items)) ($tail (cdr-atom $items))
            ($kind (llm:v1:get $item "kind")) ($status (llm:v1:get $item "status"))
            ($native (llm:v1:get $item "native")) ($native-status (llm:v1:get $native "status"))
            ($native-ready (if (or (== $native-status JsonNull)
                                   (== $native-status (JsonString "completed"))) True
                              (llm:v1:failure unfinished-replay)))
            ($ready (if (== $kind (JsonString "tool-call"))
                      (if (== $status (JsonString "completed")) True
                        (llm:v1:failure unfinished-replay)) True))
            ($parts (llm:v1:get $item "parts"))
            ($nested (if (== $parts JsonNull) True
                       (let $values (llm:v1:array $parts) (llm:v1:replay-items-ready $values))))
            ($rest (llm:v1:replay-items-ready $tail)))
       (llm:v1:validated ($native-ready $ready $nested $rest) True))))
(= (llm:v1:nth $items $index)
   (if
     (or (< $index 0) (== $items ()))
     (llm:v1:failure missing-choice)
     (if
       (== $index 0)
       (car-atom $items)
       (let* (($tail (cdr-atom $items)) ($next (- $index 1))) (llm:v1:nth $tail $next)))))
(= (llm:v1:replay-value $result $index)
   (let* (($schema (llm:v1:required $result "schema"))
           ($schema-ok (if (== $schema (JsonString "llm-result-v1")) True
                         (llm:v1:failure invalid-replay-schema)))
           ($protocol-json (llm:v1:required $result "protocol"))
           ($protocol (llm:v1:text $protocol-json))
           ($version-json (llm:v1:required $result "protocol_version"))
           ($version (llm:v1:version $protocol))
           ($checked-version
             (if
               (== $version-json (JsonString $version))
               True
               (llm:v1:failure incompatible-native-attachment)))
           ($native (llm:v1:required $result "native"))
           ($termination (llm:v1:required $result "termination"))
           ($finish (llm:v1:get $termination "normalized"))
           ($items-json (llm:v1:required $result "items"))
           ($items (llm:v1:array $items-json))
           ($selected-items (if (== $protocol "chat-completions")
                              (let $selected (llm:v1:nth $items $index) (cons-atom $selected ())) $items))
           ($ready (llm:v1:replay-items-ready $selected-items)))
     (let
       $validated-output-37
       (if
         (== $protocol "chat-completions")
         (let* (($choices-json (llm:v1:required $native "choices"))
                 ($choices (llm:v1:array $choices-json))
                 ($choice (llm:v1:nth $choices $index))
                 ($raw (llm:v1:get $choice "finish_reason"))
                 ($normalized (llm:v1:finish $protocol $raw)))
           (if
             (or (== $normalized "stop") (== $normalized "tool_calls"))
             (llm:v1:required $choice "message")
             (llm:v1:failure unfinished-replay)))
         (if
           (or
             (not (== $index 0))
             (not (or (== $finish (JsonString "stop")) (== $finish (JsonString "tool_calls")))))
           (llm:v1:failure unfinished-replay)
           (let* (($field (if (== $protocol "anthropic") "content" "output"))
                   ($value (llm:v1:required $native $field))
                   ($attachment
                     (JsonObject
                       ((JsonPair "protocol" $protocol-json)
                         (JsonPair "protocol_version" $version-json)
                         (JsonPair "value" $value))))
                   ($key (if (== $protocol "anthropic") "native_content" "native_items"))
                   ($message (JsonObject ((JsonPair "role" (JsonString "assistant"))))))
             (llm:v1:with $message $key $attachment))))
       (llm:v1:validated ($schema-ok $version-json $version $checked-version $ready) $validated-output-37))))
(= (llm:v1:checked $value)
   (let
     $failure
     (llm:v1:failure-in $value)
     (case $failure (((llm:v1:failure $code) (llm:v1:failure $code)) ($none $value)))))
(= (llm:v1:validated $guards $value)
   (let
     $failure
     (llm:v1:failure-in $guards)
     (case $failure (((llm:v1:failure $code) (llm:v1:failure $code)) ($none $value)))))
(= (llm:v1:failure-in $value)
   (case
     $value
     (((llm:v1:failure $code) (llm:v1:failure $code))
       ((Error $source $reason) (llm:v1:failure invalid-protocol-data))
       ($other (if (== (get-metatype $value) Expression) (llm:v1:failure-list $value) ())))))
(= (llm:v1:failure-list $items)
   (if (== $items ()) ()
     (let* (($head (car-atom $items)) ($tail (cdr-atom $items)) ($failure (llm:v1:failure-in $head)))
       (if (== $failure ()) (llm:v1:failure-list $tail) $failure))))
(= (llm:v1:replay $text $choice)
   (function
     (case
       (let* (($result (llm:v1:parse $text))
               ($message-38 (llm:v1:replay-parsed $result $choice)))
         (llm:v1:checked $message-38))
       (((llm:v1:failure $code) (return (llm:v1:error $code)))
         ((Error $source $reason) (return (llm:v1:error invalid-replay)))
         ($message (return (llm:v1:ok $message)))))))

; Value parameters are held; compute calls with let before passing them.
(: llm:v1:decode-parsed (-> Atom Atom %Undefined%))
(: llm:v1:encode-parsed (-> Atom Atom %Undefined%))
(: llm:v1:replay-parsed (-> Atom Atom %Undefined%))
(: llm:v1:validate-request (-> Atom %Undefined%))
(: llm:v1:output-limit (-> Atom %Undefined%))
(: llm:v1:checked (-> Atom %Undefined%))
(: llm:v1:validated (-> Atom Atom %Undefined%))
(: llm:v1:failure-in (-> Atom %Undefined%))
(: llm:v1:failure-list (-> Atom %Undefined%))
(: llm:v1:get (-> Atom Atom %Undefined%))
(: llm:v1:member? (-> Atom Atom %Undefined%))
(: llm:v1:unique-list? (-> Atom %Undefined%))
(: llm:v1:unique-members? (-> Atom Atom %Undefined%))
(: llm:v1:unique? (-> Atom %Undefined%))
(: llm:v1:parse (-> %Undefined% %Undefined%))
(: llm:v1:object? (-> Atom %Undefined%))
(: llm:v1:array (-> Atom %Undefined%))
(: llm:v1:text (-> Atom %Undefined%))
(: llm:v1:required (-> Atom Atom %Undefined%))
(: llm:v1:with (-> Atom Atom Atom %Undefined%))
(: llm:v1:without (-> Atom Atom %Undefined%))
(: llm:v1:append (-> Atom Atom %Undefined%))
(: llm:v1:prepend-reversed (-> Atom Atom %Undefined%))
(: llm:v1:in-order (-> Atom %Undefined%))
(: llm:v1:cons (-> Atom Atom %Undefined%))
(: llm:v1:count (-> Atom %Undefined%))
(: llm:v1:counter (-> Atom Atom %Undefined%))
(: llm:v1:usage (-> Atom Atom %Undefined%))
(: llm:v1:termination (-> Atom Atom Atom %Undefined%))
(: llm:v1:finish (-> Atom Atom %Undefined%))
(: llm:v1:version (-> Atom %Undefined%))
(: llm:v1:part (-> Atom Atom %Undefined%))
(: llm:v1:text-part (-> Atom Atom Atom %Undefined%))
(: llm:v1:call-part (-> Atom Atom Atom Atom Atom %Undefined%))
(: llm:v1:blocks (-> Atom Atom Atom %Undefined%))
(: llm:v1:block (-> Atom Atom Atom %Undefined%))
(: llm:v1:message-item (-> Atom Atom Atom %Undefined%))
(: llm:v1:anthropic-items (-> Atom %Undefined%))
(: llm:v1:responses-items (-> Atom Atom %Undefined%))
(: llm:v1:response-item (-> Atom Atom %Undefined%))
(: llm:v1:chat-calls (-> Atom Atom %Undefined%))
(: llm:v1:optional-array (-> Atom %Undefined%))
(: llm:v1:chat-choice (-> Atom %Undefined%))
(: llm:v1:chat-choices (-> Atom %Undefined%))
(: llm:v1:decoded (-> Atom Atom %Undefined%))
(: llm:v1:outcome (-> Atom %Undefined%))
(: llm:v1:decode (-> %Undefined% %Undefined% %Undefined%))
(: llm:v1:text-blocks (-> Atom %Undefined%))
(: llm:v1:checked-text-blocks (-> Atom %Undefined%))
(: llm:v1:attachment (-> Atom Atom %Undefined%))
(: llm:v1:request-calls (-> Atom Atom %Undefined%))
(: llm:v1:reasoning (-> Atom Atom %Undefined%))
(: llm:v1:anthropic-message (-> Atom %Undefined%))
(: llm:v1:anthropic-conversation (-> Atom Atom Atom Atom %Undefined%))
(: llm:v1:anthropic-turns (-> Atom Atom Atom Atom Atom %Undefined%))
(: llm:v1:instruction-refusal (-> Atom Atom Atom Atom %Undefined%))
(: llm:v1:refused-conversation (-> Atom Atom Atom Atom %Undefined%))
(: llm:v1:open-turn (-> Atom %Undefined%))
(: llm:v1:join-turn (-> Atom Atom %Undefined%))
(: llm:v1:late-tool-result? (-> Atom Atom Atom Atom %Undefined%))
(: llm:v1:tool-results? (-> Atom %Undefined%))
(: llm:v1:close-turn (-> Atom Atom %Undefined%))
(: llm:v1:finished-turn (-> Atom %Undefined%))
(: llm:v1:response-message (-> Atom Atom %Undefined%))
(: llm:v1:response-conversation (-> Atom Atom Atom Atom %Undefined%))
(: llm:v1:refused-items (-> Atom Atom Atom %Undefined%))
(: llm:v1:tools (-> Atom Atom %Undefined%))
(: llm:v1:tool-choice (-> Atom Atom Atom Atom %Undefined%))
(: llm:v1:cache-last (-> Atom %Undefined%))
(: llm:v1:cache-marker (-> Atom %Undefined%))
(: llm:v1:cache-last-with (-> Atom Atom %Undefined%))
(: llm:v1:cache-last-list (-> Atom Atom %Undefined%))
(: llm:v1:cache-message (-> Atom Atom %Undefined%))
(: llm:v1:reverse-onto (-> Atom Atom %Undefined%))
(: llm:v1:cache-newest (-> Atom Atom Atom %Undefined%))
(: llm:v1:cache-conversation (-> Atom Atom %Undefined%))
(: llm:v1:reasoning-options (-> Atom Atom Atom %Undefined%))
(: llm:v1:extensions (-> Atom Atom %Undefined%))
(: llm:v1:encode-value (-> Atom Atom %Undefined%))
(: llm:v1:wire-value (-> Atom Atom %Undefined%))
(: llm:v1:wire-parsed (-> Atom Atom %Undefined%))
(: llm:v1:rendered (-> Atom %Undefined%))
(: llm:v1:wire-checked (-> Atom %Undefined%))
(: llm:v1:held (-> Atom %Undefined%))
(: llm:v1:distinct? (-> Atom %Undefined%))
(: llm:v1:distinct-pairs? (-> Atom Atom %Undefined%))
(: llm:v1:distinct-items? (-> Atom %Undefined%))
(: llm:v1:encode-wire (-> %Undefined% %Undefined% %Undefined%))
(: llm:v1:join-text (-> Atom Atom %Undefined%))
(: llm:v1:texts (-> Atom %Undefined%))
(: llm:v1:encode (-> %Undefined% %Undefined% %Undefined%))
(: llm:v1:protocol (-> Atom %Undefined%))
(: llm:v1:request-fields (-> Atom %Undefined%))
(: llm:v1:allowed-fields (-> Atom Atom %Undefined%))
(: llm:v1:nth (-> Atom Atom %Undefined%))
(: llm:v1:replay-value (-> Atom Atom %Undefined%))
(: llm:v1:replay (-> %Undefined% Number %Undefined%))
