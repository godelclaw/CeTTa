; Rust-faithful pure AgentControl boundary slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/agent/control.rs
;
; Covered in this increment:
; - thread_spawn_parent_thread_id
; - thread_spawn_depth
; - register_session_root
; - get_agent_metadata registry forwarding
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
; - CeTTa callers often pass registry metadata through local helper equations.
;   Rust stores concrete structs, so this boundary forces metadata evaluation
;   while scanning registry entries before applying the same field tests.

!(import! &self agent_path)
!(import! &self agent_registry)
!(import! &self error)
!(import! &self list)
!(import! &self protocol)
!(import! &self session_prefix)
!(import! &self str)

(= (codex:agent-control-ok $value)
   (CodexAgentControlOk $value))

(= (codex:agent-control-err $error)
   (CodexAgentControlErr $error))

(= (codex:agent-control-root-last-task-message)
   "Main thread")

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
           (if (== (codex:agent-registry-entry-key $head)
                   $agent-path-key)
               (codex:agent-registry-metadata-agent-id
                 (codex:agent-control-registry-entry-metadata $head))
               (codex:agent-control-agent-id-for-path-from
                 $tail
                 $agent-path-key))))))))

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
             (if (== (codex:agent-registry-metadata-agent-id $metadata)
                     $thread-id)
                 $metadata
                 (codex:agent-control-agent-metadata-for-thread-from
                   $tail
                   $thread-id)))))))))

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

(= (codex:agent-control-get-agent-metadata $registry-state $agent-id)
   (codex:agent-control-agent-metadata-for-thread
     $registry-state
     $agent-id))

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
