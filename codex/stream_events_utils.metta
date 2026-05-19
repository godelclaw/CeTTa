; Rust-faithful pure stream-event helper slice.
;
; This ports the pure helper behavior from:
; - openai-codex/codex-rs/core/src/stream_events_utils.rs
;
; Covered in this increment:
; - image_generation_artifact_path
; - strip_hidden_assistant_markup
; - strip_hidden_assistant_markup_and_parse_memory_citation
; - raw_assistant_output_text_from_item
; - response_item_may_include_external_context
; - last_assistant_message_from_item
; - completed_item_defers_mailbox_delivery_to_next_turn
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust also saves image bytes asynchronously after base64 decoding. This
;   slice ports the deterministic artifact path and message-routing decisions;
;   filesystem persistence belongs with the later async/runtime helper slice.
; - Rust uses `PathBuf::join` for all artifact path components. CeTTa appends
;   the constant/sanitized components lexically; after Rust's sanitizer has
;   removed path separators from session and call ids, the visible path is the
;   same for the absolute codex_home values used by Codex and avoids symbolic
;   path-helper reduction at this eval boundary.
; - The current CeTTa protocol serializer has not yet exposed Rust
;   `ResponseItem::ToolSearchCall`. This helper still recognizes the Rust
;   constructor shape locally so the external-context predicate keeps the same
;   algorithmic branch when that variant is passed through this boundary.

!(import! &self list)
!(import! &self memory_citation)
!(import! &self protocol)
!(import! &self str)
!(import! &self stream_parser)

(= (codex:generated-image-artifacts-dir)
   "generated_images")

(= (codex:image-generation-artifact-fallback-name)
   "generated_image")

(= (codex:stream-events-is-artifact-path-char $char)
   (case $char
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
      ("-" True)
      ("_" True)
      ($other False))))

(= (codex:image-generation-sanitize-artifact-component-from $value $index $acc)
   (if (== $index (str-length $value))
       $acc
       (let $char (str-slice $value $index (+ $index 1))
         (codex:image-generation-sanitize-artifact-component-from
           $value
           (+ $index 1)
           (str-concat
             $acc
             (if (codex:stream-events-is-artifact-path-char $char)
                 $char
                 "_"))))))

(= (codex:image-generation-sanitize-artifact-component $value)
   (let $sanitized
     (codex:image-generation-sanitize-artifact-component-from $value 0 "")
     (if (== $sanitized "")
         (codex:image-generation-artifact-fallback-name)
         $sanitized)))

(= (codex:image-generation-artifact-root $codex-home)
   (str-concat $codex-home "/generated_images"))

(= (codex:image-generation-artifact-path-from-components
      $generated-root
      $session-dir
      $file-name)
   (str-concat
     (str-concat
       (str-concat
         (str-concat $generated-root "/")
         $session-dir)
       "/")
     $file-name))

(= (codex:image-generation-artifact-path $codex-home $session-id $call-id)
   (codex:image-generation-artifact-path-session-from
     $codex-home
     $session-id
     $call-id
     0
     ""))

(= (codex:image-generation-artifact-path-session-from
      $codex-home
      $session-id
      $call-id
      $index
      $session-acc)
   (if (== $index (str-length $session-id))
       (let $session-dir
         (if (== $session-acc "")
             (codex:image-generation-artifact-fallback-name)
             $session-acc)
         (codex:image-generation-artifact-path-call-from
           $codex-home
           $session-dir
           $call-id
           0
           ""))
       (let $char (str-slice $session-id $index (+ $index 1))
         (codex:image-generation-artifact-path-session-from
           $codex-home
           $session-id
           $call-id
           (+ $index 1)
           (str-concat
             $session-acc
             (if (codex:stream-events-is-artifact-path-char $char)
                 $char
                 "_"))))))

(= (codex:image-generation-artifact-path-call-from
      $codex-home
      $session-dir
      $call-id
      $index
      $call-acc)
   (if (== $index (str-length $call-id))
       (let $call-name
         (if (== $call-acc "")
             (codex:image-generation-artifact-fallback-name)
             $call-acc)
         (str-concat
           (str-concat
             (str-concat
               (str-concat
                 (str-concat $codex-home "/generated_images/")
                 $session-dir)
               "/")
             $call-name)
           ".png"))
       (let $char (str-slice $call-id $index (+ $index 1))
         (codex:image-generation-artifact-path-call-from
           $codex-home
           $session-dir
           $call-id
           (+ $index 1)
           (str-concat
             $call-acc
             (if (codex:stream-events-is-artifact-path-char $char)
                 $char
                 "_"))))))

