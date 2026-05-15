!(register-module! ../codex)
!(import! &self str)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)
!(import! &self codex:permissions_instructions)

(= (codex-pi-empty-config $approval-policy $request-permissions-tool-enabled)
   (codex:permissions-prompt-config
     $approval-policy
     (codex:permissions-approvals-reviewer-user)
     (codex:policy ())
     False
     $request-permissions-tool-enabled))

(= (codex-pi-allow-policy)
   (codex:policy
     ((codex:prefix-rule
        ((codex:pattern-token "git")
         (codex:pattern-token "pull"))
        (codex:decision-allow))
      (codex:prefix-rule
        ((codex:pattern-token "cargo")
         (codex:pattern-token "test"))
        (codex:decision-allow))
      (codex:prefix-rule
        ((codex:pattern-token "git"))
        (codex:decision-prompt)))))

(= (codex-pi-contains-text $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($offset True))))

!(assertEqualToResult
  (codex:permissions-sandbox-text
    (codex:permissions-sandbox-mode-workspace-write)
    (codex:permissions-network-access-restricted))
  ("Filesystem sandboxing defines which files can be read or written. `sandbox_mode` is `workspace-write`: The sandbox permits reading files, and editing files in `cwd` and `writable_roots`. Editing files in other directories requires approval. Network access is restricted."))

!(assertEqualToResult
  (codex:permissions-approval-text
    (codex:ask-for-approval-unless-trusted)
    (codex:permissions-approvals-reviewer-user)
    (codex:policy ())
    False
    True)
  (" Approvals are your mechanism to get user consent to run shell commands without the sandbox. `approval_policy` is `unless-trusted`: The harness will escalate most commands for user approval, apart from a limited allowlist of safe \"read\" commands.\n\n# request_permissions Tool\n\nThe built-in `request_permissions` tool is available in this session. Invoke it when you need to request additional `network` or `file_system` permissions before later shell-like commands need them. Request only the specific permissions required for the task."))

!(assertEqual
  (codex:permissions-approval-text
    (codex:ask-for-approval-on-request)
    (codex:permissions-approvals-reviewer-user)
    (codex-pi-allow-policy)
    False
    False)
  (str-concat
    (codex:permissions-approval-policy-on-request-rule-text)
    "\n\n## Approved command prefixes\nThe following prefix rules have already been approved: - [\"git\", \"pull\"]\n- [\"cargo\", \"test\"]"))

!(assertEqualToResult
  (codex:permissions-approval-text
    (codex:ask-for-approval-granular
      (codex:ask-for-approval-granular-config
        False
        True
        False
        True
        False))
    (codex:permissions-approvals-reviewer-user)
    (codex:policy ())
    True
    False)
  ("# Approval Requests\n\nApproval policy is `granular`. Categories set to `false` are automatically rejected instead of prompting the user.\n\nThese approval categories may still prompt the user when needed:\n- `rules`\n\nThese approval categories are automatically rejected instead of prompting the user:\n- `sandbox_approval`\n- `skill_approval`\n- `mcp_elicitations`"))

!(assertEqual
  (codex-pi-contains-text
    (codex:permissions-approval-text
      (codex:ask-for-approval-granular
        (codex:ask-for-approval-granular-config
          True
          True
          True
          True
          True))
      (codex:permissions-approvals-reviewer-user)
      (codex:policy ())
      True
      True)
    "# request_permissions Tool")
  True)

!(assertEqual
  (codex-pi-contains-text
    (codex:permissions-approval-text
      (codex:ask-for-approval-on-request)
      (codex:permissions-approvals-reviewer-auto-review)
      (codex:policy ())
      False
      False)
    "`approvals_reviewer` is `auto_review`")
  True)

!(assertEqual
  (codex-pi-contains-text
    (codex:permissions-approval-text
      (codex:ask-for-approval-never)
      (codex:permissions-approvals-reviewer-auto-review)
      (codex:policy ())
      False
      False)
    "`approvals_reviewer` is `auto_review`")
  False)

!(assertEqualToResult
  (codex:permissions-instructions-body
    (codex:permissions-instructions-from-policy
      (codex:permissions-sandbox-policy-workspace-write
        (codex:permissions-network-access-enabled)
        ("/repo" "/tmp/work"))
      (codex-pi-empty-config
        (codex:ask-for-approval-on-failure)
        False)))
  ("\nFilesystem sandboxing defines which files can be read or written. `sandbox_mode` is `workspace-write`: The sandbox permits reading files, and editing files in `cwd` and `writable_roots`. Editing files in other directories requires approval. Network access is enabled.\nApprovals are your mechanism to get user consent to run shell commands without the sandbox. `approval_policy` is `on-failure`: The harness will allow all commands to run in the sandbox (if enabled), and failures will be escalated to the user for approval to run again without the sandbox.\n The writable roots are `/repo`, `/tmp/work`.\n"))
