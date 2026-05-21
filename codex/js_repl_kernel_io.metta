; Rust-faithful js_repl kernel I/O helper slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/js_repl/mod.rs
;   - `write_kernel_script`
;   - `write_message`
;   - `kernel_stderr_tail_snapshot`
;   - `kernel_debug_snapshot`
;   - `format_exit_status`
;   - the `HostToKernel`, `RunToolResult`, and `EmitImageResult` JSON shapes.
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust embeds `kernel.js` and `meriyah.umd.min.js` with `include_str!` and
;   writes their concrete bytes with Tokio fs. This pure slice carries symbolic
;   source asset tags at the async filesystem boundary while preserving paths,
;   write order, first-error short-circuiting, and returned kernel path.
; - Rust serializes with serde_json and writes bytes to `ChildStdin`. This pure
;   slice exposes the exact JSON text and modeled stdin write attempts; callers
;   supply observed write outcomes where Rust would await `write_all`.
; - Rust inspects `tokio::process::Child` through `id()` and `try_wait()`.
;   This slice receives that observed child inspection value and preserves the
;   same status string formatting.

!(import! &self function_tool)
!(import! &self js_repl)
!(import! &self js_repl_kernel_state)
!(import! &self json)
!(import! &self num_format)
!(import! &self str)

(= (codex:js-repl-kernel-script-file-name)
   "js_repl_kernel.js")

(= (codex:js-repl-meriyah-umd-file-name)
   "meriyah.umd.min.js")

(= (codex:js-repl-kernel-source-asset)
   CodexJsReplKernelSourceAsset)

(= (codex:js-repl-meriyah-umd-asset)
   CodexJsReplMeriyahUmdAsset)

(= (codex:js-repl-kernel-join-path $tmp-dir $file-name)
   (if (str-ends-with? $tmp-dir "/")
       (str-concat $tmp-dir $file-name)
       (str-concat $tmp-dir (str-concat "/" $file-name))))

(= (codex:js-repl-kernel-script-path $tmp-dir)
   (codex:js-repl-kernel-join-path
     $tmp-dir
     (codex:js-repl-kernel-script-file-name)))

(= (codex:js-repl-meriyah-umd-path $tmp-dir)
   (codex:js-repl-kernel-join-path
     $tmp-dir
     (codex:js-repl-meriyah-umd-file-name)))

(= (codex:js-repl-fs-write $path $content)
   (CodexJsReplFsWrite $path $content))

(= (codex:js-repl-fs-write-path
      (CodexJsReplFsWrite $path $content))
   $path)

(= (codex:js-repl-fs-write-content
      (CodexJsReplFsWrite $path $content))
   $content)

(= (codex:js-repl-fs-write-ok)
   CodexJsReplFsWriteOk)

(= (codex:js-repl-fs-write-error $message)
   (CodexJsReplFsWriteError $message))

(= (codex:js-repl-write-kernel-script-ok $kernel-path $writes)
   (CodexJsReplWriteKernelScriptOk $kernel-path $writes))

(= (codex:js-repl-write-kernel-script-error $message $writes)
   (CodexJsReplWriteKernelScriptError $message $writes))

(= (codex:js-repl-write-kernel-script-result-path
      (CodexJsReplWriteKernelScriptOk $kernel-path $writes))
   $kernel-path)

(= (codex:js-repl-write-kernel-script-result-error
      (CodexJsReplWriteKernelScriptError $message $writes))
   $message)

(= (codex:js-repl-write-kernel-script-result-writes
      (CodexJsReplWriteKernelScriptOk $kernel-path $writes))
   $writes)

(= (codex:js-repl-write-kernel-script-result-writes
      (CodexJsReplWriteKernelScriptError $message $writes))
   $writes)

(= (codex:js-repl-write-kernel-script
      $tmp-dir
      (CodexJsReplFsWriteError $message)
      $meriyah-write-result)
   (let $kernel-path (codex:js-repl-kernel-script-path $tmp-dir)
     (codex:js-repl-write-kernel-script-error
       $message
       ((codex:js-repl-fs-write
          $kernel-path
          (codex:js-repl-kernel-source-asset))))))

(= (codex:js-repl-write-kernel-script
      $tmp-dir
      CodexJsReplFsWriteOk
      (CodexJsReplFsWriteError $message))
   (let $kernel-path (codex:js-repl-kernel-script-path $tmp-dir)
     (let $meriyah-path (codex:js-repl-meriyah-umd-path $tmp-dir)
       (codex:js-repl-write-kernel-script-error
         $message
         ((codex:js-repl-fs-write
            $kernel-path
            (codex:js-repl-kernel-source-asset))
          (codex:js-repl-fs-write
            $meriyah-path
            (codex:js-repl-meriyah-umd-asset)))))))

