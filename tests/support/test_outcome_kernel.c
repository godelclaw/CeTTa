#include "atom.h"
#include "eval.h"
#include "grounded.h"
#include "library.h"
#include "native_handle.h"
#include "parser.h"
#include "prepared_pure_machine.h"
#include "runtime_names.h"
#include "session.h"
#include "space.h"
#include "symbol.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

static bool inject, interrupt_native, fail_calloc;
static CettaCallOutcome packet;
static const char *phase = "ownership";
static unsigned compiled_fault_calls, canonical_fault_calls;
static unsigned injected_calls;
static unsigned compiled_depth;
bool __real_cetta_prepared_pure_program_execute_closed_controlled(
    CettaPreparedPureProgram *, Arena *, size_t, CettaPreparedPureInterruptPollFn,
    void *, CettaCallOutcome *);
bool __wrap_cetta_prepared_pure_program_execute_closed_controlled(
    CettaPreparedPureProgram *program, Arena *arena, size_t bytes,
    CettaPreparedPureInterruptPollFn poll, void *context, CettaCallOutcome *out) {
    ++compiled_depth;
    bool result = __real_cetta_prepared_pure_program_execute_closed_controlled(
        program, arena, bytes, poll, context, out);
    --compiled_depth;
    return result;
}
CettaPreparedPureOptionalResult __real_cetta_prepared_pure_program_execute_closed_optional(
    CettaPreparedPureProgram *, Arena *, size_t, CettaPreparedPureInterruptPollFn,
    void *, Atom **);
CettaPreparedPureOptionalResult __wrap_cetta_prepared_pure_program_execute_closed_optional(
    CettaPreparedPureProgram *program, Arena *arena, size_t bytes,
    CettaPreparedPureInterruptPollFn poll, void *context, Atom **out) {
    ++compiled_depth;
    CettaPreparedPureOptionalResult result = __real_cetta_prepared_pure_program_execute_closed_optional(
        program, arena, bytes, poll, context, out);
    --compiled_depth;
    return result;
}
bool __real_grounded_call(Arena *, Atom *, Atom **, uint32_t, CettaCallOutcome *);
bool __wrap_grounded_call(Arena *a, Atom *head, Atom **args, uint32_t count,
                         CettaCallOutcome *out) {
    if (inject && atom_is_symbol_id(head, g_builtin_syms.op_plus)) {
        ++injected_calls;
        if (interrupt_native) eval_native_interrupt(CETTA_EVAL_INCOMPLETE_HOST_FAILURE);
        *out = packet;
        return true;
    }
    if (atom_is_symbol_id(head, g_builtin_syms.op_div)) {
        if (compiled_depth) ++compiled_fault_calls;
        else ++canonical_fault_calls;
    }
    return __real_grounded_call(a, head, args, count, out);
}
void *__real_calloc(size_t, size_t);
void *__wrap_calloc(size_t n, size_t size) {
    if (fail_calloc) { fail_calloc = false; return NULL; }
    return __real_calloc(n, size);
}

static CettaCallOutcome call(CettaLibraryContext *ctx, Space *space, Arena *a,
    SymbolId head, Atom **args, uint32_t count) {
    CettaCallOutcome out = {0};
    assert(cetta_eval_outcome_kernel_call(ctx, space, a,
        atom_symbol_id(a, head), args, count, &out));
    assert(cetta_call_outcome_shape_valid(out));
    return out;
}
static Atom *event(CettaLibraryContext *ctx, Space *space, Arena *a,
                   SymbolId kind, Atom *payload) {
    CettaCallOutcome out = call(ctx, space, a, kind, &payload, 1u);
    assert(out.kind == CETTA_CALL_VALUE && out.result_form == CETTA_CALL_RESULT_COMPLETED_VALUE);
    return out.term;
}
static void kind(CettaLibraryContext *ctx, Space *space, Arena *a, Atom *frame,
                 const char *expected) {
    CettaCallOutcome out = call(ctx, space, a, g_builtin_syms.lib_outcome_kind, &frame, 1u);
    assert(atom_is_symbol(out.term, expected));
}
static Atom *parse(Arena *a, const char *source) {
    size_t offset = 0;
    Atom *value = parse_sexpr(a, source, &offset);
    assert(value); return value;
}
static Atom *only_frame(CettaCallOutcome out) {
    assert(out.kind == CETTA_CALL_VALUE);
    if (out.result_form == CETTA_CALL_RESULT_COMPLETED_FRONTIER) {
        if (out.term->expr.len != 1u) {
            fprintf(stderr, "Unexpected outcome frontier in %s: ", phase);
            atom_print(out.term, stderr); fputc('\n', stderr);
        }
        assert(out.term->expr.len == 1u); return out.term->expr.elems[0];
    }
    assert(out.result_form == CETTA_CALL_RESULT_COMPLETED_VALUE);
    return out.term;
}

