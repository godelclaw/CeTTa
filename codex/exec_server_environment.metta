; Rust-faithful exec-server environment manager slice.
;
; This ports deterministic selection behavior from:
; - openai-codex/codex-rs/exec-server/src/environment.rs
;   - CODEX_EXEC_SERVER_URL_ENV_VAR
;   - LOCAL_ENVIRONMENT_ID / REMOTE_ENVIRONMENT_ID
;   - EnvironmentManagerArgs::new
;   - normalize_exec_server_url
;   - Environment::default_for_tests / create / create_for_tests / create_inner
;   - Environment::local / remote / remote_inner
;   - Environment::{is_remote, exec_server_url, local_runtime_paths}
;   - EnvironmentManager::default_for_tests / new
;   - EnvironmentManager::{default_environment, default_environment_id,
;     local_environment, get_environment}
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores `Arc<Environment>` values in a `HashMap` and concrete backend
;   trait objects for process, filesystem, and HTTP clients. This pure CeTTa
;   slice uses deterministic entry lists and a small source tag while preserving
;   Rust-visible environment selection, URL, and runtime-path behavior.
; - Rust `Environment::create*` returns `Result<Self, ExecServerError>`. This
;   slice exposes that boundary as explicit
;   `CodexExecServerEnvironmentCreateOk/Err` constructors carrying the visible
;   protocol error message.
; - Rust `EnvironmentManagerArgs::from_env` reads process environment. This
;   pure slice receives the already-read optional URL explicitly; the runtime
;   environment reader can feed the same constructor later.

!(import! &self list)
!(import! &self str)
!(import! &self exec_server_runtime_paths)

(= (codex:exec-server-url-env-var)
   "CODEX_EXEC_SERVER_URL")

(= (codex:exec-server-local-environment-id)
   "local")

(= (codex:exec-server-remote-environment-id)
   "remote")

(= (codex:exec-server-environment-source-local)
   (CodexExecServerEnvironmentSourceLocal))

(= (codex:exec-server-environment-source-remote)
   (CodexExecServerEnvironmentSourceRemote))

(= (codex:exec-server-environment-manager-args
      $exec-server-url
      $local-runtime-paths)
   (CodexExecServerEnvironmentManagerArgs
     $exec-server-url
     $local-runtime-paths))

(= (codex:exec-server-environment-manager-args-new $local-runtime-paths)
   (CodexExecServerEnvironmentManagerArgs CodexAbsent $local-runtime-paths))

(= (codex:exec-server-environment-manager-args-from-url
      $exec-server-url
      $local-runtime-paths)
   (CodexExecServerEnvironmentManagerArgs
     $exec-server-url
     $local-runtime-paths))

(= (codex:exec-server-environment-manager-args-exec-server-url
      (CodexExecServerEnvironmentManagerArgs
        $exec-server-url
        $local-runtime-paths))
   $exec-server-url)

(= (codex:exec-server-environment-manager-args-local-runtime-paths
      (CodexExecServerEnvironmentManagerArgs
        $exec-server-url
        $local-runtime-paths))
   $local-runtime-paths)

(= (codex:exec-server-environment-ascii-lower-char $char)
   (case $char
     (("A" "a")
      ("B" "b")
      ("C" "c")
      ("D" "d")
      ("E" "e")
      ("F" "f")
      ("G" "g")
      ("H" "h")
      ("I" "i")
      ("J" "j")
      ("K" "k")
      ("L" "l")
      ("M" "m")
      ("N" "n")
      ("O" "o")
      ("P" "p")
      ("Q" "q")
      ("R" "r")
      ("S" "s")
      ("T" "t")
      ("U" "u")
      ("V" "v")
      ("W" "w")
      ("X" "x")
      ("Y" "y")
      ("Z" "z")
      ($other $other))))

(= (codex:exec-server-environment-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:exec-server-environment-ascii-lower-char
           (str-slice $text 0 1))
         (codex:exec-server-environment-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:exec-server-environment-eq-ignore-ascii-case $left $right)
   (== (codex:exec-server-environment-ascii-lower-text $left)
       (codex:exec-server-environment-ascii-lower-text $right)))

