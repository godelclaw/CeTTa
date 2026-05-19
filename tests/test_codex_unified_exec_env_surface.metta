!(register-module! ../codex)
!(import! &self codex:unified_exec_env)

(= (codex-ue-env-base)
   ((codex:unified-exec-env-var "NO_COLOR" "0")
    (codex:unified-exec-env-var "PATH" "/usr/bin")))

(= (codex-ue-local-policy-env)
   ((codex:unified-exec-env-var "HOME" "/client-home")
    (codex:unified-exec-env-var "PATH" "/client-path")
    (codex:unified-exec-env-var "SHELL_SET" "policy")))

(= (codex-ue-request-env)
   ((codex:unified-exec-env-var "HOME" "/client-home")
    (codex:unified-exec-env-var "PATH" "/sandbox-path")
    (codex:unified-exec-env-var "SHELL_SET" "policy")
    (codex:unified-exec-env-var "CODEX_THREAD_ID" "thread-1")
    (codex:unified-exec-env-var "CODEX_SANDBOX_NETWORK_DISABLED" "1")))

!(assertEqual
  (codex:unified-exec-env-var-name
    (codex:unified-exec-env-var "TERM" "dumb"))
  "TERM")

!(assertEqual
  (codex:unified-exec-env-var-value
    (codex:unified-exec-env-var "TERM" "dumb"))
  "dumb")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-defaults)
    "NO_COLOR")
  "1")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-defaults)
    "COLORTERM")
  "")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-defaults)
    "CODEX_CI")
  "1")

!(assertEqual
  (codex:unified-exec-env-contains-key
    (codex:unified-exec-env-defaults)
    "PAGER")
  True)

!(assertEqual
  (codex:unified-exec-env-contains-key
    (codex:unified-exec-env-defaults)
    "PATH")
  False)

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-apply-env-defaults ())
    "LANG")
  "C.UTF-8")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-apply-env-defaults ())
    "GH_PAGER")
  "cat")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-apply-env-defaults (codex-ue-env-base))
    "NO_COLOR")
  "1")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-apply-env-defaults (codex-ue-env-base))
    "PATH")
  "/usr/bin")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-insert
      (codex:unified-exec-env-insert () "A" "old")
      "A"
      "new")
    "A")
  "new")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-remove
      ((codex:unified-exec-env-var "A" "1")
       (codex:unified-exec-env-var "B" "2"))
      "A")
    "A")
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-overlay-for-exec-server
      (codex-ue-request-env)
      (codex-ue-local-policy-env))
    "PATH")
  "/sandbox-path")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-overlay-for-exec-server
      (codex-ue-request-env)
      (codex-ue-local-policy-env))
    "CODEX_THREAD_ID")
  "thread-1")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-overlay-for-exec-server
      (codex-ue-request-env)
      (codex-ue-local-policy-env))
    "CODEX_SANDBOX_NETWORK_DISABLED")
  "1")

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-overlay-for-exec-server
      (codex-ue-request-env)
      (codex-ue-local-policy-env))
    "HOME")
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-env-overlay-for-exec-server
      (codex-ue-request-env)
      (codex-ue-local-policy-env))
    "SHELL_SET")
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-server-process-id 4321)
  "4321")

!(assertEqual
  (codex:unified-exec-server-env-result-policy
    (codex:unified-exec-server-env-for-request
      (codex:unified-exec-exec-request
        ("bash" "-lc" "true")
        "/repo"
        (codex-ue-request-env)
        CodexAbsent
        CodexAbsent)))
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-server-env-result-env
      (codex:unified-exec-server-env-for-request
        (codex:unified-exec-exec-request
          ("bash" "-lc" "true")
          "/repo"
          (codex-ue-request-env)
          CodexAbsent
          CodexAbsent)))
    "HOME")
  "/client-home")

!(assertEqual
  (codex:unified-exec-server-env-result-policy
    (codex:unified-exec-server-env-for-request
      (codex:unified-exec-exec-request
        ("bash" "-lc" "true")
        "/repo"
        (codex-ue-request-env)
        (codex:unified-exec-server-env-config
          test-policy
          (codex-ue-local-policy-env))
        CodexAbsent)))
  test-policy)

!(assertEqual
  (codex:unified-exec-env-get
    (codex:unified-exec-server-env-result-env
      (codex:unified-exec-server-env-for-request
        (codex:unified-exec-exec-request
          ("bash" "-lc" "true")
          "/repo"
          (codex-ue-request-env)
          (codex:unified-exec-server-env-config
            test-policy
            (codex-ue-local-policy-env))
          CodexAbsent)))
    "PATH")
  "/sandbox-path")

