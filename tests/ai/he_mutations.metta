; Qualification-only fault injection. Production has no mutation switches.
!(import! &self "./mutations.metta")

(HMReplace "header" "#include \"atom.h\""
 "#include \"atom.h\"\n#include <stdlib.h>\n#include <string.h>\nstatic inline bool cetta_ai_audit_mutant(const char *name) { const char *active = getenv(\"CETTA_AI_AUDIT_MUTANT\"); return active && strcmp(active, name) == 0; }" 1)
(HMReplace "header" "            return atom_he_evaluated_deep_copy(arena, error);"
 "            { if (cetta_ai_audit_mutant(\"kinds\")) error = atom_expr3(arena, error->expr.elems[0], error->expr.elems[1], atom_expr2(arena, atom_symbol(arena, \"Fault\"), reason->expr.elems[1])); return atom_he_evaluated_deep_copy(arena, error); }" 1)
(HMReplace "grounded" "#include \"grounded.h\"" "#include \"grounded.h\"\n#include \"ai_failure.h\"" 1)
(HMReplace "grounded" "eval_current_uses_failure_values && eval_current_uses_failure_values()"
 "eval_current_uses_failure_values && eval_current_uses_failure_values() && !cetta_ai_audit_mutant(\"native-producer\")" 4)
(HMReplace "eval" "    if (eval_failure_values() && outcome.kind == CETTA_CALL_RAISED) {"
 "    if (eval_failure_values() && outcome.kind == CETTA_CALL_RAISED) {\n        if (cetta_ai_audit_mutant(\"native-raise\")) { outcome_set_add(outcomes, ai_completed_data(a, outcome.term), environment); return true; }" 1)
(HMReplace "eval" "        !ai_native_packet_admitted(&outcome, environment))"
 "        !cetta_ai_audit_mutant(\"packet\") && !ai_native_packet_admitted(&outcome, environment))" 1)
(HMReplace "eval" "        !cetta_call_result_is_frontier(outcome.result_form) && atom_is_error(outcome.term)) {"
 "        !cetta_call_result_is_frontier(outcome.result_form) && atom_is_error(outcome.term)) {\n        if (cetta_ai_audit_mutant(\"native-data\")) { ai_add_failure(a, outcomes, outcome.term, environment); return true; }" 1)
(HMReplace "eval" "        (eval_failure_values() ? ai_outcome_raised(seed) : atom_is_error(result)))"
 "        (eval_failure_values() && !cetta_ai_audit_mutant(\"data-type\") ? ai_outcome_raised(seed) : atom_is_error(result)))" 1)
(HMReplace "eval" "        items[count++] = value;\n    }\n    if (g_eval_completion_tracker"
 "        if (cetta_ai_audit_mutant(\"collect-failure\") && ai_outcome_raised(item)) continue;\n        if (cetta_ai_audit_mutant(\"duplicates\") && count && atom_eq(items[count - 1u], value)) continue;\n        if (cetta_ai_audit_mutant(\"empty-data\") && atom_head_symbol_id(value) == g_builtin_syms.empty) continue;\n        items[count++] = value;\n    }\n    if (g_eval_completion_tracker" 1)
(HMReplace "eval" "        !g_ai_cut_reified) {\n        Atom *diagnostic = ai_completion_diagnostic(a, expr, outcome->completion);"
 "        !g_ai_cut_reified && !cetta_ai_audit_mutant(\"budget\")) {\n        Atom *diagnostic = ai_completion_diagnostic(a, expr, outcome->completion);" 1)
(HMReplace "canonical" "    if (!atom_is_error(source) || atom_is_he_evaluated(source))"
 "    if (cetta_ai_audit_mutant(\"source\") || !atom_is_error(source) || atom_is_he_evaluated(source))" 1)
(HMReplace "eval" "    if (!eval_failure_values())\n        return value;"
 "    if (cetta_ai_audit_mutant(\"data-admission\") || !eval_failure_values())\n        return value;" 1)
