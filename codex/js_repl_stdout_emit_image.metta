; Rust-faithful js_repl read_stdout EmitImage branch slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - the `KernelToHost::EmitImage(req)` arm in `read_stdout`
;   - `emitted_image_content_item`
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust reads `ExecContext` from an `Arc<Mutex<HashMap<...>>>`, records
;   content items by mutating `ExecToolCalls`, writes to kernel stdin, and warns
;   on write failure. This pure slice receives symbolic contexts/stdin/write
;   outcomes and returns immutable state plus explicit actions/warnings in the
;   same branch order.
; - Rust's `ExecContext` carries a full turn; this slice only stores the turn
;   model-info field consumed by `emitted_image_content_item`.

!(import! &self function_tool)
!(import! &self image_detail)
!(import! &self js_repl)
!(import! &self js_repl_exec_tool_calls)
!(import! &self js_repl_kernel_io)
!(import! &self list)

(= (codex:js-repl-kernel-to-host-emit-image
      $id
      $exec-id
      $image-url
      $detail)
   (CodexJsReplKernelToHostEmitImage $id $exec-id $image-url $detail))

(= (codex:js-repl-emit-image-exec-context $model-info)
   (CodexJsReplEmitImageExecContext $model-info))

(= (codex:js-repl-emit-image-exec-context-model-info
      (CodexJsReplEmitImageExecContext $model-info))
   $model-info)

(= (codex:js-repl-emit-image-exec-context-entry $exec-id $context)
   (CodexJsReplEmitImageExecContextEntry $exec-id $context))

(= (codex:js-repl-emit-image-exec-context-entry-exec-id
      (CodexJsReplEmitImageExecContextEntry $exec-id $context))
   $exec-id)

(= (codex:js-repl-emit-image-exec-context-entry-context
      (CodexJsReplEmitImageExecContextEntry $exec-id $context))
   $context)

(= (codex:js-repl-emit-image-exec-contexts $entries)
   (CodexJsReplEmitImageExecContexts $entries))

(= (codex:js-repl-emit-image-exec-contexts-entries
      (CodexJsReplEmitImageExecContexts $entries))
   $entries)

(= (codex:js-repl-emit-image-context-lookup-missing)
   CodexJsReplEmitImageContextLookupMissing)

(= (codex:js-repl-emit-image-context-lookup-found $context)
   (CodexJsReplEmitImageContextLookupFound $context))

(= (codex:js-repl-emit-image-context-lookup-value
      CodexJsReplEmitImageContextLookupMissing)
   CodexAbsent)

(= (codex:js-repl-emit-image-context-lookup-value
      (CodexJsReplEmitImageContextLookupFound $context))
   $context)

(= (codex:js-repl-emit-image-find-context-entry
      ()
      $exec-id)
   CodexJsReplEmitImageContextLookupMissing)

(= (codex:js-repl-emit-image-find-context-entry
      $entries
      $exec-id)
   (let $entry (list:first $entries)
     (if (== (codex:js-repl-emit-image-exec-context-entry-exec-id $entry)
             $exec-id)
         (CodexJsReplEmitImageContextLookupFound
           (codex:js-repl-emit-image-exec-context-entry-context $entry))
         (codex:js-repl-emit-image-find-context-entry
           (list:rest $entries)
           $exec-id))))

(= (codex:js-repl-emit-image-contexts-find
      (CodexJsReplEmitImageExecContexts $entries)
      $exec-id)
   (codex:js-repl-emit-image-find-context-entry $entries $exec-id))

(= (codex:js-repl-emitted-image-detail-or-default $model-info $detail)
   (case (codex:normalize-output-image-detail $model-info $detail)
     ((CodexAbsent (codex:image-detail-default-detail))
      ($normalized $normalized))))

(= (codex:js-repl-emitted-image-content-item $context $image-url $detail)
   (CodexInputImage
     $image-url
     (codex:js-repl-emitted-image-detail-or-default
       (codex:js-repl-emit-image-exec-context-model-info $context)
       $detail)))

(= (codex:js-repl-emit-image-context-missing-message)
   "js_repl exec context not found")

