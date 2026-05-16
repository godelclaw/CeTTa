!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:sandbox_roots)
!(import! &self process)

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace/.git /home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace/.agents /home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/outside /home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/docs"))
  (0))

!(assertEqualToResult
  (== (codex:session-sandbox-policy-new-read-only-policy)
      (codex:session-sandbox-policy-read-only
        (codex:session-read-only-access-full)
        False))
  (True))

!(assertEqualToResult
  (== (codex:session-sandbox-policy-new-workspace-write-policy)
      (codex:session-sandbox-policy-workspace-write
        ()
        (codex:session-read-only-access-full)
        False
        False
        False))
  (True))

!(assertEqualToResult
  (== (codex:session-read-only-access-get-readable-roots-with-cwd
        (codex:session-read-only-access-full)
        "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace")
      ())
  (True))

!(assertEqualToResult
  (== (codex:session-read-only-access-get-readable-roots-with-cwd
        (codex:session-read-only-access-restricted
          False
          ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/docs"
           "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace"
           "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/docs"))
        "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace")
      ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/docs"
       "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace"))
  (True))

!(assertEqualToResult
  (== (codex:session-sandbox-policy-get-readable-roots-with-cwd
        (codex:session-sandbox-policy-read-only
          (codex:session-read-only-access-restricted
            False
            ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/docs"))
          False)
        "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace")
      ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/docs"
       "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace"))
  (True))

!(assertEqualToResult
  (== (codex:session-sandbox-policy-get-readable-roots-with-cwd
        (codex:session-sandbox-policy-danger-full-access)
        "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace")
      ())
  (True))

!(assertEqualToResult
  (== (codex:session-sandbox-policy-get-readable-roots-with-cwd
        (codex:session-sandbox-policy-external-sandbox
          (codex:session-network-access-restricted))
        "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace")
      ())
  (True))

!(assertEqualToResult
  (== (codex:session-sandbox-policy-get-writable-roots-with-cwd
        (codex:session-sandbox-policy-workspace-write
          ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/outside"
           "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace")
          (codex:session-read-only-access-restricted
            False
            ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/docs"))
          False
          True
          True)
        "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace")
      ((codex:writable-root
         "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/outside"
         ())
       (codex:writable-root
         "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace"
         ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace/.git"
          "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace/.agents"
          "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace/.codex"))
       (codex:writable-root
         "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace"
         ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace/.git"
          "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace/.agents"
          "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace/.codex"))))
  (True))

!(assertEqualToResult
  (== (codex:session-sandbox-policy-get-readable-roots-with-cwd
        (codex:session-sandbox-policy-workspace-write
          ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/outside"
           "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace")
          (codex:session-read-only-access-restricted
            False
            ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/docs"
             "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/outside"))
          False
          True
          True)
        "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace")
      ("/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/docs"
       "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/outside"
       "/home/zarclaw/repos/CeTTa/runtime/codex-sandbox-roots/workspace"))
  (True))