(HMReplace "eval" "    Atom *data = atom_graph_image(NULL, arena, value, he_data_descends, he_data_build);"
 "    Atom *data = cetta_ai_audit_mutant(\"data-freeze\") ? atom_he_evaluated_deep_copy(arena, value) : atom_graph_image(NULL, arena, value, he_data_descends, he_data_build);" 1)
(HMReplace "eval" "        !atom_is_he_evaluated_throughout(value);"
 "        !atom_is_he_evaluated_throughout(value) && (!cetta_ai_audit_mutant(\"data-nesting\") || atom_is_error(value));" 1)
(HMReplace "eval" "    if (new_elems && eval_failure_values())\n        result = bindings_retain_rebuilt_role(a, body, result);"
 "    if (new_elems && eval_failure_values() && !cetta_ai_audit_mutant(\"data-substitution\"))\n        result = bindings_retain_rebuilt_role(a, body, result);" 1)
(HMReplace "header" "static inline Atom *cetta_ai_code_reading(Arena *arena, Atom *value) {"
 "static inline Atom *cetta_ai_code_reading(Arena *arena, Atom *value) {\n    if (cetta_ai_audit_mutant(\"activation-root\")) return value;\n    if (cetta_ai_audit_mutant(\"activation-deep\")) { atom_deep_copy_strip_he_marks_enter(); Atom *copy = atom_deep_copy(arena, value); atom_deep_copy_strip_he_marks_leave(); return copy; }" 1)
(HMReplace "bindings" "        !ai_binding_activate_quotations(arena, pattern, &candidate)) {"
 "        (!cetta_ai_audit_mutant(\"quote-activation\") && !ai_binding_activate_quotations(arena, pattern, &candidate))) {" 1)
(HMReplace "eval" "    bool preserve, OutcomeSet *target) {\n    if (!value) {"
 "    bool preserve, OutcomeSet *target) {\n    if (cetta_ai_audit_mutant(\"declared-output\") && value && atom_is_error(value)) { Outcome receipt; outcome_init(&receipt); receipt.atom = receipt.materialized_atom = he_admit_data(arena, value); receipt.env = source->env; receipt.delayed = source->delayed; outcome_set_add_prefixed_outcome(arena, target, &receipt, outer, preserve); return true; }\n    if (!value) {" 1)
(HMReplace "eval" "    Arena *arena, Outcome *source) {\n    if (ai_outcome_raised(source))"
 "    Arena *arena, Outcome *source) {\n    if (cetta_ai_audit_mutant(\"declared-output\")) { Atom *value = outcome_atom_materialize(arena, source); if (value && atom_is_error(value)) { source->atom = source->materialized_atom = he_admit_data(arena, value); source->result_form = CETTA_CALL_RESULT_COMPLETED_VALUE; } return true; }\n    if (ai_outcome_raised(source))" 1)
(HMReplace "eval" "    returned.result_form = CETTA_CALL_RESULT_PRESERVED_VALUE;\n    ai_forward_preserved_value"
 "    if (cetta_ai_audit_mutant(\"return-output\")) returned.atom = returned.materialized_atom = value = he_admit_data(arena, value);\n    returned.result_form = CETTA_CALL_RESULT_PRESERVED_VALUE;\n    ai_forward_preserved_value" 1)
(HMReplace "grounded" "        *out = cetta_call_preserved_value(result);"
 "        *out = cetta_ai_audit_mutant(\"projection-origin\") ? cetta_call_completed_value(result) : cetta_call_preserved_value(result);" 1)
(HMReplace "eval" "        } else if (eval_failure_values()) {\n            value = ai_completed_data(arena, value);"
 "        } else if (eval_failure_values() && !cetta_ai_audit_mutant(\"native-callback\")) {\n            value = ai_completed_data(arena, value);" 1)
(HMReplace "header" "static inline Atom *cetta_ai_constructed_value(Arena *arena, Atom *value) {"
 "static inline Atom *cetta_ai_constructed_value(Arena *arena, Atom *value) {\n    if (cetta_ai_audit_mutant(\"constructor-children\")) return atom_he_evaluated_deep_copy(arena, value);" 1)
