!(register-module! ../codex)
!(import! &self fs)
!(import! &self process)
!(import! &self str)
!(import! &self codex:list_dir)
!(import! &self codex:protocol)

(= (codex-list-dir-fixture-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-fixture")

(= (codex-list-dir-deny-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture")

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-list-dir-fixture /home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-list-dir-fixture/nested/deeper /home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture/visible /home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture/private"))
  (0))

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-fixture/entry.txt" "content")
!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-fixture/nested/child.txt" "child")
!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-fixture/nested/deeper/grandchild.txt" "grandchild")

!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture/visible/ok.txt" "ok")
!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture/private/secret.txt" "secret")
!(fs-write-text "/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture/top_secret.txt" "secret")

!(assertEqualToResult
  (str-starts-with?
    (codex:tool-result-output-text
      (once
        (codex:run-list-dir-tool-call
          "call-list-dir"
          "{\"dir_path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-fixture\",\"offset\":1,\"limit\":20,\"depth\":3}")))
    "Absolute path: /home/zarclaw/repos/CeTTa/runtime/codex-list-dir-fixture\nentry.txt\nnested/\n  child.txt\n  deeper/\n    grandchild.txt")
  (True))

!(assertEqualToResult
  (codex:tool-result-output-text
    (once
      (codex:run-list-dir-tool-call
        "call-list-dir-offset"
        "{\"dir_path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-fixture\",\"offset\":10,\"limit\":1,\"depth\":2}")))
  ("offset exceeds directory entry count"))

!(assertEqualToResult
  (str-starts-with?
    (codex:tool-result-output-text
      (once
        (codex:run-list-dir-tool-call-with-context
          (codex:list-dir-handler-context
            ("/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture/private"
             "/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture/top_secret.txt"))
          "call-list-dir-deny"
          "{\"dir_path\":\"/home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture\",\"offset\":1,\"limit\":20,\"depth\":3}")))
    "Absolute path: /home/zarclaw/repos/CeTTa/runtime/codex-list-dir-deny-fixture\nvisible/\n  ok.txt")
  (True))
