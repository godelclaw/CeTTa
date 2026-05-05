(= (shell-plain-commands $command)
   (function
     (case (__cetta_lib_shell_plain_commands $command)
       (($result (return $result))))))
