; Generate a separate audit binary. All mutation switches below exist only
; in copied qualification sources, never in the production implementation.
!(import! &self (library fs))
!(import! &self (library str))
!(import! &self (library proc))
!(import! &self (library system))

(AMReplace "header" "#include \"atom.h\""
 "#include \"atom.h\"\n#include <stdlib.h>\n#include <string.h>\nstatic inline bool cetta_ai_audit_mutant(const char *name) { const char *active = getenv(\"CETTA_AI_AUDIT_MUTANT\"); return active && strcmp(active, name) == 0; }" 1)
(AMReplace "header" "            return atom_he_evaluated_deep_copy(arena, error);"
 "            { if (cetta_ai_audit_mutant(\"kinds\")) error = atom_expr3(arena, error->expr.elems[0], error->expr.elems[1], atom_expr2(arena, atom_symbol(arena, \"Fault\"), reason->expr.elems[1])); return cetta_ai_audit_mutant(\"fields\") ? atom_he_evaluated_copy(arena, error) : atom_he_evaluated_deep_copy(arena, error); }" 1)
(AMReplace "eval" "if (ai_outcome_raised(arg_outcome)) {"
 "if (ai_outcome_raised(arg_outcome) && !cetta_ai_audit_mutant(\"argument\")) {" 1)
(AMReplace "eval" "if (ai_outcome_raised(&vals.items[0])) {"
 "if (ai_outcome_raised(&vals.items[0]) && !cetta_ai_audit_mutant(\"let\")) {" 1)
(AMReplace "eval" "if (ai_outcome_raised(&vals.items[i])) {"
 "if (ai_outcome_raised(&vals.items[i]) && !cetta_ai_audit_mutant(\"let\")) {" 1)
(AMReplace "eval" "if (ai_outcome_raised(&conds.items[0])) {"
 "if (ai_outcome_raised(&conds.items[0]) && !cetta_ai_audit_mutant(\"if\")) {" 1)
(AMReplace "eval" "eval_failure_values() ? ai_outcome_raised(&conds.items[i])"
 "eval_failure_values() ? (ai_outcome_raised(&conds.items[i]) && !cetta_ai_audit_mutant(\"if\"))" 1)
(AMReplace "eval" "if (failure && !atom_is_error(pattern))"
 "if (failure && (cetta_ai_audit_mutant(\"case-explicit\") || (!atom_is_error(pattern) && !cetta_ai_audit_mutant(\"case-wildcard\"))))" 1)
(AMReplace "eval" "if (ai_outcome_raised(&inner.items[i])) {"
 "if (ai_outcome_raised(&inner.items[i]) && !cetta_ai_audit_mutant(\"catch\")) {" 1)
(AMReplace "eval" "            CettaExprLen count = 0u;\n            for (CettaCount i = 0u; i < inner.len; i++) {\n                Atom *value = outcome_atom_materialize(a, &inner.items[i]);"
 "            CettaExprLen count = 0u;\n            for (CettaCount i = 0u; i < inner.len; i++) {\n                if (cetta_ai_audit_mutant(\"collapse\") && ai_outcome_raised(&inner.items[i])) continue;\n                Atom *value = outcome_atom_materialize(a, &inner.items[i]);\n                if (cetta_ai_audit_mutant(\"duplicates\") && count && value && atom_eq(items[count - 1u], value)) continue;" 1)
(AMReplace "eval" "             bound_arg->kind == ATOM_VAR);\n        bool hold_observed = false;"
 "             bound_arg->kind == ATOM_VAR);\n        if (eval_failure_values() && cetta_ai_audit_mutant(\"holding\") && atom_is_symbol_id(frame->arg_type, g_builtin_syms.atom)) { held_position = false; frame->arg_type = atom_undefined_type(a); }\n        bool hold_observed = false;" 1)
(AMReplace "eval" "        Atom *target_operand =\n            bindings_apply_if_vars(CURRENT_ENV, a, expr_arg((*call), 0));"
 "        Atom *target_operand =\n            bindings_apply_if_vars(CURRENT_ENV, a, expr_arg((*call), 0));\n        if (eval_failure_values() && cetta_ai_audit_mutant(\"unify\")) { OutcomeSet forced; outcome_set_init(&forced); metta_eval_bind(s, a, target_operand, fuel, &forced); if (forced.len) target_operand = outcome_atom_materialize(a, &forced.items[0]); outcome_set_free(&forced); }" 1)
