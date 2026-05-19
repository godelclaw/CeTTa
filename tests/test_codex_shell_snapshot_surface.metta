!(register-module! ../codex)
!(import! &self str)
!(import! &self codex:shell_snapshot)

(= (test:shell-snapshot-session-id)
   "019cf82b-6a62-7700-bbbd-46909794ef89")

!(assertEqualToResult
  (codex:shell-snapshot-dir)
  ("shell_snapshots"))

!(assertEqualToResult
  (codex:shell-snapshot-timeout-secs)
  (10))

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
