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
    (process-run-shell-cwd-timeout-ms "printf \"$PWD\"" "/tmp" 1000))
  ("/tmp"))

!(assertEqualToResult
  (process-result-aggregated-output
    (process-run-shell-cwd-timeout-cap-bytes
      "printf abcdef; printf 123456 >&2"
      "/tmp"
      1000
      6))
  ("ab1234"))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-env-timeout-cap-bytes
      ("/bin/printf" "%s:%s" "argv" "ok")
      "/tmp"
      ()
      1000
      1048576))
  ("argv:ok"))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-env-timeout-cap-bytes
      ("/usr/bin/env")
      "/tmp"
      ((Env "CETTA_EXEC_TEST" "env-ok"))
      1000
      1048576))
  ("CETTA_EXEC_TEST=env-ok\n"))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-env-stdin-timeout-cap-bytes
      ("/bin/sh" "-c" "printf '%s:' \"$CETTA_EXEC_TEST\"; cat")
      "/tmp"
      ((Env "CETTA_EXEC_TEST" "stdin-env-ok"))
      "payload\n"
      1000
      1048576))
  ("stdin-env-ok:payload\n"))

!(assertEqualToResult
  (process-result-exit-code (process-run-shell "exit 3"))
  (3))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-timeout-cap-bytes
      ("/bin/sh" "-c" "printf argv-inherit-ok")
      ""
      1000
      1048576))
  ("argv-inherit-ok"))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-timeout-cap-bytes
      ("/bin/sh" "-c" "test -n \"$PATH\" && printf path-inherited")
      ""
      1000
      1048576))
  ("path-inherited"))

!(assertEqualToResult
  (process-result-exit-code
    (process-run-cmd-cwd-timeout-cap-bytes
      ("/bin/sh" "-c" "yes | head -c 200000") "" 5000 16))
  (0))

!(assertEqualToResult
  (process-result-stdout
    (process-run-cmd-cwd-timeout-cap-bytes
      ("/bin/sh" "-c" "yes | head -c 200000") "" 5000 16))
  ("y\ny\ny\ny\ny\ny\ny\ny\n"))

!(assertEqualToResult
  (process-result-timed-out?
    (process-run-cmd-cwd-timeout-cap-bytes
      ("/bin/sh" "-c" "sleep 1") "" 50 1048576))
  (True))