(AMReplace "eval" "                            : branch->expr.elems[0];\n                        if (ai_empty_case"
 "                            : branch->expr.elems[0];\n                        if (eval_failure_values() && cetta_ai_audit_mutant(\"case-pattern\")) { OutcomeSet forced; outcome_set_init(&forced); metta_eval_bind(s, a, pattern, fuel, &forced); if (forced.len) pattern = outcome_atom_materialize(a, &forced.items[0]); outcome_set_free(&forced); }\n                        if (ai_empty_case" 1)
(AMReplace "eval" "    if (valid && conditions->expr.elems[0]->expr.len == 0u &&\n                 conditions->expr.elems[1]->expr.len == 0u)"
 "    if (valid && (cetta_ai_audit_mutant(\"conditions\") || (conditions->expr.elems[0]->expr.len == 0u && conditions->expr.elems[1]->expr.len == 0u)))" 1)
(AMReplace "eval" "    if (eval_failure_values() && outcome.kind == CETTA_CALL_RAISED) {"
 "    if (eval_failure_values() && outcome.kind == CETTA_CALL_RAISED) {\n        if (cetta_ai_audit_mutant(\"native-raise\")) { outcome_set_add(outcomes, ai_completed_data(a, outcome.term), environment); return true; }" 1)
(AMReplace "eval" "        !cetta_call_result_is_frontier(outcome.result_form) && atom_is_error(outcome.term)) {"
 "        !cetta_call_result_is_frontier(outcome.result_form) && atom_is_error(outcome.term)) {\n        if (cetta_ai_audit_mutant(\"native-value\")) { ai_add_failure(a, outcomes, outcome.term, environment); return true; }" 1)
(AMReplace "eval" "    if (eval_failure_values() && outcome && outcome->completion != CETTA_EVAL_COMPLETE &&\n        !g_ai_cut_reified) {"
 "    if (eval_failure_values() && outcome && outcome->completion != CETTA_EVAL_COMPLETE &&\n        !g_ai_cut_reified && !cetta_ai_audit_mutant(\"budget\")) {" 1)
(AMReplace "machine" "                outcome->result_form == CETTA_CALL_RESULT_RAISED)"
 "                outcome->result_form == CETTA_CALL_RESULT_RAISED && !cetta_ai_audit_mutant(\"return\"))" 1)
(AMReplace "eval" "if (!ai_outcome_raised(&source->items[i]))"
 "if (cetta_ai_audit_mutant(\"aggregate\") || !ai_outcome_raised(&source->items[i]))" 1)
(AMReplace "machine" "        Atom *quoted = machine->host.quote_is_inert_data\n            ? expression : expression->expr.elems[1];"
 "        Atom *quoted = machine->host.quote_is_inert_data\n            ? expression : expression->expr.elems[1];\n        if (machine->host.failure_values && cetta_ai_audit_mutant(\"quote\")) { Atom *code = petta_machine_apply_bindings(machine, environment, &machine->heap, quoted); const PettaPlanNode *translated = code && machine->host.translate_source ? petta_machine_translate_source(machine, code) : NULL; if (!code || (machine->host.translate_source && !translated)) { *failure = PETTA_MACHINE_STEP_CAPACITY; return false; } return petta_push_solve_planned(machine, code, expected, goal->barrier, translated); }" 1)
(AMReplace "machine" "    if (machine->host.failure_values) {\n        error = cetta_ai_failure_value(&machine->heap, error);"
 "    if (machine->host.failure_values && cetta_ai_audit_mutant(\"failure-as-zero\")) return petta_goal_push(machine, &(PettaGoal){.kind = PETTA_GOAL_FAIL});\n    if (machine->host.failure_values) {\n        error = cetta_ai_failure_value(&machine->heap, error);" 1)
(AMReplace "machine" "    machine->raised_error = stable;\n    machine->goal_len = 0u;"
 "    if (machine->host.failure_values && cetta_ai_audit_mutant(\"failure-dominates-choice\")) petta_choice_truncate(machine, 0u);\n    machine->raised_error = stable;\n    machine->goal_len = 0u;" 1)
