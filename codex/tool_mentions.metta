; Narrow Rust-faithful tool mention parsing slice.
;
; This ports the pure visible behavior from:
; - openai-codex/codex-rs/utils/plugins/src/mention_syntax.rs
; - openai-codex/codex-rs/core-skills/src/injection.rs
; - openai-codex/codex-rs/core/src/plugins/mentions.rs
;
; Covered in this increment:
; - plaintext tool/plugin sigils
; - ToolMentionKind path classification helpers
; - `extract_tool_mentions_with_sigil`
; - app/plugin explicit mention collection from text and structured mentions
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores parsed mentions in `HashSet<&str>`. This CeTTa surface returns
;   deterministic first-seen lists as the representation of those sets. The
;   membership behavior and plugin-order filtering match the Rust callers.
; - Rust scans UTF-8 bytes. CeTTa `str-slice` indexes strings through the
;   runtime string surface, but the mention grammar and delimiters are ASCII,
;   so the same visible ASCII mention names and resource boundaries are used.

!(import! &self list)
!(import! &self str)

(= (codex:tool-mention-sigil)
   "$")

(= (codex:plugin-text-mention-sigil)
   "@")

(= (codex:tool-mention-kind-app)
   (CodexToolMentionKindApp))

(= (codex:tool-mention-kind-mcp)
   (CodexToolMentionKindMcp))

(= (codex:tool-mention-kind-plugin)
   (CodexToolMentionKindPlugin))

(= (codex:tool-mention-kind-skill)
   (CodexToolMentionKindSkill))

(= (codex:tool-mention-kind-other)
   (CodexToolMentionKindOther))

(= (codex:tool-mentions $names $paths $plain-names)
   (CodexToolMentions $names $paths $plain-names))

(= (codex:tool-mentions-names (CodexToolMentions $names $paths $plain-names))
   $names)

(= (codex:tool-mentions-paths (CodexToolMentions $names $paths $plain-names))
   $paths)

(= (codex:tool-mentions-plain-names (CodexToolMentions $names $paths $plain-names))
   $plain-names)

(= (codex:linked-tool-mention $name $path $end-index)
   (CodexLinkedToolMention $name $path $end-index))

(= (codex:tool-mentions-list-contains $items $item)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head $item)
               True
               (codex:tool-mentions-list-contains $tail $item))))))

(= (codex:tool-mentions-list-add $items $item)
   (if (codex:tool-mentions-list-contains $items $item)
       $items
       (list:append $items ($item))))

(= (codex:tool-mentions-add-name
      (CodexToolMentions $names $paths $plain-names)
      $name)
   (CodexToolMentions
     (codex:tool-mentions-list-add $names $name)
     $paths
     $plain-names))

(= (codex:tool-mentions-add-path
      (CodexToolMentions $names $paths $plain-names)
      $path)
   (CodexToolMentions
     $names
     (codex:tool-mentions-list-add $paths $path)
     $plain-names))

(= (codex:tool-mentions-add-plain-name
      (CodexToolMentions $names $paths $plain-names)
      $name)
   (CodexToolMentions
     $names
     $paths
     (codex:tool-mentions-list-add $plain-names $name)))

(= (codex:tool-mentions-ascii-lower-char $char)
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
      ("a" "a")
      ("b" "b")
      ("c" "c")
      ("d" "d")
      ("e" "e")
      ("f" "f")
      ("g" "g")
      ("h" "h")
      ("i" "i")
      ("j" "j")
      ("k" "k")
      ("l" "l")
      ("m" "m")
      ("n" "n")
      ("o" "o")
      ("p" "p")
      ("q" "q")
      ("r" "r")
      ("s" "s")
      ("t" "t")
      ("u" "u")
      ("v" "v")
      ("w" "w")
      ("x" "x")
      ("y" "y")
      ("z" "z")
      ("0" "0")
      ("1" "1")
      ("2" "2")
      ("3" "3")
      ("4" "4")
      ("5" "5")
      ("6" "6")
      ("7" "7")
      ("8" "8")
      ("9" "9")
      ("_" "_")
      ("-" "-")
      (":" ":")
      ("." ".")
      ("/" "/")
      ("\\" "\\")
      ($other $other))))

