; Rust-faithful client_common prompt-formatting slice.
;
; This ports the pure prompt input reserialization logic from:
; - openai-codex/codex-rs/core/src/client_common.rs
;
; Covered in this increment:
; - Prompt record/default surface used by the model-client request path.
; - Prompt::get_formatted_input gating on the Freeform apply_patch tool.
; - reserialize_shell_outputs, including the same call-id tracking table for
;   LocalShellCall, CustomToolCall(apply_patch), FunctionCall(shell,
;   container.exec, apply_patch), FunctionCallOutput, and
;   CustomToolCallOutput.
; - parse_structured_shell_output / build_structured_output /
;   strip_total_output_header.
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust mutates `&mut [ResponseItem]`; this CeTTa slice returns a rewritten
;   list while preserving the same left-to-right state transitions.
; - Rust's Prompt carries `BaseInstructions` and `Personality` concrete Rust
;   types. The restarted CeTTa port carries those fields as terms until their
;   full protocol/config surfaces are ported.

!(import! &self json)
!(import! &self list)
!(import! &self protocol)
!(import! &self str)
!(import! &self tool_registry_plan)

(= (codex:client-common-prompt
      $input
      $tools
      $parallel-tool-calls
      $base-instructions
      $personality
      $output-schema
      $output-schema-strict)
   (CodexClientCommonPrompt
     $input
     $tools
     $parallel-tool-calls
     $base-instructions
     $personality
     $output-schema
     $output-schema-strict))

(= (codex:client-common-prompt-default)
   (codex:client-common-prompt
     ()
     ()
     False
     CodexBaseInstructionsDefault
     CodexAbsent
     CodexAbsent
     True))

(= (codex:client-common-prompt-input
      (CodexClientCommonPrompt
        $input
        $tools
        $parallel-tool-calls
        $base-instructions
        $personality
        $output-schema
        $output-schema-strict))
   $input)

(= (codex:client-common-prompt-tools
      (CodexClientCommonPrompt
        $input
        $tools
        $parallel-tool-calls
        $base-instructions
        $personality
        $output-schema
        $output-schema-strict))
   $tools)

(= (codex:client-common-prompt-parallel-tool-calls
      (CodexClientCommonPrompt
        $input
        $tools
        $parallel-tool-calls
        $base-instructions
        $personality
        $output-schema
        $output-schema-strict))
   $parallel-tool-calls)

(= (codex:client-common-prompt-base-instructions
      (CodexClientCommonPrompt
        $input
        $tools
        $parallel-tool-calls
        $base-instructions
        $personality
        $output-schema
        $output-schema-strict))
   $base-instructions)

(= (codex:client-common-prompt-personality
      (CodexClientCommonPrompt
        $input
        $tools
        $parallel-tool-calls
        $base-instructions
        $personality
        $output-schema
        $output-schema-strict))
   $personality)

(= (codex:client-common-prompt-output-schema
      (CodexClientCommonPrompt
        $input
        $tools
        $parallel-tool-calls
        $base-instructions
        $personality
        $output-schema
        $output-schema-strict))
   $output-schema)

(= (codex:client-common-prompt-output-schema-strict
      (CodexClientCommonPrompt
        $input
        $tools
        $parallel-tool-calls
        $base-instructions
        $personality
        $output-schema
        $output-schema-strict))
   $output-schema-strict)

(= (codex:client-common-prompt-formatted-input
      (CodexClientCommonPrompt
        $input
        $tools
        $parallel-tool-calls
        $base-instructions
        $personality
        $output-schema
        $output-schema-strict))
   (if (codex:client-common-has-freeform-apply-patch-tool $tools)
       (codex:client-common-reserialize-shell-outputs $input)
       $input))

(= (codex:client-common-is-freeform-apply-patch-tool $tool)
   (case $tool
     (((CodexToolSpecFreeform
         (CodexFreeformTool
           "apply_patch"
           $description
           $format-type
           $format-syntax
           $format-definition))
       True)
      ($other
       False))))

(= (codex:client-common-has-freeform-apply-patch-tool $tools)
   (if (== $tools ())
       False
       (let $head (list:first $tools)
         (let $tail (list:rest $tools)
           (if (codex:client-common-is-freeform-apply-patch-tool $head)
               True
               (codex:client-common-has-freeform-apply-patch-tool $tail))))))

(= (codex:client-common-is-shell-tool-name $name)
   (case $name
     (("shell" True)
      ("container.exec" True)
      ($other False))))

(= (codex:client-common-call-id-set-contains $call-ids $call-id)
   (if (== $call-ids ())
       False
       (let $head (list:first $call-ids)
         (let $tail (list:rest $call-ids)
           (if (== $head $call-id)
               True
               (codex:client-common-call-id-set-contains $tail $call-id))))))

(= (codex:client-common-call-id-set-insert $call-ids $call-id)
   (if (== $call-id CodexAbsent)
       $call-ids
       (if (codex:client-common-call-id-set-contains $call-ids $call-id)
           $call-ids
           (cons-atom $call-id $call-ids))))

