; Visible list_dir slice for the restarted Codex port.
;
; This ports the narrow list_dir path from:
; - openai-codex/codex-rs/tools/src/utility_tool.rs
; - openai-codex/codex-rs/core/src/tools/handlers/list_dir.rs
;
; Covered in this increment:
; - Rust-shaped tool name/description and JSON argument decoding
; - offset / limit / depth / absolute-path validation
; - directory traversal, entry formatting, pagination, and output text
; - unsupported-payload handling and a direct runnable tool-call surface
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust threads `ReadDenyMatcher` from the full session turn context. The
;   restarted CeTTa slice does not yet expose that turn/runtime layer, so the
;   handler context carries only explicit denied read roots for deterministic
;   local coverage. The default visible tool-call surface remains unrestricted.
; - Rust collects structured entries, then sorts them by relative path with a
;   comparator over the full record. The current CeTTa evaluator does not yet
;   expose a comparable structured-sort helper, so this slice sorts the
;   materialized string keys and maps them back to entries. This preserves
;   Rust-visible ordering for unique normalized relative paths; if separate
;   long paths truncate to the same 500-byte key, Rust's `sort_unstable_by`
;   leaves their relative order unspecified while this slice keeps collection
;   order for that tie.
; - The current CeTTa `json-object-get` surface does not preserve Rust's
;   missing-vs-null distinction for these optional numeric fields. Omitted
;   `offset` / `limit` / `depth` therefore follow the shared absent/null
;   representation that the runtime exposes, so explicit `null` currently also
;   falls back to the Rust default instead of producing a serde type error.

!(import! &self fs)
!(import! &self json)
!(import! &self list)
!(import! &self path)
!(import! &self protocol)
!(import! &self str)
!(import! &self tool_handler_common)

(= (codex:list-dir-tool-name)
   "list_dir")

(= (codex:list-dir-tool-description)
   "Lists entries in a local directory with 1-indexed entry numbers and simple type labels.")

(= (codex:list-dir-unsupported-payload-message)
   "list_dir handler received unsupported payload")

(= (codex:list-dir-deny-read-policy-message)
   "access denied: reading this path is blocked by filesystem deny_read policy")

(= (codex:list-dir-default-offset)
   1)

(= (codex:list-dir-default-limit)
   25)

(= (codex:list-dir-default-depth)
   2)

(= (codex:list-dir-maximum-entry-length)
   500)

(= (codex:list-dir-indentation-spaces)
   2)

(= (codex:list-dir-kind-directory)
   "directory")

(= (codex:list-dir-kind-file)
   "file")

(= (codex:list-dir-kind-symlink)
   "symlink")

(= (codex:list-dir-kind-other)
   "other")

(= (codex:list-dir-args $dir-path $offset $limit $depth)
   (CodexListDirArgs $dir-path $offset $limit $depth))

(= (codex:list-dir-args-dir-path (CodexListDirArgs $dir-path $offset $limit $depth))
   $dir-path)

(= (codex:list-dir-args-offset (CodexListDirArgs $dir-path $offset $limit $depth))
   $offset)

(= (codex:list-dir-args-limit (CodexListDirArgs $dir-path $offset $limit $depth))
   $limit)

(= (codex:list-dir-args-depth (CodexListDirArgs $dir-path $offset $limit $depth))
   $depth)

(= (codex:list-dir-entry $display-name $depth $kind)
   (codex:list-dir-entry-with-sort-key
     $display-name
     $display-name
     $depth
     $kind))

(= (codex:list-dir-entry-with-sort-key $sort-key $display-name $depth $kind)
   (CodexListDirEntry $sort-key $display-name $depth $kind))

(= (codex:list-dir-entry-sort-key
      (CodexListDirEntry $sort-key $display-name $depth $kind))
   $sort-key)

(= (codex:list-dir-entry-display-name
      (CodexListDirEntry $sort-key $display-name $depth $kind))
   $display-name)

