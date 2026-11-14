/* Explicit outcome observation. Base values keep their existing representation.
 * The owned envelope is inspected by registry identity, never printed syntax. */
#include "native_handle.h"

typedef enum {
    OUTCOME_KERNEL_VALUE,
    OUTCOME_KERNEL_RAISED,
    OUTCOME_KERNEL_INCOMPLETE,
} OutcomeKernelKind;

typedef struct {
    Arena storage;
    Atom *payload;
    OutcomeKernelKind kind;
} OutcomeKernelEnvelope;

static const char outcome_kernel_handle_kind[] = "outcome-kernel-event";

static void outcome_kernel_envelope_free(void *opaque) {
    OutcomeKernelEnvelope *envelope = opaque;
    arena_free(&envelope->storage);
    free(envelope);
}

static void outcome_kernel_envelope_storage(const void *opaque, CettaStorageCensus *census) {
    const OutcomeKernelEnvelope *envelope = opaque;
    if (cetta_storage_object(census, envelope, sizeof(*envelope), CETTA_STORAGE_BLOCK))
        arena_storage_census(&envelope->storage, census);
}

static bool outcome_kernel_unsupported_leaf(const Atom *atom, void *context) {
    (void)context;
    if (!atom || atom->kind != ATOM_GROUNDED) return false;
    switch (atom->ground.gkind) {
    case GV_SPACE: case GV_STATE: case GV_CAPTURE: case GV_FOREIGN:
    case GV_PRIME_NEED_CAPABILITY: case GV_PRIME_CONTEXT: case GV_BINDINGS:
    case GV_TERM_GRAPH: case GV_SEAL:
        return true;
    default: return false;
    }
}

static Atom *outcome_kernel_envelope(CettaLibraryContext *context, Arena *arena,
    OutcomeKernelKind kind, Atom *payload) {
    bool complete = false;
    if (!payload || atom_graph_any_checked(payload, outcome_kernel_unsupported_leaf,
            NULL, NULL, SIZE_MAX, &complete) || !complete)
        return NULL;
    OutcomeKernelEnvelope *envelope = calloc(1u, sizeof(*envelope));
    if (!envelope) return NULL;
    arena_init_detached(&envelope->storage);
    arena_set_block_growth(&envelope->storage, 4096u);
    envelope->kind = kind;
    envelope->payload = atom_deep_copy(&envelope->storage, payload);
    size_t storage = envelope->storage.reserved_bytes;
    if (envelope->storage.external_bytes > SIZE_MAX - storage ||
        sizeof(*envelope) > SIZE_MAX - storage - envelope->storage.external_bytes) {
        outcome_kernel_envelope_free(envelope);
        return NULL;
    }
    storage += envelope->storage.external_bytes + sizeof(*envelope);
    uint64_t id;
    if (!envelope->payload || !cetta_native_handle_alloc_sized(context,
            outcome_kernel_handle_kind, envelope, outcome_kernel_envelope_free, storage, &id)) {
        outcome_kernel_envelope_free(envelope);
        return NULL;
    }
    if (!cetta_native_handle_set_storage(context, outcome_kernel_handle_kind, id,
            outcome_kernel_envelope_storage)) {
        cetta_native_handle_close(context, outcome_kernel_handle_kind, id);
        return NULL;
    }
    Atom *result = cetta_native_handle_owned_atom(context, arena, outcome_kernel_handle_kind, id);
    if (!result) cetta_native_handle_close(context, outcome_kernel_handle_kind, id);
    return result;
}

static OutcomeKernelEnvelope *outcome_kernel_get(CettaLibraryContext *context, Atom *atom) {
    return cetta_native_handle_get_owned(context, outcome_kernel_handle_kind, atom);
}

static Atom *outcome_kernel_diagnostic(Arena *arena, Atom *where,
    const char *kind, const char *detail) {
    return atom_expr3(arena, atom_symbol(arena, "Error"), where,
        atom_expr2(arena, atom_symbol(arena, kind), atom_symbol(arena, detail)));
}

static Atom *outcome_kernel_refusal(CettaLibraryContext *context, Arena *arena,
    Atom *where, const char *kind, const char *detail, bool incomplete) {
    return outcome_kernel_envelope(context, arena,
        incomplete ? OUTCOME_KERNEL_INCOMPLETE : OUTCOME_KERNEL_RAISED,
        outcome_kernel_diagnostic(arena, where, kind, detail));
}

static bool outcome_kernel_finish(CettaLibraryContext *context, Arena *arena,
    Atom *value, CettaCallOutcome *out) {
    if (!value) {
        value = outcome_kernel_refusal(context, arena, atom_symbol(arena, "outcome-kernel"),
            "Incomplete", "UnsupportedValueOwnershipOrCapacity", true);
    }
    *out = value ? cetta_call_completed_value(value) : cetta_call_interrupted();
    if (!value) eval_mark_interrupted(CETTA_EVAL_INCOMPLETE_CAPACITY);
    return true;
}