(= (codex:js-repl-read-stdout-emit-image-warning-message)
   "failed to reply to kernel emit_image request")

(= (codex:js-repl-read-stdout-emit-image-action-record-content-item
      $exec-id
      $content-item)
   (CodexJsReplReadStdoutEmitImageActionRecordContentItem
     $exec-id
     $content-item))

(= (codex:js-repl-read-stdout-emit-image-action-write-message
      $message
      $write-result)
   (CodexJsReplReadStdoutEmitImageActionWriteMessage
     $message
     $write-result))

(= (codex:js-repl-read-stdout-emit-image-warning-write-failed
      $exec-id
      $emit-id
      $error
      $snapshot)
   (CodexJsReplReadStdoutEmitImageWarningWriteFailed
     (codex:js-repl-read-stdout-emit-image-warning-message)
     $exec-id
     $emit-id
     $error
     $snapshot))

(= (codex:js-repl-read-stdout-emit-image-record-actions
      $content-item
      $exec-id)
   (case $content-item
     ((CodexAbsent ())
      ($item
       ((codex:js-repl-read-stdout-emit-image-action-record-content-item
          $exec-id
          $item))))))

(= (codex:js-repl-read-stdout-emit-image-write-warnings
      (CodexJsReplWriteMessageOk $writes)
      $exec-id
      $emit-id
      $child-inspection
      $recent-stderr)
   ())

(= (codex:js-repl-read-stdout-emit-image-write-warnings
      (CodexJsReplWriteMessageError $error $writes)
      $exec-id
      $emit-id
      $child-inspection
      $recent-stderr)
   ((codex:js-repl-read-stdout-emit-image-warning-write-failed
      $exec-id
      $emit-id
      (codex:function-call-error-display $error)
      (codex:js-repl-kernel-debug-snapshot-from-inspection
        $child-inspection
        $recent-stderr))))

(= (codex:js-repl-read-stdout-emit-image-branch-result
      $exec-tool-calls
      $response
      $content-item)
   (CodexJsReplReadStdoutEmitImageBranchResult
     $exec-tool-calls
     $response
     $content-item))

(= (codex:js-repl-read-stdout-emit-image-branch-result-exec-tool-calls
      (CodexJsReplReadStdoutEmitImageBranchResult
        $exec-tool-calls $response $content-item))
   $exec-tool-calls)

(= (codex:js-repl-read-stdout-emit-image-branch-result-response
      (CodexJsReplReadStdoutEmitImageBranchResult
        $exec-tool-calls $response $content-item))
   $response)

(= (codex:js-repl-read-stdout-emit-image-branch-result-content-item
      (CodexJsReplReadStdoutEmitImageBranchResult
        $exec-tool-calls $response $content-item))
   $content-item)

(= (codex:js-repl-read-stdout-emit-image-with-context
      (CodexJsReplEmitImageExecContext $model-info)
      (CodexJsReplKernelToHostEmitImage $id $exec-id $image-url $detail)
      $exec-tool-calls)
   (case (codex:js-repl-validate-emitted-image-url $image-url)
     (((CodexJsReplValidationOk)
       (let $context (CodexJsReplEmitImageExecContext $model-info)
         (let $content-item
           (codex:js-repl-emitted-image-content-item
             $context
             $image-url
             $detail)
           (CodexJsReplReadStdoutEmitImageBranchResult
             (codex:js-repl-record-exec-content-item-map
               $exec-tool-calls
               $exec-id
               $content-item)
             (codex:js-repl-host-to-kernel-emit-image-result
               (codex:js-repl-emit-image-result
                 $id
                 True
                 CodexAbsent))
             $content-item))))
      ((CodexJsReplValidationError $message)
       (CodexJsReplReadStdoutEmitImageBranchResult
         $exec-tool-calls
         (codex:js-repl-host-to-kernel-emit-image-result
           (codex:js-repl-emit-image-result
             $id
             False
             $message))
         CodexAbsent)))))

(= (codex:js-repl-read-stdout-emit-image-without-context
      (CodexJsReplKernelToHostEmitImage $id $exec-id $image-url $detail)
      $exec-tool-calls)
   (CodexJsReplReadStdoutEmitImageBranchResult
     $exec-tool-calls
     (codex:js-repl-host-to-kernel-emit-image-result
       (codex:js-repl-emit-image-result
         $id
         False
         (codex:js-repl-emit-image-context-missing-message)))
     CodexAbsent))

