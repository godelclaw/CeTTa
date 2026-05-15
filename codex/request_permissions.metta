; Visible request_permissions slice for the restarted Codex port.
;
; This ports the narrow request_permissions path from:
; - openai-codex/codex-rs/protocol/src/request_permissions.rs
; - openai-codex/codex-rs/tools/src/local_tool.rs
; - openai-codex/codex-rs/core/src/tools/handlers/request_permissions.rs
; - openai-codex/codex-rs/core/src/session/mod.rs
; - openai-codex/codex-rs/core/src/tools/handlers/{mod.rs,apply_patch.rs}
;
; Covered in this increment:
; - Rust-shaped request/response/event protocol values and JSON rendering
; - permission-profile parsing, normalization, merge, intersection, and
;   turn/session grant recording
; - approval-policy short-circuit and cancellation behavior
; - same-turn apply_patch carry-over, including strict-auto-review propagation
;
; Required slice-local deviations from Rust, documented for later audit:
; - Rust normalizes filesystem permissions with
;   `canonicalize_preserving_symlinks` and supports canonical entry/glob/special
;   path variants. The visible CeTTa slice currently exposes only the legacy
;   `read`/`write` root lists from the public tool schema, and it normalizes
;   them lexically with `path-join` / `path-normalize`.
; - Rust records granted permissions into async session/turn state and applies
;   `permissions_preapproved` inside the apply_patch runtime/orchestrator. The
;   visible CeTTa slice does not have that session layer yet, so it carries an
;   explicit request-permissions state value and applies the strict/preapproved
;   approval transitions at the visible apply_patch boundary instead.
; - Rust applies request_permissions grants to later shell-like commands in
;   general. The visible CeTTa command runner is still synchronous and
;   unsandboxed, so this slice can only surface the carry-over in the visible
;   apply_patch lane for now.

!(import! &self approval)
!(import! &self apply_patch)
!(import! &self json)
!(import! &self list)
!(import! &self path)
!(import! &self protocol)
!(import! &self str)
!(import! &self system)

(= (codex:request-permissions-tool-name)
   "request_permissions")

(= (codex:request-permissions-unsupported-payload-message)
   "request_permissions handler received unsupported payload")

(= (codex:request-permissions-missing-permissions-message)
   "request_permissions requires at least one permission")

(= (codex:request-permissions-cancelled-message)
   "request_permissions was cancelled before receiving a response")

(= (codex:request-permissions-tool-description)
   "Request additional filesystem or network permissions from the user and wait for the client to grant a subset of the requested permission profile. Granted permissions apply automatically to later shell-like commands in the current turn, or for the rest of the session if the client approves them at session scope.")

(= (codex:permission-grant-scope-turn)
   "turn")

(= (codex:permission-grant-scope-session)
   "session")

(= (codex:request-permissions-network $enabled)
   (CodexRequestPermissionsNetwork $enabled))

(= (codex:request-permissions-file-system $read $write)
   (CodexRequestPermissionsFileSystem $read $write))

(= (codex:request-permission-profile $network $file-system)
   (CodexRequestPermissionProfile $network $file-system))

(= (codex:request-permissions-args $reason $permissions)
   (CodexRequestPermissionsArgs $reason $permissions))

(= (codex:request-permissions-args-without-reason $permissions)
   (CodexRequestPermissionsArgs CodexAbsent $permissions))

(= (codex:request-permissions-response $permissions $scope $strict-auto-review)
   (CodexRequestPermissionsResponse $permissions $scope $strict-auto-review))

(= (codex:request-permissions-event
      $call-id
      $turn-id
      $reason
      $permissions
      $cwd)
   (CodexRequestPermissionsEvent
     $call-id
     $turn-id
     $reason
     $permissions
     $cwd))

(= (codex:request-permissions-function-payload $arguments)
   (CodexRequestPermissionsPayloadFunction $arguments))

(= (codex:request-permissions-unsupported-payload $payload-kind)
   (CodexRequestPermissionsPayloadUnsupported $payload-kind))

(= (codex:request-permissions-response-behavior-return $response)
   (CodexRequestPermissionsResponseBehaviorReturn $response))

(= (codex:request-permissions-response-behavior-cancel)
   (CodexRequestPermissionsResponseBehaviorCancel))

(= (codex:request-permissions-handler-context
      $approval-policy
      $turn-id
      $cwd
      $response-behavior)
   (CodexRequestPermissionsHandlerContext
     $approval-policy
     $turn-id
     $cwd
     $response-behavior))

(= (codex:default-request-permissions-handler-context)
   (codex:request-permissions-handler-context
     (codex:ask-for-approval-never)
     "turn-local"
     (system-cwd)
     (codex:request-permissions-response-behavior-cancel)))

(= (codex:request-permissions-state
      $session-permissions
      $turn-permissions
      $turn-strict-auto-review)
   (CodexRequestPermissionsState
     $session-permissions
     $turn-permissions
     $turn-strict-auto-review))

(= (codex:empty-request-permissions-state)
   (codex:request-permissions-state CodexAbsent CodexAbsent False))

(= (codex:request-permissions-tool-call-result $item $state)
   (CodexRequestPermissionsToolCallResult $item $state))

(= (codex:request-permissions-effective-additional-permissions
      $file-system-sandbox-policy
      $additional-permissions
      $permissions-preapproved)
   (CodexRequestPermissionsEffectiveAdditionalPermissions
     $file-system-sandbox-policy
     $additional-permissions
     $permissions-preapproved))

(= (codex:request-permissions-network-enabled
      (CodexRequestPermissionsNetwork $enabled))
   $enabled)

(= (codex:request-permissions-file-system-read
      (CodexRequestPermissionsFileSystem $read $write))
   $read)

(= (codex:request-permissions-file-system-write
      (CodexRequestPermissionsFileSystem $read $write))
   $write)

(= (codex:request-permission-profile-network
      (CodexRequestPermissionProfile $network $file-system))
   $network)

