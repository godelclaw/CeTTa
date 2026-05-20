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
;   - read_agents_md successful-path loading, truncation budget, whitespace
;     skipping, and root-to-cwd concatenation
;   - render_js_repl_instructions
;   - hierarchical_agents_message.md feature-gated append
;   - instruction_sources source ordering
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
; - Rust reads project docs as bytes, truncates the byte buffer, and converts
;   with String::from_utf8_lossy. The current CeTTa fs layer exposes text reads
;   only, so agents-md-read-docs uses byte-counting text strings and truncates
;   at UTF-8 character boundaries. This is exact for ASCII project docs; a
;   future byte-vector fs API should replace the truncation step to preserve
;   Rust's replacement-character behavior for invalid or partial UTF-8.
; - Rust distinguishes NotFound from other read errors and bubbles unexpected
;   I/O errors to the caller. The current CeTTa fs-read-text surface exposes an
;   opaque Error atom without io::ErrorKind, so read failures are skipped like
;   Rust's NotFound branch until a richer filesystem Result layer exists.
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

(= (codex:agents-md-js-repl-instructions-base)
   (str-join
     ""
     ("## JavaScript REPL (Node)\n"
      "- Use `js_repl` for Node-backed JavaScript with top-level await in a persistent kernel.\n"
      "- `js_repl` is a freeform/custom tool. Direct `js_repl` calls must send raw JavaScript tool input (optionally with first-line `// codex-js-repl: timeout_ms=15000`). Do not wrap code in JSON (for example `{\"code\":\"...\"}`), quotes, or markdown code fences.\n"
      "- Helpers: `codex.cwd`, `codex.homeDir`, `codex.tmpDir`, `codex.tool(name, args"
      "?)`, and `codex.emitImage(imageLike)`.\n"
      "- `codex.tool` executes a normal tool call and resolves to the raw tool output object. Use it for shell and non-shell tools alike. Nested tool outputs stay inside JavaScript unless you emit them explicitly.\n"
      "- `codex.emitImage(...)` adds one image to the outer `js_repl` function output each time you call it, so you can call it multiple times to emit multiple images. It accepts a data URL, a single `input_image` item, an object like `{ bytes, mimeType }` containing encoded PNG/JPEG/WebP/GIF bytes, or a raw tool response object with exactly one image and no text. It rejects mixed text-and-image content.\n"
      "- `codex.tool(...)` and `codex.emitImage(...)` keep stable helper identities across cells. Saved references and persisted objects can reuse them in later cells, but async callbacks that fire after a cell finishes still fail because no exec is active.\n"
      "- Request full-resolution image processing with `detail: \"original\"` only when the `view_image` tool schema includes a `detail` argument. The same availability applies to `codex.emitImage(...)`: if `view_image.detail` is present, you may also pass `detail: \"original\"` there. Use this when high-fidelity image perception or precise localization is needed, especially for CUA agents.\n"
      "- Raw MCP image blocks can request the same behavior by returning `_meta: { \"codex/imageDetail\": \"original\" }` on the image content item.\n"
      "- Example of sharing an in-memory Playwright screenshot: `await codex.emitImage({ bytes: await page.screenshot({ type: \"jpeg\", quality: 85 }), mimeType: \"image/jpeg\", detail: \"original\" })`.\n"
      "- Example of sharing a local image tool result: `await codex.emitImage(codex.tool(\"view_image\", { path: \"/absolute/path\", detail: \"original\" }))`.\n"
      "- When encoding an image to send with `codex.emitImage(...)` or `view_image`, prefer JPEG at about 85 quality when lossy compression is acceptable; use PNG when transparency or lossless detail matters. Smaller uploads are faster and less likely to hit size limits.\n"
      "- Top-level bindings persist across cells. If a cell throws, prior bindings remain available and bindings that finished initializing before the throw often remain usable in later cells. For code you plan to reuse across cells, prefer declaring or assigning it in direct top-level statements before operations that might throw. If you hit `SyntaxError: Identifier 'x' has already been declared`, first reuse the existing binding, reassign a previously declared `let`, or pick a new descriptive name. Use `{ ... }` only for a short temporary block when you specifically need local scratch names; do not wrap an entire cell in block scope if you want those names reusable later. Reset the kernel with `js_repl_reset` only when you need a clean state.\n"
      "- Top-level static import declarations (for example `import x from \"./file.js\"`) are currently unsupported in `js_repl`; use dynamic imports with `await import(\"pkg\")`, `await import(\"./file.js\")`, or `await import(\"/abs/path/file.mjs\")` instead. Imported local files must be ESM `.js`/`.mjs` files and run in the same REPL VM context. Bare package imports always resolve from REPL-global search roots (`CODEX_JS_REPL_NODE_MODULE_DIRS`, then cwd), not relative to the imported file location. Local files may statically import only other local relative/absolute/`file://` `.js`/`.mjs` files; package and builtin imports from local files must stay dynamic. `import.meta.resolve()` returns importable strings such as `file://...`, bare package names, and `node:...` specifiers. Local file modules reload between execs, while top-level bindings persist until `js_repl_reset`.\n")))