(= (codex:list-dir-entry-depth
      (CodexListDirEntry $sort-key $display-name $depth $kind))
   $depth)

(= (codex:list-dir-entry-kind
      (CodexListDirEntry $sort-key $display-name $depth $kind))
   $kind)

(= (codex:list-dir-function-payload $arguments)
   (CodexListDirPayloadFunction $arguments))

(= (codex:list-dir-unsupported-payload $payload-kind)
   (CodexListDirPayloadUnsupported $payload-kind))

(= (codex:list-dir-handler-context $read-deny-roots)
   (CodexListDirHandlerContext $read-deny-roots))

(= (codex:default-list-dir-handler-context)
   (codex:list-dir-handler-context ()))

(= (codex:list-dir-handler-context-read-deny-roots
      (CodexListDirHandlerContext $read-deny-roots))
   $read-deny-roots)

(= (codex:list-dir-handler-result-success $output-text)
   (CodexListDirHandlerResultSuccess $output-text))

(= (codex:list-dir-handler-result-error $message)
   (CodexListDirHandlerResultError $message))

(= (codex:list-dir-handler-result-output-text
      (CodexListDirHandlerResultSuccess $output-text))
   $output-text)

(= (codex:list-dir-handler-result-message
      (CodexListDirHandlerResultError $message))
   $message)

(= (codex:list-dir-parse-ok $value)
   (CodexListDirParseOk $value))

(= (codex:list-dir-parse-error $message)
   (CodexListDirParseError $message))

(= (codex:list-dir-parse-result-message
      (CodexListDirParseError $message))
   $message)

(= (codex:list-dir-collect-ok $entries)
   (CodexListDirCollectOk $entries))

(= (codex:list-dir-collect-error $message)
   (CodexListDirCollectError $message))

(= (codex:list-dir-json-object-required-string-result $object $key)
   (case (json-object-get $object $key)
     ((Empty
       (codex:list-dir-parse-error
         (format-args "missing field `{}`" ($key))))
      (JsonNull
       (codex:list-dir-parse-error
         (format-args "missing field `{}`" ($key))))
      ((JsonString $text) (codex:list-dir-parse-ok $text))
      ($other
       (codex:list-dir-parse-error
         (format-args "invalid type for `{}`; expected string" ($key)))))))

(= (codex:list-dir-decimal-digit-value "0")
   0)

(= (codex:list-dir-decimal-digit-value "1")
   1)

(= (codex:list-dir-decimal-digit-value "2")
   2)

(= (codex:list-dir-decimal-digit-value "3")
   3)

(= (codex:list-dir-decimal-digit-value "4")
   4)

(= (codex:list-dir-decimal-digit-value "5")
   5)

(= (codex:list-dir-decimal-digit-value "6")
   6)

(= (codex:list-dir-decimal-digit-value "7")
   7)

(= (codex:list-dir-decimal-digit-value "8")
   8)

(= (codex:list-dir-decimal-digit-value "9")
   9)

(= (codex:is-list-dir-decimal-digit $digit)
   (case $digit
     (("0" True)
      ("1" True)
      ("2" True)
      ("3" True)
      ("4" True)
      ("5" True)
      ("6" True)
      ("7" True)
      ("8" True)
      ("9" True)
      ($other False))))

(= (codex:is-list-dir-decimal-string $text)
   (if (== $text "")
       False
       (codex:is-list-dir-decimal-string-from $text 0)))

(= (codex:is-list-dir-decimal-string-from $text $index)
   (if (== $index (str-length $text))
       True
       (let $digit (str-slice $text $index (+ $index 1))
         (if (codex:is-list-dir-decimal-digit $digit)
             (codex:is-list-dir-decimal-string-from $text (+ $index 1))
             False))))

(= (codex:list-dir-decimal-string-to-number $text)
   (codex:list-dir-decimal-string-to-number-from $text 0 0))

