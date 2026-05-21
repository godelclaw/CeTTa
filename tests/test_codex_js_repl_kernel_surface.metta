!(register-module! ../codex)
!(import! &self codex:js_repl)

!(assertEqual
  (codex:js-repl-stderr-tail-line-limit)
  20)

!(assertEqual
  (codex:js-repl-stderr-tail-line-max-bytes)
  512)

!(assertEqual
  (codex:js-repl-stderr-tail-max-bytes)
  4096)

!(assertEqual
  (codex:js-repl-stderr-tail-separator)
  " | ")

!(assertEqual
  (codex:js-repl-exec-id-log-limit)
  8)

!(assertEqual
  (codex:js-repl-model-diag-stderr-max-bytes)
  1024)

!(assertEqual
  (codex:js-repl-model-diag-error-max-bytes)
  256)

!(assertEqual
  (codex:js-repl-top-level-exec-state-registered-exec-id
    (codex:js-repl-top-level-exec-state-idle))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-top-level-exec-state-registered-exec-id
    (codex:js-repl-top-level-exec-state-fresh-kernel
      "turn-1"
      CodexAbsent))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-top-level-exec-state-registered-exec-id
    (codex:js-repl-top-level-exec-state-submitted
      "turn-1"
      "exec-1"))
  "exec-1")

!(assertEqual
  (codex:js-repl-top-level-exec-state-should-reset-for-interrupt
    (codex:js-repl-top-level-exec-state-fresh-kernel
      "turn-1"
      CodexAbsent)
    "turn-1")
  True)

!(assertEqual
  (codex:js-repl-top-level-exec-state-should-reset-for-interrupt
    (codex:js-repl-top-level-exec-state-reused-kernel-pending
      "turn-1"
      "exec-1")
    "turn-1")
  False)

!(assertEqual
  (codex:js-repl-register-top-level-exec-state
    (codex:js-repl-top-level-exec-state-fresh-kernel
      "turn-1"
      CodexAbsent)
    "exec-1"
    "turn-1")
  (CodexJsReplTopLevelExecStateFreshKernel "turn-1" "exec-1"))

!(assertEqual
  (codex:js-repl-register-top-level-exec-state
    (codex:js-repl-top-level-exec-state-idle)
    "exec-1"
    "turn-1")
  (CodexJsReplTopLevelExecStateReusedKernelPending "turn-1" "exec-1"))

!(assertEqual
  (codex:js-repl-mark-top-level-exec-submitted-state
    (codex:js-repl-top-level-exec-state-reused-kernel-pending
      "turn-1"
      "exec-1")
    "exec-1")
  (CodexJsReplTopLevelExecStateSubmitted "turn-1" "exec-1"))

!(assertEqual
  (codex:js-repl-clear-top-level-exec-if-matches-state
    (codex:js-repl-top-level-exec-state-submitted
      "turn-1"
      "exec-1")
    "exec-1")
  (CodexJsReplTopLevelExecStateIdle))

!(assertEqual
  (codex:js-repl-clear-top-level-exec-if-matches-any-state
    (codex:js-repl-top-level-exec-state-submitted
      "turn-1"
      "exec-2")
    ("exec-1" "exec-2"))
  (CodexJsReplTopLevelExecStateIdle))

!(assertEqual
  (codex:js-repl-kernel-stream-end-reason
    (codex:js-repl-kernel-stream-end-shutdown))
  "shutdown")

!(assertEqual
  (codex:js-repl-kernel-stream-end-reason
    (codex:js-repl-kernel-stream-end-stdout-read-error "bad read"))
  "stdout_read_error")

!(assertEqual
  (codex:js-repl-kernel-stream-end-error
    (codex:js-repl-kernel-stream-end-stdout-read-error "bad read"))
  "bad read")

!(assertEqual
  (codex:js-repl-kernel-stream-end-error
    (codex:js-repl-kernel-stream-end-stdout-eof))
  CodexAbsent)

!(assertEqual
  (codex:js-repl-truncate-utf8-prefix-by-bytes "abcdef" 3)
  "abc")

!(assertEqual
  (codex:js-repl-truncate-utf8-prefix-by-bytes "😀abc" 5)
  "😀a")

!(assertEqual
  (codex:js-repl-truncate-utf8-prefix-by-bytes "😀abc" 1)
  "")

!(assertEqual
  (codex:js-repl-format-stderr-tail ())
  "<empty>")

!(assertEqual
  (codex:js-repl-format-stderr-tail ("alpha" "beta"))
  "alpha | beta")

!(assertEqual
  (codex:js-repl-stderr-tail-formatted-bytes ("aa" "bbb"))
  8)

!(assertEqual
  (codex:js-repl-stderr-tail-bytes-with-candidate ("aa" "bbb") "c")
  12)

