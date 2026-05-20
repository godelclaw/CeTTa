; Rust-faithful config key alias normalization slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/config/src/key_aliases.rs
;
; Covered in this increment:
; - CONFIG_KEY_ALIASES
; - normalize_key_aliases
; - normalized_with_key_aliases
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust operates on `toml::Value` and mutable `toml::map::Map` tables. This
;   CeTTa slice uses the existing JsonValue constructors as the
;   already-materialized table/array boundary; a future TOML parser layer must
;   feed equivalent unique-key table pairs.
; - Rust's table map has unique keys. If duplicate pairs are supplied directly
;   to this pure boundary, this slice removes all legacy-key pairs because that
;   is the closest deterministic projection of `table.remove`.

!(import! &self json)
!(import! &self list)

(= (codex:config-key-alias $table-path $legacy-key $canonical-key)
   (CodexConfigKeyAlias $table-path $legacy-key $canonical-key))

(= (codex:config-key-alias-table-path
      (CodexConfigKeyAlias $table-path $legacy-key $canonical-key))
   $table-path)

(= (codex:config-key-alias-legacy-key
      (CodexConfigKeyAlias $table-path $legacy-key $canonical-key))
   $legacy-key)

(= (codex:config-key-alias-canonical-key
      (CodexConfigKeyAlias $table-path $legacy-key $canonical-key))
   $canonical-key)

(= (codex:config-key-aliases)
   ((CodexConfigKeyAlias
      ("memories")
      "no_memories_if_mcp_or_web_search"
      "disable_on_external_context")))

(= (codex:config-key-alias-object-value $pairs $key)
   (case $pairs
     ((() CodexAbsent)
      ($non-empty-pairs
       (let $head (list:first $non-empty-pairs)
         (let $tail (list:rest $non-empty-pairs)
           (case $head
             (((JsonPair $pair-key $value)
               (if (== $pair-key $key)
                   $value
                   (codex:config-key-alias-object-value $tail $key)))
              ($other
               (codex:config-key-alias-object-value $tail $key))))))))))

(= (codex:config-key-alias-object-has-key $pairs $key)
   (if (== (codex:config-key-alias-object-value $pairs $key) CodexAbsent)
       False
       True))

(= (codex:config-key-alias-remove-key $pairs $key)
   (case $pairs
     ((() ())
      ($non-empty-pairs
       (let $head (list:first $non-empty-pairs)
         (let $tail (list:rest $non-empty-pairs)
           (case (codex:config-key-alias-remove-key $tail $key)
             (($rest
               (case $head
                 (((JsonPair $pair-key $value)
                   (if (== $pair-key $key)
                       $rest
                       (list:cons $head $rest)))
                  ($other (list:cons $head $rest)))))))))))))

(= (codex:config-key-alias-append-pair $pairs $key $value)
   (list:append $pairs ((JsonPair $key $value))))

(= (codex:config-key-alias-apply-one $path $pairs $alias)
   (if (== $path (codex:config-key-alias-table-path $alias))
       (let $legacy-key (codex:config-key-alias-legacy-key $alias)
         (let $legacy-value
           (codex:config-key-alias-object-value $pairs $legacy-key)
           (if (== $legacy-value CodexAbsent)
               $pairs
               (let $canonical-key
                 (codex:config-key-alias-canonical-key $alias)
                 (let $without-legacy
                   (codex:config-key-alias-remove-key $pairs $legacy-key)
                   (if (codex:config-key-alias-object-has-key
                         $without-legacy
                         $canonical-key)
                       $without-legacy
                       (codex:config-key-alias-append-pair
                         $without-legacy
                         $canonical-key
                         $legacy-value)))))))
       $pairs))

(= (codex:normalize-key-aliases-list $path $pairs $aliases)
   (case $aliases
     ((() $pairs)
      ($non-empty-aliases
       (let $alias (list:first $non-empty-aliases)
         (let $tail (list:rest $non-empty-aliases)
           (codex:normalize-key-aliases-list
             $path
             (codex:config-key-alias-apply-one $path $pairs $alias)
             $tail)))))))

(= (codex:normalize-key-aliases $path $pairs)
   (codex:normalize-key-aliases-list
     $path
     $pairs
     (codex:config-key-aliases)))

(= (codex:config-key-aliases-normalize-pairs $pairs $path)
   (case $pairs
     ((() ())
      ($non-empty-pairs
       (let $head (list:first $non-empty-pairs)
         (let $tail (list:rest $non-empty-pairs)
           (case (codex:config-key-aliases-normalize-pairs $tail $path)
             (($rest
               (case $head
                 (((JsonPair $key $child)
                   (list:cons
                     (JsonPair
                       $key
                       (codex:normalized-with-key-aliases-at-path
                         $child
                         (list:append $path ($key))))
                     $rest))
                  ($other (list:cons $head $rest)))))))))))))

(= (codex:config-key-aliases-normalize-array $items $path)
   (case $items
     ((() ())
      ($non-empty-items
       (let $head (list:first $non-empty-items)
         (let $tail (list:rest $non-empty-items)
           (case (codex:config-key-aliases-normalize-array $tail $path)
             (($rest
               (list:cons
                 (codex:normalized-with-key-aliases-at-path $head $path)
                 $rest))))))))))

(= (codex:normalized-with-key-aliases-at-path $value $path)
   (case $value
     (((JsonObject $pairs)
       (JsonObject
         (codex:normalize-key-aliases
           $path
           (codex:config-key-aliases-normalize-pairs $pairs $path))))
      ((JsonArray $items)
       (JsonArray
         (codex:config-key-aliases-normalize-array $items $path)))
      ((JsonString $text) (JsonString $text))
      ((JsonNumber $text) (JsonNumber $text))
      ((JsonBool $bool-value) (JsonBool $bool-value))
      (JsonNull JsonNull))))

(= (codex:normalized-with-key-aliases $value)
   (codex:normalized-with-key-aliases-at-path $value ()))
