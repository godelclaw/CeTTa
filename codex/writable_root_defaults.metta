; Visible writable-root default-subpath helper slice for the restarted Codex
; port.
;
; This ports the adjacent Rust helpers from:
; - openai-codex/codex-rs/protocol/src/protocol.rs
;   - default_read_only_subpaths_for_writable_root
;   - is_git_pointer_file
;   - resolve_gitdir_from_file
;
; Required CeTTa deviation for audit:
; - Rust resolves `gitdir:` pointers with `Path::parent` and lexical path
;   joins on `AbsolutePathBuf`. Under the current evaluator, recursive
;   lexical-path reducers become unstable once the large `codex:protocol`
;   module is loaded. This restart slice therefore uses direct runtime process
;   calls to `/usr/bin/dirname` and `/usr/bin/realpath -m` to preserve the
;   same visible absolute-path results for these helpers.

!(import! &self fs)
!(import! &self process)
!(import! &self str)

(= (codex:writable-root-defaults-helper-cwd)
   "/")

(= (codex:writable-root-defaults-helper-timeout-ms)
   1000)

(= (codex:writable-root-defaults-helper-max-bytes)
   1048576)

(= (codex:writable-root-defaults-child-path $root $child)
   (if (== $root "/")
       (str-concat "/" $child)
       (if (str-ends-with? $root "/")
           (str-concat $root $child)
           (str-concat
             (str-concat $root "/")
             $child))))

(= (codex:writable-root-defaults-append-unique () $item)
   ($item))

(= (codex:writable-root-defaults-append-unique ($a) $item)
   (if (== $a $item)
       ($a)
       ($a $item)))

(= (codex:writable-root-defaults-append-unique ($a $b) $item)
   (if (or (== $a $item) (== $b $item))
       ($a $b)
       ($a $b $item)))

(= (codex:writable-root-defaults-append-unique ($a $b $c) $item)
   (if (or (== $a $item) (== $b $item) (== $c $item))
       ($a $b $c)
       ($a $b $c $item)))

(= (codex:writable-root-defaults-append-unique ($a $b $c $d) $item)
   (if (or (== $a $item) (== $b $item) (== $c $item) (== $d $item))
       ($a $b $c $d)
       ($a $b $c $d $item)))

(= (codex:writable-root-defaults-resolve-gitdir-script)
   "f=\"$1\"; trimmed=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \"$f\" 2>/dev/null) || exit 1; case \"$trimmed\" in *:*) ;; *) exit 1 ;; esac; gitdir_raw=${trimmed#*:}; gitdir_raw=$(printf '%s' \"$gitdir_raw\" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'); [ -n \"$gitdir_raw\" ] || exit 1; base=$(dirname \"$f\") || exit 1; gitdir=$(cd \"$base\" && realpath -m -- \"$gitdir_raw\") || exit 1; [ -e \"$gitdir\" ] || exit 1; printf '%s' \"$gitdir\"")

(= (codex:is-git-pointer-file $path)
   (let $normalized-path $path
     (case (fs-path-kind $normalized-path)
       (("file"
         (if (or
               (== $normalized-path ".git")
               (str-ends-with? $normalized-path "/.git"))
             True
             False))
        ($kind False)))))

(= (codex:resolve-gitdir-from-file $dot-git)
   (let $result
     (process-run-cmd-cwd-env-timeout-cap-bytes
       ("/bin/sh"
        "-c"
        (codex:writable-root-defaults-resolve-gitdir-script)
        "sh"
        $dot-git)
       (codex:writable-root-defaults-helper-cwd)
       ()
       (codex:writable-root-defaults-helper-timeout-ms)
       (codex:writable-root-defaults-helper-max-bytes))
     (if (== (process-result-exit-code $result) 0)
         (str-trim (process-result-stdout $result))
         CodexAbsent)))

(= (codex:writable-root-defaults-top-level-git-subpaths $top-level-git)
   (case (fs-path-kind $top-level-git)
     (("directory"
       ($top-level-git))
      ("file"
       (let $subpaths-with-gitdir
         (if (codex:is-git-pointer-file $top-level-git)
             (let $gitdir (codex:resolve-gitdir-from-file $top-level-git)
               (if (== $gitdir CodexAbsent)
                   ()
                   ($gitdir)))
             ())
         (codex:writable-root-defaults-append-unique
           $subpaths-with-gitdir
           $top-level-git)))
      ($kind ()))))

(= (codex:writable-root-defaults-maybe-append-directory $subpaths $path)
   (case (fs-path-kind $path)
     (("directory"
       (codex:writable-root-defaults-append-unique $subpaths $path))
      ($kind $subpaths))))

(= (codex:writable-root-defaults-append-top-level-codex
      $subpaths
      $top-level-codex
      $protect-missing-dot-codex)
   (if $protect-missing-dot-codex
       (codex:writable-root-defaults-append-unique
         $subpaths
         $top-level-codex)
       (codex:writable-root-defaults-maybe-append-directory
         $subpaths
         $top-level-codex)))

(= (codex:default-read-only-subpaths-for-writable-root
      $writable-root
      $protect-missing-dot-codex)
   (let $top-level-git
     (codex:writable-root-defaults-child-path $writable-root ".git")
     (let $top-level-agents
       (codex:writable-root-defaults-child-path $writable-root ".agents")
       (let $top-level-codex
         (codex:writable-root-defaults-child-path $writable-root ".codex")
         (codex:writable-root-defaults-append-top-level-codex
           (codex:writable-root-defaults-maybe-append-directory
             (codex:writable-root-defaults-top-level-git-subpaths
               $top-level-git)
             $top-level-agents)
           $top-level-codex
           $protect-missing-dot-codex)))))
