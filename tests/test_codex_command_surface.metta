!(register-module! ../codex)
!(import! &self json)
!(import! &self codex:command)

!(assertEqualToResult
  (json-stringify
    (codex:parsed-commands-json
      (codex:parse-command ("cat" "README.md"))))
  ("[{\"type\":\"read\",\"cmd\":\"cat README.md\",\"name\":\"README.md\",\"path\":\"README.md\"}]"))

!(assertEqualToResult
  (json-stringify
    (codex:parsed-commands-json
      (codex:parse-command ("rg" "-n" "TODO" "src"))))
  ("[{\"type\":\"search\",\"cmd\":\"rg -n TODO src\",\"query\":\"TODO\",\"path\":\"src\"}]"))

!(assertEqualToResult
  (json-stringify
    (codex:parsed-commands-json
      (codex:parse-command ("bash" "-lc" "rg --files webview/src | head -n 5"))))
  ("[{\"type\":\"list_files\",\"cmd\":\"rg --files webview/src\",\"path\":\"webview\"}]"))

!(assertEqualToResult
  (json-stringify
    (codex:parsed-commands-json
      (codex:parse-command ("bash" "-lc" "echo foo > bar"))))
  ("[{\"type\":\"unknown\",\"cmd\":\"echo foo > bar\"}]"))
