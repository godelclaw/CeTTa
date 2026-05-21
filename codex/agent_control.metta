; Rust-faithful pure AgentControl boundary slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/agent/control.rs
;
; Covered in this increment:
; - thread_spawn_parent_thread_id
; - thread_spawn_depth
; - keep_forked_rollout_item
; - spawn_forked_thread rollout-history truncation/retention preparation
; - register_session_root
; - prepare_thread_spawn pure registry/session-source preparation
; - get_agent_metadata registry forwarding
; - live_thread_spawn_children/open_thread_spawn_children over thread snapshots
; - live_thread_spawn_descendants/list_live_agent_subtree_thread_ids
; - resolve_agent_reference path resolution and error mapping
; - format_environment_context_subagents formatting over materialized children
; - agent_matches_prefix
; - list_agents filtering/projection over materialized thread statuses
; - render_input_preview
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust AgentControl owns weak async access to ThreadManagerState. This pure
;   slice receives explicit registry state, child lists, and status entries at
;   the async boundary while preserving the same visible branching, sorting,
;   filtering, and error strings for the covered logic.
; - Rust returns `CodexResult<T>`. This slice represents that result surface
;   with explicit `CodexAgentControlOk` and `CodexAgentControlErr` wrappers.
; - Rust stores thread ids as `ThreadId`. Existing CeTTa Codex slices carry
;   those ids as their canonical string representation at pure boundaries.
; - Rust render_input_preview uses PathBuf::display for LocalImage and Skill
;   paths. The existing CeTTa protocol surface carries those same visible path
;   values as strings.
; - Rust keep_forked_rollout_item consumes protocol RolloutItem values. The
;   current CeTTa fork-history surface exposes those constructors through the
;   thread_rollout_truncation slice, and this helper matches that same local
;   representation at the AgentControl boundary.
; - Rust SpawnAgentForkMode is private to AgentControl. This slice exposes a
;   local constructor pair with the same variants so the pure fork-history
;   preparation branch can be tested without the async ThreadManager boundary.
; - CeTTa callers often pass registry metadata through local helper equations.
;   Rust stores concrete structs, so this boundary forces metadata evaluation
;   while scanning registry entries before applying the same field tests.
; - Rust prepare_thread_spawn reads Config and calls rand::choose through the
;   registry reservation. This pure boundary receives ordered user role configs
;   plus an in-bounds nickname choice index, preserving the same role candidate
;   selection and registry state transitions at deterministic boundaries.
; - Rust live_thread_spawn_children lists ThreadManager threads, reads each
;   config snapshot asynchronously, and skips threads that disappear. This pure
;   slice receives the still-live materialized thread snapshots at that async
;   boundary and keeps the same parent grouping, metadata fallback, and sorting.

!(import! &self agent_path)
!(import! &self agent_registry)
!(import! &self agent_role)
!(import! &self error)
!(import! &self list)
!(import! &self protocol)
!(import! &self session_prefix)
!(import! &self str)
!(import! &self thread_rollout_truncation)

(= (codex:agent-control-ok $value)
   (CodexAgentControlOk $value))

(= (codex:agent-control-err $error)
   (CodexAgentControlErr $error))

(= (codex:agent-control-root-last-task-message)
   "Main thread")

(= (codex:agent-control-spawn-agent-fork-mode-full-history)
   (CodexSpawnAgentForkModeFullHistory))

(= (codex:agent-control-spawn-agent-fork-mode-last-n-turns $last-n-turns)
   (CodexSpawnAgentForkModeLastNTurns $last-n-turns))

(= (codex:agent-control-thread-metadata-entry $thread-id $metadata)
   (CodexAgentControlThreadMetadataEntry $thread-id $metadata))

(= (codex:agent-control-thread-metadata-entry-thread-id
      (CodexAgentControlThreadMetadataEntry $thread-id $metadata))
   $thread-id)

(= (codex:agent-control-thread-metadata-entry-metadata
      (CodexAgentControlThreadMetadataEntry $thread-id $metadata))
   (eval $metadata))

(= (codex:agent-control-status-entry $thread-id $status)
   (CodexAgentControlStatusEntry $thread-id $status))

(= (codex:agent-control-status-entry-thread-id
      (CodexAgentControlStatusEntry $thread-id $status))
   $thread-id)

(= (codex:agent-control-status-entry-status
      (CodexAgentControlStatusEntry $thread-id $status))
   (eval $status))

(= (codex:agent-control-thread-snapshot-entry $thread-id $session-source)
   (CodexAgentControlThreadSnapshotEntry $thread-id $session-source))

(= (codex:agent-control-thread-snapshot-entry-thread-id
      (CodexAgentControlThreadSnapshotEntry $thread-id $session-source))
   $thread-id)

(= (codex:agent-control-thread-snapshot-entry-session-source
      (CodexAgentControlThreadSnapshotEntry $thread-id $session-source))
   (eval $session-source))

(= (codex:agent-control-thread-spawn-children-entry
      $parent-thread-id
      $children)
   (CodexAgentControlThreadSpawnChildrenEntry
     $parent-thread-id
     $children))

(= (codex:agent-control-thread-spawn-children-entry-parent-thread-id
      (CodexAgentControlThreadSpawnChildrenEntry
        $parent-thread-id
        $children))
   $parent-thread-id)

(= (codex:agent-control-thread-spawn-children-entry-children
      (CodexAgentControlThreadSpawnChildrenEntry
        $parent-thread-id
        $children))
   $children)

(= (codex:agent-control-listed-agent
      $agent-name
      $agent-status
      $last-task-message)
   (CodexAgentControlListedAgent
     $agent-name
     $agent-status
     $last-task-message))

