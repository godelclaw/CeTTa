!(register-module! ../codex)
!(import! &self fs)
!(import! &self json)
!(import! &self codex:apply_patch)
!(import! &self codex:approval)
!(import! &self codex:request_permissions)

(= (codex-rp-demo-root) "/home/zarclaw/repos/CeTTa")
(= (codex-rp-demo-file) "/home/zarclaw/repos/CeTTa/runtime/codex-rp-demo.txt")

!(fs-write-text (codex-rp-demo-file) "before\n")

(= (codex-rp-demo-state)
   (let $handler
     (codex:handle-request-permissions-payload
       (codex:request-permissions-handler-context
         (codex:ask-for-approval-on-request)
         "turn-demo"
         (codex-rp-demo-root)
         (codex:request-permissions-response-behavior-return
           (codex:request-permissions-response
             (codex:request-permission-profile
               CodexAbsent
               (codex:request-permissions-file-system
                 ()
                 ("/home/zarclaw/repos/CeTTa/runtime")))
             (codex:permission-grant-scope-turn)
             False)))
       (codex:empty-request-permissions-state)
       "call-rp-demo"
       (codex:request-permissions-function-payload
         "{\"reason\":\"Need to patch runtime.\",\"permissions\":{\"file_system\":{\"write\":[\"runtime\"]}}}"))
     (codex:request-permissions-handler-result-state $handler)))

(= (codex-rp-demo-turn-permissions-json)
   (let $state (codex-rp-demo-state)
     (json-stringify
       (codex:request-permission-profile-json
         (codex:request-permissions-state-turn-permissions $state)))))

!(println!
  (once
    (let $handler
      (codex:handle-request-permissions-payload
        (codex:request-permissions-handler-context
          (codex:ask-for-approval-on-request)
          "turn-demo"
          (codex-rp-demo-root)
          (codex:request-permissions-response-behavior-return
            (codex:request-permissions-response
              (codex:request-permission-profile
                CodexAbsent
                (codex:request-permissions-file-system
                  ()
                  ("/home/zarclaw/repos/CeTTa/runtime")))
              (codex:permission-grant-scope-turn)
              False)))
        (codex:empty-request-permissions-state)
        "call-rp-demo"
        (codex:request-permissions-function-payload
          "{\"reason\":\"Need to patch runtime.\",\"permissions\":{\"file_system\":{\"write\":[\"runtime\"]}}}"))
      (let $state (codex:request-permissions-handler-result-state $handler)
        (codex:run-apply-patch-with-request-permissions-state
          $state
          (codex:ask-for-approval-on-request)
          (codex:patch-sandbox-workspace-write)
          (codex:patch-fs-policy ("/home/zarclaw/repos/CeTTa/src") () ())
          "*** Begin Patch\n*** Update File: runtime/codex-rp-demo.txt\n@@\n-before\n+after\n*** End Patch"
          False)))))
!(println! (fs-read-text (codex-rp-demo-file)))
!(println! (codex-rp-demo-turn-permissions-json))