!(assertEqual
  (let $params
    (codex:unified-exec-server-params-for-request
      123
      (codex:unified-exec-exec-request
        ("bash" "-lc" "true")
        "/repo"
        ((codex:unified-exec-env-var "HOME" "/client-home")
         (codex:unified-exec-env-var "PATH" "/sandbox-path")
         (codex:unified-exec-env-var "CODEX_THREAD_ID" "thread-1"))
        (codex:unified-exec-server-env-config
          test-policy
          ((codex:unified-exec-env-var "HOME" "/client-home")
           (codex:unified-exec-env-var "PATH" "/client-path")))
        CodexAbsent)
      True)
    (codex:unified-exec-server-params-process-id $params))
  "123")

!(assertEqual
  (let $params
    (codex:unified-exec-server-params-for-request
      123
      (codex:unified-exec-exec-request
        ("bash" "-lc" "true")
        "/repo"
        ((codex:unified-exec-env-var "HOME" "/client-home")
         (codex:unified-exec-env-var "PATH" "/sandbox-path")
         (codex:unified-exec-env-var "CODEX_THREAD_ID" "thread-1"))
        (codex:unified-exec-server-env-config
          test-policy
          ((codex:unified-exec-env-var "HOME" "/client-home")
           (codex:unified-exec-env-var "PATH" "/client-path")))
        CodexAbsent)
      True)
    (codex:unified-exec-server-params-argv $params))
  ("bash" "-lc" "true"))

!(assertEqual
  (let $params
    (codex:unified-exec-server-params-for-request
      123
      (codex:unified-exec-exec-request
        ("bash" "-lc" "true")
        "/repo"
        ((codex:unified-exec-env-var "HOME" "/client-home")
         (codex:unified-exec-env-var "PATH" "/sandbox-path")
         (codex:unified-exec-env-var "CODEX_THREAD_ID" "thread-1"))
        (codex:unified-exec-server-env-config
          test-policy
          ((codex:unified-exec-env-var "HOME" "/client-home")
           (codex:unified-exec-env-var "PATH" "/client-path")))
        CodexAbsent)
      True)
    (codex:unified-exec-server-params-env-policy $params))
  test-policy)

!(assertEqual
  (let $params
    (codex:unified-exec-server-params-for-request
      123
      (codex:unified-exec-exec-request
        ("bash" "-lc" "true")
        "/repo"
        ((codex:unified-exec-env-var "HOME" "/client-home")
         (codex:unified-exec-env-var "PATH" "/sandbox-path")
         (codex:unified-exec-env-var "CODEX_THREAD_ID" "thread-1"))
        (codex:unified-exec-server-env-config
          test-policy
          ((codex:unified-exec-env-var "HOME" "/client-home")
           (codex:unified-exec-env-var "PATH" "/client-path")))
        CodexAbsent)
      True)
    (codex:unified-exec-env-get
      (codex:unified-exec-server-params-env $params)
      "CODEX_THREAD_ID"))
  "thread-1")

!(assertEqual
  (let $params
    (codex:unified-exec-server-params-for-request
      123
      (codex:unified-exec-exec-request
        ("bash" "-lc" "true")
        "/repo"
        ((codex:unified-exec-env-var "HOME" "/client-home")
         (codex:unified-exec-env-var "PATH" "/sandbox-path")
         (codex:unified-exec-env-var "CODEX_THREAD_ID" "thread-1"))
        (codex:unified-exec-server-env-config
          test-policy
          ((codex:unified-exec-env-var "HOME" "/client-home")
           (codex:unified-exec-env-var "PATH" "/client-path")))
        CodexAbsent)
      True)
    (codex:unified-exec-server-params-tty $params))
  True)

!(assertEqual
  (let $params
    (codex:unified-exec-server-params-for-request
      123
      (codex:unified-exec-exec-request
        ("bash" "-lc" "true")
        "/repo"
        ((codex:unified-exec-env-var "HOME" "/client-home")
         (codex:unified-exec-env-var "PATH" "/sandbox-path")
         (codex:unified-exec-env-var "CODEX_THREAD_ID" "thread-1"))
        (codex:unified-exec-server-env-config
          test-policy
          ((codex:unified-exec-env-var "HOME" "/client-home")
           (codex:unified-exec-env-var "PATH" "/client-path")))
        CodexAbsent)
      True)
    (codex:unified-exec-server-params-pipe-stdin $params))
  False)