!(assertEqual
  (codex:js-repl-push-stderr-tail-line
    ("0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
     "10" "11" "12" "13" "14" "15" "16" "17" "18" "19")
    "20")
  (CodexJsReplStderrTailPushResult
    ("1" "2" "3" "4" "5" "6" "7" "8" "9"
     "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20")
    "20"))

!(assertEqual
  (codex:js-repl-is-kernel-status-exited "exited(code=1)")
  True)

!(assertEqual
  (codex:js-repl-is-kernel-status-exited "running")
  False)

!(assertEqual
  (codex:js-repl-should-include-model-diagnostics-for-write-error
    "Broken pipe"
    (codex:js-repl-kernel-debug-snapshot CodexAbsent "running" "<empty>"))
  True)

!(assertEqual
  (codex:js-repl-should-include-model-diagnostics-for-write-error
    "write failed"
    (codex:js-repl-kernel-debug-snapshot 123 "exited(code=1)" "tail"))
  True)

!(assertEqual
  (codex:js-repl-should-include-model-diagnostics-for-write-error
    "permission denied"
    (codex:js-repl-kernel-debug-snapshot CodexAbsent "running" "tail"))
  False)

!(assertEqual
  (codex:js-repl-format-model-kernel-failure-details
    "write_failed"
    CodexAbsent
    (codex:js-repl-kernel-debug-snapshot CodexAbsent "running" "tail"))
  "js_repl diagnostics: {\"reason\":\"write_failed\",\"stream_error\":null,\"kernel_pid\":null,\"kernel_status\":\"running\",\"kernel_stderr_tail\":\"tail\"}")

!(assertEqual
  (codex:js-repl-with-model-kernel-failure-message
    "failed to write to kernel"
    "write_failed"
    "Broken pipe"
    (codex:js-repl-kernel-debug-snapshot 123 "exited(code=1)" "stderr"))
  "failed to write to kernel\n\njs_repl diagnostics: {\"reason\":\"write_failed\",\"stream_error\":\"Broken pipe\",\"kernel_pid\":123,\"kernel_status\":\"exited(code=1)\",\"kernel_stderr_tail\":\"stderr\"}")

!(assertEqual
  (codex:js-repl-validate-emitted-image-url
    "DATA:IMAGE/PNG;base64,AAA")
  (CodexJsReplValidationOk))

!(assertEqual
  (codex:js-repl-validation-error-message
    (codex:js-repl-validate-emitted-image-url
      "http://example.invalid/image.png"))
  "codex.emitImage only accepts data URLs")

!(assertEqual
  (codex:js-repl-validation-error-message
    (codex:js-repl-validate-emitted-image-url "data:,AAA"))
  "codex.emitImage expected a valid image data URL")

!(assertEqual
  (codex:js-repl-validation-error-message
    (codex:js-repl-validate-emitted-image-url
      "data:image/svg+xml;base64,AAA"))
  "codex.emitImage only supports image/png, image/jpeg, image/webp, or image/gif")

!(assertEqual
  (codex:js-repl-build-exec-result-content-items
    "stdout"
    ((CodexInputImage "data:image/png;base64,AAA" "high")))
  ((CodexInputText "stdout")
   (CodexInputImage "data:image/png;base64,AAA" "high")))

!(assertEqual
  (codex:js-repl-split-exec-result-content-items
    ((CodexInputText "stdout")
     (CodexInputImage "data:image/png;base64,AAA" "high")))
  (CodexJsReplExecResultContentSplit
    "stdout"
    ((CodexInputImage "data:image/png;base64,AAA" "high"))))

!(assertEqual
  (codex:js-repl-split-exec-result-content-items
    ((CodexInputImage "data:image/png;base64,AAA" "high")))
  (CodexJsReplExecResultContentSplit
    ""
    ((CodexInputImage "data:image/png;base64,AAA" "high"))))

!(assertEqual
  (codex:js-repl-split-exec-result-content-items ())
  (CodexJsReplExecResultContentSplit "" ()))

!(assertEqual
  (codex:is-js-repl-internal-tool "js_repl")
  True)

!(assertEqual
  (codex:is-js-repl-internal-tool "js_repl_reset")
  True)

!(assertEqual
  (codex:is-js-repl-internal-tool "python")
  False)

!(assertEqual
  (codex:js-repl-node-version-parse " v20.11.1\n")
  (CodexJsReplNodeVersionParseOk
    (CodexJsReplNodeVersion 20 11 1)))

!(assertEqual
  (codex:js-repl-node-version-parse "vv22.3.4-nightly+meta")
  (CodexJsReplNodeVersionParseOk
    (CodexJsReplNodeVersion 22 3 4)))

!(assertEqual
  (codex:js-repl-node-version-parse-result-error
    (codex:js-repl-node-version-parse "20"))
  "missing minor version")