(= (codex:agent-control-listed-agent-name
      (CodexAgentControlListedAgent
        $agent-name
        $agent-status
        $last-task-message))
   $agent-name)

(= (codex:agent-control-listed-agent-status
      (CodexAgentControlListedAgent
        $agent-name
        $agent-status
        $last-task-message))
   $agent-status)

(= (codex:agent-control-listed-agent-last-task-message
      (CodexAgentControlListedAgent
        $agent-name
        $agent-status
        $last-task-message))
   $last-task-message)

(= (codex:agent-control-prepare-thread-spawn-ok
      $registry-state
      $reservation
      $session-source
      $metadata)
   (CodexAgentControlPrepareThreadSpawnOk
     $registry-state
     $reservation
     $session-source
     $metadata))

(= (codex:agent-control-prepare-thread-spawn-err $error)
   (CodexAgentControlPrepareThreadSpawnErr $error))

(= (codex:agent-control-default-agent-nickname-list)
   ("Euclid"
    "Archimedes"
    "Ptolemy"
    "Hypatia"
    "Avicenna"
    "Averroes"
    "Aquinas"
    "Copernicus"
    "Kepler"
    "Galileo"
    "Bacon"
    "Descartes"
    "Pascal"
    "Fermat"
    "Huygens"
    "Leibniz"
    "Newton"
    "Halley"
    "Euler"
    "Lagrange"
    "Laplace"
    "Volta"
    "Gauss"
    "Ampere"
    "Faraday"
    "Darwin"
    "Lovelace"
    "Boole"
    "Pasteur"
    "Maxwell"
    "Mendel"
    "Curie"
    "Planck"
    "Tesla"
    "Poincare"
    "Noether"
    "Hilbert"
    "Einstein"
    "Raman"
    "Bohr"
    "Turing"
    "Hubble"
    "Feynman"
    "Franklin"
    "McClintock"
    "Meitner"
    "Herschel"
    "Linnaeus"
    "Wegener"
    "Chandrasekhar"
    "Sagan"
    "Goodall"
    "Carson"
    "Carver"
    "Socrates"
    "Plato"
    "Aristotle"
    "Epicurus"
    "Cicero"
    "Confucius"
    "Mencius"
    "Zeno"
    "Locke"
    "Hume"
    "Kant"
    "Hegel"
    "Kierkegaard"
    "Mill"
    "Nietzsche"
    "Peirce"
    "James"
    "Dewey"
    "Russell"
    "Popper"
    "Sartre"
    "Beauvoir"
    "Arendt"
    "Rawls"
    "Singer"
    "Anscombe"
    "Parfit"
    "Kuhn"
    "Boyle"
    "Hooke"
    "Harvey"
    "Dalton"
    "Ohm"
    "Helmholtz"
    "Gibbs"
    "Lorentz"
    "Schrodinger"
    "Heisenberg"
    "Pauli"
    "Dirac"
    "Bernoulli"
    "Godel"
    "Nash"
    "Banach"
    "Ramanujan"
    "Erdos"
    "Jason"))

(= (codex:agent-control-agent-nickname-candidates
      $user-defined-roles
      $agent-role)
   (let $role-name
     (codex:agent-role-select-role-name $agent-role)
     (let $role-config
       (codex:agent-role-resolve-role-config-with-built-ins
         $user-defined-roles
         $role-name)
       (case $role-config
         ((CodexAbsent
           (codex:agent-control-default-agent-nickname-list))
          ($config
           (case (codex:agent-role-config-nickname-candidates $config)
             ((CodexAbsent
               (codex:agent-control-default-agent-nickname-list))
              ($candidates
               $candidates)))))))))

(= (codex:agent-control-thread-spawn-parent-thread-id $session-source)
   (case (eval $session-source)
     (((CodexSessionSourceSubAgent
         (CodexSubAgentSourceThreadSpawn
           $parent-thread-id
           $depth
           $agent-path
           $agent-nickname
           $agent-role))
       $parent-thread-id)
      ($other CodexAbsent))))

(= (codex:agent-control-thread-spawn-depth $session-source)
   (case (eval $session-source)
     (((CodexSessionSourceSubAgent
         (CodexSubAgentSourceThreadSpawn
           $parent-thread-id
           $depth
           $agent-path
           $agent-nickname
           $agent-role))
       $depth)
      ($other CodexAbsent))))

(= (codex:agent-control-is-final-answer-phase $phase)
   (case (eval $phase)
     (((CodexMessagePhaseFinalAnswer) True)
      ("final_answer" True)
      ($other False))))

(= (codex:agent-control-keep-forked-message $role $phase)
   (case $role
     (("system" True)
      ("developer" True)
      ("user" True)
      ("assistant"
       (codex:agent-control-is-final-answer-phase $phase))
      ($other False))))

(= (codex:agent-control-keep-forked-response-item $response-item)
   (case (once (eval $response-item))
     (((CodexResponseItemMessage $role $content $phase)
       (codex:agent-control-keep-forked-message $role $phase))
      ((CodexResponseItemMessageWithId $id $role $content $phase)
       (codex:agent-control-keep-forked-message $role $phase))
      ((CodexResponseItemReasoning $id $summary $content $encrypted-content)
       False)
      ((CodexResponseItemLocalShellCall $id $call-id $status $action)
       False)
      ((CodexResponseItemFunctionCall $id $name $namespace $arguments $call-id)
       False)
      ((CodexResponseItemToolSearchCall
         $id
         $status
         $queries
         $source
         $targets
         $operation
         $tools)
       False)
      ((CodexResponseItemFunctionCallOutput $call-id $output)
       False)
      ((CodexResponseItemCustomToolCall $call-id $name $input)
       False)
      ((CodexResponseItemCustomToolCallOutput $call-id $name $output)
       False)
      ((CodexResponseItemToolSearchOutput
         $call-id
         $status
         $execution
         $tools)
       False)
      ((CodexResponseItemWebSearchCall $id $status $action)
       False)
      ((CodexResponseItemImageGenerationCall
         $id
         $status
         $revised-prompt
         $result)
       False)
      ((CodexResponseItemGhostSnapshot $ghost-commit)
       False)
      ((CodexResponseItemCompaction $encrypted-content)
       False)
      ((CodexResponseItemOther)
       False)
      ($other False))))

