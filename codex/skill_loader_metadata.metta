; Narrow Rust-faithful core-skills loader metadata slice.
;
; This ports the pure helper logic from:
; - openai-codex/codex-rs/core-skills/src/loader.rs
;
; Covered in this increment:
; - `SkillParseError` display messages for the helper surfaces below
; - `sanitize_single_line`
; - `validate_len`
; - `default_skill_name`
; - `extract_frontmatter`
; - `resolve_str` / `resolve_required_str` / `resolve_color_str`
; - `resolve_asset_path`
; - `resolve_interface`
; - `resolve_dependency_tool` / `resolve_dependencies`
; - `resolve_policy`
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust obtains `Interface`, `Dependencies`, and `Policy` by deserializing
;   `.agents/openai.yaml`. This pure CeTTa slice accepts already-decoded loader
;   records and applies the same normalization/filtering algorithms.
; - Rust paths are `PathBuf`/`AbsolutePathBuf` and `resolve_asset_path` uses
;   `Path::components` before joining under the skill directory. This slice
;   carries visible path strings and mirrors the same Unix component rules with
;   lexical `/` splitting: empty and `.` components are ignored, `..` and
;   absolute paths are rejected, and the first retained component must be
;   `assets`.
; - Rust validates character counts. The current CeTTa string length primitive
;   is used here; the exposed behavior is identical for ASCII skill metadata,
;   which is the surface covered by the current tests.

!(import! &self list)
!(import! &self path)
!(import! &self str)
!(import! &self skill_model)

(= (codex:skill-loader-max-name-len) 64)
(= (codex:skill-loader-max-description-len) 1024)
(= (codex:skill-loader-max-short-description-len)
   (codex:skill-loader-max-description-len))
(= (codex:skill-loader-max-default-prompt-len)
   (codex:skill-loader-max-description-len))
(= (codex:skill-loader-max-dependency-type-len)
   (codex:skill-loader-max-name-len))
(= (codex:skill-loader-max-dependency-transport-len)
   (codex:skill-loader-max-name-len))
(= (codex:skill-loader-max-dependency-value-len)
   (codex:skill-loader-max-description-len))
(= (codex:skill-loader-max-dependency-description-len)
   (codex:skill-loader-max-description-len))
(= (codex:skill-loader-max-dependency-command-len)
   (codex:skill-loader-max-description-len))
(= (codex:skill-loader-max-dependency-url-len)
   (codex:skill-loader-max-description-len))

(= (codex:skill-loader-ok $value)
   (CodexSkillLoaderOk $value))

(= (codex:skill-loader-err $error)
   (CodexSkillLoaderErr $error))

(= (codex:skill-loader-parse-error-read $message)
   (CodexSkillParseErrorRead $message))

(= (codex:skill-loader-parse-error-missing-frontmatter)
   (CodexSkillParseErrorMissingFrontmatter))

(= (codex:skill-loader-parse-error-invalid-yaml $message)
   (CodexSkillParseErrorInvalidYaml $message))

(= (codex:skill-loader-parse-error-missing-field $field)
   (CodexSkillParseErrorMissingField $field))

(= (codex:skill-loader-parse-error-invalid-field $field $reason)
   (CodexSkillParseErrorInvalidField $field $reason))

(= (codex:skill-loader-parse-error-message
      (CodexSkillParseErrorRead $message))
   (str-concat "failed to read file: " $message))

(= (codex:skill-loader-parse-error-message
      (CodexSkillParseErrorMissingFrontmatter))
   "missing YAML frontmatter delimited by ---")

(= (codex:skill-loader-parse-error-message
      (CodexSkillParseErrorInvalidYaml $message))
   (str-concat "invalid YAML: " $message))

(= (codex:skill-loader-parse-error-message
      (CodexSkillParseErrorMissingField $field))
   (format-args "missing field `{}`" ($field)))

(= (codex:skill-loader-parse-error-message
      (CodexSkillParseErrorInvalidField $field $reason))
   (format-args "invalid {}: {}" ($field $reason)))

