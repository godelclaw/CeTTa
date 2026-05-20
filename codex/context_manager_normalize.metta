; Rust-faithful context-manager normalization helper slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/context_manager/normalize.rs
;
; Covered in this increment:
; - ensure_call_outputs_present
; - remove_orphan_outputs
; - remove_corresponding_for
; - strip_images_when_unsupported
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust mutates `&mut Vec<ResponseItem>` / `&mut [ResponseItem]` in place.
;   CeTTa terms are immutable, so this port returns rebuilt item lists while
;   preserving the same visible item order and inserted/removed payloads.
; - Rust logs or calls `error_or_panic` for malformed history. This pure slice
;   preserves the visible normalized history and omits those side effects.
; - Rust takes `&[InputModality]`; this slice models the same visible modality
;   membership through explicit `CodexInputModality*` constructors.

!(import! &self protocol)
!(import! &self list)

(= (codex:context-manager-image-content-omitted-placeholder)
   "image content omitted because you do not support image input")

(= (codex:input-modality-text)
   (CodexInputModalityText))

(= (codex:input-modality-image)
   (CodexInputModalityImage))

(= (codex:context-manager-normalize-list-contains $items $needle)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head $needle)
               True
               (codex:context-manager-normalize-list-contains
                 $tail
                 $needle))))))

(= (codex:context-manager-normalize-has-function-call-output $items $call-id)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (case $head
             (((CodexResponseItemFunctionCallOutput $existing-call-id $output)
               (if (== $existing-call-id $call-id)
                   True
                   (codex:context-manager-normalize-has-function-call-output
                     $tail
                     $call-id)))
              ($other
               (codex:context-manager-normalize-has-function-call-output
                 $tail
                 $call-id))))))))

(= (codex:context-manager-normalize-has-custom-tool-call-output $items $call-id)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (case $head
             (((CodexResponseItemCustomToolCallOutput
                 $existing-call-id
                 $name
                 $output)
               (if (== $existing-call-id $call-id)
                   True
                   (codex:context-manager-normalize-has-custom-tool-call-output
                     $tail
                     $call-id)))
              ($other
               (codex:context-manager-normalize-has-custom-tool-call-output
                 $tail
                 $call-id))))))))

(= (codex:context-manager-normalize-has-tool-search-output $items $call-id)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (case $head
             (((CodexResponseItemToolSearchOutput
                 $existing-call-id
                 $status
                 $execution
                 $tools)
               (if (== $existing-call-id $call-id)
                   True
                   (codex:context-manager-normalize-has-tool-search-output
                     $tail
                     $call-id)))
              ($other
               (codex:context-manager-normalize-has-tool-search-output
                 $tail
                 $call-id))))))))

(= (codex:context-manager-normalize-has-function-call $items $call-id)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (case $head
             (((CodexResponseItemFunctionCall
                 $id
                 $name
                 $namespace
                 $arguments
                 $existing-call-id)
               (if (== $existing-call-id $call-id)
                   True
                   (codex:context-manager-normalize-has-function-call
                     $tail
                     $call-id)))
              ($other
               (codex:context-manager-normalize-has-function-call
                 $tail
                 $call-id))))))))

(= (codex:context-manager-normalize-has-local-shell-call $items $call-id)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (case $head
             (((CodexResponseItemLocalShellCall
                 $id
                 $existing-call-id
                 $status
                 $action)
               (if (== $existing-call-id $call-id)
                   True
                   (codex:context-manager-normalize-has-local-shell-call
                     $tail
                     $call-id)))
              ($other
               (codex:context-manager-normalize-has-local-shell-call
                 $tail
                 $call-id))))))))

(= (codex:context-manager-normalize-has-custom-tool-call $items $call-id)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (case $head
             (((CodexResponseItemCustomToolCall $existing-call-id $name $input)
               (if (== $existing-call-id $call-id)
                   True
                   (codex:context-manager-normalize-has-custom-tool-call
                     $tail
                     $call-id)))
              ($other
               (codex:context-manager-normalize-has-custom-tool-call
                 $tail
                 $call-id))))))))