(= (codex:agent-control-keep-forked-rollout-item $item)
   (case (once (eval $item))
     (((CodexRolloutItemResponseItem $response-item)
       (codex:agent-control-keep-forked-response-item $response-item))
      ((CodexRolloutItemTurnContext $turn-context)
       False)
      ((CodexRolloutItemCompacted $compacted-item)
       True)
      ((CodexRolloutItemEventMsg $event)
       True)
      ((CodexRolloutItemSessionMeta $meta)
       True)
      ($other False))))

(= (codex:agent-control-retain-forked-rollout-items $items)
   (case $items
     ((() ())
      ($non-empty-items
       (let $head (list:first $non-empty-items)
         (let $tail (list:rest $non-empty-items)
           (case (codex:agent-control-retain-forked-rollout-items $tail)
             (($tail-retained
               (case (codex:agent-control-keep-forked-rollout-item $head)
                 ((True
                   (cons-atom $head $tail-retained))
                  (False
                   $tail-retained))))))))))))

(= (codex:agent-control-fork-mode-truncated-rollout-items
      $rollout-items
      $fork-mode)
   (case (eval $fork-mode)
     (((CodexSpawnAgentForkModeFullHistory)
       $rollout-items)
      ((CodexSpawnAgentForkModeLastNTurns $last-n-turns)
       (codex:truncate-rollout-to-last-n-fork-turns
         $rollout-items
         $last-n-turns)))))

(= (codex:agent-control-prepare-forked-rollout-items
      $rollout-items
      $fork-mode)
   (case
     (codex:agent-control-fork-mode-truncated-rollout-items
       $rollout-items
       $fork-mode)
     (($truncated-rollout-items
       (codex:agent-control-retain-forked-rollout-items
         $truncated-rollout-items)))))

(= (codex:agent-control-prepare-forked-initial-history
      $rollout-items
      $fork-mode)
   (case
     (codex:agent-control-prepare-forked-rollout-items
       $rollout-items
       $fork-mode)
     (($forked-rollout-items
       (codex:initial-history-forked $forked-rollout-items)))))

(= (codex:agent-control-registry-entry-metadata $entry)
   (eval (codex:agent-registry-entry-metadata $entry)))

(= (codex:agent-control-agent-id-for-path-from
      $entries
      $agent-path-key)
   (case $entries
     ((() CodexAbsent)
      ($non-empty-entries
       (let $head (list:first $non-empty-entries)
         (let $tail (list:rest $non-empty-entries)
           (case (== (codex:agent-registry-entry-key $head)
                     $agent-path-key)
             ((True
               (codex:agent-registry-metadata-agent-id
                 (codex:agent-control-registry-entry-metadata $head)))
              (False
               (codex:agent-control-agent-id-for-path-from
                 $tail
                 $agent-path-key))))))))))

(= (codex:agent-control-agent-id-for-path
      $registry-state
      $agent-path)
   (codex:agent-control-agent-id-for-path-from
     (codex:agent-registry-state-agent-tree (eval $registry-state))
     (codex:agent-path-as-str $agent-path)))

(= (codex:agent-control-agent-metadata-for-thread-from
      $entries
      $thread-id)
   (case $entries
     ((() CodexAbsent)
      ($non-empty-entries
       (let $head (list:first $non-empty-entries)
         (let $tail (list:rest $non-empty-entries)
           (let $metadata
             (codex:agent-control-registry-entry-metadata $head)
             (case (== (codex:agent-registry-metadata-agent-id $metadata)
                       $thread-id)
               ((True $metadata)
                (False
                 (codex:agent-control-agent-metadata-for-thread-from
                   $tail
                   $thread-id)))))))))))

(= (codex:agent-control-agent-metadata-for-thread
      $registry-state
      $thread-id)
   (codex:agent-control-agent-metadata-for-thread-from
     (codex:agent-registry-state-agent-tree (eval $registry-state))
     $thread-id))

(= (codex:agent-control-is-root-metadata $metadata)
   (case (eval (codex:agent-registry-metadata-agent-path $metadata))
     ((CodexAbsent False)
      ($agent-path (codex:is-agent-path-root $agent-path)))))

(= (codex:agent-control-live-agents-from $entries)
   (case $entries
     ((() ())
      ($non-empty-entries
       (let $head (list:first $non-empty-entries)
         (let $tail (list:rest $non-empty-entries)
           (let $metadata
             (codex:agent-control-registry-entry-metadata $head)
             (case (codex:agent-control-live-agents-from $tail)
               (($tail-live
                 (if (and
                       (not (== (codex:agent-registry-metadata-agent-id
                                  $metadata)
                                CodexAbsent))
                       (not (codex:agent-control-is-root-metadata $metadata)))
                     (cons-atom $metadata $tail-live)
                     $tail-live)))))))))))

(= (codex:agent-control-live-agents $registry-state)
   (codex:agent-control-live-agents-from
     (codex:agent-registry-state-agent-tree (eval $registry-state))))

