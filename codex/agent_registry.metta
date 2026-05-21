; Rust-faithful pure AgentRegistry bookkeeping slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/agent/registry.rs
;
; Covered in this increment:
; - AgentMetadata projection
; - format_agent_nickname ordinal suffixes
; - session_depth / next_thread_spawn_depth / depth-limit check
; - registry state projection for agent_tree, used_agent_nicknames,
;   nickname_reset_count, and total_count
; - register_root_thread / agent_id_for_path / agent_metadata_for_thread
; - live_agents filtering
; - update_last_task_message
; - register_spawned_thread key selection and used-nickname marking
; - reserve_agent_nickname_with_preference with injected RNG choice index
; - reserve/release agent path placeholders
; - reserve_spawn_slot, drop, commit, release_spawned_thread bookkeeping
;
; Required CeTTa representation notes for audit:
; - Rust stores active agents in a Mutex<HashMap<String, AgentMetadata>> and
;   used nicknames in a HashSet. This pure slice uses ordered entry lists with
;   the same key and membership semantics. HashMap iteration order is not part
;   of the Rust contract; list order is therefore only a deterministic test
;   representation for otherwise unordered results.
; - Rust reserve_agent_nickname uses rand::choose. This pure slice receives an
;   in-bounds choice index from the caller at that randomness boundary, then
;   applies the same candidate filtering, preferred-name bypass, used-pool
;   reset, ordinal formatting, and used-nickname insertion as Rust.
; - Rust AtomicUsize increments/decrements are represented as explicit state
;   transitions. The pure helpers assume the same valid call sequences as Rust
;   Drop/commit/release, so underflow is not introduced as a separate branch.

!(import! &self agent_path)
!(import! &self error)
!(import! &self list)
!(import! &self protocol)
!(import! &self str)

(= (codex:agent-registry-ok $value)
   (CodexAgentRegistryOk $value))

(= (codex:agent-registry-err $error)
   (CodexAgentRegistryErr $error))

(= (codex:agent-registry-metadata
      $agent-id
      $agent-path
      $agent-nickname
      $agent-role
      $last-task-message)
   (CodexAgentRegistryMetadata
     $agent-id
     $agent-path
     $agent-nickname
     $agent-role
     $last-task-message))

(= (codex:agent-registry-metadata-agent-id
      (CodexAgentRegistryMetadata
        $agent-id
        $agent-path
        $agent-nickname
        $agent-role
        $last-task-message))
   $agent-id)

(= (codex:agent-registry-metadata-agent-path
      (CodexAgentRegistryMetadata
        $agent-id
        $agent-path
        $agent-nickname
        $agent-role
        $last-task-message))
   $agent-path)

(= (codex:agent-registry-metadata-agent-nickname
      (CodexAgentRegistryMetadata
        $agent-id
        $agent-path
        $agent-nickname
        $agent-role
        $last-task-message))
   $agent-nickname)

(= (codex:agent-registry-metadata-agent-role
      (CodexAgentRegistryMetadata
        $agent-id
        $agent-path
        $agent-nickname
        $agent-role
        $last-task-message))
   $agent-role)

(= (codex:agent-registry-metadata-last-task-message
      (CodexAgentRegistryMetadata
        $agent-id
        $agent-path
        $agent-nickname
        $agent-role
        $last-task-message))
   $last-task-message)

(= (codex:agent-registry-metadata-with-last-task-message
      (CodexAgentRegistryMetadata
        $agent-id
        $agent-path
        $agent-nickname
        $agent-role
        $last-task-message)
      $new-last-task-message)
   (CodexAgentRegistryMetadata
     $agent-id
     $agent-path
     $agent-nickname
     $agent-role
     $new-last-task-message))

(= (codex:agent-registry-entry $key $metadata)
   (CodexAgentRegistryEntry $key $metadata))

(= (codex:agent-registry-entry-key
      (CodexAgentRegistryEntry $key $metadata))
   $key)

(= (codex:agent-registry-entry-metadata
      (CodexAgentRegistryEntry $key $metadata))
   $metadata)

(= (codex:agent-registry-state
      $agent-tree
      $used-agent-nicknames
      $nickname-reset-count
      $total-count)
   (CodexAgentRegistryState
     $agent-tree
     $used-agent-nicknames
     $nickname-reset-count
     $total-count))

(= (codex:agent-registry-state-empty)
   (codex:agent-registry-state () () 0 0))

