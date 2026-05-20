!(register-module! ../codex)
!(import! &self fs)
!(import! &self json)
!(import! &self codex:apply_patch)
!(import! &self codex:apply_patch_runtime)
!(import! &self codex:approval)
!(import! &self codex:permissions)
!(import! &self codex:protocol)
!(import! &self codex:request_permissions)
!(import! &self codex:tool_sandboxing)

(= (runtime)
   (codex:apply-patch-runtime-new))

(= (patch-text)
   "*** Begin Patch\n*** Add File: a.txt\n+hello\n*** End Patch")

(= (patch-action)
   (CodexApplyPatchAction
     "/repo"
     ((CodexApplyPatchFileChangeAdd "a.txt" "hello\n"))))

(= (runtime-request)
   (codex:apply-patch-runtime-request
     (patch-action)
     (patch-text)
     ("/repo/a.txt")
     ((codex:file-change-map-entry
        "a.txt"
        (codex:file-change-add "hello\n")))
     False
     (codex:approval-needs-approval CodexAbsent)
     CodexAbsent
     False))

(= (runtime-request-permissions-preapproved)
   (codex:apply-patch-runtime-request
     (patch-action)
     (patch-text)
     ("/repo/a.txt")
     ((codex:file-change-map-entry
        "a.txt"
        (codex:file-change-add "hello\n")))
     False
     (codex:approval-needs-approval CodexAbsent)
     CodexAbsent
     True))

(= (runtime-request-with-additional-permissions)
   (codex:apply-patch-runtime-request
     (patch-action)
     (patch-text)
     ("/repo/a.txt")
     ((codex:file-change-map-entry
        "a.txt"
        (codex:file-change-add "hello\n")))
     False
     (codex:approval-needs-approval CodexAbsent)
     (codex:request-permission-profile
       (codex:request-permissions-network True)
       (codex:request-permissions-file-system () ("/repo/extra")))
     False))

(= (runtime-base-file-system-policy)
   (codex:file-system-sandbox-policy-restricted
     ((codex:file-system-sandbox-entry
        (codex:file-system-path-path "/repo")
        (codex:file-system-access-read)))))

(= (runtime-merged-file-system-policy)
   (codex:file-system-sandbox-policy-restricted
     ((codex:file-system-sandbox-entry
        (codex:file-system-path-path "/repo")
        (codex:file-system-access-read))
      (codex:file-system-sandbox-entry
        (codex:file-system-path-path "/repo/extra")
        (codex:file-system-access-write)))))

(= (runtime-sandbox-attempt)
   (CodexSandboxAttempt
     "MacosSeatbelt"
     (codex:session-sandbox-policy-read-only
       (codex:session-read-only-access-full)
       (codex:session-network-access-restricted))
     (runtime-base-file-system-policy)
     (codex:network-sandbox-policy-restricted)
     False
     SandboxManager
     "/repo"
     CodexAbsent
     True
     (codex:windows-sandbox-level-restricted-token)
     True))

(= (runtime-no-sandbox-attempt)
   (CodexSandboxAttempt
     "None"
     (codex:session-sandbox-policy-danger-full-access)
     (codex:file-system-sandbox-policy-unrestricted)
     (codex:network-sandbox-policy-enabled)
     False
     SandboxManager
     "/repo"
     CodexAbsent
     False
     (codex:windows-sandbox-level-disabled)
     False))

(= (runtime-run-patch-text)
   "*** Begin Patch\n*** Update File: runtime/codex-apply-runtime-run.txt\n@@\n-before\n+after\n*** End Patch")

(= (runtime-run-stdout)
   "Success. Updated the following files:\nM runtime/codex-apply-runtime-run.txt\n")

(= (runtime-run-request)
   (codex:apply-patch-runtime-request
     (CodexApplyPatchAction
       "/home/zarclaw/repos/CeTTa"
       ((CodexApplyPatchFileChangeUpdate
          "runtime/codex-apply-runtime-run.txt"
          "@@\n-before\n+after\n"
          CodexAbsent
          "after\n")))
     (runtime-run-patch-text)
     ("/home/zarclaw/repos/CeTTa/runtime/codex-apply-runtime-run.txt")
     ((codex:file-change-map-entry
        "runtime/codex-apply-runtime-run.txt"
        (codex:file-change-update "@@\n-before\n+after\n" CodexAbsent)))
     False
     (codex:approval-skip False)
     CodexAbsent
     False))

(= (runtime-run-context $environment-available)
   (codex:apply-patch-runtime-run-context
     "call-run"
     "linux"
     $environment-available
     CodexAbsent))

(= (approval-ctx $guardian-review-id $retry-reason)
   (codex:approval-ctx
     session-1
     turn-1
     "call-1"
     $guardian-review-id
     $retry-reason
     CodexAbsent))