(AMReplace "machine" "if (!machine->host.failure_values && has_success &&"
 "if ((!machine->host.failure_values || cetta_ai_audit_mutant(\"prefer-success\")) && has_success &&" 1)
(AMReplace "machine" "bool feeds_force = machine->host.failure_values && machine->goal_len &&"
 "bool feeds_force = machine->host.failure_values && !cetta_ai_audit_mutant(\"quoted-template\") && machine->goal_len &&" 1)
(AMReplace "machine" "            machine, goal, goal->first);\n        return error && petta_machine_raise_error(machine, error);"
 "            machine, goal, goal->first);\n        if (error && cetta_ai_audit_mutant(\"argument\")) return petta_machine_unify_resolved(machine, atom_he_evaluated_deep_copy(&machine->heap, error), goal->second);\n        return error && petta_machine_raise_error(machine, error);" 1)
(AMReplace "machine" "                search_context_bindings(&machine->search), &machine->heap, goal->first);\n        return error && petta_machine_raise_error(machine, error);"
 "                search_context_bindings(&machine->search), &machine->heap, goal->first);\n        if (error && cetta_ai_audit_mutant(\"argument\")) return petta_machine_unify_resolved(machine, atom_he_evaluated_deep_copy(&machine->heap, error), goal->second);\n        return error && petta_machine_raise_error(machine, error);" 1)
(AMReplace "machine" "        PettaGoal marker = machine->goals[index];"
 "        PettaGoal marker = machine->goals[index];\n        if (machine->host.failure_values && cetta_ai_audit_mutant(\"let\") && marker.kind == PETTA_GOAL_ARGUMENT_RETURN) { machine->goal_len = index; return petta_push_unify(machine, atom_he_evaluated_deep_copy(&machine->heap, stable), marker.first, marker.barrier); }\n        if (machine->host.failure_values && cetta_ai_audit_mutant(\"if\") && marker.kind == PETTA_GOAL_IF_SELECT) { machine->goal_len = index + 1u; return petta_push_unify(machine, stable, marker.first, marker.barrier); }" 1)
(AMReplace "machine" "            marker.kind == PETTA_GOAL_CASE_SELECT && !marker.ready_branches) {"
 "            marker.kind == PETTA_GOAL_CASE_SELECT && !marker.ready_branches && !cetta_ai_audit_mutant(\"case-explicit\")) {" 1)
(AMReplace "machine" "        if (!pattern || pattern->kind != ATOM_EXPR || !pattern->expr.len ||\n            !atom_is_symbol(pattern->expr.elems[0], \"Error\"))"
 "        if (!cetta_ai_audit_mutant(\"case-wildcard\") && (!pattern || pattern->kind != ATOM_EXPR || !pattern->expr.len ||\n            !atom_is_symbol(pattern->expr.elems[0], \"Error\")))" 1)
(AMReplace "machine" "        if (marker.kind != PETTA_GOAL_CATCH_READY)"
 "        if (marker.kind != PETTA_GOAL_CATCH_READY || cetta_ai_audit_mutant(\"catch\"))" 1)
(AMReplace "eval" "        .literal_binding_patterns = g_he_shared_execution || prime_machine || eval_failure_values(),"
 "        .literal_binding_patterns = g_he_shared_execution || prime_machine || (eval_failure_values() && !cetta_ai_audit_mutant(\"let\"))," 1)
(AMReplace "machine" "        if (machine->host.failure_values)\n            continue;\n        if (!petta_machine_callable_root(machine, pattern, NULL)"
 "        if (machine->host.failure_values && !cetta_ai_audit_mutant(\"case-pattern\"))\n            continue;\n        if (!petta_machine_callable_root(machine, pattern, NULL)" 1)
