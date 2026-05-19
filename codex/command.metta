; Visible command-parsing slice for the restarted Codex port.
;
; This ports the Rust `ParsedCommand` wire shape from
; openai-codex/codex-rs/protocol/src/parse_command.rs and a narrow,
; user-runnable subset of the parser from
; openai-codex/codex-rs/shell-command/src/parse_command.rs.
;
; Covered in this increment:
; - `cat`
; - `head` / `tail` file reads
; - `sed -n <range> <file>` reads
; - `ls`
; - `rg` / `rga` / `ripgrep-all` search and `--files`
; - `bash|sh|zsh -c|-lc` wrappers via the native shell plain-command splitter
; - pipeline helper dropping for small formatting commands (`head`, `tail`,
;   `sed`, `wc`) so summaries bias toward the main command
;
; CeTTa-specific limitation for this first command slice:
; shell wrapper reconstruction still threads through a quoted wrapper string
; because the native shell parser is currently exposed at that boundary. The
; visible wrapper path therefore remains narrower than Rust for some scripts
; with complex quoting, even though absolute shell paths now follow basename
; matching like the Rust helper.

!(import! &self json)
!(import! &self list)
!(import! &self path)
!(import! &self shell)
!(import! &self str)

(= (codex:parsed-read $cmd $name $path)
   (CodexParsedCommandRead $cmd $name $path))

(= (codex:parsed-list-files $cmd)
   (CodexParsedCommandListFiles $cmd CodexAbsent))

(= (codex:parsed-list-files $cmd $path)
   (CodexParsedCommandListFiles $cmd $path))

(= (codex:parsed-search $cmd)
   (CodexParsedCommandSearch $cmd CodexAbsent CodexAbsent))

(= (codex:parsed-search $cmd $query $path)
   (CodexParsedCommandSearch $cmd $query $path))

(= (codex:parsed-unknown $cmd)
   (CodexParsedCommandUnknown $cmd))

(= (codex:parsed-command-type (CodexParsedCommandRead $cmd $name $path))
   "read")

(= (codex:parsed-command-type (CodexParsedCommandListFiles $cmd $path))
   "list_files")

(= (codex:parsed-command-type (CodexParsedCommandSearch $cmd $query $path))
   "search")

(= (codex:parsed-command-type (CodexParsedCommandUnknown $cmd))
   "unknown")

(= (codex:optional-string-json $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:parsed-command-json (CodexParsedCommandRead $cmd $name $path))
   (JsonObject
     ((JsonPair "type" (JsonString "read"))
      (JsonPair "cmd" (JsonString $cmd))
      (JsonPair "name" (JsonString $name))
      (JsonPair "path" (JsonString $path)))))

(= (codex:parsed-command-json (CodexParsedCommandListFiles $cmd $path))
   (JsonObject
     ((JsonPair "type" (JsonString "list_files"))
      (JsonPair "cmd" (JsonString $cmd))
      (JsonPair "path" (codex:optional-string-json $path)))))

(= (codex:parsed-command-json (CodexParsedCommandSearch $cmd $query $path))
   (JsonObject
     ((JsonPair "type" (JsonString "search"))
      (JsonPair "cmd" (JsonString $cmd))
      (JsonPair "query" (codex:optional-string-json $query))
      (JsonPair "path" (codex:optional-string-json $path)))))

(= (codex:parsed-command-json (CodexParsedCommandUnknown $cmd))
   (JsonObject
     ((JsonPair "type" (JsonString "unknown"))
      (JsonPair "cmd" (JsonString $cmd)))))

(= (codex:parsed-commands-json $items)
   (function
     (let $json-items
       (eval (map-atom $items $item (codex:parsed-command-json $item)))
       (return (JsonArray $json-items)))))

(= (codex:join-command $tokens)
   (str-join " " $tokens))

(= (codex:path-last-part $path)
   (let $parts (path-parts $path)
     (if (== $parts ())
         $path
         (list:first (list:reverse $parts)))))

(= (codex:is-bash-shell-name? $shell)
   (let $name (codex:path-last-part $shell)
     (if (== $name "bash")
         True
         (if (== $name "sh")
             True
             (if (== $name "zsh")
                 True
                 False)))))

(= (codex:is-shell-wrapper-parts? $shell $flag)
   (if (== $flag "-c")
       (codex:is-bash-shell-name? $shell)
       (if (== $flag "-lc")
           (codex:is-bash-shell-name? $shell)
           False)))

(= (codex:single-unknown-for-command $tokens)
   (if (== (list:len $tokens) 3)
       (let $shell (list:at $tokens 0)
         (let $flag (list:at $tokens 1)
           (let $script (list:at $tokens 2)
             (if (codex:is-shell-wrapper-parts? $shell $flag)
                 (codex:parsed-unknown $script)
                 (codex:parsed-unknown (codex:join-command $tokens))))))
       (codex:parsed-unknown (codex:join-command $tokens))))

