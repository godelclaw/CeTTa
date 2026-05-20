; Narrow Rust-faithful core-skills explicit mention selection slice.
;
; This ports:
; - openai-codex/codex-rs/core-skills/src/injection.rs
;
; Covered in this increment:
; - `collect_explicit_skill_mentions`
; - structured `UserInput::Skill` priority
; - text `$skill-name` mention selection preserving skill order
; - explicit linked skill path selection preserving skill order
; - disabled-path, duplicate-path, ambiguous-name, and connector-conflict filters
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust carries `HashSet`/`HashMap` state. This CeTTa surface uses
;   deterministic list-backed sets and count lists. Membership and lookup
;   behavior are the same for the ported selection algorithm.
; - Rust converts structured skill paths with
;   `AbsolutePathBuf::relative_to_current_dir`. This CeTTa surface applies
;   lexical `path-normalize` to the supplied path string because this boundary
;   does not yet have the broader absolute-path layer. Text-linked resource
;   paths are intentionally compared as supplied, matching the Rust path-string
;   comparison after `skill://` prefix removal.

!(import! &self list)
!(import! &self path)
!(import! &self codex:tool_mentions)
!(import! &self codex:skill_mention_counts)

(= (codex:skill-explicit-state
      $selected
      $seen-names
      $seen-paths
      $blocked-plain-names)
   (CodexSkillExplicitMentionState
     $selected
     $seen-names
     $seen-paths
     $blocked-plain-names))

(= (codex:skill-explicit-state-selected
      (CodexSkillExplicitMentionState
        $selected
        $seen-names
        $seen-paths
        $blocked-plain-names))
   $selected)

(= (codex:skill-explicit-state-seen-names
      (CodexSkillExplicitMentionState
        $selected
        $seen-names
        $seen-paths
        $blocked-plain-names))
   $seen-names)

(= (codex:skill-explicit-state-seen-paths
      (CodexSkillExplicitMentionState
        $selected
        $seen-names
        $seen-paths
        $blocked-plain-names))
   $seen-paths)

(= (codex:skill-explicit-state-blocked-plain-names
      (CodexSkillExplicitMentionState
        $selected
        $seen-names
        $seen-paths
        $blocked-plain-names))
   $blocked-plain-names)

(= (codex:skill-explicit-skill-name
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $name)

(= (codex:skill-explicit-skill-path
      (CodexSkillMetadata
        $name
        $description
        $short-description
        $interface
        $dependencies
        $path
        $scope
        $enabled))
   $path)

(= (codex:skill-explicit-list-contains $items $item)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head $item)
               True
               (codex:skill-explicit-list-contains $tail $item))))))

(= (codex:skill-explicit-list-add $items $item)
   (if (codex:skill-explicit-list-contains $items $item)
       $items
       (list:append $items ($item))))

(= (codex:skill-explicit-state-add-selected
      (CodexSkillExplicitMentionState
        $selected
        $seen-names
        $seen-paths
        $blocked-plain-names)
      $skill)
   (let $name (codex:skill-explicit-skill-name $skill)
     (let $skill-path (codex:skill-explicit-skill-path $skill)
       (CodexSkillExplicitMentionState
         (list:append $selected ($skill))
         (codex:skill-explicit-list-add $seen-names $name)
         (codex:skill-explicit-list-add $seen-paths $skill-path)
         $blocked-plain-names))))

(= (codex:skill-explicit-state-block-plain-name
      (CodexSkillExplicitMentionState
        $selected
        $seen-names
        $seen-paths
        $blocked-plain-names)
      $name)
   (CodexSkillExplicitMentionState
     $selected
     $seen-names
     $seen-paths
     (codex:skill-explicit-list-add $blocked-plain-names $name)))

(= (codex:skill-explicit-find-skill-by-path () $skill-path)
   CodexAbsent)

(= (codex:skill-explicit-find-skill-by-path $skills $skill-path)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (if (== (codex:skill-explicit-skill-path $skill) $skill-path)
           $skill
           (codex:skill-explicit-find-skill-by-path $tail $skill-path)))))

(= (codex:skill-explicit-normalize-structured-path $skill-path)
   (path-normalize $skill-path))