static void ownership(CettaLibraryContext *ctx, Space *space, Arena *a) {
    Arena producer, receiver;
    arena_init_detached(&producer); arena_init_detached(&receiver);
    Atom *error = parse(&producer, "(Error source (Forbidden detail))");
    Atom *value = event(ctx, space, &producer, g_builtin_syms.lib_outcome_value, error);
    Atom *raised = event(ctx, space, &producer, g_builtin_syms.lib_outcome_raised, error);
    kind(ctx, space, a, value, "value"); kind(ctx, space, a, raised, "raised");
    Atom *copy = atom_deep_copy(&receiver, value);
    assert(copy && receiver.external_bytes > 0u);
    /* An event's printed form is data, never the event. */
    Atom *forged = parse(a, "(Sealed outcome-value)");
    assert(!atom_eq(copy, forged));
    kind(ctx, space, a, forged, "data");
    arena_free(&producer);
    kind(ctx, space, a, copy, "value");
    CettaCallOutcome payload = call(ctx, space, a, g_builtin_syms.lib_outcome_payload, &copy, 1u);
    assert(atom_eq(payload.term, parse(a, "(Error source (Forbidden detail))")));
    CettaLibraryContext *other = calloc(1u, sizeof(*other));
    assert(other); other->native_handle_next_id = 1u;
    other->session = ctx->session;
    kind(other, space, a, copy, "data");
    cetta_native_handle_cleanup_all(other); free(other);
    CettaStorageCensus census = {0};
    arena_storage_census(&receiver, &census); cetta_storage_finish(&census);
    assert(!census.incomplete && !census.overflow && census.bytes > 0u);
    cetta_storage_census_free(&census);
    /* Once its last holder retires, the event's storage goes with it. */
    arena_free(&receiver);
    Atom *prior = event(ctx, space, a, g_builtin_syms.lib_outcome_value, atom_int(a, 42));
    fail_calloc = true;
    Atom *refused = event(ctx, space, a, g_builtin_syms.lib_outcome_value, atom_int(a, 43));
    assert(!fail_calloc);
    kind(ctx, space, a, refused, "incomplete");
    kind(ctx, space, a, prior, "value");
    Atom *forbidden = atom_state(a, NULL);
    assert(forbidden != NULL);
    Atom *unowned = event(ctx, space, a, g_builtin_syms.lib_outcome_value, forbidden);
    kind(ctx, space, a, unowned, "incomplete");
}

static void native_packets(CettaLibraryContext *ctx, Space *space, Arena *a) {
    Atom *args[] = {atom_symbol_id(a, g_builtin_syms.op_plus), atom_expr(a, NULL, 0u)};
    Atom *error = parse(a, "(Error native (Fault exact))");
    inject = true;
    packet = cetta_call_completed_value(error);
    kind(ctx, space, a, only_frame(call(ctx, space, a, g_builtin_syms.lib_outcome_invoke, args, 2u)), "value");
    packet = cetta_call_raised(error);
    kind(ctx, space, a, only_frame(call(ctx, space, a, g_builtin_syms.lib_outcome_invoke, args, 2u)), "raised");
    packet = cetta_call_completed_frontier(atom_expr(a, (Atom *[]){error, error}, 2u));
    CettaCallOutcome returned = call(ctx, space, a, g_builtin_syms.lib_outcome_invoke, args, 2u);
    assert(returned.term->expr.len == 2u);
    kind(ctx, space, a, returned.term->expr.elems[0], "value");
    kind(ctx, space, a, returned.term->expr.elems[1], "value");
    assert(!atom_eq(returned.term->expr.elems[0], returned.term->expr.elems[1]));
    packet = cetta_call_completed_frontier(atom_expr(a, (Atom *[]){error, NULL}, 2u));
    kind(ctx, space, a, only_frame(call(ctx, space, a, g_builtin_syms.lib_outcome_invoke, args, 2u)), "raised");
    packet = cetta_call_value(error);
    kind(ctx, space, a, only_frame(call(ctx, space, a, g_builtin_syms.lib_outcome_invoke, args, 2u)), "incomplete");
    packet = cetta_call_failure();
    assert(call(ctx, space, a, g_builtin_syms.lib_outcome_invoke, args, 2u).kind == CETTA_CALL_FAILURE);
    packet = cetta_call_interrupted(); interrupt_native = true;
    kind(ctx, space, a, only_frame(call(ctx, space, a, g_builtin_syms.lib_outcome_invoke, args, 2u)), "incomplete");
    assert(!eval_native_interrupted());
    interrupt_native = false;
    packet = (CettaCallOutcome){.kind = CETTA_CALL_SUSPENDED,
        .term = atom_int(a, 1), .delayed = atom_symbol(a, "pending")};
    kind(ctx, space, a, only_frame(call(ctx, space, a, g_builtin_syms.lib_outcome_invoke, args, 2u)), "incomplete");
    Atom *good = event(ctx, space, a, g_builtin_syms.lib_outcome_value, atom_int(a, 1));
    Atom *forged = parse(a, "(Sealed outcome-value)");
    args[1] = atom_expr(a, (Atom *[]){good, forged}, 2u);
    injected_calls = 0u;
    kind(ctx, space, a, only_frame(call(ctx, space, a, g_builtin_syms.lib_outcome_invoke, args, 2u)), "raised");
    assert(injected_calls == 0u);
    inject = false;
}

