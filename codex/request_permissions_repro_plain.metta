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

(= (codex:request-permissions-repro-plain-handler-output-text)
   (codex:request-permissions-handler-result-output-text
     (codex:handle-request-permissions-function
       (codex:default-request-permissions-handler-context)
       (codex:empty-request-permissions-state)
       "call-rp-repro"
       (codex:request-permissions-repro-input-json))))

(= (codex:request-permissions-repro-plain-tool-output-text)
   (codex:tool-result-output-text
     (once
       (codex:run-request-permissions-tool-call
         "call-rp-repro"
         (codex:request-permissions-repro-input-json)))))

(= (codex:request-permissions-repro-plain-case-output-text)
   (case
     (codex:handle-request-permissions-function
       (codex:default-request-permissions-handler-context)
       (codex:empty-request-permissions-state)
       "call-rp-repro"
       (codex:request-permissions-repro-input-json))
     (((CodexRequestPermissionsHandlerOutput $event $output $next-state) $output)
      ((CodexRequestPermissionsHandlerCancelled $event $message) $message)
      ((CodexRequestPermissionsHandlerError $message) $message))))
