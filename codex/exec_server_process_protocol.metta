; Rust-faithful exec-server process protocol slice.
;
; This ports the deterministic wire-shape behavior from:
; - openai-codex/codex-rs/exec-server/src/protocol.rs
;   - JSON-RPC method constants
;   - ByteChunk transparent base64 JSON surface
;   - InitializeParams / InitializeResponse
;   - ExecParams / ExecEnvPolicy / ExecResponse
;   - ReadParams / ProcessOutputChunk / ReadResponse
;   - WriteParams / WriteStatus / WriteResponse
;   - TerminateParams / TerminateResponse
;   - ExecOutputStream
;   - ExecOutputDeltaNotification / ExecExitedNotification /
;     ExecClosedNotification
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust stores `ByteChunk` as `Vec<u8>` and serializes it with standard
;   base64. This CeTTa slice carries the current bytes as text and applies
;   `str-base64-encode` at JSON projection time. This preserves visible JSON
;   behavior for UTF-8/ASCII payloads; arbitrary byte-vector preservation
;   belongs with the future byte-vector protocol library.
; - Rust stores `HashMap<String, String>` for `env` and `set`. This CeTTa
;   slice uses ordered string-pair lists and projects them to the same JSON
;   object shape. JSON object member order is not semantic in Rust.

!(import! &self json)
!(import! &self list)
!(import! &self str)
!(import! &self exec_server_process_id)

(= (codex:exec-server-protocol-initialize-method)
   "initialize")

(= (codex:exec-server-protocol-initialized-method)
   "initialized")

(= (codex:exec-server-protocol-exec-method)
   "process/start")

(= (codex:exec-server-protocol-exec-read-method)
   "process/read")

(= (codex:exec-server-protocol-exec-write-method)
   "process/write")

(= (codex:exec-server-protocol-exec-terminate-method)
   "process/terminate")

(= (codex:exec-server-protocol-exec-output-delta-method)
   "process/output")

(= (codex:exec-server-protocol-exec-exited-method)
   "process/exited")

(= (codex:exec-server-protocol-exec-closed-method)
   "process/closed")

(= (codex:exec-server-protocol-fs-read-file-method)
   "fs/readFile")

(= (codex:exec-server-protocol-fs-write-file-method)
   "fs/writeFile")

(= (codex:exec-server-protocol-fs-create-directory-method)
   "fs/createDirectory")

(= (codex:exec-server-protocol-fs-get-metadata-method)
   "fs/getMetadata")

(= (codex:exec-server-protocol-fs-read-directory-method)
   "fs/readDirectory")

(= (codex:exec-server-protocol-fs-remove-method)
   "fs/remove")

(= (codex:exec-server-protocol-fs-copy-method)
   "fs/copy")

(= (codex:exec-server-protocol-http-request-method)
   "http/request")

(= (codex:exec-server-protocol-http-request-body-delta-method)
   "http/request/bodyDelta")

(= (codex:exec-server-protocol-json-number $value)
   (JsonNumber (format-args "{}" ($value))))

(= (codex:exec-server-protocol-json-option-string $value)
   (if (== $value CodexAbsent)
       JsonNull
       (JsonString $value)))

(= (codex:exec-server-protocol-json-option-number $value)
   (if (== $value CodexAbsent)
       JsonNull
       (codex:exec-server-protocol-json-number $value)))

(= (codex:exec-server-protocol-json-option-value $value)
   (if (== $value CodexAbsent)
       JsonNull
       $value))

(= (codex:exec-server-protocol-json-string-array $items)
   (JsonArray (map-atom-strict $items $item (JsonString $item))))

(= (codex:exec-server-protocol-string-pair $key $value)
   (CodexExecServerProtocolStringPair $key $value))

(= (codex:exec-server-protocol-string-pair-key
      (CodexExecServerProtocolStringPair $key $value))
   $key)

(= (codex:exec-server-protocol-string-pair-value
      (CodexExecServerProtocolStringPair $key $value))
   $value)

(= (codex:exec-server-protocol-string-pairs-json-pairs ())
   ())

(= (codex:exec-server-protocol-string-pairs-json-pairs $pairs)
   (let $head (list:first $pairs)
     (list:append
       ((JsonPair
          (codex:exec-server-protocol-string-pair-key $head)
          (JsonString
            (codex:exec-server-protocol-string-pair-value $head))))
       (codex:exec-server-protocol-string-pairs-json-pairs
         (list:rest $pairs)))))

(= (codex:exec-server-protocol-string-map-json $pairs)
   (JsonObject
     (codex:exec-server-protocol-string-pairs-json-pairs $pairs)))

