!(register-module! ../codex)
!(import! &self codex:external_bearer)
!(import! &self codex:login_auth)
!(import! &self codex:model_provider_info)
!(import! &self process)

(= (codex-external-bearer-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-external-bearer")

(= (codex-external-bearer-cache-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/cache")

(= (codex-external-bearer-stale-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/stale")

(= (codex-external-bearer-zero-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/zero")

(= (codex-external-bearer-manager-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/manager")

(= (codex-external-bearer-recovery-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/recovery")

(= (codex-external-bearer-fail-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/fail")

(= (codex-external-bearer-empty-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/empty")

(= (codex-external-bearer-slow-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/slow")

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/cache /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/stale /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/zero /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/manager /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/recovery /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/fail /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/empty /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/slow && for d in cache stale zero manager recovery; do printf 'provider-token\\nnext-token\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/$d/tokens.txt; cat > /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/$d/print-token.sh <<'SH'\n#!/bin/sh\nfirst_line=$(sed -n '1p' tokens.txt)\nprintf '%s\\n' \"$first_line\"\ntail -n +2 tokens.txt > tokens.next\nmv tokens.next tokens.txt\nSH\nchmod +x /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/$d/print-token.sh; done && cat > /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/fail/fail.sh <<'SH'\n#!/bin/sh\nprintf 'bad token source\\n' >&2\nexit 1\nSH\nchmod +x /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/fail/fail.sh && cat > /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/empty/empty.sh <<'SH'\n#!/bin/sh\nprintf '   \\n'\nSH\nchmod +x /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/empty/empty.sh && cat > /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/slow/slow.sh <<'SH'\n#!/bin/sh\nsleep 1\nprintf late\nSH\nchmod +x /home/zarclaw/repos/CeTTa/runtime/codex-external-bearer/slow/slow.sh"))
  (0))

(= (codex-external-bearer-config $cwd $refresh-interval-ms)
   (codex:model-provider-auth-info
     "./print-token.sh"
     ()
     1000
     $refresh-interval-ms
     $cwd))

!(assertEqualToResult
  (codex:resolve-provider-auth-program "/tmp/print-token.sh" "/repo")
  ("/tmp/print-token.sh"))

!(assertEqualToResult
  (codex:resolve-provider-auth-program "./print-token.sh" "/repo")
  ("/repo/print-token.sh"))

!(assertEqualToResult
  (codex:resolve-provider-auth-program "print-token" "/repo")
  ("print-token"))

!(assertEqualToResult
  (case (codex:bearer-token-refresher-resolve-at
          (codex:bearer-token-refresher-new
            (codex-external-bearer-config
              (codex-external-bearer-cache-root)
              60000))
          1000)
    (((CodexExternalBearerResolveOk $first-refresher $first-tokens)
      (case (codex:bearer-token-refresher-resolve-at $first-refresher 2000)
        (((CodexExternalBearerResolveOk $second-refresher $second-tokens)
          (case (codex:bearer-token-refresher-refresh-at
                  $second-refresher
                  3000)
            (((CodexExternalBearerResolveOk $refreshed-refresher $refresh-tokens)
              ((codex:external-auth-tokens-access-token $first-tokens)
               (codex:external-auth-tokens-access-token $second-tokens)
               (codex:external-auth-tokens-access-token $refresh-tokens)))))))))))
  (("provider-token" "provider-token" "next-token")))

!(assertEqualToResult
  (case (codex:bearer-token-refresher-resolve-at
          (codex:bearer-token-refresher-new
            (codex-external-bearer-config
              (codex-external-bearer-stale-root)
              50))
          1000)
    (((CodexExternalBearerResolveOk $first-refresher $first-tokens)
      (case (codex:bearer-token-refresher-resolve-at $first-refresher 1100)
        (((CodexExternalBearerResolveOk $second-refresher $second-tokens)
          (codex:external-auth-tokens-access-token $second-tokens)))))))
  ("next-token"))

!(assertEqualToResult
  (case (codex:bearer-token-refresher-resolve-at
          (codex:bearer-token-refresher-new
            (codex-external-bearer-config
              (codex-external-bearer-zero-root)
              0))
          1000)
    (((CodexExternalBearerResolveOk $first-refresher $first-tokens)
      (case (codex:bearer-token-refresher-resolve-at $first-refresher 1000000)
        (((CodexExternalBearerResolveOk $second-refresher $second-tokens)
          (codex:external-auth-tokens-access-token $second-tokens)))))))
  ("provider-token"))

!(assertEqualToResult
  (codex:external-bearer-run-result-message
    (codex:run-provider-auth-command
      (codex:model-provider-auth-info
        "./fail.sh"
        ()
        1000
        60000
        (codex-external-bearer-fail-root))))
  ("provider auth command `./fail.sh` exited with status exit status: 1: bad token source"))

!(assertEqualToResult
  (codex:external-bearer-auth-manager-auth-auth
    (codex:external-bearer-auth-manager-auth-at
      (codex:external-bearer-auth-manager
        (codex:bearer-token-refresher-new
          (codex:model-provider-auth-info
            "./fail.sh"
            ()
            1000
            60000
            (codex-external-bearer-fail-root))))
      4000))
  (CodexAbsent))

!(assertEqualToResult
  (codex:external-bearer-run-result-message
    (codex:run-provider-auth-command
      (codex:model-provider-auth-info
        "./empty.sh"
        ()
        1000
        60000
        (codex-external-bearer-empty-root))))
  ("provider auth command `./empty.sh` produced an empty token"))

!(assertEqualToResult
  (codex:external-bearer-run-result-message
    (codex:run-provider-auth-command
      (codex:model-provider-auth-info
        "./slow.sh"
        ()
        50
        60000
        (codex-external-bearer-slow-root))))
  ("provider auth command `./slow.sh` timed out after 50 ms"))

(= (codex-external-bearer-manager-auth)
   (codex:external-bearer-auth-manager-auth-at
     (codex:external-bearer-auth-manager
       (codex:bearer-token-refresher-new
         (codex-external-bearer-config
           (codex-external-bearer-manager-root)
           60000)))
     4000))

!(assertEqualToResult
  (codex:codex-auth-token-result-value
    (codex:codex-auth-get-token
      (codex:external-bearer-auth-manager-auth-auth
        (codex-external-bearer-manager-auth))))
  ("provider-token"))

!(assertEqualToResult
  (case (codex:external-bearer-auth-manager-auth-at
          (codex:external-bearer-auth-manager
            (codex:bearer-token-refresher-new
              (codex-external-bearer-config
                (codex-external-bearer-recovery-root)
                0)))
          1000)
    (((CodexExternalBearerAuthManagerAuthOk $initial-manager $initial-auth)
      (let $recovery
        (codex:auth-manager-unauthorized-recovery $initial-manager)
        (case (codex:unauthorized-recovery-next-at $recovery 2000)
          (((CodexUnauthorizedRecoveryNextOk $done-recovery $step-result)
            (case (codex:external-bearer-auth-manager-auth-at
                    (codex:unauthorized-recovery-manager $done-recovery)
                    3000)
              (((CodexExternalBearerAuthManagerAuthOk $refreshed-manager $refreshed-auth)
                ((codex:unauthorized-recovery-mode-name $recovery)
                 (codex:unauthorized-recovery-step-name $recovery)
                 (codex:unauthorized-recovery-has-next $recovery)
                 (codex:unauthorized-recovery-unavailable-reason $recovery)
                 (codex:codex-auth-token-result-value
                   (codex:codex-auth-get-token $initial-auth))
                 (codex:unauthorized-recovery-step-result-auth-state-changed
                   $step-result)
                 (codex:unauthorized-recovery-step-name $done-recovery)
                 (codex:unauthorized-recovery-has-next $done-recovery)
                 (codex:unauthorized-recovery-unavailable-reason $done-recovery)
                 (codex:codex-auth-token-result-value
                   (codex:codex-auth-get-token $refreshed-auth)))))))))))))
  (("external"
    "external_refresh"
    True
    "ready"
    "provider-token"
    True
    "done"
    False
    "recovery_exhausted"
    "next-token")))

!(assertEqualToResult
  (codex:unauthorized-recovery-next-result-message
    (codex:unauthorized-recovery-next-at
      (codex:unauthorized-recovery
        (codex:external-bearer-auth-manager
          (codex:bearer-token-refresher-new
            (codex-external-bearer-config
              (codex-external-bearer-manager-root)
              60000)))
        CodexAbsent
        (codex:unauthorized-recovery-mode-external)
        (codex:unauthorized-recovery-step-done))
      5000))
  ("No more recovery steps available."))

!(assertEqualToResult
  (case (codex:unauthorized-recovery-next-at
          (codex:auth-manager-unauthorized-recovery
            (codex:external-bearer-auth-manager
              (codex:bearer-token-refresher-new
                (codex:model-provider-auth-info
                  "./fail.sh"
                  ()
                  1000
                  60000
                  (codex-external-bearer-fail-root)))))
          6000)
    (((CodexUnauthorizedRecoveryNextErr $recovery $message)
      ($message
       (codex:unauthorized-recovery-step-name $recovery)
       (codex:unauthorized-recovery-has-next $recovery)))))
  (("provider auth command `./fail.sh` exited with status exit status: 1: bad token source"
    "external_refresh"
    True)))
