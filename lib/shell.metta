(= (shell-plain-commands $command)
   (function
     (case (__cetta_lib_shell_plain_commands $command)
       (($result (return $result))))))

; Rust uses tree-sitter-bash for `parse_shell_lc_single_command_prefix`.
; CeTTa's native helper is intentionally conservative: it only returns an argv
; prefix for a single literal heredoc command and rejects ambiguous shell forms.
(= (shell-single-command-prefix $shell $flag $script)
   (function
     (case (__cetta_lib_shell_single_command_prefix $shell $flag $script)
       (($result (return $result))))))

(= (shell-shlex-join $words)
   (function
     (case (__cetta_lib_shell_shlex_join $words)
       (($result (return $result))))))
