; Rust-faithful web-search display detail helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/web_search.rs
;
; Covered in this increment:
; - search_action_detail
; - web_search_action_detail
; - web_search_detail
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust models optional strings and query vectors as `Option<String>` and
;   `Option<Vec<String>>`. This CeTTa slice uses the existing `CodexAbsent`
;   sentinel and list values at the protocol boundary.

!(import! &self protocol)
!(import! &self str)

(= (codex:web-search-search-action-detail $query $queries)
   (if (== $query CodexAbsent)
       (if (== $queries CodexAbsent)
           ""
           (if (== $queries ())
               ""
               (let $first (list:first $queries)
                 (let $tail (list:rest $queries)
                   (if (== $first "")
                       $first
                       (if (== $tail ())
                           $first
                           (str-concat $first " ...")))))))
       (if (== $query "")
           (codex:web-search-search-action-detail CodexAbsent $queries)
           $query)))

(= (codex:web-search-action-detail
      (CodexWebSearchActionSearch $query $queries))
   (codex:web-search-search-action-detail $query $queries))

(= (codex:web-search-action-detail
      (CodexWebSearchActionOpenPage $url))
   (if (== $url CodexAbsent) "" $url))

(= (codex:web-search-action-detail
      (CodexWebSearchActionFindInPage $url $pattern))
   (if (== $pattern CodexAbsent)
       (if (== $url CodexAbsent) "" $url)
       (if (== $url CodexAbsent)
           (format-args "'{}'" ($pattern))
           (format-args "'{}' in {}" ($pattern $url)))))

(= (codex:web-search-action-detail
      (CodexWebSearchActionOther))
   "")

(= (codex:web-search-detail $action $query)
   (if (== $action CodexAbsent)
       $query
       (let $detail (codex:web-search-action-detail $action)
         (if (== $detail "")
             $query
             $detail))))
