!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:memory_trace)

(= (codex-memory-trace-test-normalized-items-json $result)
   (json-stringify
     (JsonArray
       (eval
         (codex:memory-trace-normalized-items $result)))))

!(assertEqual
  (codex-memory-trace-test-normalized-items-json
    (codex:normalize-trace-items
      ((JsonObject
         ((JsonPair "type" (JsonString "response_item"))
          (JsonPair "payload"
            (JsonObject
              ((JsonPair "type" (JsonString "message"))
               (JsonPair "role" (JsonString "assistant"))
               (JsonPair "content" (JsonArray ())))))))
       (JsonObject
         ((JsonPair "type" (JsonString "response_item"))
          (JsonPair "payload"
            (JsonArray
              ((JsonObject
                 ((JsonPair "type" (JsonString "message"))
                  (JsonPair "role" (JsonString "user"))
                  (JsonPair "content" (JsonArray ()))))
               (JsonObject
                 ((JsonPair "type" (JsonString "message"))
                  (JsonPair "role" (JsonString "tool"))
                  (JsonPair "content" (JsonArray ()))))
               (JsonObject
                 ((JsonPair "type" (JsonString "function_call"))
                  (JsonPair "name" (JsonString "shell"))
                  (JsonPair "arguments" (JsonString "{}"))
                  (JsonPair "call_id" (JsonString "c1")))))))))
       (JsonObject
         ((JsonPair "type" (JsonString "not_response_item"))
          (JsonPair "payload"
            (JsonObject
              ((JsonPair "type" (JsonString "message"))
               (JsonPair "role" (JsonString "assistant"))
               (JsonPair "content" (JsonArray ())))))))
       (JsonObject
         ((JsonPair "type" (JsonString "message"))
          (JsonPair "role" (JsonString "developer"))
          (JsonPair "content" (JsonArray ())))))
      "trace.json"))
  "[{\"type\":\"message\",\"role\":\"assistant\",\"content\":[]},{\"type\":\"message\",\"role\":\"user\",\"content\":[]},{\"type\":\"function_call\",\"name\":\"shell\",\"arguments\":\"{}\",\"call_id\":\"c1\"},{\"type\":\"message\",\"role\":\"developer\",\"content\":[]}]")

!(assertEqual
  (codex-memory-trace-test-normalized-items-json
    (codex:load-trace-items
      "trace.jsonl"
      "\n{\"type\":\"response_item\",\"payload\":{\"type\":\"message\",\"role\":\"assistant\",\"content\":[]}}\n[{\"type\":\"message\",\"role\":\"user\",\"content\":[]},{\"type\":\"message\",\"role\":\"tool\",\"content\":[]}]\n"))
  "[{\"type\":\"message\",\"role\":\"assistant\",\"content\":[]},{\"type\":\"message\",\"role\":\"user\",\"content\":[]}]")

!(assertEqual
  (codex-memory-trace-test-normalized-items-json
    (codex:load-trace-items
      "trace.json"
      "[{\"type\":\"message\",\"role\":\"system\",\"content\":[]},{\"type\":\"message\",\"role\":\"tool\",\"content\":[]},{\"type\":\"function_call\",\"call_id\":\"c2\"}]"))
  "[{\"type\":\"message\",\"role\":\"system\",\"content\":[]},{\"type\":\"function_call\",\"call_id\":\"c2\"}]")

!(assertEqual
  (codex:memory-trace-invalid-request-message
    (codex:normalize-trace-items
      ((JsonObject
         ((JsonPair "type" (JsonString "message"))
          (JsonPair "role" (JsonString "tool")))))
      "trace.json"))
  "no valid trace items after normalization: trace.json")

!(assertEqual
  (codex:memory-trace-invalid-request-message
    (codex:load-trace-items
      "empty.json"
      "[]"))
  "no object items found in trace file: empty.json")

!(assertEqual
  (codex:build-memory-id 1 "/tmp/trace.jsonl")
  "memory_1_trace")

!(assertEqual
  (codex:build-memory-id 2 "/tmp/.profile")
  "memory_2_.profile")