(= (codex:skill-loader-interface
      $display-name
      $short-description
      $icon-small
      $icon-large
      $brand-color
      $default-prompt)
   (CodexSkillLoaderInterface
     $display-name
     $short-description
     $icon-small
     $icon-large
     $brand-color
     $default-prompt))

(= (codex:skill-loader-dependencies $tools)
   (CodexSkillLoaderDependencies $tools))

(= (codex:skill-loader-dependency-tool
      $kind
      $value
      $description
      $transport
      $command
      $url)
   (CodexSkillLoaderDependencyTool
     $kind
     $value
     $description
     $transport
     $command
     $url))

(= (codex:skill-loader-policy $allow-implicit-invocation $products)
   (CodexSkillLoaderPolicy $allow-implicit-invocation $products))

(= (codex:skill-loader-loaded-metadata $interface $dependencies $policy)
   (CodexSkillLoaderLoadedMetadata $interface $dependencies $policy))

(= (codex:skill-loader-sanitize-single-line $raw)
   (str-join " " (str-split-whitespace $raw)))

(= (codex:skill-loader-invalid-length-reason $max-len)
   (format-args "exceeds maximum length of {} characters" ($max-len)))

(= (codex:skill-loader-validate-len $value $max-len $field-name)
   (if (== $value "")
       (codex:skill-loader-err
         (codex:skill-loader-parse-error-missing-field $field-name))
       (if (> (str-length $value) $max-len)
           (codex:skill-loader-err
             (codex:skill-loader-parse-error-invalid-field
               $field-name
               (codex:skill-loader-invalid-length-reason $max-len)))
           (codex:skill-loader-ok ()))))

(= (codex:skill-loader-last-list-item () $fallback)
   $fallback)

(= (codex:skill-loader-last-list-item $items $fallback)
   (let $head (list:first $items)
     (let $tail (list:rest $items)
       (codex:skill-loader-last-list-item $tail $head))))

(= (codex:skill-loader-default-skill-name $skill-path)
   (let $parent (path-dirname $skill-path)
     (let $parent-name
       (codex:skill-loader-last-list-item (path-parts $parent) CodexAbsent)
       (if (== $parent-name CodexAbsent)
           "skill"
           (let $sanitized
             (codex:skill-loader-sanitize-single-line $parent-name)
             (if (== $sanitized "")
                 "skill"
                 $sanitized))))))

(= (codex:skill-loader-strip-trailing-cr $text)
   (if (str-ends-with? $text "\r")
       (str-slice $text 0 (- (str-length $text) 1))
       $text))

(= (codex:skill-loader-normalize-split-lines () $drop-final-empty)
   ())

(= (codex:skill-loader-normalize-split-lines $parts $drop-final-empty)
   (let ($head $tail) (decons-atom $parts)
     (if (== $tail ())
         (if (and $drop-final-empty (== $head ""))
             ()
             ((codex:skill-loader-strip-trailing-cr $head)))
         (let $line (codex:skill-loader-strip-trailing-cr $head)
           (let $rest
             (codex:skill-loader-normalize-split-lines $tail $drop-final-empty)
             (cons-atom $line $rest))))))

(= (codex:skill-loader-lines $contents)
   (if (== $contents "")
       ()
       (codex:skill-loader-normalize-split-lines
         (str-split "\n" $contents)
         (str-ends-with? $contents "\n"))))

(= (codex:skill-loader-frontmatter-after-open () $reversed-lines)
   CodexAbsent)

(= (codex:skill-loader-frontmatter-after-open $lines $reversed-lines)
   (let $line (list:first $lines)
     (let $tail (list:rest $lines)
       (if (== (str-trim $line) "---")
           (if (== $reversed-lines ())
               CodexAbsent
               (str-join "\n" (list:reverse $reversed-lines)))
           (codex:skill-loader-frontmatter-after-open
             $tail
             (cons-atom $line $reversed-lines))))))

(= (codex:skill-loader-extract-frontmatter $contents)
   (let $lines (codex:skill-loader-lines $contents)
     (if (== $lines ())
         CodexAbsent
         (let $first-line (list:first $lines)
           (if (not (== (str-trim $first-line) "---"))
               CodexAbsent
               (codex:skill-loader-frontmatter-after-open
                 (list:rest $lines)
                 ()))))))

