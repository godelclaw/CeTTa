!(import! &self process)

!(assertEqualToResult
  (process-result-exit-code (process-run-shell "printf hello"))
  (0))

!(assertEqualToResult
  (process-result-stdout (process-run-shell "printf hello"))
  ("hello"))

!(assertEqualToResult
  (process-result-stderr (process-run-shell "printf err >&2"))
  ("err"))

!(assertEqualToResult
  (process-result-timed-out? (process-run-shell-timeout-ms "sleep 1" 50))
  (True))

!(assertEqualToResult
  (process-result-stdout
    (process-run-shell-cwd-timeout-ms "printf \"$PWD\"" "/home/zarclaw/repos/CeTTa" 1000))
  ("/home/zarclaw/repos/CeTTa"))

!(assertEqualToResult
  (process-result-aggregated-output
    (process-run-shell-cwd-timeout-cap-bytes
      "printf abcdef; printf 123456 >&2"
      "/home/zarclaw/repos/CeTTa"
      1000
      6))
  ("ab1234"))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-env-timeout-cap-bytes
      ("/bin/printf" "%s:%s" "argv" "ok")
      "/home/zarclaw/repos/CeTTa"
      ()
      1000
      1048576))
  ("argv:ok"))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-env-timeout-cap-bytes
      ("/usr/bin/env")
      "/home/zarclaw/repos/CeTTa"
      ((Env "CODEX_EXEC_TEST" "env-ok"))
      1000
      1048576))
  ("CODEX_EXEC_TEST=env-ok\n"))

!(assertEqualToResult
  (process-shell-argv (process-shell "bash" "/bin/bash") "printf hi" True)
  (("/bin/bash" "-lc" "printf hi")))

!(assertEqualToResult
  (process-shell-argv (process-shell "zsh" "/bin/zsh") "printf hi" False)
  (("/bin/zsh" "-c" "printf hi")))

!(assertEqualToResult
  (process-shell-argv (process-shell "powershell" "pwsh") "Write-Output hi" False)
  (("pwsh" "-NoProfile" "-Command" "Write-Output hi")))

!(assertEqualToResult
  (process-shell-argv (process-shell "powershell" "pwsh") "Write-Output hi" True)
  (("pwsh" "-Command" "Write-Output hi")))

!(assertEqualToResult
  (process-shell-argv (process-shell "cmd" "cmd.exe") "echo hi" True)
  (("cmd.exe" "/c" "echo hi")))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-env-timeout-cap-bytes
      (process-shell-argv (process-default-shell) "printf codex-shell" True)
      "/home/zarclaw/repos/CeTTa"
      ()
      1000
      1048576))
  ("codex-shell"))

!(assertEqualToResult
  (process-create-shell-env
    (process-shell-env-policy
      "none"
      True
      ()
      ((Env "ONLY_VAR" "yes"))
      ())
    "thread-1")
  (((Env "ONLY_VAR" "yes") (Env "CODEX_THREAD_ID" "thread-1"))))

!(assertEqualToResult
  (process-create-shell-env
    (process-shell-env-policy
      "none"
      True
      ()
      ((Env "KEEP_PATH" "yes") (Env "DROP_ME" "no"))
      ("*path"))
    "thread-2")
  (((Env "KEEP_PATH" "yes") (Env "CODEX_THREAD_ID" "thread-2"))))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-env-timeout-cap-bytes
      ("/bin/sh" "-lc" "printf \"%s:%s:%s\" \"$ONLY_VAR\" \"$CODEX_THREAD_ID\" \"$DROP_ME\"")
      "/home/zarclaw/repos/CeTTa"
      (process-create-shell-env
        (process-shell-env-policy
          "none"
          True
          ()
          ((Env "ONLY_VAR" "yes"))
          ())
        "thread-3")
      1000
      1048576))
  ("yes:thread-3:"))
