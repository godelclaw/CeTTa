; Rust-faithful AGENTS.md discovery and instruction assembly helper slice.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/agents_md.rs
;   - DEFAULT_AGENTS_MD_FILENAME
;   - LOCAL_AGENTS_MD_FILENAME
;   - AGENTS_MD_SEPARATOR
;   - load_global_instructions filename priority
;   - candidate_filenames
;   - agents_md_paths path ordering and per-directory candidate preference
;   - user_instructions concatenation over already-materialized optional
;     sections
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust canonicalizes cwd with dunce::canonicalize when possible, then falls
;   back to the original path. The current CeTTa path layer exposes lexical
;   normalization rather than symlink-aware canonicalization, so this slice uses
;   path-normalize. A future filesystem canonicalization layer must replace
;   agents-md-normalized-cwd with the Rust fallback behavior.
; - Rust derives project_root_markers by merging non-project config layers and
;   parsing TOML before discovery. This slice accepts the already-resolved
;   marker list, using CodexAbsent to mean Rust's default marker list.
; - Rust's user_instructions also calls render_js_repl_instructions and appends
;   include_str!("../hierarchical_agents_message.md") when feature flags are
;   enabled. This slice ports the exact concatenation algorithm over
;   already-materialized optional section strings; exact prompt generation lands
;   in a separate prompt-text slice.

!(import! &self codex:project_root_markers)
!(import! &self fs)
!(import! &self list)
!(import! &self path)
!(import! &self str)

(= (codex:agents-md-default-filename)
   "AGENTS.md")

(= (codex:agents-md-local-filename)
   "AGENTS.override.md")

(= (codex:agents-md-separator)
   "\n\n--- project-doc ---\n\n")

(= (codex:agents-md-loaded $contents $path)
   (CodexAgentsMdLoaded $contents $path))

(= (codex:agents-md-loaded-contents
      (CodexAgentsMdLoaded $contents $path))
   $contents)

(= (codex:agents-md-loaded-path
      (CodexAgentsMdLoaded $contents $path))
   $path)

(= (codex:agents-md-text-starts-with $text $prefix)
   (let $text-len (str-length $text)
     (let $prefix-len (str-length $prefix)
       (if (< $text-len $prefix-len)
           False
           (== (str-slice $text 0 $prefix-len) $prefix)))))

(= (codex:agents-md-text-ends-with $text $suffix)
   (let $text-len (str-length $text)
     (let $suffix-len (str-length $suffix)
       (if (< $text-len $suffix-len)
           False
           (== (str-slice $text (- $text-len $suffix-len) $text-len)
               $suffix)))))

(= (codex:agents-md-list-contains $items $item)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head $item)
               True
               (codex:agents-md-list-contains $tail $item))))))

(= (codex:agents-md-add-candidate-filename $names $candidate)
   (if (== $candidate "")
       $names
       (if (codex:agents-md-list-contains $names $candidate)
           $names
           (list:cons $candidate $names))))

(= (codex:agents-md-candidate-filenames-fold $names-reversed $fallbacks)
   (if (== $fallbacks ())
       (codex:agents-md-reverse $names-reversed)
       (let $head (list:first $fallbacks)
         (let $tail (list:rest $fallbacks)
           (codex:agents-md-candidate-filenames-fold
             (codex:agents-md-add-candidate-filename
               $names-reversed
               $head)
             $tail)))))

(= (codex:agents-md-reverse $items)
   (codex:agents-md-reverse-acc $items ()))

(= (codex:agents-md-reverse-acc $items $acc)
   (if (== $items ())
       $acc
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (codex:agents-md-reverse-acc
             $tail
             (list:cons $head $acc))))))

(= (codex:agents-md-candidate-filenames $fallbacks)
   (codex:agents-md-candidate-filenames-fold
     ("AGENTS.md" "AGENTS.override.md")
     $fallbacks))

(= (codex:agents-md-global-candidate-filenames)
   ("AGENTS.override.md" "AGENTS.md"))

(= (codex:agents-md-child-path $base $name)
   (if (== $base "/")
       (str-concat "/" $name)
       (if (codex:agents-md-text-ends-with $base "/")
           (str-concat $base $name)
           (str-concat (str-concat $base "/") $name))))

(= (codex:agents-md-is-file-path $path)
   (case (fs-path-kind $path)
     (("file" True)
      ($other False))))

