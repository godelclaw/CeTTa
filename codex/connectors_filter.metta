; Pure Rust-faithful connectors filter helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/connectors/src/filter.rs
;
; Covered in this increment:
; - DISALLOWED_CONNECTOR_IDS
; - FIRST_PARTY_CHAT_DISALLOWED_CONNECTOR_IDS
; - DISALLOWED_CONNECTOR_PREFIX
; - is_connector_id_allowed
; - filter_disallowed_connectors
;
; Required CeTTa representation notes for audit:
; - Rust receives `Vec<AppInfo>` and filters by `AppInfo.id`, preserving vector
;   order. This helper receives the existing CeTTa `CodexAppInfo` list from the
;   context fragment slice and preserves list order with the same id predicate.

!(import! &self context_fragment)
!(import! &self default_client)
!(import! &self list)
!(import! &self str)

(= (codex:connectors-filter-disallowed-connector-ids)
   ("asdk_app_6938a94a61d881918ef32cb999ff937c"
    "connector_2b0a9009c9c64bf9933a3dae3f2b1254"
    "connector_3f8d1a79f27c4c7ba1a897ab13bf37dc"
    "connector_68de829bf7648191acd70a907364c67c"
    "connector_68e004f14af881919eb50893d3d9f523"
    "connector_69272cb413a081919685ec3c88d1744e"))

(= (codex:connectors-filter-first-party-chat-disallowed-connector-ids)
   ("connector_0f9c9d4592e54d0a9a12b3f44a1e2010"))

(= (codex:connectors-filter-disallowed-connector-prefix)
   "connector_openai_")

(= (codex:connectors-filter-list-contains () $item)
   False)

(= (codex:connectors-filter-list-contains $items $item)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (if (== $head $item)
           True
           (codex:connectors-filter-list-contains $tail $item)))))

(= (codex:connectors-filter-disallowed-ids-for-originator $originator-value)
   (if (codex:default-client-is-first-party-chat-originator
         $originator-value)
       (codex:connectors-filter-first-party-chat-disallowed-connector-ids)
       (codex:connectors-filter-disallowed-connector-ids)))

(= (codex:connectors-filter-is-connector-id-allowed $connector-id $originator-value)
   (case
     (str-starts-with?
       $connector-id
       (eval (codex:connectors-filter-disallowed-connector-prefix)))
     ((True False)
      (False
       (case
         (codex:connectors-filter-list-contains
           (eval
             (codex:connectors-filter-disallowed-ids-for-originator
               $originator-value))
           $connector-id)
         ((True False)
          (False True)))))))

(= (codex:connectors-filter-disallowed-connectors () $originator-value)
   ())

(= (codex:connectors-filter-disallowed-connectors $connectors $originator-value)
   (let $head (list:first $connectors)
     (let $tail (list:rest $connectors)
       (if (codex:connectors-filter-is-connector-id-allowed
             (codex:app-info-id $head)
             $originator-value)
           (list:append
             ($head)
             (codex:connectors-filter-disallowed-connectors
               $tail
               $originator-value))
           (codex:connectors-filter-disallowed-connectors
             $tail
             $originator-value)))))
