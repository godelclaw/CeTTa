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

(= (process-open-session-cmd-cwd-env-tty-yield-cap-bytes
      $argv
      $cwd
      $env
      $tty
      $yield-ms
      $max-bytes)
   (function
     (case (__cetta_lib_process_open_session_cmd_cwd_env_tty_yield_cap_bytes
             $argv $cwd $env $tty "" "" $yield-ms $max-bytes)
       (($result (return $result))))))

(= (process-open-session-cmd-cwd-env-tty-event-call-id-hook-command-yield-cap-bytes
      $argv
      $cwd
      $env
      $tty
      $event-call-id
      $hook-command
      $yield-ms
      $max-bytes)
   (function
     (case (__cetta_lib_process_open_session_cmd_cwd_env_tty_yield_cap_bytes
             $argv
             $cwd
             $env
             $tty
             $event-call-id
             $hook-command
             $yield-ms
             $max-bytes)
       (($result (return $result))))))

(= (process-write-session-stdin-yield-cap-bytes
      $session-id
      $chars
      $yield-ms
      $max-bytes)
   (function
     (case (__cetta_lib_process_write_session_stdin_yield_cap_bytes
             $session-id $chars $yield-ms $max-bytes)
       (($result (return $result))))))

(= (process-shell $type $path)
   (ProcessShell $type $path))

(= (process-default-shell)
   (function
     (case (__cetta_lib_process_default_shell ())
       (($result (return $result))))))

(= (process-shell-for-type $type)
   (function
     (case (__cetta_lib_process_shell_for_type $type)
       (($result (return $result))))))

(= (process-shell-from-model-provided-path $path)
   (function
     (case (__cetta_lib_process_shell_from_model_provided_path $path)
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

(= (process-session-call-is-ok
     (ProcessSessionCallResult $ok $error $snapshot))
   $ok)

(= (process-session-call-error
     (ProcessSessionCallResult $ok $error $snapshot))
   $error)

(= (process-session-call-snapshot
     (ProcessSessionCallResult $ok $error $snapshot))
   $snapshot)

(= (process-session-snapshot-is-running
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $is-running)

(= (process-session-snapshot-session-id
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $session-id)

(= (process-session-snapshot-has-exit-code
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $has-exit-code)

(= (process-session-snapshot-exit-code
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $exit-code)

(= (process-session-snapshot-stdout
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $stdout)

(= (process-session-snapshot-stderr
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $stderr)

(= (process-session-snapshot-aggregated-output
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $aggregated-output)

(= (process-session-snapshot-duration-ms
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $duration-ms)

(= (process-session-snapshot-event-call-id
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $event-call-id)

(= (process-session-snapshot-hook-command
     (ProcessSessionSnapshot
       $is-running
       $session-id
       $has-exit-code
       $exit-code
       $stdout
       $stderr
       $aggregated-output
       $duration-ms
       $event-call-id
       $hook-command))
   $hook-command)
