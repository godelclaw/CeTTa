; Rust-faithful path utility helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/utils/path-utils/src/lib.rs
;   - normalize_for_wsl_with_flag
;   - is_wsl_case_insensitive_path
;   - lower_ascii_path
;   - normalize_for_native_workdir_with_flag
; - openai-codex/codex-rs/utils/path-utils/src/env.rs
;   - is_wsl
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust reads host cfg flags, environment variables, and `/proc/version`.
;   This CeTTa slice exposes the same branch logic through explicit flag/env
;   inputs so tests and higher layers can drive the same decisions
;   deterministically.
; - Rust's Unix `Path::components` collapses repeated separators while reading
;   path components. This CeTTa slice drops empty slash-separated components to
;   preserve that visible behavior for Unix-style strings.
; - Rust's Windows `dunce::simplified` covers the full Windows verbatim path
;   space. This slice implements the visible `\\?\` prefix simplification
;   covered by Codex tests; broader Windows path semantics require a native path
;   layer.

!(import! &self list)
!(import! &self str)

(= (codex:path-utils-ascii-lower-char $char)
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

(= (codex:path-utils-ascii-lower-text $text)
   (if (== (str-length $text) 0)
       ""
       (str-concat
         (codex:path-utils-ascii-lower-char (str-slice $text 0 1))
         (codex:path-utils-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:path-utils-is-ascii-alpha-char $char)
   (case $char
     (("A" True)
      ("B" True)
      ("C" True)
      ("D" True)
      ("E" True)
      ("F" True)
      ("G" True)
      ("H" True)
      ("I" True)
      ("J" True)
      ("K" True)
      ("L" True)
      ("M" True)
      ("N" True)
      ("O" True)
      ("P" True)
      ("Q" True)
      ("R" True)
      ("S" True)
      ("T" True)
      ("U" True)
      ("V" True)
      ("W" True)
      ("X" True)
      ("Y" True)
      ("Z" True)
      ("a" True)
      ("b" True)
      ("c" True)
      ("d" True)
      ("e" True)
      ("f" True)
      ("g" True)
      ("h" True)
      ("i" True)
      ("j" True)
      ("k" True)
      ("l" True)
      ("m" True)
      ("n" True)
      ("o" True)
      ("p" True)
      ("q" True)
      ("r" True)
      ("s" True)
      ("t" True)
      ("u" True)
      ("v" True)
      ("w" True)
      ("x" True)
      ("y" True)
      ("z" True)
      ($other False))))

(= (codex:path-utils-drop-empty-components $components)
   (case $components
     ((() ())
      ($items
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head "")
               (codex:path-utils-drop-empty-components $tail)
               (list:cons
                 $head
                 (codex:path-utils-drop-empty-components $tail)))))))))

(= (codex:path-utils-ascii-eq-ignore-case $left $right)
   (== (codex:path-utils-ascii-lower-text $left)
       (codex:path-utils-ascii-lower-text $right)))

(= (codex:path-utils-starts-with $text $prefix)
   (let $text-len (str-length $text)
     (let $prefix-len (str-length $prefix)
       (if (< $text-len $prefix-len)
           False
           (== (str-slice $text 0 $prefix-len) $prefix)))))

(= (codex:path-utils-components-after-root $path)
   (if (codex:path-utils-starts-with $path "/")
       (codex:path-utils-drop-empty-components
         (str-split "/" (str-slice $path 1 (str-length $path))))
       ()))

(= (codex:is-wsl-case-insensitive-path $path)
   (let $components (codex:path-utils-components-after-root $path)
     (if (== $components ())
         False
         (let $first (list:first $components)
           (let $after-first (list:rest $components)
             (if (not (codex:path-utils-ascii-eq-ignore-case $first "mnt"))
                 False
                 (if (== $after-first ())
                     False
                     (let $drive (list:first $after-first)
                       (if (== (str-length $drive) 1)
                           (codex:path-utils-is-ascii-alpha-char $drive)
                           False)))))))))

(= (codex:lower-ascii-path $path)
   (codex:path-utils-ascii-lower-text $path))

(= (codex:normalize-for-wsl-with-flag $path $is-wsl)
   (if $is-wsl
       (if (codex:is-wsl-case-insensitive-path $path)
           (codex:lower-ascii-path $path)
           $path)
       $path))

(= (codex:normalize-for-native-workdir-with-flag $path $is-windows)
   (if $is-windows
       (if (codex:path-utils-starts-with $path "\\\\?\\")
           (str-slice $path 4 (str-length $path))
           $path)
       $path))

(= (codex:is-wsl-from-env-and-version $wsl-distro-name $proc-version)
   (if (not (== $wsl-distro-name CodexAbsent))
       True
       (if (== $proc-version CodexAbsent)
           False
           (case (str-find
                   (codex:path-utils-ascii-lower-text $proc-version)
                   "microsoft")
             ((Empty False)
              ($index True))))))
