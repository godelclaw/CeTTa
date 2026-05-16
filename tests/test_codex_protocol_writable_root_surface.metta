!(register-module! ../codex)
!(import! &self codex:protocol)

!(assertEqualToResult
  (codex:writable-root-root
    (codex:writable-root
      "/repo"
      ("/repo/.git" "/repo/.codex")))
  ("/repo"))

!(assertEqualToResult
  (codex:writable-root-read-only-subpaths
    (codex:writable-root
      "/repo"
      ("/repo/.git" "/repo/.codex")))
  (("/repo/.git" "/repo/.codex")))

!(assertEqualToResult
  (codex:writable-root-is-path-writable
    (codex:writable-root
      "/repo"
      ("/repo/.git" "/repo/.codex"))
    "/repo")
  (True))

!(assertEqualToResult
  (codex:writable-root-is-path-writable
    (codex:writable-root
      "/repo"
      ("/repo/.git" "/repo/.codex"))
    "/repo/src/main.rs")
  (True))

!(assertEqualToResult
  (codex:writable-root-is-path-writable
    (codex:writable-root
      "/repo"
      ("/repo/.git" "/repo/.codex"))
    "/repo/.git/config")
  (False))

!(assertEqualToResult
  (codex:writable-root-is-path-writable
    (codex:writable-root
      "/repo"
      ("/repo/.git" "/repo/.codex"))
    "/repo/.codex")
  (False))

!(assertEqualToResult
  (codex:writable-root-is-path-writable
    (codex:writable-root
      "/repo"
      ("/repo/.git"))
    "/repo-x/file.txt")
  (False))

!(assertEqualToResult
  (codex:writable-root-is-path-writable
    (codex:writable-root
      "/repo"
      ("/repo/.git"))
    "repo/src/main.rs")
  (False))
