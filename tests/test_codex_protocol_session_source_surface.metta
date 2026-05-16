!(register-module! ../codex)
!(import! &self codex:protocol)
!(import! &self codex:agent_path)
!(import! &self json)

(= (session-source-startup-arg-result-text
      (CodexSessionSourceOk $source))
   (str-concat "ok:" (codex:session-source-display $source)))

(= (session-source-startup-arg-result-text
      (CodexSessionSourceErr $message))
   (str-concat "err:" $message))

(= (session-source-restriction-product-text $product)
   (if (== $product CodexAbsent)
       "absent"
       (json-stringify (codex:product-json $product))))

!(assertEqualToResult
  (session-source-startup-arg-result-text
    (codex:session-source-from-startup-arg "vscode"))
  ("ok:vscode"))

!(assertEqualToResult
  (session-source-startup-arg-result-text
    (codex:session-source-from-startup-arg "app-server"))
  ("ok:mcp"))

!(assertEqualToResult
  (session-source-startup-arg-result-text
    (codex:session-source-from-startup-arg " Atlas "))
  ("ok:atlas"))

!(assertEqualToResult
  (session-source-startup-arg-result-text
    (codex:session-source-from-startup-arg " "))
  ("err:session source must not be empty"))

!(assertEqualToResult
  (codex:session-source-thread-source-name
    (codex:session-source-cli))
  ("user"))

!(assertEqualToResult
  (codex:session-source-thread-source-name
    (codex:session-source-subagent
      (codex:subagent-source-review)))
  ("subagent"))

!(assertEqualToResult
  (codex:session-source-thread-source-name
    (codex:session-source-custom "atlas"))
  (CodexAbsent))

!(assertEqualToResult
  (codex:session-source-display
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        "/root"
        2
        (codex:agent-path "/root/scout")
        "Scout"
        "explorer")))
  ("subagent_thread_spawn_/root_d2"))

!(assertEqualToResult
  (codex:subagent-source-display
    (codex:subagent-source-memory-consolidation))
  ("memory_consolidation"))

!(assertEqualToResult
  (codex:session-source-get-nickname
    (codex:session-source-subagent
      (codex:subagent-source-thread-spawn
        "/root"
        1
        (codex:agent-path "/root/scout")
        "Scout"
        "explorer")))
  ("Scout"))

!(assertEqualToResult
  (codex:session-source-get-agent-role
    (codex:session-source-subagent
      (codex:subagent-source-memory-consolidation)))
  ("memory builder"))

!(assertEqualToResult
  (codex:agent-path-as-str
    (codex:session-source-get-agent-path
      (codex:session-source-subagent
        (codex:subagent-source-memory-consolidation))))
  ("/morpheus"))

!(assertEqualToResult
  (codex:agent-path-as-str
    (codex:session-source-get-agent-path
      (codex:session-source-subagent
        (codex:subagent-source-thread-spawn
          "/root"
          1
          (codex:agent-path "/root/scout")
          "Scout"
          "explorer"))))
  ("/root/scout"))

!(assertEqualToResult
  (codex:session-source-get-agent-path
    (codex:session-source-exec))
  (CodexAbsent))

!(assertEqualToResult
  (session-source-restriction-product-text
    (codex:session-source-restriction-product
      (codex:session-source-vscode)))
  ("\"codex\""))

!(assertEqualToResult
  (session-source-restriction-product-text
    (codex:session-source-restriction-product
      (codex:session-source-subagent
        (codex:subagent-source-review))))
  ("absent"))

!(assertEqualToResult
  (session-source-restriction-product-text
    (codex:session-source-restriction-product
      (codex:session-source-custom "ATLAS")))
  ("\"atlas\""))

!(assertEqualToResult
  (session-source-restriction-product-text
    (codex:session-source-restriction-product
      (codex:session-source-custom "atlas-dev")))
  ("absent"))

!(assertEqualToResult
  (codex:session-source-matches-product-restriction
    (codex:session-source-custom "chatgpt")
    ((codex:product-chatgpt)))
  (True))

!(assertEqualToResult
  (codex:session-source-matches-product-restriction
    (codex:session-source-custom "chatgpt")
    ((codex:product-codex)))
  (False))

!(assertEqualToResult
  (codex:session-source-matches-product-restriction
    (codex:session-source-vscode)
    ((codex:product-codex)))
  (True))

!(assertEqualToResult
  (codex:session-source-matches-product-restriction
    (codex:session-source-custom "atlas-dev")
    ((codex:product-atlas)))
  (False))

!(assertEqualToResult
  (codex:session-source-matches-product-restriction
    (codex:session-source-custom "atlas-dev")
    ())
  (True))