static void compiled_fault(CettaLibraryContext *ctx, Space *space, Arena *a) {
    space_add(space, parse(a, "(= (kernel-compiled-divide $n) (/ (+ $n 1) 0))"));
    Atom *source = parse(a, "(kernel-compiled-divide 4)");
    compiled_fault_calls = canonical_fault_calls = 0u;
    CettaCallOutcome returned = call(ctx, space, a, g_builtin_syms.lib_outcome_capture, &source, 1u);
    if (returned.kind == CETTA_CALL_VALUE && returned.result_form == CETTA_CALL_RESULT_COMPLETED_FRONTIER && returned.term->expr.len != 1u) {
        for (CettaExprIndex i = 0; i < returned.term->expr.len; ++i) {
            Atom *frame = returned.term->expr.elems[i];
            CettaCallOutcome tag = call(ctx, space, a, g_builtin_syms.lib_outcome_kind, &frame, 1u);
            CettaCallOutcome value = call(ctx, space, a, g_builtin_syms.lib_outcome_payload, &frame, 1u);
            atom_print(tag.term, stderr); fputs(": ", stderr);
            atom_print(value.term, stderr); fputc('\n', stderr);
        }
    }
    kind(ctx, space, a, only_frame(returned), "raised");
    assert(compiled_fault_calls == 1u);
    assert(canonical_fault_calls == 0u);
    assert(!eval_native_interrupted());
}

static void dependencies(Arena *a) {
    Space root, first, second, late;
    space_init(&root); space_init(&first); space_init(&second); space_init(&late);
    assert(space_add_dependency(&root, &first));
    SpaceProgramToken before = space_program_token(&root);
    Atom *equation = parse(a, "(= (owned-f $x) (+ $x 1))");
    space_add(&first, equation);
    assert(!space_program_token_is_current(before));
    before = space_program_token(&root);
    assert(space_remove(&first, equation));
    assert(!space_program_token_is_current(before));
    before = space_program_token(&root);
    space_add(&first, parse(a, "(: owned-f (-> Atom Atom))"));
    assert(!space_program_token_is_current(before));
    before = space_program_token(&root);
    assert(space_add_dependency(&root, &second));
    assert(!space_program_token_is_current(before));
    before = space_program_token(&root);
    assert(space_add_dependency(&root, &second));
    assert(space_program_token_is_current(before));
    space_add(&second, equation);
    assert(!space_program_token_is_current(before));
    /* Late links do not change the flat reader: imported members contribute
     * their own rows. A newly reachable module is not read recursively. */
    CettaCount visible = space_view_length64(&root);
    before = space_program_token(&root);
    space_add(&late, equation);
    assert(space_add_dependency(&first, &late));
    assert(space_program_token_is_current(before));
    assert(space_view_length64(&root) == visible);
    assert(space_add_dependency(&first, &root));
    assert(space_view_length64(&root) == visible);
    space_free(&first); space_free(&second); space_free(&late); space_free(&root);
}

int main(void) {
    SymbolTable symbols;
    symbol_table_init(&symbols); symbol_table_init_builtins(&symbols, &g_builtin_syms);
    g_symbols = &symbols;
    VarInternTable variables; var_intern_init(&variables); g_var_intern = &variables;
    CettaLibraryContext *ctx = calloc(1u, sizeof(*ctx)); assert(ctx);
    cetta_library_context_init_for_language_profile(ctx, CETTA_LANGUAGE_HE,
        cetta_profile_from_name_for_language(CETTA_LANGUAGE_HE, "ai"));
    eval_set_library_context(ctx);
    Arena a; arena_init_detached(&a);
    Space space; space_init(&space);
    Atom *argument = atom_int(&a, 1);
    CettaCallOutcome refused = call(ctx, &space, &a, g_builtin_syms.lib_outcome_value, &argument, 1u);
    assert(refused.kind == CETTA_CALL_RAISED && !ctx->outcome_brands[0]);
    assert(cetta_session_enable_experiment(&ctx->session, "outcome-kernel") == CETTA_EXPERIMENT_ENABLED);
    ctx->session.speculative = true;
    refused = call(ctx, &space, &a, g_builtin_syms.lib_outcome_value, &argument, 1u);
    assert(refused.kind == CETTA_CALL_RAISED && !ctx->outcome_brands[0]);
    ctx->session.speculative = false;
    ownership(ctx, &space, &a); phase = "native packets"; native_packets(ctx, &space, &a);
    phase = "compiled native fault"; compiled_fault(ctx, &space, &a); dependencies(&a);
    arena_free(&a); space_free(&space); cetta_native_handle_cleanup_all(ctx);
    eval_set_library_context(NULL); cetta_library_context_free(ctx); free(ctx);
    var_intern_free(&variables); symbol_table_free(&symbols);
    puts("OutcomeKernelNativePass ownership provenance packets interruption dependencies");
    return 0;
}
