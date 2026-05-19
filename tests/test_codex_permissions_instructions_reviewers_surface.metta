!(register-module! ../codex)
!(import! &self str)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)
!(import! &self codex:permissions_instructions)

(= (codex-pi-contains-text $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($offset True))))

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
