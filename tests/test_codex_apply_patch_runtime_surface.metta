!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:apply_patch)
!(import! &self codex:apply_patch_runtime)
!(import! &self codex:approval)
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
