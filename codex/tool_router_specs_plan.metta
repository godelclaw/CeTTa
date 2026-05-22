; Rust-faithful ToolRouter specs/find_spec slice.
;
; This ports deterministic helper behavior from:
; - openai-codex/codex-rs/core/src/tools/router.rs
;   - ToolRouter::specs
;   - ToolRouter::model_visible_specs
;   - ToolRouter::find_spec
; - openai-codex/codex-rs/code-mode/src/description.rs
;   - is_code_mode_nested_tool
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust computes `model_visible_specs` during `ToolRouter::from_config` after
;   `build_specs_with_discoverable_tools` builds the registry. This pure slice
;   receives the configured specs directly and applies the same projection and
;   code-mode-only filter.
; - Rust's ToolRouter owns the registry too. This slice covers only the
;   configured-spec and model-visible-spec helper surface; dispatch behavior is
;   ported in `tool_router_dispatch_plan`.

!(import! &self tool_name)

(= (codex:tool-router-specs-responses-api-tool $name)
   (CodexResponsesApiTool
     $name
     CodexAbsent
     False
     CodexAbsent
     CodexAbsent
     CodexAbsent))

(= (codex:tool-router-specs-function-spec $name)
   (CodexToolSpecFunction
     (codex:tool-router-specs-responses-api-tool $name)))

(= (codex:tool-router-specs-freeform-spec $name)
   (CodexToolSpecFreeform
     (CodexFreeformTool
       $name
       CodexAbsent
       CodexAbsent
       CodexAbsent
       CodexAbsent)))

(= (codex:tool-router-specs-namespace-function $name)
   (CodexResponsesApiNamespaceToolFunction
     (codex:tool-router-specs-responses-api-tool $name)))

(= (codex:tool-router-specs-namespace-spec
      $namespace-name
      $description
      $tools)
   (CodexToolSpecNamespace
     (CodexResponsesApiNamespace
       $namespace-name
       $description
       $tools)))

(= (codex:tool-router-specs-configured-spec
      $spec
      $supports-parallel-tool-calls)
   (CodexConfiguredToolSpec
     $spec
     $supports-parallel-tool-calls))

(= (codex:tool-router-specs-spec-of-configured
      (CodexConfiguredToolSpec $spec $supports-parallel-tool-calls))
   $spec)

(= (codex:tool-router-specs-spec-name
      (CodexToolSpecFunction
        (CodexResponsesApiTool
          $name
          $description
          $strict
          $defer-loading
          $parameters
          $output-schema)))
   $name)

(= (codex:tool-router-specs-spec-name
      (CodexToolSpecFreeform
        (CodexFreeformTool
          $name
          $description
          $format-type
          $format-syntax
          $format-definition)))
   $name)

(= (codex:tool-router-specs-spec-name
      (CodexToolSpecNamespace
        (CodexResponsesApiNamespace $name $description $tools)))
   $name)

(= (codex:tool-router-specs-spec-name (CodexToolSpecToolSearch))
   "tool_search")

(= (codex:tool-router-specs-spec-name
      (CodexToolSpecToolSearch
        $execution
        $description
        $parameters))
   "tool_search")

(= (codex:tool-router-specs-spec-name (CodexToolSpecLocalShell))
   "local_shell")

(= (codex:tool-router-specs-spec-name
      (CodexToolSpecImageGeneration $output-format))
   "image_generation")

(= (codex:tool-router-specs-spec-name (CodexToolSpecWebSearch))
   "web_search")

(= (codex:tool-router-specs-configured-spec-name
      (CodexConfiguredToolSpec $spec $supports-parallel-tool-calls))
   (codex:tool-router-specs-spec-name $spec))

(= (codex:tool-router-specs-from-configured ())
   ())

(= (codex:tool-router-specs-from-configured $configured-specs)
   (let ($head $tail) (decons-atom $configured-specs)
     (let $spec (codex:tool-router-specs-spec-of-configured $head)
       (let $rest (codex:tool-router-specs-from-configured $tail)
         (cons-atom $spec $rest)))))

