; Minimal evaluator repro extracted from the Rust-faithful request_permissions
; handler path.
;
; This wrapper differs from `request_permissions_repro_plain.metta` only by the
; extra `codex:tools` import. Under the current evaluator, that wider import
; surface is enough to collapse the same request_permissions expressions to
; `Empty`, which is the module-boundary issue blocking generic router work.

!(import! &self json)
!(import! &self protocol)
!(import! &self request_permissions)
!(import! &self tools)

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

(= (codex:request-permissions-repro-tools-handler-output-text)
   (codex:request-permissions-handler-result-output-text
     (codex:handle-request-permissions-function
       (codex:default-request-permissions-handler-context)
       (codex:empty-request-permissions-state)
       "call-rp-repro"
       (codex:request-permissions-repro-input-json))))

(= (codex:request-permissions-repro-tools-tool-output-text)
   (codex:tool-result-output-text
     (once
       (codex:run-request-permissions-tool-call
         "call-rp-repro"
         (codex:request-permissions-repro-input-json)))))
