; Narrow Rust-faithful core-skills config-rules slice.
;
; This ports:
; - openai-codex/codex-rs/core-skills/src/config_rules.rs
;
; Covered in this increment:
; - `SkillConfigRuleSelector`
; - `SkillConfigRule`
; - `SkillConfigRules`
; - selector construction from decoded `skills.config` entries
; - user/session layer filtering in lowest-precedence-first order
; - duplicate selector replacement while preserving layer order
; - disabled skill path resolution by path and by skill name
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust reads `SkillsConfig` out of a `ConfigLayerStack` TOML value. This
;   CeTTa slice accepts already-decoded layer records carrying `skills.config`
;   entries because the broader config/TOML stack is not part of this module
;   boundary yet. The selector and precedence algorithms are unchanged.
; - Rust canonicalizes existing path selectors with `Path::canonicalize()`.
;   This pure CeTTa slice applies lexical `path-normalize`; it preserves the
;   same visible non-symlink path behavior until a shared filesystem
;   canonicalization layer is available here.
; - Rust returns a `HashSet<AbsolutePathBuf>` for disabled paths. This surface
;   returns a deterministic list-set with unique paths; membership behavior is
;   the same for downstream checks.

!(import! &self list)
!(import! &self path)
!(import! &self str)

(= (codex:skill-config-layer-source-user)
   (CodexSkillConfigLayerSourceUser))

(= (codex:skill-config-layer-source-session-flags)
   (CodexSkillConfigLayerSourceSessionFlags))

(= (codex:skill-config-layer-source-project)
   (CodexSkillConfigLayerSourceProject))

(= (codex:skill-config-layer-source-other $name)
   (CodexSkillConfigLayerSourceOther $name))

(= (codex:skill-config-entry $path $name $enabled)
   (CodexSkillConfigEntry $path $name $enabled))

(= (codex:skill-config-entry-path
      (CodexSkillConfigEntry $path $name $enabled))
   $path)

(= (codex:skill-config-entry-name
      (CodexSkillConfigEntry $path $name $enabled))
   $name)

(= (codex:skill-config-entry-enabled
      (CodexSkillConfigEntry $path $name $enabled))
   $enabled)

(= (codex:skill-config-layer $source $config-entries)
   (CodexSkillConfigLayer $source $config-entries))

(= (codex:skill-config-layer-source
      (CodexSkillConfigLayer $source $config-entries))
   $source)

(= (codex:skill-config-layer-config-entries
      (CodexSkillConfigLayer $source $config-entries))
   $config-entries)

(= (codex:skill-config-rule-selector-name $name)
   (CodexSkillConfigRuleSelectorName $name))

(= (codex:skill-config-rule-selector-path $path)
   (CodexSkillConfigRuleSelectorPath $path))

(= (codex:skill-config-rule $selector $enabled)
   (CodexSkillConfigRule $selector $enabled))

(= (codex:skill-config-rule-selector
      (CodexSkillConfigRule $selector $enabled))
   $selector)

(= (codex:skill-config-rule-enabled
      (CodexSkillConfigRule $selector $enabled))
   $enabled)

(= (codex:skill-config-rules $entries)
   (CodexSkillConfigRules $entries))

(= (codex:skill-config-rules-entries
      (CodexSkillConfigRules $entries))
   $entries)

(= (codex:is-skill-config-rules-layer-source $source)
   (case $source
     (((CodexSkillConfigLayerSourceUser) True)
      ((CodexSkillConfigLayerSourceSessionFlags) True)
      ($other False))))

(= (codex:skill-config-normalize-path $path-value)
   (if (== $path-value CodexAbsent)
       CodexAbsent
       (path-normalize $path-value)))

(= (codex:skill-config-rule-selector-from-entry $entry)
   (let $path-value (codex:skill-config-entry-path $entry)
     (let $name-value (codex:skill-config-entry-name $entry)
       (if (== $path-value CodexAbsent)
           (if (== $name-value CodexAbsent)
               CodexAbsent
               (let $name (str-trim $name-value)
                 (if (== $name "")
                     CodexAbsent
                     (codex:skill-config-rule-selector-name $name))))
           (if (== $name-value CodexAbsent)
               (codex:skill-config-rule-selector-path
                 (codex:skill-config-normalize-path $path-value))
               CodexAbsent)))))

(= (codex:skill-config-rule-list-retain-not-selector () $selector)
   ())

(= (codex:skill-config-rule-list-retain-not-selector $rules $selector)
   (let $rule (list:first $rules)
     (let $tail (list:rest $rules)
       (let $retained-tail
         (codex:skill-config-rule-list-retain-not-selector $tail $selector)
         (if (== (codex:skill-config-rule-selector $rule) $selector)
             $retained-tail
             (cons-atom $rule $retained-tail))))))

