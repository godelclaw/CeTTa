!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:command)

!(println! "=== Codex command demo ===")
!(println!
  (json-stringify
    (codex:parsed-commands-json
      (codex:parse-command ("cat" "README.md")))))
!(println!
  (json-stringify
    (codex:parsed-commands-json
      (codex:parse-command ("rg" "-n" "TODO" "src")))))
!(println!
  (json-stringify
    (codex:parsed-commands-json
      (codex:parse-command ("bash" "-lc" "rg --files webview/src | head -n 5")))))
!(println!
  (json-stringify
    (codex:parsed-commands-json
      (codex:parse-command ("head" "-n" "20" "Cargo.toml")))))
!(println!
  (json-stringify
    (codex:parsed-commands-json
      (codex:parse-command ("bash" "-lc" "echo foo > bar")))))