(= (codex:js-repl-write-kernel-script
      $tmp-dir
      CodexJsReplFsWriteOk
      CodexJsReplFsWriteOk)
   (let $kernel-path (codex:js-repl-kernel-script-path $tmp-dir)
     (let $meriyah-path (codex:js-repl-meriyah-umd-path $tmp-dir)
       (codex:js-repl-write-kernel-script-ok
         $kernel-path
         ((codex:js-repl-fs-write
            $kernel-path
            (codex:js-repl-kernel-source-asset))
          (codex:js-repl-fs-write
            $meriyah-path
            (codex:js-repl-meriyah-umd-asset)))))))

(= (codex:js-repl-host-to-kernel-exec $id $code $timeout-ms)
   (CodexJsReplHostToKernelExec $id $code $timeout-ms))

(= (codex:js-repl-run-tool-result $id $ok $response $error)
   (CodexJsReplRunToolResult $id $ok $response $error))

(= (codex:js-repl-host-to-kernel-run-tool-result $result)
   (CodexJsReplHostToKernelRunToolResult $result))

(= (codex:js-repl-emit-image-result $id $ok $error)
   (CodexJsReplEmitImageResult $id $ok $error))

(= (codex:js-repl-host-to-kernel-emit-image-result $result)
   (CodexJsReplHostToKernelEmitImageResult $result))

(= (codex:js-repl-optional-json-value $value)
   (if (== $value CodexAbsent)
       JsonNull
       $value))

(= (codex:js-repl-host-to-kernel-json
      (CodexJsReplHostToKernelExec $id $code $timeout-ms))
   (JsonObject
     ((JsonPair "type" (JsonString "exec"))
      (JsonPair "id" (JsonString $id))
      (JsonPair "code" (JsonString $code))
      (JsonPair "timeout_ms"
        (codex:js-repl-optional-json-number $timeout-ms)))))

(= (codex:js-repl-host-to-kernel-json
      (CodexJsReplHostToKernelRunToolResult
        (CodexJsReplRunToolResult $id $ok $response $error)))
   (JsonObject
     ((JsonPair "type" (JsonString "run_tool_result"))
      (JsonPair "id" (JsonString $id))
      (JsonPair "ok" (JsonBool $ok))
      (JsonPair "response" (codex:js-repl-optional-json-value $response))
      (JsonPair "error" (codex:js-repl-optional-json-string $error)))))

(= (codex:js-repl-host-to-kernel-json
      (CodexJsReplHostToKernelEmitImageResult
        (CodexJsReplEmitImageResult $id $ok $error)))
   (JsonObject
     ((JsonPair "type" (JsonString "emit_image_result"))
      (JsonPair "id" (JsonString $id))
      (JsonPair "ok" (JsonBool $ok))
      (JsonPair "error" (codex:js-repl-optional-json-string $error)))))

(= (codex:js-repl-host-to-kernel-json-string $message)
   (json-stringify (codex:js-repl-host-to-kernel-json $message)))

(= (codex:js-repl-host-to-kernel-serialize-ok $encoded)
   (CodexJsReplHostToKernelSerializeOk $encoded))

(= (codex:js-repl-host-to-kernel-serialize-error $message)
   (CodexJsReplHostToKernelSerializeError $message))

(= (codex:js-repl-host-to-kernel-serialize-result $message)
   (codex:js-repl-host-to-kernel-serialize-ok
     (codex:js-repl-host-to-kernel-json-string $message)))

(= (codex:js-repl-stdin-write $stdin $bytes)
   (CodexJsReplStdinWrite $stdin $bytes))

(= (codex:js-repl-stdin-write-stdin
      (CodexJsReplStdinWrite $stdin $bytes))
   $stdin)

(= (codex:js-repl-stdin-write-bytes
      (CodexJsReplStdinWrite $stdin $bytes))
   $bytes)

(= (codex:js-repl-stdin-write-ok)
   CodexJsReplStdinWriteOk)

(= (codex:js-repl-stdin-write-error $message)
   (CodexJsReplStdinWriteError $message))

(= (codex:js-repl-write-message-ok $writes)
   (CodexJsReplWriteMessageOk $writes))

(= (codex:js-repl-write-message-error $error $writes)
   (CodexJsReplWriteMessageError $error $writes))

(= (codex:js-repl-write-message-result-writes
      (CodexJsReplWriteMessageOk $writes))
   $writes)

(= (codex:js-repl-write-message-result-writes
      (CodexJsReplWriteMessageError $error $writes))
   $writes)

(= (codex:js-repl-write-message-result-error
      (CodexJsReplWriteMessageError $error $writes))
   $error)

(= (codex:js-repl-write-message-serialize-error-message $message)
   (str-concat "failed to serialize kernel message: " $message))

