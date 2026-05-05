(= (patch-apply $cwd $patch)
   (function
     (case (__cetta_lib_patch_apply $cwd $patch)
       (($result (return $result))))))

(= (patch-intercept-shell-command $cwd $command)
   (function
     (case (__cetta_lib_patch_intercept_shell_command $cwd $command)
       (($result (return $result))))))

(= (patch-result-ok? (PatchResult $ok $stdout $stderr $changes))
   $ok)

(= (patch-result-stdout (PatchResult $ok $stdout $stderr $changes))
   $stdout)

(= (patch-result-stderr (PatchResult $ok $stdout $stderr $changes))
   $stderr)

(= (patch-result-changes (PatchResult $ok $stdout $stderr $changes))
   $changes)

(= (patch-shell-intercept-matched? (PatchShellIntercept $matched $result))
   $matched)

(= (patch-shell-intercept-result (PatchShellIntercept $matched $result))
   $result)
