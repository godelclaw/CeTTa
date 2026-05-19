!(register-module! ../codex)
!(import! &self json)
!(import! &self shell)
!(import! &self codex:approval)
!(import! &self codex:exec_policy)

!(assertEqual
  (shell-shlex-join ("foo bar" "baz"))
  "'foo bar' baz")

!(assertEqual
  (shell-shlex-join ("hello!world" "'hello!world" "a,b" "a..b"))
  "'hello!world' \"'hello\"'!world' 'a,b' a..b")

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-on-request)
        (codex:file-system-sandbox-restricted)
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "git"))
             (codex:decision-prompt))))
        ("git" "commit" "-m" "hello world"))))
  ("{\"type\":\"needs_approval\",\"reason\":\"`git commit -m 'hello world'` requires approval by policy\",\"proposed_execpolicy_amendment\":null}"))

!(assertEqualToResult
  (json-stringify
    (codex:approval-requirement-json
      (codex:approval-for-command
        (codex:ask-for-approval-never)
        (codex:file-system-sandbox-restricted)
        (codex:policy
          ((codex:prefix-rule
             ((codex:pattern-token "git")
              (codex:pattern-token "commit"))
             (codex:decision-forbidden))))
        ("git" "commit" "-m" "hello world"))))
  ("{\"type\":\"forbidden\",\"reason\":\"`git commit -m 'hello world'` rejected: policy forbids commands starting with `git commit`\"}"))