(= (codex:agents-md-js-repl-tools-only-instructions)
   (str-join
     ""
     ("- Do not call tools directly; use `js_repl` + `codex.tool(...)` for all tool calls, including shell commands.\n"
      "- MCP tools (if any) can also be called by name via `codex.tool(...)`.\n")))

(= (codex:agents-md-js-repl-final-instruction)
   "- Avoid direct access to `process.stdout` / `process.stderr` / `process.stdin`; it can corrupt the JSON line protocol. Use `console.log`, `codex.tool(...)`, and `codex.emitImage(...)`.")

(= (codex:agents-md-hierarchical-agents-message)
   (str-join
     "\n\n"
     ("Files called AGENTS.md commonly appear in many places inside a container - at \"/\", in \"~\", deep within git repositories, or in any other directory; their location is not limited to version-controlled folders."
      "Their purpose is to pass along human guidance to you, the agent. Such guidance can include coding standards, explanations of the project layout, steps for building or testing, and even wording that must accompany a GitHub pull-request description produced by the agent; all of it is to be followed."
      "Each AGENTS.md governs the entire directory that contains it and every child directory beneath that point. Whenever you change a file, you have to comply with every AGENTS.md whose scope covers that file. Naming conventions, stylistic rules and similar directives are restricted to the code that falls inside that scope unless the document explicitly states otherwise."
      "When two AGENTS.md files disagree, the one located deeper in the directory structure overrides the higher-level file, while instructions given directly in the prompt by the system, developer, or user outrank any AGENTS.md content.\n")))

(= (codex:agents-md-render-js-repl-instructions
      $js-repl-enabled
      $js-repl-tools-only-enabled)
   (if (== $js-repl-enabled True)
       (let $section (codex:agents-md-js-repl-instructions-base)
         (let $with-tools-only
           (if (== $js-repl-tools-only-enabled True)
               (str-concat
                 $section
                 (codex:agents-md-js-repl-tools-only-instructions))
               $section)
           (str-concat
             $with-tools-only
             (codex:agents-md-js-repl-final-instruction))))
       CodexAbsent))

(= (codex:agents-md-render-hierarchical-agents-message
      $child-agents-md-enabled)
   (if (== $child-agents-md-enabled True)
       (codex:agents-md-hierarchical-agents-message)
       CodexAbsent))

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

(= (codex:agents-md-list-append () $rhs)
   $rhs)

(= (codex:agents-md-list-append $lhs $rhs)
   (let $head (list:first $lhs)
     (let $tail (list:rest $lhs)
       (list:cons
         $head
         (codex:agents-md-list-append $tail $rhs)))))

(= (codex:agents-md-global-instruction-source-paths $codex-dir)
   (let $loaded (codex:agents-md-load-global-instructions $codex-dir)
     (if (== $loaded CodexAbsent)
         ()
         ((codex:agents-md-loaded-path $loaded)))))

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

