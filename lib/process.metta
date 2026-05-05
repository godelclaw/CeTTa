(= (process-run-shell $command)
   (function
     (case (__cetta_lib_process_run_shell $command)
       (($result (return $result))))))

(= (process-run-shell-timeout-ms $command $timeout-ms)
   (function
     (case (__cetta_lib_process_run_shell_timeout_ms $command $timeout-ms)
       (($result (return $result))))))

(= (process-run-shell-cwd-timeout-ms $command $cwd $timeout-ms)
   (function
     (case (__cetta_lib_process_run_shell_cwd_timeout_ms $command $cwd $timeout-ms)
       (($result (return $result))))))

(= (process-run-shell-cwd-timeout-cap-bytes $command $cwd $timeout-ms $max-bytes)
   (function
     (case (__cetta_lib_process_run_shell_cwd_timeout_cap_bytes $command $cwd $timeout-ms $max-bytes)
       (($result (return $result))))))

(= (process-run-cmd-cwd-env-timeout-cap-bytes $argv $cwd $env $timeout-ms $max-bytes)
   (function
     (case (__cetta_lib_process_run_cmd_cwd_env_timeout_cap_bytes
             $argv $cwd $env $timeout-ms $max-bytes)
       (($result (return $result))))))

(= (process-shell $type $path)
   (ProcessShell $type $path))

(= (process-default-shell)
   (function
     (case (__cetta_lib_process_default_shell ())
       (($result (return $result))))))

(= (process-shell-argv $shell $command $use-login-shell)
   (function
     (case (__cetta_lib_process_shell_argv $shell $command $use-login-shell)
       (($result (return $result))))))

(= (process-shell-type (ProcessShell $type $path))
   $type)

(= (process-shell-path (ProcessShell $type $path))
   $path)

(= (process-shell-env-policy $inherit $ignore-default-excludes $exclude $set $include-only)
   (ShellEnvPolicy $inherit $ignore-default-excludes $exclude $set $include-only))

(= (process-default-shell-env-policy)
   (process-shell-env-policy "all" True () () ()))

(= (process-create-shell-env $policy $thread-id)
   (function
     (case (__cetta_lib_process_create_shell_env $policy $thread-id)
       (($result (return $result))))))

(= (process-create-shell-env-no-thread $policy)
   (function
     (case (__cetta_lib_process_create_shell_env_no_thread $policy)
       (($result (return $result))))))

(= (process-result-exit-code
     (ProcessResult $exit-code $stdout $stderr $aggregated-output $duration-ms $timed-out))
   $exit-code)

(= (process-result-stdout
     (ProcessResult $exit-code $stdout $stderr $aggregated-output $duration-ms $timed-out))
   $stdout)

(= (process-result-stderr
     (ProcessResult $exit-code $stdout $stderr $aggregated-output $duration-ms $timed-out))
   $stderr)

(= (process-result-aggregated-output
     (ProcessResult $exit-code $stdout $stderr $aggregated-output $duration-ms $timed-out))
   $aggregated-output)

(= (process-result-duration-ms
     (ProcessResult $exit-code $stdout $stderr $aggregated-output $duration-ms $timed-out))
   $duration-ms)

(= (process-result-timed-out?
     (ProcessResult $exit-code $stdout $stderr $aggregated-output $duration-ms $timed-out))
   $timed-out)
