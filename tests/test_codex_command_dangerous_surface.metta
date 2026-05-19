!(register-module! ../codex)
!(import! &self codex:command)

!(assertEqual
  (codex:is-command-dangerous ("rm" "-rf" "/tmp/codex"))
  True)

!(assertEqual
  (codex:is-command-dangerous ("rm" "-f" "/tmp/codex"))
  True)

!(assertEqual
  (codex:is-command-dangerous ("sudo" "rm" "-rf" "/tmp/codex"))
  True)

!(assertEqual
  (codex:is-command-dangerous
    ("bash" "-lc" "echo hi && rm -rf /tmp/codex"))
  True)

!(assertEqual
  (codex:is-command-dangerous ("rm" "-fr" "/tmp/codex"))
  False)

!(assertEqual
  (codex:is-command-dangerous ("rg" "-n" "TODO" "src"))
  False)
