!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:approval)
!(import! &self codex:protocol)
!(import! &self codex:request_permissions)

(= (codex-rp-root) "/home/zarclaw/repos/CeTTa")

(= (codex-rp-requested-profile)
   (codex:request-permission-profile
     (codex:request-permissions-network True)
     (codex:request-permissions-file-system
       ("docs")
       ("runtime"))))

(= (codex-rp-input-json)
   (json-stringify
     (codex:request-permissions-args-json
       (codex:request-permissions-args
         "Need docs and runtime access."
         (codex-rp-requested-profile)))))

!(assertEqual
  (once
    (case
      (codex:run-request-permissions-tool-call-with-context-state
        (codex:request-permissions-handler-context
          (codex:ask-for-approval-on-request)
          "turn-rp"
          (codex-rp-root)
          (codex:request-permissions-response-behavior-cancel))
        (codex:empty-request-permissions-state)
        "call-rp"
        (codex-rp-input-json))
      (((CodexRequestPermissionsToolCallResult
          (CodexResponseItemCustomToolCallOutput
            $call-id
            $name
            (CodexFunctionCallOutputText $text))
          $state)
        $text))))
  "request_permissions was cancelled before receiving a response")