(= (codex:stream-events-hidden-markup-result $visible $memory-citation)
   (CodexStreamEventsHiddenMarkupResult $visible $memory-citation))

(= (codex:stream-events-hidden-markup-result-visible
      (CodexStreamEventsHiddenMarkupResult $visible $memory-citation))
   $visible)

(= (codex:stream-events-hidden-markup-result-memory-citation
      (CodexStreamEventsHiddenMarkupResult $visible $memory-citation))
   $memory-citation)

(= (codex:strip-hidden-assistant-markup $text $plan-mode)
   (case (once (eval (codex:strip-citations $text)))
     (((CodexStreamParserStripCitationsResult $without-citations $citations)
       (if $plan-mode
           (case
             (codex:strip-proposed-plan-blocks $without-citations)
             (($visible $visible)))
           $without-citations)))))

(= (codex:strip-hidden-assistant-markup-and-parse-memory-citation
      $text
      $plan-mode)
   (case (once (eval (codex:strip-citations $text)))
     (((CodexStreamParserStripCitationsResult $without-citations $citations)
       (let $visible
         (if $plan-mode
             (case
               (codex:strip-proposed-plan-blocks $without-citations)
               (($plan-stripped $plan-stripped)))
             $without-citations)
         (case (codex:parse-memory-citation $citations)
           (($memory-citation
             (codex:stream-events-hidden-markup-result
               $visible
               $memory-citation)))))))))

(= (codex:stream-events-output-text-content ())
   "")

(= (codex:stream-events-output-text-content $items)
   (codex:stream-events-output-text-content-acc $items ""))

(= (codex:stream-events-output-text-content-acc () $acc)
   $acc)

(= (codex:stream-events-output-text-content-acc $items $acc)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (case $head
        (((CodexOutputText $text)
           (codex:stream-events-output-text-content-acc
             $tail
             (str-concat $acc $text)))
          ($other
           (codex:stream-events-output-text-content-acc $tail $acc)))))))

(= (codex:raw-assistant-output-text-from-item $item)
   (case (once (eval $item))
     (((CodexResponseItemMessage "assistant" $content $phase)
       (codex:stream-events-output-text-content $content))
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       (codex:stream-events-output-text-content $content))
      ($other CodexAbsent))))

(= (codex:response-item-may-include-external-context $item)
   (case (once (eval $item))
     (((CodexResponseItemToolSearchCall
         $id
         $call-id
         $status
         $execution
         $arguments)
       True)
      ((CodexResponseItemToolSearchOutput
         $call-id
         $status
         $execution
         $tools)
       True)
      ((CodexResponseItemWebSearchCall $id $status $action)
       True)
      ($other False))))

(= (codex:last-assistant-message-from-item $item $plan-mode)
   (case (codex:raw-assistant-output-text-from-item $item)
     ((CodexAbsent
       CodexAbsent)
      ($raw-text
       (if (== $raw-text "")
           CodexAbsent
           (case
             (codex:strip-hidden-assistant-markup $raw-text $plan-mode)
             (($stripped
               (if (== (str-trim $stripped) "")
                   CodexAbsent
                   $stripped)))))))))

(= (codex:completed-item-defers-mailbox-delivery-to-next-turn
      $item
      $plan-mode)
   (case (once (eval $item))
     (((CodexResponseItemMessage "assistant" $content "commentary")
       False)
      ((CodexResponseItemMessageWithId $id "assistant" $content "commentary")
       False)
      ((CodexResponseItemMessage "assistant" $content $phase)
       (case
         (codex:last-assistant-message-from-item $item $plan-mode)
         ((CodexAbsent False)
          ($message True))))
      ((CodexResponseItemMessageWithId $id "assistant" $content $phase)
       (case
         (codex:last-assistant-message-from-item $item $plan-mode)
         ((CodexAbsent False)
          ($message True))))
      ((CodexResponseItemImageGenerationCall
         $id
         $status
         $revised-prompt
         $result)
       True)
      ($other False))))