(= (codex:skill-loader-resolve-str $value $max-len $field)
   (if (== $value CodexAbsent)
       CodexAbsent
       (let $sanitized (codex:skill-loader-sanitize-single-line $value)
         (if (== $sanitized "")
             CodexAbsent
             (if (> (str-length $sanitized) $max-len)
                 CodexAbsent
                 $sanitized)))))

(= (codex:skill-loader-resolve-required-str $value $max-len $field)
   (if (== $value CodexAbsent)
       CodexAbsent
       (codex:skill-loader-resolve-str $value $max-len $field)))

(= (codex:skill-loader-is-ascii-hex-char $char)
   (let $found (str-find "0123456789abcdefABCDEF" $char)
     (if (== $found Empty) False True)))

(= (codex:skill-loader-are-ascii-hex-chars $text)
   (if (== $text "")
       True
       (if (codex:skill-loader-is-ascii-hex-char (str-slice $text 0 1))
           (codex:skill-loader-are-ascii-hex-chars
             (str-slice $text 1 (str-length $text)))
           False)))

(= (codex:skill-loader-resolve-color-str $value $field)
   (if (== $value CodexAbsent)
       CodexAbsent
       (let $trimmed (str-trim $value)
         (if (== $trimmed "")
             CodexAbsent
             (if (and
                   (== (str-length $trimmed) 7)
                   (== (str-slice $trimmed 0 1) "#"))
                 (if (codex:skill-loader-are-ascii-hex-chars
                       (str-slice $trimmed 1 (str-length $trimmed)))
                     $trimmed
                     CodexAbsent)
                 CodexAbsent)))))

(= (codex:skill-loader-normalize-asset-parts () $reversed-parts)
   (list:reverse $reversed-parts))

(= (codex:skill-loader-normalize-asset-parts $segments $reversed-parts)
   (let $head (list:first $segments)
     (let $tail (list:rest $segments)
       (if (or (== $head "") (== $head "."))
           (codex:skill-loader-normalize-asset-parts $tail $reversed-parts)
           (if (== $head "..")
               CodexAbsent
               (codex:skill-loader-normalize-asset-parts
                 $tail
                 (cons-atom $head $reversed-parts)))))))

(= (codex:skill-loader-relative-asset-path-from-parts $parts)
   (if (== $parts ())
       CodexAbsent
       (if (== (list:first $parts) "assets")
           (str-join "/" $parts)
           CodexAbsent)))

(= (codex:skill-loader-resolve-asset-path $skill-dir $field $path-value)
   (if (== $path-value CodexAbsent)
       CodexAbsent
       (if (== $path-value "")
           CodexAbsent
           (if (path-is-absolute? $path-value)
               CodexAbsent
               (case (codex:skill-loader-normalize-asset-parts
                       (str-split "/" $path-value)
                       ())
                 ((CodexAbsent CodexAbsent)
                  ($parts
                   (case (codex:skill-loader-relative-asset-path-from-parts $parts)
                     ((CodexAbsent CodexAbsent)
                      ($relative-path
                       (path-join $skill-dir $relative-path)))))))))))

(= (codex:skill-loader-resolved-interface-has-fields
      $display-name
      $short-description
      $icon-small
      $icon-large
      $brand-color
      $default-prompt)
   (if (not (== $display-name CodexAbsent))
       True
       (if (not (== $short-description CodexAbsent))
           True
           (if (not (== $icon-small CodexAbsent))
               True
               (if (not (== $icon-large CodexAbsent))
                   True
                   (if (not (== $brand-color CodexAbsent))
                       True
                       (not (== $default-prompt CodexAbsent))))))))

(= (codex:skill-loader-resolve-interface CodexAbsent $skill-dir)
   CodexAbsent)