static Atom *outcome_kernel_frame(CettaLibraryContext *context, Arena *arena,
    OutcomeKernelKind kind, Atom *payload) {
    return outcome_kernel_envelope(context, arena, kind, payload);
}

static bool outcome_kernel_capture(CettaLibraryContext *context, Space *space,
    Arena *arena, Atom **arguments, uint32_t count, CettaCallOutcome *out) {
    int budget = -1;
    if (count != 1u && count != 2u)
        return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
            atom_symbol(arena, "outcome:capture"), "Unsolvable", "IncorrectArity", false), out);
    if (count == 2u) {
        if (arguments[1]->kind != ATOM_GROUNDED || arguments[1]->ground.gkind != GV_INT ||
            arguments[1]->ground.ival < 0 || arguments[1]->ground.ival > INT_MAX)
            return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
                atom_symbol(arena, "outcome:capture"), "Unsolvable", "InvalidBudget", false), out);
        budget = (int)arguments[1]->ground.ival;
    }
    if (g_outcome_kernel_capture_depth == UINT32_MAX)
        return outcome_kernel_finish(context, arena, NULL, out);
    Atom *previous_raise = petta_eval_take_raise();
    Arena *previous_arena = g_outcome_kernel_capture_arena;
    PettaDirectiveReport previous_report = g_petta_directive_report;
    g_petta_directive_report = (PettaDirectiveReport){0};
    g_outcome_kernel_capture_depth++;
    g_outcome_kernel_capture_arena = arena;
    EvalOutcome observed;
    eval_outcome_init(&observed);
    observed.completion_consumed = true;
    CettaEvalEpisode boundary;
    eval_completion_child_begin(&boundary);
    /* PeTTa's explicit activation owns runtime source translation, including
     * tabled-call admission. Its bare metta interpretation has a different
     * nested relation policy. HE already fully interprets this source. */
    Atom *source = eval_current_language_id() == CETTA_LANGUAGE_PETTA
        ? atom_expr2(arena, atom_symbol_id(arena, g_builtin_syms.eval), arguments[0])
        : arguments[0];
    metta_eval_outcome(space, arena, NULL, source, budget, &observed);
    boundary.completion = CETTA_EVAL_COMPLETE;
    boundary.interrupted = false;
    (void)eval_completion_child_end(&boundary);
    Atom *raised = petta_eval_take_raise();
    bool reported_raise = g_petta_directive_report.known && g_petta_directive_report.raised;
    g_outcome_kernel_capture_depth--;
    g_outcome_kernel_capture_arena = previous_arena;
    g_petta_pending_raise = previous_raise;
    g_petta_directive_report = previous_report;
    if (!raised && reported_raise && observed.results.len == 1u) {
        raised = observed.results.items[0];
        observed.results.len = 0u;
    }
    size_t capacity = (size_t)observed.results.len + 2u;
    Atom **frames = arena_alloc(arena, sizeof(*frames) * capacity);
    CettaExprLen length = 0u;
    bool valid = frames != NULL;
    for (CettaCount index = 0u; valid && index < observed.results.len; index++) {
        Atom *value = outcome_kernel_frame(context, arena, OUTCOME_KERNEL_VALUE,
            observed.results.items[index]);
        if (!value) valid = false;
        else frames[length++] = value;
    }
    if (valid && raised) {
        Atom *value = outcome_kernel_frame(context, arena, OUTCOME_KERNEL_RAISED, raised);
        if (!value) valid = false;
        else frames[length++] = value;
    }
    if (valid && observed.completion != CETTA_EVAL_COMPLETE) {
        Atom *value = outcome_kernel_refusal(context, arena, arguments[0], "Incomplete",
            eval_completion_reason(observed.completion), true);
        if (!value) valid = false;
        else frames[length++] = value;
    }
    eval_outcome_free(&observed);
    if (!valid) return outcome_kernel_finish(context, arena, NULL, out);
    *out = length ? cetta_call_completed_frontier(atom_expr(arena, frames, length))
                  : cetta_call_failure();
    return true;
}