(= (codex:context-manager-normalize-has-tool-search-call $items $call-id)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (case $head
             (((CodexResponseItemToolSearchCall
                 $id
                 $existing-call-id
                 $status
                 $execution
                 $arguments)
               (if (== $existing-call-id $call-id)
                   True
                   (codex:context-manager-normalize-has-tool-search-call
                     $tail
                     $call-id)))
              ($other
               (codex:context-manager-normalize-has-tool-search-call
                 $tail
                 $call-id))))))))

(= (codex:context-manager-normalize-aborted-function-output $call-id)
   (CodexResponseItemFunctionCallOutput
     $call-id
     (CodexFunctionCallOutputText "aborted")))

(= (codex:context-manager-normalize-aborted-custom-output $call-id)
   (CodexResponseItemCustomToolCallOutput
     $call-id
     CodexAbsent
     (CodexFunctionCallOutputText "aborted")))

(= (codex:context-manager-normalize-empty-tool-search-output $call-id)
   (CodexResponseItemToolSearchOutput
     $call-id
     "completed"
     "client"
     ()))

(= (codex:context-manager-normalize-ensure-function-output-item
      $all-items
      $head
      $call-id
      $normalized-tail)
   (case (codex:context-manager-normalize-has-function-call-output
           $all-items
           $call-id)
     ((True
       (list:cons $head $normalized-tail))
      (False
       (list:cons
         $head
         (list:cons
           (codex:context-manager-normalize-aborted-function-output $call-id)
           $normalized-tail))))))

(= (codex:context-manager-normalize-ensure-custom-output-item
      $all-items
      $head
      $call-id
      $normalized-tail)
   (case (codex:context-manager-normalize-has-custom-tool-call-output
           $all-items
           $call-id)
     ((True
       (list:cons $head $normalized-tail))
      (False
       (list:cons
         $head
         (list:cons
           (codex:context-manager-normalize-aborted-custom-output $call-id)
           $normalized-tail))))))

(= (codex:context-manager-normalize-ensure-tool-search-output-item
      $all-items
      $head
      $call-id
      $normalized-tail)
   (case (codex:context-manager-normalize-has-tool-search-output
           $all-items
           $call-id)
     ((True
       (list:cons $head $normalized-tail))
      (False
       (list:cons
         $head
         (list:cons
           (codex:context-manager-normalize-empty-tool-search-output $call-id)
           $normalized-tail))))))

(= (codex:ensure-call-outputs-present $items)
   (codex:context-manager-normalize-ensure-call-outputs-present-loop
     $items
     $items))

(= (codex:context-manager-normalize-ensure-call-outputs-present-loop
      $all-items
      ())
   ())

(= (codex:context-manager-normalize-ensure-call-outputs-present-loop
      $all-items
      $items)
   (let $raw-head (list:first $items)
     (let $tail (list:rest $items)
       (let $head $raw-head
         (case
           (codex:context-manager-normalize-ensure-call-outputs-present-loop
             $all-items
             $tail)
           (($normalized-tail
             (case $head
               (((CodexResponseItemFunctionCall
                   $id
                   $name
                   $namespace
                   $arguments
                   $call-id)
                 (codex:context-manager-normalize-ensure-function-output-item
                   $all-items
                   $head
                   $call-id
                   $normalized-tail))
                ((CodexResponseItemToolSearchCall
                   $id
                   $call-id
                   $status
                   $execution
                   $arguments)
                 (if (== $call-id CodexAbsent)
                     (list:cons $head $normalized-tail)
                     (codex:context-manager-normalize-ensure-tool-search-output-item
                       $all-items
                       $head
                       $call-id
                       $normalized-tail)))
                ((CodexResponseItemCustomToolCall $call-id $name $input)
                 (codex:context-manager-normalize-ensure-custom-output-item
                   $all-items
                   $head
                   $call-id
                   $normalized-tail))
                ((CodexResponseItemLocalShellCall $id $call-id $status $action)
                 (if (== $call-id CodexAbsent)
                     (list:cons $head $normalized-tail)
                     (codex:context-manager-normalize-ensure-function-output-item
                       $all-items
                       $head
                       $call-id
                       $normalized-tail)))
                ($other
                 (list:cons $head $normalized-tail)))))))))))

(= (codex:remove-orphan-outputs $items)
   (codex:context-manager-normalize-remove-orphan-outputs-loop $items $items))

