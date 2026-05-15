; Narrow Rust-faithful view_image slice for the restarted Codex port.
;
; This ports the direct runnable surface from:
; - openai-codex/codex-rs/tools/src/view_image.rs
; - openai-codex/codex-rs/core/src/tools/handlers/view_image.rs
;
; Covered in this increment:
; - Rust-shaped tool name/description and JSON argument decoding
; - image-input support / session-availability / detail validation
; - cwd-relative path resolution, file checks, and direct runnable tool calls
; - custom_tool_call_output lowering with input_image payloads
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust routes image bytes through `load_for_prompt_bytes`, which may resize
;   non-original requests before generating the final data URL. The restarted
;   CeTTa runtime currently returns the original image bytes for both paths and
;   preserves the visible detail hint only.
; - Rust uses its image stack to infer and normalize a wider range of formats.
;   The current CeTTa runtime recognizes common raster formats from magic bytes
;   plus a small extension fallback set; unsupported inputs fail early.
; - Rust executes this tool through the general handler registry. The current
;   CeTTa evaluator does not yet reliably reduce the same logic when split
;   across additional helper layers over parsed structured values, so the
;   direct runnable helper inlines parse->handle lowering in one definition
;   while preserving the same visible behavior.

!(import! &self fs)
!(import! &self json)
!(import! &self path)
!(import! &self protocol)
!(import! &self system)

(= (codex:view-image-tool-name)
   "view_image")

(= (codex:view-image-tool-description)
   "View a local image from the filesystem (only use if given a full filepath by the user, and the image isn't already attached to the thread context within <image ...> tags).")

(= (codex:view-image-unsupported-message)
   "view_image is not allowed because you do not support image inputs")

(= (codex:view-image-default-detail)
   "high")

(= (codex:view-image-args $path $detail)
   (CodexViewImageArgs $path $detail))

(= (codex:view-image-args-path (CodexViewImageArgs $path $detail))
   $path)

(= (codex:view-image-args-detail (CodexViewImageArgs $path $detail))
   $detail)

(= (codex:view-image-handler-context
      $image-input-supported
      $environment-available
      $can-request-original-image-detail
      $cwd)
   (CodexViewImageHandlerContext
     $image-input-supported
     $environment-available
     $can-request-original-image-detail
     $cwd))

(= (codex:default-view-image-handler-context)
   (codex:view-image-handler-context
     True
     True
     False
     (system-cwd)))

(= (codex:view-image-handler-context-image-input-supported
      (CodexViewImageHandlerContext
        $image-input-supported
        $environment-available
        $can-request-original-image-detail
        $cwd))
   $image-input-supported)

(= (codex:view-image-handler-context-environment-available
      (CodexViewImageHandlerContext
        $image-input-supported
        $environment-available
        $can-request-original-image-detail
        $cwd))
   $environment-available)

(= (codex:view-image-handler-context-can-request-original-image-detail
      (CodexViewImageHandlerContext
        $image-input-supported
        $environment-available
        $can-request-original-image-detail
        $cwd))
   $can-request-original-image-detail)

(= (codex:view-image-handler-context-cwd
      (CodexViewImageHandlerContext
        $image-input-supported
        $environment-available
        $can-request-original-image-detail
        $cwd))
   $cwd)

(= (codex:view-image-parse-ok $value)
   (CodexViewImageParseOk $value))

(= (codex:view-image-parse-error $message)
   (CodexViewImageParseError $message))

(= (codex:view-image-handler-result-success $image-url $detail)
   (CodexViewImageHandlerResultSuccess $image-url $detail))

(= (codex:view-image-handler-result-error $message)
   (CodexViewImageHandlerResultError $message))

(= (codex:view-image-json-object-required-string-result $object $key)
   (case (json-object-get $object $key)
     ((Empty
       (codex:view-image-parse-error
         (format-args "missing field `{}`" ($key))))
      (JsonNull
       (codex:view-image-parse-error
         (format-args "missing field `{}`" ($key))))
      ((JsonString $text) (codex:view-image-parse-ok $text))
      ($other
       (codex:view-image-parse-error
         (format-args "invalid type for `{}`; expected string" ($key)))))))