(= (codex:request-permission-profile-file-system
      (CodexRequestPermissionProfile $network $file-system))
   $file-system)

(= (codex:request-permissions-args-reason
      (CodexRequestPermissionsArgs $reason $permissions))
   $reason)

(= (codex:request-permissions-args-permissions
      (CodexRequestPermissionsArgs $reason $permissions))
   $permissions)

(= (codex:request-permissions-response-permissions
      (CodexRequestPermissionsResponse $permissions $scope $strict-auto-review))
   $permissions)

(= (codex:request-permissions-response-scope
      (CodexRequestPermissionsResponse $permissions $scope $strict-auto-review))
   $scope)

(= (codex:request-permissions-response-strict-auto-review
      (CodexRequestPermissionsResponse $permissions $scope $strict-auto-review))
   $strict-auto-review)

(= (codex:request-permissions-event-call-id
      (CodexRequestPermissionsEvent
        $call-id
        $turn-id
        $reason
        $permissions
        $cwd))
   $call-id)

(= (codex:request-permissions-event-turn-id
      (CodexRequestPermissionsEvent
        $call-id
        $turn-id
        $reason
        $permissions
        $cwd))
   $turn-id)

(= (codex:request-permissions-event-reason
      (CodexRequestPermissionsEvent
        $call-id
        $turn-id
        $reason
        $permissions
        $cwd))
   $reason)

(= (codex:request-permissions-event-permissions
      (CodexRequestPermissionsEvent
        $call-id
        $turn-id
        $reason
        $permissions
        $cwd))
   $permissions)

(= (codex:request-permissions-event-cwd
      (CodexRequestPermissionsEvent
        $call-id
        $turn-id
        $reason
        $permissions
        $cwd))
   $cwd)

(= (codex:request-permissions-handler-context-approval-policy
      (CodexRequestPermissionsHandlerContext
        $approval-policy
        $turn-id
        $cwd
        $response-behavior))
   $approval-policy)

(= (codex:request-permissions-handler-context-turn-id
      (CodexRequestPermissionsHandlerContext
        $approval-policy
        $turn-id
        $cwd
        $response-behavior))
   $turn-id)

(= (codex:request-permissions-handler-context-cwd
      (CodexRequestPermissionsHandlerContext
        $approval-policy
        $turn-id
        $cwd
        $response-behavior))
   $cwd)

(= (codex:request-permissions-handler-context-response-behavior
      (CodexRequestPermissionsHandlerContext
        $approval-policy
        $turn-id
        $cwd
        $response-behavior))
   $response-behavior)

(= (codex:request-permissions-state-session-permissions
      (CodexRequestPermissionsState
        $session-permissions
        $turn-permissions
        $turn-strict-auto-review))
   $session-permissions)

(= (codex:request-permissions-state-turn-permissions
      (CodexRequestPermissionsState
        $session-permissions
        $turn-permissions
        $turn-strict-auto-review))
   $turn-permissions)

(= (codex:request-permissions-state-turn-strict-auto-review
      (CodexRequestPermissionsState
        $session-permissions
        $turn-permissions
        $turn-strict-auto-review))
   $turn-strict-auto-review)

(= (codex:request-permissions-tool-call-result-item
      (CodexRequestPermissionsToolCallResult $item $state))
   $item)

(= (codex:request-permissions-tool-call-result-state
      (CodexRequestPermissionsToolCallResult $item $state))
   $state)

(= (codex:request-permissions-effective-additional-file-system-sandbox-policy
      (CodexRequestPermissionsEffectiveAdditionalPermissions
        $file-system-sandbox-policy
        $additional-permissions
        $permissions-preapproved))
   $file-system-sandbox-policy)

(= (codex:request-permissions-effective-additional-permissions-profile
      (CodexRequestPermissionsEffectiveAdditionalPermissions
        $file-system-sandbox-policy
        $additional-permissions
        $permissions-preapproved))
   $additional-permissions)

(= (codex:request-permissions-effective-additional-permissions-preapproved
      (CodexRequestPermissionsEffectiveAdditionalPermissions
        $file-system-sandbox-policy
        $additional-permissions
        $permissions-preapproved))
   $permissions-preapproved)

(= (codex:request-permissions-normalize-result-type
      (CodexRequestPermissionsNormalizeOk $args))
   "ok")

(= (codex:request-permissions-normalize-result-type
      (CodexRequestPermissionsNormalizeError $message))
   "error")

(= (codex:request-permissions-normalize-result-args
      (CodexRequestPermissionsNormalizeOk $args))
   $args)

(= (codex:request-permissions-normalize-result-message
      (CodexRequestPermissionsNormalizeError $message))
   $message)

(= (codex:request-permissions-handler-result-type $result)
   (let $resolved-result (eval $result)
     (case $resolved-result
       (((CodexRequestPermissionsHandlerOutput $event $output $state)
         "output")
        ((CodexRequestPermissionsHandlerCancelled $event $message)
         "cancelled")
        ((CodexRequestPermissionsHandlerError $message)
         "error")))))

(= (codex:request-permissions-handler-result-event $result)
   (let $resolved-result (eval $result)
     (case $resolved-result
       (((CodexRequestPermissionsHandlerOutput $event $output $state)
         $event)
        ((CodexRequestPermissionsHandlerCancelled $event $message)
         $event)
        ($other
         Empty)))))

(= (codex:request-permissions-handler-result-output-text $result)
   (let $resolved-result (eval $result)
     (case $resolved-result
       (((CodexRequestPermissionsHandlerOutput $event $output $state)
         $output)
        ($other
         Empty)))))

(= (codex:request-permissions-handler-result-state $result)
   (let $resolved-result (eval $result)
     (case $resolved-result
       (((CodexRequestPermissionsHandlerOutput $event $output $state)
         $state)
        ($other
         Empty)))))

(= (codex:request-permissions-handler-result-message $result)
   (let $resolved-result (eval $result)
     (case $resolved-result
       (((CodexRequestPermissionsHandlerCancelled $event $message)
         $message)
        ((CodexRequestPermissionsHandlerError $message)
         $message)
        ($other
         Empty)))))