(HMReplace "space" "    return rewritten ? bindings_retain_rebuilt_role(a, atom,\n        atom_expr(a, rewritten, atom->expr.len)) : atom;"
 "    return rewritten ? (cetta_ai_audit_mutant(\"alias-role\") ? atom_expr(a, rewritten, atom->expr.len) : bindings_retain_rebuilt_role(a, atom, atom_expr(a, rewritten, atom->expr.len))) : atom;" 1)
(HMReplace "space" "        atom_may_hold_he_mark(atom) && eval_current_uses_failure_values &&"
 "        !cetta_ai_audit_mutant(\"alias-role\") && atom_may_hold_he_mark(atom) && eval_current_uses_failure_values &&" 1)
(HMReplace "match" "    if (eval_current_uses_failure_values && eval_current_uses_failure_values())\n        return bindings_apply_epoch_graph"
 "    if (eval_current_uses_failure_values && eval_current_uses_failure_values() && !cetta_ai_audit_mutant(\"epoch-sharing\"))\n        return bindings_apply_epoch_graph" 1)
(HMReplace "space" "#include \"space.h\"" "#include \"space.h\"\n#include \"ai_failure.h\"" 1)
(HMReplace "match" "#include \"match.h\"" "#include \"match.h\"\n#include \"ai_failure.h\"" 1)
(HMReplace "machine" "                bool scheduled = activation_supported"
 "                if (cetta_ai_audit_mutant(\"choice-capture\") && machine->host.failure_values && atom_is_error(result) && !atom_is_he_evaluated(result)) return petta_machine_raise_error(machine, result);\n                bool scheduled = activation_supported" 1)
(HMReplace "machine" "    /* Selection may precede the choice's continuation snapshot. Surface a"
 "    if (cetta_ai_audit_mutant(\"raw-output\") && machine->host.failure_values && !evaluate_result && atom_is_error(result) && !atom_is_he_evaluated(result)) return petta_push_unify(machine, atom_he_evaluated_deep_copy(&machine->heap, result), expected, barrier);\n    /* Selection may precede the choice's continuation snapshot. Surface a" 1)
(HMReplace "eval" "eval_atom_type_demand(arena, value, expected) == HE_TYPE_INTERPRET"
 "(eval_atom_type_demand(arena, value, expected) == HE_TYPE_INTERPRET || cetta_ai_audit_mutant(\"typed-activation\"))" 1)
(HMReplace "grounded" "bool grounded_op_preserves_result_origin(SymbolId id) {"
 "bool grounded_op_preserves_result_origin(SymbolId id) {\n    if (cetta_ai_audit_mutant(\"sealed-origin\") && id == g_builtin_syms.sealed_text) return false;" 1)
(HMReplace "grounded" "            ? cetta_ai_constructed_value(a, converted) : converted;"
 "            ? (cetta_ai_audit_mutant(\"conversion-children\") ? atom_he_evaluated_deep_copy(a, converted) : cetta_ai_constructed_value(a, converted)) : converted;" 1)
(HMReplace "eval" "    return bindings_retain_rebuilt_role(arena, source,\n        atom_expr(arena, children, source->expr.len));"
 "    if (cetta_ai_audit_mutant(\"once-role\")) return atom_expr(arena, children, source->expr.len);\n    return bindings_retain_rebuilt_role(arena, source,\n        atom_expr(arena, children, source->expr.len));" 1)
(HMReplace "eval" "    return eval_failure_values()\n        ? instantiate_template_variable_once_ai(arena, source, variable, value)"
 "    return eval_failure_values() && !cetta_ai_audit_mutant(\"once-sharing\")\n        ? instantiate_template_variable_once_ai(arena, source, variable, value)" 1)
(HMReplace "machine" "    if (machine && machine->host.failure_values)\n        return false;"
 "    if (machine && machine->host.failure_values && !cetta_ai_audit_mutant(\"memo-decline\"))\n        return false;" 1)
(HMReplace "machine" "            bool code_pattern = structure && structure->code_pattern &&"
 "            bool code_pattern = !cetta_ai_audit_mutant(\"quote-machine\") && structure && structure->code_pattern &&" 1)
