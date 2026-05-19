; Rust-faithful memory trace normalization slice.
;
; This ports the pure data-shaping behavior from:
; - openai-codex/codex-rs/core/src/memory_trace.rs
;
; Covered in this increment:
; - normalize_trace_items
; - is_allowed_trace_item
; - load_trace_items over already-loaded text
; - build_memory_id
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust returns `Result<Vec<Value>, CodexErr>` and reads trace files from the
;   async filesystem before normalization. This CeTTa slice exposes the same
;   success/error data at the already-loaded text/JSON boundary so the runtime
;   file and model-client layers can be added separately.
; - Rust's path handling uses `Path::file_stem`. The current CeTTa port mirrors
;   the visible file-name stem behavior for normalized slash paths.

!(import! &self json)
!(import! &self list)
!(import! &self path)
!(import! &self str)

(= (codex:memory-trace-normalized $items)
   (CodexMemoryTraceNormalized $items))

(= (codex:memory-trace-invalid-request $message)
   (CodexMemoryTraceInvalidRequest $message))

(= (codex:memory-trace-normalized-items
      (CodexMemoryTraceNormalized $items))
   $items)

(= (codex:memory-trace-invalid-request-message
      (CodexMemoryTraceInvalidRequest $message))
   $message)

(= (codex:memory-trace-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:memory-trace-json-object-optional-string $object $key)
   (case (codex:memory-trace-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $text) $text))))

(= (codex:memory-trace-json-object-optional-array $object $key)
   (case (codex:memory-trace-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonArray $items) $items))))

(= (codex:memory-trace-json-object-optional-object $object $key)
   (case (codex:memory-trace-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonObject $pairs) (JsonObject $pairs)))))

(= (codex:memory-trace-append () $rhs)
   $rhs)

(= (codex:memory-trace-append $lhs $rhs)
   (let ($head $tail) (decons-atom $lhs)
     (case (codex:memory-trace-append $tail $rhs)
       (($rest (cons-atom $head $rest))))))

(= (codex:memory-trace-allowed-message-role $role)
   (if (== $role "assistant")
       True
       (if (== $role "system")
           True
           (if (== $role "developer")
               True
               (if (== $role "user")
                   True
                   False)))))

(= (codex:memory-trace-is-allowed-item $object)
   (let $item-type
     (codex:memory-trace-json-object-optional-string $object "type")
     (if (== $item-type CodexAbsent)
         False
         (if (== $item-type "message")
             (codex:memory-trace-allowed-message-role
               (codex:memory-trace-json-object-optional-string $object "role"))
             True))))

(= (codex:memory-trace-normalize-payload-object $payload)
   (if (codex:memory-trace-is-allowed-item $payload)
       ($payload)
       ()))

(= (codex:memory-trace-normalize-payload-array ())
   ())

(= (codex:memory-trace-normalize-payload-array $items)
   (let ($head $tail) (decons-atom $items)
     (case (codex:memory-trace-normalize-payload-array $tail)
       (($rest
         (case $head
           (((JsonObject $pairs)
             (let $object (JsonObject $pairs)
               (if (codex:memory-trace-is-allowed-item $object)
                   (cons-atom $object $rest)
                   $rest)))
            ($other $rest))))))))

(= (codex:memory-trace-normalize-object $object)
   (case (codex:memory-trace-json-object-optional-value $object "payload")
     ((CodexAbsent
       (if (codex:memory-trace-is-allowed-item $object)
           ($object)
           ()))
      ((JsonObject $payload-pairs)
       (if (== (codex:memory-trace-json-object-optional-string $object "type")
               "response_item")
           (codex:memory-trace-normalize-payload-object
             (JsonObject $payload-pairs))
           ()))
      ((JsonArray $payload-items)
       (if (== (codex:memory-trace-json-object-optional-string $object "type")
               "response_item")
           (codex:memory-trace-normalize-payload-array $payload-items)
           ()))
      ($other ()))))

(= (codex:memory-trace-normalize-items-list ())
   ())

(= (codex:memory-trace-normalize-items-list $items)
   (let ($head $tail) (decons-atom $items)
     (case (codex:memory-trace-normalize-items-list $tail)
       (($rest
         (case $head
           (((JsonObject $pairs)
             (codex:memory-trace-append
               (codex:memory-trace-normalize-object (JsonObject $pairs))
               $rest))
            ($other $rest))))))))

(= (codex:normalize-trace-items $items $path)
   (let $normalized (codex:memory-trace-normalize-items-list $items)
     (if (== $normalized ())
         (codex:memory-trace-invalid-request
           (format-args
             "no valid trace items after normalization: {}"
             ($path)))
         (codex:memory-trace-normalized $normalized))))

(= (codex:memory-trace-json-object-items ())
   ())

