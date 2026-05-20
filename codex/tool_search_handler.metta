; Pure tool-search handler slice for the Codex port.
;
; This ports deterministic behavior from:
; - openai-codex/codex-rs/core/src/tools/handlers/tool_search.rs
; - openai-codex/codex-rs/tools/src/responses_api.rs
;
; Covered in this increment:
; - ToolSearchHandler kind
; - tool_search payload validation and FunctionCallError variants
; - default and explicit limit handling
; - BM25 search result ranking over the current CeTTa BM25 token boundary
; - computer-use expanded default search limit
; - per-bucket default result limiting
; - loadable-tool namespace coalescing over the source-preserving markers from
;   tool_search_entry.metta
;
; Required slice-local deviations from Rust, documented for audit:
; - The scorer now uses codex:bm25, which ports the bm25 crate scoring formula.
;   Its module-level comments document the remaining tokenizer/hash deviations
;   from Rust's `SearchEngineBuilder::with_documents(Language::English, ...)`.
; - Rust coalesces concrete `LoadableToolSpec` values. The earlier
;   tool_search_entry slice represents those specs as source-preserving marker
;   atoms, so this module coalesces marker atoms into explicit namespace marker
;   atoms while preserving Rust's first-namespace-wins order and append logic.

!(import! &self bm25)
!(import! &self context)
!(import! &self function_tool)
!(import! &self list)
!(import! &self str)
!(import! &self tool_search_entry)

(= (codex:tool-search-handler-kind)
   "function")

(= (codex:tool-search-tool-name)
   "tool_search")

(= (codex:tool-search-default-limit)
   8)

(= (codex:tool-search-computer-use-mcp-server-name)
   "computer-use")

(= (codex:tool-search-computer-use-tool-search-limit)
   20)

(= (codex:tool-search-default-limit-for-bucket $bucket)
   (if (== $bucket (codex:tool-search-computer-use-mcp-server-name))
       (codex:tool-search-computer-use-tool-search-limit)
       (codex:tool-search-default-limit)))

(= (codex:tool-search-handler-ok $output)
   (CodexToolSearchHandlerOk $output))

(= (codex:tool-search-handler-err $error)
   (CodexToolSearchHandlerErr $error))

(= (codex:tool-search-output-tools (CodexToolOutputToolSearch $tools))
   $tools)

(= (codex:tool-search-handler-result-tools
      (CodexToolSearchHandlerOk (CodexToolOutputToolSearch $tools)))
   $tools)

(= (codex:tool-search-output-namespace $name $description $tools)
   (CodexToolSearchOutputNamespace $name $description $tools))

(= (codex:tool-search-output-namespace-name
      (CodexToolSearchOutputNamespace $name $description $tools))
   $name)

(= (codex:tool-search-output-namespace-description
      (CodexToolSearchOutputNamespace $name $description $tools))
   $description)

(= (codex:tool-search-output-namespace-tools
      (CodexToolSearchOutputNamespace $name $description $tools))
   $tools)

(= (codex:tool-search-entry-document $entries $index)
   (let $entry (index-atom $entries $index)
     (codex:bm25-document
       $index
       (codex:tool-search-entry-search-text $entry))))

(= (codex:tool-search-entry-documents $entries)
   (let $indexes (range-atom (size-atom $entries))
     (map-atom-strict
       $indexes
       $index
       (codex:tool-search-entry-document $entries $index))))

(= (codex:tool-search-bm25-result-entry $entries $result)
   (index-atom
     $entries
     (codex:bm25-search-result-document-id $result)))

(= (codex:tool-search-rank-entries $query $entries)
   (let $documents (codex:tool-search-entry-documents $entries)
     (case (codex:bm25-search-documents $documents $query CodexAbsent)
       (($results
          (map-atom-strict
            $results
            $result
            (codex:tool-search-bm25-result-entry $entries $result)))))))

(= (tool-search-take-local $items $limit)
   (if (<= $limit 0)
       ()
       (if (== $items ())
           ()
           (let ($head $tail) (decons-atom $items)
               (let $rest
                 (eval (tool-search-take-local $tail (- $limit 1)))
                 (cons-atom $head $rest))))))

(= (codex:tool-search-take $items $limit)
   (if (<= $limit 0)
       ()
       (let $item-count (size-atom $items)
         (if (== $item-count 0)
           ()
           (let $take-count
             (if (< $limit $item-count)
                 $limit
                 $item-count)
             (let $range (range-atom $take-count)
               (map-atom-strict
                 $range
                 $index
                 (index-atom $items $index))))))))