(= (codex:agent-registry-state-agent-tree
      (CodexAgentRegistryState
        $agent-tree
        $used-agent-nicknames
        $nickname-reset-count
        $total-count))
   $agent-tree)

(= (codex:agent-registry-state-used-agent-nicknames
      (CodexAgentRegistryState
        $agent-tree
        $used-agent-nicknames
        $nickname-reset-count
        $total-count))
   $used-agent-nicknames)

(= (codex:agent-registry-state-nickname-reset-count
      (CodexAgentRegistryState
        $agent-tree
        $used-agent-nicknames
        $nickname-reset-count
        $total-count))
   $nickname-reset-count)

(= (codex:agent-registry-state-total-count
      (CodexAgentRegistryState
        $agent-tree
        $used-agent-nicknames
        $nickname-reset-count
        $total-count))
   $total-count)

(= (codex:agent-registry-state-with-agent-tree
      (CodexAgentRegistryState
        $agent-tree
        $used-agent-nicknames
        $nickname-reset-count
        $total-count)
      $new-agent-tree)
   (CodexAgentRegistryState
     $new-agent-tree
     $used-agent-nicknames
     $nickname-reset-count
     $total-count))

(= (codex:agent-registry-state-with-total-count
      (CodexAgentRegistryState
        $agent-tree
        $used-agent-nicknames
        $nickname-reset-count
        $total-count)
      $new-total-count)
   (CodexAgentRegistryState
     $agent-tree
     $used-agent-nicknames
     $nickname-reset-count
     $new-total-count))

(= (codex:agent-registry-state-with-used-agent-nicknames
      (CodexAgentRegistryState
        $agent-tree
        $used-agent-nicknames
        $nickname-reset-count
        $total-count)
      $new-used-agent-nicknames)
   (CodexAgentRegistryState
     $agent-tree
     $new-used-agent-nicknames
     $nickname-reset-count
     $total-count))

(= (codex:agent-registry-state-with-nickname-reset-count
      (CodexAgentRegistryState
        $agent-tree
        $used-agent-nicknames
        $nickname-reset-count
        $total-count)
      $new-nickname-reset-count)
   (CodexAgentRegistryState
     $agent-tree
     $used-agent-nicknames
     $new-nickname-reset-count
     $total-count))

(= (codex:agent-registry-spawn-reservation
      $active
      $reserved-agent-nickname
      $reserved-agent-path)
   (CodexAgentRegistrySpawnReservation
     $active
     $reserved-agent-nickname
     $reserved-agent-path))

(= (codex:agent-registry-spawn-reservation-active
      (CodexAgentRegistrySpawnReservation
        $active
        $reserved-agent-nickname
        $reserved-agent-path))
   $active)

(= (codex:agent-registry-spawn-reservation-reserved-agent-path
      (CodexAgentRegistrySpawnReservation
        $active
        $reserved-agent-nickname
        $reserved-agent-path))
   $reserved-agent-path)

(= (codex:agent-registry-spawn-reservation-reserved-agent-nickname
      (CodexAgentRegistrySpawnReservation
        $active
        $reserved-agent-nickname
        $reserved-agent-path))
   $reserved-agent-nickname)

(= (codex:agent-registry-spawn-reservation-with-nickname
      (CodexAgentRegistrySpawnReservation
        $active
        $reserved-agent-nickname
        $reserved-agent-path)
      $new-reserved-agent-nickname)
   (CodexAgentRegistrySpawnReservation
     $active
     $new-reserved-agent-nickname
     $reserved-agent-path))

(= (codex:agent-registry-spawn-reservation-with-path
      (CodexAgentRegistrySpawnReservation
        $active
        $reserved-agent-nickname
        $reserved-agent-path)
      $new-reserved-agent-path)
   (CodexAgentRegistrySpawnReservation
     $active
     $reserved-agent-nickname
     $new-reserved-agent-path))

(= (codex:agent-registry-reserve-ok $state $reservation)
   (CodexAgentRegistryReserveOk $state $reservation))

(= (codex:agent-registry-reserve-err $error)
   (CodexAgentRegistryReserveErr $error))

(= (codex:agent-registry-nickname-selection $state $nickname)
   (CodexAgentRegistryNicknameSelection $state $nickname))

(= (codex:agent-registry-ordinal-suffix $value)
   (let $mod-100 (% $value 100)
     (if (and (>= $mod-100 11) (<= $mod-100 13))
         "th"
         (let $mod-10 (% $value 10)
           (case $mod-10
             ((1 "st")
              (2 "nd")
              (3 "rd")
              ($other "th")))))))