(= (codex:agent-control-register-session-root
      $registry-state
      $current-thread-id
      $current-session-source)
   (case
     (eval
       (codex:agent-control-thread-spawn-parent-thread-id
         $current-session-source))
     ((CodexAbsent
       (codex:agent-registry-register-root-thread
         $registry-state
         $current-thread-id))
      ($parent-thread-id
       $registry-state))))

(= (codex:agent-control-prepare-thread-spawn-root-state
      $registry-state
      $parent-thread-id
      $depth)
   (if (== $depth 1)
       (codex:agent-registry-register-root-thread
         $registry-state
         $parent-thread-id)
       $registry-state))

(= (codex:agent-control-prepare-thread-spawn-reserve-path
      $registry-state
      $reservation
      $agent-path)
   (case $agent-path
     ((CodexAbsent
       (codex:agent-registry-reserve-ok $registry-state $reservation))
      ($path
       (codex:agent-registry-reserve-agent-path-for-reservation
         $registry-state
         $reservation
         $path)))))

(= (codex:agent-control-thread-spawn-session-source
      $parent-thread-id
      $depth
      $agent-path
      $agent-nickname
      $agent-role)
   (codex:session-source-subagent
     (codex:subagent-source-thread-spawn
       $parent-thread-id
       $depth
       $agent-path
       $agent-nickname
       $agent-role)))

(= (codex:agent-control-thread-spawn-metadata
      $agent-path
      $agent-nickname
      $agent-role)
   (codex:agent-registry-metadata
     CodexAbsent
     $agent-path
     $agent-nickname
     $agent-role
     CodexAbsent))

(= (codex:agent-control-prepare-thread-spawn
      $registry-state
      $reservation
      $user-defined-roles
      $parent-thread-id
      $depth
      $agent-path
      $agent-role
      $preferred-agent-nickname
      $choice-index)
   (let $root-state
     (codex:agent-control-prepare-thread-spawn-root-state
       $registry-state
       $parent-thread-id
       $depth)
     (case
       (codex:agent-control-prepare-thread-spawn-reserve-path
         $root-state
         $reservation
         $agent-path)
       (((CodexAgentRegistryReserveErr $error)
         (codex:agent-control-prepare-thread-spawn-err $error))
        ((CodexAgentRegistryReserveOk $path-state $path-reservation)
         (case
           (codex:agent-registry-reserve-agent-nickname-with-preference
             $path-state
             $path-reservation
             (codex:agent-control-agent-nickname-candidates
               $user-defined-roles
               $agent-role)
             $preferred-agent-nickname
             $choice-index)
           (((CodexAgentRegistryReserveErr $error)
             (codex:agent-control-prepare-thread-spawn-err $error))
            ((CodexAgentRegistryReserveOk
               $nickname-state
               $nickname-reservation)
             (let $agent-nickname
               (codex:agent-registry-spawn-reservation-reserved-agent-nickname
                 $nickname-reservation)
               (codex:agent-control-prepare-thread-spawn-ok
                 $nickname-state
                 $nickname-reservation
                 (codex:agent-control-thread-spawn-session-source
                   $parent-thread-id
                   $depth
                   $agent-path
                   $agent-nickname
                   $agent-role)
                 (codex:agent-control-thread-spawn-metadata
                   $agent-path
                   $agent-nickname
                   $agent-role)))))))))))

(= (codex:agent-control-get-agent-metadata $registry-state $agent-id)
   (codex:agent-control-agent-metadata-for-thread
     $registry-state
     $agent-id))

(= (codex:agent-control-default-metadata-for-thread $thread-id)
   (codex:agent-registry-metadata
     $thread-id
     CodexAbsent
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:agent-control-live-thread-metadata $registry-state $thread-id)
   (case
     (codex:agent-control-agent-metadata-for-thread
       $registry-state
       $thread-id)
     ((CodexAbsent
       (codex:agent-control-default-metadata-for-thread $thread-id))
      ($metadata $metadata))))

(= (codex:agent-control-thread-metadata-entry-sort-path $entry)
   (case
     (eval
       (codex:agent-registry-metadata-agent-path
         (codex:agent-control-thread-metadata-entry-metadata $entry)))
     ((CodexAbsent "")
      ($agent-path (codex:agent-path-as-str $agent-path)))))

(= (codex:agent-control-thread-metadata-entry-le $left $right)
   (let $left-path
     (codex:agent-control-thread-metadata-entry-sort-path $left)
     (let $right-path
       (codex:agent-control-thread-metadata-entry-sort-path $right)
       (case (== $left-path $right-path)
         ((True
           (codex:agent-control-text-le
             (codex:agent-control-thread-metadata-entry-thread-id $left)
             (codex:agent-control-thread-metadata-entry-thread-id $right)))
          (False
           (codex:agent-control-text-le $left-path $right-path)))))))

(= (codex:agent-control-sort-thread-metadata-entries $entries)
   (case $entries
     ((() ())
      ($non-empty-entries
       (let $head (list:first $non-empty-entries)
         (let $tail (list:rest $non-empty-entries)
           (case
             (codex:agent-control-sort-thread-metadata-entries $tail)
             (($sorted-tail
               (codex:agent-control-insert-thread-metadata-entry
                 $head
                 $sorted-tail))))))))))

(= (codex:agent-control-insert-thread-metadata-entry $entry $sorted)
   (case $sorted
     ((() ($entry))
      ($non-empty-sorted
       (let $head (list:first $non-empty-sorted)
         (let $tail (list:rest $non-empty-sorted)
           (case
             (codex:agent-control-thread-metadata-entry-le $entry $head)
             ((True (cons-atom $entry $non-empty-sorted))
              (False
               (case
                 (codex:agent-control-insert-thread-metadata-entry
                   $entry
                   $tail)
                 (($inserted-tail
                   (cons-atom $head $inserted-tail)))))))))))))

