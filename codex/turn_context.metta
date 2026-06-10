; Rust-faithful turn context slice (core-loop spine slice 1).
;
; This ports the data spine of:
; - openai-codex/codex-rs/core/src/session/turn_context.rs
;
; Covered in this increment:
; - TurnSkillsContext record and TurnSkillsContext::new
; - TurnEnvironment record and TurnEnvironment::selection
; - the TurnContext record: all 44 Rust fields under their exact names,
;   grouped into seven field-group records (turn_context_parts_a/b)
; - TurnContext::model_context_window as a value-level computation
; - the supported-reasoning-level midpoint selection from with_model
; - TurnContext::resolve_path over the session cwd
;
; Deferred to later spine slices (each needs unported collaborators):
; - with_model's full flow (models manager), file_system_sandbox_context
;   (sandbox policy transforms), to_turn_context_item (protocol item;
;   also protocol must not be imported into recursion-heavy modules),
;   compact_prompt's SUMMARIZATION_PROMPT fallback (compact.rs),
;   permission_profile/apps_enabled (permission profile + auth manager
;   runtime), build_per_turn_config and local_time_context (Config load,
;   time native).
;
; Required slice-local deviations from Rust, documented for audit:
; - The flat 44-field struct is represented as seven group records
;   (identity/model/environment/instructions/permissions/tools/state);
;   a 44-arity constructor with full-destructure getters would exceed
;   the evaluator's module-size tolerance (see
;   tests/repro_evaluator_materialization.metta).
; - Arc/Mutex wrappers are identity in CeTTa's term model; the
;   implicit-invocation seen-skills set is an explicit list value.
; - AtomicBool warning flags are plain True/False slots.
; - Rust integer division is implemented as trunc-math over the
;   float-valued division native (operands are non-negative here).

!(import! &self list)
!(import! &self path)
!(import! &self str)
!(import! &self turn_context_parts_a)
!(import! &self turn_context_parts_b)

; --- TurnSkillsContext ---------------------------------------------------

(= (codex:turn-skills-context $outcome $implicit-invocation-seen-skills)
   (CodexTurnSkillsContext $outcome $implicit-invocation-seen-skills))

(= (codex:turn-skills-context-new $outcome)
   (CodexTurnSkillsContext $outcome ()))

(= (codex:turn-skills-context-outcome
      (CodexTurnSkillsContext $outcome $implicit-invocation-seen-skills))
   $outcome)

(= (codex:turn-skills-context-implicit-invocation-seen-skills
      (CodexTurnSkillsContext $outcome $implicit-invocation-seen-skills))
   $implicit-invocation-seen-skills)

; --- TurnEnvironment -------------------------------------------------------

(= (codex:turn-environment $environment-id $environment $cwd)
   (CodexTurnEnvironment $environment-id $environment $cwd))

(= (codex:turn-environment-environment-id
      (CodexTurnEnvironment $environment-id $environment $cwd))
   $environment-id)

(= (codex:turn-environment-environment
      (CodexTurnEnvironment $environment-id $environment $cwd))
   $environment)

(= (codex:turn-environment-cwd
      (CodexTurnEnvironment $environment-id $environment $cwd))
   $cwd)

(= (codex:turn-environment-selection
      (CodexTurnEnvironment $environment-id $environment $cwd))
   (CodexTurnEnvironmentSelection $environment-id $cwd))

(= (codex:turn-environment-selection-environment-id
      (CodexTurnEnvironmentSelection $environment-id $cwd))
   $environment-id)

(= (codex:turn-environment-selection-cwd
      (CodexTurnEnvironmentSelection $environment-id $cwd))
   $cwd)

; --- TurnContext as a record of field groups --------------------------------

(= (codex:turn-context
      $identity
      $model
      $environment
      $instructions
      $permissions
      $tools
      $state)
   (CodexTurnContext
     $identity
     $model
     $environment
     $instructions
     $permissions
     $tools
     $state))

(= (codex:turn-context-identity-group
      (CodexTurnContext
        $identity $model $environment $instructions
        $permissions $tools $state))
   $identity)

(= (codex:turn-context-model-group
      (CodexTurnContext
        $identity $model $environment $instructions
        $permissions $tools $state))
   $model)

(= (codex:turn-context-environment-group
      (CodexTurnContext
        $identity $model $environment $instructions
        $permissions $tools $state))
   $environment)

(= (codex:turn-context-instructions-group
      (CodexTurnContext
        $identity $model $environment $instructions
        $permissions $tools $state))
   $instructions)

(= (codex:turn-context-permissions-group
      (CodexTurnContext
        $identity $model $environment $instructions
        $permissions $tools $state))
   $permissions)

(= (codex:turn-context-tools-group
      (CodexTurnContext
        $identity $model $environment $instructions
        $permissions $tools $state))
   $tools)

(= (codex:turn-context-state-group
      (CodexTurnContext
        $identity $model $environment $instructions
        $permissions $tools $state))
   $state)

; --- model_context_window ----------------------------------------------------

; Rust: resolved_context_window().map(|w| w.saturating_mul(pct) / 100).
; Value-level form over the resolved window option and effective percent;
; the TurnContext-level accessor follows once ModelInfo lands.
(= (codex:turn-context-model-context-window-value
      $resolved-context-window
      $effective-context-window-percent)
   (if (== $resolved-context-window CodexAbsent)
       CodexAbsent
       (codex:turn-context-div-100
         (* $resolved-context-window $effective-context-window-percent))))

; floor division by 100: the division native is float-valued, so the
; quotient is truncated explicitly (operands are non-negative here)
(= (codex:turn-context-div-100 $n)
   (trunc-math (/ $n 100)))

; --- reasoning-level midpoint selection ---------------------------------------

; Rust: supported.get(supported.len().saturating_sub(1) / 2).copied()
;       .or(default_reasoning_level)
(= (codex:turn-context-half $n)
   (trunc-math (/ $n 2)))

; countdown walker instead of list:at: trunc-math yields a float-typed
; whole number that the indexing native rejects
(= (codex:turn-context-nth $xs $i)
   (let ($head $tail) (decons-atom $xs)
     (if (< $i 1)
         $head
         (codex:turn-context-nth $tail (- $i 1)))))

(= (codex:turn-context-midpoint-reasoning-level $supported-levels $default)
   (if (== $supported-levels ())
       $default
       (let $len (list:len $supported-levels)
         (codex:turn-context-nth
           $supported-levels
           (codex:turn-context-half (- $len 1))))))

; Rust with_model keeps the current effort when supported, else midpoint.
(= (codex:turn-context-select-reasoning-effort
      $current $supported-levels $default)
   (if (== $current CodexAbsent)
       (codex:turn-context-midpoint-reasoning-level $supported-levels $default)
       (if (codex:turn-context-level-supported $current $supported-levels)
           $current
           (codex:turn-context-midpoint-reasoning-level
             $supported-levels $default))))

(= (codex:turn-context-level-supported $level $levels)
   (if (== $levels ())
       False
       (let ($head $tail) (decons-atom $levels)
         (if (== $head $level)
             True
             (codex:turn-context-level-supported $level $tail)))))

; --- resolve_path ----------------------------------------------------------------

; Rust: path.map_or_else(|| cwd.clone(), |p| cwd.join_relaxed(p))
(= (codex:turn-context-resolve-path $cwd $path)
   (if (== $path CodexAbsent)
       $cwd
       (if (path-is-absolute? $path)
           $path
           (path-join $cwd $path))))
