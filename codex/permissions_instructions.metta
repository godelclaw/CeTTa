; Visible Rust-faithful permissions-instructions slice for the restarted Codex
; port.
;
; This ports the prompt assembly logic from:
; - openai-codex/codex-rs/core/src/context/permissions_instructions.rs
; - openai-codex/codex-rs/core/src/context/prompts/permissions/*
;
; Covered in this increment:
; - exact sandbox-mode and approval-policy prompt text
; - request_permissions-tool prompt section and auto-review suffix handling
; - granular approval category rendering
; - approved-prefix rendering and truncation
; - prompt-visible `from_permissions_with_network` assembly
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust's public `from_policy()` reads the full SandboxPolicy runtime object
;   and derives writable roots from cwd. The current CeTTa slice ports the
;   prompt-visible behavior through a simplified sandbox-policy projection that
;   already carries network access and writable roots.
; - The restarted exec-policy slice reconstructs allowed prefixes from the
;   currently visible prefix-rule representation and does not include the
;   broader Rust policy/runtime surfaces (network rules, host executables).

!(import! &self approval)
!(import! &self exec_policy)
!(import! &self json)
!(import! &self list)
!(import! &self str)

(= (codex:permissions-approvals-reviewer-user)
   "user")

(= (codex:permissions-approvals-reviewer-auto-review)
   "auto_review")

(= (codex:permissions-approvals-reviewer-guardian-subagent)
   "guardian_subagent")

(= (codex:permissions-network-access-enabled)
   "enabled")

(= (codex:permissions-network-access-restricted)
   "restricted")

(= (codex:permissions-sandbox-mode-danger-full-access)
   "danger-full-access")

(= (codex:permissions-sandbox-mode-workspace-write)
   "workspace-write")

(= (codex:permissions-sandbox-mode-read-only)
   "read-only")

(= (codex:permissions-approval-policy-never-text)
   "Approval policy is currently never. Do not provide the `sandbox_permissions` for any reason, commands will be rejected.")

(= (codex:permissions-approval-policy-unless-trusted-text)
   " Approvals are your mechanism to get user consent to run shell commands without the sandbox. `approval_policy` is `unless-trusted`: The harness will escalate most commands for user approval, apart from a limited allowlist of safe \"read\" commands.")

(= (codex:permissions-approval-policy-on-failure-text)
   "Approvals are your mechanism to get user consent to run shell commands without the sandbox. `approval_policy` is `on-failure`: The harness will allow all commands to run in the sandbox (if enabled), and failures will be escalated to the user for approval to run again without the sandbox.")

(= (codex:permissions-approval-policy-on-request-rule-text)
   "# Escalation Requests

Commands are run outside the sandbox if they are approved by the user, or match an existing rule that allows it to run unrestricted. The command string is split into independent command segments at shell control operators, including but not limited to:

- Pipes: |
- Logical operators: &&, ||
- Command separators: ;
- Subshell boundaries: (...), $(...)

Each resulting segment is evaluated independently for sandbox restrictions and approval requirements.

Example:

git pull | tee output.txt

This is treated as two command segments:

[\"git\", \"pull\"]

[\"tee\", \"output.txt\"]

Commands that use more advanced shell features like redirection (>, >>, <), substitutions ($(...), ...), environment variables (FOO=bar), or wildcard patterns (*, ?) will not be evaluated against rules, to limit the scope of what an approved rule allows.

## How to request escalation

IMPORTANT: To request approval to execute a command that will require escalated privileges:

- Provide the `sandbox_permissions` parameter with the value \"require_escalated\"
- Include a short question asking the user if they want to allow the action in `justification` parameter. e.g. \"Do you want to download and install dependencies for this project?\"
- Optionally suggest a `prefix_rule` - this will be shown to the user with an option to persist the rule approval for future sessions.

If you run a command that is important to solving the user's query, but it fails because of sandboxing or with a likely sandbox-related network error (for example DNS/host resolution, registry/index access, or dependency download failure), rerun the command with \"require_escalated\". ALWAYS proceed to use the `justification` parameter - do not message the user before requesting approval for the command.

## When to request escalation

While commands are running inside the sandbox, here are some scenarios that will require escalation outside the sandbox:

- You need to run a command that writes to a directory that requires it (e.g. running tests that write to /var)
- You need to run a GUI app (e.g., open/xdg-open/osascript) to open browsers or files.
- If you run a command that is important to solving the user's query, but it fails because of sandboxing or with a likely sandbox-related network error (for example DNS/host resolution, registry/index access, or dependency download failure), rerun the command with `require_escalated`. ALWAYS proceed to use the `sandbox_permissions` and `justification` parameters. do not message the user before requesting approval for the command.
- You are about to take a potentially destructive action such as an `rm` or `git reset` that the user did not explicitly ask for.
- Be judicious with escalating, but if completing the user's request requires it, you should do so - don't try and circumvent approvals by using other tools.

## prefix_rule guidance

When choosing a `prefix_rule`, request one that will allow you to fulfill similar requests from the user in the future without re-requesting escalation. It should be categorical and reasonably scoped to similar capabilities. You should rarely pass the entire command into `prefix_rule`.

### Banned prefix_rules 
Avoid requesting overly broad prefixes that the user would be ill-advised to approve. For example, do not request [\"python3\"], [\"python\", \"-\"], or other similar prefixes that would allow arbitrary scripting.
NEVER provide a prefix_rule argument for destructive commands like rm.
NEVER provide a prefix_rule if your command uses a heredoc or herestring. 

### Examples
Good examples of prefixes:
- [\"npm\", \"run\", \"dev\"]
- [\"gh\", \"pr\", \"check\"]
- [\"cargo\", \"test\"]")

(= (codex:permissions-approval-policy-on-request-rule-request-permission-text)
   "# Permission Requests

Commands may require user approval before execution. Prefer requesting sandboxed additional permissions instead of asking to run fully outside the sandbox.

## Preferred request mode

When you need extra sandboxed permissions for one command, use:

- `sandbox_permissions: \"with_additional_permissions\"`
- `additional_permissions` with one or more of:
  - `network.enabled`: set to `true` to enable network access
  - `file_system.read`: list of paths that need read access
  - `file_system.write`: list of paths that need write access

When using the `request_permissions` tool directly, only request `network` and `file_system` permissions.

This keeps execution inside the current sandbox policy, while adding only the requested permissions for that command, unless an exec-policy allow rule applies and authorizes running the command outside the sandbox.

If the command already matches an exec-policy allow rule, the command can be auto-approved without an extra prompt. In that case, exec-policy allow behavior (including any sandbox bypass) takes precedence.

## Escalation Requests

Use full escalation only when sandboxed additional permissions cannot satisfy the task.

- `sandbox_permissions: \"require_escalated\"`
- Include `justification` as a short question asking for approval.
- Optionally include `prefix_rule` to suggest a reusable allow rule.

## Command segmentation reminder

The command string is split into independent command segments at shell control operators, including pipes (`|`), logical operators (`&&`, `||`), command separators (`;`), and subshell boundaries (`(...)`, `$()`).

Each segment is evaluated independently for sandbox restrictions and approval requirements.")

(= (codex:permissions-auto-review-approval-suffix)
   "`approvals_reviewer` is `auto_review`: Sandbox escalations with require_escalated will be reviewed for compliance with the policy. If a rejection happens, you should proceed only with a materially safer alternative, or inform the user of the risk and send a final message to ask for approval.")

(= (codex:permissions-max-rendered-prefixes)
   100)

(= (codex:permissions-max-allow-prefix-text-bytes)
   5000)

(= (codex:permissions-truncated-marker)
   "...\n[Some commands were truncated]")

(= (codex:permissions-request-permissions-tool-prompt-section)
   "# request_permissions Tool

The built-in `request_permissions` tool is available in this session. Invoke it when you need to request additional `network` or `file_system` permissions before later shell-like commands need them. Request only the specific permissions required for the task.")

(= (codex:permissions-granular-prompt-intro-text)
   "# Approval Requests

Approval policy is `granular`. Categories set to `false` are automatically rejected instead of prompting the user.")

(= (codex:permissions-instructions-role)
   "developer")

(= (codex:permissions-instructions-start-marker)
   "<permissions instructions>")

(= (codex:permissions-instructions-end-marker)
   "</permissions instructions>")

(= (codex:permissions-instructions $text)
   (CodexPermissionsInstructions $text))

(= (codex:permissions-instructions-body
      (CodexPermissionsInstructions $text))
   $text)

(= (codex:permissions-prompt-config
      $approval-policy
      $approvals-reviewer
      $exec-policy
      $exec-permission-approvals-enabled
      $request-permissions-tool-enabled)
   (CodexPermissionsPromptConfig
     $approval-policy
     $approvals-reviewer
     $exec-policy
     $exec-permission-approvals-enabled
     $request-permissions-tool-enabled))

(= (codex:permissions-prompt-config-approval-policy
      (CodexPermissionsPromptConfig
        $approval-policy
        $approvals-reviewer
        $exec-policy
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled))
   $approval-policy)

(= (codex:permissions-prompt-config-approvals-reviewer
      (CodexPermissionsPromptConfig
        $approval-policy
        $approvals-reviewer
        $exec-policy
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled))
   $approvals-reviewer)

(= (codex:permissions-prompt-config-exec-policy
      (CodexPermissionsPromptConfig
        $approval-policy
        $approvals-reviewer
        $exec-policy
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled))
   $exec-policy)

(= (codex:permissions-prompt-config-exec-permission-approvals-enabled
      (CodexPermissionsPromptConfig
        $approval-policy
        $approvals-reviewer
        $exec-policy
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled))
   $exec-permission-approvals-enabled)

(= (codex:permissions-prompt-config-request-permissions-tool-enabled
      (CodexPermissionsPromptConfig
        $approval-policy
        $approvals-reviewer
        $exec-policy
        $exec-permission-approvals-enabled
        $request-permissions-tool-enabled))
   $request-permissions-tool-enabled)

(= (codex:permissions-sandbox-policy-danger-full-access $network-access)
   (CodexPermissionsSandboxPolicyDangerFullAccess $network-access))

(= (codex:permissions-sandbox-policy-external-sandbox $network-access)
   (CodexPermissionsSandboxPolicyExternalSandbox $network-access))

(= (codex:permissions-sandbox-policy-read-only $network-access)
   (CodexPermissionsSandboxPolicyReadOnly $network-access))

(= (codex:permissions-sandbox-policy-workspace-write
      $network-access
      $writable-roots)
   (CodexPermissionsSandboxPolicyWorkspaceWrite
     $network-access
     $writable-roots))

(= (codex:is-auto-review-approvals-reviewer? $reviewer)
   (if (== $reviewer (codex:permissions-approvals-reviewer-auto-review))
       True
       (if (== $reviewer (codex:permissions-approvals-reviewer-guardian-subagent))
           True
           False)))

(= (codex:permissions-append-section $text $section)
   (if (str-ends-with? $text "\n")
       (str-concat $text $section)
       (str-concat $text (str-concat "\n" $section))))

(= (codex:permissions-ensure-trailing-newline $text)
   (if (str-ends-with? $text "\n")
       $text
       (str-concat $text "\n")))

(= (codex:permissions-join-sections $text $section)
   (if (== $text "")
       $section
       (str-concat
         $text
         (str-concat "\n\n" $section))))

(= (codex:permissions-bool-and $left $right)
   (if $left
       (if $right
           True
           False)
       False))

(= (codex:permissions-bool-or $left $right)
   (if $left
       True
       (if $right
           True
           False)))

(= (codex:permissions-sandbox-text $sandbox-mode $network-access)
   (if (== $sandbox-mode (codex:permissions-sandbox-mode-danger-full-access))
       (format-args
         "Filesystem sandboxing defines which files can be read or written. `sandbox_mode` is `danger-full-access`: No filesystem sandboxing - all commands are permitted. Network access is {}."
         ($network-access))
       (if (== $sandbox-mode (codex:permissions-sandbox-mode-workspace-write))
           (format-args
             "Filesystem sandboxing defines which files can be read or written. `sandbox_mode` is `workspace-write`: The sandbox permits reading files, and editing files in `cwd` and `writable_roots`. Editing files in other directories requires approval. Network access is {}."
             ($network-access))
           (if (== $sandbox-mode (codex:permissions-sandbox-mode-read-only))
               (format-args
                 "Filesystem sandboxing defines which files can be read or written. `sandbox_mode` is `read-only`: The sandbox only permits reading files. Network access is {}."
                 ($network-access))
               Empty))))

(= (codex:permissions-quoted-root $root)
   (str-concat "`" (str-concat $root "`")))

; CeTTa does not reliably select among overloaded list-pattern rules when the
; argument is a computed atom, so these list helpers use explicit empty and
; singleton checks while preserving the Rust-visible behavior.
(= (codex:permissions-writable-roots-text $roots)
   (if (== $roots ())
       CodexAbsent
       (if (== (list:rest $roots) ())
           (format-args
             " The writable root is {}."
             ((codex:permissions-quoted-root (list:first $roots))))
           (format-args
             " The writable roots are {}."
             ((str-join
                ", "
                (eval
                  (map-atom $roots $root (codex:permissions-quoted-root $root)))))))))

(= (codex:permissions-category $is-allowed $label)
   (CodexPermissionsCategory $is-allowed $label))

(= (codex:permissions-category-allowed
      (CodexPermissionsCategory $is-allowed $label))
   $is-allowed)

(= (codex:permissions-category-label
      (CodexPermissionsCategory $is-allowed $label))
   $label)

(= (codex:permissions-category-line $label)
   (str-concat "- " $label))

(= (codex:permissions-category-lists $prompted $rejected)
   (CodexPermissionsCategoryLists $prompted $rejected))

(= (codex:permissions-category-lists-prompted
      (CodexPermissionsCategoryLists $prompted $rejected))
   $prompted)

(= (codex:permissions-category-lists-rejected
      (CodexPermissionsCategoryLists $prompted $rejected))
   $rejected)

(= (codex:permissions-partition-categories $categories)
   (if (== $categories ())
       (codex:permissions-category-lists () ())
       (let ($head $tail) (decons-atom $categories)
         (let $rest (codex:permissions-partition-categories $tail)
           (if (codex:permissions-category-allowed $head)
               (codex:permissions-category-lists
                 (list:append
                   ((codex:permissions-category-line
                       (codex:permissions-category-label $head)))
                   (codex:permissions-category-lists-prompted $rest))
                 (codex:permissions-category-lists-rejected $rest))
               (codex:permissions-category-lists
                 (codex:permissions-category-lists-prompted $rest)
                 (list:append
                   ((codex:permissions-category-line
                       (codex:permissions-category-label $head)))
                   (codex:permissions-category-lists-rejected $rest))))))))

(= (codex:permissions-granular-config-sandbox-approval
      (CodexAskForApprovalGranularConfig
        $sandbox-approval
        $rules
        $skill-approval
        $request-permissions
        $mcp-elicitations))
   $sandbox-approval)

(= (codex:permissions-granular-config-rules
      (CodexAskForApprovalGranularConfig
        $sandbox-approval
        $rules
        $skill-approval
        $request-permissions
        $mcp-elicitations))
   $rules)

(= (codex:permissions-granular-config-skill-approval
      (CodexAskForApprovalGranularConfig
        $sandbox-approval
        $rules
        $skill-approval
        $request-permissions
        $mcp-elicitations))
   $skill-approval)

(= (codex:permissions-granular-config-request-permissions
      (CodexAskForApprovalGranularConfig
        $sandbox-approval
        $rules
        $skill-approval
        $request-permissions
        $mcp-elicitations))
   $request-permissions)

(= (codex:permissions-granular-config-mcp-elicitations
      (CodexAskForApprovalGranularConfig
        $sandbox-approval
        $rules
        $skill-approval
        $request-permissions
        $mcp-elicitations))
   $mcp-elicitations)

(= (codex:permissions-allows-sandbox-approval? $config)
   (codex:permissions-granular-config-sandbox-approval $config))

(= (codex:permissions-allows-rules-approval? $config)
   (codex:permissions-granular-config-rules $config))

(= (codex:permissions-allows-skill-approval? $config)
   (codex:permissions-granular-config-skill-approval $config))

(= (codex:permissions-allows-request-permissions? $config)
   (codex:permissions-granular-config-request-permissions $config))

(= (codex:permissions-allows-mcp-elicitations? $config)
   (codex:permissions-granular-config-mcp-elicitations $config))

(= (codex:permissions-prefix-combined-str-len $prefix)
   (if (== $prefix ())
       0
       (let ($head $tail) (decons-atom $prefix)
         (+ (str-length $head)
            (codex:permissions-prefix-combined-str-len $tail)))))

(= (codex:permissions-render-pattern-token $token)
   (case $token
     (((CodexExecPolicyPatternTokenSingle $value)
       $value)
      ((CodexExecPolicyPatternTokenAlts $alternatives)
       (str-concat
         "["
         (str-concat (str-join "|" $alternatives) "]"))))))

(= (codex:permissions-rule-prefix $rule)
   (case $rule
     (((CodexExecPolicyPrefixRule $first $rest $decision $justification)
       (let $rendered-rest
         (eval
           (map-atom $rest $token (codex:permissions-render-pattern-token $token)))
         (cons-atom
           $first
           $rendered-rest))))))

(= (codex:permissions-collect-allowed-prefixes-rules $rules)
   (if (== $rules ())
       ()
       (let ($head $tail) (decons-atom $rules)
         (case (codex:permissions-collect-allowed-prefixes-rules $tail)
           (($rest-prefixes
             (if (== (codex:prefix-rule-decision $head) "allow")
                 (case (codex:permissions-rule-prefix $head)
                   (($prefix
                     (cons-atom $prefix $rest-prefixes))))
                 $rest-prefixes)))))))

; Rust uses serde_json::to_string for each prefix token. The direct native
; stringifier keeps this prompt helper independent of caller-visible imports.
(= (codex:permissions-json-quoted-string $text)
   (function
     (case (__cetta_lib_json_stringify (JsonString $text))
       (($result (return $result))))))

; CeTTa evaluation accommodation: direct recursion preserves Rust's Vec
; map/join result while avoiding imported-module map materialization collapse.
(= (codex:permissions-render-command-prefix-items ())
   "")

(= (codex:permissions-render-command-prefix-items $prefix)
   (let ($head $tail) (decons-atom $prefix)
     (if (== $tail ())
         (codex:permissions-json-quoted-string $head)
         (str-concat
           (codex:permissions-json-quoted-string $head)
           (str-concat
             ", "
             (codex:permissions-render-command-prefix-items $tail))))))

(= (codex:permissions-render-command-prefix $prefix)
   (str-concat
     "["
     (str-concat
       (codex:permissions-render-command-prefix-items $prefix)
       "]")))

(= (codex:permissions-pad-natural-six-text $value)
   (let $text (format-args "{}" ($value))
     (if (== (str-length $text) 0)
         "000000"
         (if (== (str-length $text) 1)
             (str-concat "00000" $text)
             (if (== (str-length $text) 2)
                 (str-concat "0000" $text)
                 (if (== (str-length $text) 3)
                     (str-concat "000" $text)
                     (if (== (str-length $text) 4)
                         (str-concat "00" $text)
                         (if (== (str-length $text) 5)
                             (str-concat "0" $text)
                             $text))))))))

(= (codex:permissions-prefix-sort-record $prefix)
   (str-concat
     (codex:permissions-pad-natural-six-text (size-atom $prefix))
     (str-concat
       "|"
       (str-concat
         (codex:permissions-pad-natural-six-text
           (codex:permissions-prefix-combined-str-len $prefix))
         (str-concat
           "|"
           (codex:permissions-render-command-prefix $prefix))))))

(= (codex:permissions-sort-prefix-records $prefixes)
   (let $materialized-prefixes (eval $prefixes)
     (let $records
       (map-atom-strict
         $materialized-prefixes
         $prefix
         (codex:permissions-prefix-sort-record $prefix))
       (sort-strings $records))))

(= (codex:permissions-dedup-sorted-strings $items)
   (if (== $items ())
       ()
       (let ($head $tail) (decons-atom $items)
           (if (== $tail ())
               ($head)
               (let $dedup-tail (codex:permissions-dedup-sorted-strings $tail)
                 (if (== $head (car-atom $dedup-tail))
                     $dedup-tail
                     (cons-atom $head $dedup-tail)))))))

(= (codex:permissions-strip-prefix-sort-key $record)
   (str-slice $record 14 (str-length $record)))

(= (codex:permissions-strip-prefix-sort-keys ())
   ())

(= (codex:permissions-strip-prefix-sort-keys $records)
   (let ($head $tail) (decons-atom $records)
     (let $value (eval (codex:permissions-strip-prefix-sort-key $head))
       (let $rest (eval (codex:permissions-strip-prefix-sort-keys $tail))
         (cons-atom $value $rest)))))

(= (codex:permissions-sorted-rendered-prefixes $policy)
   (let $sorted-records
     (codex:permissions-dedup-sorted-strings
       (codex:permissions-sort-prefix-records
         (codex:permissions-collect-allowed-prefixes-rules
           (codex:policy-rules $policy))))
     (eval (codex:permissions-strip-prefix-sort-keys $sorted-records))))

(= (codex:permissions-take-first-n $items $count)
   (if (<= $count 0)
       ()
       (if (== $items ())
           ()
           (cons-atom
             (car-atom $items)
             (codex:permissions-take-first-n
               (cdr-atom $items)
               (- $count 1))))))

(= (codex:permissions-render-bullet-lines $items)
   (if (== $items ())
       ""
       (let ($head $tail) (decons-atom $items)
           (if (== $tail ())
               (str-concat "- " $head)
               (str-concat
                 (str-concat "- " $head)
                 (str-concat
                   "\n"
                   (codex:permissions-render-bullet-lines $tail)))))))

(= (codex:permissions-format-allow-prefixes $prefixes)
   (case (codex:permissions-sorted-rendered-prefixes $prefixes)
     (($sorted-rendered
       (if (== $sorted-rendered ())
           CodexAbsent
           (let $prefix-count (size-atom $sorted-rendered)
             (let $truncated-by-count (> $prefix-count (codex:permissions-max-rendered-prefixes))
               (let $limited-rendered
                 (codex:permissions-take-first-n
                   $sorted-rendered
                   (codex:permissions-max-rendered-prefixes))
                 (let $full-text
                   (codex:permissions-render-bullet-lines $limited-rendered)
                   (let $truncated-text
                     (str-take-bytes-at-char-boundary
                       $full-text
                       (codex:permissions-max-allow-prefix-text-bytes))
                     (let $truncated-by-bytes
                       (< (str-length $truncated-text) (str-length $full-text))
                       (if (codex:permissions-bool-or
                             $truncated-by-count
                             $truncated-by-bytes)
                           (str-concat
                             $truncated-text
                             (codex:permissions-truncated-marker))
                           $full-text))))))))))))

(= (codex:permissions-approved-command-prefixes-text $exec-policy)
   (codex:permissions-format-allow-prefixes $exec-policy))

(= (codex:permissions-granular-text
      $granular-config
      $exec-policy
      $exec-permission-approvals-enabled
      $request-permissions-tool-enabled)
   (let $categories
     (if $request-permissions-tool-enabled
         ((codex:permissions-category
             (codex:permissions-allows-sandbox-approval? $granular-config)
             "`sandbox_approval`")
          (codex:permissions-category
             (codex:permissions-allows-rules-approval? $granular-config)
             "`rules`")
          (codex:permissions-category
             (codex:permissions-allows-skill-approval? $granular-config)
             "`skill_approval`")
          (codex:permissions-category
             (codex:permissions-allows-request-permissions? $granular-config)
             "`request_permissions`")
          (codex:permissions-category
             (codex:permissions-allows-mcp-elicitations? $granular-config)
             "`mcp_elicitations`"))
         ((codex:permissions-category
             (codex:permissions-allows-sandbox-approval? $granular-config)
             "`sandbox_approval`")
          (codex:permissions-category
             (codex:permissions-allows-rules-approval? $granular-config)
             "`rules`")
          (codex:permissions-category
             (codex:permissions-allows-skill-approval? $granular-config)
             "`skill_approval`")
          (codex:permissions-category
             (codex:permissions-allows-mcp-elicitations? $granular-config)
             "`mcp_elicitations`")))
     (let $partitioned (codex:permissions-partition-categories $categories)
       (let $shell-permission-requests-available
         (codex:permissions-bool-and
           $exec-permission-approvals-enabled
           (codex:permissions-allows-sandbox-approval? $granular-config))
         (let $request-permissions-tool-prompts-allowed
           (codex:permissions-bool-and
             $request-permissions-tool-enabled
             (codex:permissions-allows-request-permissions? $granular-config))
           (let $text-0 (codex:permissions-granular-prompt-intro-text)
             (let $text-1
               (if (== (codex:permissions-category-lists-prompted $partitioned) ())
                   $text-0
                   (codex:permissions-join-sections
                     $text-0
                     (str-concat
                       "These approval categories may still prompt the user when needed:\n"
                       (str-join
                         "\n"
                         (codex:permissions-category-lists-prompted $partitioned)))))
               (let $text-2
                 (if (== (codex:permissions-category-lists-rejected $partitioned) ())
                     $text-1
                     (codex:permissions-join-sections
                       $text-1
                       (str-concat
                         "These approval categories are automatically rejected instead of prompting the user:\n"
                         (str-join
                           "\n"
                           (codex:permissions-category-lists-rejected $partitioned)))))
                 (let $text-3
                   (if $shell-permission-requests-available
                       (codex:permissions-join-sections
                         $text-2
                         (codex:permissions-approval-policy-on-request-rule-request-permission-text))
                       $text-2)
                   (let $text-4
                     (if $request-permissions-tool-prompts-allowed
                         (codex:permissions-join-sections
                           $text-3
                           (codex:permissions-request-permissions-tool-prompt-section))
                         $text-3)
                     (case (codex:permissions-approved-command-prefixes-text $exec-policy)
                       ((CodexAbsent $text-4)
                        ($prefixes
                         (codex:permissions-join-sections
                           $text-4
                           (str-concat
                             "## Approved command prefixes\nThe following prefix rules have already been approved: "
                             $prefixes)))))))))))))))

(= (codex:permissions-approval-text
      $approval-policy
      $approvals-reviewer
      $exec-policy
      $exec-permission-approvals-enabled
      $request-permissions-tool-enabled)
   (let $base-text
     (case $approval-policy
       (((CodexAskForApprovalGranular $granular-config)
         (codex:permissions-granular-text
           $granular-config
           $exec-policy
           $exec-permission-approvals-enabled
           $request-permissions-tool-enabled))
        ($other
         (if (== $approval-policy (codex:ask-for-approval-never))
             (codex:permissions-approval-policy-never-text)
             (if (== $approval-policy (codex:ask-for-approval-unless-trusted))
                 (if $request-permissions-tool-enabled
                     (str-concat
                       (codex:permissions-approval-policy-unless-trusted-text)
                       (str-concat
                         "\n\n"
                         (codex:permissions-request-permissions-tool-prompt-section)))
                     (codex:permissions-approval-policy-unless-trusted-text))
                 (if (== $approval-policy (codex:ask-for-approval-on-failure))
                     (if $request-permissions-tool-enabled
                         (str-concat
                           (codex:permissions-approval-policy-on-failure-text)
                           (str-concat
                             "\n\n"
                             (codex:permissions-request-permissions-tool-prompt-section)))
                         (codex:permissions-approval-policy-on-failure-text))
                     (if (== $approval-policy (codex:ask-for-approval-on-request))
                         (let $on-request-base
                           (if $exec-permission-approvals-enabled
                               (codex:permissions-approval-policy-on-request-rule-request-permission-text)
                               (codex:permissions-approval-policy-on-request-rule-text))
                           (let $on-request-with-tool
                             (if $request-permissions-tool-enabled
                                 (str-concat
                                   $on-request-base
                                   (str-concat
                                     "\n\n"
                                     (codex:permissions-request-permissions-tool-prompt-section)))
                                 $on-request-base)
                             (case (codex:permissions-approved-command-prefixes-text $exec-policy)
                               ((CodexAbsent $on-request-with-tool)
                                ($prefixes
                                 (str-concat
                                   $on-request-with-tool
                                   (str-concat
                                     "\n\n## Approved command prefixes\nThe following prefix rules have already been approved: "
                                     $prefixes)))))))
                         Empty)))))))
     (if (codex:is-auto-review-approvals-reviewer? $approvals-reviewer)
         (if (== $approval-policy (codex:ask-for-approval-never))
             $base-text
             (str-concat
               $base-text
               (str-concat
                 "\n\n"
                 (codex:permissions-auto-review-approval-suffix))))
         $base-text)))

(= (codex:permissions-instructions-from-permissions-with-network
      $sandbox-mode
      $network-access
      $config
      $writable-roots)
   (let $text-0
     (codex:permissions-append-section
       ""
       (codex:permissions-sandbox-text $sandbox-mode $network-access))
     (let $text-1
       (codex:permissions-append-section
         $text-0
         (codex:permissions-approval-text
           (codex:permissions-prompt-config-approval-policy $config)
           (codex:permissions-prompt-config-approvals-reviewer $config)
           (codex:permissions-prompt-config-exec-policy $config)
           (codex:permissions-prompt-config-exec-permission-approvals-enabled
             $config)
           (codex:permissions-prompt-config-request-permissions-tool-enabled
             $config)))
       (case (codex:permissions-writable-roots-text $writable-roots)
         ((CodexAbsent
           (codex:permissions-instructions
             (codex:permissions-ensure-trailing-newline $text-1)))
          ($writable-roots-text
           (codex:permissions-instructions
             (codex:permissions-ensure-trailing-newline
               (codex:permissions-append-section
                 $text-1
                 $writable-roots-text)))))))))

(= (codex:permissions-instructions-from-policy $sandbox-policy $config)
   (case $sandbox-policy
     (((CodexPermissionsSandboxPolicyDangerFullAccess $network-access)
       (codex:permissions-instructions-from-permissions-with-network
         (codex:permissions-sandbox-mode-danger-full-access)
         $network-access
         $config
         ()))
      ((CodexPermissionsSandboxPolicyExternalSandbox $network-access)
       (codex:permissions-instructions-from-permissions-with-network
         (codex:permissions-sandbox-mode-danger-full-access)
         $network-access
         $config
         ()))
      ((CodexPermissionsSandboxPolicyReadOnly $network-access)
       (codex:permissions-instructions-from-permissions-with-network
         (codex:permissions-sandbox-mode-read-only)
         $network-access
         $config
         ()))
      ((CodexPermissionsSandboxPolicyWorkspaceWrite $network-access $writable-roots)
       (codex:permissions-instructions-from-permissions-with-network
         (codex:permissions-sandbox-mode-workspace-write)
         $network-access
         $config
         $writable-roots)))))
