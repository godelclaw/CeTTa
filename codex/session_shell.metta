; Rust-faithful session shell helper slice.
;
; This ports the pure helper surface from:
; - openai-codex/codex-rs/core/src/shell.rs
;
; Covered in this increment:
; - ShellType discriminants and string names
; - Shell data shape accessors
; - Shell::derive_exec_args branch behavior
; - Shell::shell_snapshot accessor shape
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust stores shell paths as PathBuf and derives display strings with
;   `to_string_lossy()`. The CeTTa port represents paths as strings at this
;   boundary because the current path library uses string paths.
; - Rust stores a tokio watch receiver for `shell_snapshot`. This pure slice
;   represents the empty/default receiver as CodexAbsent; async receiver
;   lifecycle belongs to the later session runtime port.

(= (codex:shell-type-zsh)
   "Zsh")

(= (codex:shell-type-bash)
   "Bash")

(= (codex:shell-type-sh)
   "Sh")

(= (codex:shell-type-powershell)
   "PowerShell")

(= (codex:shell-type-cmd)
   "Cmd")

(= (codex:shell $shell-type $shell-path $shell-snapshot)
   (CodexShell $shell-type $shell-path $shell-snapshot))

(= (codex:shell-without-snapshot $shell-type $shell-path)
   (codex:shell
     $shell-type
     $shell-path
     (codex:empty-shell-snapshot-receiver)))

(= (codex:shell-shell-type
      (CodexShell $shell-type $shell-path $shell-snapshot))
   $shell-type)

(= (codex:shell-shell-path
      (CodexShell $shell-type $shell-path $shell-snapshot))
   $shell-path)

(= (codex:shell-shell-snapshot
      (CodexShell $shell-type $shell-path $shell-snapshot))
   $shell-snapshot)

(= (codex:empty-shell-snapshot-receiver)
   CodexAbsent)

(= (codex:normalize-shell-type "zsh")
   (codex:shell-type-zsh))

(= (codex:normalize-shell-type "Zsh")
   (codex:shell-type-zsh))

(= (codex:normalize-shell-type "bash")
   (codex:shell-type-bash))

(= (codex:normalize-shell-type "Bash")
   (codex:shell-type-bash))

(= (codex:normalize-shell-type "sh")
   (codex:shell-type-sh))

(= (codex:normalize-shell-type "Sh")
   (codex:shell-type-sh))

(= (codex:normalize-shell-type "powershell")
   (codex:shell-type-powershell))

(= (codex:normalize-shell-type "pwsh")
   (codex:shell-type-powershell))

(= (codex:normalize-shell-type "PowerShell")
   (codex:shell-type-powershell))

(= (codex:normalize-shell-type "cmd")
   (codex:shell-type-cmd))

(= (codex:normalize-shell-type "Cmd")
   (codex:shell-type-cmd))

(= (codex:shell-type-name "Zsh")
   "zsh")

(= (codex:shell-type-name "Bash")
   "bash")

(= (codex:shell-type-name "Sh")
   "sh")

(= (codex:shell-type-name "PowerShell")
   "powershell")

(= (codex:shell-type-name "Cmd")
   "cmd")

(= (codex:shell-name
      (CodexShell $shell-type $shell-path $shell-snapshot))
   (codex:shell-type-name $shell-type))

(= (codex:shell-unix-exec-arg $use-login-shell)
   (if $use-login-shell
       "-lc"
       "-c"))

(= (codex:is-unix-session-shell-type $shell-type)
   (if (== $shell-type (codex:shell-type-zsh))
       True
       (if (== $shell-type (codex:shell-type-bash))
           True
           (if (== $shell-type (codex:shell-type-sh))
               True
               False))))

(= (codex:shell-derive-exec-args
      (CodexShell $shell-type $shell-path $shell-snapshot)
      $command
      $use-login-shell)
   (if (codex:is-unix-session-shell-type $shell-type)
       ($shell-path
        (codex:shell-unix-exec-arg $use-login-shell)
        $command)
       (if (== $shell-type (codex:shell-type-powershell))
           (if $use-login-shell
               ($shell-path "-Command" $command)
               ($shell-path "-NoProfile" "-Command" $command))
           (if (== $shell-type (codex:shell-type-cmd))
               ($shell-path "/c" $command)
               CodexAbsent))))