(HMReplace "header" "static inline Atom *cetta_ai_constructed_value(Arena *arena, Atom *value) {"
 "static inline Atom *cetta_ai_constructed_value(Arena *arena, Atom *value) {\n    if (cetta_ai_audit_mutant(\"constructed-root\")) return value;" 1)
(HMReplace "canonical" "if (eval_failure_values() && ai_forward_failure(a, frame->target,\n                item, tuple->ctx, true))"
 "if (eval_failure_values() && !cetta_ai_audit_mutant(\"tuple\") && ai_forward_failure(a, frame->target,\n                item, tuple->ctx, true))" 1)
(HMReplace "canonical" "        if (!atom_is_error(pattern))"
 "        if (cetta_ai_audit_mutant(\"case-explicit\") || (!atom_is_error(pattern) && !cetta_ai_audit_mutant(\"case-wildcard\")))" 1)
(HMReplace "canonical" "    if (eval_failure_values() && ai_outcome_raised(source) &&\n        (frame->control.operation == CETTA_CONTROL_SEQUENCE ||\n         frame->control.operation == CETTA_CONTROL_BRANCH)) {"
 "    if (eval_failure_values() && ai_outcome_raised(source) &&\n        !((cetta_ai_audit_mutant(\"sequence\") && frame->control.operation == CETTA_CONTROL_SEQUENCE) || (cetta_ai_audit_mutant(\"branch\") && frame->control.operation == CETTA_CONTROL_BRANCH)) &&\n        (frame->control.operation == CETTA_CONTROL_SEQUENCE ||\n         frame->control.operation == CETTA_CONTROL_BRANCH)) {" 1)
(HMReplace "canonical" "            Atom *data = ai_completed_data(a, value);"
 "            if (cetta_ai_audit_mutant(\"handler\")) { outcome_set_add_prefixed_outcome(a, &frame->paths, source, &frame->env, frame->preserve_bindings); return; }\n            Atom *data = ai_completed_data(a, value);" 1)
(HMReplace "canonical" "if (eval_failure_values() && ai_forward_failure(a, frame->target,\n                    value, &frame->env, frame->preserve_bindings))"
 "if (eval_failure_values() && !cetta_ai_audit_mutant(\"state\") && ai_forward_failure(a, frame->target,\n                    value, &frame->env, frame->preserve_bindings))" 1)
(HMReplace "canonical" "if (eval_failure_values() && ai_forward_failure(frame->arena, &frame->paths,"
 "if (eval_failure_values() && !cetta_ai_audit_mutant(\"instruction\") && ai_forward_failure(frame->arena, &frame->paths," 1)
(HMReplace "canonical" "if (eval_failure_values() && ai_forward_failure(a, &frame->paths,"
 "if (eval_failure_values() && !cetta_ai_audit_mutant(\"instruction\") && ai_forward_failure(a, &frame->paths," 1)
(HMReplace "canonical" "        (eval_failure_values() ? ai_outcome_raised(seed) : outcome_atom_is_error(a, seed)))"
 "        (eval_failure_values() && !cetta_ai_audit_mutant(\"data-type\") ? ai_outcome_raised(seed) : outcome_atom_is_error(a, seed)))" 1)
(HMReplace "boundary" "eval_failure_values() && ai_forward_failure"
 "eval_failure_values() && !cetta_ai_audit_mutant(\"instruction\") && ai_forward_failure" 5)

