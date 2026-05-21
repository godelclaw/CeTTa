; Rust-faithful exec-server runtime paths slice.
;
; This ports deterministic construction behavior from:
; - openai-codex/codex-rs/exec-server/src/runtime_paths.rs
;   - ExecServerRuntimePaths
;   - ExecServerRuntimePaths::from_optional_paths
;   - ExecServerRuntimePaths::new
;   - absolute_path
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust returns `std::io::Result<Self>` with `InvalidInput` errors. This
;   CeTTa slice represents the same success/error boundary through explicit
;   `CodexExecServerRuntimePathsOk` and `CodexExecServerRuntimePathsErr`
;   constructors carrying the visible error message.
; - Rust validates through `AbsolutePathBuf::from_absolute_path`, preserving the
;   supplied absolute path without lexical normalization. This slice uses the
;   current path absolute predicate and likewise returns the original string for
;   accepted absolute inputs.

!(import! &self path)

(= (codex:exec-server-runtime-paths $codex-self-exe $codex-linux-sandbox-exe)
   (CodexExecServerRuntimePaths
     $codex-self-exe
     $codex-linux-sandbox-exe))

(= (codex:exec-server-runtime-paths-codex-self-exe
      (CodexExecServerRuntimePaths
        $codex-self-exe
        $codex-linux-sandbox-exe))
   $codex-self-exe)

(= (codex:exec-server-runtime-paths-codex-linux-sandbox-exe
      (CodexExecServerRuntimePaths
        $codex-self-exe
        $codex-linux-sandbox-exe))
   $codex-linux-sandbox-exe)

(= (codex:exec-server-runtime-paths-ok $paths)
   (CodexExecServerRuntimePathsOk $paths))

(= (codex:exec-server-runtime-paths-err $message)
   (CodexExecServerRuntimePathsErr $message))

(= (codex:exec-server-runtime-paths-result-paths
      (CodexExecServerRuntimePathsOk $paths))
   $paths)

(= (codex:exec-server-runtime-paths-result-message
      (CodexExecServerRuntimePathsErr $message))
   $message)

(= (codex:exec-server-runtime-paths-missing-codex-exe-message)
   "Codex executable path is not configured")

(= (codex:exec-server-runtime-paths-relative-path-message $path)
   (format-args "path is not absolute: {}" ($path)))

(= (codex:exec-server-runtime-paths-absolute-path $path)
   (if (path-is-absolute? $path)
       (CodexExecServerRuntimePathsOk $path)
       (CodexExecServerRuntimePathsErr
         (codex:exec-server-runtime-paths-relative-path-message $path))))

(= (codex:exec-server-runtime-paths-optional-absolute-path $path)
   (if (== $path CodexAbsent)
       (CodexExecServerRuntimePathsOk CodexAbsent)
       (codex:exec-server-runtime-paths-absolute-path $path)))

(= (codex:exec-server-runtime-paths-new
      $codex-self-exe
      $codex-linux-sandbox-exe)
   (case (codex:exec-server-runtime-paths-absolute-path $codex-self-exe)
     (((CodexExecServerRuntimePathsErr $message)
       (CodexExecServerRuntimePathsErr $message))
      ((CodexExecServerRuntimePathsOk $absolute-codex-self-exe)
       (case (codex:exec-server-runtime-paths-optional-absolute-path
               $codex-linux-sandbox-exe)
         (((CodexExecServerRuntimePathsErr $message)
           (CodexExecServerRuntimePathsErr $message))
          ((CodexExecServerRuntimePathsOk $absolute-linux-sandbox-exe)
           (CodexExecServerRuntimePathsOk
             (CodexExecServerRuntimePaths
               $absolute-codex-self-exe
               $absolute-linux-sandbox-exe)))))))))

(= (codex:exec-server-runtime-paths-from-optional-paths
      $codex-self-exe
      $codex-linux-sandbox-exe)
   (if (== $codex-self-exe CodexAbsent)
       (CodexExecServerRuntimePathsErr
         (codex:exec-server-runtime-paths-missing-codex-exe-message))
       (codex:exec-server-runtime-paths-new
         $codex-self-exe
         $codex-linux-sandbox-exe)))