(= (tool-search-entry-limit-bucket-local
      (CodexToolSearchEntry $search-text $output $limit-bucket))
   $limit-bucket)

(= (tool-search-entry-output-local
      (CodexToolSearchEntry $search-text $output $limit-bucket))
   $output)

(= (tool-search-is-entry-in-bucket-local $entry $bucket)
   (case (tool-search-entry-limit-bucket-local $entry)
     ((CodexAbsent False)
      ($entry-bucket (== $entry-bucket $bucket)))))

(= (codex:is-tool-search-entry-in-bucket $entry $bucket)
   (tool-search-is-entry-in-bucket-local $entry $bucket))

(= (codex:tool-search-any-limit-bucket $entries $bucket)
   (> (codex:tool-search-count-results-for-bucket $entries $bucket) 0))

(= (codex:tool-search-count-results-for-bucket $results $bucket)
   (let $matching
     (filter-atom
       $results
       $entry
       (tool-search-is-entry-in-bucket-local $entry $bucket))
     (size-atom $matching)))

; Rust uses `Iterator::scan` with a mutable `HashMap<&str, usize>`. The pure
; CeTTa form below is an equivalent index scan: for each result, count preceding
; same-bucket entries and keep the result iff that count is still below the
; Rust default limit for the bucket.
(= (tool-search-result-index-accepted-by-bucket-local $results $index)
   (let $entry (index-atom $results $index)
     (case (tool-search-entry-limit-bucket-local $entry)
       ((CodexAbsent True)
        ($bucket
         (let $prior-results (codex:tool-search-take $results $index)
           (< (codex:tool-search-count-results-for-bucket
                $prior-results
                $bucket)
              (codex:tool-search-default-limit-for-bucket $bucket))))))))

(= (codex:tool-search-limit-results-by-bucket $results)
   (let $indexes (range-atom (size-atom $results))
     (let $accepted-indexes
       (filter-atom
         $indexes
         $index
         (tool-search-result-index-accepted-by-bucket-local $results $index))
       (map-atom-strict
         $accepted-indexes
         $index
         (index-atom $results $index)))))

(= (codex:tool-search-search-result-entries
      $entries
      $query
      $limit
      $use-default-limit)
   (let $ranked
     (codex:tool-search-rank-entries $query $entries)
     (let $results
       (codex:tool-search-take $ranked $limit)
       (if $use-default-limit
           (if (== $results ())
               ()
               (if (codex:tool-search-any-limit-bucket
                     $results
                     (codex:tool-search-computer-use-mcp-server-name))
                   (let $expanded
                     (codex:tool-search-take
                       $ranked
                       (codex:tool-search-computer-use-tool-search-limit))
                     (codex:tool-search-limit-results-by-bucket $expanded))
                   (codex:tool-search-limit-results-by-bucket $results)))
           $results))))

(= (codex:tool-search-default-namespace-description $namespace)
   (str-concat
     "Tools in the "
     (str-concat $namespace " namespace.")))

(= (codex:tool-search-trimmed-optional-text $value)
   (case $value
     ((CodexAbsent CodexAbsent)
      ($other
       (let $trimmed (str-trim $other)
         (if (== $trimmed "")
             CodexAbsent
             $trimmed))))))

(= (codex:tool-search-mcp-namespace-description
      $tool-namespace
      $connector-name
      $connector-description)
   (case (codex:tool-search-trimmed-optional-text $connector-description)
     ((CodexAbsent
       (case (codex:tool-search-trimmed-optional-text $connector-name)
         ((CodexAbsent
           (codex:tool-search-default-namespace-description $tool-namespace))
          ($name
           (str-concat
             "Tools for working with "
             (str-concat $name "."))))))
      ($description $description))))

(= (codex:tool-search-output-as-loadable-spec
      (CodexToolSearchOutputMcp
        $server-name
        $tool-namespace
        $tool-name
        $connector-name
        $connector-description))
   (let $description
     (codex:tool-search-mcp-namespace-description
       $tool-namespace
       $connector-name
       $connector-description)
     (codex:tool-search-output-namespace
       $tool-namespace
       $description
       ((CodexToolSearchOutputMcp
          $server-name
          $tool-namespace
          $tool-name
          $connector-name
          $connector-description)))))

(= (codex:tool-search-output-as-loadable-spec
      (CodexToolSearchOutputDynamic $namespace $name))
   (case $namespace
     ((CodexAbsent (CodexToolSearchOutputDynamic CodexAbsent $name))
      ($real-namespace
       (let $description
         (codex:tool-search-default-namespace-description $real-namespace)
         (codex:tool-search-output-namespace
           $real-namespace
           $description
           ((CodexToolSearchOutputDynamic $real-namespace $name))))))))