(HMWitness "kinds" () "!(let $v (Error first (Forbidden detail)) never)" "[(Error first (Forbidden detail))]\n")
(HMWitness "source" () "!(let $v (Error first (Forbidden detail)) never)" "[(Error first (Forbidden detail))]\n")
(HMWitness "tuple" () "!(let (Other $x) (Box (Error first (Forbidden detail))) never)" "[(Error first (Forbidden detail))]\n")
(HMWitness "sequence" () "!(let $v (Error first (Forbidden detail)) never)" "[(Error first (Forbidden detail))]\n")
(HMWitness "branch" () "!(if (Error first (Forbidden detail)) yes no)" "[(Error first (Forbidden detail))]\n")
(HMWitness "case-explicit" () "!(case (Error first (Forbidden detail)) (((Error $w $d) caught) ($x hidden)))" "[caught]\n")
(HMWitness "case-wildcard" () "!(case (Error first (Forbidden detail)) (($x hidden)))" "[(Error first (Forbidden detail))]\n")
(HMWitness "handler" () "!(let $d (catch (Error first (Forbidden detail))) (Box $d))" "[(Box (Error first (Forbidden detail)))]\n")
(HMWitness "collect-failure" () "!(collapse (superpose ((Error first (Forbidden detail)) live)))" "[((Error first (Forbidden detail)) live)]\n")
(HMWitness "duplicates" () "!(collapse (superpose ((Error first (Forbidden detail)) (Error first (Forbidden detail)))))" "[((Error first (Forbidden detail)) (Error first (Forbidden detail)))]\n")
(HMWitness "empty-data" () "(: Empty (-> Atom ScopedObservation)) !(collapse (superpose (() (Empty scope))))" "[(() (Empty scope))]\n")
(HMWitness "instruction" () "!(let $v (metta (Error first (Forbidden detail)) %Undefined% &self) never)" "[(Error first (Forbidden detail))]\n")
(HMWitness "state" () "!(let $s (new-state before) (let $f (catch (change-state! $s (Error first (Forbidden detail)))) (Pair $f (get-state $s))))" "[(Pair (Error first (Forbidden detail)) before)]\n")
(HMWitness "native-producer" () "!(let $v (index-atom (a b) 9) never)" "unused: native fixture establishes this channel")
(HMWitness "native-raise" () "!(let $v (index-atom (a b) 9) never)" "unused: native fixture establishes this channel")
(HMWitness "packet" () "unused" "unused: native fixture establishes whole-packet admission")
(HMWitness "native-data" () "!(let $d (cons-atom Error (native datum)) (Box $d))" "[(Box (Error native datum))]\n")
(HMWitness "data-type" () "(: only-number (-> Number Number)) (= (only-number $x) $x) !(case (catch (only-number (cons-atom Error (native datum)))) (((Error $w (Unsolvable $d)) rejected) ($x missed)))" "[rejected]\n")
(HMWitness "budget" ("--fuel" "0") "!(+ 1 2)" "[(Error (+ 1 2) (Incomplete fuel-exhausted))]\n")
(HMWitness "data-admission" () "(Item (Error stored s)) !(match &self (Item $x) (Box $x))" "[(Box (Error stored s))]\n")
(HMWitness "data-freeze" () "(Item (g y)) !(match &self (Item $code) (let $added (add-atom &self (= (g y) done)) $code))" "[done]\n")
(HMWitness "data-nesting" () "(Item (Holder (Error stored (Fault b)))) !(let $container (match &self (Item $row) $row) (let (Holder $piece) $container (Box $piece)))" "[(Box (Error stored (Fault b)))]\n")
(HMWitness "data-substitution" () "!(let $d (catch (Error $w (Fault b))) (let $w 5 (Box $d)))" "[(Box (Error 5 (Fault b)))]\n")
(HMWitness "activation-root" () "!(let $d (catch (Error a (Forbidden b))) (let $r (eval $d) reached))" "[(Error a (Forbidden b))]\n")
(HMWitness "activation-deep" () "!(let $d (catch (Error a (Forbidden b))) (let $r (unquote (quote (Box $d))) (Nested $r)))" "[(Nested (Box (Error a (Forbidden b))))]\n")
(HMWitness "quote-activation" () "(= (qopen (quote $x)) $x) !(let $d (catch (Error a (Forbidden b))) (let $r (qopen (quote $d)) reached))" "[(Error a (Forbidden b))]\n")
(HMWitness "return-output" () "!(let $d (function (return (Error a (Fault b)))) never)" "[(Error a (Fault b))]\n")
(HMWitness "declared-output" () "(: held (-> Atom Atom)) (= (held $x) $x) !(let $d (held (Error a (Fault b))) never)" "[(Error a (Fault b))]\n")
(HMWitness "projection-origin" () "!(let $d (index-atom ((Error a (Fault b))) 0) never)" "[(Error a (Fault b))]\n")
(HMWitness "native-callback" () "unused" "unused: native fixture establishes fresh native VALUE admission")
(HMWitness "constructor-children" () "!(let (Holder $piece) (cons-atom Holder ((Error a (Fault b)))) (Box $piece))" "[(Error a (Fault b))]\n")
(HMWitness "alias-role" () "(= (g $v $e) $e) !(let $d (catch (Error $x (Fault b))) (let $r (g $x $d) (Box $r)))" "[(Box (Error $x (Fault b)))]\n")
(HMWitness "epoch-sharing" () "(= (dag $n $leaf) (if (== $n 0) $leaf (let $t (dag (- $n 1) $leaf) (Pair $t $t)))) (= (carry $v $value) $value) !(let $leaf (catch (Error $x (Fault b))) (let $d (dag 60 $leaf) (let $r (carry $x $d) ok)))" "[ok]\n")
(HMWitness "choice-capture" () "(= (pick $x) (Error $x (Forbidden reason))) (= (pick $x) $x) !(let $r (pick 3) (Got $r))" "(Error 3 (Forbidden reason))\n(Got 3)\n")
(HMWitness "typed-activation" () "!(let $d (catch (Error a (Fault b))) (let $r (metta $d Atom &self) (Box $r)))" "[(Box (Error a (Fault b)))]\n")
(HMWitness "sealed-origin" () "!(let $r (sealed () (Error a (Fault b))) never)" "[(Error a (Fault b))]\n")
(HMWitness "conversion-children" () "!(let (Error $where $kind) (__cetta_lib_list_to_expression [Error (Error inner (Fault reason)) (Fault outer)]) (Box $where))" "[(Error inner (Fault reason))]\n")
(HMWitness "once-role" () "!(let $e (catch (Error $x (Fault b))) (let $r (chain 5 $x $e) (Box $r)))" "[(Box (Error 5 (Fault b)))]\n")
(HMWitness "once-sharing" () "(= (dag $n $leaf) (if (== $n 0) $leaf (let $t (dag (- $n 1) $leaf) (pair $t $t)))) !(let $leaf (catch (Error $x (Fault b))) (let $d (dag 60 $leaf) (let $r (chain 5 $x $d) ok)))" "[ok]\n")
(HMWitness "memo-decline" () "!(import! &self (library lib_memo)) (: memo-hold (-> Atom %Undefined%)) (= (memo-hold $x) $x) !(memoize memo-hold) !(let $r (memo-hold (Error a (Forbidden b))) reached)" "true\ntrue\n(Error a (Forbidden b))\n")
(HMWitness "quote-machine" () "(= (qopen (quote $x)) $x) !(let $d (catch (Error a (Forbidden b))) (let $r (qopen (quote (quote $d))) reached))" "(Error a (Forbidden b))\n")
(HMWitness "constructed-root" () "!(let $v (cons-atom Error (a (Fault b))) (let $u $v (Box $u)))" "(Box (Error a (Fault b)))\n")
(HMWitness "raw-output" () "(: plain (-> Atom)) (= (plain) (Error a (Forbidden b))) !(let $r (plain) reached)" "(Error a (Forbidden b))\n")

