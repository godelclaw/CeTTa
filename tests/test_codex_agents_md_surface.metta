!(register-module! ../codex)
!(import! &self process)
!(import! &self str)
!(import! &self codex:agents_md)

(= (codex-agents-md-root)
   "/home/zarclaw/repos/CeTTa/runtime/codex-agents-md")

(= (codex-agents-md-text-contains $text $needle)
   (case (str-find $text $needle)
     ((Empty False)
      ($index True))))

!(assertEqualToResult
  (codex:agents-md-default-filename)
  ("AGENTS.md"))

!(assertEqualToResult
  (codex:agents-md-local-filename)
  ("AGENTS.override.md"))

!(assertEqualToResult
  (codex:agents-md-separator)
  ("\n\n--- project-doc ---\n\n"))

!(assertEqualToResult
  (codex:agents-md-text-starts-with
    (codex:agents-md-js-repl-instructions-base)
    "## JavaScript REPL (Node)\n")
  (True))

!(assertEqualToResult
  (codex:agents-md-text-ends-with
    (codex:agents-md-js-repl-instructions-base)
    "Local file modules reload between execs, while top-level bindings persist until `js_repl_reset`.\n")
  (True))

!(assertEqualToResult
  (codex:agents-md-js-repl-tools-only-instructions)
  ("- Do not call tools directly; use `js_repl` + `codex.tool(...)` for all tool calls, including shell commands.\n- MCP tools (if any) can also be called by name via `codex.tool(...)`.\n"))

!(assertEqualToResult
  (codex:agents-md-js-repl-final-instruction)
  ("- Avoid direct access to `process.stdout` / `process.stderr` / `process.stdin`; it can corrupt the JSON line protocol. Use `console.log`, `codex.tool(...)`, and `codex.emitImage(...)`."))

!(assertEqualToResult
  (codex:agents-md-render-js-repl-instructions False False)
  (CodexAbsent))

!(assertEqualToResult
  (==
    (codex:agents-md-render-js-repl-instructions True False)
    (str-concat
      (codex:agents-md-js-repl-instructions-base)
      (codex:agents-md-js-repl-final-instruction)))
  (True))

!(assertEqualToResult
  (codex-agents-md-text-contains
    (codex:agents-md-render-js-repl-instructions True False)
    "- Do not call tools directly;")
  (False))

!(assertEqualToResult
  (==
    (codex:agents-md-render-js-repl-instructions True True)
    (str-concat
      (codex:agents-md-js-repl-instructions-base)
      (str-concat
        (codex:agents-md-js-repl-tools-only-instructions)
        (codex:agents-md-js-repl-final-instruction))))
  (True))

!(assertEqualToResult
  (codex:agents-md-text-ends-with
    (codex:agents-md-render-js-repl-instructions True True)
    "- MCP tools (if any) can also be called by name via `codex.tool(...)`.\n- Avoid direct access to `process.stdout` / `process.stderr` / `process.stdin`; it can corrupt the JSON line protocol. Use `console.log`, `codex.tool(...)`, and `codex.emitImage(...)`.")
  (True))

!(assertEqualToResult
  (codex:agents-md-candidate-filenames
    ("EXAMPLE.md" "" "AGENTS.md" ".example.md" "EXAMPLE.md"))
  (("AGENTS.override.md" "AGENTS.md" "EXAMPLE.md" ".example.md")))

!(assertEqualToResult
  (process-result-exit-code
    (process-run-shell
      "rm -rf /home/zarclaw/repos/CeTTa/runtime/codex-agents-md && mkdir -p /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global-empty-override /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/repo/workspace/crate /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/fallback /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/unmarked/child && printf 'global\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global/AGENTS.md && printf ' local override \\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global/AGENTS.override.md && printf 'versioned\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global-empty-override/AGENTS.md && printf '  \\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global-empty-override/AGENTS.override.md && printf 'gitdir: elsewhere\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/repo/.git && printf 'root\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/repo/AGENTS.md && printf 'root-local\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/repo/AGENTS.override.md && printf 'crate\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/repo/workspace/crate/AGENTS.md && printf 'fallback\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/fallback/EXAMPLE.md && printf 'parent\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/unmarked/AGENTS.md && printf 'child\\n' > /home/zarclaw/repos/CeTTa/runtime/codex-agents-md/unmarked/child/AGENTS.md"))
  (0))

!(assertEqualToResult
  (codex:agents-md-loaded-contents
    (codex:agents-md-load-global-instructions
      "/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global"))
  ("local override"))

!(assertEqualToResult
  (codex:agents-md-loaded-path
    (codex:agents-md-load-global-instructions
      "/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global"))
  ("/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global/AGENTS.override.md"))

!(assertEqualToResult
  (codex:agents-md-loaded-contents
    (codex:agents-md-load-global-instructions
      "/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/global-empty-override"))
  ("versioned"))

!(assertEqualToResult
  (codex:agents-md-load-global-instructions CodexAbsent)
  (CodexAbsent))

!(assertEqualToResult
  (codex:agents-md-paths
    "/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/repo/workspace/crate"
    4096
    (".git")
    ())
  (("/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/repo/AGENTS.override.md"
    "/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/repo/workspace/crate/AGENTS.md")))

!(assertEqualToResult
  (codex:agents-md-paths
    "/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/fallback"
    4096
    ()
    ("EXAMPLE.md"))
  (("/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/fallback/EXAMPLE.md")))

!(assertEqualToResult
  (codex:agents-md-paths
    "/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/unmarked/child"
    4096
    ()
    ())
  (("/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/unmarked/child/AGENTS.md")))

!(assertEqualToResult
  (codex:agents-md-paths
    "/home/zarclaw/repos/CeTTa/runtime/codex-agents-md/repo/workspace/crate"
    0
    (".git")
    ())
  (()))

!(assertEqualToResult
  (codex:agents-md-compose-user-instructions
    CodexAbsent
    CodexAbsent
    CodexAbsent
    CodexAbsent)
  (CodexAbsent))

!(assertEqualToResult
  (codex:agents-md-compose-user-instructions
    "base"
    "project"
    CodexAbsent
    CodexAbsent)
  ("base\n\n--- project-doc ---\n\nproject"))

!(assertEqualToResult
  (codex:agents-md-compose-user-instructions
    CodexAbsent
    "project"
    "js"
    "child")
  ("project\n\njs\n\nchild"))

!(assertEqualToResult
  (codex:agents-md-text-starts-with
    (codex:agents-md-compose-configured-user-instructions
      CodexAbsent
      "project"
      True
      True
      CodexAbsent)
    "project\n\n## JavaScript REPL (Node)\n")
  (True))

!(assertEqualToResult
  (codex-agents-md-text-contains
    (codex:agents-md-compose-configured-user-instructions
      CodexAbsent
      "project"
      True
      True
      CodexAbsent)
    "- Do not call tools directly;")
  (True))
