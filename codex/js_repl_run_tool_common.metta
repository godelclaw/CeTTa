; Shared Rust-faithful js_repl RunTool kernel-message helpers.
;
; This carries constructor/message helpers used by both read_stdout RunTool
; slices. It intentionally imports no runtime modules so callers can compose it
; with the exact bookkeeping/I/O slices they need without duplicate reductions.

(= (codex:js-repl-kernel-to-host-run-tool
      $id
      $exec-id
      $tool-name
      $arguments)
   (CodexJsReplKernelToHostRunTool $id $exec-id $tool-name $arguments))

(= (codex:js-repl-run-tool-context-missing-message)
   "js_repl exec context not found")

(= (codex:js-repl-read-stdout-run-tool-warning-message)
   "failed to reply to kernel run_tool request")

(= (codex:js-repl-read-stdout-run-tool-action-write-message
      $message
      $write-result)
   (CodexJsReplReadStdoutRunToolActionWriteMessage
     $message
     $write-result))
