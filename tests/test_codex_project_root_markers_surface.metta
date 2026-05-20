!(register-module! ../codex)
!(import! &self json)
!(import! &self process)
!(import! &self codex:project_root_markers)

!(assertEqualToResult
  (codex:default-project-root-markers)
  ((".git")))

!(assertEqualToResult
  (codex:project-root-markers-from-config
    (JsonString "not-a-table"))
  ((CodexProjectRootMarkersOk CodexAbsent)))

!(assertEqualToResult
  (codex:project-root-markers-from-config
    (JsonObject ()))
  ((CodexProjectRootMarkersOk CodexAbsent)))

!(assertEqualToResult
  (codex:project-root-markers-from-config
    (JsonObject
      ((JsonPair "project_root_markers" (JsonArray ())))))
  ((CodexProjectRootMarkersOk ())))

!(assertEqualToResult
  (codex:project-root-markers-from-config
    (JsonObject
      ((JsonPair "project_root_markers"
         (JsonArray
           ((JsonString "WORKSPACE")
            (JsonString ".git")))))))
  ((CodexProjectRootMarkersOk ("WORKSPACE" ".git"))))

!(assertEqualToResult
  (codex:project-root-markers-error-message
    (codex:project-root-markers-from-config
      (JsonObject
        ((JsonPair "project_root_markers" (JsonString ".git"))))))
  ("project_root_markers must be an array of strings"))

!(assertEqualToResult
  (codex:project-root-markers-error-message
    (codex:project-root-markers-from-config
      (JsonObject
        ((JsonPair "project_root_markers"
           (JsonArray
             ((JsonString ".git")
              (JsonNumber "42"))))))))
  ("project_root_markers must be an array of strings"))

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/repo/.git /home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/repo/inner/src/crate /home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/unmarked/src && printf 'marker\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/repo/inner/WORKSPACE"))
  (0))

!(assertEqualToResult
  (codex:find-project-root
    "/home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/repo/inner/src/crate"
    ())
  ("/home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/repo/inner/src/crate"))

!(assertEqualToResult
  (codex:find-project-root
    "/home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/repo/inner/src/crate"
    (".git"))
  ("/home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/repo"))

!(assertEqualToResult
  (codex:find-project-root
    "/home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/repo/inner/src/crate"
    ("WORKSPACE" ".git"))
  ("/home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/repo/inner"))

!(assertEqualToResult
  (codex:find-project-root
    "/home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/unmarked/src"
    ("NO_SUCH_MARKER_FOR_CODEX_PROJECT_ROOT_TEST"))
  ("/home/zarclaw/repos/CeTTa/runtime/codex-project-root-markers/unmarked/src"))
