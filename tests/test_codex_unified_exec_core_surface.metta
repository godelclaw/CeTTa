!(register-module! ../codex)
!(import! &self codex:unified_exec_core)

(= (codex-core-exec-command-request)
   (codex:unified-exec-exec-command-request
     ("bash" "-lc" "printf hi")
     "printf hi"
     1000
     125
     CodexAbsent
     "/repo"
     CodexAbsent
     True
     sandbox-read-only
     CodexAbsent
     False
     "needed"
     ("bash" "-lc")))

(= (codex-core-write-stdin-request $input $yield-time-ms)
   (codex:unified-exec-write-stdin-request
     1000
     $input
     $yield-time-ms
     CodexAbsent))

!(assertEqual
  (codex:unified-exec-min-yield-time-ms)
  250)

!(assertEqual
  (codex:unified-exec-min-empty-yield-time-ms)
  5000)

!(assertEqual
  (codex:unified-exec-max-yield-time-ms)
  30000)

!(assertEqual
  (codex:unified-exec-default-max-background-terminal-timeout-ms)
  300000)

!(assertEqual
  (codex:unified-exec-default-max-output-tokens)
  10000)

!(assertEqual
  (codex:unified-exec-output-max-tokens)
  262144)

!(assertEqual
  (codex:unified-exec-context-session
    (codex:unified-exec-context-new session-1 turn-1 "call-1"))
  session-1)

!(assertEqual
  (codex:unified-exec-context-turn
    (codex:unified-exec-context-new session-1 turn-1 "call-1"))
  turn-1)

!(assertEqual
  (codex:unified-exec-context-call-id
    (codex:unified-exec-context-new session-1 turn-1 "call-1"))
  "call-1")

!(assertEqual
  (codex:unified-exec-exec-command-request-command
    (codex-core-exec-command-request))
  ("bash" "-lc" "printf hi"))

!(assertEqual
  (codex:unified-exec-exec-command-request-hook-command
    (codex-core-exec-command-request))
  "printf hi")

!(assertEqual
  (codex:unified-exec-exec-command-request-process-id
    (codex-core-exec-command-request))
  1000)

!(assertEqual
  (codex:unified-exec-exec-command-request-yield-time-ms
    (codex-core-exec-command-request))
  125)

!(assertEqual
  (codex:unified-exec-exec-command-request-max-output-tokens
    (codex-core-exec-command-request))
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-exec-command-request-workdir
    (codex-core-exec-command-request))
  "/repo")

!(assertEqual
  (codex:unified-exec-exec-command-request-network
    (codex-core-exec-command-request))
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-exec-command-request-tty
    (codex-core-exec-command-request))
  True)

!(assertEqual
  (codex:unified-exec-exec-command-request-sandbox-permissions
    (codex-core-exec-command-request))
  sandbox-read-only)

!(assertEqual
  (codex:unified-exec-exec-command-request-additional-permissions
    (codex-core-exec-command-request))
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-exec-command-request-additional-permissions-preapproved
    (codex-core-exec-command-request))
  False)

!(assertEqual
  (codex:unified-exec-exec-command-request-justification
    (codex-core-exec-command-request))
  "needed")

!(assertEqual
  (codex:unified-exec-exec-command-request-prefix-rule
    (codex-core-exec-command-request))
  ("bash" "-lc"))

!(assertEqual
  (codex:unified-exec-write-stdin-request-process-id
    (codex-core-write-stdin-request "exit\n" 100))
  1000)

!(assertEqual
  (codex:unified-exec-write-stdin-request-input
    (codex-core-write-stdin-request "exit\n" 100))
  "exit\n")

!(assertEqual
  (codex:unified-exec-write-stdin-request-yield-time-ms
    (codex-core-write-stdin-request "exit\n" 100))
  100)

!(assertEqual
  (codex:unified-exec-write-stdin-request-max-output-tokens
    (codex-core-write-stdin-request "exit\n" 100))
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-process-store-processes
    (codex:unified-exec-process-manager-process-store
      (codex:unified-exec-process-manager-new 1)))
  ())

!(assertEqual
  (codex:unified-exec-process-manager-max-write-stdin-yield-time-ms
    (codex:unified-exec-process-manager-new 1))
  5000)

!(assertEqual
  (codex:unified-exec-process-manager-max-write-stdin-yield-time-ms
    (codex:unified-exec-process-manager-new 7000))
  7000)

!(assertEqual
  (codex:unified-exec-process-manager-max-write-stdin-yield-time-ms
    (codex:unified-exec-process-manager-default))
  300000)

!(assertEqual
  (codex:unified-exec-clamp-yield-time 1)
  250)

!(assertEqual
  (codex:unified-exec-clamp-yield-time 250)
  250)

!(assertEqual
  (codex:unified-exec-clamp-yield-time 10000)
  10000)

!(assertEqual
  (codex:unified-exec-clamp-yield-time 30000)
  30000)

!(assertEqual
  (codex:unified-exec-clamp-yield-time 30001)
  30000)

!(assertEqual
  (codex:unified-exec-resolve-max-tokens CodexAbsent)
  10000)

!(assertEqual
  (codex:unified-exec-resolve-max-tokens 50)
  50)

!(assertEqual
  (codex:unified-exec-write-stdin-yield-time-ms
    (codex:unified-exec-process-manager-new 12000)
    (codex-core-write-stdin-request "" 1))
  5000)

!(assertEqual
  (codex:unified-exec-write-stdin-yield-time-ms
    (codex:unified-exec-process-manager-new 12000)
    (codex-core-write-stdin-request "" 8000))
  8000)

!(assertEqual
  (codex:unified-exec-write-stdin-yield-time-ms
    (codex:unified-exec-process-manager-new 12000)
    (codex-core-write-stdin-request "" 20000))
  12000)

!(assertEqual
  (codex:unified-exec-write-stdin-yield-time-ms
    (codex:unified-exec-process-manager-new 12000)
    (codex-core-write-stdin-request "x" 1))
  250)

!(assertEqual
  (codex:unified-exec-write-stdin-yield-time-ms
    (codex:unified-exec-process-manager-new 12000)
    (codex-core-write-stdin-request "x" 40000))
  30000)

!(assertEqual
  (codex:unified-exec-hex-nibble 0)
  "0")

!(assertEqual
  (codex:unified-exec-hex-nibble 9)
  "9")

!(assertEqual
  (codex:unified-exec-hex-nibble 10)
  "a")

!(assertEqual
  (codex:unified-exec-hex-nibble 15)
  "f")

!(assertEqual
  (codex:unified-exec-hex-nibble 16)
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-generate-chunk-id-from-nibbles
    (0 1 10 11 14 15))
  "01abef")

!(assertEqual
  (codex:unified-exec-generate-chunk-id-from-nibbles
    (15 15 15 15 15 15))
  "ffffff")

!(assertEqual
  (codex:unified-exec-generate-chunk-id-from-nibbles
    (0 1 2 3 4))
  CodexAbsent)

!(assertEqual
  (codex:unified-exec-generate-chunk-id-from-nibbles
    (0 1 2 3 4 16))
  CodexAbsent)