(= (codex:client-common-call-id-set-remove $call-ids $call-id)
   (if (== $call-ids ())
       ()
       (let $head (list:first $call-ids)
         (let $tail (list:rest $call-ids)
           (let $rest
             (codex:client-common-call-id-set-remove $tail $call-id)
             (if (== $head $call-id)
                 $rest
                 (cons-atom $head $rest)))))))

(= (codex:client-common-local-shell-identifier $call-id $id)
   (if (== $call-id CodexAbsent)
       $id
       $call-id))

(= (codex:client-common-track-call-item $call-ids $item)
   (case $item
     (((CodexResponseItemLocalShellCall $id $call-id $status $action)
       (codex:client-common-call-id-set-insert
         $call-ids
         (codex:client-common-local-shell-identifier $call-id $id)))
      ((CodexResponseItemCustomToolCall $call-id "apply_patch" $input)
       (codex:client-common-call-id-set-insert $call-ids $call-id))
      ((CodexResponseItemFunctionCall
         $id
         "apply_patch"
         $namespace
         $arguments
         $call-id)
       (codex:client-common-call-id-set-insert $call-ids $call-id))
      ((CodexResponseItemFunctionCall $id $name $namespace $arguments $call-id)
       (if (codex:client-common-is-shell-tool-name $name)
           (codex:client-common-call-id-set-insert $call-ids $call-id)
           $call-ids))
      ($other
       $call-ids))))

(= (codex:client-common-reserialized-item $item $call-ids)
   (CodexClientCommonReserializedItem $item $call-ids))

(= (codex:client-common-reserialized-item-item
      (CodexClientCommonReserializedItem $item $call-ids))
   $item)

(= (codex:client-common-reserialized-item-call-ids
      (CodexClientCommonReserializedItem $item $call-ids))
   $call-ids)

(= (codex:client-common-reserialized-items $items $call-ids)
   (CodexClientCommonReserializedItems $items $call-ids))

(= (codex:client-common-reserialized-items-items
      (CodexClientCommonReserializedItems $items $call-ids))
   $items)

(= (codex:client-common-reserialized-items-call-ids
      (CodexClientCommonReserializedItems $items $call-ids))
   $call-ids)

(= (codex:client-common-reserialize-shell-output $output)
   (case $output
     (((CodexFunctionCallOutputText $raw)
       (case (codex:client-common-parse-structured-shell-output $raw)
         ((CodexAbsent
           (CodexFunctionCallOutputText $raw))
          ($structured
           (CodexFunctionCallOutputText $structured)))))
      ($other
       $output))))

(= (codex:client-common-reserialize-output-item $call-ids $item)
   (case $item
     (((CodexResponseItemFunctionCallOutput $call-id $output)
       (if (codex:client-common-call-id-set-contains $call-ids $call-id)
           (codex:client-common-reserialized-item
             (CodexResponseItemFunctionCallOutput
               $call-id
               (codex:client-common-reserialize-shell-output $output))
             (codex:client-common-call-id-set-remove $call-ids $call-id))
           (codex:client-common-reserialized-item $item $call-ids)))
      ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
       (if (codex:client-common-call-id-set-contains $call-ids $call-id)
           (codex:client-common-reserialized-item
             (CodexResponseItemCustomToolCallOutput
               $call-id
               $name
               (codex:client-common-reserialize-shell-output $output))
             (codex:client-common-call-id-set-remove $call-ids $call-id))
           (codex:client-common-reserialized-item $item $call-ids)))
      ($other
       (codex:client-common-reserialized-item
         $item
         (codex:client-common-track-call-item $call-ids $item))))))

(= (codex:client-common-reserialize-shell-outputs $items)
   (codex:client-common-reserialized-items-items
     (codex:client-common-reserialize-shell-outputs-with-ids $items ())))

(= (codex:client-common-reserialize-shell-outputs-with-ids $items $call-ids)
   (if (== $items ())
       (codex:client-common-reserialized-items () $call-ids)
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (let $rewritten-head
             (codex:client-common-reserialize-output-item $call-ids $head)
             (let $next-call-ids
               (codex:client-common-reserialized-item-call-ids $rewritten-head)
               (case
                 (codex:client-common-reserialize-shell-outputs-with-ids
                   $tail
                   $next-call-ids)
                 (((CodexClientCommonReserializedItems
                     $rewritten-tail
                     $final-call-ids)
                   (codex:client-common-reserialized-items
                     (cons-atom
                       (codex:client-common-reserialized-item-item
                         $rewritten-head)
                       $rewritten-tail)
                     $final-call-ids))))))))))

(= (codex:client-common-split $left $right)
   (CodexClientCommonSplit $left $right))

(= (codex:client-common-split-left (CodexClientCommonSplit $left $right))
   $left)

(= (codex:client-common-split-right (CodexClientCommonSplit $left $right))
   $right)

(= (codex:client-common-split-first $text $needle)
   (case (str-find $text $needle)
     ((Empty CodexAbsent)
      ($index
       (codex:client-common-split
         (str-slice $text 0 $index)
         (str-slice
           $text
           (+ $index (str-length $needle))
           (str-length $text)))))))