(= (codex:agents-md-instruction-sources
      $codex-dir
      $cwd
      $project-doc-max-bytes
      $project-root-markers
      $project-doc-fallback-filenames)
   (codex:agents-md-list-append
     (codex:agents-md-global-instruction-source-paths $codex-dir)
     (codex:agents-md-paths
       $cwd
       $project-doc-max-bytes
       $project-root-markers
       $project-doc-fallback-filenames)))

(= (codex:agents-md-read-docs-finish $parts-reversed)
   (if (== $parts-reversed ())
       CodexAbsent
       (str-join
         "\n\n"
         (codex:agents-md-reverse $parts-reversed))))

(= (codex:agents-md-read-docs-consumed-bytes $raw-size $remaining)
   (if (> $raw-size $remaining)
       $remaining
       $raw-size))

(= (codex:agents-md-read-docs-slice $raw $raw-size $remaining)
   (if (> $raw-size $remaining)
       (str-take-bytes-at-char-boundary $raw $remaining)
       $raw))

(= (codex:agents-md-read-docs-after-read
      $tail
      $remaining
      $parts-reversed
      (Error $source $message))
   (codex:agents-md-read-docs-from-paths
     $tail
     $remaining
     $parts-reversed))

(= (codex:agents-md-read-docs-after-read
      $tail
      $remaining
      $parts-reversed
      $raw)
   (let $raw-size (str-length $raw)
     (let $text
       (codex:agents-md-read-docs-slice $raw $raw-size $remaining)
       (if (== (str-trim $text) "")
           (codex:agents-md-read-docs-from-paths
             $tail
             $remaining
             $parts-reversed)
           (codex:agents-md-read-docs-from-paths
             $tail
             (- $remaining
                (codex:agents-md-read-docs-consumed-bytes
                  $raw-size
                  $remaining))
             (list:cons $text $parts-reversed))))))

(= (codex:agents-md-read-docs-from-paths
      $paths
      $remaining
      $parts-reversed)
   (if (== $remaining 0)
       (codex:agents-md-read-docs-finish $parts-reversed)
       (if (== $paths ())
           (codex:agents-md-read-docs-finish $parts-reversed)
           (let $path (list:first $paths)
             (let $tail (list:rest $paths)
               (if (not (codex:agents-md-is-file-path $path))
                   (codex:agents-md-read-docs-from-paths
                     $tail
                     $remaining
                     $parts-reversed)
                   (codex:agents-md-read-docs-after-read
                     $tail
                     $remaining
                     $parts-reversed
                     (fs-read-text $path))))))))

(= (codex:agents-md-read-docs
      $cwd
      $project-doc-max-bytes
      $project-root-markers
      $project-doc-fallback-filenames)
   (if (== $project-doc-max-bytes 0)
       CodexAbsent
       (codex:agents-md-read-docs-from-paths
         (codex:agents-md-paths
           $cwd
           $project-doc-max-bytes
           $project-root-markers
           $project-doc-fallback-filenames)
         $project-doc-max-bytes
         ())))

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

(= (codex:agents-md-compose-configured-user-instructions
      $user-instructions
      $agents-md-docs
      $js-repl-enabled
      $js-repl-tools-only-enabled
      $child-agents-md-enabled)
   (codex:agents-md-compose-user-instructions
     $user-instructions
     $agents-md-docs
     (codex:agents-md-render-js-repl-instructions
       $js-repl-enabled
       $js-repl-tools-only-enabled)
     (codex:agents-md-render-hierarchical-agents-message
       $child-agents-md-enabled)))

(= (codex:agents-md-user-instructions
      $user-instructions
      $cwd
      $project-doc-max-bytes
      $project-root-markers
      $project-doc-fallback-filenames
      $js-repl-enabled
      $js-repl-tools-only-enabled
      $child-agents-md-enabled)
   (codex:agents-md-compose-configured-user-instructions
     $user-instructions
     (codex:agents-md-read-docs
       $cwd
       $project-doc-max-bytes
       $project-root-markers
       $project-doc-fallback-filenames)
     $js-repl-enabled
     $js-repl-tools-only-enabled
     $child-agents-md-enabled))