(= (codex:js-repl-write-message-body-error-message $message)
   (str-concat "failed to write to kernel: " $message))

(= (codex:js-repl-write-message-newline-error-message $message)
   (str-concat "failed to flush kernel message: " $message))

(= (codex:js-repl-write-message-from-serialize-result
      $stdin
      (CodexJsReplHostToKernelSerializeError $message)
      $body-write-result
      $newline-write-result)
   (codex:js-repl-write-message-error
     (codex:function-call-error-respond-to-model
       (codex:js-repl-write-message-serialize-error-message $message))
     ()))

(= (codex:js-repl-write-message-from-serialize-result
      $stdin
      (CodexJsReplHostToKernelSerializeOk $encoded)
      (CodexJsReplStdinWriteError $message)
      $newline-write-result)
   (codex:js-repl-write-message-error
     (codex:function-call-error-respond-to-model
       (codex:js-repl-write-message-body-error-message $message))
     ((codex:js-repl-stdin-write $stdin $encoded))))

(= (codex:js-repl-write-message-from-serialize-result
      $stdin
      (CodexJsReplHostToKernelSerializeOk $encoded)
      CodexJsReplStdinWriteOk
      (CodexJsReplStdinWriteError $message))
   (codex:js-repl-write-message-error
     (codex:function-call-error-respond-to-model
       (codex:js-repl-write-message-newline-error-message $message))
     ((codex:js-repl-stdin-write $stdin $encoded)
      (codex:js-repl-stdin-write $stdin "\n"))))

(= (codex:js-repl-write-message-from-serialize-result
      $stdin
      (CodexJsReplHostToKernelSerializeOk $encoded)
      CodexJsReplStdinWriteOk
      CodexJsReplStdinWriteOk)
   (codex:js-repl-write-message-ok
     ((codex:js-repl-stdin-write $stdin $encoded)
      (codex:js-repl-stdin-write $stdin "\n"))))

(= (codex:js-repl-write-message
      $stdin
      $message
      $body-write-result
      $newline-write-result)
   (codex:js-repl-write-message-from-serialize-result
     $stdin
     (codex:js-repl-host-to-kernel-serialize-result $message)
     $body-write-result
     $newline-write-result))

(= (codex:js-repl-kernel-stderr-tail-snapshot $recent-stderr)
   (codex:js-repl-format-stderr-tail
     (codex:js-repl-recent-stderr-buffer-lines
       (codex:js-repl-arc-mutex-value $recent-stderr))))

(= (codex:js-repl-exit-status-code $code)
   (CodexJsReplExitStatusCode $code))

(= (codex:js-repl-exit-status-signal $signal)
   (CodexJsReplExitStatusSignal $signal))

(= (codex:js-repl-exit-status-unknown)
   CodexJsReplExitStatusUnknown)

(= (codex:js-repl-format-exit-status
      (CodexJsReplExitStatusCode $code))
   (str-concat "code=" (codex:num-format-number-text $code)))

(= (codex:js-repl-format-exit-status
      (CodexJsReplExitStatusSignal $signal))
   (str-concat "signal=" (codex:num-format-number-text $signal)))

(= (codex:js-repl-format-exit-status CodexJsReplExitStatusUnknown)
   "unknown")

(= (codex:js-repl-child-try-wait-exited $status)
   (CodexJsReplChildTryWaitExited $status))

(= (codex:js-repl-child-try-wait-running)
   CodexJsReplChildTryWaitRunning)

(= (codex:js-repl-child-try-wait-error $message)
   (CodexJsReplChildTryWaitError $message))

(= (codex:js-repl-child-inspection $pid $try-wait)
   (CodexJsReplChildInspection $pid $try-wait))

(= (codex:js-repl-child-inspection-pid
      (CodexJsReplChildInspection $pid $try-wait))
   $pid)

(= (codex:js-repl-child-inspection-status
      (CodexJsReplChildInspection
        $pid
        (CodexJsReplChildTryWaitExited $status)))
   (str-concat
     "exited("
     (str-concat
       (codex:js-repl-format-exit-status $status)
       ")")))

(= (codex:js-repl-child-inspection-status
      (CodexJsReplChildInspection
        $pid
        CodexJsReplChildTryWaitRunning))
   "running")

(= (codex:js-repl-child-inspection-status
      (CodexJsReplChildInspection
        $pid
        (CodexJsReplChildTryWaitError $message)))
   (str-concat "unknown (" (str-concat $message ")")))

(= (codex:js-repl-kernel-debug-snapshot-from-inspection
      $child-inspection
      $recent-stderr)
   (codex:js-repl-kernel-debug-snapshot
     (codex:js-repl-child-inspection-pid $child-inspection)
     (codex:js-repl-child-inspection-status $child-inspection)
     (codex:js-repl-kernel-stderr-tail-snapshot $recent-stderr)))