(= (codex:trimmed-display-path $path)
   (path-normalize $path))

(= (codex:is-hidden-display-part? $part)
   (if (== $part "build")
       True
       (if (== $part "dist")
           True
           (if (== $part "node_modules")
               True
               (if (== $part "src")
                   True
                   False)))))

(= (codex:first-display-part ())
   CodexAbsent)

(= (codex:first-display-part $parts)
   (let ($head $tail) (decons-atom $parts)
     (if (codex:is-hidden-display-part? $head)
         (codex:first-display-part $tail)
         $head)))

(= (codex:short-display-path $path)
   (let $trimmed (codex:trimmed-display-path $path)
     (let $selected
       (codex:first-display-part (list:reverse (path-parts $trimmed)))
       (if (== $selected CodexAbsent)
           $trimmed
           $selected))))

(= (codex:is-decimal-digit $char)
   (if (== $char "0")
       True
       (if (== $char "1")
           True
           (if (== $char "2")
               True
               (if (== $char "3")
                   True
                   (if (== $char "4")
                       True
                       (if (== $char "5")
                           True
                           (if (== $char "6")
                               True
                               (if (== $char "7")
                                   True
                                   (if (== $char "8")
                                       True
                                       (if (== $char "9")
                                           True
                                           False)))))))))))

(= (codex:is-decimal-string $text)
   (if (== (str-length $text) 0)
       False
       (codex:is-decimal-string-from $text 0)))

(= (codex:is-decimal-string-from $text $index)
   (if (== $index (str-length $text))
       True
       (let $char (str-slice $text $index (+ $index 1))
         (if (codex:is-decimal-digit $char)
             (codex:is-decimal-string-from $text (+ $index 1))
             False))))

(= (codex:is-tail-count-string $text)
   (if (str-starts-with? $text "+")
       (codex:is-decimal-string (str-slice $text 1 (str-length $text)))
       (codex:is-decimal-string $text)))

(= (codex:is-digit-or-comma-char $char)
   (if (== $char ",")
       True
       (codex:is-decimal-digit $char)))

(= (codex:is-digit-or-comma-string $text)
   (if (== (str-length $text) 0)
       False
       (codex:is-digit-or-comma-string-from $text 0)))

(= (codex:is-digit-or-comma-string-from $text $index)
   (if (== $index (str-length $text))
       True
       (let $char (str-slice $text $index (+ $index 1))
         (if (codex:is-digit-or-comma-char $char)
             (codex:is-digit-or-comma-string-from $text (+ $index 1))
             False))))

(= (codex:is-sed-range-arg $range)
   (if (str-ends-with? $range "p")
       (codex:is-digit-or-comma-string
         (str-slice $range 0 (- (str-length $range) 1)))
       False))

(= (codex:is-connector $token)
   (if (== $token "&&")
       True
       (if (== $token "||")
           True
           (if (== $token "|")
               True
               (if (== $token ";")
                   True
                   False)))))

(= (codex:split-on-connectors $tokens)
   (codex:split-on-connectors-acc $tokens () ()))

(= (codex:split-on-connectors-acc () () $groups)
   $groups)

(= (codex:split-on-connectors-acc () $current $groups)
   (list:push $groups $current))

(= (codex:split-on-connectors-acc $tokens $current $groups)
   (let ($head $tail) (decons-atom $tokens)
     (if (codex:is-connector $head)
         (if (== $current ())
             (codex:split-on-connectors-acc $tail () $groups)
             (codex:split-on-connectors-acc
               $tail
               ()
               (list:push $groups $current)))
         (codex:split-on-connectors-acc
           $tail
           (list:push $current $head)
           $groups))))

(= (codex:non-flag-operands ())
   ())

(= (codex:non-flag-operands $tokens)
   (let ($head $tail) (decons-atom $tokens)
     (if (str-starts-with? $head "-")
         (codex:non-flag-operands $tail)
         (let $rest (eval (codex:non-flag-operands $tail))
           (cons-atom $head $rest)))))

(= (codex:contains-token () $needle)
   False)

(= (codex:contains-token $tokens $needle)
   (let ($head $tail) (decons-atom $tokens)
     (if (== $head $needle)
         True
         (codex:contains-token $tail $needle))))

(= (codex:is-read-path-token $path)
   (if (str-starts-with? $path "-")
       False
       True))

(= (codex:sed-read-path $tail)
   (if (== (list:len $tail) 3)
       (let $flag (list:at $tail 0)
         (let $range (list:at $tail 1)
           (let $path (list:at $tail 2)
             (if (== $flag "-n")
                 (if (codex:is-sed-range-arg $range)
                     (if (codex:is-read-path-token $path)
                         $path
                         CodexAbsent)
                     CodexAbsent)
                 CodexAbsent))))
       CodexAbsent))

