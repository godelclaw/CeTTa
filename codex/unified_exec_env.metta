; Rust-faithful pure unified-exec environment/exec-server parameter slice.
;
; This ports the deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - UNIFIED_EXEC_ENV
;   - apply_unified_exec_env
;   - env_overlay_for_exec_server
;   - exec_server_env_for_request
;   - exec_server_params_for_request
;   - exec_server_process_id
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `HashMap<String, String>` for environment maps. This CeTTa slice
;   uses an ordered list of `CodexUnifiedExecEnvVar` pairs and explicit
;   key-replacement helpers. Lookup semantics match Rust `HashMap::insert` and
;   `HashMap::get`; list order is not a Rust-visible contract.
; - Rust `ExecRequest` has many sandbox/runtime fields. The exec-server params
;   helper only reads `command`, `cwd`, `env`, `exec_server_env_config`, and
;   `arg0`, so this pure boundary represents exactly those fields. The larger
;   sandbox request shape remains in the future runtime/orchestrator slice.
; - Rust returns `Option<ExecEnvPolicy>`. This port follows the existing CeTTa
;   Codex convention and represents `None` as `CodexAbsent`.

!(import! &self list)

(= (codex:unified-exec-env-var $name $value)
   (CodexUnifiedExecEnvVar $name $value))

(= (codex:unified-exec-env-var-name
      (CodexUnifiedExecEnvVar $name $value))
   $name)

(= (codex:unified-exec-env-var-value
      (CodexUnifiedExecEnvVar $name $value))
   $value)

(= (codex:unified-exec-env-defaults)
   ((codex:unified-exec-env-var "NO_COLOR" "1")
    (codex:unified-exec-env-var "TERM" "dumb")
    (codex:unified-exec-env-var "LANG" "C.UTF-8")
    (codex:unified-exec-env-var "LC_CTYPE" "C.UTF-8")
    (codex:unified-exec-env-var "LC_ALL" "C.UTF-8")
    (codex:unified-exec-env-var "COLORTERM" "")
    (codex:unified-exec-env-var "PAGER" "cat")
    (codex:unified-exec-env-var "GIT_PAGER" "cat")
    (codex:unified-exec-env-var "GH_PAGER" "cat")
    (codex:unified-exec-env-var "CODEX_CI" "1")))

(= (codex:unified-exec-env-get-inner $env $name)
   (if (== $env ())
       CodexAbsent
       (let $head (list:first $env)
         (let $tail (list:rest $env)
           (if (== (codex:unified-exec-env-var-name $head) $name)
               (codex:unified-exec-env-var-value $head)
               (codex:unified-exec-env-get-inner $tail $name))))))

(= (codex:unified-exec-env-get $env $name)
   (case (once (eval $env))
     ((() CodexAbsent)
      ($materialized-env
       (let $head (list:first $materialized-env)
         (let $tail (list:rest $materialized-env)
           (if (== (codex:unified-exec-env-var-name $head) $name)
               (codex:unified-exec-env-var-value $head)
               (case (codex:unified-exec-env-get $tail $name)
                 (($found $found))))))))))

(= (codex:unified-exec-env-contains-key $env $name)
   (if (== (codex:unified-exec-env-get $env $name) CodexAbsent)
       False
       True))

(= (codex:unified-exec-env-remove-inner $env $name)
   (if (== $env ())
       ()
       (let $head (list:first $env)
         (let $tail (list:rest $env)
           (let $rest
             (eval (codex:unified-exec-env-remove-inner $tail $name))
             (if (== (codex:unified-exec-env-var-name $head) $name)
                 $rest
                 (cons-atom $head $rest)))))))

(= (codex:unified-exec-env-remove $env $name)
   (case (once (eval $env))
     ((() ())
      ($materialized-env
       (let $head (list:first $materialized-env)
         (let $tail (list:rest $materialized-env)
           (let $rest
             (case (codex:unified-exec-env-remove $tail $name)
               (($materialized-rest $materialized-rest)))
             (if (== (codex:unified-exec-env-var-name $head) $name)
                 $rest
                 (cons-atom $head $rest)))))))))

(= (codex:unified-exec-env-insert $env $name $value)
   (let $materialized-name (once (eval $name))
     (let $materialized-value (once (eval $value))
       (let $rest
         (eval
           (codex:unified-exec-env-remove $env $materialized-name))
         (let $entry
           (eval
             (codex:unified-exec-env-var
               $materialized-name
               $materialized-value))
           (cons-atom $entry $rest))))))

(= (codex:unified-exec-apply-env-defaults $env)
   (codex:unified-exec-apply-env-defaults-from
     $env
     (codex:unified-exec-env-defaults)))

(= (codex:unified-exec-apply-env-defaults-from-inner $env $defaults)
   (if (== $defaults ())
       $env
       (let $head (list:first $defaults)
         (let $tail (list:rest $defaults)
           (let $updated
             (eval
               (codex:unified-exec-env-insert
                 $env
                 (codex:unified-exec-env-var-name $head)
                 (codex:unified-exec-env-var-value $head)))
             (codex:unified-exec-apply-env-defaults-from-inner
               $updated
               $tail))))))