(= (codex:skill-loader-resolve-interface
      (CodexSkillLoaderInterface
        $display-name
        $short-description
        $icon-small
        $icon-large
        $brand-color
        $default-prompt)
      $skill-dir)
   (let $resolved-display-name
     (codex:skill-loader-resolve-str
       $display-name
       (codex:skill-loader-max-name-len)
       "interface.display_name")
     (let $resolved-short-description
       (codex:skill-loader-resolve-str
         $short-description
         (codex:skill-loader-max-short-description-len)
         "interface.short_description")
       (let $resolved-icon-small
         (codex:skill-loader-resolve-asset-path
           $skill-dir
           "interface.icon_small"
           $icon-small)
         (let $resolved-icon-large
           (codex:skill-loader-resolve-asset-path
             $skill-dir
             "interface.icon_large"
             $icon-large)
           (let $resolved-brand-color
             (codex:skill-loader-resolve-color-str
               $brand-color
               "interface.brand_color")
             (let $resolved-default-prompt
               (codex:skill-loader-resolve-str
                 $default-prompt
                 (codex:skill-loader-max-default-prompt-len)
                 "interface.default_prompt")
               (if (codex:skill-loader-resolved-interface-has-fields
                     $resolved-display-name
                     $resolved-short-description
                     $resolved-icon-small
                     $resolved-icon-large
                     $resolved-brand-color
                     $resolved-default-prompt)
                   (CodexSkillInterface
                     $resolved-display-name
                     $resolved-short-description
                     $resolved-icon-small
                     $resolved-icon-large
                     $resolved-brand-color
                     $resolved-default-prompt)
                   CodexAbsent))))))))

(= (codex:skill-loader-resolve-dependency-tool
      (CodexSkillLoaderDependencyTool
        $kind
        $value
        $description
        $transport
        $command
        $url))
   (case
     (codex:skill-loader-resolve-required-str
       $kind
       (codex:skill-loader-max-dependency-type-len)
       "dependencies.tools.type")
     ((CodexAbsent CodexAbsent)
      ($type
       (case
         (codex:skill-loader-resolve-required-str
           $value
           (codex:skill-loader-max-dependency-value-len)
           "dependencies.tools.value")
         ((CodexAbsent CodexAbsent)
          ($resolved-value
           (CodexSkillToolDependency
             $type
             $resolved-value
             (codex:skill-loader-resolve-str
               $description
               (codex:skill-loader-max-dependency-description-len)
               "dependencies.tools.description")
             (codex:skill-loader-resolve-str
               $transport
               (codex:skill-loader-max-dependency-transport-len)
               "dependencies.tools.transport")
             (codex:skill-loader-resolve-str
               $command
               (codex:skill-loader-max-dependency-command-len)
               "dependencies.tools.command")
             (codex:skill-loader-resolve-str
               $url
               (codex:skill-loader-max-dependency-url-len)
               "dependencies.tools.url")))))))))

(= (codex:skill-loader-resolve-dependency-tools ())
   ())

(= (codex:skill-loader-resolve-dependency-tools $tools)
   (let $tool (list:first $tools)
     (let $tail (list:rest $tools)
       (let $resolved-tail
         (codex:skill-loader-resolve-dependency-tools $tail)
         (case (codex:skill-loader-resolve-dependency-tool $tool)
           ((CodexAbsent $resolved-tail)
            ($resolved-tool
             (cons-atom $resolved-tool $resolved-tail))))))))

(= (codex:skill-loader-resolve-dependencies CodexAbsent)
   CodexAbsent)

(= (codex:skill-loader-resolve-dependencies
      (CodexSkillLoaderDependencies $tools))
   (let $resolved-tools (codex:skill-loader-resolve-dependency-tools $tools)
     (if (== $resolved-tools ())
         CodexAbsent
         (CodexSkillDependencies $resolved-tools))))

(= (codex:skill-loader-resolve-policy CodexAbsent)
   CodexAbsent)

(= (codex:skill-loader-resolve-policy
      (CodexSkillLoaderPolicy $allow-implicit-invocation $products))
   (codex:core-skill-policy $allow-implicit-invocation $products))

(= (codex:skill-loader-resolve-loaded-metadata
      $skill-dir
      $interface
      $dependencies
      $policy)
   (codex:skill-loader-loaded-metadata
     (codex:skill-loader-resolve-interface $interface $skill-dir)
     (codex:skill-loader-resolve-dependencies $dependencies)
     (codex:skill-loader-resolve-policy $policy)))
