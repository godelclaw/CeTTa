; Narrow Rust-faithful ToolName slice.
;
; This ports:
; - openai-codex/codex-rs/protocol/src/tool_name.rs
;
; Covered in this increment:
; - ToolName record shape
; - new / plain / namespaced constructors
; - display rendering
; - serde-compatible JSON rendering
; - serde-compatible JSON parsing for the protocol struct shape
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `Option<String>` for `namespace`. The current CeTTa port
;   preserves the same visible behavior and uses `CodexAbsent` for the absent
;   branch.
; - `display()` and JSON namespace rendering use explicit `if` checks over
;   `namespace` instead of overlapping pattern rules because the current CeTTa
;   reducer can materialize both branches under nested callers.

!(import! &self json)
!(import! &self str)

(= (codex:tool-name $namespace $name)
   (CodexToolName $name $namespace))

(= (codex:plain-tool-name $name)
   (codex:tool-name CodexAbsent $name))

(= (codex:namespaced-tool-name $namespace $name)
   (codex:tool-name $namespace $name))

(= (codex:tool-name-name (CodexToolName $name $namespace))
   $name)

(= (codex:tool-name-namespace (CodexToolName $name $namespace))
   $namespace)

(= (codex:tool-name-display (CodexToolName $name $namespace))
   (if (== $namespace CodexAbsent)
       $name
       (str-concat $namespace $name)))

(= (codex:tool-name-namespace-json $namespace)
   (if (== $namespace CodexAbsent)
       JsonNull
       (JsonString $namespace)))

(= (codex:tool-name-json (CodexToolName $name $namespace))
   (JsonObject
     ((JsonPair "name" (JsonString $name))
      (JsonPair "namespace" (codex:tool-name-namespace-json $namespace)))))

(= (codex:tool-name-parse-ok $value)
   (CodexToolNameParseOk $value))

(= (codex:tool-name-parse-error $message)
   (CodexToolNameParseError $message))

(= (codex:tool-name-parse-result-value (CodexToolNameParseOk $value))
   $value)

(= (codex:tool-name-parse-result-error (CodexToolNameParseError $message))
   $message)

(= (codex:tool-name-json-field-missing)
   (CodexToolNameJsonFieldMissing))

(= (codex:tool-name-json-field-value $value)
   (CodexToolNameJsonFieldValue $value))

(= (codex:tool-name-json-object-field-from () $key $found)
   $found)

(= (codex:tool-name-json-object-field-from $pairs $key $found)
   (let ($head $tail) (decons-atom $pairs)
     (case $head
       (((JsonPair $pair-key $value)
         (if (== $pair-key $key)
             (codex:tool-name-json-object-field-from
               $tail
               $key
               (codex:tool-name-json-field-value $value))
             (codex:tool-name-json-object-field-from
               $tail
               $key
               $found)))))))

(= (codex:tool-name-json-object-field (JsonObject $pairs) $key)
   (codex:tool-name-json-object-field-from
     $pairs
     $key
     (codex:tool-name-json-field-missing)))

(= (codex:tool-name-json-required-string $object $key)
   (case (codex:tool-name-json-object-field $object $key)
     (((CodexToolNameJsonFieldMissing)
       (codex:tool-name-parse-error
         (format-args "missing field `{}`" ($key))))
      ((CodexToolNameJsonFieldValue (JsonString $text))
       (codex:tool-name-parse-ok $text))
      ((CodexToolNameJsonFieldValue $other)
       (codex:tool-name-parse-error
         (format-args "invalid type for field `{}`: expected string" ($key)))))))

(= (codex:tool-name-json-optional-string $object $key)
   (case (codex:tool-name-json-object-field $object $key)
     (((CodexToolNameJsonFieldMissing)
       (codex:tool-name-parse-ok CodexAbsent))
      ((CodexToolNameJsonFieldValue JsonNull)
       (codex:tool-name-parse-ok CodexAbsent))
      ((CodexToolNameJsonFieldValue (JsonString $text))
       (codex:tool-name-parse-ok $text))
      ((CodexToolNameJsonFieldValue $other)
       (codex:tool-name-parse-error
         (format-args "invalid type for field `{}`: expected string or null" ($key)))))))

(= (codex:tool-name-from-json $json)
   (case $json
     (((JsonObject $pairs)
       (let $object (JsonObject $pairs)
         (case (codex:tool-name-json-required-string $object "name")
           (((CodexToolNameParseOk $name)
             (case (codex:tool-name-json-optional-string $object "namespace")
               (((CodexToolNameParseOk $namespace)
                 (codex:tool-name-parse-ok
                   (codex:tool-name $namespace $name)))
                ((CodexToolNameParseError $message)
                 (codex:tool-name-parse-error $message)))))
            ((CodexToolNameParseError $message)
             (codex:tool-name-parse-error $message))))))
      ($other
       (codex:tool-name-parse-error "invalid type: expected object")))))