(= (hm:file $root $dir $name $filename)
   (let* (($source (am:read (str:join "" ($root "/src/" $filename))))
          ($patches (collapse (match &self (HMReplace $name $old $new $count) (Patch $old $new $count))))
          ($changed (am:patches $source $patches))
          ($written (am:write (str:join "" ($dir "/" $filename)) $changed)))
     (HEMutationSource $name (size-atom $patches) (str:sha256 $source) (str:sha256 $changed))))
(= (hm:link $dev $dir $name $binary)
   (let* (($source (am:read (str:join "" ($dev "/" $name ".rsp"))))
          ($a (am:replace $source (str:concat $dev "/eval.o") (str:concat $dir "/eval.o") 1))
          ($b (am:replace $a (str:concat $dev "/grounded.o") (str:concat $dir "/grounded.o") 1))
          ($m (am:replace $b (str:concat $dev "/petta_search_machine.o") (str:concat $dir "/petta_search_machine.o") 1))
          ($s (am:replace $m (str:concat $dev "/space.o") (str:concat $dir "/space.o") 1))
          ($f (am:replace $s (str:concat $dev "/match.o") (str:concat $dir "/match.o") 1))
          ($c (am:replace $f (str:join "" ($dev "/" $binary)) (str:join "" ($dir "/" $binary)) 1)))
     (am:write (str:join "" ($dir "/" $name ".rsp")) $c)))