static bool outcome_kernel_invoke(CettaLibraryContext *context, Space *space,
    Arena *arena, Atom **arguments, uint32_t count, CettaCallOutcome *out) {
    if (count != 2u || arguments[0]->kind != ATOM_SYMBOL || arguments[1]->kind != ATOM_EXPR)
        return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
            atom_symbol(arena, "outcome:invoke"), "Unsolvable", "ExpectedHeadAndValueEnvelopes", false), out);
    CettaExprLen length = arguments[1]->expr.len;
    Atom **values = arena_alloc(arena, sizeof(*values) * (length ? length : 1u));
    if (!values) return outcome_kernel_finish(context, arena, NULL, out);
    for (CettaExprIndex index = 0u; index < length; index++) {
        OutcomeKernelEnvelope *argument = outcome_kernel_get(context, arguments[1]->expr.elems[index]);
        if (!argument || argument->kind != OUTCOME_KERNEL_VALUE)
            return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
                atom_symbol(arena, "outcome:invoke"), "Unsolvable", "ExpectedValueEnvelope", false), out);
        values[index] = argument->payload;
    }
    CettaCallOutcome reply;
    CettaInvocation invocation = {.head = binding_value_from_atom(arguments[0]),
        .supplied = {.atoms = values, .count = length}};
    uint32_t outer_capture = g_outcome_kernel_capture_depth;
    Atom *previous_raise = petta_eval_take_raise();
    CettaEvalEpisode episode;
    eval_completion_child_begin(&episode);
    g_outcome_kernel_capture_depth = 0u;
    g_outcome_kernel_invoke_depth++;
    bool handled = dispatch_native_invocation(space, arena, &invocation, &reply);
    g_outcome_kernel_invoke_depth--;
    g_outcome_kernel_capture_depth = outer_capture;
    Atom *raised = petta_eval_take_raise();
    g_petta_pending_raise = previous_raise;
    CettaEvalCompletion own_completion = episode.completion;
    episode.completion = CETTA_EVAL_COMPLETE;
    episode.interrupted = false;
    (void)eval_completion_child_end(&episode);
    if (raised) reply = cetta_call_raised(raised);
    if (own_completion != CETTA_EVAL_COMPLETE)
        return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
            arguments[0], "Incomplete", eval_completion_reason(own_completion), true), out);
    if (!handled)
        return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
            arguments[0], "Unsolvable", "NativeOperationUnavailable", false), out);
    if (!cetta_call_outcome_shape_valid(reply))
        return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
            arguments[0], "Fault", "MalformedNativeOutcome", false), out);
    if (reply.kind == CETTA_CALL_FAILURE) { *out = cetta_call_failure(); return true; }
    if (reply.kind == CETTA_CALL_INTERRUPTED || reply.kind == CETTA_CALL_SUSPENDED)
        return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
            arguments[0], "Incomplete", reply.kind == CETTA_CALL_SUSPENDED
                ? "UnresolvedNativeConditions" : "NativeInterrupted", true), out);
    eval_native_qualify_result(atom_symbol_current_id(arguments[0]), (uint32_t)length, &reply);
    if (reply.kind == CETTA_CALL_VALUE &&
        (reply.result_form == CETTA_CALL_RESULT_EXPRESSION_FRONTIER ||
         (reply.result_form == CETTA_CALL_RESULT_EXPRESSION &&
          (!reply.term || reply.term->kind != ATOM_GROUNDED))))
        return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
            arguments[0], "Incomplete", "NativeCompletionRequired", true), out);
    CettaCallReturnCursor cursor = {.outcome = reply};
    CettaEvalCompletion completion = CETTA_EVAL_COMPLETE;
    CettaOwnedReturn returned;
    /* Validate the complete borrowed packet before publishing its first frame. */
    while (cetta_call_return_next(&cursor, &returned, &completion) == CETTA_OWNED_EXECUTION_RETURN) {}
    if (completion != CETTA_EVAL_COMPLETE)
        return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
            arguments[0], "Fault", "MalformedNativePacket", false), out);
    CettaExprLen capacity = cetta_call_result_is_frontier(reply.result_form) ? reply.term->expr.len : 1u;
    Atom **frames = arena_alloc(arena, sizeof(*frames) * (capacity ? capacity : 1u));
    if (!frames) return outcome_kernel_finish(context, arena, NULL, out);
    cursor.position = 0u;
    CettaExprLen used = 0u;
    while (cetta_call_return_next(&cursor, &returned, &completion) == CETTA_OWNED_EXECUTION_RETURN) {
        Atom *frame = outcome_kernel_frame(context, arena,
            returned.outcome.kind == CETTA_CALL_RAISED ? OUTCOME_KERNEL_RAISED : OUTCOME_KERNEL_VALUE,
            returned.outcome.term);
        if (!frame) return outcome_kernel_finish(context, arena, NULL, out);
        frames[used++] = frame;
    }
    *out = used ? cetta_call_completed_frontier(atom_expr(arena, frames, used)) : cetta_call_failure();
    return true;
}