(= (codex:collect-explicit-skill-mentions $inputs $skills $disabled-paths $connector-slug-counts)
   (let $skill-name-counts
     (codex:skill-name-counts-exact
       (codex:build-skill-name-counts $skills $disabled-paths))
     (let $after-structured
       (codex:collect-explicit-skill-mentions-structured
         $inputs
         $skills
         $disabled-paths
         (codex:skill-explicit-state () () () ()))
       (codex:skill-explicit-state-selected
         (codex:collect-explicit-skill-mentions-text-inputs
           $inputs
           $skills
           $disabled-paths
           $skill-name-counts
           $connector-slug-counts
           $after-structured)))))

(= (codex:collect-explicit-skill-mentions-structured
      ()
      $skills
      $disabled-paths
      $state)
   $state)

(= (codex:collect-explicit-skill-mentions-structured-input
      $skills
      $disabled-paths
      $state
      $name
      $raw-path)
   (let $blocked-state
     (codex:skill-explicit-state-block-plain-name $state $name)
     (let $skill-path
       (codex:skill-explicit-normalize-structured-path $raw-path)
       (let $seen-paths
         (codex:skill-explicit-state-seen-paths $blocked-state)
         (if (codex:skill-explicit-list-contains $disabled-paths $skill-path)
             $blocked-state
             (if (codex:skill-explicit-list-contains $seen-paths $skill-path)
                 $blocked-state
                 (case (codex:skill-explicit-find-skill-by-path
                         $skills
                         $skill-path)
                   ((CodexAbsent $blocked-state)
                    ($skill
                     (codex:skill-explicit-state-add-selected
                       $blocked-state
                       $skill))))))))))

(= (codex:collect-explicit-skill-mentions-structured
      $inputs
      $skills
      $disabled-paths
      $state)
   (let $input (list:first $inputs)
     (let $tail (list:rest $inputs)
       (case $input
         (((CodexUserInputSkill $name $raw-path)
           (let $next-state
             (codex:collect-explicit-skill-mentions-structured-input
               $skills
               $disabled-paths
               $state
               $name
               $raw-path)
             (codex:collect-explicit-skill-mentions-structured
               $tail
               $skills
               $disabled-paths
               $next-state)))
          ($other
           (codex:collect-explicit-skill-mentions-structured
             $tail
             $skills
             $disabled-paths
             $state)))))))

(= (codex:is-skill-explicit-ignored-path-kind $path)
   (let $kind (codex:tool-kind-for-path $path)
     (if (== $kind (codex:tool-mention-kind-app))
         True
         (if (== $kind (codex:tool-mention-kind-mcp))
             True
             (if (== $kind (codex:tool-mention-kind-plugin))
                 True
                 False)))))

(= (codex:skill-explicit-mention-skill-paths $paths $acc)
   (if (== $paths ())
       $acc
       (let $head (list:first $paths)
         (let $tail (list:rest $paths)
           (codex:skill-explicit-mention-skill-paths
             $tail
             (if (codex:is-skill-explicit-ignored-path-kind $head)
                 $acc
                 (codex:skill-explicit-list-add
                   $acc
                   (codex:normalize-skill-path $head))))))))

(= (codex:is-skill-explicit-mentions-empty
      (CodexToolMentions $names $paths $plain-names))
   (if (== $names ())
       (if (== $paths ())
           True
           False)
       False))

(= (codex:select-explicit-skills-from-mentions
      $skills
      $disabled-paths
      $skill-name-counts
      $connector-slug-counts
      $mentions
      $state)
   (if (codex:is-skill-explicit-mentions-empty $mentions)
       $state
       (let $mention-skill-paths
         (codex:skill-explicit-mention-skill-paths
           (codex:tool-mentions-paths $mentions)
           ())
         (let $after-paths
           (codex:select-explicit-skills-from-mention-paths
             $skills
             $disabled-paths
             $mention-skill-paths
             $state)
           (codex:select-explicit-skills-from-plain-names
             $skills
             $disabled-paths
             $skill-name-counts
             $connector-slug-counts
             (codex:tool-mentions-plain-names $mentions)
             $after-paths)))))

(= (codex:select-explicit-skills-from-mention-paths
      ()
      $disabled-paths
      $mention-skill-paths
      $state)
   $state)

