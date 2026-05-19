!(register-module! ../codex)
!(import! &self str)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)
!(import! &self codex:permissions_instructions)

(= (codex-pi-prefix-allow-policy)
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

!(assertEqual
  (case (codex:permissions-approval-text
    (codex:ask-for-approval-on-request)
    (codex:permissions-approvals-reviewer-user)
    (codex-pi-prefix-allow-policy)
    False
    False)
    (($text
      (case (str-find
              $text
              "## Approved command prefixes\nThe following prefix rules have already been approved: - [\"git\", \"pull\"]\n- [\"cargo\", \"test\"]")
        ((Empty False)
         ($offset True))))))
  True)
