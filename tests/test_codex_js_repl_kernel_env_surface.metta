!(register-module! ../codex)
!(import! &self codex:js_repl)

!(assertEqual
  (codex:js-repl-env-get
    ((codex:js-repl-env-var "A" "1")
     (codex:js-repl-env-var "B" "2"))
    "B")
  "2")

!(assertEqual
  (codex:js-repl-env-get
    (codex:js-repl-env-insert
      ((codex:js-repl-env-var "A" "old")
       (codex:js-repl-env-var "B" "2"))
      "A"
      "new")
    "A")
  "new")

!(assertEqual
  (codex:js-repl-env-get
    (codex:js-repl-start-kernel-env-value
      (codex:js-repl-start-kernel-env
        ((codex:js-repl-env-var "PATH" "/usr/bin")
         (codex:js-repl-env-var "DUP" "base"))
        ((codex:js-repl-env-var "DUP" "dependency"))
        "/tmp/js"
        ("/repo/node_modules" "/repo/vendor")
        (CodexJsReplNodeModuleDirsJoinOk
          "/repo/node_modules:/repo/vendor")))
    "DUP")
  "dependency")

!(assertEqual
  (codex:js-repl-env-get
    (codex:js-repl-start-kernel-env-value
      (codex:js-repl-start-kernel-env
        ()
        ()
        "/tmp/js"
        ()
        (CodexJsReplNodeModuleDirsJoinError "should not be used")))
    "CODEX_JS_TMP_DIR")
  "/tmp/js")

!(assertEqual
  (codex:js-repl-env-get
    (codex:js-repl-start-kernel-env-value
      (codex:js-repl-start-kernel-env
        ()
        ()
        "/tmp/js"
        ("/repo/node_modules" "/repo/vendor")
        (CodexJsReplNodeModuleDirsJoinOk
          "/repo/node_modules:/repo/vendor")))
    "CODEX_JS_REPL_NODE_MODULE_DIRS")
  "/repo/node_modules:/repo/vendor")

!(assertEqual
  (codex:js-repl-env-get
    (codex:js-repl-start-kernel-env-value
      (codex:js-repl-start-kernel-env
        ((codex:js-repl-env-var
           "CODEX_JS_REPL_NODE_MODULE_DIRS"
           "preexisting"))
        ()
        "/tmp/js"
        ("/repo/node_modules")
        (CodexJsReplNodeModuleDirsJoinOk "/repo/node_modules")))
    "CODEX_JS_REPL_NODE_MODULE_DIRS")
  "preexisting")

!(assertEqual
  (codex:js-repl-env-get
    (codex:js-repl-start-kernel-env-value
      (codex:js-repl-start-kernel-env
        ()
        ()
        "/tmp/js"
        ()
        (CodexJsReplNodeModuleDirsJoinOk "unused")))
    "CODEX_JS_REPL_NODE_MODULE_DIRS")
  CodexAbsent)

!(assertEqual
  (codex:js-repl-start-kernel-env-error-message
    (codex:js-repl-start-kernel-env
      ()
      ()
      "/tmp/js"
      ("/bad:path")
      (CodexJsReplNodeModuleDirsJoinError
        "path contains separator")))
  "failed to join js_repl_node_module_dirs: path contains separator")

!(assertEqual
  (codex:js-repl-env-get
    (codex:js-repl-start-kernel-env-value
      (codex:js-repl-start-kernel-env
        ((codex:js-repl-env-var
           "CODEX_JS_REPL_NODE_MODULE_DIRS"
           "preexisting"))
        ()
        "/tmp/js"
        ("/bad:path")
        (CodexJsReplNodeModuleDirsJoinError
          "path contains separator")))
    "CODEX_JS_REPL_NODE_MODULE_DIRS")
  "preexisting")