(= (codex:request-permissions-json-object-optional-value $object $key)
   (case (json-object-get $object $key)
     ((Empty CodexAbsent)
      (JsonNull CodexAbsent)
      ($value $value))))

(= (codex:request-permissions-json-object-optional-string $object $key)
   (case (codex:request-permissions-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonString $text) $text))))

(= (codex:request-permissions-json-object-optional-bool $object $key)
   (case (codex:request-permissions-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonBool $value) $value))))

(= (codex:request-permissions-json-object-optional-object $object $key)
   (case (codex:request-permissions-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonObject $pairs) (JsonObject $pairs)))))

(= (codex:request-permissions-json-object-required-object $object $key)
   (json-object-get $object $key))

(= (codex:request-permissions-json-object-optional-array $object $key)
   (case (codex:request-permissions-json-object-optional-value $object $key)
     ((CodexAbsent CodexAbsent)
      ((JsonArray $items) $items))))

(= (codex:request-permissions-optional-string-json CodexAbsent)
   JsonNull)

(= (codex:request-permissions-optional-string-json $value)
   (JsonString $value))

(= (codex:is-request-permissions-network-empty? CodexAbsent)
   True)

(= (codex:is-request-permissions-network-empty?
      (CodexRequestPermissionsNetwork CodexAbsent))
   True)

(= (codex:is-request-permissions-network-empty?
      (CodexRequestPermissionsNetwork $enabled))
   False)

(= (codex:is-request-permissions-file-system-empty? CodexAbsent)
   True)

(= (codex:is-request-permissions-file-system-empty?
      (CodexRequestPermissionsFileSystem $read $write))
   (if (== (list:len $read) 0)
       (== (list:len $write) 0)
       False))

(= (codex:is-request-permission-profile-empty? CodexAbsent)
   True)

(= (codex:is-request-permission-profile-empty?
      (CodexRequestPermissionProfile $network $file-system))
   (if (codex:is-request-permissions-network-empty? $network)
       (codex:is-request-permissions-file-system-empty? $file-system)
       False))

(= (codex:is-string-in-list $needle ())
   False)

(= (codex:is-string-in-list $needle $items)
   (let ($head $tail) (decons-atom $items)
     (if (== $needle $head)
         True
         (codex:is-string-in-list $needle $tail))))

(= (codex:dedup-string-list $items)
   (codex:dedup-string-list-acc $items ()))

(= (codex:dedup-string-list-acc () $acc)
   $acc)

(= (codex:dedup-string-list-acc $items $acc)
   (let ($head $tail) (decons-atom $items)
     (codex:dedup-string-list-acc
       $tail
       (if (codex:is-string-in-list $head $acc)
           $acc
           (list:append $acc ($head))))))

(= (codex:normalized-request-permissions-path $cwd $path)
   (if (path-is-absolute? $path)
       (path-normalize $path)
       (path-join $cwd $path)))

(= (codex:normalize-request-permissions-path-list $cwd $paths)
   (codex:normalize-request-permissions-path-list-acc $cwd $paths ()))

(= (codex:normalize-request-permissions-path-list-acc $cwd () $acc)
   $acc)

(= (codex:normalize-request-permissions-path-list-acc $cwd $paths $acc)
   (let ($head $tail) (decons-atom $paths)
     (let $normalized (codex:normalized-request-permissions-path $cwd $head)
       (codex:normalize-request-permissions-path-list-acc
         $cwd
         $tail
         (if (codex:is-string-in-list $normalized $acc)
             $acc
             (list:append $acc ($normalized)))))))

(= (codex:append-dedup-string-lists $left $right)
   (codex:append-dedup-string-lists-acc $right $left))

(= (codex:append-dedup-string-lists-acc () $acc)
   $acc)

(= (codex:append-dedup-string-lists-acc $items $acc)
   (let ($head $tail) (decons-atom $items)
     (codex:append-dedup-string-lists-acc
       $tail
       (if (codex:is-string-in-list $head $acc)
           $acc
           (list:append $acc ($head))))))

(= (codex:request-permissions-string-array-json $items)
   (function
     (let $json-items
       (eval (map-atom $items $item (JsonString $item)))
       (return (JsonArray $json-items)))))

(= (codex:request-permissions-string-array-from-json-items $items)
   (function
     (let $strings
       (eval (map-atom $items $item (json-string-value $item)))
       (return $strings))))

(= (codex:request-permissions-string-array-from-optional-json $items)
   (if (== $items CodexAbsent)
       ()
       (codex:request-permissions-string-array-from-json-items $items)))

(= (codex:request-permissions-network-json
      (CodexRequestPermissionsNetwork $enabled))
   (if (== $enabled CodexAbsent)
       (JsonObject ())
       (JsonObject
         ((JsonPair "enabled" (JsonBool $enabled))))))

(= (codex:request-permissions-file-system-json
      (CodexRequestPermissionsFileSystem $read $write))
   (if (== (list:len $read) 0)
       (if (== (list:len $write) 0)
           (JsonObject ())
           (JsonObject
             ((JsonPair "write"
                (codex:request-permissions-string-array-json $write)))))
       (if (== (list:len $write) 0)
           (JsonObject
             ((JsonPair "read"
                (codex:request-permissions-string-array-json $read))))
           (JsonObject
             ((JsonPair "read"
                (codex:request-permissions-string-array-json $read))
              (JsonPair "write"
                (codex:request-permissions-string-array-json $write)))))))

(= (codex:request-permission-profile-json CodexAbsent)
   (JsonObject ()))

(= (codex:request-permission-profile-json
      (CodexRequestPermissionProfile $network $file-system))
   (if (== $network CodexAbsent)
       (if (== $file-system CodexAbsent)
           (JsonObject ())
           (JsonObject
             ((JsonPair "file_system"
                (codex:request-permissions-file-system-json $file-system)))))
       (if (== $file-system CodexAbsent)
           (JsonObject
             ((JsonPair "network"
                (codex:request-permissions-network-json $network))))
           (JsonObject
             ((JsonPair "network"
                (codex:request-permissions-network-json $network))
              (JsonPair "file_system"
                (codex:request-permissions-file-system-json $file-system)))))))

