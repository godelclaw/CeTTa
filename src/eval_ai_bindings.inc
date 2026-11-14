/* Equations that open quotations read the captured roots as code. Ordinary
 * parameter holding and data-pattern inspection retain their value roles. */
static bool ai_quotation_node(const Atom *node, void *context) {
    (void)context;
    return atom_is_quotation((Atom *)node);
}

static bool ai_binding_policy_current(const void *context) {
    return context && eval_failure_values() &&
        *(const CettaLanguageId *)context == eval_current_language_id();
}

/* These policy identities have static lifetime and own no dynamic storage.
 * Captured hook descriptors still implement the ordinary owner contract. */
static void ai_binding_policy_reference(void *context) { (void)context; }
static void ai_binding_policy_storage(const void *context, CettaStorageCensus *census) {
    (void)context;
    (void)census;
}

static bool ai_binding_policy_capture(void *context, void **owned) {
    if (!ai_binding_policy_current(context)) {
        eval_mark_incomplete(CETTA_EVAL_INCOMPLETE_INVALIDATED);
        return false;
    }
    *owned = context;
    return true;
}

static bool ai_binding_code_pattern(const void *context, const Atom *pattern) {
    if (!ai_binding_policy_current(context)) {
        eval_mark_interrupted(CETTA_EVAL_INCOMPLETE_HOST_FAILURE);
        return true;
    }
    bool complete = false;
    bool found = atom_graph_any_checked(pattern, ai_quotation_node, NULL, NULL,
        SIZE_MAX, &complete);
    if (!complete) {
        eval_mark_incomplete(CETTA_EVAL_INCOMPLETE_CAPACITY);
        return true;
    }
    return found;
}

static bool ai_binding_activate_variable(Arena *arena, Bindings *bindings, Atom *variable) {
    BindingValue value = bindings_lookup_value_id(bindings, variable->var_id);
    if (!value.skeleton)
        return true;
    if (value.skeleton->kind == ATOM_VAR) {
        Atom *resolved = bindings_apply(bindings, arena, variable);
        if (!resolved)
            return false;
        value = binding_value_from_atom(resolved);
    }
    Atom *code = cetta_ai_code_reading(arena, value.skeleton);
    if (!code)
        return false;
    if (code == value.skeleton)
        return true;
    value = binding_value_with_skeleton(value, code);
    /* The new root belongs to this observation's arena. It cannot keep a
     * persistent-skeleton certificate from the value it was copied from. */
    if (binding_value_kind(value) == BINDING_VALUE_CONTEXTUAL_PERSISTENT)
        binding_value_set_kind(&value, BINDING_VALUE_CONTEXTUAL);
    return bindings_rewrite_value_id(bindings, variable->var_id, value);
}

typedef struct { Atom *node; bool quoted; } AiQuoteScan;

static bool ai_binding_activate_quotations(Arena *arena, Atom *pattern, Bindings *bindings) {
    AiQuoteScan local[32], *stack = local;
    size_t size = 0u, capacity = sizeof(local) / sizeof(*local);
    AtomVisitSet seen[2] = {{0}, {0}};
    bool success = false;
#define AI_QUOTE_PUSH(node_, quoted_) do { \
    if (size == capacity) { \
        if (capacity > SIZE_MAX / 2u / sizeof(*stack)) goto done; \
        size_t next = capacity * 2u; \
        AiQuoteScan *grown = malloc(next * sizeof(*stack)); \
        if (!grown) goto done; \
        memcpy(grown, stack, size * sizeof(*stack)); \
        if (stack != local) free(stack); \
        stack = grown; capacity = next; \
    } \
    stack[size++] = (AiQuoteScan){(node_), (quoted_)}; \
} while (0)
    stack[size++] = (AiQuoteScan){pattern, false};
    while (size) {
        AiQuoteScan item = stack[--size];
        if (!item.node) goto done;
        bool fault = false;
        if (!atom_visit_set_add(&seen[item.quoted ? 1u : 0u], item.node, &fault)) {
            if (fault) goto done;
            continue;
        }
        if (item.node->kind == ATOM_VAR) {
            if (item.quoted && !ai_binding_activate_variable(arena, bindings, item.node))
                goto done;
        } else if (item.node->kind == ATOM_EXPR) {
            bool quoted = item.quoted || atom_is_quotation(item.node);
            for (CettaExprIndex i = item.node->expr.len; i > 0u; i--)
                AI_QUOTE_PUSH(item.node->expr.elems[i - 1u], quoted);
        }
    }
    success = true;
done:
#undef AI_QUOTE_PUSH
    if (stack != local) free(stack);
    atom_visit_set_free(&seen[0]);
    atom_visit_set_free(&seen[1]);
    return success;
}

static bool ai_binding_code_match(const void *context, Arena *arena,
    Atom *pattern, Atom *value, Bindings *bindings, bool *matched) {
    *matched = false;
    if (!ai_binding_policy_current(context)) {
        eval_mark_interrupted(CETTA_EVAL_INCOMPLETE_HOST_FAILURE);
        return false;
    }
    BindingsBuilder builder;
    if (!bindings_builder_init(&builder, bindings)) {
        eval_mark_incomplete(CETTA_EVAL_INCOMPLETE_CAPACITY);
        return false;
    }
    CettaMatchCompletion completion = match_atoms_builder_checked(value, pattern,
        &builder, arena, UINT64_MAX);
    Bindings candidate;
    bindings_init(&candidate);
    if (completion == CETTA_MATCH_MATCHED)
        bindings_builder_take(&builder, &candidate);
    bindings_builder_free(&builder);
    if (completion == CETTA_MATCH_REFUTED)
        return true;
    if (completion != CETTA_MATCH_MATCHED ||
        !ai_binding_activate_quotations(arena, pattern, &candidate)) {
        bindings_free(&candidate);
        eval_mark_incomplete(CETTA_EVAL_INCOMPLETE_CAPACITY);
        return false;
    }
    bindings_replace(bindings, &candidate);
    *matched = true;
    return true;
}

static const BindingsStructureHooks *ai_binding_hooks(CettaLanguageId language) {
    static const CettaLanguageId he = CETTA_LANGUAGE_HE, petta = CETTA_LANGUAGE_PETTA;
    static const BindingsStructureHooks he_hooks = {
        .context = (void *)&he, .capture = ai_binding_policy_capture,
        .retain = ai_binding_policy_reference, .release = ai_binding_policy_reference,
        .storage = ai_binding_policy_storage, .is_current = ai_binding_policy_current,
        .code_pattern = ai_binding_code_pattern, .code_match = ai_binding_code_match,
    };
    static const BindingsStructureHooks petta_hooks = {
        .context = (void *)&petta, .capture = ai_binding_policy_capture,
        .retain = ai_binding_policy_reference, .release = ai_binding_policy_reference,
        .storage = ai_binding_policy_storage, .is_current = ai_binding_policy_current,
        .code_pattern = ai_binding_code_pattern, .code_match = ai_binding_code_match,
    };
    return language == CETTA_LANGUAGE_HE ? &he_hooks
        : language == CETTA_LANGUAGE_PETTA ? &petta_hooks : NULL;
}
