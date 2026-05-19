!(register-module! ../codex)
!(import! &self codex:unified_exec_async_watcher)

(= (watcher-empty-state)
   (codex:unified-exec-async-watcher-chunk-state
     ()
     ()
     0
     ()))

!(assertEqual
  (codex:unified-exec-trailing-output-grace-ms)
  100)

!(assertEqual
  (codex:unified-exec-output-delta-max-bytes)
  8192)

!(assertEqual
  (codex:max-exec-output-deltas-per-call)
  10000)

!(assertEqual
  (codex:unified-exec-utf8-prefix-split-kind
    (codex:unified-exec-split-valid-utf8-prefix-with-max () 5))
  none)

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (104 101 108 108 111 32 119 111 114 100 33)
      5)
    (codex:unified-exec-utf8-prefix-split-prefix $result))
  (104 101 108 108 111))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (104 101 108 108 111 32 119 111 114 100 33)
      5)
    (codex:unified-exec-utf8-prefix-split-remaining $result))
  (32 119 111 114 100 33))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (32 119 111 114 100 33)
      5)
    (codex:unified-exec-utf8-prefix-split-prefix $result))
  (32 119 111 114 100))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (32 119 111 114 100 33)
      5)
    (codex:unified-exec-utf8-prefix-split-remaining $result))
  (33))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (195 169 195 169 195 169)
      3)
    (codex:unified-exec-utf8-prefix-split-prefix $result))
  (195 169))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (195 169 195 169 195 169)
      3)
    (codex:unified-exec-utf8-prefix-split-remaining $result))
  (195 169 195 169))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (255 97 98)
      2)
    (codex:unified-exec-utf8-prefix-split-prefix $result))
  (255))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (255 97 98)
      2)
    (codex:unified-exec-utf8-prefix-split-remaining $result))
  (97 98))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (240 159 152 128 65)
      3)
    (codex:unified-exec-utf8-prefix-split-prefix $result))
  (240))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (240 159 152 128 65)
      4)
    (codex:unified-exec-utf8-prefix-split-prefix $result))
  (240 159 152 128))

!(assertEqual
  (let $result
    (codex:unified-exec-split-valid-utf8-prefix-with-max
      (65 66)
      0)
    (codex:unified-exec-utf8-prefix-split-prefix $result))
  (65))

!(assertEqual
  (codex:unified-exec-utf8-valid-bytes (65 195 169 240 159 152 128))
  True)

!(assertEqual
  (codex:unified-exec-utf8-valid-bytes (65 195))
  False)

!(assertEqual
  (codex:unified-exec-utf8-valid-bytes (237 160 128))
  False)

!(assertEqual
  (let $state
    (codex:unified-exec-process-chunk-with-limits
      (watcher-empty-state)
      "call-1"
      (97 98 99 100 101 102)
      1
      3)
    (codex:unified-exec-async-watcher-chunk-state-pending
      $state))
  ())

!(assertEqual
  (let $state
    (codex:unified-exec-process-chunk-with-limits
      (watcher-empty-state)
      "call-1"
      (97 98 99 100 101 102)
      1
      3)
    (codex:unified-exec-async-watcher-chunk-state-transcript
      $state))
  (97 98 99 100 101 102))

!(assertEqual
  (let $state
    (codex:unified-exec-process-chunk-with-limits
      (watcher-empty-state)
      "call-1"
      (97 98 99 100 101 102)
      1
      3)
    (codex:unified-exec-async-watcher-chunk-state-emitted-deltas
      $state))
  1)

!(assertEqual
  (let $state
    (codex:unified-exec-process-chunk-with-limits
      (watcher-empty-state)
      "call-1"
      (97 98 99 100 101 102)
      1
      3)
    (codex:unified-exec-output-delta-bytes-event-chunk
      (list:first
        (codex:unified-exec-async-watcher-chunk-state-events
          $state))))
  (97 98 99))

!(assertEqual
  (let $state
    (codex:unified-exec-process-chunk-with-limits
      (watcher-empty-state)
      "call-1"
      (195 169 195 169)
      10
      3)
    (codex:unified-exec-async-watcher-chunk-state-transcript
      $state))
  (195 169 195 169))

!(assertEqual
  (let $state
    (codex:unified-exec-process-chunk-with-limits
      (watcher-empty-state)
      "call-1"
      (195 169 195 169)
      10
      3)
    (list:len
      (codex:unified-exec-async-watcher-chunk-state-events
        $state)))
  2)

!(assertEqual
  (let $state
    (codex:unified-exec-process-chunk-with-limits
      (watcher-empty-state)
      "call-invalid"
      (255 97)
      10
      2)
    (codex:unified-exec-async-watcher-chunk-state-transcript
      $state))
  (255 97))

!(assertEqual
  (let $state
    (codex:unified-exec-process-chunk-with-limits
      (codex:unified-exec-async-watcher-chunk-state
        (65)
        (48)
        9999
        ())
      "call-2"
      (66 67)
      10000
      2)
    (codex:unified-exec-async-watcher-chunk-state-transcript
      $state))
  (48 65 66 67))