(= (codex:agent-registry-format-agent-nickname
      $name
      $nickname-reset-count)
   (if (== $nickname-reset-count 0)
       $name
       (let $value (+ $nickname-reset-count 1)
         (format-args
           "{} the {}{}"
           ($name $value (codex:agent-registry-ordinal-suffix $value))))))

(= (codex:agent-registry-session-depth $session-source)
   (case $session-source
     (((CodexSessionSourceSubAgent
         (CodexSubAgentSourceThreadSpawn
           $parent-thread-id
           $depth
           $agent-path
           $agent-nickname
           $agent-role))
       $depth)
      ($other 0))))

(= (codex:agent-registry-i32-max)
   2147483647)

(= (codex:agent-registry-saturating-add-one-i32 $value)
   (if (>= $value (codex:agent-registry-i32-max))
       (codex:agent-registry-i32-max)
       (+ $value 1)))

(= (codex:agent-registry-next-thread-spawn-depth $session-source)
   (codex:agent-registry-saturating-add-one-i32
     (codex:agent-registry-session-depth $session-source)))

(= (codex:agent-registry-exceeds-thread-spawn-depth-limit
      $depth
      $max-depth)
   (> $depth $max-depth))

(= (codex:agent-registry-list-contains () $value)
   False)

(= (codex:agent-registry-list-contains $items $value)
   (let ($head $tail) (decons-atom $items)
     (if (== $head $value)
         True
         (codex:agent-registry-list-contains $tail $value))))

(= (codex:agent-registry-set-insert $items $value)
   (if (codex:agent-registry-list-contains $items $value)
       $items
       (cons-atom $value $items)))

(= (codex:agent-registry-available-agent-nicknames
      ()
      $used-agent-nicknames
      $nickname-reset-count)
   ())

(= (codex:agent-registry-available-agent-nicknames
      $names
      $used-agent-nicknames
      $nickname-reset-count)
   (let ($head $tail) (decons-atom $names)
     (let $candidate
       (codex:agent-registry-format-agent-nickname
         $head
         $nickname-reset-count)
       (case
         (codex:agent-registry-available-agent-nicknames
           $tail
           $used-agent-nicknames
           $nickname-reset-count)
         (($tail-available
           (if (codex:agent-registry-list-contains
                 $used-agent-nicknames
                 $candidate)
               $tail-available
               (cons-atom $candidate $tail-available))))))))

(= (codex:agent-registry-state-after-reserved-nickname
      $state
      $nickname)
   (codex:agent-registry-state-with-used-agent-nicknames
     $state
     (codex:agent-registry-set-insert
       (codex:agent-registry-state-used-agent-nicknames $state)
       $nickname)))

(= (codex:agent-registry-state-after-nickname-pool-reset
      $state
      $nickname
      $new-nickname-reset-count)
   (codex:agent-registry-state-with-used-agent-nicknames
     (codex:agent-registry-state-with-nickname-reset-count
       $state
       $new-nickname-reset-count)
     ($nickname)))

(= (codex:agent-registry-reserve-agent-nickname-selection
      $state
      $names
      $preferred
      $choice-index)
   (case $preferred
     ((CodexAbsent
       (case $names
         ((() CodexAbsent)
          ($non-empty-names
           (let $nickname-reset-count
             (codex:agent-registry-state-nickname-reset-count $state)
             (let $available-names
               (codex:agent-registry-available-agent-nicknames
                 $non-empty-names
                 (codex:agent-registry-state-used-agent-nicknames $state)
                 $nickname-reset-count)
               (case $available-names
                 ((()
                   (let $new-nickname-reset-count
                     (+ $nickname-reset-count 1)
                     (let $nickname
                       (codex:agent-registry-format-agent-nickname
                         (list:at $non-empty-names $choice-index)
                         $new-nickname-reset-count)
                       (codex:agent-registry-nickname-selection
                         (codex:agent-registry-state-after-nickname-pool-reset
                           $state
                           $nickname
                           $new-nickname-reset-count)
                         $nickname))))
                  ($non-empty-available-names
                   (let $nickname
                     (list:at $non-empty-available-names $choice-index)
                     (codex:agent-registry-nickname-selection
                       (codex:agent-registry-state-after-reserved-nickname
                         $state
                         $nickname)
                       $nickname)))))))))))
      ($preferred-name
       (codex:agent-registry-nickname-selection
         (codex:agent-registry-state-after-reserved-nickname
           $state
           $preferred-name)
         $preferred-name)))))

