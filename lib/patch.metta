(= (patch-inspect $cwd $patch)
   (function
     (case (__cetta_lib_patch_inspect $cwd $patch)
       (($result (return $result))))))

(= (patch-inspect-shell-command $cwd $command)
   (function
     (case (__cetta_lib_patch_inspect_shell_command $cwd $command)
       (($result (return $result))))))

(= (patch-apply $cwd $patch)
   (function
     (case (__cetta_lib_patch_apply $cwd $patch)
       (($result (return $result))))))

(= (patch-intercept-shell-command $cwd $command)
   (function
     (case (__cetta_lib_patch_intercept_shell_command $cwd $command)
       (($result (return $result))))))

(= (patch-inspect-ok? (PatchInspectResult $ok $error $action))
   $ok)

(= (patch-inspect-error (PatchInspectResult $ok $error $action))
   $error)

(= (patch-inspect-action (PatchInspectResult $ok $error $action))
   $action)

(= (patch-action-cwd (PatchAction $cwd $changes))
   $cwd)

(= (patch-action-changes (PatchAction $cwd $changes))
   $changes)

(= (patch-action-change-kind (PatchActionAdd $path $content))
   "add")

(= (patch-action-change-kind (PatchActionDelete $path $content))
   "delete")

(= (patch-action-change-kind
      (PatchActionUpdate $path $unified-diff $move-path $new-content))
   "update")

(= (patch-action-change-path (PatchActionAdd $path $content))
   $path)

(= (patch-action-change-path (PatchActionDelete $path $content))
   $path)

(= (patch-action-change-path
      (PatchActionUpdate $path $unified-diff $move-path $new-content))
   $path)

(= (patch-action-change-content (PatchActionAdd $path $content))
   $content)

(= (patch-action-change-content (PatchActionDelete $path $content))
   $content)

(= (patch-action-change-unified-diff
      (PatchActionUpdate $path $unified-diff $move-path $new-content))
   $unified-diff)

(= (patch-action-change-move-path
      (PatchActionUpdate $path $unified-diff $move-path $new-content))
   $move-path)

(= (patch-action-change-new-content
      (PatchActionUpdate $path $unified-diff $move-path $new-content))
   $new-content)

(= (patch-action-change-has-move-path
      (PatchActionUpdate $path $unified-diff $move-path $new-content))
   (if (== $move-path PatchNoMove)
       False
       True))

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

(= (patch-shell-inspect-matched?
      (PatchShellInspect $matched $effective-cwd $patch-text $result))
   $matched)

(= (patch-shell-inspect-effective-cwd
      (PatchShellInspect $matched $effective-cwd $patch-text $result))
   $effective-cwd)

(= (patch-shell-inspect-patch-text
      (PatchShellInspect $matched $effective-cwd $patch-text $result))
   $patch-text)

(= (patch-shell-inspect-result
      (PatchShellInspect $matched $effective-cwd $patch-text $result))
   $result)