(= (codex:tool-search-output-as-loadable-spec
      (CodexToolSearchOutputNamespace $name $description $tools))
   (CodexToolSearchOutputNamespace $name $description $tools))

(= (codex:tool-search-coalesce-namespace $coalesced $name $description $tools)
   (if (== $coalesced ())
       ((CodexToolSearchOutputNamespace $name $description $tools))
       (let $head (list:first $coalesced)
         (let $tail (list:rest $coalesced)
           (case $head
             (((CodexToolSearchOutputNamespace
                 $head-name
                 $head-description
                 $head-tools)
               (if (== $head-name $name)
                   (cons-atom
                     (codex:tool-search-output-namespace
                       $head-name
                       $head-description
                       (list:append $head-tools $tools))
                     $tail)
                   (let $coalesced-tail
                     (eval (codex:tool-search-coalesce-namespace
                             $tail
                             $name
                             $description
                             $tools))
                     (cons-atom $head $coalesced-tail))))
              ($other
               (let $coalesced-tail
                 (eval (codex:tool-search-coalesce-namespace
                         $tail
                         $name
                         $description
                         $tools))
                 (cons-atom $head $coalesced-tail)))))))))

(= (codex:tool-search-coalesce-one $coalesced $spec)
   (case $spec
     (((CodexToolSearchOutputNamespace $name $description $tools)
       (codex:tool-search-coalesce-namespace
         $coalesced
         $name
         $description
         $tools))
      ($other
       (list:append $coalesced ($other))))))

(= (codex:tool-search-coalesce-loadable-tool-specs $outputs)
   (codex:tool-search-coalesce-loadable-tool-specs-acc $outputs ()))

(= (codex:tool-search-coalesce-loadable-tool-specs-acc () $coalesced)
   $coalesced)

(= (codex:tool-search-coalesce-loadable-tool-specs-acc $outputs $coalesced)
   (let $head (list:first $outputs)
     (let $tail (list:rest $outputs)
       (let $spec (codex:tool-search-output-as-loadable-spec $head)
         (let $next-coalesced
           (eval (codex:tool-search-coalesce-one $coalesced $spec))
           (codex:tool-search-coalesce-loadable-tool-specs-acc
             $tail
             $next-coalesced))))))

(= (codex:tool-search-entry-outputs $entries)
   (map-atom-strict
     $entries
     $entry
     (codex:tool-search-entry-output $entry)))

(= (codex:tool-search-search-output-tools $results)
   (let $outputs (eval (codex:tool-search-entry-outputs $results))
     (codex:tool-search-coalesce-loadable-tool-specs $outputs)))

(= (codex:tool-search-search $entries $query $limit $use-default-limit)
   (let $results
     (codex:tool-search-search-result-entries
       $entries
       $query
       $limit
       $use-default-limit)
     (codex:tool-search-search-output-tools $results)))

(= (codex:tool-search-resolved-limit $requested-limit)
   (case $requested-limit
     ((CodexAbsent (codex:tool-search-default-limit))
      ($limit $limit))))

(= (codex:is-tool-search-requested-limit-absent $requested-limit)
   (case $requested-limit
     ((CodexAbsent True)
      ($limit False))))

(= (codex:run-tool-search-handler-arguments $entries $query $requested-limit)
   (let $trimmed-query (str-trim $query)
     (if (== $trimmed-query "")
         (codex:tool-search-handler-err
           (codex:function-call-error-respond-to-model
             "query must not be empty"))
         (let $limit (codex:tool-search-resolved-limit $requested-limit)
           (if (== $limit 0)
               (codex:tool-search-handler-err
                 (codex:function-call-error-respond-to-model
                   "limit must be greater than zero"))
               (if (== $entries ())
                   (codex:tool-search-handler-ok
                     (codex:tool-search-tool-output ()))
                   (codex:tool-search-handler-ok
                     (codex:tool-search-tool-output
                       (codex:tool-search-search
                         $entries
                         $trimmed-query
                         $limit
                         (codex:is-tool-search-requested-limit-absent
                           $requested-limit))))))))))

(= (codex:run-tool-search-handler $entries $payload)
   (case $payload
     (((CodexToolPayloadToolSearch $query $requested-limit)
       (codex:run-tool-search-handler-arguments
         $entries
         $query
         $requested-limit))
      ($other
       (codex:tool-search-handler-err
         (codex:function-call-error-fatal
           "tool_search handler received unsupported payload"))))))