bool cetta_eval_outcome_kernel_call(CettaLibraryContext *context, Space *space,
    Arena *arena, Atom *head, Atom **arguments, uint32_t count, CettaCallOutcome *out) {
    if (!context || !head || head->kind != ATOM_SYMBOL || !out) return false;
    SymbolId id = atom_symbol_current_id(head);
    if (id < g_builtin_syms.lib_outcome_capture || id > g_builtin_syms.lib_outcome_pack) return false;
    if (!(context->session.experiments & CETTA_EXPERIMENT_OUTCOME_KERNEL) ||
        context->session.speculative) {
        /* Admission has not installed an outcome owner. Refuse through the
         * existing native channel without mutating the handle registry. */
        *out = cetta_call_raised(outcome_kernel_diagnostic(arena, head, "Forbidden",
            context->session.speculative ? "SpeculativeOutcomeBoundary" : "OutcomeKernelNotDeclared"));
        return true;
    }
    if (id == g_builtin_syms.lib_outcome_capture)
        return outcome_kernel_capture(context, space, arena, arguments, count, out);
    if (id == g_builtin_syms.lib_outcome_invoke)
        return outcome_kernel_invoke(context, space, arena, arguments, count, out);
    if ((id == g_builtin_syms.lib_outcome_value || id == g_builtin_syms.lib_outcome_raised ||
         id == g_builtin_syms.lib_outcome_incomplete) && count == 1u)
        return outcome_kernel_finish(context, arena, outcome_kernel_frame(context, arena,
            id == g_builtin_syms.lib_outcome_value ? OUTCOME_KERNEL_VALUE
                : id == g_builtin_syms.lib_outcome_raised ? OUTCOME_KERNEL_RAISED : OUTCOME_KERNEL_INCOMPLETE,
            arguments[0]), out);
    OutcomeKernelEnvelope *envelope = count ? outcome_kernel_get(context, arguments[0]) : NULL;
    if (id == g_builtin_syms.lib_outcome_kind && count == 1u) {
        /* Interned once: a kind is asked for on every bind. */
        static SymbolId kinds[4];
        if (kinds[0] == SYMBOL_ID_NONE) {
            kinds[1] = symbol_intern_cstr(g_symbols, "value");
            kinds[2] = symbol_intern_cstr(g_symbols, "raised");
            kinds[3] = symbol_intern_cstr(g_symbols, "incomplete");
            kinds[0] = symbol_intern_cstr(g_symbols, "data");
        }
        *out = cetta_call_completed_value(atom_symbol_id(arena, !envelope ? kinds[0]
            : envelope->kind == OUTCOME_KERNEL_VALUE ? kinds[1]
            : envelope->kind == OUTCOME_KERNEL_RAISED ? kinds[2] : kinds[3]));
        return true;
    }
    if (id == g_builtin_syms.lib_outcome_payload && count == 1u && envelope) {
        *out = cetta_call_completed_value(atom_deep_copy(arena, envelope->payload));
        return true;
    }
    if (id == g_builtin_syms.lib_outcome_rechannel && count == 2u && envelope) {
        OutcomeKernelKind kind;
        if (atom_is_symbol(arguments[1], "value")) kind = OUTCOME_KERNEL_VALUE;
        else if (atom_is_symbol(arguments[1], "raised")) kind = OUTCOME_KERNEL_RAISED;
        else if (atom_is_symbol(arguments[1], "incomplete")) kind = OUTCOME_KERNEL_INCOMPLETE;
        else return outcome_kernel_finish(context, arena, NULL, out);
        return outcome_kernel_finish(context, arena,
            outcome_kernel_frame(context, arena, kind, envelope->payload), out);
    }
    if (id == g_builtin_syms.lib_outcome_equal && count == 2u) {
        OutcomeKernelEnvelope *other = outcome_kernel_get(context, arguments[1]);
        *out = cetta_call_completed_value(atom_bool(arena, envelope && other &&
            envelope->kind == other->kind && atom_eq(envelope->payload, other->payload)));
        return true;
    }
    if (id == g_builtin_syms.lib_outcome_pack && count == 1u && arguments[0]->kind == ATOM_EXPR) {
        CettaExprLen length = arguments[0]->expr.len;
        Atom **values = arena_alloc(arena, sizeof(*values) * (length ? length : 1u));
        if (!values) return outcome_kernel_finish(context, arena, NULL, out);
        for (CettaExprIndex index = 0u; index < length; index++) {
            OutcomeKernelEnvelope *item = outcome_kernel_get(context, arguments[0]->expr.elems[index]);
            if (!item || item->kind != OUTCOME_KERNEL_VALUE)
                return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
                    head, "Unsolvable", "ExpectedObservedValueEnvelopes", false), out);
            values[index] = item->payload;
        }
        return outcome_kernel_finish(context, arena,
            outcome_kernel_frame(context, arena, OUTCOME_KERNEL_VALUE, atom_expr(arena, values, length)), out);
    }
    return outcome_kernel_finish(context, arena, outcome_kernel_refusal(context, arena,
        head, "Unsolvable", "InvalidOutcomeOperation", false), out);
}