(= (codex:exec-server-byte-chunk $bytes)
   (CodexExecServerByteChunk $bytes))

(= (codex:exec-server-byte-chunk-into-inner
      (CodexExecServerByteChunk $bytes))
   $bytes)

(= (codex:exec-server-byte-chunk-json $chunk)
   (JsonString
     (str-base64-encode
       (codex:exec-server-byte-chunk-into-inner $chunk))))

(= (codex:exec-server-protocol-process-id-json $process-id)
   (JsonString (codex:exec-server-process-id-as-str $process-id)))

(= (codex:exec-server-initialize-params
      $client-name
      $resume-session-id)
   (CodexExecServerInitializeParams $client-name $resume-session-id))

(= (codex:exec-server-initialize-params-client-name
      (CodexExecServerInitializeParams $client-name $resume-session-id))
   $client-name)

(= (codex:exec-server-initialize-params-resume-session-id
      (CodexExecServerInitializeParams $client-name $resume-session-id))
   $resume-session-id)

(= (codex:exec-server-initialize-params-json
      (CodexExecServerInitializeParams $client-name $resume-session-id))
   (JsonObject
     ((JsonPair "clientName" (JsonString $client-name))
      (JsonPair
        "resumeSessionId"
        (codex:exec-server-protocol-json-option-string
          $resume-session-id)))))

(= (codex:exec-server-initialize-response $session-id)
   (CodexExecServerInitializeResponse $session-id))

(= (codex:exec-server-initialize-response-session-id
      (CodexExecServerInitializeResponse $session-id))
   $session-id)

(= (codex:exec-server-initialize-response-json
      (CodexExecServerInitializeResponse $session-id))
   (JsonObject
     ((JsonPair "sessionId" (JsonString $session-id)))))

(= (codex:exec-server-shell-env-inherit-core)
   (CodexExecServerShellEnvironmentPolicyInheritCore))

(= (codex:exec-server-shell-env-inherit-all)
   (CodexExecServerShellEnvironmentPolicyInheritAll))

(= (codex:exec-server-shell-env-inherit-none)
   (CodexExecServerShellEnvironmentPolicyInheritNone))

(= (codex:exec-server-shell-env-inherit-json-string
      (CodexExecServerShellEnvironmentPolicyInheritCore))
   "core")

(= (codex:exec-server-shell-env-inherit-json-string
      (CodexExecServerShellEnvironmentPolicyInheritAll))
   "all")

(= (codex:exec-server-shell-env-inherit-json-string
      (CodexExecServerShellEnvironmentPolicyInheritNone))
   "none")

(= (codex:exec-server-exec-env-policy
      $inherit
      $ignore-default-excludes
      $exclude
      $set
      $include-only)
   (CodexExecServerExecEnvPolicy
     $inherit
     $ignore-default-excludes
     $exclude
     $set
     $include-only))

(= (codex:exec-server-exec-env-policy-inherit
      (CodexExecServerExecEnvPolicy
        $inherit
        $ignore-default-excludes
        $exclude
        $set
        $include-only))
   $inherit)

(= (codex:exec-server-exec-env-policy-json
      (CodexExecServerExecEnvPolicy
        $inherit
        $ignore-default-excludes
        $exclude
        $set
        $include-only))
   (JsonObject
     ((JsonPair
        "inherit"
        (JsonString
          (codex:exec-server-shell-env-inherit-json-string $inherit)))
      (JsonPair "ignoreDefaultExcludes" (JsonBool $ignore-default-excludes))
      (JsonPair
        "exclude"
        (codex:exec-server-protocol-json-string-array $exclude))
      (JsonPair "set" (codex:exec-server-protocol-string-map-json $set))
      (JsonPair
        "includeOnly"
        (codex:exec-server-protocol-json-string-array $include-only)))))

(= (codex:exec-server-exec-params
      $process-id
      $argv
      $cwd
      $env-policy
      $env
      $tty
      $pipe-stdin
      $arg0)
   (CodexExecServerExecParams
     $process-id
     $argv
     $cwd
     $env-policy
     $env
     $tty
     $pipe-stdin
     $arg0))