(= (codex:skill-config-rules-apply-config-entry $entries $config-entry)
   (case (codex:skill-config-rule-selector-from-entry $config-entry)
     ((CodexAbsent $entries)
      ($selector
       (list:push
         (codex:skill-config-rule-list-retain-not-selector
           $entries
           $selector)
         (codex:skill-config-rule
           $selector
           (codex:skill-config-entry-enabled $config-entry)))))))

(= (codex:skill-config-rules-apply-config-entries $entries ())
   $entries)

(= (codex:skill-config-rules-apply-config-entries $entries $config-entries)
   (let $head (list:first $config-entries)
     (let $tail (list:rest $config-entries)
       (let $updated
         (codex:skill-config-rules-apply-config-entry $entries $head)
         (codex:skill-config-rules-apply-config-entries $updated $tail)))))

(= (codex:skill-config-rules-from-layers $layers)
   (codex:skill-config-rules
     (codex:skill-config-rules-from-layers-acc $layers ())))

(= (codex:skill-config-rules-from-layers-acc () $entries)
   $entries)

(= (codex:skill-config-rules-from-layers-acc $layers $entries)
   (let $layer (list:first $layers)
     (let $tail (list:rest $layers)
       (let $source (codex:skill-config-layer-source $layer)
         (if (not (codex:is-skill-config-rules-layer-source $source))
             (codex:skill-config-rules-from-layers-acc $tail $entries)
             (let $updated
               (codex:skill-config-rules-apply-config-entries
                 $entries
                 (codex:skill-config-layer-config-entries $layer))
               (codex:skill-config-rules-from-layers-acc
                 $tail
                 $updated)))))))

(= (codex:skill-config-list-contains $items $item)
   (if (== $items ())
       False
       (let $head (list:first $items)
         (let $tail (list:rest $items)
           (if (== $head $item)
               True
               (codex:skill-config-list-contains $tail $item))))))

(= (codex:skill-config-list-add $items $item)
   (if (codex:skill-config-list-contains $items $item)
       $items
       (list:push $items $item)))

(= (codex:skill-config-list-remove () $item)
   ())

(= (codex:skill-config-list-remove $items $item)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (let $rest (codex:skill-config-list-remove $tail $item)
         (if (== $head $item)
             $rest
             (cons-atom $head $rest))))))

(= (codex:skill-config-skill-name
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

(= (codex:skill-config-skill-path
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

(= (codex:resolve-disabled-skill-paths $skills $rules)
   (codex:resolve-disabled-skill-paths-from-rules
     $skills
     (codex:skill-config-rules-entries $rules)
     ()))

(= (codex:resolve-disabled-skill-paths-from-rules $skills () $disabled-paths)
   $disabled-paths)

(= (codex:resolve-disabled-skill-paths-from-rules $skills $rules $disabled-paths)
   (let $rule (list:first $rules)
     (let $tail (list:rest $rules)
       (let $updated
         (codex:resolve-disabled-skill-paths-for-rule
           $skills
           $rule
           $disabled-paths)
         (codex:resolve-disabled-skill-paths-from-rules
           $skills
           $tail
           $updated)))))

(= (codex:resolve-disabled-skill-paths-for-rule $skills $rule $disabled-paths)
   (let $enabled (codex:skill-config-rule-enabled $rule)
     (case (codex:skill-config-rule-selector $rule)
       (((CodexSkillConfigRuleSelectorPath $path)
         (if $enabled
             (codex:skill-config-list-remove $disabled-paths $path)
             (codex:skill-config-list-add $disabled-paths $path)))
        ((CodexSkillConfigRuleSelectorName $name)
         (codex:resolve-disabled-skill-paths-for-name
           $skills
           $name
           $enabled
           $disabled-paths))))))

(= (codex:resolve-disabled-skill-paths-for-name () $name $enabled $disabled-paths)
   $disabled-paths)

(= (codex:resolve-disabled-skill-paths-for-name $skills $name $enabled $disabled-paths)
   (let $skill (list:first $skills)
     (let $tail (list:rest $skills)
       (let $path (codex:skill-config-skill-path $skill)
         (let $updated
           (if (== (codex:skill-config-skill-name $skill) $name)
               (if $enabled
                   (codex:skill-config-list-remove $disabled-paths $path)
                   (codex:skill-config-list-add $disabled-paths $path))
               $disabled-paths)
           (codex:resolve-disabled-skill-paths-for-name
             $tail
             $name
             $enabled
             $updated))))))