!(assertEqual
  (codex:apply-patch-runtime-sandbox-preference (runtime))
  (codex:sandboxable-preference-auto))

!(assertEqual
  (codex:apply-patch-runtime-escalate-on-failure (runtime))
  True)

!(assertEqual
  (codex:apply-patch-runtime-wants-no-sandbox-approval
    (runtime)
    (codex:ask-for-approval-never))
  False)

!(assertEqual
  (codex:apply-patch-runtime-wants-no-sandbox-approval
    (runtime)
    (codex:ask-for-approval-on-request))
  True)

!(assertEqual
  (codex:apply-patch-runtime-wants-no-sandbox-approval
    (runtime)
    (codex:ask-for-approval-on-failure))
  True)

!(assertEqual
  (codex:apply-patch-runtime-wants-no-sandbox-approval
    (runtime)
    (codex:ask-for-approval-unless-trusted))
  True)

!(assertEqual
  (codex:apply-patch-runtime-wants-no-sandbox-approval
    (runtime)
    (codex:ask-for-approval-granular False))
  False)

!(assertEqual
  (codex:apply-patch-runtime-wants-no-sandbox-approval
    (runtime)
    (codex:ask-for-approval-granular-config
      True
      True
      True
      True
      True))
  True)

!(assertEqual
  (codex:apply-patch-runtime-approval-keys
    (runtime)
    (runtime-request))
  ("/repo/a.txt"))

!(assertEqual
  (codex:apply-patch-runtime-exec-approval-requirement
    (runtime)
    (runtime-request))
  (codex:approval-needs-approval CodexAbsent))

!(assertEqualToResult
  (json-stringify
    (codex:permission-request-payload-json
      (codex:apply-patch-runtime-permission-request-payload
        (runtime)
        (runtime-request))))
  ("{\"tool_name\":{\"name\":\"apply_patch\",\"matcher_aliases\":[\"Write\",\"Edit\"]},\"tool_input\":{\"command\":\"*** Begin Patch\\n*** Add File: a.txt\\n+hello\\n*** End Patch\"}}"))

!(assertEqual
  (codex:apply-patch-runtime-build-guardian-review-request
    (runtime)
    (runtime-request)
    "call-1")
  (codex:guardian-approval-request-apply-patch
    "call-1"
    "/repo"
    ("/repo/a.txt")
    (patch-text)))

!(assertEqualToResult
  (json-stringify
    (codex:guardian-approval-request-apply-patch-json
      (codex:apply-patch-runtime-build-guardian-review-request
        (runtime)
        (runtime-request)
        "call-1")))
  ("{\"tool\":\"apply_patch\",\"cwd\":\"/repo\",\"files\":[\"/repo/a.txt\"],\"patch\":\"*** Begin Patch\\n*** Add File: a.txt\\n+hello\\n*** End Patch\"}"))

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request)
      (approval-ctx CodexAbsent CodexAbsent))
    (codex:apply-patch-runtime-approval-plan-kind $plan))
  cached)

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request)
      (approval-ctx CodexAbsent CodexAbsent))
    (codex:apply-patch-runtime-approval-plan-cached-tool-name $plan))
  "apply_patch")

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request)
      (approval-ctx CodexAbsent CodexAbsent))
    (codex:apply-patch-runtime-approval-plan-cached-keys $plan))
  ("/repo/a.txt"))

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request)
      (approval-ctx CodexAbsent CodexAbsent))
    (codex:apply-patch-runtime-approval-plan-cached-reason $plan))
  CodexAbsent)

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request-permissions-preapproved)
      (approval-ctx CodexAbsent CodexAbsent))
    (codex:apply-patch-runtime-approval-plan-kind $plan))
  preapproved)

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request-permissions-preapproved)
      (approval-ctx CodexAbsent CodexAbsent))
    (codex:apply-patch-runtime-approval-plan-preapproved-decision $plan))
  (codex:review-decision-approved))

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request-permissions-preapproved)
      (approval-ctx CodexAbsent "retry"))
    (codex:apply-patch-runtime-approval-plan-kind $plan))
  direct_patch_approval)

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request-permissions-preapproved)
      (approval-ctx CodexAbsent "retry"))
    (codex:apply-patch-runtime-approval-plan-direct-reason $plan))
  "retry")

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request-permissions-preapproved)
      (approval-ctx CodexAbsent "retry"))
    (codex:apply-patch-runtime-approval-plan-direct-call-id $plan))
  "call-1")

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request-permissions-preapproved)
      (approval-ctx "review-1" "retry"))
    (codex:apply-patch-runtime-approval-plan-kind $plan))
  guardian)

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request-permissions-preapproved)
      (approval-ctx "review-1" "retry"))
    (codex:apply-patch-runtime-approval-plan-guardian-review-id $plan))
  "review-1")