(= (codex:context-manager-normalize-keep-function-output-item
      $all-items
      $head
      $call-id
      $normalized-tail)
   (case (codex:context-manager-normalize-has-function-call $all-items $call-id)
     ((True
       (list:cons $head $normalized-tail))
      (False
       (case (codex:context-manager-normalize-has-local-shell-call
               $all-items
               $call-id)
         ((True
           (list:cons $head $normalized-tail))
          (False
           $normalized-tail)))))))

(= (codex:context-manager-normalize-keep-custom-output-item
      $all-items
      $head
      $call-id
      $normalized-tail)
   (case (codex:context-manager-normalize-has-custom-tool-call
           $all-items
           $call-id)
     ((True
       (list:cons $head $normalized-tail))
      (False
       $normalized-tail))))

(= (codex:context-manager-normalize-keep-tool-search-output-item
      $all-items
      $head
      $call-id
      $normalized-tail)
   (case (codex:context-manager-normalize-has-tool-search-call
           $all-items
           $call-id)
     ((True
       (list:cons $head $normalized-tail))
      (False
       $normalized-tail))))

(= (codex:context-manager-normalize-remove-orphan-outputs-loop $all-items ())
   ())

(= (codex:context-manager-normalize-remove-orphan-outputs-loop $all-items $items)
   (let $raw-head (list:first $items)
     (let $tail (list:rest $items)
       (let $head $raw-head
         (case
           (codex:context-manager-normalize-remove-orphan-outputs-loop
             $all-items
             $tail)
           (($normalized-tail
             (case $head
               (((CodexResponseItemFunctionCallOutput $call-id $output)
                 (codex:context-manager-normalize-keep-function-output-item
                   $all-items
                   $head
                   $call-id
                   $normalized-tail))
                ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
                 (codex:context-manager-normalize-keep-custom-output-item
                   $all-items
                   $head
                   $call-id
                   $normalized-tail))
                ((CodexResponseItemToolSearchOutput
                   $call-id
                   $status
                   "server"
                   $tools)
                 (list:cons $head $normalized-tail))
                ((CodexResponseItemToolSearchOutput
                   CodexAbsent
                   $status
                   $execution
                   $tools)
                 (list:cons $head $normalized-tail))
                ((CodexResponseItemToolSearchOutput
                   $call-id
                   $status
                   $execution
                   $tools)
                 (codex:context-manager-normalize-keep-tool-search-output-item
                   $all-items
                   $head
                   $call-id
                   $normalized-tail))
                ($other
                 (list:cons $head $normalized-tail)))))))))))

(= (codex:context-manager-normalize-remove-first-function-output
      ()
      $call-id)
   ())

(= (codex:context-manager-normalize-remove-first-function-output $items $call-id)
   (let $raw-head (list:first $items)
     (let $tail (list:rest $items)
       (let $head $raw-head
         (case $head
           (((CodexResponseItemFunctionCallOutput $existing-call-id $output)
             (if (== $existing-call-id $call-id)
                 $tail
                 (list:cons
                   $head
                   (codex:context-manager-normalize-remove-first-function-output
                     $tail
                     $call-id))))
            ($other
             (list:cons
               $head
               (codex:context-manager-normalize-remove-first-function-output
                $tail
                 $call-id)))))))))

(= (codex:context-manager-normalize-remove-first-custom-output $items $call-id)
   (if (== $items ())
       ()
       (let $raw-head (list:first $items)
         (let $tail (list:rest $items)
           (let $head $raw-head
             (case $head
               (((CodexResponseItemCustomToolCallOutput
                   $existing-call-id
                   $name
                   $output)
                 (if (== $existing-call-id $call-id)
                     $tail
                     (list:cons
                       $head
                       (codex:context-manager-normalize-remove-first-custom-output
                         $tail
                         $call-id))))
                ($other
                 (list:cons
                   $head
                   (codex:context-manager-normalize-remove-first-custom-output
                    $tail
                     $call-id))))))))))

