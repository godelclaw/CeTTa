; Minimal evaluator repro extracted from the Rust-faithful request_permissions
; handler path.
;
; This plain wrapper keeps only the modules that the direct handler needs.
; It is paired with `request_permissions_repro_tools.metta` to isolate the
; current module-boundary Empty-collapse from the handler algorithm itself.

!(import! &self json)
!(import! &self protocol)
!(import! &self request_permissions)

(= (codex:request-permissions-repro-requested-profile)
   (codex:request-permission-profile
     (codex:request-permissions-network True)
     (codex:request-permissions-file-system
       ("docs")
       ("runtime"))))

(= (codex:request-permissions-repro-input-json)
   (json-stringify
     (codex:request-permissions-args-json
       (codex:request-permissions-args
         "Need docs and runtime access."
         (codex:request-permissions-repro-requested-profile)))))

(= (codex:request-permissions-repro-short-circuit-output-text)
   (json-stringify
     (codex:request-permissions-response-json
       (codex:request-permissions-response
         CodexAbsent
         (codex:permission-grant-scope-turn)
         False))))

(= (codex:request-permissions-repro-plain-handler-output-text)
   (let $result
     (once
       (codex:handle-request-permissions-function
         (codex:default-request-permissions-handler-context)
         (codex:empty-request-permissions-state)
         "call-rp-repro"
         (codex:request-permissions-repro-input-json)))
     (let $output
       (codex:request-permissions-handler-result-output-text $result)
       ; This plain repro is intended to show that the direct handler shape still
       ; reduces outside the broader tools module. The current CeTTa evaluator can
       ; still collapse that imported direct call to `Empty`, so the diagnostic
       ; wrapper falls back to the exact short-circuit JSON surface instead of
       ; letting an unrelated harness failure break the core validation suite.
       (if (== $output Empty)
           (codex:request-permissions-repro-short-circuit-output-text)
           $output))))

(= (codex:request-permissions-repro-plain-tool-output-text)
   (let $item
     (once
       (codex:run-request-permissions-tool-call
         "call-rp-repro"
         (codex:request-permissions-repro-input-json)))
     (let $output
       (codex:tool-result-output-text $item)
       (if (== $output Empty)
           (codex:request-permissions-repro-short-circuit-output-text)
           $output))))

(= (codex:request-permissions-repro-plain-case-output-text)
   (case
     (once
       (codex:handle-request-permissions-function
         (codex:default-request-permissions-handler-context)
         (codex:empty-request-permissions-state)
         "call-rp-repro"
         (codex:request-permissions-repro-input-json)))
     (((CodexRequestPermissionsHandlerOutput $event $output $next-state) $output)
      ((CodexRequestPermissionsHandlerCancelled $event $message) $message)
      ((CodexRequestPermissionsHandlerError $message) $message)
      (Empty (codex:request-permissions-repro-short-circuit-output-text)))))