(= (codex:is-small-formatting-command $tokens)
   (if (== (list:first $tokens) "wc")
       True
       (codex:is-small-formatting-command-rest $tokens)))

(= (codex:is-small-formatting-command-rest $tokens)
   (if (== $tokens ())
       False
       (let $head (list:first $tokens)
         (if (== $head "head")
             (if (== (list:len $tokens) 1)
                 True
                 (if (== (list:len $tokens) 2)
                     (str-starts-with? (list:at $tokens 1) "-")
                     (if (== (list:len $tokens) 3)
                         (if (== (list:at $tokens 1) "-n")
                             (codex:is-decimal-string (list:at $tokens 2))
                             False)
                         False)))
             (if (== $head "tail")
                 (if (== (list:len $tokens) 1)
                     True
                     (if (== (list:len $tokens) 2)
                         (str-starts-with? (list:at $tokens 1) "-")
                         (if (== (list:len $tokens) 3)
                             (if (== (list:at $tokens 1) "-n")
                                 (codex:is-tail-count-string (list:at $tokens 2))
                                 False)
                             False)))
                 (if (== $head "sed")
                     (if (== (list:len $tokens) 3)
                         (if (== (list:at $tokens 1) "-n")
                             (codex:is-sed-range-arg (list:at $tokens 2))
                             False)
                         False)
                     False))))))

(= (codex:drop-small-formatting-commands ())
   ())

(= (codex:drop-small-formatting-commands $commands)
   (let ($head $tail) (decons-atom $commands)
     (if (codex:is-small-formatting-command $head)
         (codex:drop-small-formatting-commands $tail)
         (let $rest (eval (codex:drop-small-formatting-commands $tail))
           (cons-atom $head $rest)))))

; Same map over command groups as the Rust parser; explicit recursion keeps the
; result concrete when callers force parsing inside approval checks.
(= (codex:parse-token-groups ())
   ())

(= (codex:parse-token-groups $commands)
   (let ($head $tail) (decons-atom $commands)
     (case (codex:parse-token-groups $tail)
       (($parsed-tail
         (cons-atom
           (codex:summarize-main-tokens $head)
           $parsed-tail))))))

(= (codex:parse-command-token-groups $commands)
   (let $filtered (codex:drop-small-formatting-commands $commands)
     (if (== $filtered ())
         (codex:parse-token-groups $commands)
         (codex:parse-token-groups $filtered))))

(= (codex:rebuild-shell-wrapper $shell $flag $script)
   (str-concat
     $shell
     (str-concat
       " "
       (str-concat
         $flag
         (str-concat " '" (str-concat $script "'"))))))

(= (codex:parse-shell-wrapper $argv $shell $flag $script)
   (function
     (case (shell-plain-commands (codex:rebuild-shell-wrapper $shell $flag $script))
       ((Empty (return ((codex:single-unknown-for-command $argv))))
        ($commands (return (codex:parse-command-token-groups $commands)))))))

(= (codex:parse-command-impl $tokens)
   (if (== (list:len $tokens) 3)
       (let $shell (list:at $tokens 0)
         (let $flag (list:at $tokens 1)
           (let $script (list:at $tokens 2)
             (if (codex:is-shell-wrapper-parts? $shell $flag)
                 (codex:parse-shell-wrapper $tokens $shell $flag $script)
                 (codex:parse-command-token-groups
                   (codex:split-on-connectors $tokens))))))
       (codex:parse-command-token-groups (codex:split-on-connectors $tokens))))

(= (codex:parsed-commands-have-unknown? ())
   False)

(= (codex:parsed-commands-have-unknown? $items)
   (let ($head $tail) (decons-atom $items)
     (if (== (codex:parsed-command-type $head) "unknown")
         True
         (codex:parsed-commands-have-unknown? $tail))))

(= (codex:dedup-parsed-commands $items)
   (codex:dedup-parsed-commands-acc $items CodexAbsent ()))

(= (codex:dedup-parsed-commands-acc () $previous $acc)
   $acc)

(= (codex:dedup-parsed-commands-acc $items $previous $acc)
   (let ($head $tail) (decons-atom $items)
     (if (== $head $previous)
         (codex:dedup-parsed-commands-acc $tail $previous $acc)
         (codex:dedup-parsed-commands-acc
           $tail
           $head
           (list:push $acc $head)))))

(= (codex:parse-command ())
   ())

(= (codex:parse-command $tokens)
   (let $parsed (codex:dedup-parsed-commands (codex:parse-command-impl $tokens))
     (if (codex:parsed-commands-have-unknown? $parsed)
         ((codex:single-unknown-for-command $tokens))
         $parsed)))