(= (codex:agent-registry-reserve-agent-nickname-with-preference
      $state
      $reservation
      $names
      $preferred
      $choice-index)
   (case
     (codex:agent-registry-reserve-agent-nickname-selection
       $state
       $names
       $preferred
       $choice-index)
     ((CodexAbsent
       (codex:agent-registry-reserve-err
         (codex:error-unsupported-operation
           "no available agent nicknames")))
      ((CodexAgentRegistryNicknameSelection $reserved-state $nickname)
       (codex:agent-registry-reserve-ok
         $reserved-state
         (codex:agent-registry-spawn-reservation-with-nickname
           $reservation
           $nickname))))))

(= (codex:agent-registry-entry-list-has-key () $key)
   False)

(= (codex:agent-registry-entry-list-has-key $entries $key)
   (let ($head $tail) (decons-atom $entries)
     (case (== (codex:agent-registry-entry-key $head) $key)
       ((True True)
        (False
         (codex:agent-registry-entry-list-has-key $tail $key))))))

(= (codex:agent-registry-entry-list-get () $key)
   CodexAbsent)

(= (codex:agent-registry-entry-list-get $entries $key)
   (let ($head $tail) (decons-atom $entries)
     (case (== (codex:agent-registry-entry-key $head) $key)
       ((True
         (codex:agent-registry-entry-metadata $head))
        (False
         (codex:agent-registry-entry-list-get $tail $key))))))

(= (codex:agent-registry-entry-list-put () $entry)
   ($entry))

(= (codex:agent-registry-entry-list-put $entries $entry)
   (let ($head $tail) (decons-atom $entries)
     (if (== (codex:agent-registry-entry-key $head)
             (codex:agent-registry-entry-key $entry))
         (cons-atom $entry $tail)
         (cons-atom
           $head
           (codex:agent-registry-entry-list-put $tail $entry)))))

(= (codex:agent-registry-register-root-thread $state $thread-id)
   (let $agent-tree (codex:agent-registry-state-agent-tree $state)
     (case
       (codex:agent-registry-entry-list-has-key
         $agent-tree
         (codex:agent-path-as-str (codex:agent-path-root)))
       ((True
         $state)
        (False
         (codex:agent-registry-state-with-agent-tree
           $state
           (cons-atom
             (codex:agent-registry-entry
               (codex:agent-path-as-str (codex:agent-path-root))
               (codex:agent-registry-metadata
                 $thread-id
                 (codex:agent-path-root)
                 CodexAbsent
                 CodexAbsent
                 CodexAbsent))
             $agent-tree)))))))

(= (codex:agent-registry-agent-id-for-path $state $agent-path)
   (case
     (codex:agent-registry-entry-list-get
       (codex:agent-registry-state-agent-tree $state)
       (codex:agent-path-as-str $agent-path))
     ((CodexAbsent
       CodexAbsent)
      ($metadata
       (codex:agent-registry-metadata-agent-id $metadata)))))

(= (codex:agent-registry-agent-metadata-for-thread-from
      ()
      $thread-id)
   CodexAbsent)

(= (codex:agent-registry-agent-metadata-for-thread-from
      $entries
      $thread-id)
   (let ($head $tail) (decons-atom $entries)
     (let $metadata (codex:agent-registry-entry-metadata $head)
       (if (== (codex:agent-registry-metadata-agent-id $metadata) $thread-id)
           $metadata
           (codex:agent-registry-agent-metadata-for-thread-from
             $tail
             $thread-id)))))

(= (codex:agent-registry-agent-metadata-for-thread $state $thread-id)
   (codex:agent-registry-agent-metadata-for-thread-from
     (codex:agent-registry-state-agent-tree $state)
     $thread-id))

(= (codex:is-agent-registry-metadata-root
      (CodexAgentRegistryMetadata
        $agent-id
        $agent-path
        $agent-nickname
        $agent-role
        $last-task-message))
   (case $agent-path
     ((CodexAbsent False)
      ($path
       (codex:is-agent-path-root $path)))))

(= (codex:agent-registry-live-agents-from ())
   ())

(= (codex:agent-registry-live-agents-from $entries)
   (let ($head $tail) (decons-atom $entries)
     (let $metadata (codex:agent-registry-entry-metadata $head)
       (let $tail-live (codex:agent-registry-live-agents-from $tail)
         (if (and
               (not (== (codex:agent-registry-metadata-agent-id $metadata)
                        CodexAbsent))
               (not (codex:is-agent-registry-metadata-root $metadata)))
             (cons-atom $metadata $tail-live)
             $tail-live)))))

