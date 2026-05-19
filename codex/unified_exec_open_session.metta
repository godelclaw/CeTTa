; Rust-faithful pure unified-exec open-session spawn boundary.
;
; This ports deterministic branch and error behavior from:
; - openai-codex/codex-rs/core/src/unified_exec/process_manager.rs
;   - UnifiedExecProcessManager::open_session_with_exec_env
; - openai-codex/codex-rs/core/src/unified_exec/process.rs
;   - SpawnLifecycle inherited_fds / after_spawn timing
;
; Covered in this increment:
; - Windows restricted-token sandbox branch selection
; - remote exec-server branch selection and inherited-fd rejection
; - local PTY vs no-stdin pipe spawn branch selection
; - missing command-line error on the local branch
; - create-process error mapping for runtime spawn/start failures
; - `spawn_lifecycle.after_spawn()` timing on successful spawn/start
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust performs OS process spawn, exec-server start, Windows policy
;   serialization, codex-home lookup, and UnifiedExecProcess construction as
;   async effects. This pure boundary receives those effect results explicitly
;   as `CodexUnifiedExecOpenSessionRuntimeInputs` and returns the same visible
;   branch/error shape.
; - Rust's `UnifiedExecProcess::from_spawned` / `from_exec_server_started`
;   perform early-exit and sandbox-denial checks. This slice materializes the
;   process source and spawn request after a successful spawn/start; the later
;   process-runtime slice should perform those constructor checks at the same
;   boundary.
; - Rust compiles the Windows restricted-token branch only on Windows. This
;   pure helper takes an explicit host-platform tag and only enters that branch
;   for `codex:host-platform-windows`, matching the Rust cfg for a fixed host.

!(import! &self list)
!(import! &self sandbox_tags)
!(import! &self unified_exec_env)
!(import! &self unified_exec_state)

(= (codex:unified-exec-open-session-environment $is-remote)
   (CodexUnifiedExecOpenSessionEnvironment $is-remote))

(= (codex:unified-exec-open-session-environment-is-remote
      (CodexUnifiedExecOpenSessionEnvironment $is-remote))
   $is-remote)

(= (codex:unified-exec-spawn-lifecycle
      $inherited-fds
      $after-spawn-called)
   (CodexUnifiedExecSpawnLifecycle
     $inherited-fds
     $after-spawn-called))

(= (codex:unified-exec-spawn-lifecycle-inherited-fds
      (CodexUnifiedExecSpawnLifecycle
        $inherited-fds
        $after-spawn-called))
   $inherited-fds)

(= (codex:unified-exec-spawn-lifecycle-after-spawn-called
      (CodexUnifiedExecSpawnLifecycle
        $inherited-fds
        $after-spawn-called))
   $after-spawn-called)

(= (codex:unified-exec-spawn-lifecycle-after-spawn
      (CodexUnifiedExecSpawnLifecycle
        $inherited-fds
        $after-spawn-called))
   (CodexUnifiedExecSpawnLifecycle
     $inherited-fds
     True))

(= (codex:unified-exec-open-session-request
      $command
      $cwd
      $env
      $exec-server-env-config
      $arg0
      $sandbox
      $sandbox-policy
      $windows-sandbox-level
      $windows-sandbox-policy-cwd
      $windows-sandbox-private-desktop)
   (CodexUnifiedExecOpenSessionRequest
     $command
     $cwd
     $env
     $exec-server-env-config
     $arg0
     $sandbox
     $sandbox-policy
     $windows-sandbox-level
     $windows-sandbox-policy-cwd
     $windows-sandbox-private-desktop))