(= (codex:agent-control-thread-spawn-children-list-add
      ()
      $parent-thread-id
      $child)
   (let $child-entry
     $child
     (let $entry
       (codex:agent-control-thread-spawn-children-entry
         $parent-thread-id
         ($child-entry))
       ($entry))))

(= (codex:agent-control-thread-spawn-children-list-add
      $entries
      $parent-thread-id
      $child)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (case
         (== (codex:agent-control-thread-spawn-children-entry-parent-thread-id
               $head)
             $parent-thread-id)
         ((True
           (let $child-entry
             $child
             (let $children
               (codex:agent-control-thread-spawn-children-entry-children
                 $head)
               (let $entry
                 (codex:agent-control-thread-spawn-children-entry
                   $parent-thread-id
                   (cons-atom $child-entry $children))
                 (cons-atom $entry $tail)))))
          (False
           (let $updated-tail
             (codex:agent-control-thread-spawn-children-list-add
               $tail
               $parent-thread-id
               $child)
             (cons-atom $head $updated-tail))))))))

(= (codex:agent-control-thread-spawn-children-for-parent
      ()
      $parent-thread-id)
   ())

(= (codex:agent-control-thread-spawn-children-for-parent
      $entries
      $parent-thread-id)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (case
         (== (codex:agent-control-thread-spawn-children-entry-parent-thread-id
               $head)
             $parent-thread-id)
         ((True
           (codex:agent-control-thread-spawn-children-entry-children
             $head))
          (False
           (codex:agent-control-thread-spawn-children-for-parent
             $tail
             $parent-thread-id)))))))

(= (codex:agent-control-thread-spawn-children-remove-parent
      ()
      $parent-thread-id)
   ())

(= (codex:agent-control-thread-spawn-children-remove-parent
      $entries
      $parent-thread-id)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (case
         (== (codex:agent-control-thread-spawn-children-entry-parent-thread-id
               $head)
             $parent-thread-id)
         ((True $tail)
          (False
           (case
             (codex:agent-control-thread-spawn-children-remove-parent
               $tail
               $parent-thread-id)
             (($remaining-tail
               (cons-atom $head $remaining-tail))))))))))

(= (codex:agent-control-sort-thread-spawn-children-entry
      (CodexAgentControlThreadSpawnChildrenEntry
        $parent-thread-id
        $children))
   (case
     (codex:agent-control-sort-thread-metadata-entries $children)
     (($sorted-children
       (codex:agent-control-thread-spawn-children-entry
         $parent-thread-id
         $sorted-children)))))

(= (codex:agent-control-sort-thread-spawn-children-map $entries)
   (case $entries
     ((() ())
      ($non-empty-entries
       (let $head (list:first $non-empty-entries)
         (let $tail (list:rest $non-empty-entries)
           (case
             (codex:agent-control-sort-thread-spawn-children-map $tail)
             (($sorted-tail
               (case
                 (codex:agent-control-sort-thread-spawn-children-entry
                   $head)
                 (($sorted-head
                   (cons-atom
                     $sorted-head
                     $sorted-tail)))))))))))))

(= (codex:agent-control-live-thread-spawn-children-from
      $registry-state
      $snapshots)
   (case $snapshots
     ((() ())
      ($non-empty-snapshots
       (let $head (list:first $non-empty-snapshots)
         (let $tail (list:rest $non-empty-snapshots)
           (case
             (codex:agent-control-live-thread-spawn-children-from
               $registry-state
               $tail)
             (($tail-map
               (let $thread-id
                 (codex:agent-control-thread-snapshot-entry-thread-id $head)
                 (let $session-source
                   (codex:agent-control-thread-snapshot-entry-session-source
                     $head)
                   (case
                     (codex:agent-control-thread-spawn-parent-thread-id
                       $session-source)
                     ((CodexAbsent $tail-map)
                      ($parent-thread-id
                       (codex:agent-control-thread-spawn-children-list-add
                         $tail-map
                         $parent-thread-id
                         (codex:agent-control-thread-metadata-entry
                           $thread-id
                           (codex:agent-control-live-thread-metadata
                             $registry-state
                             $thread-id)))))))))))))))))

(= (codex:agent-control-live-thread-spawn-children
      $registry-state
      $snapshots)
   (codex:agent-control-sort-thread-spawn-children-map
     (codex:agent-control-live-thread-spawn-children-from
       $registry-state
       $snapshots)))

(= (codex:agent-control-open-thread-spawn-children
      $registry-state
      $snapshots
      $parent-thread-id)
   (codex:agent-control-thread-spawn-children-for-parent
     (codex:agent-control-live-thread-spawn-children
       $registry-state
       $snapshots)
     $parent-thread-id))

(= (codex:agent-control-thread-metadata-entry-thread-ids ())
   ())

(= (codex:agent-control-thread-metadata-entry-thread-ids $entries)
   (let $head (list:first $entries)
     (let $tail (list:rest $entries)
       (case
         (codex:agent-control-thread-metadata-entry-thread-id $head)
         (($thread-id
           (case
             (codex:agent-control-thread-metadata-entry-thread-ids $tail)
             (($tail-ids
               (cons-atom $thread-id $tail-ids))))))))))