(= (codex:agents-md-load-global-instructions-from-names
      $codex-dir
      $candidate-names)
   (if (== $candidate-names ())
       CodexAbsent
       (let $name (list:first $candidate-names)
         (let $tail (list:rest $candidate-names)
           (let $candidate (codex:agents-md-child-path $codex-dir $name)
             (if (not (codex:agents-md-is-file-path $candidate))
                 (codex:agents-md-load-global-instructions-from-names
                   $codex-dir
                   $tail)
                 (case (fs-read-text $candidate)
                   (((Error $source $message)
                     (codex:agents-md-load-global-instructions-from-names
                       $codex-dir
                       $tail))
                    ($contents
                     (let $trimmed (str-trim $contents)
                       (if (== $trimmed "")
                           (codex:agents-md-load-global-instructions-from-names
                             $codex-dir
                             $tail)
                           (codex:agents-md-loaded
                             $trimmed
                             $candidate))))))))))))

(= (codex:agents-md-load-global-instructions $codex-dir)
   (if (== $codex-dir CodexAbsent)
       CodexAbsent
       (codex:agents-md-load-global-instructions-from-names
         $codex-dir
         (codex:agents-md-global-candidate-filenames))))

(= (codex:agents-md-normalized-cwd $cwd)
   (path-normalize $cwd))

(= (codex:agents-md-resolved-project-root-markers $markers)
   (if (== $markers CodexAbsent)
       (codex:default-project-root-markers)
       $markers))

(= (codex:agents-md-search-dirs-from-cwd-to-root
      $cursor
      $root
      $acc)
   (let $next-acc (list:cons $cursor $acc)
     (if (== $cursor $root)
         $next-acc
         (let $parent (path-dirname $cursor)
           (if (== $parent $cursor)
               $next-acc
               (codex:agents-md-search-dirs-from-cwd-to-root
                 $parent
                 $root
                 $next-acc))))))

(= (codex:agents-md-search-dirs $cwd $project-root-markers)
   (let $dir (codex:agents-md-normalized-cwd $cwd)
     (let $markers
       (codex:agents-md-resolved-project-root-markers $project-root-markers)
       (let $root (codex:find-project-root $dir $markers)
         (codex:agents-md-search-dirs-from-cwd-to-root
           $dir
           $root
           ())))))

(= (codex:agents-md-first-file-in-dir $dir $candidate-names)
   (if (== $candidate-names ())
       CodexAbsent
       (let $name (list:first $candidate-names)
         (let $tail (list:rest $candidate-names)
           (let $candidate (codex:agents-md-child-path $dir $name)
             (if (codex:agents-md-is-file-path $candidate)
                 $candidate
                 (codex:agents-md-first-file-in-dir $dir $tail)))))))

(= (codex:agents-md-paths-from-dirs $dirs $candidate-names)
   (if (== $dirs ())
       ()
       (let $dir (list:first $dirs)
         (let $tail (list:rest $dirs)
           (let $candidate
             (codex:agents-md-first-file-in-dir $dir $candidate-names)
             (let $tail-paths
               (codex:agents-md-paths-from-dirs $tail $candidate-names)
               (if (== $candidate CodexAbsent)
                   $tail-paths
                   (list:cons $candidate $tail-paths))))))))

(= (codex:agents-md-paths
      $cwd
      $project-doc-max-bytes
      $project-root-markers
      $project-doc-fallback-filenames)
   (if (== $project-doc-max-bytes 0)
       ()
       (codex:agents-md-paths-from-dirs
         (codex:agents-md-search-dirs $cwd $project-root-markers)
         (codex:agents-md-candidate-filenames
           $project-doc-fallback-filenames))))

(= (codex:agents-md-append-project-docs $output $agents-md-docs)
   (if (== $agents-md-docs CodexAbsent)
       $output
       (if (== $output "")
           $agents-md-docs
           (str-concat
             $output
             (str-concat
               (codex:agents-md-separator)
               $agents-md-docs)))))

(= (codex:agents-md-append-plain-section $output $section)
   (if (== $section CodexAbsent)
       $output
       (if (== $output "")
           $section
           (str-concat
             $output
             (str-concat "\n\n" $section)))))

(= (codex:agents-md-compose-user-instructions
      $user-instructions
      $agents-md-docs
      $js-repl-section
      $hierarchical-agents-message)
   (let $base
     (if (== $user-instructions CodexAbsent)
         ""
         $user-instructions)
     (let $with-project-docs
       (codex:agents-md-append-project-docs $base $agents-md-docs)
       (let $with-js-repl
         (codex:agents-md-append-plain-section
           $with-project-docs
           $js-repl-section)
         (let $output
           (codex:agents-md-append-plain-section
             $with-js-repl
             $hierarchical-agents-message)
           (if (== $output "")
               CodexAbsent
               $output))))))
