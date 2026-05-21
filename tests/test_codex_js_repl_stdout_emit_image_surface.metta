!(register-module! ../codex)
!(import! &self codex:js_repl_stdout_emit_image)

(= (test:supported-model)
   (CodexToolConfigModelInfo shell CodexAbsent () True))

(= (test:unsupported-model)
   (CodexToolConfigModelInfo shell CodexAbsent () False))

(= (test:contexts-supported)
   (codex:js-repl-emit-image-exec-contexts
     ((codex:js-repl-emit-image-exec-context-entry
        "exec-1"
        (codex:js-repl-emit-image-exec-context
          (test:supported-model))))))

(= (test:contexts-unsupported)
   (codex:js-repl-emit-image-exec-contexts
     ((codex:js-repl-emit-image-exec-context-entry
        "exec-1"
        (codex:js-repl-emit-image-exec-context
          (test:unsupported-model))))))

(= (test:tool-calls)
   (codex:js-repl-register-exec-tool-calls-map
     (codex:js-repl-exec-tool-calls-map-empty)
     "exec-1"
     notify-1
     cancel-1))

(= (test:recent-stderr)
   (codex:js-repl-arc-mutex
     (codex:js-repl-recent-stderr-buffer
       (codex:js-repl-stderr-tail-line-limit)
       ("stderr tail"))))

(= (test:emit-original-request)
   (codex:js-repl-kernel-to-host-emit-image
     "emit-1"
     "exec-1"
     "data:image/png;base64,AAA"
     "original"))

(= (test:emit-original-supported-result)
   (codex:js-repl-read-stdout-emit-image-step
     (test:emit-original-request)
     (test:contexts-supported)
     (test:tool-calls)
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-child-inspection
       42
       (codex:js-repl-child-try-wait-running))
     (test:recent-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-emit-image-step-result-response
    (test:emit-original-supported-result))
  (CodexJsReplHostToKernelEmitImageResult
    (CodexJsReplEmitImageResult "emit-1" True CodexAbsent)))

!(assertEqual
  (codex:js-repl-exec-tool-calls-state-content-items
    (codex:js-repl-exec-tool-calls-map-find-state
      (codex:js-repl-read-stdout-emit-image-step-result-exec-tool-calls
        (test:emit-original-supported-result))
      "exec-1"))
  ((CodexInputImage "data:image/png;base64,AAA" "original")))

!(assertEqual
  (codex:js-repl-read-stdout-emit-image-step-result-actions
    (test:emit-original-supported-result))
  ((CodexJsReplReadStdoutEmitImageActionRecordContentItem
     "exec-1"
     (CodexInputImage "data:image/png;base64,AAA" "original"))
   (CodexJsReplReadStdoutEmitImageActionWriteMessage
     (CodexJsReplHostToKernelEmitImageResult
       (CodexJsReplEmitImageResult "emit-1" True CodexAbsent))
     (CodexJsReplWriteMessageOk
       ((CodexJsReplStdinWrite
          stdin-1
          "{\"type\":\"emit_image_result\",\"id\":\"emit-1\",\"ok\":true,\"error\":null}")
        (CodexJsReplStdinWrite stdin-1 "\n"))))))

!(assertEqual
  (codex:js-repl-read-stdout-emit-image-step-result-warnings
    (test:emit-original-supported-result))
  ())

(= (test:emit-original-unsupported-result)
   (codex:js-repl-read-stdout-emit-image-step
     (test:emit-original-request)
     (test:contexts-unsupported)
     (test:tool-calls)
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-child-inspection
       42
       (codex:js-repl-child-try-wait-running))
     (test:recent-stderr)))

!(assertEqual
  (codex:js-repl-exec-tool-calls-state-content-items
    (codex:js-repl-exec-tool-calls-map-find-state
      (codex:js-repl-read-stdout-emit-image-step-result-exec-tool-calls
        (test:emit-original-unsupported-result))
      "exec-1"))
  ((CodexInputImage "data:image/png;base64,AAA" "high")))

(= (test:invalid-url-result)
   (codex:js-repl-read-stdout-emit-image-step
     (codex:js-repl-kernel-to-host-emit-image
       "emit-2"
       "exec-1"
       "https://example.invalid/image.png"
       CodexAbsent)
     (test:contexts-supported)
     (test:tool-calls)
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-child-inspection
       42
       (codex:js-repl-child-try-wait-running))
     (test:recent-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-emit-image-step-result-response
    (test:invalid-url-result))
  (CodexJsReplHostToKernelEmitImageResult
    (CodexJsReplEmitImageResult
      "emit-2"
      False
      "codex.emitImage only accepts data URLs")))

!(assertEqual
  (codex:js-repl-exec-tool-calls-state-content-items
    (codex:js-repl-exec-tool-calls-map-find-state
      (codex:js-repl-read-stdout-emit-image-step-result-exec-tool-calls
        (test:invalid-url-result))
      "exec-1"))
  ())

!(assertEqual
  (codex:js-repl-read-stdout-emit-image-step-result-actions
    (test:invalid-url-result))
  ((CodexJsReplReadStdoutEmitImageActionWriteMessage
     (CodexJsReplHostToKernelEmitImageResult
       (CodexJsReplEmitImageResult
         "emit-2"
         False
         "codex.emitImage only accepts data URLs"))
     (CodexJsReplWriteMessageOk
       ((CodexJsReplStdinWrite
          stdin-1
          "{\"type\":\"emit_image_result\",\"id\":\"emit-2\",\"ok\":false,\"error\":\"codex.emitImage only accepts data URLs\"}")
        (CodexJsReplStdinWrite stdin-1 "\n"))))))

(= (test:missing-context-result)
   (codex:js-repl-read-stdout-emit-image-step
     (codex:js-repl-kernel-to-host-emit-image
       "emit-3"
       "missing-exec"
       "data:image/png;base64,AAA"
       CodexAbsent)
     (test:contexts-supported)
     (test:tool-calls)
     stdin-1
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-child-inspection
       42
       (codex:js-repl-child-try-wait-running))
     (test:recent-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-emit-image-step-result-response
    (test:missing-context-result))
  (CodexJsReplHostToKernelEmitImageResult
    (CodexJsReplEmitImageResult
      "emit-3"
      False
      "js_repl exec context not found")))

(= (test:write-error-result)
   (codex:js-repl-read-stdout-emit-image-step
     (test:emit-original-request)
     (test:contexts-supported)
     (test:tool-calls)
     stdin-1
     (codex:js-repl-stdin-write-error "broken pipe")
     (codex:js-repl-stdin-write-ok)
     (codex:js-repl-child-inspection
       42
       (codex:js-repl-child-try-wait-exited
         (codex:js-repl-exit-status-code 1)))
     (test:recent-stderr)))

!(assertEqual
  (codex:js-repl-read-stdout-emit-image-step-result-warnings
    (test:write-error-result))
  ((CodexJsReplReadStdoutEmitImageWarningWriteFailed
     "failed to reply to kernel emit_image request"
     "exec-1"
     "emit-1"
     "failed to write to kernel: broken pipe"
     (CodexJsReplKernelDebugSnapshot
       42
       "exited(code=1)"
       "stderr tail"))))
