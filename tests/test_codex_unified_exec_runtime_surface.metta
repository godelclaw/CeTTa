!(register-module! ../codex)
!(import! &self json)
!(import! &self list)
!(import! &self codex:network_policy_decision)
!(import! &self codex:unified_exec_runtime)

(= (runtime-request $network $tty $sandbox-permissions $approval)
   (CodexUnifiedExecToolRequest
     ("/bin/bash" "-lc" "cargo test -p codex-core")
     "cargo test -p codex-core"
     42
     "/repo"
     env-1
     exec-env-config-1
     explicit-env-1
     $network
     $tty
     $sandbox-permissions
     additional-permissions-1
     False
     "because"
     $approval))

(= (runtime-ctx)
   (CodexUnifiedExecToolCtx session-1 turn-1 "call-7" "exec_command"))

(= (approval-ctx $guardian-review-id $retry-reason)
   (codex:approval-ctx
     session-1
     turn-1
     "call-7"
     $guardian-review-id
     $retry-reason
     (codex:network-approval-context
       "example.com"
       (codex:network-approval-protocol-https))))

(= (runtime)
   (codex:unified-exec-runtime-new manager-1 shell-mode-1))

!(assertEqual
  (codex:unified-exec-runtime-manager (runtime))
  manager-1)

!(assertEqual
  (codex:unified-exec-runtime-shell-mode (runtime))
  shell-mode-1)

!(assertEqual
  (codex:unified-exec-runtime-sandbox-preference (runtime))
  (codex:sandboxable-preference-auto))

!(assertEqual
  (codex:unified-exec-runtime-escalate-on-failure (runtime))
  True)

!(assertEqual
  (let $key
    (list:first
      (codex:unified-exec-runtime-approval-keys
        (runtime)
        (runtime-request
          network-1
          True
          "with_additional_permissions"
          (codex:approval-needs-approval
            "policy"
            (CodexExecPolicyAmendment ("cargo" "test"))))))
    (codex:unified-exec-approval-key-command $key))
  ("cargo" "test" "-p" "codex-core"))

!(assertEqual
  (let $key
    (list:first
      (codex:unified-exec-runtime-approval-keys
        (runtime)
        (runtime-request
          network-1
          True
          "with_additional_permissions"
          (codex:approval-needs-approval "policy"))))
    (codex:unified-exec-approval-key-cwd $key))
  "/repo")

!(assertEqual
  (let $key
    (list:first
      (codex:unified-exec-runtime-approval-keys
        (runtime)
        (runtime-request
          network-1
          True
          "with_additional_permissions"
          (codex:approval-needs-approval "policy"))))
    (codex:unified-exec-approval-key-tty $key))
  True)

!(assertEqual
  (codex:unified-exec-runtime-exec-approval-requirement
    (runtime)
    (runtime-request
      network-1
      True
      "use_default"
      (codex:approval-needs-approval "policy")))
  (codex:approval-needs-approval "policy"))

!(assertEqualToResult
  (json-stringify
    (codex:permission-request-payload-json
      (codex:unified-exec-runtime-permission-request-payload
        (runtime)
        (runtime-request
          network-1
          True
          "use_default"
          (codex:approval-needs-approval "policy")))))
  ("{\"tool_name\":{\"name\":\"Bash\",\"matcher_aliases\":[]},\"tool_input\":{\"command\":\"cargo test -p codex-core\",\"description\":\"because\"}}"))

!(assertEqual
  (codex:unified-exec-runtime-sandbox-mode-for-first-attempt
    (runtime)
    (runtime-request
      network-1
      True
      "require_escalated"
      (codex:approval-needs-approval "policy")))
  (codex:sandbox-override-bypass-sandbox-first-attempt))

!(assertEqual
  (codex:unified-exec-runtime-network-approval-spec
    (runtime)
    (runtime-request
      CodexAbsent
      True
      "use_default"
      (codex:approval-needs-approval "policy"))
    (runtime-ctx))
  CodexAbsent)

!(assertEqual
  (let $spec
    (codex:unified-exec-runtime-network-approval-spec
      (runtime)
      (runtime-request
        network-1
        False
        "use_default"
        (codex:approval-needs-approval "policy"))
      (runtime-ctx))
    (codex:network-approval-spec-mode $spec))
  (codex:network-approval-mode-deferred))

!(assertEqual
  (let $spec
    (codex:unified-exec-runtime-network-approval-spec
      (runtime)
      (runtime-request
        network-1
        False
        "use_default"
        (codex:approval-needs-approval "policy"))
      (runtime-ctx))
    (let $trigger (codex:network-approval-spec-trigger $spec)
      (codex:guardian-network-access-trigger-tty $trigger)))
  False)

!(assertEqual
  (let $plan
    (codex:unified-exec-runtime-start-approval-plan
      (runtime)
      (runtime-request
        network-1
        True
        "use_default"
        (codex:approval-needs-approval
          "policy"
          (CodexExecPolicyAmendment ("cargo" "test"))))
      (approval-ctx CodexAbsent "retry"))
    (codex:unified-exec-runtime-approval-plan-kind $plan))
  cached)

!(assertEqual
  (let $plan
    (codex:unified-exec-runtime-start-approval-plan
      (runtime)
      (runtime-request
        network-1
        True
        "use_default"
        (codex:approval-needs-approval
          "policy"
          (CodexExecPolicyAmendment ("cargo" "test"))))
      (approval-ctx CodexAbsent "retry"))
    (codex:unified-exec-runtime-approval-plan-cached-tool-name $plan))
  "unified_exec")

!(assertEqual
  (let $plan
    (codex:unified-exec-runtime-start-approval-plan
      (runtime)
      (runtime-request
        network-1
        True
        "use_default"
        (codex:approval-needs-approval
          "policy"
          (CodexExecPolicyAmendment ("cargo" "test"))))
      (approval-ctx CodexAbsent "retry"))
    (codex:unified-exec-runtime-approval-plan-cached-reason $plan))
  "retry")

!(assertEqual
  (let $plan
    (codex:unified-exec-runtime-start-approval-plan
      (runtime)
      (runtime-request
        network-1
        True
        "use_default"
        (codex:approval-needs-approval
          "policy"
          (CodexExecPolicyAmendment ("cargo" "test"))))
      (approval-ctx CodexAbsent CodexAbsent))
    (codex:unified-exec-runtime-approval-plan-cached-reason $plan))
  "because")

!(assertEqual
  (let $plan
    (codex:unified-exec-runtime-start-approval-plan
      (runtime)
      (runtime-request
        network-1
        True
        "use_default"
        (codex:approval-needs-approval
          "policy"
          (CodexExecPolicyAmendment ("cargo" "test"))))
      (approval-ctx CodexAbsent CodexAbsent))
    (codex:unified-exec-runtime-approval-plan-cached-proposed-execpolicy-amendment
      $plan))
  (CodexExecPolicyAmendment ("cargo" "test")))

!(assertEqual
  (let $plan
    (codex:unified-exec-runtime-start-approval-plan
      (runtime)
      (runtime-request
        network-1
        True
        "use_default"
        (codex:approval-needs-approval "policy"))
      (approval-ctx "review-1" "retry"))
    (codex:unified-exec-runtime-approval-plan-kind $plan))
  guardian)

!(assertEqual
  (let $plan
    (codex:unified-exec-runtime-start-approval-plan
      (runtime)
      (runtime-request
        network-1
        True
        "use_default"
        (codex:approval-needs-approval "policy"))
      (approval-ctx "review-1" "retry"))
    (codex:unified-exec-runtime-approval-plan-guardian-review-id $plan))
  "review-1")