(= (codex:agent-registry-live-agents $state)
   (codex:agent-registry-live-agents-from
     (codex:agent-registry-state-agent-tree $state)))

(= (codex:agent-registry-update-last-task-message-from
      ()
      $thread-id
      $last-task-message)
   ())

(= (codex:agent-registry-update-last-task-message-from
      $entries
      $thread-id
      $last-task-message)
   (let ($head $tail) (decons-atom $entries)
     (let $metadata (codex:agent-registry-entry-metadata $head)
       (let $new-metadata
         (if (== (codex:agent-registry-metadata-agent-id $metadata) $thread-id)
             (codex:agent-registry-metadata-with-last-task-message
               $metadata
               $last-task-message)
             $metadata)
         (cons-atom
           (codex:agent-registry-entry
             (codex:agent-registry-entry-key $head)
             $new-metadata)
           (codex:agent-registry-update-last-task-message-from
             $tail
             $thread-id
             $last-task-message))))))

(= (codex:agent-registry-update-last-task-message
      $state
      $thread-id
      $last-task-message)
   (codex:agent-registry-state-with-agent-tree
     $state
     (codex:agent-registry-update-last-task-message-from
       (codex:agent-registry-state-agent-tree $state)
       $thread-id
       $last-task-message)))

(= (codex:agent-registry-metadata-key
      (CodexAgentRegistryMetadata
        $agent-id
        $agent-path
        $agent-nickname
        $agent-role
        $last-task-message))
   (case $agent-path
     ((CodexAbsent
       (format-args "thread:{}" ($agent-id)))
      ($path
       (codex:agent-path-as-str $path)))))

(= (codex:agent-registry-used-nickname-after-register
      $used-agent-nicknames
      $agent-nickname)
   (case $agent-nickname
     ((CodexAbsent $used-agent-nicknames)
      ($nickname
       (codex:agent-registry-set-insert
         $used-agent-nicknames
         $nickname)))))

(= (codex:agent-registry-register-spawned-thread $state $metadata)
   (if (== (codex:agent-registry-metadata-agent-id $metadata) CodexAbsent)
       $state
       (let $key (codex:agent-registry-metadata-key $metadata)
         (let $state-with-tree
           (codex:agent-registry-state-with-agent-tree
             $state
             (codex:agent-registry-entry-list-put
               (codex:agent-registry-state-agent-tree $state)
               (codex:agent-registry-entry $key $metadata)))
           (codex:agent-registry-state-with-used-agent-nicknames
             $state-with-tree
             (codex:agent-registry-used-nickname-after-register
               (codex:agent-registry-state-used-agent-nicknames $state)
               (codex:agent-registry-metadata-agent-nickname
                 $metadata)))))))

(= (codex:agent-registry-release-scan $entries $removed-metadata)
   (CodexAgentRegistryReleaseScan $entries $removed-metadata))

(= (codex:agent-registry-release-scan-entries
      (CodexAgentRegistryReleaseScan $entries $removed-metadata))
   $entries)

(= (codex:agent-registry-release-scan-removed-metadata
      (CodexAgentRegistryReleaseScan $entries $removed-metadata))
   $removed-metadata)

(= (codex:agent-registry-release-spawned-thread-from () $thread-id)
   (codex:agent-registry-release-scan () CodexAbsent))

(= (codex:agent-registry-release-spawned-thread-from $entries $thread-id)
   (let ($head $tail) (decons-atom $entries)
     (let $metadata (codex:agent-registry-entry-metadata $head)
       (if (== (codex:agent-registry-metadata-agent-id $metadata) $thread-id)
           (codex:agent-registry-release-scan $tail $metadata)
           (let $tail-scan
             (codex:agent-registry-release-spawned-thread-from
               $tail
               $thread-id)
             (codex:agent-registry-release-scan
               (cons-atom
                 $head
                 (codex:agent-registry-release-scan-entries $tail-scan))
               (codex:agent-registry-release-scan-removed-metadata
                 $tail-scan)))))))

(= (codex:is-agent-registry-removed-counted-agent $metadata)
   (case $metadata
     ((CodexAbsent False)
      ($removed-metadata
       (not (codex:is-agent-registry-metadata-root $removed-metadata))))))