(= (codex:unified-exec-apply-env-defaults-from $env $defaults)
   (case (once (eval $defaults))
     ((() (once (eval $env)))
      ($materialized-defaults
       (let $head (list:first $materialized-defaults)
         (let $tail (list:rest $materialized-defaults)
           (let $updated
             (eval
               (codex:unified-exec-env-insert
                 $env
                 (codex:unified-exec-env-var-name $head)
                 (codex:unified-exec-env-var-value $head)))
             (codex:unified-exec-apply-env-defaults-from
               $updated
               $tail))))))))

(= (codex:unified-exec-env-overlay-for-exec-server
      $request-env
      $local-policy-env)
   (if (== $request-env ())
       ()
       (let $head (list:first $request-env)
         (let $tail (list:rest $request-env)
           (let $name (codex:unified-exec-env-var-name $head)
             (let $value (codex:unified-exec-env-var-value $head)
               (let $rest
                 (eval
                   (codex:unified-exec-env-overlay-for-exec-server
                     $tail
                     $local-policy-env))
                 (if (== (codex:unified-exec-env-get $local-policy-env $name)
                         $value)
                     $rest
                     (cons-atom $head $rest)))))))))

(= (codex:unified-exec-server-env-config $policy $local-policy-env)
   (CodexUnifiedExecServerEnvConfig $policy $local-policy-env))

(= (codex:unified-exec-server-env-config-policy
      (CodexUnifiedExecServerEnvConfig $policy $local-policy-env))
   $policy)

(= (codex:unified-exec-server-env-config-local-policy-env
      (CodexUnifiedExecServerEnvConfig $policy $local-policy-env))
   $local-policy-env)

(= (codex:unified-exec-exec-request
      $command
      $cwd
      $env
      $exec-server-env-config
      $arg0)
   (CodexUnifiedExecExecRequest
     $command
     $cwd
     $env
     $exec-server-env-config
     $arg0))

(= (codex:unified-exec-exec-request-command
      (CodexUnifiedExecExecRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0))
   $command)

(= (codex:unified-exec-exec-request-cwd
      (CodexUnifiedExecExecRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0))
   $cwd)

(= (codex:unified-exec-exec-request-env
      (CodexUnifiedExecExecRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0))
   $env)

(= (codex:unified-exec-exec-request-env-config
      (CodexUnifiedExecExecRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0))
   $exec-server-env-config)

(= (codex:unified-exec-exec-request-arg0
      (CodexUnifiedExecExecRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0))
   $arg0)

(= (codex:unified-exec-server-env-for-request $request)
   (let $config (codex:unified-exec-exec-request-env-config $request)
     (if (== $config CodexAbsent)
         (codex:unified-exec-server-env-result
           CodexAbsent
           (codex:unified-exec-exec-request-env $request))
         (codex:unified-exec-server-env-result
           (codex:unified-exec-server-env-config-policy $config)
           (codex:unified-exec-env-overlay-for-exec-server
             (codex:unified-exec-exec-request-env $request)
             (codex:unified-exec-server-env-config-local-policy-env
               $config))))))

(= (codex:unified-exec-server-env-result $env-policy $env)
   (CodexUnifiedExecServerEnvResult $env-policy $env))

(= (codex:unified-exec-server-env-result-policy
      (CodexUnifiedExecServerEnvResult $env-policy $env))
   $env-policy)

(= (codex:unified-exec-server-env-result-env
      (CodexUnifiedExecServerEnvResult $env-policy $env))
   $env)

(= (codex:unified-exec-server-process-id $process-id)
   (format-args "{}" ($process-id)))

(= (codex:unified-exec-server-params
      $process-id
      $argv
      $cwd
      $env-policy
      $env
      $tty
      $pipe-stdin
      $arg0)
   (CodexUnifiedExecServerParams
     $process-id
     $argv
     $cwd
     $env-policy
     $env
     $tty
     $pipe-stdin
     $arg0))

(= (codex:unified-exec-server-params-process-id
      (CodexUnifiedExecServerParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   $process-id)

(= (codex:unified-exec-server-params-argv
      (CodexUnifiedExecServerParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   $argv)

(= (codex:unified-exec-server-params-cwd
      (CodexUnifiedExecServerParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   $cwd)

(= (codex:unified-exec-server-params-env-policy
      (CodexUnifiedExecServerParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   $env-policy)

(= (codex:unified-exec-server-params-env
      (CodexUnifiedExecServerParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   $env)

(= (codex:unified-exec-server-params-tty
      (CodexUnifiedExecServerParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   $tty)

(= (codex:unified-exec-server-params-pipe-stdin
      (CodexUnifiedExecServerParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   $pipe-stdin)

(= (codex:unified-exec-server-params-arg0
      (CodexUnifiedExecServerParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   $arg0)

(= (codex:unified-exec-server-params-for-request
      $process-id
      $request
      $tty)
   (let $env-result
     (codex:unified-exec-server-env-for-request $request)
     (codex:unified-exec-server-params
       (codex:unified-exec-server-process-id $process-id)
       (codex:unified-exec-exec-request-command $request)
       (codex:unified-exec-exec-request-cwd $request)
       (codex:unified-exec-server-env-result-policy $env-result)
       (codex:unified-exec-server-env-result-env $env-result)
       $tty
       False
       (codex:unified-exec-exec-request-arg0 $request))))