(= (codex:summarize-main-tokens $tokens)
   (let ($head $tail) (decons-atom $tokens)
     (if (== $head "cat")
         (codex:summarize-cat-command $tokens $tail)
         (if (== $head "head")
             (codex:summarize-head-command $tokens $tail)
             (if (== $head "tail")
                 (codex:summarize-tail-command $tokens $tail)
                 (if (== $head "sed")
                     (codex:summarize-sed-command $tokens $tail)
                     (if (== $head "ls")
                         (codex:summarize-ls-command $tokens $tail)
                         (if (== $head "rg")
                             (codex:summarize-rg-command $tokens $tail)
                             (if (== $head "rga")
                                 (codex:summarize-rg-command $tokens $tail)
                                 (if (== $head "ripgrep-all")
                                     (codex:summarize-rg-command $tokens $tail)
                                     (codex:parsed-unknown
                                       (codex:join-command $tokens))))))))))))

(= (codex:summarize-cat-command $tokens $tail)
   (if (== (list:len $tail) 1)
       (let $path (list:first $tail)
         (if (codex:is-read-path-token $path)
             (codex:parsed-read
               (codex:join-command $tokens)
               (codex:short-display-path $path)
               $path)
             (codex:parsed-unknown (codex:join-command $tokens))))
       (codex:parsed-unknown (codex:join-command $tokens))))

(= (codex:summarize-head-command $tokens $tail)
   (if (== (list:len $tail) 1)
       (let $path (list:first $tail)
         (if (codex:is-read-path-token $path)
             (codex:parsed-read
               (codex:join-command $tokens)
               (codex:short-display-path $path)
               $path)
             (codex:parsed-unknown (codex:join-command $tokens))))
       (if (== (list:len $tail) 3)
           (let $flag (list:at $tail 0)
             (let $count (list:at $tail 1)
               (let $path (list:at $tail 2)
                 (if (== $flag "-n")
                     (if (codex:is-decimal-string $count)
                         (if (codex:is-read-path-token $path)
                             (codex:parsed-read
                               (codex:join-command $tokens)
                               (codex:short-display-path $path)
                               $path)
                             (codex:parsed-unknown (codex:join-command $tokens)))
                         (codex:parsed-unknown (codex:join-command $tokens)))
                     (codex:parsed-unknown (codex:join-command $tokens))))))
           (codex:parsed-unknown (codex:join-command $tokens)))))

(= (codex:summarize-tail-command $tokens $tail)
   (if (== (list:len $tail) 1)
       (let $path (list:first $tail)
         (if (codex:is-read-path-token $path)
             (codex:parsed-read
               (codex:join-command $tokens)
               (codex:short-display-path $path)
               $path)
             (codex:parsed-unknown (codex:join-command $tokens))))
       (if (== (list:len $tail) 3)
           (let $flag (list:at $tail 0)
             (let $count (list:at $tail 1)
               (let $path (list:at $tail 2)
                 (if (== $flag "-n")
                     (if (codex:is-tail-count-string $count)
                         (if (codex:is-read-path-token $path)
                             (codex:parsed-read
                               (codex:join-command $tokens)
                               (codex:short-display-path $path)
                               $path)
                             (codex:parsed-unknown (codex:join-command $tokens)))
                         (codex:parsed-unknown (codex:join-command $tokens)))
                     (codex:parsed-unknown (codex:join-command $tokens))))))
           (codex:parsed-unknown (codex:join-command $tokens)))))

(= (codex:summarize-sed-command $tokens $tail)
   (let $path (codex:sed-read-path $tail)
     (if (== $path CodexAbsent)
         (codex:parsed-unknown (codex:join-command $tokens))
         (codex:parsed-read
           (codex:join-command $tokens)
           (codex:short-display-path $path)
           $path))))

(= (codex:summarize-ls-command $tokens $tail)
   (let $operands (codex:non-flag-operands $tail)
     (if (== $operands ())
         (codex:parsed-list-files (codex:join-command $tokens))
         (codex:parsed-list-files
           (codex:join-command $tokens)
           (codex:short-display-path (list:first $operands))))))

(= (codex:summarize-rg-command $tokens $tail)
   (let $cmd (codex:join-command $tokens)
     (let $operands (codex:non-flag-operands $tail)
       (if (codex:contains-token $tail "--files")
           (if (== $operands ())
               (codex:parsed-list-files $cmd)
               (codex:parsed-list-files
                 $cmd
                 (codex:short-display-path (list:first $operands))))
           (if (== $operands ())
               (codex:parsed-search $cmd)
               (let $query (list:first $operands)
                 (let $rest (list:rest $operands)
                   (if (== $rest ())
                       (codex:parsed-search $cmd $query CodexAbsent)
                       (codex:parsed-search
                         $cmd
                         $query
                         (codex:short-display-path (list:first $rest)))))))))))