(= (codex:list-dir-decimal-string-to-number-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $digit-char (str-slice $text $index (+ $index 1))
         (codex:list-dir-decimal-string-to-number-from
           $text
           (+ $index 1)
           (+ (* $acc 10) (codex:list-dir-decimal-digit-value $digit-char))))))

(= (codex:list-dir-number-field-result $key $text)
   (case (codex:is-list-dir-decimal-string $text)
     ((True
       (case (codex:list-dir-decimal-string-to-number $text)
         (($number
            (codex:list-dir-parse-ok $number)))))
      (False
       (codex:list-dir-parse-error
         (format-args "invalid type for `{}`; expected integer" ($key)))))))

(= (codex:list-dir-json-object-number-with-default-result $object $key $default)
   (case (json-object-get $object $key)
     ((Empty
       (codex:list-dir-parse-ok $default))
      (JsonNull
       (codex:list-dir-parse-ok $default))
      ((JsonNumber $text) (codex:list-dir-number-field-result $key $text))
      ($other
       (codex:list-dir-parse-error
         (format-args "invalid type for `{}`; expected integer" ($key)))))))

(= (codex:list-dir-args-from-depth-result
      $dir-path
      $offset
      $limit
      (CodexListDirParseOk $depth))
   (codex:list-dir-parse-ok
     (codex:list-dir-args $dir-path $offset $limit $depth)))

(= (codex:list-dir-args-from-depth-result
      $dir-path
      $offset
      $limit
      (CodexListDirParseError $message))
   (codex:list-dir-parse-error $message))

(= (codex:list-dir-args-from-limit-result
      $dir-path
      $offset
      (CodexListDirParseOk $limit)
      $object)
   (case (codex:list-dir-json-object-number-with-default-result
           $object
           "depth"
           (codex:list-dir-default-depth))
     (($depth-result
       (codex:list-dir-args-from-depth-result
         $dir-path
         $offset
         $limit
         $depth-result)))))

(= (codex:list-dir-args-from-limit-result
      $dir-path
      $offset
      (CodexListDirParseError $message)
      $object)
   (codex:list-dir-parse-error $message))

(= (codex:list-dir-args-from-offset-result
      $dir-path
      (CodexListDirParseOk $offset)
      $object)
   (case (codex:list-dir-json-object-number-with-default-result
           $object
           "limit"
           (codex:list-dir-default-limit))
     (($limit-result
       (codex:list-dir-args-from-limit-result
         $dir-path
         $offset
         $limit-result
         $object)))))

(= (codex:list-dir-args-from-offset-result
      $dir-path
      (CodexListDirParseError $message)
      $object)
   (codex:list-dir-parse-error $message))

(= (codex:parse-list-dir-args-object $object)
   (case (codex:list-dir-json-object-required-string-result
           $object
           "dir_path")
     (((CodexListDirParseOk $dir-path)
       (case (codex:list-dir-json-object-number-with-default-result
               $object
               "offset"
               (codex:list-dir-default-offset))
         (($offset-result
           (codex:list-dir-args-from-offset-result
             $dir-path
             $offset-result
             $object)))))
      ((CodexListDirParseError $message)
       (codex:list-dir-parse-error $message)))))

(= (codex:parse-list-dir-args $input)
   (case (codex:parse-function-arguments-object $input)
     (((CodexParseFunctionArgumentsObjectOk $object)
       (codex:parse-list-dir-args-object $object))
      ((CodexParseFunctionArgumentsObjectError $message)
       (codex:list-dir-parse-error $message)))))

(= (codex:list-dir-fs-entry-name ($name $kind))
   $name)

(= (codex:list-dir-fs-entry-kind ($name $kind))
   $kind)

(= (codex:list-dir-relative-child-prefix $prefix $name)
   (if (== $prefix "")
       $name
       (str-concat
         $prefix
         (str-concat "/" $name))))

