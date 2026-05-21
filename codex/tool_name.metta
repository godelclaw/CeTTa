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