(= (codex:request-permissions-args-json
      (CodexRequestPermissionsArgs $reason $permissions))
   (if (== $reason CodexAbsent)
       (JsonObject
         ((JsonPair "permissions"
            (codex:request-permission-profile-json $permissions))))
       (JsonObject
         ((JsonPair "reason" (JsonString $reason))
          (JsonPair "permissions"
            (codex:request-permission-profile-json $permissions))))))

(= (codex:request-permissions-response-json
      (CodexRequestPermissionsResponse $permissions $scope $strict-auto-review))
   (if $strict-auto-review
       (JsonObject
         ((JsonPair "permissions"
            (codex:request-permission-profile-json $permissions))
          (JsonPair "scope" (JsonString $scope))
          (JsonPair "strict_auto_review" (JsonBool True))))
       (JsonObject
         ((JsonPair "permissions"
            (codex:request-permission-profile-json $permissions))
          (JsonPair "scope" (JsonString $scope))))))

(= (codex:request-permissions-event-json
      (CodexRequestPermissionsEvent
        $call-id
        $turn-id
        $reason
        $permissions
        $cwd))
   (if (== $reason CodexAbsent)
       (JsonObject
         ((JsonPair "call_id" (JsonString $call-id))
          (JsonPair "turn_id" (JsonString $turn-id))
          (JsonPair "permissions"
            (codex:request-permission-profile-json $permissions))
          (JsonPair "cwd" (JsonString $cwd))))
       (JsonObject
         ((JsonPair "call_id" (JsonString $call-id))
          (JsonPair "turn_id" (JsonString $turn-id))
          (JsonPair "reason" (JsonString $reason))
          (JsonPair "permissions"
            (codex:request-permission-profile-json $permissions))
          (JsonPair "cwd" (JsonString $cwd))))))

(= (codex:request-permissions-network-from-json $json)
   (if (== $json CodexAbsent)
       CodexAbsent
       (codex:request-permissions-network
         (codex:request-permissions-json-object-optional-bool $json "enabled"))))

(= (codex:request-permissions-file-system-from-json $json)
   (if (== $json CodexAbsent)
       CodexAbsent
       (codex:request-permissions-file-system
         (codex:request-permissions-string-array-from-optional-json
           (codex:request-permissions-json-object-optional-array $json "read"))
         (codex:request-permissions-string-array-from-optional-json
           (codex:request-permissions-json-object-optional-array $json "write")))))

(= (codex:request-permission-profile-from-json $json)
   (codex:request-permission-profile
     (codex:request-permissions-network-from-json
       (codex:request-permissions-json-object-optional-object $json "network"))
     (codex:request-permissions-file-system-from-json
       (codex:request-permissions-json-object-optional-object
         $json
         "file_system"))))

(= (codex:parse-request-permissions-args $input)
   (let $json (json-parse $input)
     (codex:request-permissions-args
       (codex:request-permissions-json-object-optional-string $json "reason")
       (codex:request-permission-profile-from-json
         (codex:request-permissions-json-object-required-object
           $json
           "permissions")))))

(= (codex:normalize-request-permissions-network CodexAbsent)
   CodexAbsent)

(= (codex:normalize-request-permissions-network
      (CodexRequestPermissionsNetwork CodexAbsent))
   CodexAbsent)

(= (codex:normalize-request-permissions-network
      (CodexRequestPermissionsNetwork $enabled))
   (CodexRequestPermissionsNetwork $enabled))

(= (codex:normalize-request-permissions-file-system $cwd CodexAbsent)
   CodexAbsent)

(= (codex:normalize-request-permissions-file-system
      $cwd
      (CodexRequestPermissionsFileSystem $read $write))
   (let $normalized-read (codex:normalize-request-permissions-path-list $cwd $read)
     (let $normalized-write (codex:normalize-request-permissions-path-list $cwd $write)
       (if (== (list:len $normalized-read) 0)
           (if (== (list:len $normalized-write) 0)
               CodexAbsent
               (CodexRequestPermissionsFileSystem () $normalized-write))
           (CodexRequestPermissionsFileSystem
             $normalized-read
             $normalized-write)))))

(= (codex:request-permission-profile-or-absent CodexAbsent CodexAbsent)
   CodexAbsent)

(= (codex:request-permission-profile-or-absent $network $file-system)
   (CodexRequestPermissionProfile $network $file-system))

(= (codex:normalize-request-permission-profile $cwd CodexAbsent)
   CodexAbsent)

(= (codex:normalize-request-permission-profile
      $cwd
      (CodexRequestPermissionProfile $network $file-system))
   (codex:request-permission-profile-or-absent
     (codex:normalize-request-permissions-network $network)
     (codex:normalize-request-permissions-file-system $cwd $file-system)))

(= (codex:normalize-request-permissions-args
      $cwd
      (CodexRequestPermissionsArgs $reason $permissions))
   (let $normalized-permissions
     (codex:normalize-request-permission-profile $cwd $permissions)
     (if (codex:is-request-permission-profile-empty? $normalized-permissions)
         (CodexRequestPermissionsNormalizeError
           (codex:request-permissions-missing-permissions-message))
         (CodexRequestPermissionsNormalizeOk
           (CodexRequestPermissionsArgs $reason $normalized-permissions)))))

(= (codex:is-request-permissions-network-enabled? CodexAbsent)
   False)

(= (codex:is-request-permissions-network-enabled?
      (CodexRequestPermissionsNetwork True))
   True)

(= (codex:is-request-permissions-network-enabled?
      (CodexRequestPermissionsNetwork False))
   False)

