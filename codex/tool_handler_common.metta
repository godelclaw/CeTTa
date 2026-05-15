; Narrow Rust-faithful shared tool-handler helpers.
;
; This ports the visible pure helper slice from:
; - openai-codex/codex-rs/core/src/tools/handlers/mod.rs
;
; Covered in this increment:
; - parse_arguments object-boundary helper
; - shared `failed to parse function arguments:` prefix helper
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust deserializes directly into a target type `T`. The current CeTTa port
;   exposes the shared boundary at the parsed JSON-object layer, and the
;   concrete handler modules keep their existing typed field decoders on top of
;   that boundary.

!(import! &self json)
!(import! &self str)

(= (codex:function-arguments-parse-error-prefix)
   "failed to parse function arguments: ")

(= (codex:function-arguments-parse-error-message $message)
   (str-concat
     (codex:function-arguments-parse-error-prefix)
     $message))

(= (codex:parse-function-arguments-object-ok $object)
   (CodexParseFunctionArgumentsObjectOk $object))

(= (codex:parse-function-arguments-object-error $message)
   (CodexParseFunctionArgumentsObjectError $message))

(= (codex:parse-function-arguments-object $arguments)
   (case (json-parse $arguments)
     (((JsonObject $pairs)
       (codex:parse-function-arguments-object-ok (JsonObject $pairs)))
      ($other
       (codex:parse-function-arguments-object-error
         "invalid type: expected object")))))
