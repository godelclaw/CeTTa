; Pure Rust-faithful environment display helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/utils/cli/src/format_env_display.rs
;
; Covered in this increment:
; - format_env_display
;
; Required CeTTa representation notes for audit:
; - Rust receives `Option<&HashMap<String, String>>` plus an env-var slice.
;   This helper receives `CodexAbsent` for `None`, or a list of
;   `CodexFormatEnvDisplayEntry` values for `Some(HashMap)`. The map values
;   are retained in the constructor shape but ignored exactly as Rust ignores
;   them for display. Duplicate keys are outside Rust HashMap semantics.

!(import! &self list)
!(import! &self str)

(= (codex:format-env-display-empty-marker)
   "-")

(= (codex:format-env-display-redacted-value)
   "*****")

(= (codex:format-env-display-entry $key $value)
   (CodexFormatEnvDisplayEntry $key $value))

(= (codex:format-env-display-entry-key
      (CodexFormatEnvDisplayEntry $key $value))
   $key)

(= (codex:format-env-display-entry-value
      (CodexFormatEnvDisplayEntry $key $value))
   $value)

(= (codex:format-env-display-entry-keys ())
   ())

(= (codex:format-env-display-entry-keys $entries)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (list:append
         ((codex:format-env-display-entry-key $head))
         (codex:format-env-display-entry-keys $tail)))))

(= (codex:format-env-display-mask-name $name)
   (str-concat
     (str-concat $name "=")
     (codex:format-env-display-redacted-value)))

(= (codex:format-env-display-mask-names ())
   ())

(= (codex:format-env-display-mask-names $names)
   (let $head (list:first $names)
     (let $tail (list:rest $names)
       (list:append
         ((codex:format-env-display-mask-name $head))
         (codex:format-env-display-mask-names $tail)))))

(= (codex:format-env-display-env-parts $entries)
   (if (or (== $entries CodexAbsent)
           (== $entries ()))
       ()
       (let $keys (once (eval (codex:format-env-display-entry-keys $entries)))
         (case (sort-strings $keys)
           (($sorted-keys
             (codex:format-env-display-mask-names $sorted-keys)))))))

(= (codex:format-env-display-parts $env $env-vars)
   (list:append
     (codex:format-env-display-env-parts $env)
     (codex:format-env-display-mask-names $env-vars)))

(= (codex:format-env-display $env $env-vars)
   (let $parts (codex:format-env-display-parts $env $env-vars)
     (if (== $parts ())
         (codex:format-env-display-empty-marker)
         (str-join ", " $parts))))
