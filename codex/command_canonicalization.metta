; Narrow Rust-faithful command-canonicalization slice.
;
; This ports:
; - openai-codex/codex-rs/core/src/command_canonicalization.rs
;
; Covered in this increment:
; - word-only `bash|sh|zsh -c|-lc` canonicalization to inner argv
; - fallback bash/zsh/sh script canonicalization to a stable script key
; - fallback powershell canonicalization to a stable script key
; - non-shell command passthrough
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust uses `Vec<String>` / `Option`. The current CeTTa port preserves the
;   same visible argv results and uses `CodexAbsent` for omitted branches.
; - Rust calls `parse_shell_lc_plain_commands(command)` directly on argv. The
;   current CeTTa runtime only exposes the native shell plain-command parser
;   through a reconstructed wrapper string, so scripts with complex quoting may
;   fall through to the stable script-key path earlier than Rust.

!(import! &self command)
!(import! &self list)
!(import! &self shell)
!(import! &self shell_detect)
!(import! &self str)

(= (codex:canonical-bash-script-prefix)
   "__codex_shell_script__")

(= (codex:canonical-powershell-script-prefix)
   "__codex_powershell_script__")

(= (codex:command-canonicalization-ascii-lower-char $char)
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

(= (codex:command-canonicalization-ascii-lower-text $text)
   (if (== $text "")
       ""
       (str-concat
         (codex:command-canonicalization-ascii-lower-char
           (str-slice $text 0 1))
         (codex:command-canonicalization-ascii-lower-text
           (str-slice $text 1 (str-length $text))))))

(= (codex:is-command-canonicalization-bash-shell? $shell)
   (let $shell-type (codex:detect-shell-type $shell)
     (if (== $shell-type (codex:shell-type-zsh))
         True
         (if (== $shell-type (codex:shell-type-bash))
             True
             (if (== $shell-type (codex:shell-type-sh))
                 True
                 False)))))

(= (codex:is-powershell-shell-name? $shell)
   (== (codex:detect-shell-type $shell)
       (codex:shell-type-powershell)))

(= (codex:is-powershell-flag? $flag)
   (let $lower (codex:command-canonicalization-ascii-lower-text $flag)
     (if (== $lower "-nologo")
         True
         (if (== $lower "-noprofile")
             True
             (if (== $lower "-command")
                 True
                 (if (== $lower "-c")
                     True
                     False))))))

(= (codex:is-powershell-command-flag? $flag)
   (let $lower (codex:command-canonicalization-ascii-lower-text $flag)
     (if (== $lower "-command")
         True
         (if (== $lower "-c")
             True
             False))))

(= (codex:is-command-canonicalization-shell-wrapper? $shell $flag)
   (if (== $flag "-c")
       (codex:is-command-canonicalization-bash-shell? $shell)
       (if (== $flag "-lc")
           (codex:is-command-canonicalization-bash-shell? $shell)
           False)))

(= (codex:command-canonicalization-extract-bash $command)
   (if (== (list:len $command) 3)
       (let $shell (list:at $command 0)
         (let $flag (list:at $command 1)
           (let $script (list:at $command 2)
             (if (codex:is-command-canonicalization-shell-wrapper?
                   $shell
                   $flag)
                 (CodexCommandCanonicalizationBash $flag $script)
                 CodexAbsent))))
       CodexAbsent))

(= (codex:command-canonicalization-plain-shell-single-command $command)
   (case (codex:command-canonicalization-extract-bash $command)
     ((CodexAbsent CodexAbsent)
      ((CodexCommandCanonicalizationBash $flag $script)
       (case (shell-plain-commands
               (codex:rebuild-shell-wrapper "bash" $flag $script))
         ((Empty CodexAbsent)
          ($commands
           (if (== (list:len $commands) 1)
               (list:first $commands)
               CodexAbsent))))))))

(= (codex:command-canonicalization-extract-powershell-rest ())
   CodexAbsent)

(= (codex:command-canonicalization-extract-powershell-rest $tail)
   (if (< (list:len $tail) 2)
       CodexAbsent
       (let $flag (list:first $tail)
         (if (not (codex:is-powershell-flag? $flag))
             CodexAbsent
             (if (codex:is-powershell-command-flag? $flag)
                 (CodexCommandCanonicalizationPowerShell (list:at $tail 1))
                 (codex:command-canonicalization-extract-powershell-rest
                   (list:rest $tail)))))))

(= (codex:command-canonicalization-extract-powershell $command)
   (if (< (list:len $command) 3)
       CodexAbsent
       (let $shell (list:first $command)
         (if (codex:is-powershell-shell-name? $shell)
             (codex:command-canonicalization-extract-powershell-rest
               (list:rest $command))
             CodexAbsent))))

(= (codex:canonicalize-command-for-approval $command)
   (case (codex:command-canonicalization-plain-shell-single-command $command)
     ((CodexAbsent
       (case (codex:command-canonicalization-extract-bash $command)
         ((CodexAbsent
           (case (codex:command-canonicalization-extract-powershell $command)
             ((CodexAbsent $command)
              ((CodexCommandCanonicalizationPowerShell $script)
               ((codex:canonical-powershell-script-prefix) $script)))))
          ((CodexCommandCanonicalizationBash $flag $script)
           ((codex:canonical-bash-script-prefix) $flag $script)))))
      ($single-command
       $single-command))))