!(assertEqual
  (let $state
    (codex:unified-exec-process-chunk-with-limits
      (codex:unified-exec-async-watcher-chunk-state
        (65)
        (48)
        9999
        ())
      "call-2"
      (66 67)
      10000
      2)
    (codex:unified-exec-async-watcher-chunk-state-emitted-deltas
      $state))
  10000)

!(assertEqual
  (codex:unified-exec-resolve-aggregated-output
    (codex:unified-exec-async-watcher-transcript 0 "ignored")
    "fallback")
  "fallback")

!(assertEqual
  (codex:unified-exec-resolve-aggregated-output
    (codex:unified-exec-async-watcher-transcript 3 "pty")
    "fallback")
  "pty")

!(assertEqual
  (codex:unified-exec-exec-command-status-for-exit-code 0)
  (CodexExecCommandStatusCompleted))

!(assertEqual
  (codex:unified-exec-exec-command-status-for-exit-code 2)
  (CodexExecCommandStatusFailed))

!(assertEqual
  (codex:unified-exec-emit-exec-end-for-unified-exec
    "call-end-ok"
    "turn-end"
    ("cat" "README.md")
    "/repo"
    "123"
    (codex:unified-exec-async-watcher-transcript 6 "hello\n")
    "fallback"
    0
    (CodexDuration 1 250000000)
    "hello\n")
  (CodexEventExecCommandEnd
    "call-end-ok"
    "123"
    "turn-end"
    ("cat" "README.md")
    "/repo"
    ((CodexParsedCommandRead "cat README.md" "README.md" "README.md"))
    (CodexExecCommandSourceUnifiedExecStartup)
    CodexAbsent
    "hello\n"
    ""
    "hello\n"
    0
    (CodexDuration 1 250000000)
    "hello\n"
    (CodexExecCommandStatusCompleted)))

!(assertEqual
  (codex:unified-exec-emit-exec-end-for-unified-exec
    "call-end-nonzero"
    "turn-end"
    ("false")
    "/repo"
    CodexAbsent
    (codex:unified-exec-async-watcher-transcript 0 "")
    "fallback err"
    2
    (CodexDuration 0 1)
    "fallback err")
  (CodexEventExecCommandEnd
    "call-end-nonzero"
    CodexAbsent
    "turn-end"
    ("false")
    "/repo"
    ((CodexParsedCommandUnknown "false"))
    (CodexExecCommandSourceUnifiedExecStartup)
    CodexAbsent
    "fallback err"
    ""
    "fallback err"
    2
    (CodexDuration 0 1)
    "fallback err"
    (CodexExecCommandStatusFailed)))

!(assertEqual
  (codex:unified-exec-failed-aggregated-output
    "out\n"
    "remote failed")
  "out\n\nremote failed")

!(assertEqual
  (codex:unified-exec-emit-failed-exec-end-for-unified-exec
    "call-end-failed"
    "turn-end"
    ("cat")
    "/repo"
    "321"
    (codex:unified-exec-async-watcher-transcript 0 "")
    "pty failed"
    (CodexDuration 0 42)
    "pty failed")
  (CodexEventExecCommandEnd
    "call-end-failed"
    "321"
    "turn-end"
    ("cat")
    "/repo"
    ((CodexParsedCommandUnknown "cat"))
    (CodexExecCommandSourceUnifiedExecStartup)
    CodexAbsent
    ""
    "pty failed"
    "pty failed"
    -1
    (CodexDuration 0 42)
    "pty failed"
    (CodexExecCommandStatusFailed)))

!(assertEqual
  (codex:unified-exec-spawn-exit-watcher-finished-event
    (codex:unified-exec-async-watcher-process-snapshot
      "pty failed"
      0)
    "call-watch-failed"
    "turn-end"
    ("cat")
    "/repo"
    CodexAbsent
    (codex:unified-exec-async-watcher-transcript 3 "out")
    (CodexDuration 2 0)
    "out\npty failed")
  (CodexEventExecCommandEnd
    "call-watch-failed"
    CodexAbsent
    "turn-end"
    ("cat")
    "/repo"
    ((CodexParsedCommandUnknown "cat"))
    (CodexExecCommandSourceUnifiedExecStartup)
    CodexAbsent
    "out"
    "pty failed"
    "out\npty failed"
    -1
    (CodexDuration 2 0)
    "out\npty failed"
    (CodexExecCommandStatusFailed)))

!(assertEqual
  (codex:unified-exec-spawn-exit-watcher-finished-event
    (codex:unified-exec-async-watcher-process-snapshot
      CodexAbsent
      CodexAbsent)
    "call-watch-default"
    "turn-end"
    ("false")
    "/repo"
    CodexAbsent
    (codex:unified-exec-async-watcher-transcript 0 "")
    (CodexDuration 0 5)
    "")
  (CodexEventExecCommandEnd
    "call-watch-default"
    CodexAbsent
    "turn-end"
    ("false")
    "/repo"
    ((CodexParsedCommandUnknown "false"))
    (CodexExecCommandSourceUnifiedExecStartup)
    CodexAbsent
    ""
    ""
    ""
    -1
    (CodexDuration 0 5)
    ""
    (CodexExecCommandStatusFailed)))