(= (codex:memory-trace-json-object-items $items)
   (let ($head $tail) (decons-atom $items)
     (case (codex:memory-trace-json-object-items $tail)
       (($rest
         (case $head
           (((JsonObject $pairs)
             (cons-atom (JsonObject $pairs) $rest))
            ($other $rest))))))))

(= (codex:memory-trace-load-array-items $items $path)
   (let $object-items (codex:memory-trace-json-object-items $items)
     (if (== $object-items ())
         (codex:memory-trace-invalid-request
           (format-args
             "no object items found in trace file: {}"
             ($path)))
         (codex:normalize-trace-items $object-items $path))))

(= (codex:memory-trace-line-could-start-json $line)
   (if (str-starts-with? $line "{")
       True
       (str-starts-with? $line "[")))

(= (codex:memory-trace-items-from-parsed-json-line (JsonObject $pairs))
   ((JsonObject $pairs)))

(= (codex:memory-trace-items-from-parsed-json-line (JsonArray $items))
   (codex:memory-trace-json-object-items $items))

(= (codex:memory-trace-items-from-parsed-json-line (JsonString $text))
   ())

(= (codex:memory-trace-items-from-parsed-json-line (JsonNumber $text))
   ())

(= (codex:memory-trace-items-from-parsed-json-line (JsonBool $value))
   ())

(= (codex:memory-trace-items-from-parsed-json-line JsonNull)
   ())

(= (codex:memory-trace-parse-json-line $line)
   (case (catch (eval (json-parse $line)))
     (((Error $context $message) ())
      ((catch $parsed)
       (codex:memory-trace-items-from-parsed-json-line $parsed)))))

(= (codex:memory-trace-lines $text)
   (let $parts (str-split "\n" $text)
     (if (str-ends-with? $text "\n")
         (codex:memory-trace-drop-last $parts)
         $parts)))

(= (codex:memory-trace-drop-last $items)
   (if (or (== $items ()) (== (list:len $items) 1))
       ()
       (let ($head $tail) (decons-atom $items)
         (case (codex:memory-trace-drop-last $tail)
           (($rest (cons-atom $head $rest)))))))

(= (codex:memory-trace-jsonl-items-from-lines ())
   ())

(= (codex:memory-trace-jsonl-items-from-lines $lines)
   (let ($head $tail) (decons-atom $lines)
     (let $line (str-trim $head)
       (case (codex:memory-trace-jsonl-items-from-lines $tail)
         (($rest
           (if (or (== $line "")
                   (not (codex:memory-trace-line-could-start-json $line)))
               $rest
               (codex:memory-trace-append
                 (codex:memory-trace-parse-json-line $line)
                 $rest))))))))

(= (codex:memory-trace-load-jsonl-items $text $path)
   (let $parsed-items
     (codex:memory-trace-jsonl-items-from-lines
       (codex:memory-trace-lines $text))
     (if (== $parsed-items ())
         (codex:memory-trace-invalid-request
           (format-args
             "no JSON items parsed from trace file: {}"
             ($path)))
         (codex:normalize-trace-items $parsed-items $path))))

(= (codex:load-trace-items $path $text)
   (case (catch (eval (json-parse $text)))
     (((catch (JsonArray $items))
       (codex:memory-trace-load-array-items $items $path))
      ($other
       (codex:memory-trace-load-jsonl-items $text $path)))))

(= (codex:memory-trace-last-part $path-text)
   (let $parts (path-parts $path-text)
     (if (== $parts ())
         ""
         (list:first (list:reverse $parts)))))

(= (codex:memory-trace-parts-last $parts)
   (if (== (list:len $parts) 1)
       (list:first $parts)
       (codex:memory-trace-parts-last (list:rest $parts))))

(= (codex:memory-trace-parts-init $parts)
   (if (== (list:len $parts) 1)
       ()
       (let $head (list:first $parts)
         (let $tail (list:rest $parts)
           (case (codex:memory-trace-parts-init $tail)
             (($rest (cons-atom $head $rest))))))))

(= (codex:memory-trace-file-stem-from-name $name)
   (if (== $name "")
       "memory"
       (let $parts (str-split "." $name)
         (if (== (list:len $parts) 1)
             $name
             (let $stem (str-join "." (codex:memory-trace-parts-init $parts))
               (if (== $stem "")
                   $name
                   $stem))))))

(= (codex:memory-trace-file-stem $path-text)
   (let $stem
     (codex:memory-trace-file-stem-from-name
       (codex:memory-trace-last-part $path-text))
     (if (== $stem "")
         "memory"
         $stem)))

(= (codex:build-memory-id $index $path-text)
   (format-args
     "memory_{}_{}"
     ($index (codex:memory-trace-file-stem $path-text))))
