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

(= (process-run-cmd-cwd-env-stdin-timeout-cap-bytes $argv $cwd $env $stdin $timeout-ms $max-bytes)
   (function
     (case (__cetta_lib_process_run_cmd_cwd_env_stdin_timeout_cap_bytes
             $argv $cwd $env $stdin $timeout-ms $max-bytes)
       (($result (return $result))))))

(= (process-run-cmd-cwd-timeout-cap-bytes $argv $cwd $timeout-ms $max-bytes)
   (function
     (case (__cetta_lib_process_run_cmd_cwd_timeout_cap_bytes
             $argv $cwd $timeout-ms $max-bytes)
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