(= (codex:list-dir-child-path $current-dir $name)
   (if (== $current-dir "/")
       (str-concat "/" $name)
       (str-concat
         $current-dir
         (str-concat "/" $name))))

(= (codex:list-dir-entry-depth-from-prefix $prefix)
   (if (== $prefix "")
       0
       (case (path-parts $prefix)
         (($parts
            (list:len $parts))))))

(= (codex:list-dir-normalize-entry-component $name)
   (if (> (str-length $name) (codex:list-dir-maximum-entry-length))
       (str-take-bytes-at-char-boundary
         $name
         (codex:list-dir-maximum-entry-length))
       $name))

(= (codex:list-dir-normalize-entry-path $name)
   (codex:list-dir-normalize-entry-component
     (str-join "/" (str-split "\\" $name))))

(= (codex:list-dir-indent $depth)
   (if (== $depth 0)
       ""
       (str-concat
         (str-join
           ""
           (list:repeat (codex:list-dir-indentation-spaces) " "))
         (codex:list-dir-indent (- $depth 1)))))

(= (codex:list-dir-kind-suffix $kind)
   (if (== $kind (codex:list-dir-kind-directory))
       "/"
       (if (== $kind (codex:list-dir-kind-symlink))
           "@"
           (if (== $kind (codex:list-dir-kind-other))
               "?"
               ""))))

(= (codex:list-dir-format-entry-line
      (CodexListDirEntry $sort-key $display-name $depth $kind))
   (str-concat
     (codex:list-dir-indent $depth)
     (str-concat $display-name (codex:list-dir-kind-suffix $kind))))

(= (codex:list-dir-format-entry-lines $entries)
   (if (list:empty? $entries)
       ()
       (let $entry (list:first $entries)
         (let $rest (list:rest $entries)
           (case (codex:list-dir-format-entry-line $entry)
             (($line
                (case (codex:list-dir-format-entry-lines $rest)
                  (($rest-lines
                     (cons-atom $line $rest-lines)))))))))))

(= (codex:list-dir-append-items () $rhs)
   $rhs)

; CeTTa reduction note: the list_dir handler imports the large protocol surface,
; and recursive `list:append`/`let` chains can collapse to no result in that
; environment. Keep the Rust-visible ordering with an explicit case-forced
; append, matching the stable pattern used by fixture turn lowering.
(= (codex:list-dir-append-items $lhs $rhs)
   (let ($head $tail) (decons-atom $lhs)
     (case (codex:list-dir-append-items $tail $rhs)
       (($rest
          (cons-atom $head $rest))))))

; Same lexical normalization as `path-normalize`, staged so false deny-root
; comparisons do not collapse under the imported tool surface.
(= (codex:list-dir-normalize-path $path)
   (case (path-is-absolute? $path)
     ((True
       (case (path-parts $path)
         (($parts
            (path-build-from-parts $parts True)))))
      (False
       (case (path-parts $path)
         (($parts
            (path-build-from-parts $parts False))))))))

(= (codex:list-dir-is-path-within-root $path $root)
   (case (codex:list-dir-normalize-path $path)
     (($norm-path
       (case (codex:list-dir-normalize-path $root)
         (($norm-root
           (if (== $norm-root "/")
               True
               (if (== $norm-path $norm-root)
                   True
                   (str-starts-with?
                     $norm-path
                     (str-concat $norm-root "/")))))))))))

(= (codex:is-list-dir-read-denied-path $context $path)
   (codex:is-list-dir-read-denied-path-roots
     $path
     (codex:list-dir-handler-context-read-deny-roots $context)))

(= (codex:is-list-dir-read-denied-path-roots $path ())
   False)

; CeTTa evaluation accommodation: force each root comparison before recursing.
; This preserves Rust ReadDenyMatcher's first-match semantics; the direct
; recursive false branch can otherwise collapse for multi-root lists.
(= (codex:is-list-dir-read-denied-path-roots $path $roots)
   (let $head (list:first $roots)
     (let $tail (list:rest $roots)
       (case (codex:list-dir-is-path-within-root $path $head)
         ((True True)
          (False
           (case (codex:is-list-dir-read-denied-path-roots $path $tail)
             (($is-denied $is-denied)))))))))

