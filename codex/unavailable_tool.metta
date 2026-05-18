; Narrow Rust-faithful unavailable-tool slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/unavailable_tool.rs
;
; Covered in this increment:
; - should_collect_unavailable_tool
; - collect_unavailable_called_tools
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust takes `&HashSet<&str>` for exposed tool names and uses a `BTreeMap`
;   keyed by `ToolName.display()`. The current CeTTa port preserves the same
;   visible dedup and lexicographic display ordering through a plain string list
;   plus an explicit sort/dedup pass.
; - The sorted display pass uses an eager `eval` before `sort-strings` because
;   the current CeTTa reducer does not always materialize the intermediate
;   string list under this nested caller.

!(import! &self list)
!(import! &self protocol)
!(import! &self str)
!(import! &self tool_name)

(= (codex:should-collect-unavailable-tool $name $namespace)
   (if (== $namespace CodexAbsent)
       (str-starts-with? $name "mcp__")
       (if (str-starts-with? $namespace "mcp__")
           True
           (str-starts-with? $name "mcp__"))))

(= (codex:unavailable-tool-pair $display $tool-name)
   (CodexUnavailableToolPair $display $tool-name))

(= (codex:unavailable-tool-pair-display
      (CodexUnavailableToolPair $display $tool-name))
   $display)

(= (codex:unavailable-tool-pair-tool-name
      (CodexUnavailableToolPair $display $tool-name))
   $tool-name)

(= (codex:unavailable-tool-string-list-contains () $needle)
   False)

(= (codex:unavailable-tool-string-list-contains $items $needle)
   (let ($head $tail) (decons-atom $items)
     (if (== $head $needle)
         True
         (codex:unavailable-tool-string-list-contains $tail $needle))))

(= (codex:collect-unavailable-called-tool-pairs
      ()
      $exposed-tool-names)
   ())

(= (codex:collect-unavailable-called-tool-pairs
      $input
      $exposed-tool-names)
   (let ($head $tail) (decons-atom $input)
     (case
       (codex:collect-unavailable-called-tool-pairs $tail $exposed-tool-names)
       (($tail-pairs
         (case $head
           (((CodexResponseItemFunctionCall
               $id
               $name
               $namespace
               $arguments
               $call_id)
             (if (codex:should-collect-unavailable-tool $name $namespace)
                 (let $tool-name
                   (if (== $namespace CodexAbsent)
                       (codex:plain-tool-name $name)
                       (codex:namespaced-tool-name $namespace $name))
                   (let $display (codex:tool-name-display $tool-name)
                     ; CeTTa evaluation accommodation: materialize the
                     ; HashSet::contains equivalent before choosing whether to
                     ; keep this pair. The direct `if` form can collapse when
                     ; the exposed-name list is itself recursive data.
                     (case
                       (codex:unavailable-tool-string-list-contains
                         $exposed-tool-names
                         $display)
                       ((True $tail-pairs)
                        (False
                         (cons-atom
                           (codex:unavailable-tool-pair $display $tool-name)
                           $tail-pairs))))))
                 $tail-pairs))
            ($other $tail-pairs))))))))

(= (codex:unavailable-tool-pair-displays $pairs)
   (eval
     (map-atom
       $pairs
       $pair
       (codex:unavailable-tool-pair-display $pair))))

(= (codex:unavailable-tool-dedup-sorted-strings ())
   ())

(= (codex:unavailable-tool-dedup-sorted-strings $items)
   (if (== (list:len $items) 1)
       $items
       (let ($head $tail) (decons-atom $items)
         (let $next (list:first $tail)
           (if (== $head $next)
               (codex:unavailable-tool-dedup-sorted-strings $tail)
               (let $dedup-tail (codex:unavailable-tool-dedup-sorted-strings $tail)
                 (cons-atom $head $dedup-tail)))))))

(= (codex:unavailable-tool-find-first-by-display $pairs $display)
   (let ($head $tail) (decons-atom $pairs)
     (if (== (codex:unavailable-tool-pair-display $head) $display)
         (codex:unavailable-tool-pair-tool-name $head)
         (codex:unavailable-tool-find-first-by-display $tail $display))))

(= (codex:unavailable-tool-names-from-displays $pairs $displays)
   ; CeTTa evaluation accommodation: Rust's BTreeMap::into_values
   ; materializes selected values after key ordering. map-atom-strict preserves
   ; that single-result mapping behavior while avoiding the imported-module
   ; tail recursion collapse seen with map-atom here.
   (if (== (list:len $displays) 1)
       (let $display (list:first $displays)
         (case (codex:unavailable-tool-find-first-by-display $pairs $display)
           (($tool-name ($tool-name)))))
       (map-atom-strict
         $displays
         $display
         (codex:unavailable-tool-find-first-by-display $pairs $display))))

(= (codex:collect-unavailable-called-tools $input $exposed-tool-names)
   (case
     (codex:collect-unavailable-called-tool-pairs $input $exposed-tool-names)
     (($pairs
       (case (eval (codex:unavailable-tool-pair-displays $pairs))
         (($displays
           (case
             (codex:unavailable-tool-dedup-sorted-strings
               (sort-strings $displays))
             (($sorted-displays
               (codex:unavailable-tool-names-from-displays
                 $pairs
                 $sorted-displays)))))))))))