(= (codex:merge-request-permissions-network $left $right)
   (if (or
         (codex:is-request-permissions-network-enabled? $left)
         (codex:is-request-permissions-network-enabled? $right))
       (codex:request-permissions-network True)
       CodexAbsent))

(= (codex:merge-request-permissions-file-system CodexAbsent CodexAbsent)
   CodexAbsent)

(= (codex:merge-request-permissions-file-system CodexAbsent $file-system)
   $file-system)

(= (codex:merge-request-permissions-file-system $file-system CodexAbsent)
   $file-system)

(= (codex:merge-request-permissions-file-system
      (CodexRequestPermissionsFileSystem $left-read $left-write)
      (CodexRequestPermissionsFileSystem $right-read $right-write))
   (let $merged-read (codex:append-dedup-string-lists $left-read $right-read)
     (let $merged-write (codex:append-dedup-string-lists $left-write $right-write)
       (if (== (list:len $merged-read) 0)
           (if (== (list:len $merged-write) 0)
               CodexAbsent
               (CodexRequestPermissionsFileSystem () $merged-write))
           (CodexRequestPermissionsFileSystem $merged-read $merged-write)))))

(= (codex:merge-request-permission-profiles CodexAbsent CodexAbsent)
   CodexAbsent)

(= (codex:merge-request-permission-profiles CodexAbsent $permissions)
   $permissions)

(= (codex:merge-request-permission-profiles $permissions CodexAbsent)
   $permissions)

(= (codex:merge-request-permission-profiles
      (CodexRequestPermissionProfile $left-network $left-file-system)
      (CodexRequestPermissionProfile $right-network $right-file-system))
   (codex:request-permission-profile-or-absent
     (codex:merge-request-permissions-network
       $left-network
       $right-network)
     (codex:merge-request-permissions-file-system
       $left-file-system
       $right-file-system)))

(= (codex:request-permissions-readable-roots CodexAbsent)
   ())

(= (codex:request-permissions-readable-roots
      (CodexRequestPermissionsFileSystem $read $write))
   (codex:append-dedup-string-lists $read $write))

(= (codex:is-request-permissions-path-within-roots $path $roots)
   (codex:is-path-within-any-root $path $roots))

(= (codex:filter-request-permissions-paths-within-roots () $roots)
   ())

(= (codex:filter-request-permissions-paths-within-roots $paths $roots)
   (let ($head $tail) (decons-atom $paths)
     (let $rest (codex:filter-request-permissions-paths-within-roots $tail $roots)
       (if (codex:is-request-permissions-path-within-roots $head $roots)
           (cons-atom $head $rest)
           $rest))))

(= (codex:intersect-request-permissions-file-system CodexAbsent CodexAbsent)
   CodexAbsent)

(= (codex:intersect-request-permissions-file-system CodexAbsent $granted)
   CodexAbsent)

(= (codex:intersect-request-permissions-file-system $requested CodexAbsent)
   CodexAbsent)

(= (codex:intersect-request-permissions-file-system
      (CodexRequestPermissionsFileSystem $requested-read $requested-write)
      (CodexRequestPermissionsFileSystem $granted-read $granted-write))
   (let $accepted-read
     (codex:filter-request-permissions-paths-within-roots
       $granted-read
       (codex:append-dedup-string-lists $requested-read $requested-write))
     (let $accepted-write
       (codex:filter-request-permissions-paths-within-roots
         $granted-write
         $requested-write)
       (if (== (list:len $accepted-read) 0)
           (if (== (list:len $accepted-write) 0)
               CodexAbsent
               (CodexRequestPermissionsFileSystem () $accepted-write))
           (CodexRequestPermissionsFileSystem
             $accepted-read
             $accepted-write)))))

(= (codex:intersect-request-permission-profiles $requested $granted $cwd)
   (if (or
         (== $requested CodexAbsent)
         (== $granted CodexAbsent))
       CodexAbsent
       (let $requested-network
         (codex:request-permission-profile-network $requested)
         (let $granted-network
           (codex:request-permission-profile-network $granted)
           (let $requested-file-system
             (codex:request-permission-profile-file-system $requested)
             (let $granted-file-system
               (codex:request-permission-profile-file-system $granted)
               (codex:request-permission-profile-or-absent
                 (if (and
                       (codex:is-request-permissions-network-enabled?
                         $requested-network)
                       (codex:is-request-permissions-network-enabled?
                         $granted-network))
                     (codex:request-permissions-network True)
                     CodexAbsent)
                 (codex:intersect-request-permissions-file-system
                   $requested-file-system
                   $granted-file-system))))))))

(= (codex:is-set-equal-string-lists $left $right)
   (if (== (list:len $left) (list:len $right))
       (codex:is-string-list-subset-of? $left $right)
       False))

(= (codex:is-string-list-subset-of? () $right)
   True)

(= (codex:is-string-list-subset-of? $left $right)
   (let ($head $tail) (decons-atom $left)
     (if (codex:is-string-in-list $head $right)
         (codex:is-string-list-subset-of? $tail $right)
         False)))

(= (codex:is-request-permissions-file-system-equivalent? CodexAbsent CodexAbsent)
   True)

(= (codex:is-request-permissions-file-system-equivalent? CodexAbsent $right)
   (codex:is-request-permissions-file-system-empty? $right))

(= (codex:is-request-permissions-file-system-equivalent? $left CodexAbsent)
   (codex:is-request-permissions-file-system-empty? $left))

(= (codex:is-request-permissions-file-system-equivalent?
      (CodexRequestPermissionsFileSystem $left-read $left-write)
      (CodexRequestPermissionsFileSystem $right-read $right-write))
   (if (codex:is-set-equal-string-lists $left-read $right-read)
       (codex:is-set-equal-string-lists $left-write $right-write)
       False))

(= (codex:is-request-permission-profile-equivalent? CodexAbsent CodexAbsent)
   True)

(= (codex:is-request-permission-profile-equivalent? CodexAbsent $right)
   (codex:is-request-permission-profile-empty? $right))