(= (codex:list-dir-read-directory-result $current-dir)
   (fs-read-dir-entries $current-dir))

(= (codex:list-dir-collect-entries $current-dir $relative-prefix $remaining-depth $context)
   (case (codex:list-dir-read-directory-result $current-dir)
     (((Error $source ("read" $message))
       (codex:list-dir-collect-error
         (str-concat "failed to read directory: " $message)))
      ((Error $source ("inspect" $message))
       (codex:list-dir-collect-error
         (str-concat "failed to inspect entry: " $message)))
      ($items
       (codex:list-dir-collect-entry-items
         $current-dir
         $relative-prefix
         $remaining-depth
         $context
         $items
         ())))))

(= (codex:list-dir-collect-entry-items
      $current-dir
      $relative-prefix
      $remaining-depth
      $context
      $items
      $acc)
   (if (list:empty? $items)
       (codex:list-dir-collect-ok $acc)
       (let $item (list:first $items)
         (let $rest (list:rest $items)
           (case (codex:list-dir-fs-entry-name $item)
             (($name
               (case (codex:list-dir-fs-entry-kind $item)
                 (($kind
                   (case (codex:is-list-dir-read-denied-path
                           $context
                           (codex:list-dir-child-path $current-dir $name))
                     ((True
                       (codex:list-dir-collect-entry-items
                         $current-dir
                         $relative-prefix
                         $remaining-depth
                         $context
                         $rest
                         $acc))
                      (False
                       (let $entry
                         (codex:list-dir-entry-with-sort-key
                           (codex:list-dir-normalize-entry-path
                             (codex:list-dir-relative-child-prefix
                               $relative-prefix
                               $name))
                           (codex:list-dir-normalize-entry-component $name)
                           (codex:list-dir-entry-depth-from-prefix $relative-prefix)
                           $kind)
                         (case (codex:list-dir-append-items $acc ($entry))
                           (($acc1
                             (if (== $kind (codex:list-dir-kind-directory))
                                 (if (> $remaining-depth 1)
                                     (case (codex:list-dir-collect-entries
                                             (codex:list-dir-child-path
                                               $current-dir
                                               $name)
                                             (codex:list-dir-relative-child-prefix
                                               $relative-prefix
                                               $name)
                                             (- $remaining-depth 1)
                                             $context)
                                       (((CodexListDirCollectOk $child-entries)
                                         (case (codex:list-dir-append-items
                                                 $acc1
                                                 $child-entries)
                                           (($acc2
                                             (codex:list-dir-collect-entry-items
                                               $current-dir
                                               $relative-prefix
                                               $remaining-depth
                                               $context
                                               $rest
                                               $acc2)))))
                                        ((CodexListDirCollectError $message)
                                         (codex:list-dir-collect-error $message))))
                                     (codex:list-dir-collect-entry-items
                                       $current-dir
                                       $relative-prefix
                                       $remaining-depth
                                       $context
                                       $rest
                                       $acc1))
                                 (codex:list-dir-collect-entry-items
                                   $current-dir
                                   $relative-prefix
                                   $remaining-depth
                                   $context
                                   $rest
                                   $acc1)))))))))))))))))))

(= (codex:list-dir-drop $items $count)
   (if (== $count 0)
       $items
       (if (list:empty? $items)
           ()
           (codex:list-dir-drop (list:rest $items) (- $count 1)))))

(= (codex:list-dir-take $items $count)
   (if (== $count 0)
       ()
       (if (list:empty? $items)
           ()
           (let $head (list:first $items)
             (let $tail (list:rest $items)
               (let $next-count (- $count 1)
                 (case (codex:list-dir-take $tail $next-count)
                   (($taken-tail
                      (cons-atom $head $taken-tail))))))))))