(= (codex:view-image-json-object-optional-string-result $object $key)
   (case (json-object-get $object $key)
     ((Empty (codex:view-image-parse-ok CodexAbsent))
      (JsonNull (codex:view-image-parse-ok CodexAbsent))
      ((JsonString $text) (codex:view-image-parse-ok $text))
      ($other
       (codex:view-image-parse-error
         (format-args "invalid type for `{}`; expected string" ($key)))))))

(= (codex:parse-view-image-args-object $object)
   (case (codex:view-image-json-object-required-string-result $object "path")
     (((CodexViewImageParseOk $path)
       (case (codex:view-image-json-object-optional-string-result $object "detail")
         (((CodexViewImageParseOk $detail)
           (codex:view-image-parse-ok
             (codex:view-image-args $path $detail)))
          ((CodexViewImageParseError $message)
           (codex:view-image-parse-error $message)))))
      ((CodexViewImageParseError $message)
       (codex:view-image-parse-error $message)))))

(= (codex:parse-view-image-args $input)
   (case (json-parse $input)
     (((JsonObject $pairs)
       (codex:parse-view-image-args-object (JsonObject $pairs)))
      ($other
       (codex:view-image-parse-error "invalid type: expected object")))))

(= (codex:view-image-resolve-path $cwd $path)
   (if (path-is-absolute? $path)
       (path-normalize $path)
       (path-join $cwd $path)))

(= (codex:view-image-output-detail $context $requested-detail)
   (if (and
         (codex:view-image-handler-context-can-request-original-image-detail $context)
         (== $requested-detail "original"))
       "original"
       (codex:view-image-default-detail)))

(= (codex:handle-view-image-image-data-url
      $context
      $requested-detail
      $resolved-path)
   ; CeTTa currently needs the fs-read-image-data-url call to stay directly in
   ; this case scrutinee. Threading the result through an extra helper argument
   ; can leave Error values unreduced, while the visible Rust behavior is the
   ; same either way.
   (case (fs-read-image-data-url $resolved-path)
     (((Error $source ("read" $message))
       (codex:view-image-handler-result-error
         (format-args
           "unable to read image at `{}`: {}"
           ($resolved-path $message))))
      ((Error $source ("process" $message))
       (codex:view-image-handler-result-error
         (format-args
           "unable to process image at `{}`: {}"
           ($resolved-path $message))))
      ($image-url
       (codex:view-image-handler-result-success
         $image-url
         (codex:view-image-output-detail
           $context
           $requested-detail))))))

(= (codex:handle-view-image-resolved-path
      $context
      $requested-detail
      $resolved-path)
   (case (fs-path-kind $resolved-path)
     (((Error $source ("stat" $message))
       (codex:view-image-handler-result-error
         (format-args
           "unable to locate image at `{}`: {}"
           ($resolved-path $message))))
      ("file"
       (codex:handle-view-image-image-data-url
         $context
         $requested-detail
         $resolved-path))
      ($kind
       (codex:view-image-handler-result-error
         (format-args
           "image path `{}` is not a file"
           ($resolved-path)))))))

(= (codex:handle-view-image-args $context $args)
   (if (not (codex:view-image-handler-context-image-input-supported $context))
       (codex:view-image-handler-result-error
         (codex:view-image-unsupported-message))
       (let $requested-detail (codex:view-image-args-detail $args)
         (if (and
               (not (== $requested-detail CodexAbsent))
               (not (== $requested-detail "original")))
             (codex:view-image-handler-result-error
               (format-args
                 "view_image.detail only supports `original`; omit `detail` for default resized behavior, got `{}`"
                 ($requested-detail)))
             (if (not (codex:view-image-handler-context-environment-available $context))
                 (codex:view-image-handler-result-error
                   "view_image is unavailable in this session")
                 (let $resolved-path
                   (codex:view-image-resolve-path
                     (codex:view-image-handler-context-cwd $context)
                     (codex:view-image-args-path $args))
                   (codex:handle-view-image-resolved-path
                     $context
                     $requested-detail
                     $resolved-path)))))))

(= (codex:run-view-image-tool-call-with-context $context $call-id $input)
   (case (codex:parse-view-image-args $input)
     (((CodexViewImageParseOk $args)
       (case (codex:handle-view-image-args $context $args)
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

(= (codex:run-view-image-tool-call $call-id $input)
   (codex:run-view-image-tool-call-with-context
     (codex:default-view-image-handler-context)
     $call-id
     $input))
