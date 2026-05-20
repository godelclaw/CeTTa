; Rust-faithful project-root marker helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/config/src/project_root_markers.rs
; - openai-codex/codex-rs/core/src/config_loader/mod.rs
;   - find_project_root
;
; Covered in this increment:
; - default_project_root_markers
; - project_root_markers_from_config over an already-materialized value
; - marker-based project root search through cwd ancestors
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust receives a `toml::Value` from the config loader. This CeTTa slice uses
;   the existing JsonValue constructors as the already-materialized table/array
;   boundary; a future TOML parser layer must preserve these visible values.
; - Rust probes metadata through `ExecutorFileSystem::get_metadata`. This CeTTa
;   slice uses `fs-path-kind` for the same success/failure decision at the local
;   runtime filesystem boundary.

!(import! &self fs)
!(import! &self json)
!(import! &self list)
!(import! &self path)
!(import! &self str)

(= (codex:project-root-markers-ok $markers)
   (CodexProjectRootMarkersOk $markers))

(= (codex:project-root-markers-error $message)
   (CodexProjectRootMarkersError $message))

(= (codex:project-root-markers-ok-value
      (CodexProjectRootMarkersOk $markers))
   $markers)

(= (codex:project-root-markers-error-message
      (CodexProjectRootMarkersError $message))
   $message)

(= (codex:project-root-markers-invalid-message)
   "project_root_markers must be an array of strings")

(= (codex:default-project-root-markers)
   (".git"))

(= (codex:project-root-text-ends-with $text $suffix)
   (let $text-len (str-length $text)
     (let $suffix-len (str-length $suffix)
       (if (< $text-len $suffix-len)
           False
           (== (str-slice $text (- $text-len $suffix-len) $text-len)
               $suffix)))))

(= (codex:project-root-markers-from-json-array $items)
   (case $items
     ((()
       (codex:project-root-markers-ok ()))
      ($non-empty-items
       (let $head (list:first $non-empty-items)
         (let $tail (list:rest $non-empty-items)
           (case $head
             (((JsonString $marker)
               (case (codex:project-root-markers-from-json-array $tail)
                 (((CodexProjectRootMarkersOk $markers)
                   (codex:project-root-markers-ok
                     (list:cons $marker $markers)))
                  ((CodexProjectRootMarkersError $message)
                   (codex:project-root-markers-error $message)))))
              ($other
               (codex:project-root-markers-error
                (codex:project-root-markers-invalid-message)))))))))))

(= (codex:project-root-markers-from-config $config)
   (case $config
     (((JsonObject $pairs)
       (case (json-object-get (JsonObject $pairs) "project_root_markers")
         ((Empty (codex:project-root-markers-ok CodexAbsent))
          (JsonNull (codex:project-root-markers-ok CodexAbsent))
          ((JsonArray $entries)
           (codex:project-root-markers-from-json-array $entries))
          ($other
           (codex:project-root-markers-error
             (codex:project-root-markers-invalid-message))))))
      ($other (codex:project-root-markers-ok CodexAbsent)))))

(= (codex:project-root-markers-child-path $base $marker)
   (if (== $base "/")
       (str-concat "/" $marker)
       (if (codex:project-root-text-ends-with $base "/")
           (str-concat $base $marker)
           (str-concat (str-concat $base "/") $marker))))

(= (codex:project-root-marker-path-exists $path)
   (case (fs-path-kind $path)
     (((Error $source ("stat" $message)) False)
      ("missing" False)
      ($kind True))))

(= (codex:project-root-any-marker-exists $ancestor $markers)
   (case $markers
     ((() False)
      ($non-empty-markers
       (let $marker (list:first $non-empty-markers)
         (let $tail (list:rest $non-empty-markers)
           (if (codex:project-root-marker-path-exists
                 (codex:project-root-markers-child-path $ancestor $marker))
               True
               (codex:project-root-any-marker-exists $ancestor $tail))))))))

(= (codex:project-root-ancestors-normalized $path)
   (if (== $path "/")
       ("/")
       (let $parent (path-dirname $path)
         (if (== $parent $path)
             ($path)
             (list:cons
               $path
               (codex:project-root-ancestors-normalized $parent))))))

(= (codex:project-root-ancestors $cwd)
   (codex:project-root-ancestors-normalized (path-normalize $cwd)))

(= (codex:project-root-find-in-ancestors $ancestors $markers $fallback-cwd)
   (case $ancestors
     ((() $fallback-cwd)
      ($non-empty-ancestors
       (let $ancestor (list:first $non-empty-ancestors)
         (let $tail (list:rest $non-empty-ancestors)
           (if (codex:project-root-any-marker-exists $ancestor $markers)
               $ancestor
               (codex:project-root-find-in-ancestors
                 $tail
                 $markers
                 $fallback-cwd))))))))

(= (codex:find-project-root $cwd $project-root-markers)
   (if (== $project-root-markers ())
       $cwd
       (let $normalized-cwd (path-normalize $cwd)
         (codex:project-root-find-in-ancestors
           (codex:project-root-ancestors-normalized $normalized-cwd)
           $project-root-markers
           $normalized-cwd))))