(= (codex:is-request-permission-profile-equivalent? $left CodexAbsent)
   (codex:is-request-permission-profile-empty? $left))

(= (codex:is-request-permission-profile-equivalent?
      (CodexRequestPermissionProfile $left-network $left-file-system)
      (CodexRequestPermissionProfile $right-network $right-file-system))
   (if (==
         (codex:is-request-permissions-network-enabled? $left-network)
         (codex:is-request-permissions-network-enabled? $right-network))
       (codex:is-request-permissions-file-system-equivalent?
         $left-file-system
         $right-file-system)
       False))

(= (codex:is-request-permissions-preapproved CodexAbsent $granted $cwd)
   False)

(= (codex:is-request-permissions-preapproved $effective CodexAbsent $cwd)
   False)

(= (codex:is-request-permissions-preapproved $effective $granted $cwd)
   (codex:is-request-permission-profile-equivalent?
     (codex:intersect-request-permission-profiles
       $effective
       $granted
       $cwd)
     (codex:normalize-request-permission-profile $cwd $effective)))

(= (codex:normalize-request-permissions-response
      $requested-permissions
      (CodexRequestPermissionsResponse $permissions $scope $strict-auto-review)
      $cwd)
   (if (and
         $strict-auto-review
         (== $scope (codex:permission-grant-scope-session)))
       (CodexRequestPermissionsResponse
         CodexAbsent
         (codex:permission-grant-scope-turn)
         False)
       (let $normalized-permissions
         (codex:normalize-request-permission-profile $cwd $permissions)
         (if (codex:is-request-permission-profile-empty? $normalized-permissions)
             (CodexRequestPermissionsResponse
               CodexAbsent
               $scope
               $strict-auto-review)
             (CodexRequestPermissionsResponse
               (codex:intersect-request-permission-profiles
                 $requested-permissions
                 $normalized-permissions
                 $cwd)
               $scope
               $strict-auto-review)))))

(= (codex:record-granted-request-permissions-for-state
      $state
      (CodexRequestPermissionsResponse $permissions $scope $strict-auto-review))
   (if (codex:is-request-permission-profile-empty? $permissions)
       $state
       (if (== $scope (codex:permission-grant-scope-turn))
           (codex:request-permissions-state
             (codex:request-permissions-state-session-permissions $state)
             (codex:merge-request-permission-profiles
               (codex:request-permissions-state-turn-permissions $state)
               $permissions)
             (if $strict-auto-review
                 True
                 (codex:request-permissions-state-turn-strict-auto-review
                   $state)))
           (codex:request-permissions-state
             (codex:merge-request-permission-profiles
               (codex:request-permissions-state-session-permissions $state)
               $permissions)
             (codex:request-permissions-state-turn-permissions $state)
             (codex:request-permissions-state-turn-strict-auto-review
               $state)))))

(= (codex:request-permissions-granted-permissions $state)
   (codex:merge-request-permission-profiles
     (codex:request-permissions-state-session-permissions $state)
     (codex:request-permissions-state-turn-permissions $state)))

(= (codex:is-request-permissions-approval-short-circuit?
      $approval-policy)
   (if (== $approval-policy (codex:ask-for-approval-never))
       True
       (case $approval-policy
         (((CodexAskForApprovalGranular False) True)
          ((CodexAskForApprovalGranular True) False)
          ((CodexAskForApprovalGranularConfig
             $sandbox-approval
             $rules
             $skill-approval
             False
             $mcp-elicitations)
           True)
          ((CodexAskForApprovalGranularConfig
             $sandbox-approval
             $rules
             $skill-approval
             True
             $mcp-elicitations)
           False)
          ($other False)))))

(= (codex:request-permissions-handler-response-result
      $state
      $requested-permissions
      $cwd
      $event
      (CodexRequestPermissionsResponseBehaviorReturn $response))
   (let $normalized-response
     (codex:normalize-request-permissions-response
       $requested-permissions
       $response
       $cwd)
     (CodexRequestPermissionsHandlerOutput
       $event
       (json-stringify
         (codex:request-permissions-response-json $normalized-response))
       (codex:record-granted-request-permissions-for-state
         $state
         $normalized-response))))

(= (codex:request-permissions-handler-response-result
      $state
      $requested-permissions
      $cwd
      $event
      (CodexRequestPermissionsResponseBehaviorCancel))
   (CodexRequestPermissionsHandlerCancelled
     $event
     (codex:request-permissions-cancelled-message)))

(= (codex:handle-request-permissions-function
      $context
      $state
      $call-id
      $arguments)
   (let $normalized-args-result
     (codex:normalize-request-permissions-args
       (codex:request-permissions-handler-context-cwd $context)
       (codex:parse-request-permissions-args $arguments))
     (case $normalized-args-result
       (((CodexRequestPermissionsNormalizeError $message)
         (CodexRequestPermissionsHandlerError $message))
        ((CodexRequestPermissionsNormalizeOk $args)
         (if (codex:is-request-permissions-approval-short-circuit?
               (codex:request-permissions-handler-context-approval-policy
                 $context))
             (let $response
               (CodexRequestPermissionsResponse
                 CodexAbsent
                 (codex:permission-grant-scope-turn)
                 False)
               (CodexRequestPermissionsHandlerOutput
                 (CodexRequestPermissionsEvent
                   $call-id
                   (codex:request-permissions-handler-context-turn-id $context)
                   (codex:request-permissions-args-reason $args)
                   (codex:request-permissions-args-permissions $args)
                   (codex:request-permissions-handler-context-cwd $context))
                 (json-stringify
                   (codex:request-permissions-response-json $response))
                 $state))
             (let $event
               (CodexRequestPermissionsEvent
                 $call-id
                 (codex:request-permissions-handler-context-turn-id $context)
                 (codex:request-permissions-args-reason $args)
                 (codex:request-permissions-args-permissions $args)
                 (codex:request-permissions-handler-context-cwd $context))
               (codex:request-permissions-handler-response-result
                 $state
                 (codex:request-permissions-args-permissions $args)
                 (codex:request-permissions-handler-context-cwd $context)
                 $event
                 (codex:request-permissions-handler-context-response-behavior
                   $context)))))))))