(= (codex:agent-control-live-thread-spawn-descendants-from
      $children-map
      $stack)
   (case $stack
     ((() ())
      ($non-empty-stack
       (let $thread-id (list:first $non-empty-stack)
         (let $rest-stack (list:rest $non-empty-stack)
           (let $children
             (codex:agent-control-thread-spawn-children-for-parent
               $children-map
               $thread-id)
             (let $remaining-map
               (codex:agent-control-thread-spawn-children-remove-parent
                 $children-map
                 $thread-id)
               (case
                 (codex:agent-control-thread-metadata-entry-thread-ids
                   $children)
                 (($child-thread-ids
                   (case
                     (list:append $child-thread-ids $rest-stack)
                     (($next-stack
                       (case
                         (codex:agent-control-live-thread-spawn-descendants-from
                           $remaining-map
                           $next-stack)
                         (($tail-descendants
                            (cons-atom
                              $thread-id
                              $tail-descendants))))))))))))))))))

(= (codex:agent-control-live-thread-spawn-descendants
      $registry-state
      $snapshots
      $root-thread-id)
   (case
     (codex:agent-control-live-thread-spawn-children
       $registry-state
       $snapshots)
     (($children-map
       (case
         (codex:agent-control-thread-spawn-children-for-parent
           $children-map
           $root-thread-id)
         (($root-children
           (case
             (codex:agent-control-thread-spawn-children-remove-parent
               $children-map
               $root-thread-id)
             (($remaining-map
               (case
                 (codex:agent-control-thread-metadata-entry-thread-ids
                   $root-children)
                  (($stack
                    (codex:agent-control-live-thread-spawn-descendants-from
                      $remaining-map
                      $stack))))))))))))))

(= (codex:agent-control-list-live-agent-subtree-thread-ids
      $registry-state
      $snapshots
      $agent-id)
   (case
     (codex:agent-control-live-thread-spawn-descendants
       $registry-state
       $snapshots
       $agent-id)
     (($descendants
       (cons-atom $agent-id $descendants)))))

(= (codex:agent-control-current-agent-path $session-source)
   (case (codex:session-source-get-agent-path $session-source)
     ((CodexAbsent (codex:agent-path-root))
      ($agent-path $agent-path))))

(= (codex:agent-control-resolve-agent-path
      $current-session-source
      $agent-reference)
   (case
     (codex:agent-path-resolve
       (codex:agent-control-current-agent-path $current-session-source)
       $agent-reference)
     (((CodexAgentPathOk $agent-path)
       (codex:agent-control-ok $agent-path))
      ((CodexAgentPathErr $message)
       (codex:agent-control-err
         (codex:error-unsupported-operation $message))))))

(= (codex:agent-control-resolve-agent-reference
      $registry-state
      $current-thread-id
      $current-session-source
      $agent-reference)
   (case
     (codex:agent-control-resolve-agent-path
       $current-session-source
       $agent-reference)
     (((CodexAgentControlErr $error)
       (codex:agent-control-err $error))
      ((CodexAgentControlOk $agent-path)
       (case
         (codex:agent-control-agent-id-for-path
           $registry-state
           $agent-path)
         ((CodexAbsent
           (codex:agent-control-err
             (codex:error-unsupported-operation
               (format-args
                 "live agent path `{}` not found"
                 ((codex:agent-path-as-str $agent-path))))))
          ($thread-id
           (codex:agent-control-ok $thread-id))))))))

(= (codex:agent-control-context-reference-for-child
      $thread-id
      $metadata)
   (case (eval (codex:agent-registry-metadata-agent-path $metadata))
     ((CodexAbsent $thread-id)
      ($agent-path
       (codex:agent-path-name $agent-path)))))

(= (codex:agent-control-context-line-from-child $child)
   (case (codex:agent-control-thread-metadata-entry-thread-id $child)
     (($thread-id
       (case (codex:agent-control-thread-metadata-entry-metadata $child)
         (($metadata
           (case
             (codex:agent-control-context-reference-for-child
               $thread-id
               $metadata)
             (($reference
               (case
                 (codex:agent-registry-metadata-agent-nickname
                   $metadata)
                 (($nickname
                   (codex:format-subagent-context-line
                     $reference
                     $nickname))))))))))))))

(= (codex:agent-control-context-lines-from-children $children)
   (case $children
     ((() ())
      ($non-empty-children
       (let $head (list:first $non-empty-children)
         (let $tail (list:rest $non-empty-children)
           (let $line
             (eval (codex:agent-control-context-line-from-child $head))
             (let $tail-lines
               (eval (codex:agent-control-context-lines-from-children $tail))
               (cons-atom $line $tail-lines)))))))))

(= (codex:agent-control-context-text-from-children $children)
   (case $children
     ((() "")
      ($non-empty-children
       (let $head (list:first $non-empty-children)
         (let $tail (list:rest $non-empty-children)
           (case (codex:agent-control-context-line-from-child $head)
             (($line
               (case $tail
                 ((() $line)
                  ($non-empty-tail
                   (case
                     (codex:agent-control-context-text-from-children
                       $non-empty-tail)
                     (($tail-text
                       (str-concat
                         $line
                         (str-concat "\n" $tail-text)))))))))))))))))

(= (codex:agent-control-format-environment-context-subagents
      (CodexAgentControlErr $error))
   "")

(= (codex:agent-control-format-environment-context-subagents
      (CodexAgentControlOk $children))
   (codex:agent-control-context-text-from-children $children))

(= (codex:agent-control-agent-path-has-prefix-child
      $agent-path
      $prefix)
   (let $agent-path-str (codex:agent-path-as-str $agent-path)
     (let $prefix-str (codex:agent-path-as-str $prefix)
       (if (str-starts-with? $agent-path-str $prefix-str)
           (str-starts-with?
             (str-slice
               $agent-path-str
               (str-length $prefix-str)
               (str-length $agent-path-str))
             "/")
           False))))