!(assertEqual
  (codex:js-repl-node-version-parse-result-error
    (codex:js-repl-node-version-parse "20.1"))
  "missing patch version")

!(assertEqual
  (codex:js-repl-node-version-parse-result-error
    (codex:js-repl-node-version-parse "node.1.0"))
  "invalid major version: invalid digit found in string")

!(assertEqual
  (codex:js-repl-node-version-parse-result-error
    (codex:js-repl-node-version-parse "v"))
  "invalid major version: cannot parse integer from empty string")

!(assertEqual
  (codex:js-repl-node-version-display
    (CodexJsReplNodeVersion 20 11 1))
  "20.11.1")

!(assertEqual
  (codex:js-repl-node-version-less-than
    (CodexJsReplNodeVersion 20 11 0)
    (CodexJsReplNodeVersion 20 11 1))
  True)

!(assertEqual
  (codex:js-repl-node-version-at-least
    (CodexJsReplNodeVersion 21 0 0)
    (CodexJsReplNodeVersion 20 11 1))
  True)

!(assertEqual
  (codex:js-repl-required-node-version)
  (CodexJsReplNodeVersionParseOk
    (CodexJsReplNodeVersion 22 22 0)))

!(assertEqual
  (codex:js-repl-read-node-version-execute-error-message
    "No such file or directory")
  "failed to execute Node: No such file or directory")

!(assertEqual
  (codex:js-repl-read-node-version-status-error-message
    "exit status: 1"
    ""
    "")
  "failed to read Node version (status exit status: 1)")

!(assertEqual
  (codex:js-repl-read-node-version-status-error-message
    "exit status: 1"
    " v18.19.0\n"
    " bad\n")
  "failed to read Node version (status exit status: 1) ( stdout: v18.19.0 stderr: bad)")

!(assertEqual
  (codex:js-repl-read-node-version-parse-output " v22.22.0\n")
  (CodexJsReplNodeVersionParseOk
    (CodexJsReplNodeVersion 22 22 0)))

!(assertEqual
  (codex:js-repl-node-version-parse-result-error
    (codex:js-repl-read-node-version-parse-output "bogus"))
  "failed to parse Node version output `bogus`: invalid major version: invalid digit found in string")

!(assertEqual
  (codex:js-repl-node-version-too-old-message
    "/usr/bin/node"
    (CodexJsReplNodeVersion 18 19 0)
    (CodexJsReplNodeVersion 20 11 1))
  "Node runtime too old for js_repl (resolved /usr/bin/node): found v18.19.0, requires >= v20.11.1. Install/update Node or set js_repl_node_path to a newer runtime.")

!(assertEqual
  (codex:js-repl-node-version-check-error-message
    (codex:js-repl-ensure-node-version
      "/usr/bin/node"
      (CodexJsReplNodeVersion 18 19 0)
      (CodexJsReplNodeVersion 20 11 1)))
  "Node runtime too old for js_repl (resolved /usr/bin/node): found v18.19.0, requires >= v20.11.1. Install/update Node or set js_repl_node_path to a newer runtime.")

!(assertEqual
  (codex:js-repl-ensure-node-version
    "/usr/bin/node"
    (CodexJsReplNodeVersion 22 22 0)
    (CodexJsReplNodeVersion 22 22 0))
  (CodexJsReplNodeVersionCheckOk))

!(assertEqual
  (codex:js-repl-resolve-node
    "/env/node"
    True
    "/config/node"
    True
    "/usr/bin/node")
  "/env/node")

!(assertEqual
  (codex:js-repl-resolve-node
    "/env/node"
    False
    "/config/node"
    True
    "/usr/bin/node")
  "/config/node")

!(assertEqual
  (codex:js-repl-resolve-node
    CodexAbsent
    False
    "/config/node"
    False
    "/usr/bin/node")
  "/usr/bin/node")

!(assertEqual
  (codex:js-repl-resolve-node
    CodexAbsent
    False
    CodexAbsent
    False
    CodexAbsent)
  CodexAbsent)

!(assertEqual
  (codex:js-repl-resolve-compatible-node
    "/usr/bin/node"
    (CodexJsReplNodeVersionCheckOk))
  (CodexJsReplResolveCompatibleNodeOk "/usr/bin/node"))

!(assertEqual
  (codex:js-repl-resolve-compatible-node-error-message
    (codex:js-repl-resolve-compatible-node
      CodexAbsent
      (CodexJsReplNodeVersionCheckOk)))
  "Node runtime not found; install Node or set CODEX_JS_REPL_NODE_PATH")

!(assertEqual
  (codex:js-repl-resolve-compatible-node-error-message
    (codex:js-repl-resolve-compatible-node
      "/usr/bin/node"
      (CodexJsReplNodeVersionCheckError "too old")))
  "too old")