(= (hm:prepare $root $dev $dir)
   (let* (($made (fs:make-directories $dir 511))
          ($h (hm:file $root $dir "header" "ai_failure.h"))
          ($e (hm:file $root $dir "eval" "eval.c"))
          ($g (hm:file $root $dir "grounded" "grounded.c"))
          ($c (hm:file $root $dir "canonical" "eval_he_canonical.inc"))
          ($b (hm:file $root $dir "boundary" "eval_he_boundary.inc"))
          ($q (hm:file $root $dir "bindings" "eval_ai_bindings.inc"))
          ($m (hm:file $root $dir "machine" "petta_search_machine.c"))
          ($s (hm:file $root $dir "space" "space.c"))
          ($f (hm:file $root $dir "match" "match.c"))
          ($er (am:compile-response $dev $dir "eval" "eval.c" "eval.o"))
          ($gr (am:compile-response $dev $dir "grounded" "grounded.c" "grounded.o"))
          ($mr (am:compile-response $dev $dir "petta_search_machine" "petta_search_machine.c" "petta_search_machine.o"))
          ($sr (am:compile-response $dev $dir "space" "space.c" "space.o"))
          ($fr (am:compile-response $dev $dir "match" "match.c" "match.o"))
          ($lr (hm:link $dev $dir "link" "cetta"))
          ($nr (hm:link $dev $dir "native-link" "native")))
     (HEMutationSourcesPrepared $h $e $g $c $b $q $m $s $f)))
(HMLanguage "memo-decline" "petta")
(HMLanguage "quote-machine" "petta")
(HMLanguage "constructed-root" "petta")
(HMLanguage "raw-output" "petta")
(HMLanguage "choice-capture" "petta")
(= (hm:language $name)
   (let $matches (collapse (match &self (HMLanguage $name $language) $language))
     (if (== $matches ()) "he" (index-atom $matches 0))))
(= (hm:witness $dir $cwd $active (Witness $name $arguments $source $expected))
   (let* (($binary (str:concat $dir "/cetta"))
          ($language (hm:language $name))
          ($program (str:concat "!(ai:experiment failure-values) " $source))
          ($wanted (str:concat (if (== $language "he") "[()]\n" "()\n") $expected))
          ($base-argv (union-atom ($binary "--lang" $language "--profile" "ai")
                   (union-atom $arguments ("-e" $program))))
          ($cap (system:getenv-or-default "CETTA_AI_TEST_ADDRESS_LIMIT" ""))
          ($argv (if (and (or (== $name "once-sharing") (== $name "epoch-sharing")) (not (== $cap "")))
                   (union-atom ("/usr/bin/prlimit" (str:concat "--as=" $cap) "--") $base-argv)
                   $base-argv))
          ($result (proc:run $argv $cwd (am:environment $active) 15000 1048576))
          ($saved (am:write (str:join "" ($dir "/" $active "." $name ".log")) (repr $result))))
     (case $result
       (((proc:exited 0 $actual "")
          (if (== $actual $wanted) (MutantSurvived $name)
            (MutantKilled $name semantic)))
        ((proc:timed-out $out $err)
          (if (and (== $active $name) (or (== $name "once-sharing") (== $name "epoch-sharing")))
              (MutantKilled $name resource)
              (am:fail (UnexpectedHEMutationTimeout $active $name $out $err))))
        ((proc:signaled $signal $out $err)
          (if (and (and (== $active $name) (or (== $name "once-sharing") (== $name "epoch-sharing")))
                   (not (== $cap "")))
              (MutantKilled $name resource-signal)
              (am:fail (UnexpectedHEMutationSignal $active $name $signal $out $err))))
        ($other (am:fail (UnexpectedHEMutationExecution $active $name $other)))))))