(AMReplace "machine" "    if (outcome.kind == CETTA_CALL_RAISED && outcome.term)\n        return !recovers && petta_machine_raise_error(machine, outcome.term);"
 "    if (outcome.kind == CETTA_CALL_RAISED && outcome.term) {\n        if (machine->host.failure_values && cetta_ai_audit_mutant(\"native-raise\")) return petta_machine_unify_resolved(machine, atom_he_evaluated_deep_copy(&machine->heap, outcome.term), expected);\n        return !recovers && petta_machine_raise_error(machine, outcome.term);\n    }\n    if (machine->host.failure_values && cetta_ai_audit_mutant(\"native-value\") && outcome.kind == CETTA_CALL_VALUE && atom_is_error(outcome.term)) return petta_machine_raise_error(machine, outcome.term);" 1)
(AMReplace "machine" "        choice->as.provider.awaiting_accept = true;\n        if (outcome.kind == CETTA_CALL_RAISED)\n            return petta_machine_raise_error(machine, value);"
 "        choice->as.provider.awaiting_accept = true;\n        if (machine->host.failure_values && cetta_ai_audit_mutant(\"native-value\") && outcome.kind == CETTA_CALL_VALUE && atom_is_error(value)) return petta_machine_raise_error(machine, value);\n        if (machine->host.failure_values && cetta_ai_audit_mutant(\"native-raise\") && outcome.kind == CETTA_CALL_RAISED) outcome.kind = CETTA_CALL_VALUE;\n        if (outcome.kind == CETTA_CALL_RAISED)\n            return petta_machine_raise_error(machine, value);" 1)
(AMReplace "eval" "    Atom *raised = petta_eval_take_raise();\n    if (!raised && native_outcome.kind == CETTA_CALL_RAISED)"
 "    Atom *raised = petta_eval_take_raise();\n    if (eval_failure_values() && cetta_ai_audit_mutant(\"native-raise\") && (raised || native_outcome.kind == CETTA_CALL_RAISED)) { native_outcome = cetta_call_completed_value(raised ? raised : native_outcome.term); raised = NULL; }\n    if (eval_failure_values() && cetta_ai_audit_mutant(\"native-value\") && native_outcome.kind == CETTA_CALL_VALUE && atom_is_error(native_outcome.term)) raised = native_outcome.term;\n    if (!raised && native_outcome.kind == CETTA_CALL_RAISED)" 1)
(AMReplace "machine" "    if (machine->host.failure_values && atom_is_he_evaluated(goal->first))"
 "    if (machine->host.failure_values && !cetta_ai_audit_mutant(\"holding\") && atom_is_he_evaluated(goal->first))" 1)
(AMReplace "machine" "        (!goal->plan || goal->plan->role != PETTA_PLAN_VALUE) &&\n        !atom_is_he_evaluated(goal->first)"
 "        (cetta_ai_audit_mutant(\"holding\") || !goal->plan || goal->plan->role != PETTA_PLAN_VALUE) &&\n        (cetta_ai_audit_mutant(\"holding\") || !atom_is_he_evaluated(goal->first))" 2)
(AMReplace "machine" "    Atom *materialized = petta_machine_materialize_answer(\n        machine, error);"
 "    if (machine->host.failure_values && cetta_ai_audit_mutant(\"fields\") && error->kind == ATOM_EXPR && error->expr.len == 3u && machine->host.evaluate) {\n        Atom *field = error->expr.elems[1]; atom_deep_copy_strip_he_marks_enter(); field = atom_deep_copy(&machine->heap, field); atom_deep_copy_strip_he_marks_leave();\n        OutcomeSet forced; outcome_set_init(&forced); CettaCallOutcome end = cetta_call_failure();\n        if (machine->host.evaluate(machine->host.context, machine->space, &machine->heap, field, search_context_bindings(&machine->search), &forced, &end, NULL) && forced.len) error = atom_expr3(&machine->heap, error->expr.elems[0], bindings_apply_if_vars(&forced.items[0].env, &machine->heap, forced.items[0].materialized_atom ? forced.items[0].materialized_atom : forced.items[0].atom), error->expr.elems[2]);\n        outcome_set_free(&forced);\n    }\n    Atom *materialized = petta_machine_materialize_answer(\n        machine, error);" 1)