(= (codex:tool-router-specs-public-code-tool-name)
   "exec")

(= (codex:tool-router-specs-wait-tool-name)
   "wait")

(= (codex:tool-router-specs-is-code-mode-nested-tool $tool-name)
   (and
     (not (== $tool-name (codex:tool-router-specs-public-code-tool-name)))
     (not (== $tool-name (codex:tool-router-specs-wait-tool-name)))))

(= (codex:tool-router-model-visible-specs-from-configured
      ()
      $code-mode-only-enabled)
   ())

(= (codex:tool-router-model-visible-specs-from-configured
      $configured-specs
      False)
   (codex:tool-router-specs-from-configured $configured-specs))

(= (codex:tool-router-model-visible-specs-from-configured
      $configured-specs
      True)
   (let ($head $tail) (decons-atom $configured-specs)
     (let $tail-visible
       (codex:tool-router-model-visible-specs-from-configured
         $tail
         True)
       (if (codex:tool-router-specs-is-code-mode-nested-tool
             (codex:tool-router-specs-configured-spec-name $head))
           $tail-visible
           (let $spec (codex:tool-router-specs-spec-of-configured $head)
             (cons-atom $spec $tail-visible))))))

(= (codex:tool-router-find-namespace-function
      $namespace-name
      ()
      (CodexToolName $name $namespace))
   CodexAbsent)

(= (codex:tool-router-find-namespace-function
      $namespace-name
      $tools
      (CodexToolName $name $namespace))
   (if (not (== $namespace $namespace-name))
       CodexAbsent
       (let ($head $tail) (decons-atom $tools)
         (case $head
           (((CodexResponsesApiNamespaceToolFunction $function-tool)
             (case $function-tool
               (((CodexResponsesApiTool
                   $tool-name
                   $description
                   $strict
                   $defer-loading
                   $parameters
                   $output-schema)
                 (if (== $tool-name $name)
                     (CodexToolSpecFunction $function-tool)
                     (codex:tool-router-find-namespace-function
                       $namespace-name
                       $tail
                       (CodexToolName $name $namespace))))))))))))

(= (codex:tool-router-find-spec-match
      (CodexConfiguredToolSpec $spec $supports-parallel-tool-calls)
      (CodexToolName $name $namespace))
   (case $spec
     (((CodexToolSpecFunction
         (CodexResponsesApiTool
           $tool-name
           $description
           $strict
           $defer-loading
           $parameters
           $output-schema))
       (if (and (== $namespace CodexAbsent)
                (== $tool-name $name))
           $spec
           CodexAbsent))
      ((CodexToolSpecFreeform
         (CodexFreeformTool
           $tool-name
           $description
           $format-type
           $format-syntax
           $format-definition))
       (if (and (== $namespace CodexAbsent)
                (== $tool-name $name))
           $spec
           CodexAbsent))
      ((CodexToolSpecNamespace
         (CodexResponsesApiNamespace $namespace-name $description $tools))
       (codex:tool-router-find-namespace-function
         $namespace-name
         $tools
         (CodexToolName $name $namespace)))
      ((CodexToolSpecToolSearch) CodexAbsent)
      ((CodexToolSpecToolSearch $execution $description $parameters)
       CodexAbsent)
      ((CodexToolSpecLocalShell) CodexAbsent)
      ((CodexToolSpecImageGeneration $output-format) CodexAbsent)
      ((CodexToolSpecWebSearch) CodexAbsent))))

(= (codex:tool-router-find-spec-from-configured
      ()
      $tool-name)
   CodexAbsent)

(= (codex:tool-router-find-spec-from-configured
      $configured-specs
      $tool-name)
   (let ($head $tail) (decons-atom $configured-specs)
     (case (codex:tool-router-find-spec-match $head $tool-name)
       ((CodexAbsent
         (codex:tool-router-find-spec-from-configured
           $tail
           $tool-name))
        ((CodexToolSpecFunction $tool)
         (CodexToolSpecFunction $tool))
        ((CodexToolSpecFreeform $tool)
         (CodexToolSpecFreeform $tool))))))