(= (codex:js-repl-read-stdout-emit-image-branch
      $request
      $exec-contexts
      $exec-tool-calls)
   (case $request
     (((CodexJsReplKernelToHostEmitImage $id $exec-id $image-url $detail)
       (case (codex:js-repl-emit-image-contexts-find
               $exec-contexts
               $exec-id)
         ((CodexJsReplEmitImageContextLookupMissing
           (codex:js-repl-read-stdout-emit-image-without-context
             $request
             $exec-tool-calls))
          ((CodexJsReplEmitImageContextLookupFound $context)
           (codex:js-repl-read-stdout-emit-image-with-context
             $context
             $request
             $exec-tool-calls))))))))

(= (codex:js-repl-read-stdout-emit-image-step-result
      $exec-contexts
      $exec-tool-calls
      $response
      $write-result
      $actions
      $warnings)
   (CodexJsReplReadStdoutEmitImageStepResult
     $exec-contexts
     $exec-tool-calls
     $response
     $write-result
     $actions
     $warnings))

(= (codex:js-repl-read-stdout-emit-image-step-result-exec-contexts
      (CodexJsReplReadStdoutEmitImageStepResult
        $exec-contexts $exec-tool-calls $response $write-result
        $actions $warnings))
   $exec-contexts)

(= (codex:js-repl-read-stdout-emit-image-step-result-exec-tool-calls
      (CodexJsReplReadStdoutEmitImageStepResult
        $exec-contexts $exec-tool-calls $response $write-result
        $actions $warnings))
   $exec-tool-calls)

(= (codex:js-repl-read-stdout-emit-image-step-result-response
      (CodexJsReplReadStdoutEmitImageStepResult
        $exec-contexts $exec-tool-calls $response $write-result
        $actions $warnings))
   $response)

(= (codex:js-repl-read-stdout-emit-image-step-result-write-result
      (CodexJsReplReadStdoutEmitImageStepResult
        $exec-contexts $exec-tool-calls $response $write-result
        $actions $warnings))
   $write-result)

(= (codex:js-repl-read-stdout-emit-image-step-result-actions
      (CodexJsReplReadStdoutEmitImageStepResult
        $exec-contexts $exec-tool-calls $response $write-result
        $actions $warnings))
   $actions)

(= (codex:js-repl-read-stdout-emit-image-step-result-warnings
      (CodexJsReplReadStdoutEmitImageStepResult
        $exec-contexts $exec-tool-calls $response $write-result
        $actions $warnings))
   $warnings)

(= (codex:js-repl-read-stdout-emit-image-step
      $request
      $exec-contexts
      $exec-tool-calls
      $stdin
      $body-write-result
      $newline-write-result
      $child-inspection
      $recent-stderr)
   (case $request
     (((CodexJsReplKernelToHostEmitImage $id $exec-id $image-url $detail)
       (let $branch
         (codex:js-repl-read-stdout-emit-image-branch
           $request
           $exec-contexts
           $exec-tool-calls)
         (let $response
           (codex:js-repl-read-stdout-emit-image-branch-result-response
             $branch)
           (let $write-result
             (codex:js-repl-write-message
               $stdin
               $response
               $body-write-result
               $newline-write-result)
             (CodexJsReplReadStdoutEmitImageStepResult
               $exec-contexts
               (codex:js-repl-read-stdout-emit-image-branch-result-exec-tool-calls
                 $branch)
               $response
               $write-result
               (list:append
                 (codex:js-repl-read-stdout-emit-image-record-actions
                   (codex:js-repl-read-stdout-emit-image-branch-result-content-item
                     $branch)
                   $exec-id)
                 ((codex:js-repl-read-stdout-emit-image-action-write-message
                    $response
                    $write-result)))
               (codex:js-repl-read-stdout-emit-image-write-warnings
                 $write-result
                 $exec-id
                 $id
                 $child-inspection
                 $recent-stderr)))))))))
