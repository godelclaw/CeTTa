; Rust-faithful pure util helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/util.rs
;
; Covered in this increment:
; - resolve_path
; - normalize_thread_name
; - resume_command
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `Path`/`PathBuf` and platform-specific `Path::is_absolute`.
;   This pure CeTTa slice operates on Unix-style path strings, which matches
;   the current Linux validation environment and preserves `PathBuf::join`
;   behavior without lexical normalization for relative paths.
; - Rust uses `Option<&str>` / `Option<ThreadId>`. This slice uses
;   `CodexAbsent` for absent values and expects an already-rendered thread id
;   string at this pure boundary.
; - Rust `backoff`, tracing feedback tags, and `error_or_panic` require random,
;   tracing, or build-mode runtime state. They are intentionally out of scope
;   for this deterministic slice.

!(import! &self shell)
!(import! &self str)

(= (codex:util-is-empty-string $text)
   (== $text ""))

(= (codex:util-starts-with-dash $text)
   (if (== (str-length $text) 0)
       False
       (== (str-slice $text 0 1) "-")))

(= (codex:util-is-unix-absolute-path $path)
   (if (== (str-length $path) 0)
       False
       (== (str-slice $path 0 1) "/")))

(= (codex:util-ends-with-slash $path)
   (let $len (str-length $path)
     (if (== $len 0)
         False
         (== (str-slice $path (- $len 1) $len) "/"))))

(= (codex:util-pathbuf-join $base $path)
   (if (== $base "")
       $path
       (if (codex:util-ends-with-slash $base)
           (str-concat $base $path)
           (str-concat $base (str-concat "/" $path)))))

(= (codex:resolve-path $base $path)
   (if (codex:util-is-unix-absolute-path $path)
       $path
       (codex:util-pathbuf-join $base $path)))

(= (codex:normalize-thread-name $name)
   (let $trimmed (str-trim $name)
     (if (== $trimmed "")
         CodexAbsent
         $trimmed)))

(= (codex:resume-command-target $thread-name $thread-id)
   (if (== $thread-name CodexAbsent)
       $thread-id
       (if (codex:util-is-empty-string $thread-name)
           $thread-id
           $thread-name)))

(= (codex:resume-command $thread-name $thread-id)
   (let $target (codex:resume-command-target $thread-name $thread-id)
     (if (== $target CodexAbsent)
         CodexAbsent
         (let $escaped (shell-shlex-join ($target))
           (if (codex:util-starts-with-dash $target)
               (str-concat "codex resume -- " $escaped)
               (str-concat "codex resume " $escaped))))))
