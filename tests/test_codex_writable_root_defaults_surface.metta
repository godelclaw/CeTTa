!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:writable_root_defaults)
!(import! &self process)

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic/.git /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic/.agents /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer-gitdir /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer/.codex /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/bad && printf 'gitdir: ../pointer-gitdir\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer/.git && printf 'not-a-pointer\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/bad/.git && printf 'hello\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/notgit.txt"))
  (0))

!(assertEqualToResult
  (codex:is-git-pointer-file
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer/.git")
  (True))

!(assertEqualToResult
  (codex:is-git-pointer-file
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic/.git")
  (False))

!(assertEqualToResult
  (codex:is-git-pointer-file
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/notgit.txt")
  (False))

!(assertEqualToResult
  (codex:resolve-gitdir-from-file
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer/.git")
  ("/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer-gitdir"))

!(assertEqualToResult
  (codex:resolve-gitdir-from-file
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/bad/.git")
  (CodexAbsent))

!(assertEqualToResult
  (codex:default-read-only-subpaths-for-writable-root
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic"
    False)
  (("/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic/.git"
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic/.agents")))

!(assertEqualToResult
  (codex:default-read-only-subpaths-for-writable-root
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic"
    True)
  (("/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic/.git"
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic/.agents"
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/basic/.codex")))

!(assertEqualToResult
  (codex:default-read-only-subpaths-for-writable-root
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer"
    False)
  (("/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer-gitdir"
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer/.git"
    "/home/zarclaw/repos/CeTTa/runtime/codex-writable-root-defaults/pointer/.codex")))
