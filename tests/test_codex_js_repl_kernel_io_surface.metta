!(register-module! ../codex)
!(import! &self codex:function_tool)
!(import! &self codex:js_repl)
!(import! &self codex:js_repl_kernel_io)
!(import! &self codex:js_repl_kernel_state)

(= (test:recent-stderr $lines)
   (codex:js-repl-arc-mutex
     (codex:js-repl-recent-stderr-buffer
       (codex:js-repl-stderr-tail-line-limit)
       $lines)))

(= (test:exec-message)
   (codex:js-repl-host-to-kernel-exec
     "exec-1"
     "console.log(1)"
     1500))

!(assertEqual
  (codex:js-repl-kernel-script-path "/tmp/js-repl")
  "/tmp/js-repl/js_repl_kernel.js")

!(assertEqual
  (codex:js-repl-meriyah-umd-path "/tmp/js-repl")
  "/tmp/js-repl/meriyah.umd.min.js")

!(assertEqual
  (codex:js-repl-write-kernel-script-result-path
    (codex:js-repl-write-kernel-script
      "/tmp/js-repl"
      (codex:js-repl-fs-write-ok)
      (codex:js-repl-fs-write-ok)))
  "/tmp/js-repl/js_repl_kernel.js")

!(assertEqual
  (codex:js-repl-write-kernel-script-result-writes
    (codex:js-repl-write-kernel-script
      "/tmp/js-repl"
      (codex:js-repl-fs-write-ok)
      (codex:js-repl-fs-write-ok)))
  ((CodexJsReplFsWrite
     "/tmp/js-repl/js_repl_kernel.js"
     CodexJsReplKernelSourceAsset)
   (CodexJsReplFsWrite
     "/tmp/js-repl/meriyah.umd.min.js"
     CodexJsReplMeriyahUmdAsset)))

!(assertEqual
  (codex:js-repl-write-kernel-script-result-error
    (codex:js-repl-write-kernel-script
      "/tmp/js-repl"
      (codex:js-repl-fs-write-error "disk full")
      (codex:js-repl-fs-write-ok)))
  "disk full")

!(assertEqual
  (codex:js-repl-write-kernel-script-result-writes
    (codex:js-repl-write-kernel-script
      "/tmp/js-repl"
      (codex:js-repl-fs-write-error "disk full")
      (codex:js-repl-fs-write-ok)))
  ((CodexJsReplFsWrite
     "/tmp/js-repl/js_repl_kernel.js"
     CodexJsReplKernelSourceAsset)))

!(assertEqual
  (codex:js-repl-write-kernel-script-result-error
    (codex:js-repl-write-kernel-script
      "/tmp/js-repl"
      (codex:js-repl-fs-write-ok)
      (codex:js-repl-fs-write-error "readonly")))
  "readonly")

!(assertEqual
  (codex:js-repl-host-to-kernel-json-string
    (test:exec-message))
  "{\"type\":\"exec\",\"id\":\"exec-1\",\"code\":\"console.log(1)\",\"timeout_ms\":1500}")

!(assertEqual
  (codex:js-repl-host-to-kernel-json-string
    (codex:js-repl-host-to-kernel-exec
      "exec-2"
      "await 1"
      CodexAbsent))
  "{\"type\":\"exec\",\"id\":\"exec-2\",\"code\":\"await 1\",\"timeout_ms\":null}")

!(assertEqual
  (codex:js-repl-host-to-kernel-json-string
    (codex:js-repl-host-to-kernel-run-tool-result
      (codex:js-repl-run-tool-result
        "tool-1"
        True
        (JsonObject ((JsonPair "text" (JsonString "ok"))))
        CodexAbsent)))
  "{\"type\":\"run_tool_result\",\"id\":\"tool-1\",\"ok\":true,\"response\":{\"text\":\"ok\"},\"error\":null}")

!(assertEqual
  (codex:js-repl-host-to-kernel-json-string
    (codex:js-repl-host-to-kernel-emit-image-result
      (codex:js-repl-emit-image-result
        "image-1"
        False
        "bad url")))
  "{\"type\":\"emit_image_result\",\"id\":\"image-1\",\"ok\":false,\"error\":\"bad url\"}")