(= (codex:client-common-decimal-digit-value "0")
   0)

(= (codex:client-common-decimal-digit-value "1")
   1)

(= (codex:client-common-decimal-digit-value "2")
   2)

(= (codex:client-common-decimal-digit-value "3")
   3)

(= (codex:client-common-decimal-digit-value "4")
   4)

(= (codex:client-common-decimal-digit-value "5")
   5)

(= (codex:client-common-decimal-digit-value "6")
   6)

(= (codex:client-common-decimal-digit-value "7")
   7)

(= (codex:client-common-decimal-digit-value "8")
   8)

(= (codex:client-common-decimal-digit-value "9")
   9)

(= (codex:is-client-common-decimal-digit $text)
   (case $text
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

(= (codex:client-common-parse-u32 $text)
   (if (== $text "")
       CodexAbsent
       (codex:client-common-parse-u32-from $text 0 0)))

(= (codex:client-common-parse-u32-from $text $index $acc)
   (if (== $index (str-length $text))
       $acc
       (let $char (str-slice $text $index (+ $index 1))
         (if (codex:is-client-common-decimal-digit $char)
             (let $next
               (+ (* $acc 10)
                  (codex:client-common-decimal-digit-value $char))
               (if (> $next 4294967295)
                   CodexAbsent
                   (codex:client-common-parse-u32-from
                     $text
                     (+ $index 1)
                     $next)))
             CodexAbsent))))

(= (codex:client-common-is-json-i32-text $text)
   (if (str-starts-with? $text "-")
       (let $digits (str-slice $text 1 (str-length $text))
         (case (codex:client-common-parse-u32 $digits)
           ((CodexAbsent False)
            ($value (<= $value 2147483648)))))
       (case (codex:client-common-parse-u32 $text)
         ((CodexAbsent False)
          ($value (<= $value 2147483647))))))

(= (codex:client-common-total-output-header $output $total-lines)
   (CodexClientCommonTotalOutputHeader $output $total-lines))

(= (codex:client-common-total-output-header-output
      (CodexClientCommonTotalOutputHeader $output $total-lines))
   $output)

(= (codex:client-common-total-output-header-total-lines
      (CodexClientCommonTotalOutputHeader $output $total-lines))
   $total-lines)

(= (codex:client-common-total-output-lines-prefix)
   "Total output lines: ")

(= (codex:client-common-strip-total-output-header $output)
   (case
     (str-starts-with?
       $output
       (codex:client-common-total-output-lines-prefix))
     ((False CodexAbsent)
      (True
       (let $after-prefix
         (str-slice
           $output
           (str-length (codex:client-common-total-output-lines-prefix))
           (str-length $output))
         (case (codex:client-common-split-first $after-prefix "\n")
           ((CodexAbsent CodexAbsent)
            ((CodexClientCommonSplit $total-segment $remainder)
             (case (codex:client-common-parse-u32 $total-segment)
               ((CodexAbsent CodexAbsent)
                ($total-lines
                 (codex:client-common-total-output-header
                   (case (str-starts-with? $remainder "\n")
                     ((True
                       (str-slice $remainder 1 (str-length $remainder)))
                      (False
                       $remainder)))
                   $total-lines))))))))))))

(= (codex:client-common-build-structured-output
      $output
      $exit-code
      $duration-seconds)
   (let $base
     (format-args
       "Exit code: {}\nWall time: {} seconds"
       ($exit-code $duration-seconds))
     (case (codex:client-common-strip-total-output-header $output)
       ((CodexAbsent
         (format-args "{}\nOutput:\n{}" ($base $output)))
        ((CodexClientCommonTotalOutputHeader $stripped $total-lines)
         (format-args
           "{}\nTotal output lines: {}\nOutput:\n{}"
           ($base $total-lines $stripped)))))))

(= (codex:client-common-parse-structured-shell-output $raw)
   (case (catch (eval (json-parse $raw)))
     (((Error $context $message)
       CodexAbsent)
      ((catch (JsonObject $pairs))
       (codex:client-common-parse-structured-shell-output-object
         (JsonObject $pairs)))
      ($other
       CodexAbsent))))

(= (codex:client-common-parse-structured-shell-output-object $object)
   (case (json-object-get $object "output")
     (((JsonString $output)
       (case (json-object-get $object "metadata")
         (((JsonObject $metadata-pairs)
           (codex:client-common-parse-structured-shell-output-metadata
             $output
             (JsonObject $metadata-pairs)))
          ($other CodexAbsent))))
      ($other
       CodexAbsent))))

(= (codex:client-common-parse-structured-shell-output-metadata
      $output
      $metadata)
   (case (json-object-get $metadata "exit_code")
     (((JsonNumber $exit-code)
       (if (codex:client-common-is-json-i32-text $exit-code)
           (case (json-object-get $metadata "duration_seconds")
             (((JsonNumber $duration-seconds)
               (codex:client-common-build-structured-output
                 $output
                 $exit-code
                 $duration-seconds))
              ($other
               CodexAbsent)))
           CodexAbsent))
      ($other
       CodexAbsent))))