(= (codex:exec-server-exec-params-process-id
      (CodexExecServerExecParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   $process-id)

(= (codex:exec-server-exec-params-json
      (CodexExecServerExecParams
        $process-id
        $argv
        $cwd
        $env-policy
        $env
        $tty
        $pipe-stdin
        $arg0))
   (JsonObject
     ((JsonPair
        "processId"
        (codex:exec-server-protocol-process-id-json $process-id))
      (JsonPair "argv" (codex:exec-server-protocol-json-string-array $argv))
      (JsonPair "cwd" (JsonString $cwd))
      (JsonPair
        "envPolicy"
        (codex:exec-server-protocol-json-option-value
          (if (== $env-policy CodexAbsent)
              CodexAbsent
              (codex:exec-server-exec-env-policy-json $env-policy))))
      (JsonPair "env" (codex:exec-server-protocol-string-map-json $env))
      (JsonPair "tty" (JsonBool $tty))
      (JsonPair "pipeStdin" (JsonBool $pipe-stdin))
      (JsonPair
        "arg0"
        (codex:exec-server-protocol-json-option-string $arg0)))))

(= (codex:exec-server-exec-response $process-id)
   (CodexExecServerExecResponse $process-id))

(= (codex:exec-server-exec-response-process-id
      (CodexExecServerExecResponse $process-id))
   $process-id)

(= (codex:exec-server-exec-response-json
      (CodexExecServerExecResponse $process-id))
   (JsonObject
     ((JsonPair
        "processId"
        (codex:exec-server-protocol-process-id-json $process-id)))))

(= (codex:exec-server-read-params
      $process-id
      $after-seq
      $max-bytes
      $wait-ms)
   (CodexExecServerReadParams
     $process-id
     $after-seq
     $max-bytes
     $wait-ms))

(= (codex:exec-server-read-params-json
      (CodexExecServerReadParams
        $process-id
        $after-seq
        $max-bytes
        $wait-ms))
   (JsonObject
     ((JsonPair
        "processId"
        (codex:exec-server-protocol-process-id-json $process-id))
      (JsonPair
        "afterSeq"
        (codex:exec-server-protocol-json-option-number $after-seq))
      (JsonPair
        "maxBytes"
        (codex:exec-server-protocol-json-option-number $max-bytes))
      (JsonPair
        "waitMs"
        (codex:exec-server-protocol-json-option-number $wait-ms)))))

(= (codex:exec-server-output-stream-stdout)
   (CodexExecServerExecOutputStreamStdout))

(= (codex:exec-server-output-stream-stderr)
   (CodexExecServerExecOutputStreamStderr))

(= (codex:exec-server-output-stream-pty)
   (CodexExecServerExecOutputStreamPty))

(= (codex:exec-server-output-stream-json-string
      (CodexExecServerExecOutputStreamStdout))
   "stdout")

(= (codex:exec-server-output-stream-json-string
      (CodexExecServerExecOutputStreamStderr))
   "stderr")

(= (codex:exec-server-output-stream-json-string
      (CodexExecServerExecOutputStreamPty))
   "pty")

(= (codex:exec-server-process-output-chunk
      $seq
      $stream
      $chunk)
   (CodexExecServerProcessOutputChunk $seq $stream $chunk))

(= (codex:exec-server-process-output-chunk-seq
      (CodexExecServerProcessOutputChunk $seq $stream $chunk))
   $seq)

(= (codex:exec-server-process-output-chunk-stream
      (CodexExecServerProcessOutputChunk $seq $stream $chunk))
   $stream)

(= (codex:exec-server-process-output-chunk-chunk
      (CodexExecServerProcessOutputChunk $seq $stream $chunk))
   $chunk)

(= (codex:exec-server-process-output-chunk-json
      (CodexExecServerProcessOutputChunk $seq $stream $chunk))
   (JsonObject
     ((JsonPair "seq" (codex:exec-server-protocol-json-number $seq))
      (JsonPair
        "stream"
        (JsonString
          (codex:exec-server-output-stream-json-string $stream)))
      (JsonPair
        "chunk"
        (codex:exec-server-byte-chunk-json $chunk)))))

(= (codex:exec-server-process-output-chunks-json $chunks)
   (JsonArray
     (map-atom-strict
       $chunks
       $chunk
       (codex:exec-server-process-output-chunk-json $chunk))))

(= (codex:exec-server-read-response
      $chunks
      $next-seq
      $exited
      $exit-code
      $closed
      $failure)
   (CodexExecServerReadResponse
     $chunks
     $next-seq
     $exited
     $exit-code
     $closed
     $failure))

(= (codex:exec-server-read-response-json
      (CodexExecServerReadResponse
        $chunks
        $next-seq
        $exited
        $exit-code
        $closed
        $failure))
   (JsonObject
     ((JsonPair
        "chunks"
        (codex:exec-server-process-output-chunks-json $chunks))
      (JsonPair "nextSeq" (codex:exec-server-protocol-json-number $next-seq))
      (JsonPair "exited" (JsonBool $exited))
      (JsonPair
        "exitCode"
        (codex:exec-server-protocol-json-option-number $exit-code))
      (JsonPair "closed" (JsonBool $closed))
      (JsonPair
        "failure"
        (codex:exec-server-protocol-json-option-string $failure)))))

(= (codex:exec-server-write-params $process-id $chunk)
   (CodexExecServerWriteParams $process-id $chunk))

(= (codex:exec-server-write-params-json
      (CodexExecServerWriteParams $process-id $chunk))
   (JsonObject
     ((JsonPair
        "processId"
        (codex:exec-server-protocol-process-id-json $process-id))
      (JsonPair
        "chunk"
        (codex:exec-server-byte-chunk-json $chunk)))))

(= (codex:exec-server-write-status-accepted)
   (CodexExecServerWriteStatusAccepted))

(= (codex:exec-server-write-status-unknown-process)
   (CodexExecServerWriteStatusUnknownProcess))

(= (codex:exec-server-write-status-stdin-closed)
   (CodexExecServerWriteStatusStdinClosed))

(= (codex:exec-server-write-status-starting)
   (CodexExecServerWriteStatusStarting))

(= (codex:exec-server-write-status-json-string
      (CodexExecServerWriteStatusAccepted))
   "accepted")

(= (codex:exec-server-write-status-json-string
      (CodexExecServerWriteStatusUnknownProcess))
   "unknownProcess")

(= (codex:exec-server-write-status-json-string
      (CodexExecServerWriteStatusStdinClosed))
   "stdinClosed")

(= (codex:exec-server-write-status-json-string
      (CodexExecServerWriteStatusStarting))
   "starting")

(= (codex:exec-server-write-response $status)
   (CodexExecServerWriteResponse $status))

(= (codex:exec-server-write-response-status
      (CodexExecServerWriteResponse $status))
   $status)

(= (codex:exec-server-write-response-json
      (CodexExecServerWriteResponse $status))
   (JsonObject
     ((JsonPair
        "status"
        (JsonString
          (codex:exec-server-write-status-json-string $status))))))

(= (codex:exec-server-terminate-params $process-id)
   (CodexExecServerTerminateParams $process-id))

(= (codex:exec-server-terminate-params-json
      (CodexExecServerTerminateParams $process-id))
   (JsonObject
     ((JsonPair
        "processId"
        (codex:exec-server-protocol-process-id-json $process-id)))))

(= (codex:exec-server-terminate-response $running)
   (CodexExecServerTerminateResponse $running))

(= (codex:exec-server-terminate-response-running
      (CodexExecServerTerminateResponse $running))
   $running)

(= (codex:exec-server-terminate-response-json
      (CodexExecServerTerminateResponse $running))
   (JsonObject
     ((JsonPair "running" (JsonBool $running)))))

(= (codex:exec-server-output-delta-notification
      $process-id
      $seq
      $stream
      $chunk)
   (CodexExecServerExecOutputDeltaNotification
     $process-id
     $seq
     $stream
     $chunk))

(= (codex:exec-server-output-delta-notification-json
      (CodexExecServerExecOutputDeltaNotification
        $process-id
        $seq
        $stream
        $chunk))
   (JsonObject
     ((JsonPair
        "processId"
        (codex:exec-server-protocol-process-id-json $process-id))
      (JsonPair "seq" (codex:exec-server-protocol-json-number $seq))
      (JsonPair
        "stream"
        (JsonString
          (codex:exec-server-output-stream-json-string $stream)))
      (JsonPair
        "chunk"
        (codex:exec-server-byte-chunk-json $chunk)))))

(= (codex:exec-server-exited-notification
      $process-id
      $seq
      $exit-code)
   (CodexExecServerExecExitedNotification
     $process-id
     $seq
     $exit-code))

(= (codex:exec-server-exited-notification-json
      (CodexExecServerExecExitedNotification
        $process-id
        $seq
        $exit-code))
   (JsonObject
     ((JsonPair
        "processId"
        (codex:exec-server-protocol-process-id-json $process-id))
      (JsonPair "seq" (codex:exec-server-protocol-json-number $seq))
      (JsonPair
        "exitCode"
        (codex:exec-server-protocol-json-number $exit-code)))))

(= (codex:exec-server-closed-notification $process-id $seq)
   (CodexExecServerExecClosedNotification $process-id $seq))

(= (codex:exec-server-closed-notification-json
      (CodexExecServerExecClosedNotification $process-id $seq))
   (JsonObject
     ((JsonPair
        "processId"
        (codex:exec-server-protocol-process-id-json $process-id))
      (JsonPair "seq" (codex:exec-server-protocol-json-number $seq)))))