!(assertEqual
  (codex:js-repl-write-message-result-writes
    (codex:js-repl-write-message
      stdin-1
      (test:exec-message)
      (codex:js-repl-stdin-write-ok)
      (codex:js-repl-stdin-write-ok)))
  ((CodexJsReplStdinWrite
     stdin-1
     "{\"type\":\"exec\",\"id\":\"exec-1\",\"code\":\"console.log(1)\",\"timeout_ms\":1500}")
   (CodexJsReplStdinWrite stdin-1 "\n")))

!(assertEqual
  (codex:function-call-error-display
    (codex:js-repl-write-message-result-error
      (codex:js-repl-write-message
        stdin-1
        (test:exec-message)
        (codex:js-repl-stdin-write-error "broken pipe")
        (codex:js-repl-stdin-write-ok))))
  "failed to write to kernel: broken pipe")

!(assertEqual
  (codex:function-call-error-display
    (codex:js-repl-write-message-result-error
      (codex:js-repl-write-message
        stdin-1
        (test:exec-message)
        (codex:js-repl-stdin-write-ok)
        (codex:js-repl-stdin-write-error "EPIPE"))))
  "failed to flush kernel message: EPIPE")

!(assertEqual
  (codex:function-call-error-display
    (codex:js-repl-write-message-result-error
      (codex:js-repl-write-message-from-serialize-result
        stdin-1
        (codex:js-repl-host-to-kernel-serialize-error "bad value")
        (codex:js-repl-stdin-write-ok)
        (codex:js-repl-stdin-write-ok))))
  "failed to serialize kernel message: bad value")

!(assertEqual
  (codex:js-repl-write-message-result-writes
    (codex:js-repl-write-message-from-serialize-result
      stdin-1
      (codex:js-repl-host-to-kernel-serialize-error "bad value")
      (codex:js-repl-stdin-write-ok)
      (codex:js-repl-stdin-write-ok)))
  ())

!(assertEqual
  (codex:js-repl-kernel-stderr-tail-snapshot
    (test:recent-stderr ("alpha" "beta")))
  "alpha | beta")

!(assertEqual
  (codex:js-repl-kernel-stderr-tail-snapshot
    (test:recent-stderr ()))
  "<empty>")

!(assertEqual
  (codex:js-repl-format-exit-status
    (codex:js-repl-exit-status-code 1))
  "code=1")

!(assertEqual
  (codex:js-repl-format-exit-status
    (codex:js-repl-exit-status-signal 9))
  "signal=9")

!(assertEqual
  (codex:js-repl-kernel-debug-snapshot-from-inspection
    (codex:js-repl-child-inspection
      123
      (codex:js-repl-child-try-wait-running))
    (test:recent-stderr ("tail")))
  (CodexJsReplKernelDebugSnapshot 123 "running" "tail"))

!(assertEqual
  (codex:js-repl-kernel-debug-snapshot-from-inspection
    (codex:js-repl-child-inspection
      123
      (codex:js-repl-child-try-wait-exited
        (codex:js-repl-exit-status-code 1)))
    (test:recent-stderr ("tail")))
  (CodexJsReplKernelDebugSnapshot 123 "exited(code=1)" "tail"))

!(assertEqual
  (codex:js-repl-kernel-debug-snapshot-from-inspection
    (codex:js-repl-child-inspection
      123
      (codex:js-repl-child-try-wait-exited
        (codex:js-repl-exit-status-signal 9)))
    (test:recent-stderr ("tail")))
  (CodexJsReplKernelDebugSnapshot 123 "exited(signal=9)" "tail"))

!(assertEqual
  (codex:js-repl-kernel-debug-snapshot-from-inspection
    (codex:js-repl-child-inspection
      CodexAbsent
      (codex:js-repl-child-try-wait-error "permission denied"))
    (test:recent-stderr ()))
  (CodexJsReplKernelDebugSnapshot
    CodexAbsent
    "unknown (permission denied)"
    "<empty>"))
