!(register-module! ../codex)
!(import! &self codex:path_utils)

!(assertEqualToResult
  (codex:is-wsl-case-insensitive-path "/mnt/C/Users/Dev")
  (True))

!(assertEqualToResult
  (codex:is-wsl-case-insensitive-path "/MNT/c/Users/Dev")
  (True))

!(assertEqualToResult
  (codex:is-wsl-case-insensitive-path "/mnt/cc/Users/Dev")
  (False))

!(assertEqualToResult
  (codex:is-wsl-case-insensitive-path "/home/Dev")
  (False))

!(assertEqualToResult
  (codex:normalize-for-wsl-with-flag "/mnt/C/Users/Dev" True)
  ("/mnt/c/users/dev"))

!(assertEqualToResult
  (codex:normalize-for-wsl-with-flag "/mnt/cc/Users/Dev" True)
  ("/mnt/cc/Users/Dev"))

!(assertEqualToResult
  (codex:normalize-for-wsl-with-flag "/home/Dev" True)
  ("/home/Dev"))

!(assertEqualToResult
  (codex:normalize-for-wsl-with-flag "/mnt/C/Users/Dev" False)
  ("/mnt/C/Users/Dev"))

!(assertEqualToResult
  (codex:normalize-for-native-workdir-with-flag "\\\\?\\D:\\c\\x\\worktrees\\2508\\swift-base" False)
  ("\\\\?\\D:\\c\\x\\worktrees\\2508\\swift-base"))

!(assertEqualToResult
  (codex:normalize-for-native-workdir-with-flag "\\\\?\\D:\\c\\x\\worktrees\\2508\\swift-base" True)
  ("D:\\c\\x\\worktrees\\2508\\swift-base"))

!(assertEqualToResult
  (codex:is-wsl-from-env-and-version "Ubuntu" CodexAbsent)
  (True))

!(assertEqualToResult
  (codex:is-wsl-from-env-and-version CodexAbsent "Linux version 6.1.0 Microsoft")
  (True))

!(assertEqualToResult
  (codex:is-wsl-from-env-and-version CodexAbsent "Linux version 6.1.0 generic")
  (False))

!(assertEqualToResult
  (codex:is-wsl-from-env-and-version CodexAbsent CodexAbsent)
  (False))