(= (codex:agent-control-agent-matches-prefix
      $agent-path
      $prefix)
   (if (codex:is-agent-path-root $prefix)
       True
       (case $agent-path
         ((CodexAbsent False)
          ($path
           (if (== $path $prefix)
               True
               (codex:agent-control-agent-path-has-prefix-child
                 $path
                 $prefix)))))))

; Rust list_agents sorts by String::cmp over AgentPath strings and ThreadId
; fallback strings. AgentPath validation restricts path characters to this ASCII
; surface, and ThreadId fallback keys are UUID strings, so this rank table covers
; the sort keys this pure slice can receive.
(= (codex:agent-control-ascii-rank $char)
   (case $char
     (("-" 45)
      ("." 46)
      ("/" 47)
      ("0" 48)
      ("1" 49)
      ("2" 50)
      ("3" 51)
      ("4" 52)
      ("5" 53)
      ("6" 54)
      ("7" 55)
      ("8" 56)
      ("9" 57)
      ("A" 65)
      ("B" 66)
      ("C" 67)
      ("D" 68)
      ("E" 69)
      ("F" 70)
      ("G" 71)
      ("H" 72)
      ("I" 73)
      ("J" 74)
      ("K" 75)
      ("L" 76)
      ("M" 77)
      ("N" 78)
      ("O" 79)
      ("P" 80)
      ("Q" 81)
      ("R" 82)
      ("S" 83)
      ("T" 84)
      ("U" 85)
      ("V" 86)
      ("W" 87)
      ("X" 88)
      ("Y" 89)
      ("Z" 90)
      ("\\" 92)
      ("_" 95)
      ("a" 97)
      ("b" 98)
      ("c" 99)
      ("d" 100)
      ("e" 101)
      ("f" 102)
      ("g" 103)
      ("h" 104)
      ("i" 105)
      ("j" 106)
      ("k" 107)
      ("l" 108)
      ("m" 109)
      ("n" 110)
      ("o" 111)
      ("p" 112)
      ("q" 113)
      ("r" 114)
      ("s" 115)
      ("t" 116)
      ("u" 117)
      ("v" 118)
      ("w" 119)
      ("x" 120)
      ("y" 121)
      ("z" 122)
      ($other 10000))))

(= (codex:agent-control-text-le $left $right)
   (codex:agent-control-text-le-from $left $right 0))

(= (codex:agent-control-text-le-from $left $right $index)
   (case (>= $index (str-length $left))
     ((True True)
      (False
       (case (>= $index (str-length $right))
         ((True False)
          (False
           (let $left-rank
             (codex:agent-control-ascii-rank
               (str-slice $left $index (+ $index 1)))
             (let $right-rank
               (codex:agent-control-ascii-rank
                 (str-slice $right $index (+ $index 1)))
               (case (< $left-rank $right-rank)
                 ((True True)
                  (False
                   (case (> $left-rank $right-rank)
                     ((True False)
                      (False
                       (codex:agent-control-text-le-from
                         $left
                         $right
                         (+ $index 1)))))))))))))))))

(= (codex:agent-control-metadata-sort-path $metadata)
   (case (eval (codex:agent-registry-metadata-agent-path $metadata))
     ((CodexAbsent "")
      ($agent-path (codex:agent-path-as-str $agent-path)))))

(= (codex:agent-control-metadata-sort-agent-id $metadata)
   (case (eval (codex:agent-registry-metadata-agent-id $metadata))
     ((CodexAbsent "")
      ($agent-id $agent-id))))

(= (codex:agent-control-metadata-le $left $right)
   (let $left-path (codex:agent-control-metadata-sort-path $left)
     (let $right-path (codex:agent-control-metadata-sort-path $right)
       (if (== $left-path $right-path)
           (codex:agent-control-text-le
             (codex:agent-control-metadata-sort-agent-id $left)
             (codex:agent-control-metadata-sort-agent-id $right))
           (codex:agent-control-text-le $left-path $right-path)))))

(= (codex:agent-control-sort-live-agents $agents)
   (case $agents
     ((() ())
      ($non-empty-agents
       (let $head (list:first $non-empty-agents)
         (let $tail (list:rest $non-empty-agents)
           (case (codex:agent-control-sort-live-agents $tail)
             (($sorted-tail
               (codex:agent-control-insert-live-agent
                 $head
                 $sorted-tail))))))))))

(= (codex:agent-control-insert-live-agent $agent $sorted)
   (case $sorted
     ((() ($agent))
      ($non-empty-sorted
       (let $head (list:first $non-empty-sorted)
         (let $tail (list:rest $non-empty-sorted)
           (case (codex:agent-control-metadata-le $agent $head)
             ((True (cons-atom $agent $non-empty-sorted))
              (False
               (case (codex:agent-control-insert-live-agent $agent $tail)
                 (($inserted-tail
                   (cons-atom $head $inserted-tail)))))))))))))

(= (codex:agent-control-resolve-list-prefix
      $current-session-source
      $path-prefix)
   (case $path-prefix
     ((CodexAbsent
       (codex:agent-control-ok CodexAbsent))
      ($prefix
       (codex:agent-control-resolve-agent-path
         $current-session-source
         $prefix)))))

(= (codex:agent-control-prefix-allows $agent-path $resolved-prefix)
   (case $resolved-prefix
     ((CodexAbsent True)
      ($prefix
       (codex:agent-control-agent-matches-prefix
         $agent-path
         $prefix)))))

