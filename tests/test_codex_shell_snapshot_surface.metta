!(register-module! ../codex)
!(import! &self fs)
!(import! &self process)
!(import! &self str)
!(import! &self codex:shell_snapshot)

(= (test:shell-snapshot-session-id)
   "019cf82b-6a62-7700-bbbd-46909794ef89")

(= (test:shell-snapshot-codex-home)
   "/home/zarclaw/repos/CeTTa/runtime/codex-shell-snapshot")

(= (test:shell-snapshot-cwd)
   "/home/zarclaw/repos/CeTTa")

(= (test:shell-snapshot-final-path)
   "/home/zarclaw/repos/CeTTa/runtime/codex-shell-snapshot/shell_snapshots/019cf82b-6a62-7700-bbbd-46909794ef89.42.sh")

(= (test:shell-snapshot-temp-path)
   "/home/zarclaw/repos/CeTTa/runtime/codex-shell-snapshot/shell_snapshots/019cf82b-6a62-7700-bbbd-46909794ef89.tmp-42")

!(assertEqualToResult
  (codex:shell-snapshot-dir)
  ("shell_snapshots"))

!(assertEqualToResult
  (codex:shell-snapshot-timeout-secs)
  (10))

!(assertEqualToResult
  (codex:shell-snapshot-timeout-ms)
  (10000))

!(assertEqualToResult
  (codex:shell-snapshot-max-output-bytes)
  (10485760))

!(assertEqualToResult
  (codex:shell-snapshot-retention-secs)
  (259200))

!(assertEqualToResult
  (codex:shell-snapshot-excluded-exports-regex)
  ("PWD|OLDPWD"))

!(assertEqualToResult
  (codex:shell-snapshot-extension (codex:shell-type-powershell))
  ("ps1"))

!(assertEqualToResult
  (codex:shell-snapshot-extension (codex:shell-type-bash))
  ("sh"))

!(assertEqualToResult
  (codex:is-shell-snapshot-write-supported (codex:shell-type-bash))
  (True))

!(assertEqualToResult
  (codex:is-shell-snapshot-write-supported (codex:shell-type-powershell))
  (False))

!(assertEqualToResult
  (codex:shell-snapshot-path-plan
    (test:shell-snapshot-codex-home)
    (test:shell-snapshot-session-id)
    42
    (codex:shell-type-bash))
  ((CodexShellSnapshotPaths
     "/home/zarclaw/repos/CeTTa/runtime/codex-shell-snapshot/shell_snapshots/019cf82b-6a62-7700-bbbd-46909794ef89.42.sh"
     "/home/zarclaw/repos/CeTTa/runtime/codex-shell-snapshot/shell_snapshots/019cf82b-6a62-7700-bbbd-46909794ef89.tmp-42")))

!(assertEqualToResult
  (codex:shell-snapshot-validation-script "/tmp/snapshot.sh")
  ("set -e; . \"/tmp/snapshot.sh\""))

!(assertEqualToResult
  (codex:shell-snapshot-result-value
    (codex:strip-shell-snapshot-preamble
      "noise\n# Snapshot file\nexport PATH=/bin\n"))
  ("# Snapshot file\nexport PATH=/bin\n"))

!(assertEqualToResult
  (codex:shell-snapshot-result-error
    (codex:strip-shell-snapshot-preamble "missing header"))
  ("Snapshot output missing marker # Snapshot file"))

!(assertEqualToResult
  (codex:shell-snapshot-session-id-from-file-name
    "019cf82b-6a62-7700-bbbd-46909794ef89.sh")
  ("019cf82b-6a62-7700-bbbd-46909794ef89"))

!(assertEqualToResult
  (codex:shell-snapshot-session-id-from-file-name
    "019cf82b-6a62-7700-bbbd-46909794ef89.123.sh")
  ("019cf82b-6a62-7700-bbbd-46909794ef89"))

!(assertEqualToResult
  (codex:shell-snapshot-session-id-from-file-name
    "019cf82b-6a62-7700-bbbd-46909794ef89.123.ps1")
  ("019cf82b-6a62-7700-bbbd-46909794ef89"))

!(assertEqualToResult
  (codex:shell-snapshot-session-id-from-file-name
    "019cf82b-6a62-7700-bbbd-46909794ef89.tmp-123")
  ("019cf82b-6a62-7700-bbbd-46909794ef89"))

!(assertEqualToResult
  (codex:shell-snapshot-session-id-from-file-name
    "parent.child.tmp-123")
  ("parent.child"))

!(assertEqualToResult
  (codex:shell-snapshot-session-id-from-file-name
    "not-a-snapshot.txt")
  (CodexAbsent))

!(assertEqual
  (case (str-find (codex:bash-snapshot-script) "# Snapshot file")
    ((Empty False)
     ($offset True)))
  True)

!(assertEqual
  (case (str-find (codex:bash-snapshot-script) "^(PWD|OLDPWD)$")
    ((Empty False)
     ($offset True)))
  True)

!(assertEqual
  (case (str-find (codex:bash-snapshot-script) "EXCLUDED_EXPORTS")
    ((Empty True)
     ($offset False)))
  True)

!(assertEqual
  (case (str-find (codex:zsh-snapshot-script) "alias -L")
    ((Empty False)
     ($offset True)))
  True)

!(assertEqual
  (case (str-find (codex:sh-snapshot-script) "export -p")
    ((Empty False)
     ($offset True)))
  True)

!(assertEqual
  (case (str-find (codex:powershell-snapshot-script) "Get-ChildItem Function:")
    ((Empty False)
     ($offset True)))
  True)

!(assertEqual
  (codex:shell-snapshot-script (codex:shell-type-bash))
  (codex:bash-snapshot-script))

!(assertEqualToResult
  (codex:shell-snapshot-script (codex:shell-type-cmd))
  (CodexAbsent))

!(assertEqualToResult
  (codex:shell-snapshot-result-error
    (codex:write-shell-snapshot
      (codex:shell-type-powershell)
      "/tmp/unused.ps1"
      (test:shell-snapshot-cwd)))
  ("Shell snapshot not supported yet for PowerShell"))

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-shell-snapshot"))
  (0))

!(assertEqualToResult
  (codex:shell-snapshot-result-value
    (codex:try-new-shell-snapshot-with-nonce
      (test:shell-snapshot-codex-home)
      (test:shell-snapshot-session-id)
      42
      (test:shell-snapshot-cwd)
      (codex:shell-type-bash)))
  ((CodexShellSnapshot
     "/home/zarclaw/repos/CeTTa/runtime/codex-shell-snapshot/shell_snapshots/019cf82b-6a62-7700-bbbd-46909794ef89.42.sh"
     "/home/zarclaw/repos/CeTTa")))

!(assertEqualToResult
  (fs-exists? (test:shell-snapshot-final-path))
  (True))

!(assertEqualToResult
  (fs-exists? (test:shell-snapshot-temp-path))
  (False))

!(assertEqualToResult
  (codex:shell-snapshot-result-value
    (codex:validate-shell-snapshot
      (codex:shell-type-bash)
      (test:shell-snapshot-final-path)
      (test:shell-snapshot-cwd)))
  (()))

!(assertEqual
  (case (str-find
          (fs-read-text (test:shell-snapshot-final-path))
          "# Snapshot file")
    ((Empty False)
     ($offset True)))
  True)