(= (codex:context-manager-normalize-remove-first-tool-search-output
      $items
      $call-id)
   (if (== $items ())
       ()
       (let $raw-head (list:first $items)
         (let $tail (list:rest $items)
           (let $head $raw-head
             (case $head
               (((CodexResponseItemToolSearchOutput
                   $existing-call-id
                   $status
                   $execution
                   $tools)
                 (if (== $existing-call-id $call-id)
                     $tail
                     (list:cons
                       $head
                       (codex:context-manager-normalize-remove-first-tool-search-output
                         $tail
                         $call-id))))
                ($other
                 (list:cons
                   $head
                   (codex:context-manager-normalize-remove-first-tool-search-output
                    $tail
                     $call-id))))))))))

(= (codex:context-manager-normalize-remove-first-function-call $items $call-id)
   (if (== $items ())
       ()
       (let $raw-head (list:first $items)
         (let $tail (list:rest $items)
           (let $head $raw-head
             (case $head
               (((CodexResponseItemFunctionCall
                   $id
                   $name
                   $namespace
                   $arguments
                   $existing-call-id)
                 (if (== $existing-call-id $call-id)
                     $tail
                     (list:cons
                       $head
                       (codex:context-manager-normalize-remove-first-function-call
                         $tail
                         $call-id))))
                ($other
                 (list:cons
                   $head
                   (codex:context-manager-normalize-remove-first-function-call
                    $tail
                     $call-id))))))))))

(= (codex:context-manager-normalize-remove-first-local-shell-call $items $call-id)
   (if (== $items ())
       ()
       (let $raw-head (list:first $items)
         (let $tail (list:rest $items)
           (let $head $raw-head
             (case $head
               (((CodexResponseItemLocalShellCall
                   $id
                   $existing-call-id
                   $status
                   $action)
                 (if (== $existing-call-id $call-id)
                     $tail
                     (list:cons
                       $head
                       (codex:context-manager-normalize-remove-first-local-shell-call
                         $tail
                         $call-id))))
                ($other
                 (list:cons
                   $head
                   (codex:context-manager-normalize-remove-first-local-shell-call
                    $tail
                     $call-id))))))))))

(= (codex:context-manager-normalize-remove-first-tool-search-call
      $items
      $call-id)
   (if (== $items ())
       ()
       (let $raw-head (list:first $items)
         (let $tail (list:rest $items)
           (let $head $raw-head
             (case $head
               (((CodexResponseItemToolSearchCall
                   $id
                   $existing-call-id
                   $status
                   $execution
                   $arguments)
                 (if (== $existing-call-id $call-id)
                     $tail
                     (list:cons
                       $head
                       (codex:context-manager-normalize-remove-first-tool-search-call
                         $tail
                         $call-id))))
                ($other
                 (list:cons
                   $head
                   (codex:context-manager-normalize-remove-first-tool-search-call
                    $tail
                     $call-id))))))))))

(= (codex:context-manager-normalize-remove-first-custom-call $items $call-id)
   (if (== $items ())
       ()
       (let $raw-head (list:first $items)
         (let $tail (list:rest $items)
           (let $head $raw-head
             (case $head
               (((CodexResponseItemCustomToolCall
                   $existing-call-id
                   $name
                   $input)
                 (if (== $existing-call-id $call-id)
                     $tail
                     (list:cons
                       $head
                       (codex:context-manager-normalize-remove-first-custom-call
                         $tail
                         $call-id))))
                ($other
                 (list:cons
                   $head
                   (codex:context-manager-normalize-remove-first-custom-call
                    $tail
                     $call-id))))))))))

(= (codex:context-manager-normalize-remove-first-call-or-local-shell
      $items
      $call-id)
   (let $without-function
     (codex:context-manager-normalize-remove-first-function-call
       $items
       $call-id)
     (if (== $without-function $items)
         (codex:context-manager-normalize-remove-first-local-shell-call
           $items
           $call-id)
         $without-function)))

