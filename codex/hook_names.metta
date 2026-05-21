; Rust-faithful hook-facing tool-name slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/tools/hook_names.rs
;
; Covered in this increment:
; - HookToolName record shape
; - new / apply_patch / bash constructors
; - name and matcher_aliases accessors
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust keeps this type crate-private. The CeTTa port exposes direct
;   constructors/accessors so adjacent pure slices can share the exact same
;   value model before the full Rust registry/runtime layer is available.
; - Rust hook_runtime serializes `name()` and `matcher_aliases()` into separate
;   request fields. Existing CeTTa hook payload surfaces also expose a compact
;   JSON projection of this value; the projection below is only that local
;   carrier shape, not a replacement for the runtime request serializer.

!(import! &self json)

(= (codex:hook-tool-name $name $matcher-aliases)
   (CodexHookToolName $name $matcher-aliases))

(= (codex:hook-tool-name-new $name)
   (codex:hook-tool-name $name ()))

(= (codex:hook-tool-name-apply-patch)
   (codex:hook-tool-name "apply_patch" ("Write" "Edit")))

(= (codex:hook-tool-name-bash)
   (codex:hook-tool-name-new "Bash"))

(= (codex:hook-tool-name-name
      (CodexHookToolName $name $matcher-aliases))
   $name)

(= (codex:hook-tool-name-matcher-aliases
      (CodexHookToolName $name $matcher-aliases))
   $matcher-aliases)

(= (codex:hook-tool-name-json
      (CodexHookToolName $name $matcher-aliases))
   (JsonObject
     ((JsonPair "name" (JsonString $name))
      (JsonPair "matcher_aliases"
        (JsonArray
          (eval
            (map-atom
              $matcher-aliases
              $alias
              (JsonString $alias))))))))
