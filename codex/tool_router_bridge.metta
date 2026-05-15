; Bridge wrappers for imported tool handlers that currently need a smaller
; CeTTa module surface to export cleanly.
;
; Rust dispatches these tools directly through the registry into their handler
; implementations. The current CeTTa evaluator still collapses some equivalent
; wrapper definitions to `Empty` when they live inside the large `codex:tools`
; module. This bridge keeps the handler logic byte-for-byte aligned with the
; existing direct tool-call surfaces and only narrows the module boundary.

!(import! &self list_dir)
!(import! &self protocol)
!(import! &self view_image)

(= (codex:bridge-run-list-dir-tool-call-item $call-id $input)
   (case
     (codex:handle-list-dir-payload
       (codex:default-list-dir-handler-context)
       $call-id
       (codex:list-dir-function-payload $input))
     (((CodexListDirHandlerResultSuccess $output-text)
       (codex:tool-result $call-id $output-text))
      ((CodexListDirHandlerResultError $message)
       (codex:tool-result $call-id $message)))))

(= (codex:bridge-run-view-image-tool-call-item $call-id $input)
   (case (codex:parse-view-image-args $input)
     (((CodexViewImageParseOk $args)
       (case
         (codex:handle-view-image-args
           (codex:default-view-image-handler-context)
           $args)
         (((CodexViewImageHandlerResultSuccess $image-url $detail)
           (codex:tool-result-content-items
             $call-id
             ((codex:input-image $image-url $detail))))
          ((CodexViewImageHandlerResultError $message)
           (codex:tool-result $call-id $message)))))
      ((CodexViewImageParseError $message)
       (codex:tool-result
         $call-id
         (str-concat
           "failed to parse function arguments: "
           $message))))))