!(assertEqual
  (let $plan
    (codex:apply-patch-runtime-start-approval-plan
      (runtime)
      (runtime-request-permissions-preapproved)
      (approval-ctx "review-1" "retry"))
    (codex:apply-patch-runtime-approval-plan-guardian-request $plan))
  (codex:guardian-approval-request-apply-patch
    "call-1"
    "/repo"
    ("/repo/a.txt")
    (patch-text)))

!(assertEqual
  (codex:apply-patch-runtime-effective-file-system-sandbox-policy
    (runtime-base-file-system-policy)
    (codex:request-permission-profile
      CodexAbsent
      (codex:request-permissions-file-system () ("/repo/extra"))))
  (runtime-merged-file-system-policy))

!(assertEqual
  (codex:apply-patch-runtime-effective-network-sandbox-policy
    (codex:network-sandbox-policy-restricted)
    (codex:request-permission-profile
      (codex:request-permissions-network True)
      CodexAbsent))
  (codex:network-sandbox-policy-enabled))

!(assertEqual
  (codex:apply-patch-runtime-file-system-sandbox-context-for-attempt
    (runtime)
    (runtime-request-with-additional-permissions)
    (runtime-sandbox-attempt))
  (codex:apply-patch-runtime-file-system-sandbox-context
    (codex:apply-patch-runtime-permission-profile-managed
      (codex:apply-patch-runtime-managed-file-system-permissions-restricted
        (codex:file-system-sandbox-policy-entries
          (runtime-merged-file-system-policy))
        CodexAbsent)
      (codex:network-sandbox-policy-enabled))
    "/repo"
    (codex:windows-sandbox-level-restricted-token)
    True
    True))

!(assertEqual
  (codex:apply-patch-runtime-file-system-sandbox-context-for-attempt
    (runtime)
    (runtime-request)
    (runtime-no-sandbox-attempt))
  CodexAbsent)

!(assertEqual
  (codex:apply-patch-runtime-output-delta-events
    "call-delta"
    "stdout text"
    "")
  ((codex:exec-command-output-delta-event
     "call-delta"
     "stdout"
     "stdout text")))

!(assertEqual
  (codex:apply-patch-runtime-finish-patch-result
    "LinuxSeccomp"
    "linux"
    "call-denied"
    CodexAbsent
    (PatchResult False "" "Operation not permitted" ()))
  (codex:apply-patch-runtime-run-err
    (codex:apply-patch-runtime-tool-error-sandbox-denied
      (codex:apply-patch-runtime-exec-tool-call-output
        1
        ""
        "Operation not permitted"
        CodexAbsent)
      CodexAbsent)
    ((codex:exec-command-output-delta-event
       "call-denied"
       "stderr"
       "Operation not permitted"))))

!(assertEqual
  (codex:apply-patch-runtime-is-likely-sandbox-denied
    "None"
    (codex:apply-patch-runtime-exec-tool-call-output
      1
      ""
      "Operation not permitted"
      CodexAbsent)
    "linux")
  False)

!(assertEqual
  (codex:apply-patch-runtime-is-likely-sandbox-denied
    "LinuxSeccomp"
    (codex:apply-patch-runtime-exec-tool-call-output
      0
      ""
      "Operation not permitted"
      CodexAbsent)
    "linux")
  False)

!(assertEqual
  (codex:apply-patch-runtime-is-likely-sandbox-denied
    "LinuxSeccomp"
    (codex:apply-patch-runtime-exec-tool-call-output
      2
      ""
      "ordinary failure"
      CodexAbsent)
    "linux")
  False)

!(assertEqual
  (codex:apply-patch-runtime-is-likely-sandbox-denied
    "LinuxSeccomp"
    (codex:apply-patch-runtime-exec-tool-call-output
      159
      ""
      "ordinary failure"
      CodexAbsent)
    "linux")
  True)

!(assertEqual
  (codex:apply-patch-runtime-run
    (runtime)
    (runtime-run-request)
    (runtime-no-sandbox-attempt)
    (runtime-run-context False))
  (codex:apply-patch-runtime-run-err
    (codex:apply-patch-runtime-tool-error-rejected
      "apply_patch is unavailable in this session")
    ()))

!(fs-write-text
   "/home/zarclaw/repos/CeTTa/runtime/codex-apply-runtime-run.txt"
   "before\n")

!(assertEqual
  (codex:apply-patch-runtime-run
    (runtime)
    (runtime-run-request)
    (runtime-no-sandbox-attempt)
    (runtime-run-context True))
  (codex:apply-patch-runtime-run-ok
    (codex:apply-patch-runtime-exec-tool-call-output
      0
      (runtime-run-stdout)
      ""
      CodexAbsent)
    ((codex:exec-command-output-delta-event
       "call-run"
       "stdout"
       (runtime-run-stdout)))))

!(assertEqualToResult
  (fs-read-text
    "/home/zarclaw/repos/CeTTa/runtime/codex-apply-runtime-run.txt")
  ("after\n"))