(= (codex:exec-server-normalized-url $url $disabled)
   (CodexExecServerNormalizedUrl $url $disabled))

(= (codex:exec-server-normalized-url-value
      (CodexExecServerNormalizedUrl $url $disabled))
   $url)

(= (codex:exec-server-normalized-url-disabled
      (CodexExecServerNormalizedUrl $url $disabled))
   $disabled)

(= (codex:exec-server-normalize-exec-server-url $exec-server-url)
   (if (== $exec-server-url CodexAbsent)
       (CodexExecServerNormalizedUrl CodexAbsent False)
       (let $trimmed (str-trim $exec-server-url)
         (if (== $trimmed "")
             (CodexExecServerNormalizedUrl CodexAbsent False)
             (if (codex:exec-server-environment-eq-ignore-ascii-case
                   $trimmed
                   "none")
                 (CodexExecServerNormalizedUrl CodexAbsent True)
                 (CodexExecServerNormalizedUrl $trimmed False))))))

(= (codex:exec-server-environment
      $source
      $exec-server-url
      $local-runtime-paths)
   (CodexExecServerEnvironment
     $source
     $exec-server-url
     $local-runtime-paths))

(= (codex:exec-server-environment-source
      (CodexExecServerEnvironment
        $source
        $exec-server-url
        $local-runtime-paths))
   $source)

(= (codex:exec-server-environment-exec-server-url
      (CodexExecServerEnvironment
        $source
        $exec-server-url
        $local-runtime-paths))
   $exec-server-url)

(= (codex:exec-server-environment-local-runtime-paths
      (CodexExecServerEnvironment
        $source
        $exec-server-url
        $local-runtime-paths))
   $local-runtime-paths)

(= (codex:exec-server-environment-is-remote $environment)
   (not
     (== (codex:exec-server-environment-exec-server-url $environment)
         CodexAbsent)))

(= (codex:exec-server-environment-default-for-tests)
   (CodexExecServerEnvironment
     (CodexExecServerEnvironmentSourceLocal)
     CodexAbsent
     CodexAbsent))

(= (codex:exec-server-environment-local $local-runtime-paths)
   (CodexExecServerEnvironment
     (CodexExecServerEnvironmentSourceLocal)
     CodexAbsent
     $local-runtime-paths))

(= (codex:exec-server-environment-remote-inner
      $exec-server-url
      $local-runtime-paths)
   (CodexExecServerEnvironment
     (CodexExecServerEnvironmentSourceRemote)
     $exec-server-url
     $local-runtime-paths))

(= (codex:exec-server-environment-remote
      $exec-server-url
      $local-runtime-paths)
   (codex:exec-server-environment-remote-inner
     $exec-server-url
     $local-runtime-paths))

(= (codex:exec-server-environment-create-ok $environment)
   (CodexExecServerEnvironmentCreateOk $environment))

(= (codex:exec-server-environment-create-err $message)
   (CodexExecServerEnvironmentCreateErr $message))

(= (codex:exec-server-environment-create-result-environment
      (CodexExecServerEnvironmentCreateOk $environment))
   $environment)

(= (codex:exec-server-environment-create-result-message
      (CodexExecServerEnvironmentCreateErr $message))
   $message)

(= (codex:exec-server-environment-disabled-create-message)
   "disabled mode does not create an Environment")

(= (codex:exec-server-environment-create-inner
      $exec-server-url
      $local-runtime-paths)
   (let $normalized
     (codex:exec-server-normalize-exec-server-url $exec-server-url)
     (if (codex:exec-server-normalized-url-disabled $normalized)
         (CodexExecServerEnvironmentCreateErr
           (codex:exec-server-environment-disabled-create-message))
         (let $normalized-url
           (codex:exec-server-normalized-url-value $normalized)
           (if (== $normalized-url CodexAbsent)
               (if (== $local-runtime-paths CodexAbsent)
                   (CodexExecServerEnvironmentCreateOk
                     (codex:exec-server-environment-default-for-tests))
                   (CodexExecServerEnvironmentCreateOk
                     (codex:exec-server-environment-local
                       $local-runtime-paths)))
               (CodexExecServerEnvironmentCreateOk
                 (codex:exec-server-environment-remote-inner
                   $normalized-url
                   $local-runtime-paths)))))))