(= (codex:agent-registry-release-spawned-thread $state $thread-id)
   (let $scan
     (codex:agent-registry-release-spawned-thread-from
       (codex:agent-registry-state-agent-tree $state)
       $thread-id)
     (let $removed-metadata
       (codex:agent-registry-release-scan-removed-metadata $scan)
       (let $state-with-tree
         (codex:agent-registry-state-with-agent-tree
           $state
           (codex:agent-registry-release-scan-entries $scan))
         (if (codex:is-agent-registry-removed-counted-agent
               $removed-metadata)
             (codex:agent-registry-state-with-total-count
               $state-with-tree
               (- (codex:agent-registry-state-total-count $state) 1))
             $state-with-tree)))))

(= (codex:agent-registry-reserve-agent-path $state $agent-path)
   (let $key (codex:agent-path-as-str $agent-path)
     (let $agent-tree (codex:agent-registry-state-agent-tree $state)
       (case
         (codex:agent-registry-entry-list-has-key $agent-tree $key)
         ((True
           (codex:agent-registry-err
             (codex:error-unsupported-operation
               (format-args "agent path `{}` already exists" ($key)))))
          (False
           (codex:agent-registry-ok
             (codex:agent-registry-state-with-agent-tree
               $state
               (cons-atom
                 (codex:agent-registry-entry
                   $key
                   (codex:agent-registry-metadata
                     CodexAbsent
                     $agent-path
                     CodexAbsent
                     CodexAbsent
                     CodexAbsent))
                 $agent-tree)))))))))

(= (codex:agent-registry-release-reserved-agent-path-from
      ()
      $agent-path)
   ())

(= (codex:agent-registry-release-reserved-agent-path-from
      $entries
      $agent-path)
   (let ($head $tail) (decons-atom $entries)
     (let $metadata (codex:agent-registry-entry-metadata $head)
       (if (and
             (== (codex:agent-registry-entry-key $head)
                 (codex:agent-path-as-str $agent-path))
             (== (codex:agent-registry-metadata-agent-id $metadata)
                 CodexAbsent))
           $tail
           (cons-atom
             $head
             (codex:agent-registry-release-reserved-agent-path-from
               $tail
               $agent-path))))))

(= (codex:agent-registry-release-reserved-agent-path
      $state
      $agent-path)
   (codex:agent-registry-state-with-agent-tree
     $state
     (codex:agent-registry-release-reserved-agent-path-from
       (codex:agent-registry-state-agent-tree $state)
       $agent-path)))

(= (codex:agent-registry-reserve-agent-path-for-reservation
      $state
      $reservation
      $agent-path)
   (case (codex:agent-registry-reserve-agent-path $state $agent-path)
     (((CodexAgentRegistryErr $error)
       (codex:agent-registry-reserve-err $error))
      ((CodexAgentRegistryOk $reserved-state)
       (codex:agent-registry-reserve-ok
         $reserved-state
         (codex:agent-registry-spawn-reservation-with-path
           $reservation
           $agent-path))))))

(= (codex:agent-registry-reserve-spawn-slot $state $max-threads)
   (let $total-count (codex:agent-registry-state-total-count $state)
     (case $max-threads
       ((CodexAbsent
         (codex:agent-registry-reserve-ok
           (codex:agent-registry-state-with-total-count
             $state
             (+ $total-count 1))
           (codex:agent-registry-spawn-reservation
             True
             CodexAbsent
             CodexAbsent)))
        ($limit
         (if (>= $total-count $limit)
             (codex:agent-registry-reserve-err
               (codex:error-agent-limit-reached $limit))
             (codex:agent-registry-reserve-ok
               (codex:agent-registry-state-with-total-count
                 $state
                 (+ $total-count 1))
               (codex:agent-registry-spawn-reservation
                 True
                 CodexAbsent
                 CodexAbsent))))))))

(= (codex:agent-registry-drop-reservation
      $state
      (CodexAgentRegistrySpawnReservation
        $active
        $reserved-agent-nickname
        $reserved-agent-path))
   (if $active
       (let $path-released-state
         (case $reserved-agent-path
           ((CodexAbsent $state)
            ($agent-path
             (codex:agent-registry-release-reserved-agent-path
               $state
               $agent-path))))
         (codex:agent-registry-state-with-total-count
           $path-released-state
           (- (codex:agent-registry-state-total-count
                $path-released-state)
              1)))
       $state))

(= (codex:agent-registry-commit-reservation
      $state
      (CodexAgentRegistrySpawnReservation
        $active
        $reserved-agent-nickname
        $reserved-agent-path)
      $metadata)
   (codex:agent-registry-register-spawned-thread $state $metadata))
