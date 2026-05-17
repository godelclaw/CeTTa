; Bridge wrappers for imported tool handlers that currently need a smaller
; CeTTa module surface to export cleanly.
;
; Rust dispatches these tools directly through the registry into their handler
; implementations. The current CeTTa evaluator still collapses some equivalent
; wrapper definitions to `Empty` when they live inside the large `codex:tools`
; module. This bridge keeps the handler logic byte-for-byte aligned with the
; existing direct tool-call surfaces and only narrows the module boundary.

!(import! &self list_dir)
!(import! &self path)
!(import! &self protocol)
!(import! &self system)
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

(= (codex:bridge-view-image-result-item
      $call-id
      (CodexViewImageHandlerResultSuccess $image-url $detail))
   (codex:tool-result-content-items
     $call-id
     ((codex:input-image $image-url $detail))))

(= (codex:bridge-view-image-result-item
      $call-id
      (CodexViewImageHandlerResultError $message))
   (codex:tool-result $call-id $message))

(= (codex:bridge-run-view-image-resolved
      $call-id
      $requested-detail
      $resolved-path)
   (case
     (codex:handle-view-image-resolved-path
       (codex:default-view-image-handler-context)
       $requested-detail
       $resolved-path)
     (($result
       (codex:bridge-view-image-result-item $call-id $result)))))

(= (codex:bridge-view-image-resolve-path $cwd $path)
   ; CeTTa evaluation accommodation: in this bridge import context,
   ; path-normalize can collapse after the list_dir call. Absolute paths are
   ; already the Rust-visible normalized form for the current bridge surface.
   (if (path-is-absolute? $path)
       $path
       (path-join $cwd $path)))

(= (codex:bridge-run-view-image-valid-detail
      $call-id
      $path
      $requested-detail)
   (case
     (codex:bridge-view-image-resolve-path
       (codex:view-image-handler-context-cwd
         (codex:default-view-image-handler-context))
       $path)
     (($resolved-path
       (codex:bridge-run-view-image-resolved
         $call-id
         $requested-detail
         $resolved-path)))))

(= (codex:bridge-run-view-image-parsed
      $call-id
      $path
      $requested-detail)
   (case $requested-detail
     ((CodexAbsent
       (codex:bridge-run-view-image-valid-detail
         $call-id
         $path
         CodexAbsent))
      ("original"
       (codex:bridge-run-view-image-valid-detail
         $call-id
         $path
         "original"))
      ($other
       (codex:tool-result
         $call-id
         (format-args
           "view_image.detail only supports `original`; omit `detail` for default resized behavior, got `{}`"
           ($other)))))))

(= (codex:bridge-run-view-image-tool-call-item $call-id $input)
   (case (codex:parse-view-image-args $input)
     (((CodexViewImageParseOk (CodexViewImageArgs $path $requested-detail))
       (codex:bridge-run-view-image-parsed
         $call-id
         $path
         $requested-detail))
      ((CodexViewImageParseError $message)
       (codex:tool-result
         $call-id
         (str-concat
           "failed to parse function arguments: "
           $message))))))