(= (codex:list-dir-entry-sort-keys ())
   ())

(= (codex:list-dir-entry-sort-keys $entries)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (case (codex:list-dir-entry-sort-key $head)
         (($sort-key
           (case (codex:list-dir-entry-sort-keys $tail)
             (($tail-keys
               (cons-atom $sort-key $tail-keys))))))))))

(= (codex:list-dir-take-entry-by-sort-key $sort-key ())
   (CodexListDirTakeEntryMissing $sort-key))

(= (codex:list-dir-take-entry-by-sort-key $sort-key $entries)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (case (codex:list-dir-entry-sort-key $head)
         (($head-sort-key
           (if (== $sort-key $head-sort-key)
               (CodexListDirTakeEntryFound $head $tail)
               (case (codex:list-dir-take-entry-by-sort-key $sort-key $tail)
                 (((CodexListDirTakeEntryFound $entry $remaining)
                   (CodexListDirTakeEntryFound
                     $entry
                     (cons-atom $head $remaining)))
                  ((CodexListDirTakeEntryMissing $missing-sort-key)
                   (CodexListDirTakeEntryMissing $missing-sort-key)))))))))))

(= (codex:list-dir-entries-from-sorted-keys $entries ())
   ())

(= (codex:list-dir-entries-from-sorted-keys $entries $keys)
   (let $key (list:first $keys)
     (let $tail-keys (list:rest $keys)
       (case (codex:list-dir-take-entry-by-sort-key $key $entries)
         (((CodexListDirTakeEntryFound $entry $remaining-entries)
           (case (codex:list-dir-entries-from-sorted-keys
                   $remaining-entries
                   $tail-keys)
             (($tail-entries
               (cons-atom $entry $tail-entries)))))
          ((CodexListDirTakeEntryMissing $missing-sort-key)
           ()))))))

(= (codex:list-dir-sort-entries-by-sort-key $entries)
   (if (list:empty? $entries)
       ()
       (case (eval (codex:list-dir-entry-sort-keys $entries))
         (($sort-keys
           (case (sort-strings $sort-keys)
             (($sorted-keys
               (codex:list-dir-entries-from-sorted-keys
                 $entries
                 $sorted-keys)))))))))

(= (codex:list-dir-selected-lines-from-formatted
      $remaining-entries
      $capped-limit
      $formatted)
   (codex:list-dir-collect-ok
     (if (< $capped-limit $remaining-entries)
         (list:append
           $formatted
           ((format-args "More than {} entries found" ($capped-limit))))
         $formatted)))

(= (codex:list-dir-selected-lines-from-selected
      $remaining-entries
      $capped-limit
      $selected-entries)
   (case (codex:list-dir-format-entry-lines $selected-entries)
     (($formatted
        (codex:list-dir-selected-lines-from-formatted
          $remaining-entries
          $capped-limit
          $formatted)))))

(= (codex:list-dir-selected-lines-from-visible
      $remaining-entries
      $capped-limit
      $visible-entries)
   (case (codex:list-dir-take $visible-entries $capped-limit)
     (($selected-entries
        (codex:list-dir-selected-lines-from-selected
          $remaining-entries
          $capped-limit
          $selected-entries)))))

(= (codex:list-dir-selected-lines $entries $offset $limit)
   (let $start-index (- $offset 1)
     (if (>= $start-index (list:len $entries))
         (codex:list-dir-collect-error "offset exceeds directory entry count")
         (let $remaining-entries (- (list:len $entries) $start-index)
           (let $capped-limit
             (if (< $limit $remaining-entries)
                 $limit
                 $remaining-entries)
             (case (codex:list-dir-drop $entries $start-index)
               (($visible-entries
                  (codex:list-dir-selected-lines-from-visible
                    $remaining-entries
                    $capped-limit
                    $visible-entries)))))))))