(= (codex:handle-request-permissions-payload
      $context
      $state
      $call-id
      (codex:request-permissions-function-payload $arguments))
   ; Rust receives an already-decoded function payload from the tool runtime.
   ; The current CeTTa evaluator can leave the helper constructor unreduced
   ; when it flows through the generic payload `case`, so the direct helper
   ; form is normalized explicitly here. Visible handler behavior is unchanged.
   (codex:handle-request-permissions-function
     $context
     $state
     $call-id
     $arguments))

(= (codex:handle-request-permissions-payload
      $context
      $state
      $call-id
      $payload)
   (case $payload
     (((CodexRequestPermissionsPayloadFunction $arguments)
       (codex:handle-request-permissions-function
         $context
         $state
         $call-id
         $arguments))
      ($other
       (CodexRequestPermissionsHandlerError
         (codex:request-permissions-unsupported-payload-message))))))

(= (codex:run-request-permissions-tool-call-with-context-state
      $context
      $state
      $call-id
      $input)
   (let $result
     ; Rust reaches this path only for function-payload tool calls.
     ; The current CeTTa evaluator can still collapse the extra payload helper
     ; layer to `Empty`, so the runnable tool-call surface invokes the same
     ; underlying handler function directly with the raw arguments string.
     ;
     ; Rust then matches on the concrete handler enum. In the current CeTTa
     ; evaluator, a direct constructor-pattern `case` over this imported
     ; handler result can also collapse to `Empty`, while the faithful field
     ; accessors still reduce. The wrapper therefore branches via the visible
     ; result tag and accessors without changing the emitted tool-call surface.
     (codex:handle-request-permissions-function
       $context
       $state
       $call-id
       $input)
     (let $result-type
       (codex:request-permissions-handler-result-type $result)
       (if (== $result-type "output")
           (CodexRequestPermissionsToolCallResult
             (codex:tool-result
               $call-id
               (codex:request-permissions-handler-result-output-text $result))
             (codex:request-permissions-handler-result-state $result))
           (CodexRequestPermissionsToolCallResult
             (codex:tool-result
               $call-id
               (codex:request-permissions-handler-result-message $result))
             $state)))))

(= (codex:run-request-permissions-tool-call-with-context $context $call-id $input)
   (codex:request-permissions-tool-call-result-item
     (codex:run-request-permissions-tool-call-with-context-state
       $context
       (codex:empty-request-permissions-state)
       $call-id
       $input)))

(= (codex:run-request-permissions-tool-call $call-id $input)
   (codex:run-request-permissions-tool-call-with-context
     (codex:default-request-permissions-handler-context)
     $call-id
     $input))

(= (codex:request-permissions-merge-file-system-sandbox-policy
      $file-system-sandbox-policy
      CodexAbsent)
   $file-system-sandbox-policy)

(= (codex:request-permissions-merge-file-system-sandbox-policy
      (CodexPatchFileSystemSandboxPolicy
        $writable-roots
        $read-only-roots
        $blocked-roots)
      (CodexRequestPermissionsFileSystem $read $write))
   (CodexPatchFileSystemSandboxPolicy
     (codex:append-dedup-string-lists $writable-roots $write)
     $read-only-roots
     $blocked-roots))

(= (codex:request-permissions-apply-patch-file-paths
      (CodexApplyPatchAction $cwd ()))
   ())

(= (codex:request-permissions-apply-patch-file-paths
      (CodexApplyPatchAction $cwd $changes))
   (let ($head $tail) (decons-atom $changes)
     (let $path
       (codex:normalized-request-permissions-path
         $cwd
         (codex:apply-patch-change-path $head))
       (let $rest
         (codex:request-permissions-apply-patch-file-paths
           (CodexApplyPatchAction $cwd $tail))
         (if (codex:apply-patch-change-has-move-path $head)
             (let $move-path
               (codex:normalized-request-permissions-path
                 $cwd
                 (codex:apply-patch-change-move-path $head))
               (codex:append-dedup-string-lists
                 ($path $move-path)
                 $rest))
             (codex:append-dedup-string-lists ($path) $rest))))))

(= (codex:request-permissions-write-roots-for-apply-patch-paths
      ()
      $file-system-sandbox-policy
      $cwd)
   ())

(= (codex:request-permissions-write-roots-for-apply-patch-paths
      $file-paths
      $file-system-sandbox-policy
      $cwd)
   (let ($head $tail) (decons-atom $file-paths)
     (let $rest
       (codex:request-permissions-write-roots-for-apply-patch-paths
         $tail
         $file-system-sandbox-policy
         $cwd)
       (let $parent (path-dirname $head)
         (if (codex:fs-policy-can-write-path-with-cwd
               $file-system-sandbox-policy
               $parent
               $cwd)
             $rest
             (codex:append-dedup-string-lists ($parent) $rest))))))

(= (codex:request-permissions-write-permissions-for-apply-patch
      $action
      $file-system-sandbox-policy)
   (let $write-roots
     (codex:request-permissions-write-roots-for-apply-patch-paths
       (codex:request-permissions-apply-patch-file-paths $action)
       $file-system-sandbox-policy
       (codex:apply-patch-action-cwd $action))
     (if (== (list:len $write-roots) 0)
         CodexAbsent
         (codex:request-permission-profile
           CodexAbsent
           (codex:request-permissions-file-system () $write-roots)))))

