!(register-module! ../codex)
!(import! &self codex:tools)
!(import! &self list)
!(import! &self process)

(= (test:argv-result-argv $result)
   (case $result
     (((CodexExecCommandArgvOk $argv) $argv)
      ($other $other))))

(= (test:argv-result-error $result)
   (case $result
     (((CodexExecCommandArgvError $message) $message)
      ($other $other))))

(= (test:session-bash-runtime-config $allow-login-shell)
   (codex:exec-command-runtime-config
     (process-shell "bash" "/bin/bash")
     (codex:direct-shell-mode)
     $allow-login-shell))

!(assertEqualToResult
  (test:argv-result-argv
    (once
      (codex:exec-command-argv-with-runtime-config
      (test:session-bash-runtime-config True)
      (codex:parse-exec-command-args "{\"cmd\":\"echo hello\"}"))))
  (("/bin/bash" "-lc" "echo hello")))

!(assertEqualToResult
  (test:argv-result-argv
    (once
      (codex:exec-command-argv-with-runtime-config
      (test:session-bash-runtime-config True)
      (codex:parse-exec-command-args "{\"cmd\":\"echo hello\",\"shell\":\"/bin/bash\"}"))))
  (("/bin/bash" "-lc" "echo hello")))

!(assertEqualToResult
  (list:at
    (test:argv-result-argv
      (once
        (codex:exec-command-argv-with-runtime-config
        (test:session-bash-runtime-config True)
        (codex:parse-exec-command-args "{\"cmd\":\"echo hello\",\"shell\":\"powershell\"}"))))
    2)
  ("echo hello"))

!(assertEqualToResult
  (list:at
    (test:argv-result-argv
      (once
        (codex:exec-command-argv-with-runtime-config
        (test:session-bash-runtime-config True)
        (codex:parse-exec-command-args "{\"cmd\":\"echo hello\",\"shell\":\"cmd\"}"))))
    2)
  ("echo hello"))

!(assertEqualToResult
  (test:argv-result-error
    (once
      (codex:exec-command-argv-with-runtime-config
      (test:session-bash-runtime-config False)
      (codex:parse-exec-command-args "{\"cmd\":\"echo hello\",\"login\":true}"))))
  ("login shell is disabled by config; omit `login` or set it to false."))

!(assertEqualToResult
  (test:argv-result-argv
    (once
      (codex:exec-command-argv-with-runtime-config
      (test:session-bash-runtime-config False)
      (codex:parse-exec-command-args "{\"cmd\":\"echo hello\"}"))))
  (("/bin/bash" "-c" "echo hello")))

!(assertEqualToResult
  (test:argv-result-argv
    (once
      (codex:exec-command-argv-with-runtime-config
      (codex:exec-command-runtime-config
        (process-shell "bash" "/bin/bash")
        (codex:zsh-fork-shell-mode
          "/opt/codex/zsh"
          "/opt/codex/codex-execve-wrapper")
        True)
      (codex:parse-exec-command-args "{\"cmd\":\"echo hello\",\"shell\":\"/bin/bash\"}"))))
  (("/opt/codex/zsh" "-lc" "echo hello")))