(= (codex:select-explicit-skills-from-mention-paths
      $skills
      $disabled-paths
      $mention-skill-paths
      $state)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $skill-path (codex:skill-explicit-skill-path $skill)
         (let $seen-paths (codex:skill-explicit-state-seen-paths $state)
           (let $next-state
             (if (codex:skill-explicit-list-contains $disabled-paths $skill-path)
                 $state
                 (if (codex:skill-explicit-list-contains $seen-paths $skill-path)
                     $state
                     (if (codex:skill-explicit-list-contains
                           $mention-skill-paths
                           $skill-path)
                         (codex:skill-explicit-state-add-selected $state $skill)
                         $state)))
             (codex:select-explicit-skills-from-mention-paths
               $tail
               $disabled-paths
               $mention-skill-paths
               $next-state)))))))

(= (codex:skill-explicit-connector-count $connector-slug-counts $skill-name)
   (codex:skill-name-count-list-get
     $connector-slug-counts
     (codex:skill-mention-counts-ascii-lower-text $skill-name)))

(= (codex:select-explicit-skills-from-plain-names
      ()
      $disabled-paths
      $skill-name-counts
      $connector-slug-counts
      $plain-names
      $state)
   $state)

(= (codex:select-explicit-skills-from-plain-names
      $skills
      $disabled-paths
      $skill-name-counts
      $connector-slug-counts
      $plain-names
      $state)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $name (codex:skill-explicit-skill-name $skill)
         (let $skill-path (codex:skill-explicit-skill-path $skill)
           (let $seen-paths (codex:skill-explicit-state-seen-paths $state)
             (let $blocked-plain-names
               (codex:skill-explicit-state-blocked-plain-names $state)
               (let $seen-names (codex:skill-explicit-state-seen-names $state)
                 (let $next-state
                   (if (codex:skill-explicit-list-contains
                         $disabled-paths
                         $skill-path)
                       $state
                       (if (codex:skill-explicit-list-contains
                             $seen-paths
                             $skill-path)
                           $state
                           (if (codex:skill-explicit-list-contains
                                 $blocked-plain-names
                                 $name)
                               $state
                               (if (not (codex:skill-explicit-list-contains
                                          $plain-names
                                          $name))
                                   $state
                                   (let $skill-count
                                     (codex:skill-name-count-list-get
                                       $skill-name-counts
                                       $name)
                                     (let $connector-count
                                       (codex:skill-explicit-connector-count
                                         $connector-slug-counts
                                         $name)
                                       (if (not (== $skill-count 1))
                                           $state
                                           (if (not (== $connector-count 0))
                                               $state
                                               (if (codex:skill-explicit-list-contains
                                                     $seen-names
                                                     $name)
                                                   $state
                                                   (codex:skill-explicit-state-add-selected
                                                     $state
                                                     $skill))))))))))
                   (codex:select-explicit-skills-from-plain-names
                     $tail
                     $disabled-paths
                     $skill-name-counts
                     $connector-slug-counts
                     $plain-names
                     $next-state))))))))))

(= (codex:collect-explicit-skill-mentions-text-inputs
      ()
      $skills
      $disabled-paths
      $skill-name-counts
      $connector-slug-counts
      $state)
   $state)

(= (codex:collect-explicit-skill-mentions-text-inputs
      $inputs
      $skills
      $disabled-paths
      $skill-name-counts
      $connector-slug-counts
      $state)
   (let $input (list:first $inputs)
     (let $tail (list:rest $inputs)
       (case $input
         (((CodexUserInputText $text $text-elements)
           (let $next-state
             (codex:select-explicit-skills-from-mentions
               $skills
               $disabled-paths
               $skill-name-counts
               $connector-slug-counts
               (codex:extract-tool-mentions $text)
               $state)
             (codex:collect-explicit-skill-mentions-text-inputs
               $tail
               $skills
               $disabled-paths
               $skill-name-counts
               $connector-slug-counts
               $next-state)))
          ($other
           (codex:collect-explicit-skill-mentions-text-inputs
             $tail
             $skills
             $disabled-paths
             $skill-name-counts
             $connector-slug-counts
             $state)))))))