(= (codex:tool-mentions-ascii-lower-text $text)
   (if (== (str-length $text) 0)
       ""
       (str-concat
         (codex:tool-mentions-ascii-lower-char (str-slice $text 0 1))
         (codex:tool-mentions-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:is-tool-mention-name-char $char)
   (case $char
     (("a" True)
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
      ("A" True)
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
      ("0" True)
      ("1" True)
      ("2" True)
      ("3" True)
      ("4" True)
      ("5" True)
      ("6" True)
      ("7" True)
      ("8" True)
      ("9" True)
      ("_" True)
      ("-" True)
      (":" True)
      ($other False))))

(= (codex:is-common-tool-mention-env-var $name)
   (case (codex:tool-mentions-ascii-lower-text $name)
     (("path" True)
      ("home" True)
      ("user" True)
      ("shell" True)
      ("pwd" True)
      ("tmpdir" True)
      ("temp" True)
      ("tmp" True)
      ("lang" True)
      ("term" True)
      ("xdg_config_home" True)
      ($other False))))

(= (codex:is-tool-mentions-ascii-whitespace $char)
   (case $char
     ((" " True)
      ("\n" True)
      ("\r" True)
      ("\t" True)
      ($other False))))

(= (codex:tool-mentions-char-at $text $index)
   (if (>= $index (str-length $text))
       CodexAbsent
       (str-slice $text $index (+ $index 1))))

(= (codex:tool-mentions-name-end $text $index)
   (if (>= $index (str-length $text))
       $index
       (let $char (codex:tool-mentions-char-at $text $index)
         (if (codex:is-tool-mention-name-char $char)
             (codex:tool-mentions-name-end $text (+ $index 1))
             $index))))

(= (codex:tool-mentions-skip-ascii-whitespace $text $index)
   (if (>= $index (str-length $text))
       $index
       (let $char (codex:tool-mentions-char-at $text $index)
         (if (codex:is-tool-mentions-ascii-whitespace $char)
             (codex:tool-mentions-skip-ascii-whitespace $text (+ $index 1))
             $index))))

(= (codex:tool-mentions-find-close-paren $text $index)
   (if (>= $index (str-length $text))
       CodexAbsent
       (if (== (codex:tool-mentions-char-at $text $index) ")")
           $index
           (codex:tool-mentions-find-close-paren $text (+ $index 1)))))

(= (codex:parse-linked-tool-mention-at $text $start $sigil)
   (let $sigil-index (+ $start 1)
     (if (not (== (codex:tool-mentions-char-at $text $sigil-index) $sigil))
         CodexAbsent
         (let $name-start (+ $sigil-index 1)
            (let $first-name-char (codex:tool-mentions-char-at $text $name-start)
             (if (== $first-name-char CodexAbsent)
                 CodexAbsent
                 (if (not (codex:is-tool-mention-name-char $first-name-char))
                     CodexAbsent
                     (case (codex:tool-mentions-name-end $text (+ $name-start 1))
                       (($name-end
                         (if (not (== (codex:tool-mentions-char-at $text $name-end) "]"))
                             CodexAbsent
                             (case (codex:tool-mentions-skip-ascii-whitespace
                                     $text
                                     (+ $name-end 1))
                               (($path-open-index
                                 (if (not (== (codex:tool-mentions-char-at $text $path-open-index) "("))
                                     CodexAbsent
                                     (case (codex:tool-mentions-find-close-paren
                                             $text
                                             (+ $path-open-index 1))
                                       (($path-close-index
                                         (if (== $path-close-index CodexAbsent)
                                             CodexAbsent
                                             (let $path
                                               (str-trim
                                                 (str-slice
                                                   $text
                                                   (+ $path-open-index 1)
                                                   $path-close-index))
                                               (if (== $path "")
                                                   CodexAbsent
                                                   (codex:linked-tool-mention
                                                     (str-slice $text $name-start $name-end)
                                                     $path
                                                     (+ $path-close-index 1)))))))))))))))))))))))

(= (codex:tool-mention-path-basename $path)
   (codex:tool-mention-path-basename-from $path 0 ""))

(= (codex:tool-mention-path-basename-from $path $index $current)
   (if (>= $index (str-length $path))
       $current
       (let $char (codex:tool-mentions-char-at $path $index)
         (if (== $char "/")
             (codex:tool-mention-path-basename-from $path (+ $index 1) "")
             (if (== $char "\\")
                 (codex:tool-mention-path-basename-from $path (+ $index 1) "")
                 (codex:tool-mention-path-basename-from
                   $path
                   (+ $index 1)
                   (str-concat $current $char)))))))

(= (codex:is-tool-mention-skill-filename $path)
   (case (codex:tool-mention-path-basename $path)
     (($basename
       (case (codex:tool-mentions-ascii-lower-text $basename)
         (("skill.md" True)
          ($other False)))))))

(= (codex:tool-kind-for-path $path)
   (if (str-starts-with? $path "app://")
       (codex:tool-mention-kind-app)
       (if (str-starts-with? $path "mcp://")
           (codex:tool-mention-kind-mcp)
           (if (str-starts-with? $path "plugin://")
               (codex:tool-mention-kind-plugin)
               (if (str-starts-with? $path "skill://")
                   (codex:tool-mention-kind-skill)
                   (if (codex:is-tool-mention-skill-filename $path)
                       (codex:tool-mention-kind-skill)
                       (codex:tool-mention-kind-other)))))))

(= (codex:tool-mentions-strip-non-empty-prefix $text $prefix)
   (if (str-starts-with? $text $prefix)
       (let $value (str-slice $text (str-length $prefix) (str-length $text))
         (if (== $value "")
             Empty
             $value))
       Empty))

(= (codex:app-id-from-path $path)
   (codex:tool-mentions-strip-non-empty-prefix $path "app://"))

(= (codex:plugin-config-name-from-path $path)
   (codex:tool-mentions-strip-non-empty-prefix $path "plugin://"))

(= (codex:normalize-skill-path $path)
   (if (str-starts-with? $path "skill://")
       (str-slice $path 8 (str-length $path))
       $path))

(= (codex:extract-tool-mentions $text)
   (codex:extract-tool-mentions-with-sigil $text "$"))

(= (codex:extract-tool-mentions-with-sigil $text $sigil)
   (codex:extract-tool-mentions-scan
     $text
     $sigil
     0
     (CodexToolMentions () () ())))

(= (codex:extract-tool-mentions-after-linked
      $text
      $sigil
      (CodexToolMentions $names $paths $plain-names)
      (CodexLinkedToolMention $name $path $end-index))
   (if (codex:is-common-tool-mention-env-var $name)
       (codex:extract-tool-mentions-scan
         $text
         $sigil
         $end-index
         (CodexToolMentions $names $paths $plain-names))
       (let $kind (codex:tool-kind-for-path $path)
         (let $with-name
           (if (== $kind (codex:tool-mention-kind-app))
               (CodexToolMentions $names $paths $plain-names)
               (if (== $kind (codex:tool-mention-kind-mcp))
                   (CodexToolMentions $names $paths $plain-names)
                   (if (== $kind (codex:tool-mention-kind-plugin))
                       (CodexToolMentions $names $paths $plain-names)
                       (codex:tool-mentions-add-name
                         (CodexToolMentions $names $paths $plain-names)
                         $name))))
         (codex:extract-tool-mentions-scan
           $text
           $sigil
           $end-index
           (codex:tool-mentions-add-path $with-name $path))))))

(= (codex:extract-tool-mentions-after-plain-name
      $text
      $sigil
      $name-end
      $mentions
      $name)
   (case $text
     (($scan-text
       (case $name-end
         (($scan-index
           (if (codex:is-common-tool-mention-env-var $name)
               (codex:extract-tool-mentions-scan
                 $scan-text
                 $sigil
                 $scan-index
                 $mentions)
               (case (codex:tool-mentions-add-plain-name
                       (codex:tool-mentions-add-name $mentions $name)
                       $name)
                 (($updated-mentions
                   (codex:extract-tool-mentions-scan
                     $scan-text
                     $sigil
                     $scan-index
                     $updated-mentions))))))))))))

(= (codex:extract-tool-mentions-after-sigil $text $sigil $index $mentions)
   (let $name-start (+ $index 1)
      (let $first-name-char (codex:tool-mentions-char-at $text $name-start)
       (if (== $first-name-char CodexAbsent)
           (codex:extract-tool-mentions-scan
             $text
             $sigil
             (+ $index 1)
             $mentions)
           (if (not (codex:is-tool-mention-name-char $first-name-char))
               (codex:extract-tool-mentions-scan
                 $text
                 $sigil
                 (+ $index 1)
                 $mentions)
               (case (codex:tool-mentions-name-end $text (+ $name-start 1))
                 (($name-end
                   (let $name (str-slice $text $name-start $name-end)
                     (codex:extract-tool-mentions-after-plain-name
                       $text
                       $sigil
                       $name-end
                       $mentions
                       $name))))))))))

(= (codex:extract-tool-mentions-scan $text $sigil $index $mentions)
   (case $text
     (($scan-text
       (codex:extract-tool-mentions-scan-materialized
         $scan-text
         $sigil
         $index
         $mentions)))))

(= (codex:extract-tool-mentions-scan-materialized $text $sigil $index $mentions)
   (if (>= $index (str-length $text))
       $mentions
       (let $char (codex:tool-mentions-char-at $text $index)
         (if (== $char "[")
             (case (codex:parse-linked-tool-mention-at $text $index $sigil)
               (($linked
                 (if (== $linked CodexAbsent)
                     (codex:extract-tool-mentions-after-sigil
                       $text
                       $sigil
                       $index
                       $mentions)
                     (codex:extract-tool-mentions-after-linked
                       $text
                       $sigil
                       $mentions
                       $linked)))))
             (if (== $char $sigil)
                 (codex:extract-tool-mentions-after-sigil
                   $text
                   $sigil
                   $index
                   $mentions)
                 (codex:extract-tool-mentions-scan
                   $text
                   $sigil
                   (+ $index 1)
                   $mentions))))))

(= (codex:text-mentions-skill $text $skill-name)
   (if (== $skill-name "")
       False
       (codex:text-mentions-skill-scan $text $skill-name 0)))

(= (codex:text-mentions-skill-scan $text $skill-name $index)
   (if (>= $index (str-length $text))
       False
       (if (not (== (codex:tool-mentions-char-at $text $index)
                    (codex:tool-mention-sigil)))
           (codex:text-mentions-skill-scan $text $skill-name (+ $index 1))
           (let $name-start (+ $index 1)
             (let $after-index (+ $name-start (str-length $skill-name))
               (if (> $after-index (str-length $text))
                   (codex:text-mentions-skill-scan
                     $text
                     $skill-name
                     (+ $index 1))
                   (if (not (str-starts-with?
                              (str-slice $text $name-start (str-length $text))
                              $skill-name))
                       (codex:text-mentions-skill-scan
                         $text
                         $skill-name
                         (+ $index 1))
                       (if (>= $after-index (str-length $text))
                           True
                           (if (not
                                 (codex:is-tool-mention-name-char
                                   (codex:tool-mentions-char-at
                                     $text
                                     $after-index)))
                               True
                               (codex:text-mentions-skill-scan
                                 $text
                                 $skill-name
                                 (+ $index 1)))))))))))

(= (codex:tool-mentions-append-items $lhs $rhs)
   (if (== $lhs ())
       $rhs
       (let $head (list:first $lhs)
         (let $tail (list:rest $lhs)
          (case (codex:tool-mentions-append-items $tail $rhs)
            (($rest (cons-atom $head $rest))))))))

(= (codex:tool-mentions-structured-mention-paths $inputs)
   (if (== $inputs ())
       ()
       (let $head (list:first $inputs)
         (let $tail (list:rest $inputs)
           (let $tail-paths (codex:tool-mentions-structured-mention-paths $tail)
             (case $head
              (((CodexUserInputMention $name $path)
                 (cons-atom $path $tail-paths))
                ($other $tail-paths))))))))

(= (codex:tool-mentions-texts $inputs)
   (if (== $inputs ())
       ()
       (let $head (list:first $inputs)
         (let $tail (list:rest $inputs)
           (let $tail-texts (codex:tool-mentions-texts $tail)
             (case $head
              (((CodexUserInputText $text $text-elements)
                 (cons-atom $text $tail-texts))
                ($other $tail-texts))))))))

(= (codex:tool-mentions-paths-from-texts-with-sigil $texts $sigil)
   (if (== $texts ())
       ()
       (let $head (list:first $texts)
         (let $tail (list:rest $texts)
           (codex:tool-mentions-append-items
             (codex:tool-mentions-paths
               (codex:extract-tool-mentions-with-sigil $head $sigil))
             (codex:tool-mentions-paths-from-texts-with-sigil $tail $sigil))))))

(= (codex:tool-mentions-app-ids-from-paths $paths $acc)
   (if (== $paths ())
       $acc
       (let $head (list:first $paths)
         (let $tail (list:rest $paths)
           (let $app-id (codex:app-id-from-path $head)
             (codex:tool-mentions-app-ids-from-paths
               $tail
               (if (== $app-id Empty)
                   $acc
                   (codex:tool-mentions-list-add $acc $app-id))))))))

(= (codex:collect-explicit-app-ids $inputs)
   (let $structured-paths (codex:tool-mentions-structured-mention-paths $inputs)
     (let $text-paths
       (codex:tool-mentions-paths-from-texts-with-sigil
         (codex:tool-mentions-texts $inputs)
         "$")
       (codex:tool-mentions-app-ids-from-paths
         (codex:tool-mentions-append-items $structured-paths $text-paths)
         ()))))

(= (codex:tool-mentions-plugin-config-names-from-paths $paths $acc)
   (if (== $paths ())
       $acc
       (let $head (list:first $paths)
         (let $tail (list:rest $paths)
           (let $config-name (codex:plugin-config-name-from-path $head)
             (codex:tool-mentions-plugin-config-names-from-paths
               $tail
               (if (== $config-name Empty)
                   $acc
                   (codex:tool-mentions-list-add $acc $config-name))))))))

(= (codex:tool-mentions-plugin-config-name
      (CodexPluginCapabilitySummary
        $config-name
        $display-name
        $description
        $has-skills
        $mcp-server-names
        $app-connector-ids))
   $config-name)

(= (codex:tool-mentions-filter-plugins-by-config-names $plugins $config-names)
   (if (== $plugins ())
       ()
       (let $head (list:first $plugins)
         (let $tail (list:rest $plugins)
           (let $filtered-tail
             (codex:tool-mentions-filter-plugins-by-config-names
               $tail
               $config-names)
             (if (codex:tool-mentions-list-contains
                   $config-names
                   (codex:tool-mentions-plugin-config-name $head))
                 (cons-atom $head $filtered-tail)
                 $filtered-tail))))))

(= (codex:collect-explicit-plugin-mentions $inputs $plugins)
   (if (== $plugins ())
       ()
       (let $structured-paths (codex:tool-mentions-structured-mention-paths $inputs)
         (let $text-paths
           (codex:tool-mentions-paths-from-texts-with-sigil
             (codex:tool-mentions-texts $inputs)
             "@")
           (let $config-names
             (codex:tool-mentions-plugin-config-names-from-paths
               (codex:tool-mentions-append-items $structured-paths $text-paths)
               ())
             (if (== $config-names ())
                 ()
                 (codex:tool-mentions-filter-plugins-by-config-names
                   $plugins
                   $config-names)))))))