(= (codex:agent-control-status-for-thread $status-entries $thread-id)
   (case $status-entries
     ((() CodexAbsent)
      ($non-empty-statuses
       (let $head (list:first $non-empty-statuses)
         (let $tail (list:rest $non-empty-statuses)
           (if (== (codex:agent-control-status-entry-thread-id $head)
                   $thread-id)
               (codex:agent-control-status-entry-status $head)
               (codex:agent-control-status-for-thread
                 $tail
                 $thread-id))))))))

(= (codex:agent-control-root-listed-agents
      $registry-state
      $status-entries
      $resolved-prefix)
   (let $root-path (codex:agent-path-root)
     (if (codex:agent-control-prefix-allows $root-path $resolved-prefix)
         (case
           (codex:agent-control-agent-id-for-path
             $registry-state
             $root-path)
           ((CodexAbsent ())
            ($root-thread-id
             (case
               (codex:agent-control-status-for-thread
                 $status-entries
                 $root-thread-id)
               ((CodexAbsent ())
                ($root-status
                 ((codex:agent-control-listed-agent
                    (codex:agent-path-as-str $root-path)
                    $root-status
                    (codex:agent-control-root-last-task-message)))))))))
         ())))

(= (codex:agent-control-agent-name-from-metadata $metadata $thread-id)
   (case (eval (codex:agent-registry-metadata-agent-path $metadata))
     ((CodexAbsent $thread-id)
      ($agent-path (codex:agent-path-as-str $agent-path)))))

(= (codex:agent-control-listed-live-agent
      $metadata
      $status-entries
      $resolved-prefix)
   (case (eval (codex:agent-registry-metadata-agent-id $metadata))
     ((CodexAbsent ())
      ($thread-id
       (if
         (codex:agent-control-prefix-allows
           (eval (codex:agent-registry-metadata-agent-path $metadata))
           $resolved-prefix)
         (case
           (codex:agent-control-status-for-thread
             $status-entries
             $thread-id)
           ((CodexAbsent ())
            ($status
             ((codex:agent-control-listed-agent
                (codex:agent-control-agent-name-from-metadata
                  $metadata
                  $thread-id)
                $status
                (codex:agent-registry-metadata-last-task-message
                  $metadata))))))
         ())))))

(= (codex:agent-control-listed-live-agents
      $live-agents
      $status-entries
      $resolved-prefix)
   (case $live-agents
     ((() ())
      ($non-empty-live-agents
       (let $head (list:first $non-empty-live-agents)
         (let $tail (list:rest $non-empty-live-agents)
           (case
             (codex:agent-control-listed-live-agent
               $head
               $status-entries
               $resolved-prefix)
             (($head-listed
               (case
                 (codex:agent-control-listed-live-agents
                   $tail
                   $status-entries
                   $resolved-prefix)
                 (($tail-listed
                   (list:append $head-listed $tail-listed)))))))))))))

(= (codex:agent-control-list-agents-with-prefix
      $registry-state
      $status-entries
      $resolved-prefix)
   (case
     (codex:agent-control-sort-live-agents
       (codex:agent-control-live-agents $registry-state))
     (($live-agents
       (case
         (codex:agent-control-root-listed-agents
           $registry-state
           $status-entries
           $resolved-prefix)
         (($root-listed
           (case
             (codex:agent-control-listed-live-agents
               $live-agents
               $status-entries
               $resolved-prefix)
             (($live-listed
               (list:append $root-listed $live-listed)))))))))))

(= (codex:agent-control-list-agents
      $registry-state
      $status-entries
      $current-session-source
      $path-prefix)
   (case
     (codex:agent-control-resolve-list-prefix
       $current-session-source
       $path-prefix)
     (((CodexAgentControlErr $error)
       (codex:agent-control-err $error))
      ((CodexAgentControlOk $resolved-prefix)
       (codex:agent-control-ok
         (codex:agent-control-list-agents-with-prefix
           $registry-state
           $status-entries
           $resolved-prefix))))))

(= (codex:agent-control-render-input-preview-item $item)
   (case (eval $item)
     (((CodexUserInputText $text $text-elements)
       $text)
      ((CodexUserInputImage $image-url)
       "[image]")
      ((CodexUserInputLocalImage $path)
       (str-concat
         "[local_image:"
         (str-concat $path "]")))
      ((CodexUserInputSkill $name $path)
       (str-concat
         "[skill:$"
         (str-concat
           $name
           (str-concat
             "]("
             (str-concat $path ")")))))
      ((CodexUserInputMention $name $path)
       (str-concat
         "[mention:$"
         (str-concat
           $name
           (str-concat
             "]("
             (str-concat $path ")")))))
      ($other
       "[input]"))))

(= (codex:agent-control-render-input-preview-items $items)
   (case $items
     ((() "")
      ($non-empty-items
       (let $head (list:first $non-empty-items)
         (let $tail (list:rest $non-empty-items)
           (case
             (codex:agent-control-render-input-preview-item $head)
             (($head-preview
               (case $tail
                 ((() $head-preview)
                  ($non-empty-tail
                   (case
                     (codex:agent-control-render-input-preview-items
                       $non-empty-tail)
                     (($tail-preview
                       (str-concat
                         $head-preview
                         (str-concat "\n" $tail-preview)))))))))))))))))

(= (codex:agent-control-render-input-preview $initial-operation)
   (case (eval $initial-operation)
     (((CodexOpUserInput
         $items
         $environments
         $final-output-json-schema
         $responsesapi-client-metadata)
       (codex:agent-control-render-input-preview-items $items))
      ((CodexOpInterAgentCommunication
         (CodexInterAgentCommunication
           $author
           $recipient
           $other-recipients
           $content
           $trigger-turn))
       $content)
      ($other ""))))