(= (codex:request-permissions-effective-additional-permissions-for-apply-patch
      $state
      $file-system-sandbox-policy
      $action)
   (let $granted-permissions (codex:request-permissions-granted-permissions $state)
     (let $effective-file-system-sandbox-policy
       (codex:request-permissions-merge-file-system-sandbox-policy
         $file-system-sandbox-policy
         (if (== $granted-permissions CodexAbsent)
             CodexAbsent
             (codex:request-permission-profile-file-system
               $granted-permissions)))
       (let $requested-permissions
         (codex:request-permissions-write-permissions-for-apply-patch
           $action
           $effective-file-system-sandbox-policy)
         (let $effective-permissions
           (codex:merge-request-permission-profiles
             $requested-permissions
             $granted-permissions)
           (CodexRequestPermissionsEffectiveAdditionalPermissions
             $effective-file-system-sandbox-policy
             $effective-permissions
             (codex:is-request-permissions-preapproved
               $effective-permissions
               $granted-permissions
               (codex:apply-patch-action-cwd $action))))))))

(= (codex:request-permissions-apply-patch-granted-write-roots CodexAbsent)
   ())

(= (codex:request-permissions-apply-patch-granted-write-roots
      (CodexRequestPermissionProfile $network CodexAbsent))
   ())

(= (codex:request-permissions-apply-patch-granted-write-roots
      (CodexRequestPermissionProfile
        $network
        (CodexRequestPermissionsFileSystem $read $write)))
   $write)

; Rust computes additional write permissions for apply_patch against the
; effective sandbox policy after granted write roots have already been merged
; into that policy. In that shape, any patch that is still outside the
; effective policy necessarily requests write roots beyond the granted set, so
; permissions_preapproved is false. If the patch is fully writable under the
; effective policy, the requested additional write set is empty and the merged
; effective permissions collapse back to the already-granted profile. CeTTa's
; evaluator currently collapses when the generic write-permissions helper is
; given that computed policy term, so this helper restages the same Rust logic
; with constructor-headed terms for audit stability.
(= (codex:request-permissions-apply-patch-permissions-preapproved
      $action
      $effective-file-system-sandbox-policy
      CodexAbsent)
   False)

(= (codex:request-permissions-apply-patch-permissions-preapproved
      $action
      $effective-file-system-sandbox-policy
      $granted-permissions)
   (codex:is-write-patch-constrained-to-writable-paths
     $action
     $effective-file-system-sandbox-policy
     (codex:apply-patch-action-cwd $action)))

(= (codex:request-permissions-effective-file-system-sandbox-policy-for-apply-patch
      (CodexRequestPermissionsState
        $session-permissions
        $turn-permissions
        $turn-strict-auto-review)
      (CodexPatchFileSystemSandboxPolicy
        $writable-roots
        $read-only-roots
        $blocked-roots))
   (CodexPatchFileSystemSandboxPolicy
     (codex:append-dedup-string-lists
       $writable-roots
       (codex:request-permissions-apply-patch-granted-write-roots
         (codex:merge-request-permission-profiles
           $session-permissions
           $turn-permissions)))
     $read-only-roots
     $blocked-roots))

; Rust applies strict-auto-review at the orchestrator boundary and
; permissions_preapproved at the apply_patch runtime approval boundary. Those
; layers are not visible in the restarted CeTTa slice yet, so the current
; request_permissions slice lowers both transitions onto the visible runtime
; invocation before local execution.
(= (codex:request-permissions-resolve-apply-patch-runtime
      $state
      $permissions-preapproved
      (CodexApplyPatchRuntimeInvocation
        $action
        $patch-text
        $auto-approved
        (CodexExecApprovalRequirementSkip $bypass-sandbox $amendment)))
   (if (codex:request-permissions-state-turn-strict-auto-review $state)
       (CodexApplyPatchRuntimeInvocation
         $action
         $patch-text
         $auto-approved
         (codex:approval-needs-approval CodexAbsent))
       (CodexApplyPatchRuntimeInvocation
         $action
         $patch-text
         $auto-approved
         (CodexExecApprovalRequirementSkip $bypass-sandbox $amendment))))

(= (codex:request-permissions-resolve-apply-patch-runtime
      $state
      $permissions-preapproved
      (CodexApplyPatchRuntimeInvocation
        $action
        $patch-text
        $auto-approved
        (CodexExecApprovalRequirementNeedsApproval $reason $amendment)))
   (if (codex:request-permissions-state-turn-strict-auto-review $state)
       (CodexApplyPatchRuntimeInvocation
         $action
         $patch-text
         $auto-approved
         (CodexExecApprovalRequirementNeedsApproval $reason $amendment))
       (if $permissions-preapproved
           (CodexApplyPatchRuntimeInvocation
             $action
             $patch-text
             True
             (codex:approval-skip False))
           (CodexApplyPatchRuntimeInvocation
             $action
             $patch-text
             $auto-approved
             (CodexExecApprovalRequirementNeedsApproval $reason $amendment)))))

(= (codex:apply-patch-with-request-permissions-state
      $state
      $approval-policy
      $sandbox-policy
      $file-system-sandbox-policy
      $patch-text
      $action
      $has-platform-sandbox)
   (let $granted-permissions
     (codex:request-permissions-granted-permissions $state)
     (let $effective-file-system-sandbox-policy
       (codex:request-permissions-effective-file-system-sandbox-policy-for-apply-patch
         $state
         $file-system-sandbox-policy)
     (case
       (codex:apply-patch
         $approval-policy
         $sandbox-policy
         $effective-file-system-sandbox-policy
         $patch-text
         $action
         $has-platform-sandbox)
       (((CodexInternalApplyPatchOutput $text)
         (CodexInternalApplyPatchOutput $text))
        ((CodexInternalApplyPatchDelegateToRuntime $runtime)
         (CodexInternalApplyPatchDelegateToRuntime
           (codex:request-permissions-resolve-apply-patch-runtime
             $state
             (codex:request-permissions-apply-patch-permissions-preapproved
               $action
               $effective-file-system-sandbox-policy
               $granted-permissions)
             $runtime))))))))

(= (codex:run-apply-patch-with-request-permissions-invocation
      (CodexInternalApplyPatchOutput $text))
   $text)

(= (codex:run-apply-patch-with-request-permissions-invocation
      (CodexInternalApplyPatchDelegateToRuntime $runtime))
   (codex:execute-apply-patch-runtime $runtime))
