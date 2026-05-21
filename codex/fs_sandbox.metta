; Rust-faithful filesystem-sandbox helper environment slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/exec-server/src/fs_sandbox.rs
;   - FS_HELPER_ENV_ALLOWLIST
;   - helper_env_key_is_allowed
;   - helper_env_from_vars
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses compile-time `cfg!(windows)`. This pure helper exposes the target
;   branch as an explicit Boolean in `...-on-platform`, while the unparameterized
;   helper uses the Unix/Linux branch used by this CeTTa profile.
; - Rust uses `OsString::to_string_lossy()` and collects into a `HashMap`.
;   This slice receives already-materialized strings and reuses ordered
;   `CodexUnifiedExecEnvVar` pairs; lookup and duplicate-key replacement match
;   `HashMap::insert`, while iteration order is intentionally not a contract.

!(import! &self list)
!(import! &self str)
!(import! &self unified_exec_env)

(= (codex:fs-helper-env-allowlist)
   ("PATH" "TMPDIR" "TMP" "TEMP"))

(= (codex:fs-helper-env-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:fs-helper-env-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:fs-helper-env-ascii-lower-char (str-slice $text 0 1))
         (codex:fs-helper-env-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:fs-helper-env-ascii-eq $left $right)
   (== (codex:fs-helper-env-ascii-lower-text $left)
       (codex:fs-helper-env-ascii-lower-text $right)))

(= (codex:fs-helper-env-key-in-allowlist $key $allowlist)
   (if (== $allowlist ())
       False
       (let $head (list:first $allowlist)
         (let $tail (list:rest $allowlist)
           (if (== $key $head)
               True
               (codex:fs-helper-env-key-in-allowlist $key $tail))))))

(= (codex:fs-helper-env-key-allowed-on-platform $is-windows $key)
   (if (codex:fs-helper-env-key-in-allowlist
         $key
         (codex:fs-helper-env-allowlist))
       True
       (if $is-windows
           (codex:fs-helper-env-ascii-eq $key "PATH")
           False)))

(= (codex:fs-helper-env-key-allowed $key)
   (codex:fs-helper-env-key-allowed-on-platform False $key))

(= (codex:fs-helper-env-from-vars-on-platform $is-windows $vars)
   (codex:fs-helper-env-from-vars-acc $is-windows $vars ()))

(= (codex:fs-helper-env-from-vars-acc $is-windows () $acc)
   $acc)

(= (codex:fs-helper-env-from-vars-acc $is-windows $vars $acc)
   (let $head (list:first $vars)
     (let $tail (list:rest $vars)
       (let $key (codex:unified-exec-env-var-name $head)
         (let $value (codex:unified-exec-env-var-value $head)
           (let $updated
             (if (codex:fs-helper-env-key-allowed-on-platform $is-windows $key)
                 (codex:unified-exec-env-insert $acc $key $value)
                 $acc)
             (codex:fs-helper-env-from-vars-acc
               $is-windows
               $tail
               $updated)))))))

(= (codex:fs-helper-env-from-vars $vars)
   (codex:fs-helper-env-from-vars-on-platform False $vars))