(AMMutant "failure-as-zero")
(AMMutant "failure-dominates-choice")
(AMMutant "prefer-success")
(AMMutant "quoted-template")
(AMMutant "kinds")
(AMMutant "fields")
(AMMutant "argument")
(AMMutant "let")
(AMMutant "if")
(AMMutant "case-wildcard")
(AMMutant "case-explicit")
(AMMutant "catch")
(AMMutant "collapse")
(AMMutant "holding")
(AMMutant "unify")
(AMMutant "case-pattern")
(AMMutant "conditions")
(AMMutant "native-value")
(AMMutant "native-raise")
(AMMutant "budget")
(AMMutant "return")
(AMMutant "duplicates")
(AMMutant "quote")
(AMMutant "aggregate")

(= (am:fail $problem) (let $shown (println! $problem) (system:exit 2)))
(= (am:read $path)
   (case (fs:read-text-result $path 0 "raw")
     ((("ok" $text) $text) ($bad (am:fail (MutationReadFailed $path $bad))))))
(= (am:write $path $text)
   (let $written (fs:write $path $text)
     (if (== (am:read $path) $text) $path (am:fail (MutationWriteFailed $path)))))
(= (am:replace $source $old $new $count)
   (let $pieces (str:split $old $source)
     (if (== (size-atom $pieces) (+ $count 1)) (str:join $new $pieces)
       (am:fail (MutationAnchorCount $old $count (- (size-atom $pieces) 1))))))
(= (am:patches $source $patches)
   (if (== $patches ()) $source
     (let* (((Patch $old $new $count) (car-atom $patches))
            ($next (am:replace $source $old $new $count)))
       (am:patches $next (cdr-atom $patches)))))
(= (am:file $root $dir $name $source-name)
   (let* (($path (str:join "" ($root "/src/" $source-name)))
          ($source (am:read $path))
          ($patches (collapse (match &self (AMReplace $name $old $new $count) (Patch $old $new $count))))
          ($changed (am:patches $source $patches))
          ($output (am:write (str:join "" ($dir "/" $source-name)) $changed)))
     (MutationSource $name (size-atom $patches) (str:sha256 $source) (str:sha256 $changed))))
(= (am:response $source $old $new) (am:replace $source $old $new 1))
(= (am:compile-response $dev $dir $name $source-name $object-name)
   (let* (($source (am:read (str:join "" ($dev "/" $name ".rsp"))))
          ($with-source (am:response $source (str:concat "src/" $source-name) (str:join "" ($dir "/" $source-name))))
          ($with-object (am:response $with-source (str:join "" ($dev "/" $object-name)) (str:join "" ($dir "/" $object-name)))))
     (am:write (str:join "" ($dir "/" $name ".rsp")) $with-object)))
(= (am:link-response $dev $dir $name $binary-name)
   (let* (($source (am:read (str:join "" ($dev "/" $name ".rsp"))))
          ($a (am:response $source (str:concat $dev "/eval.o") (str:concat $dir "/eval.o")))
          ($b (am:response $a (str:concat $dev "/petta_search_machine.o") (str:concat $dir "/petta_search_machine.o")))
          ($c (am:response $b (str:join "" ($dev "/" $binary-name)) (str:join "" ($dir "/" $binary-name)))))
     (am:write (str:join "" ($dir "/" $name ".rsp")) $c)))
(= (am:prepare $root $dev $dir)
   (let* (($made (fs:make-directories $dir 511))
          ($h (am:file $root $dir "header" "ai_failure.h"))
          ($e (am:file $root $dir "eval" "eval.c"))
          ($m (am:file $root $dir "machine" "petta_search_machine.c"))
          ($b (am:write (str:concat $dir "/eval_he_boundary.inc") (am:read (str:concat $root "/src/eval_he_boundary.inc"))))
          ($er (am:compile-response $dev $dir "eval" "eval.c" "eval.o"))
          ($mr (am:compile-response $dev $dir "petta_search_machine" "petta_search_machine.c" "petta_search_machine.o"))
          ($lr (am:link-response $dev $dir "link" "cetta"))
          ($nr (am:link-response $dev $dir "native-link" "native")))
     (MutationSourcesPrepared $h $e $m $b)))

(= (am:contains $text $needle) (> (size-atom (str:split $needle $text)) 1))
(= (am:environment $name)
   (("PATH" "/usr/local/bin:/usr/bin:/bin") ("LANG" "C.UTF-8")
    ("LC_ALL" "C.UTF-8") ("TZ" "UTC") ("CETTA_AI_AUDIT_MUTANT" $name)
    ("CETTA_PETTA_SEARCH_MACHINE" "1")))