(= (codex:exec-server-environment-create
      $exec-server-url
      $local-runtime-paths)
   (codex:exec-server-environment-create-inner
     $exec-server-url
     $local-runtime-paths))

(= (codex:exec-server-environment-create-for-tests $exec-server-url)
   (codex:exec-server-environment-create-inner
     $exec-server-url
     CodexAbsent))

(= (codex:exec-server-environment-manager-entry
      $environment-id
      $environment)
   (CodexExecServerEnvironmentManagerEntry
     $environment-id
     $environment))

(= (codex:exec-server-environment-manager-entry-id
      (CodexExecServerEnvironmentManagerEntry
        $environment-id
        $environment))
   $environment-id)

(= (codex:exec-server-environment-manager-entry-environment
      (CodexExecServerEnvironmentManagerEntry
        $environment-id
        $environment))
   $environment)

(= (codex:exec-server-environment-manager
      $default-environment-id
      $environments)
   (CodexExecServerEnvironmentManager
     $default-environment-id
     $environments))

(= (codex:exec-server-environment-manager-default-environment-id
      (CodexExecServerEnvironmentManager
        $default-environment-id
        $environments))
   $default-environment-id)

(= (codex:exec-server-environment-manager-environments
      (CodexExecServerEnvironmentManager
        $default-environment-id
        $environments))
   $environments)

(= (codex:exec-server-environment-manager-default-for-tests)
   (CodexExecServerEnvironmentManager
     (codex:exec-server-local-environment-id)
     ((CodexExecServerEnvironmentManagerEntry
        (codex:exec-server-local-environment-id)
        (codex:exec-server-environment-default-for-tests)))))

(= (codex:exec-server-environment-manager-new
      (CodexExecServerEnvironmentManagerArgs
        $exec-server-url
        $local-runtime-paths))
   (let $normalized
     (codex:exec-server-normalize-exec-server-url $exec-server-url)
     (let $local-entry
       (CodexExecServerEnvironmentManagerEntry
         (codex:exec-server-local-environment-id)
         (codex:exec-server-environment-local $local-runtime-paths))
       (if (codex:exec-server-normalized-url-disabled $normalized)
           (CodexExecServerEnvironmentManager
             CodexAbsent
             ($local-entry))
           (let $normalized-url
             (codex:exec-server-normalized-url-value $normalized)
             (if (== $normalized-url CodexAbsent)
                 (CodexExecServerEnvironmentManager
                   (codex:exec-server-local-environment-id)
                   ($local-entry))
                 (CodexExecServerEnvironmentManager
                   (codex:exec-server-remote-environment-id)
                   ($local-entry
                    (CodexExecServerEnvironmentManagerEntry
                      (codex:exec-server-remote-environment-id)
                      (codex:exec-server-environment-remote
                        $normalized-url
                        $local-runtime-paths))))))))))

(= (codex:exec-server-environment-manager-get-from-entries
      ()
      $environment-id)
   CodexAbsent)

(= (codex:exec-server-environment-manager-get-from-entries
      $environments
      $environment-id)
   (let $head (list:first $environments)
     (let $tail (list:rest $environments)
       (if (== (codex:exec-server-environment-manager-entry-id $head)
               $environment-id)
           (codex:exec-server-environment-manager-entry-environment $head)
           (codex:exec-server-environment-manager-get-from-entries
             $tail
             $environment-id)))))

(= (codex:exec-server-environment-manager-get-environment
      (CodexExecServerEnvironmentManager $default-environment-id $environments)
      $environment-id)
   (codex:exec-server-environment-manager-get-from-entries
     $environments
     $environment-id))

(= (codex:exec-server-environment-manager-default-environment $manager)
   (let $environment-id
     (codex:exec-server-environment-manager-default-environment-id $manager)
     (if (== $environment-id CodexAbsent)
         CodexAbsent
         (codex:exec-server-environment-manager-get-environment
           $manager
           $environment-id))))

(= (codex:exec-server-environment-manager-local-environment $manager)
   (codex:exec-server-environment-manager-get-environment
     $manager
     (codex:exec-server-local-environment-id)))