(= (codex:list-dir-output-text $dir-path $lines)
   (if (list:empty? $lines)
       (format-args "Absolute path: {}" ($dir-path))
       (str-join
         "\n"
         (list:append
           ((format-args "Absolute path: {}" ($dir-path)))
           $lines))))

(= (codex:list-dir-handler-from-entries $dir-path $offset $limit $entries)
   (if (list:empty? $entries)
       (codex:list-dir-handler-result-success
         (codex:list-dir-output-text $dir-path ()))
       (case (codex:list-dir-sort-entries-by-sort-key $entries)
         (($sorted-entries
           (case (codex:list-dir-selected-lines $sorted-entries $offset $limit)
             (((CodexListDirCollectOk $lines)
               (codex:list-dir-handler-result-success
                 (codex:list-dir-output-text $dir-path $lines)))
              ((CodexListDirCollectError $message)
               (codex:list-dir-handler-result-error $message)))))))))

(= (codex:handle-list-dir-args $context $args)
   (let $dir-path (codex:list-dir-args-dir-path $args)
     (let $offset (codex:list-dir-args-offset $args)
       (let $limit (codex:list-dir-args-limit $args)
         (let $depth (codex:list-dir-args-depth $args)
           (if (== $offset 0)
               (codex:list-dir-handler-result-error
                 "offset must be a 1-indexed entry number")
               (if (== $limit 0)
                   (codex:list-dir-handler-result-error
                     "limit must be greater than zero")
                   (if (== $depth 0)
                       (codex:list-dir-handler-result-error
                         "depth must be greater than zero")
                      (if (path-is-absolute? $dir-path)
                          (case (codex:is-list-dir-read-denied-path $context $dir-path)
                            ((True
                              (codex:list-dir-handler-result-error
                                (format-args
                                  "{}: `{}`"
                                  ((codex:list-dir-deny-read-policy-message)
                                   $dir-path))))
                             (False
                              (case (codex:list-dir-collect-entries
                                      $dir-path
                                      ""
                                      $depth
                                      $context)
                                (((CodexListDirCollectOk $entries)
                                  (codex:list-dir-handler-from-entries
                                    $dir-path
                                    $offset
                                    $limit
                                    $entries))
                                 ((CodexListDirCollectError $message)
                                  (codex:list-dir-handler-result-error
                                    $message)))))))
                          (codex:list-dir-handler-result-error
                            "dir_path must be an absolute path"))))))))))

(= (codex:handle-list-dir-parse-result
      $context
      (CodexListDirParseOk $args))
   (codex:handle-list-dir-args $context $args))

(= (codex:handle-list-dir-parse-result
      $context
      (CodexListDirParseError $message))
   (codex:list-dir-handler-result-error
     (codex:function-arguments-parse-error-message $message)))

(= (codex:handle-list-dir-function $context $arguments)
   (case (codex:parse-list-dir-args $arguments)
     (($parse-result
       (codex:handle-list-dir-parse-result $context $parse-result)))))

(= (codex:handle-list-dir-payload $context $call-id $payload)
   (case $payload
     (((CodexListDirPayloadFunction $arguments)
       (codex:handle-list-dir-function $context $arguments))
      ((CodexListDirPayloadUnsupported $payload-kind)
       (codex:list-dir-handler-result-error
         (codex:list-dir-unsupported-payload-message))))))

(= (codex:run-list-dir-tool-call-with-context $context $call-id $input)
   (case
     (codex:handle-list-dir-payload
       $context
       $call-id
       (codex:list-dir-function-payload $input))
     (((CodexListDirHandlerResultSuccess $output-text)
       (codex:tool-result $call-id $output-text))
      ((CodexListDirHandlerResultError $message)
       (codex:tool-result $call-id $message)))))

(= (codex:run-list-dir-tool-call $call-id $input)
   (codex:run-list-dir-tool-call-with-context
     (codex:default-list-dir-handler-context)
     $call-id
     $input))