(= (am:exec $dir $name $stage $argv $cwd)
   (let* (($result (proc:run $argv $cwd (am:environment $name) 180000 4194304))
          ($saved (am:write (str:join "" ($dir "/" $name "." $stage ".log")) (repr $result))))
     $result))
(= (am:semantic $dir $name $cwd)
   (let* (($binary (str:concat $dir "/cetta"))
          ($driver (str:concat $cwd "/tests/ai/suite.metta"))
          ($program (str:join "" ("!(import! &self " (repr $driver) ") !"
            (if (== $name "control")
              (str:join "" ("(ais:run " (repr $binary) " " (repr $cwd) ")"))
              (str:join "" ("(ais:fixtures " (repr $binary)
                " \"petta\" \"CETTA_PETTA_TRANSLATOR_EXPANSION=1\" "
                "(\"failure_values\" \"positions\" \"effects\" \"library_observers\" \"macro_capture\" \"review_regressions\") "
                (repr $cwd) " 0)")))))))
     (case (am:exec $dir $name "semantic"
            ($binary "--lang" "petta" "--profile" "extended" "-e" $program) $cwd)
       (((proc:exited 0 $out "")
          (if (or (am:contains $out "(AISuitePass 12 1984 18)") (== $out "true\n6\n")) (MutantSurvived $name)
            (if (am:contains $out "Mismatch") (MutantKilled $name semantic)
              (am:fail (InvalidMutationRunner $name $out)))))
        ((proc:exited 1 $out $err)
          (if (am:contains $out "Mismatch") (MutantKilled $name semantic)
            (am:fail (UnexpectedMutationFailure $name $out $err))))
        ($other (am:fail (UnexpectedMutationExecution $name $other)))))))
(= (am:budget $dir $name $cwd)
   (let $binary (str:concat $dir "/cetta")
     (case (am:exec $dir $name "budget"
        ($binary "--lang" "petta" "--profile" "ai" "--fuel" "0" "-e" "!(ai:experiment failure-values) !(+ 1 2)") $cwd)
       (((proc:exited 0 $out "")
          (if (== $out "()\n(Error (+ 1 2) (Incomplete fuel-exhausted))\n")
            (am:semantic $dir $name $cwd) (MutantKilled $name budget)))
        ($other (am:fail (UnexpectedBudgetMutationExecution $name $other)))))))
(= (am:exercise $dir $name $cwd)
   (case (am:exec $dir $name "native" ((str:concat $dir "/native") "--ai-native") $cwd)
     (((proc:exited 0 $out "")
        (if (am:contains $out "PASS: 25 PeTTa AI native") (am:budget $dir $name $cwd)
          (am:fail (InvalidNativeMutationRunner $name $out))))
      ((proc:signaled 6 $out $err)
        (if (am:contains $err "Assertion") (MutantKilled $name native)
          (am:fail (UnexpectedNativeAbort $name $out $err))))
      ($other (am:fail (UnexpectedNativeMutationExecution $name $other))))))
(= (am:walk $dir $cwd $names $killed $survived)
   (if (== $names ())
     (if (and (== $killed 24) (== $survived 0)) (MutationSummary 24 24 0)
       (am:fail (MutationSurvivors $killed $survived)))
     (let* (($name (car-atom $names)) ($rest (cdr-atom $names))
            ($result (am:exercise $dir $name $cwd)) ($shown (println! $result)))
       (case $result
         (((MutantKilled $name $stage) (am:walk $dir $cwd $rest (+ $killed 1) $survived))
          ((MutantSurvived $name) (am:walk $dir $cwd $rest $killed (+ $survived 1)))
          ($bad (am:fail (InvalidMutationResult $bad))))))))
(= (am:run $dir $cwd)
   (case (am:exercise $dir "control" $cwd)
     (((MutantSurvived "control")
        (let $names (collapse (match &self (AMMutant $name) $name))
          (if (== (size-atom $names) 24) (am:walk $dir $cwd $names 0 0)
            (am:fail (InvalidMutationCount (size-atom $names))))))
      ($bad (am:fail (MutationControlFailed $bad))))))