(= (codex:remove-corresponding-for $items $item)
   (case $item
     (((CodexResponseItemFunctionCall $id $name $namespace $arguments $call-id)
       (codex:context-manager-normalize-remove-first-function-output
         $items
         $call-id))
      ((CodexResponseItemFunctionCallOutput $call-id $output)
       (codex:context-manager-normalize-remove-first-call-or-local-shell
         $items
         $call-id))
      ((CodexResponseItemToolSearchCall
         $id
         $call-id
         $status
         $execution
         $arguments)
       (if (== $call-id CodexAbsent)
           $items
           (codex:context-manager-normalize-remove-first-tool-search-output
             $items
             $call-id)))
      ((CodexResponseItemToolSearchOutput
         $call-id
         $status
         $execution
         $tools)
       (if (== $call-id CodexAbsent)
           $items
           (codex:context-manager-normalize-remove-first-tool-search-call
             $items
             $call-id)))
      ((CodexResponseItemCustomToolCall $call-id $name $input)
       (codex:context-manager-normalize-remove-first-custom-output
         $items
         $call-id))
      ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
       (codex:context-manager-normalize-remove-first-custom-call
         $items
         $call-id))
      ((CodexResponseItemLocalShellCall $id $call-id $status $action)
       (if (== $call-id CodexAbsent)
           $items
           (codex:context-manager-normalize-remove-first-function-output
             $items
             $call-id)))
      ($other $items))))

(= (codex:context-manager-normalize-strip-content-items ())
   ())

(= (codex:context-manager-normalize-strip-content-items $items)
   (let $raw-head (list:first $items)
     (let $tail (list:rest $items)
       (let $head $raw-head
         (case
           (codex:context-manager-normalize-strip-content-items $tail)
           (($stripped-tail
             (case $head
               (((CodexInputImage $image-url $detail)
                 (list:cons
                   (CodexInputText
                     (codex:context-manager-image-content-omitted-placeholder))
                   $stripped-tail))
                ($other
                 (list:cons $head $stripped-tail)))))))))))

(= (codex:context-manager-normalize-strip-output
      (CodexFunctionCallOutputText $text))
   (CodexFunctionCallOutputText $text))

(= (codex:context-manager-normalize-strip-output
      (CodexFunctionCallOutputContentItems $items))
   (case (codex:context-manager-normalize-strip-content-items $items)
     (($stripped-items
       (CodexFunctionCallOutputContentItems $stripped-items)))))

(= (codex:strip-images-when-unsupported $input-modalities $items)
   (case (codex:context-manager-normalize-list-contains
           $input-modalities
           (CodexInputModalityImage))
     ((True
       $items)
      (False
       (codex:context-manager-normalize-strip-images-loop $items)))))

(= (codex:context-manager-normalize-strip-images-loop ())
   ())

(= (codex:context-manager-normalize-strip-images-loop $items)
   (let $raw-head (list:first $items)
     (let $tail (list:rest $items)
       (let $head $raw-head
         (case
           (codex:context-manager-normalize-strip-images-loop $tail)
           (($stripped-tail
             (case $head
               (((CodexResponseItemMessage $role $content $phase)
                 (case
                   (codex:context-manager-normalize-strip-content-items $content)
                   (($stripped-content
                     (list:cons
                       (CodexResponseItemMessage
                         $role
                         $stripped-content
                         $phase)
                       $stripped-tail)))))
                ((CodexResponseItemMessageWithId $id $role $content $phase)
                 (case
                   (codex:context-manager-normalize-strip-content-items $content)
                   (($stripped-content
                     (list:cons
                       (CodexResponseItemMessageWithId
                         $id
                         $role
                         $stripped-content
                         $phase)
                       $stripped-tail)))))
                ((CodexResponseItemFunctionCallOutput $call-id $output)
                 (case (codex:context-manager-normalize-strip-output $output)
                   (($stripped-output
                     (list:cons
                       (CodexResponseItemFunctionCallOutput
                         $call-id
                         $stripped-output)
                       $stripped-tail)))))
                ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
                 (case (codex:context-manager-normalize-strip-output $output)
                   (($stripped-output
                     (list:cons
                       (CodexResponseItemCustomToolCallOutput
                         $call-id
                         $name
                         $stripped-output)
                       $stripped-tail)))))
                ((CodexResponseItemImageGenerationCall
                   $id
                   $status
                   $revised-prompt
                   $result)
                 (list:cons
                   (CodexResponseItemImageGenerationCall
                     $id
                     $status
                     $revised-prompt
                     "")
                   $stripped-tail))
                ($other
                 (list:cons $head $stripped-tail)))))))))))