(= (codex:unified-exec-open-session-request-command
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $command)

(= (codex:unified-exec-open-session-request-cwd
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $cwd)

(= (codex:unified-exec-open-session-request-env
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $env)

(= (codex:unified-exec-open-session-request-env-config
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $exec-server-env-config)

(= (codex:unified-exec-open-session-request-arg0
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $arg0)

(= (codex:unified-exec-open-session-request-sandbox
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $sandbox)

(= (codex:unified-exec-open-session-request-sandbox-policy
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $sandbox-policy)

(= (codex:unified-exec-open-session-request-windows-sandbox-level
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $windows-sandbox-level)

(= (codex:unified-exec-open-session-request-windows-sandbox-policy-cwd
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $windows-sandbox-policy-cwd)

(= (codex:unified-exec-open-session-request-windows-sandbox-private-desktop
      (CodexUnifiedExecOpenSessionRequest
        $command
        $cwd
        $env
        $exec-server-env-config
        $arg0
        $sandbox
        $sandbox-policy
        $windows-sandbox-level
        $windows-sandbox-policy-cwd
        $windows-sandbox-private-desktop))
   $windows-sandbox-private-desktop)

(= (codex:unified-exec-open-session-request-exec-request
      $request)
   (codex:unified-exec-exec-request
     (codex:unified-exec-open-session-request-command $request)
     (codex:unified-exec-open-session-request-cwd $request)
     (codex:unified-exec-open-session-request-env $request)
     (codex:unified-exec-open-session-request-env-config $request)
     (codex:unified-exec-open-session-request-arg0 $request)))

(= (codex:unified-exec-runtime-result-ok $value)
   (CodexUnifiedExecRuntimeResultOk $value))

(= (codex:unified-exec-runtime-result-err $message)
   (CodexUnifiedExecRuntimeResultErr $message))

(= (codex:unified-exec-runtime-result-kind
      (CodexUnifiedExecRuntimeResultOk $value))
   ok)

(= (codex:unified-exec-runtime-result-kind
      (CodexUnifiedExecRuntimeResultErr $message))
   err)

(= (codex:unified-exec-runtime-result-value
      (CodexUnifiedExecRuntimeResultOk $value))
   $value)

(= (codex:unified-exec-runtime-result-error-message
      (CodexUnifiedExecRuntimeResultErr $message))
   $message)

(= (codex:unified-exec-open-session-runtime-inputs
      $remote-start-result
      $local-spawn-result
      $windows-policy-json-result
      $windows-codex-home-result
      $windows-spawn-result)
   (CodexUnifiedExecOpenSessionRuntimeInputs
     $remote-start-result
     $local-spawn-result
     $windows-policy-json-result
     $windows-codex-home-result
     $windows-spawn-result))

(= (codex:unified-exec-open-session-runtime-inputs-remote-start-result
      (CodexUnifiedExecOpenSessionRuntimeInputs
        $remote-start-result
        $local-spawn-result
        $windows-policy-json-result
        $windows-codex-home-result
        $windows-spawn-result))
   $remote-start-result)

(= (codex:unified-exec-open-session-runtime-inputs-local-spawn-result
      (CodexUnifiedExecOpenSessionRuntimeInputs
        $remote-start-result
        $local-spawn-result
        $windows-policy-json-result
        $windows-codex-home-result
        $windows-spawn-result))
   $local-spawn-result)

(= (codex:unified-exec-open-session-runtime-inputs-windows-policy-json-result
      (CodexUnifiedExecOpenSessionRuntimeInputs
        $remote-start-result
        $local-spawn-result
        $windows-policy-json-result
        $windows-codex-home-result
        $windows-spawn-result))
   $windows-policy-json-result)

(= (codex:unified-exec-open-session-runtime-inputs-windows-codex-home-result
      (CodexUnifiedExecOpenSessionRuntimeInputs
        $remote-start-result
        $local-spawn-result
        $windows-policy-json-result
        $windows-codex-home-result
        $windows-spawn-result))
   $windows-codex-home-result)

(= (codex:unified-exec-open-session-runtime-inputs-windows-spawn-result
      (CodexUnifiedExecOpenSessionRuntimeInputs
        $remote-start-result
        $local-spawn-result
        $windows-policy-json-result
        $windows-codex-home-result
        $windows-spawn-result))
   $windows-spawn-result)

(= (codex:unified-exec-open-session-remote-start-request
      $params
      $sandbox)
   (CodexUnifiedExecOpenSessionRemoteStartRequest
     $params
     $sandbox))

(= (codex:unified-exec-open-session-remote-start-request-params
      (CodexUnifiedExecOpenSessionRemoteStartRequest
        $params
        $sandbox))
   $params)

(= (codex:unified-exec-open-session-remote-start-request-sandbox
      (CodexUnifiedExecOpenSessionRemoteStartRequest
        $params
        $sandbox))
   $sandbox)

(= (codex:unified-exec-open-session-local-spawn-request
      $kind
      $program
      $args
      $cwd
      $env
      $arg0
      $inherited-fds
      $sandbox)
   (CodexUnifiedExecOpenSessionLocalSpawnRequest
     $kind
     $program
     $args
     $cwd
     $env
     $arg0
     $inherited-fds
     $sandbox))

(= (codex:unified-exec-open-session-local-spawn-request-kind
      (CodexUnifiedExecOpenSessionLocalSpawnRequest
        $kind
        $program
        $args
        $cwd
        $env
        $arg0
        $inherited-fds
        $sandbox))
   $kind)

(= (codex:unified-exec-open-session-local-spawn-request-program
      (CodexUnifiedExecOpenSessionLocalSpawnRequest
        $kind
        $program
        $args
        $cwd
        $env
        $arg0
        $inherited-fds
        $sandbox))
   $program)

(= (codex:unified-exec-open-session-local-spawn-request-args
      (CodexUnifiedExecOpenSessionLocalSpawnRequest
        $kind
        $program
        $args
        $cwd
        $env
        $arg0
        $inherited-fds
        $sandbox))
   $args)

(= (codex:unified-exec-open-session-local-spawn-request-cwd
      (CodexUnifiedExecOpenSessionLocalSpawnRequest
        $kind
        $program
        $args
        $cwd
        $env
        $arg0
        $inherited-fds
        $sandbox))
   $cwd)

(= (codex:unified-exec-open-session-local-spawn-request-env
      (CodexUnifiedExecOpenSessionLocalSpawnRequest
        $kind
        $program
        $args
        $cwd
        $env
        $arg0
        $inherited-fds
        $sandbox))
   $env)

(= (codex:unified-exec-open-session-local-spawn-request-arg0
      (CodexUnifiedExecOpenSessionLocalSpawnRequest
        $kind
        $program
        $args
        $cwd
        $env
        $arg0
        $inherited-fds
        $sandbox))
   $arg0)

(= (codex:unified-exec-open-session-local-spawn-request-inherited-fds
      (CodexUnifiedExecOpenSessionLocalSpawnRequest
        $kind
        $program
        $args
        $cwd
        $env
        $arg0
        $inherited-fds
        $sandbox))
   $inherited-fds)

(= (codex:unified-exec-open-session-local-spawn-request-sandbox
      (CodexUnifiedExecOpenSessionLocalSpawnRequest
        $kind
        $program
        $args
        $cwd
        $env
        $arg0
        $inherited-fds
        $sandbox))
   $sandbox)

(= (codex:unified-exec-open-session-windows-spawn-request
      $kind
      $policy-json
      $policy-cwd
      $codex-home
      $command
      $cwd
      $env
      $tty
      $windows-sandbox-private-desktop
      $sandbox)
   (CodexUnifiedExecOpenSessionWindowsSpawnRequest
     $kind
     $policy-json
     $policy-cwd
     $codex-home
     $command
     $cwd
     $env
     $tty
     $windows-sandbox-private-desktop
     $sandbox))

(= (codex:unified-exec-open-session-windows-spawn-request-kind
      (CodexUnifiedExecOpenSessionWindowsSpawnRequest
        $kind
        $policy-json
        $policy-cwd
        $codex-home
        $command
        $cwd
        $env
        $tty
        $windows-sandbox-private-desktop
        $sandbox))
   $kind)

(= (codex:unified-exec-open-session-windows-spawn-request-policy-json
      (CodexUnifiedExecOpenSessionWindowsSpawnRequest
        $kind
        $policy-json
        $policy-cwd
        $codex-home
        $command
        $cwd
        $env
        $tty
        $windows-sandbox-private-desktop
        $sandbox))
   $policy-json)

(= (codex:unified-exec-open-session-windows-spawn-request-codex-home
      (CodexUnifiedExecOpenSessionWindowsSpawnRequest
        $kind
        $policy-json
        $policy-cwd
        $codex-home
        $command
        $cwd
        $env
        $tty
        $windows-sandbox-private-desktop
        $sandbox))
   $codex-home)

(= (codex:unified-exec-open-session-process
      $source
      $sandbox
      $runtime-handle
      $spawn-request)
   (CodexUnifiedExecOpenSessionProcess
     $source
     $sandbox
     $runtime-handle
     $spawn-request))

(= (codex:unified-exec-open-session-process-source
      (CodexUnifiedExecOpenSessionProcess
        $source
        $sandbox
        $runtime-handle
        $spawn-request))
   $source)

(= (codex:unified-exec-open-session-process-sandbox
      (CodexUnifiedExecOpenSessionProcess
        $source
        $sandbox
        $runtime-handle
        $spawn-request))
   $sandbox)

(= (codex:unified-exec-open-session-process-runtime-handle
      (CodexUnifiedExecOpenSessionProcess
        $source
        $sandbox
        $runtime-handle
        $spawn-request))
   $runtime-handle)

(= (codex:unified-exec-open-session-process-spawn-request
      (CodexUnifiedExecOpenSessionProcess
        $source
        $sandbox
        $runtime-handle
        $spawn-request))
   $spawn-request)

(= (codex:unified-exec-open-session-result-ok
      $process
      $spawn-lifecycle
      $spawn-request)
   (CodexUnifiedExecOpenSessionResultOk
     $process
     $spawn-lifecycle
     $spawn-request))

(= (codex:unified-exec-open-session-result-err
      $error
      $spawn-lifecycle
      $spawn-request)
   (CodexUnifiedExecOpenSessionResultErr
     $error
     $spawn-lifecycle
     $spawn-request))

(= (codex:unified-exec-open-session-result-kind
      (CodexUnifiedExecOpenSessionResultOk
        $process
        $spawn-lifecycle
        $spawn-request))
   ok)

(= (codex:unified-exec-open-session-result-kind
      (CodexUnifiedExecOpenSessionResultErr
        $error
        $spawn-lifecycle
        $spawn-request))
   err)

(= (codex:unified-exec-open-session-result-process
      (CodexUnifiedExecOpenSessionResultOk
        $process
        $spawn-lifecycle
        $spawn-request))
   $process)

(= (codex:unified-exec-open-session-result-error
      (CodexUnifiedExecOpenSessionResultErr
        $error
        $spawn-lifecycle
        $spawn-request))
   $error)

(= (codex:unified-exec-open-session-result-spawn-lifecycle
      (CodexUnifiedExecOpenSessionResultOk
        $process
        $spawn-lifecycle
        $spawn-request))
   $spawn-lifecycle)

(= (codex:unified-exec-open-session-result-spawn-lifecycle
      (CodexUnifiedExecOpenSessionResultErr
        $error
        $spawn-lifecycle
        $spawn-request))
   $spawn-lifecycle)

(= (codex:unified-exec-open-session-result-spawn-request
      (CodexUnifiedExecOpenSessionResultOk
        $process
        $spawn-lifecycle
        $spawn-request))
   $spawn-request)

(= (codex:unified-exec-open-session-result-spawn-request
      (CodexUnifiedExecOpenSessionResultErr
        $error
        $spawn-lifecycle
        $spawn-request))
   $spawn-request)

(= (codex:unified-exec-open-session-runtime-err
      $message
      $spawn-lifecycle
      $spawn-request)
   (codex:unified-exec-open-session-result-err
     (codex:unified-exec-error-create-process $message)
     $spawn-lifecycle
     $spawn-request))

(= (codex:unified-exec-open-session-remote-inherited-fd-error)
   "remote exec-server does not support inherited file descriptors")

(= (codex:unified-exec-open-session-windows-policy-error-message $message)
   (format-args
     "failed to serialize Windows sandbox policy: {}"
     ($message)))

(= (codex:unified-exec-open-session-windows-codex-home-error-message $message)
   (format-args
     "windows sandbox: failed to resolve codex_home: {}"
     ($message)))

(= (codex:unified-exec-open-session-windows-kind $windows-sandbox-level)
   (if (== $windows-sandbox-level (codex:windows-sandbox-level-elevated))
       windows_elevated
       windows_legacy))

(= (codex:unified-exec-open-session-runtime-success
      $source
      $sandbox
      $runtime-result
      $spawn-lifecycle
      $spawn-request)
   (if (== (codex:unified-exec-runtime-result-kind $runtime-result) ok)
       (let $spawned-lifecycle
         (codex:unified-exec-spawn-lifecycle-after-spawn
           $spawn-lifecycle)
         (codex:unified-exec-open-session-result-ok
           (codex:unified-exec-open-session-process
             $source
             $sandbox
             (codex:unified-exec-runtime-result-value
               $runtime-result)
             $spawn-request)
           $spawned-lifecycle
           $spawn-request))
       (codex:unified-exec-open-session-runtime-err
         (codex:unified-exec-runtime-result-error-message
           $runtime-result)
         $spawn-lifecycle
         $spawn-request)))

(= (codex:unified-exec-open-session-with-exec-env
      $process-id
      $request
      $tty
      $spawn-lifecycle
      $environment
      $host-platform
      $runtime-inputs)
   (if (and
         (== $host-platform (codex:host-platform-windows))
         (== (codex:unified-exec-open-session-request-sandbox $request)
             (codex:sandbox-type-windows-restricted-token)))
       (codex:unified-exec-open-session-windows
         $request
         $tty
         $spawn-lifecycle
         $runtime-inputs)
       (if (codex:unified-exec-open-session-environment-is-remote
             $environment)
           (codex:unified-exec-open-session-remote
             $process-id
             $request
             $tty
             $spawn-lifecycle
             $runtime-inputs)
           (codex:unified-exec-open-session-local
             $request
             $tty
             $spawn-lifecycle
             $runtime-inputs))))

(= (codex:unified-exec-open-session-windows
      $request
      $tty
      $spawn-lifecycle
      $runtime-inputs)
   (let $policy-json-result
     (codex:unified-exec-open-session-runtime-inputs-windows-policy-json-result
       $runtime-inputs)
     (if (== (codex:unified-exec-runtime-result-kind $policy-json-result) ok)
         (codex:unified-exec-open-session-windows-with-policy-json
           $request
           $tty
           $spawn-lifecycle
           $runtime-inputs
           (codex:unified-exec-runtime-result-value
             $policy-json-result))
         (codex:unified-exec-open-session-result-err
           (codex:unified-exec-error-create-process
             (codex:unified-exec-open-session-windows-policy-error-message
               (codex:unified-exec-runtime-result-error-message
                 $policy-json-result)))
           $spawn-lifecycle
           CodexAbsent))))

(= (codex:unified-exec-open-session-windows-with-policy-json
      $request
      $tty
      $spawn-lifecycle
      $runtime-inputs
      $policy-json)
   (let $codex-home-result
     (codex:unified-exec-open-session-runtime-inputs-windows-codex-home-result
       $runtime-inputs)
     (if (== (codex:unified-exec-runtime-result-kind $codex-home-result) ok)
         (let $codex-home
           (codex:unified-exec-runtime-result-value $codex-home-result)
           (let $spawn-request
             (codex:unified-exec-open-session-windows-spawn-request
               (codex:unified-exec-open-session-windows-kind
                 (codex:unified-exec-open-session-request-windows-sandbox-level
                   $request))
               $policy-json
               (codex:unified-exec-open-session-request-windows-sandbox-policy-cwd
                 $request)
               $codex-home
               (codex:unified-exec-open-session-request-command $request)
               (codex:unified-exec-open-session-request-cwd $request)
               (codex:unified-exec-open-session-request-env $request)
               $tty
               (codex:unified-exec-open-session-request-windows-sandbox-private-desktop
                 $request)
               (codex:unified-exec-open-session-request-sandbox
                 $request))
             (codex:unified-exec-open-session-runtime-success
               (codex:unified-exec-open-session-windows-kind
                 (codex:unified-exec-open-session-request-windows-sandbox-level
                   $request))
               (codex:unified-exec-open-session-request-sandbox $request)
               (codex:unified-exec-open-session-runtime-inputs-windows-spawn-result
                 $runtime-inputs)
               $spawn-lifecycle
               $spawn-request)))
         (codex:unified-exec-open-session-result-err
           (codex:unified-exec-error-create-process
             (codex:unified-exec-open-session-windows-codex-home-error-message
               (codex:unified-exec-runtime-result-error-message
                 $codex-home-result)))
           $spawn-lifecycle
           CodexAbsent))))

(= (codex:unified-exec-open-session-remote
      $process-id
      $request
      $tty
      $spawn-lifecycle
      $runtime-inputs)
   (let $inherited-fds
     (codex:unified-exec-spawn-lifecycle-inherited-fds
       $spawn-lifecycle)
     (if (== $inherited-fds ())
         (let $spawn-request
           (codex:unified-exec-open-session-remote-start-request
             (codex:unified-exec-server-params-for-request
               $process-id
               (codex:unified-exec-open-session-request-exec-request
                 $request)
               $tty)
             (codex:unified-exec-open-session-request-sandbox $request))
           (codex:unified-exec-open-session-runtime-success
             exec_server
             (codex:unified-exec-open-session-request-sandbox
               $request)
             (codex:unified-exec-open-session-runtime-inputs-remote-start-result
               $runtime-inputs)
             $spawn-lifecycle
             $spawn-request))
         (codex:unified-exec-open-session-result-err
           (codex:unified-exec-error-create-process
             (codex:unified-exec-open-session-remote-inherited-fd-error))
           $spawn-lifecycle
           CodexAbsent))))

(= (codex:unified-exec-open-session-local
      $request
      $tty
      $spawn-lifecycle
      $runtime-inputs)
   (let $command
     (codex:unified-exec-open-session-request-command $request)
     (if (== $command ())
         (codex:unified-exec-open-session-result-err
           (codex:unified-exec-error-missing-command-line)
           $spawn-lifecycle
           CodexAbsent)
         (let $program (list:first $command)
           (let $args (list:rest $command)
             (let $kind (if $tty local_pty local_pipe)
               (let $spawn-request
                 (codex:unified-exec-open-session-local-spawn-request
                   $kind
                   $program
                   $args
                   (codex:unified-exec-open-session-request-cwd $request)
                   (codex:unified-exec-open-session-request-env $request)
                   (codex:unified-exec-open-session-request-arg0 $request)
                   (codex:unified-exec-spawn-lifecycle-inherited-fds
                     $spawn-lifecycle)
                   (codex:unified-exec-open-session-request-sandbox
                     $request))
                 (codex:unified-exec-open-session-runtime-success
                   $kind
                   (codex:unified-exec-open-session-request-sandbox
                     $request)
                   (codex:unified-exec-open-session-runtime-inputs-local-spawn-result
                     $runtime-inputs)
                   $spawn-lifecycle
                   $spawn-request))))))))