(= (hm:native-one $dir $cwd $active $route)
   (let* (($environment (cons-atom ("CETTA_HE_CANONICAL_EXECUTION" $route) (am:environment $active)))
          ($result (proc:run ((str:concat $dir "/native") "--ai-native-he") $cwd $environment 15000 1048576))
          ($saved (am:write (str:join "" ($dir "/" $active ".native-he-" $route ".log")) (repr $result))))
   (case $result
     (((proc:exited 0 $out "")
        (if (am:contains $out "PASS: 35 HE AI native") (NativeControlPass)
          (am:fail (InvalidHENativeMutationControl $active $out))))
      ((proc:signaled 6 $out $err)
        (if (am:contains $err "Assertion") (MutantKilled $active native)
          (am:fail (UnexpectedHENativeAbort $active $out $err))))
      ($other (am:fail (UnexpectedHENativeMutationExecution $active $other)))))))
(= (hm:native $dir $cwd $active)
   (let $petta (proc:run ((str:concat $dir "/native") "--ai-native") $cwd (am:environment $active) 15000 1048576)
     (case $petta
       (((proc:exited 0 $out "")
          (if (am:contains $out "PASS: 35 PeTTa AI native")
            (case (hm:native-one $dir $cwd $active "1")
              (((NativeControlPass) (hm:native-one $dir $cwd $active "0")) ($killed $killed)))
            (am:fail (InvalidPeTTaNativeMutationControl $active $out))))
        ((proc:signaled 6 $out $err)
          (if (am:contains $err "Assertion") (MutantKilled $active native)
            (am:fail (UnexpectedPeTTaNativeAbort $active $out $err))))
        ($other (am:fail (UnexpectedPeTTaNativeMutationExecution $active $other)))))))
(= (hm:exercise $dir $cwd $active $entry)
   (case (hm:native $dir $cwd $active)
     (((NativeControlPass) (hm:witness $dir $cwd $active $entry))
      ($killed $killed))))
(= (hm:controls $dir $cwd $entries)
   (if (== $entries ()) (HEMutationControlPass)
     (let* (($entry (car-atom $entries)) ($rest (cdr-atom $entries)))
       (case $entry
         (((Witness $name $arguments $source $expected)
            (if (or (or (== $name "native-producer") (== $name "native-raise")) (or (== $name "packet") (== $name "native-callback")))
              (hm:controls $dir $cwd $rest)
              (case (hm:witness $dir $cwd "control" $entry)
                (((MutantSurvived $name) (hm:controls $dir $cwd $rest))
                 ($bad (am:fail (HEMutationControlFailed $bad))))))))))))
(= (hm:walk $dir $cwd $entries $killed $survived)
   (if (== $entries ()) (HEMutationSummary (+ $killed $survived) $killed $survived)
     (let* (($entry (car-atom $entries)) ($rest (cdr-atom $entries))
            ((Witness $name $arguments $source $expected) $entry)
            ($result (hm:exercise $dir $cwd $name $entry))
            ($shown (println! $result)))
       (case $result
         (((MutantKilled $name $stage) (hm:walk $dir $cwd $rest (+ $killed 1) $survived))
          ((MutantSurvived $name) (hm:walk $dir $cwd $rest $killed (+ $survived 1)))
          ($bad (am:fail (InvalidHEMutationResult $bad))))))))
(= (hm:run $dir $cwd)
   (let $entries (collapse (match &self (HMWitness $name $arguments $source $expected)
                                      (Witness $name $arguments $source $expected)))
     (case ((hm:native $dir $cwd "control") (hm:controls $dir $cwd $entries))
       ((((NativeControlPass) (HEMutationControlPass)) (hm:walk $dir $cwd $entries 0 0))
        ($bad (am:fail (HEMutationPositiveControlFailed $bad)))))))
