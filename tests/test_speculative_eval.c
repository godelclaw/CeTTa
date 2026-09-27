#include "atom.h"
#include "effect_policy.h"
#include "eval.h"
#include "foreign.h"
#include "library.h"
#include "parser.h"
#include "space.h"
#include "symbol.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static Arena persistent, scratch;
static Space space;
static Registry registry;
static CettaLibraryContext *context;

static Atom *parse(const char *text) {
    size_t position=0;
    Atom *a=parse_sexpr(&persistent,text,&position);
    assert(a && position==strlen(text)); return a;
}
static void check(const char *text, const char *expected) {
    EvalOutcome result; eval_outcome_init(&result);
    int fuel=context->session.options.fuel_limit;
    eval_top_speculative(context,&space,&scratch,&persistent,&registry,parse(text),&result);
    assert(!context->session.speculative && !cetta_speculative_active());
    assert(context->session.options.fuel_limit==fuel);
    if (result.results.len!=1 || !atom_eq(result.results.items[0],parse(expected))) {
        fprintf(stderr,"unexpected speculative result for %s: ",text);
        for (CettaCount i=0;i<result.results.len;++i) atom_print(result.results.items[i],stderr);
        fputc('\n',stderr); abort();
    }
    assert(result.completion==CETTA_EVAL_COMPLETE);
    eval_outcome_free(&result);
}
static void denied(const char *text) {
    check(text,"(Error speculative-evaluation EffectNotAllowed)");
}
int main(int argc,char **argv) {
    assert(argc==4);
    SymbolTable symbols; symbol_table_init(&symbols);
    symbol_table_init_builtins(&symbols,&g_builtin_syms); g_symbols=&symbols;
    VarInternTable vars; var_intern_init(&vars); g_var_intern=&vars;
    arena_init(&persistent); arena_init(&scratch); space_init(&space);
    registry_init(&registry); registry_bind(&registry,"&self",atom_space(&persistent,&space));
    context=calloc(1,sizeof(*context)); assert(context);
    cetta_library_context_init(context); cetta_library_context_set_exec_path(context,argv[0]);
    cetta_eval_session_init_he_extended(&context->session);
    eval_set_library_context(context);
    const char *modules[]={"io","fs","system","str","rhometta","durable"};
    for (size_t i=0;i<sizeof(modules)/sizeof(*modules);++i) {
        Atom *error=NULL;
        if (!cetta_library_import(context,modules[i],&space,&scratch,&persistent,&registry,10000,&error)) {
            fprintf(stderr,"import %s: ",modules[i]); if (error) atom_print(error,stderr); abort();
        }
    }
#if CETTA_BUILD_WITH_PYTHON
    Atom *foreign_error=NULL;
    if (!cetta_foreign_load_module(context->foreign_runtime,argv[3],&space,&persistent,&foreign_error)) {
        if (foreign_error) atom_print(foreign_error,stderr);
        abort();
    }
#endif
    space_add(&space,parse("(= (computed $op) ($op \"SHOULD-NOT-PRINT\"))"));
    space_add(&space,parse("(record 42)"));
    check("(+ 1 2)","3");
    check("(match &self (record $x) (proposal $x))","(proposal 42)");
    check("(quote (io:submit (http:request GET private () body 1000 32)))",
          "(quote (io:submit (http:request GET private () body 1000 32)))");
    check("(if True (quote (telegram:send chat text)) (println! wrong))","(quote (telegram:send chat text))");
    check("(str:concat \"ab\" \"cd\")","\"abcd\"");
    denied("(println! secret)");
    denied("(computed println!)");
    denied("(let $op println! ($op secret))");
    denied("(import! &self fs)");
    denied("(pragma! fuel 1)");
    denied("(add-atom &self (record 43))");
    check("(collapse (match &self (record $x) $x))","(42)");
    denied("(new-state 1)");
    denied("(system:monotonic-ns)");
    denied("(__cetta_lib_system_monotonic_ns ())");
    denied("(__cetta_lib_durable_read \"dummy\" inbox)");
    denied("(__cetta_lib_future_operation ())");
    denied("(py-call anything ())");
#if CETTA_BUILD_WITH_PYTHON
    denied("(speculative-write)");
    denied("(let $fn speculative-write ($fn))");
#endif
    denied("(__cetta_lib_prolog_query anything ())");
    char expr[8192];
    snprintf(expr,sizeof(expr),"(fs:write \"%s\" \"forbidden\")",argv[2]); denied(expr);
    snprintf(expr,sizeof(expr),"(io:submit (http:request \"GET\" \"%s/counted\" () \"\" 1000 100))",argv[1]); denied(expr);
    char branch[9000];
    snprintf(branch,sizeof(branch),"(collapse (superpose (kept %s)))",expr);
    check(branch,"(kept)");
    snprintf(branch,sizeof(branch),"(collapse (hyperpose (kept %s)))",expr);
    check(branch,"(kept)");
    snprintf(branch,sizeof(branch),
        "(collapse (rhometta:transitions (rho:par (rho:recv (rho:quote rho:nil) $x (rho:drop $x)) "
        "(rho:send (rho:quote rho:nil) (rhometta:eval %s)))))",expr);
    check(branch,"((rho:val (Error speculative-evaluation EffectNotAllowed)))");
    check("(collapse (rhometta:transitions (rho:par (rho:recv (rho:quote rho:nil) $x (rho:drop $x)) (rho:send (rho:quote rho:nil) (rhometta:eval (+ 2 3))))))",
          "((rho:val 5))");
    /* The policy follows the library context into parallel evaluation too.
     * Eligibility may fall back to cooperative evaluation for effectful syntax. */
    assert(cetta_eval_session_record_generic_setting(&context->session,"num-threads",
        CETTA_EVAL_OPTION_VALUE_INT,"2",2));
    check("(collapse (hyperpose ((+ 1 1) (+ 2 2))))","(2 4)");
    snprintf(branch,sizeof(branch),"(collapse (hyperpose (kept %s)))",expr);
    check(branch,"(kept)");
    snprintf(branch,sizeof(branch),"(collapse (hyperpose (kept (let $op io:submit ($op (http:request \"GET\" \"%s/counted\" () \"\" 1000 100))))))",argv[1]);
    check(branch,"(kept)");
    /* Unsupported evaluator profiles fail before starting the expression. */
    CettaLanguageId saved_language=context->session.language_id;
    context->session.language_id=CETTA_LANGUAGE_PETTA;
    EvalOutcome refused; eval_outcome_init(&refused);
    eval_top_speculative(context,&space,&scratch,&persistent,&registry,parse("(println! secret)"),&refused);
    assert(refused.completion==CETTA_EVAL_INCOMPLETE_HOST_FAILURE && refused.results.len==1);
    assert(atom_is_error(refused.results.items[0]) && !context->session.speculative);
    eval_outcome_free(&refused); context->session.language_id=saved_language;
    /* Ordinary evaluation remains enabled after the policy scope exits. */
    ResultSet ordinary; result_set_init(&ordinary);
    eval_top_with_registry(&space,&scratch,&persistent,&registry,parse("(new-state 1)"),&ordinary);
    assert(ordinary.len==1 && ordinary.items[0]->kind==ATOM_GROUNDED && !atom_is_error(ordinary.items[0]));
    result_set_free(&ordinary);
    eval_set_library_context(NULL); cetta_library_context_free(context); free(context);
    registry_free(&registry); space_free(&space); arena_free(&scratch); arena_free(&persistent);
    g_var_intern=NULL; var_intern_free(&vars); g_symbols=NULL; symbol_table_free(&symbols);
    puts("speculative HE: pure proposals, quoted data, computed/foreign calls, nested choices/rho, two-thread configuration, forbidden effects, unsupported language and authority restoration passed");
    return 0;
}
