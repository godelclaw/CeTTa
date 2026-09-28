#define _POSIX_C_SOURCE 200809L
#include "atom.h"
#include "cetta_stdlib.h"
#include "durable_value.h"
#include "telegram_intake.h"
#include "eval.h"
#include "library.h"
#include "parser.h"
#include "symbol.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static Arena persistent, scratch;
static Space program;
static Registry registry;
static CettaLibraryContext context;
static unsigned checks;
static Atom *parse(const char *text) {
    size_t pos=0; Atom *a=parse_sexpr(&persistent,text,&pos);
    assert(a && pos==strlen(text)); return a;
}
static Atom *run(Atom *call, int fuel, EvalOutcome *out) {
    eval_outcome_init(out);
    eval_top_speculative(&context,&program,&scratch,&persistent,&registry,call,fuel,out);
    if (out->completion!=CETTA_EVAL_COMPLETE || out->effect_denials || out->results.len!=1) {
        fprintf(stderr,"policy evaluation: completion %d, denials %llu, results %llu, steps %llu\n",
            out->completion,(unsigned long long)out->effect_denials,(unsigned long long)out->results.len,
            (unsigned long long)out->steps_spent);
        fprintf(stderr,"check %u call: ",checks); atom_print(call,stderr); fputc('\n',stderr);
        for (CettaCount i=0;i<out->results.len;++i) { atom_print(out->results.items[i],stderr); fputc('\n',stderr); }
        abort();
    }
    return out->results.items[0];
}
static void check(const char *expr, const char *expected) {
    EvalOutcome out; Atom *a=run(parse(expr),1000000,&out);
    if (!atom_eq(a,parse(expected))) {
        fprintf(stderr,"check %u %s\nexpected: %s\nactual: ",checks,expr,expected); atom_print(a,stderr); abort();
    }
    ++checks; eval_outcome_free(&out);
}
static Atom *decode(const char *body, const char *policy, EvalOutcome *out) {
    /* Provider text enters as a string, never as MeTTa source. */
    Atom *args[]={atom_symbol(&persistent,"telegram:decode"),atom_string(&persistent,body),parse(policy)};
    return run(atom_expr(&persistent,args,3),1000000,out);
}
static const char *policy="(telegram:policy 1 (-100 42) False (7) (8))";
static bool form(const Atom *a, const char *head, size_t n) {
    return a && a->kind==ATOM_EXPR && a->expr.len==n && atom_is_symbol(a->expr.elems[0],head);
}
static bool text(const Atom *a, const char *s) {
    return a && a->kind==ATOM_GROUNDED && a->ground.gkind==GV_STRING && !strcmp(a->ground.sval,s);
}
static Atom *items(Atom *a, size_t n) {
    if (!form(a,"telegram:batch",3) || a->expr.elems[2]->kind!=ATOM_EXPR || a->expr.elems[2]->expr.len!=n) {
        fprintf(stderr,"expected batch of %zu: ",n); atom_print(a,stderr); abort();
    }
    return a->expr.elems[2];
}
static void route(const char *body, const char *config, const char *lane, const char *disposition,
                  const char *kind, int64_t chat, int64_t thread, int64_t sender, const char *role) {
    EvalOutcome out; Atom *a=items(decode(body,config,&out),1)->expr.elems[0];
    assert(form(a,"tg:item",5) && text(a->expr.elems[2],lane) && atom_is_symbol(a->expr.elems[3],disposition));
    a=a->expr.elems[4];
    assert(form(a,"telegram:input",8) && text(a->expr.elems[2],kind));
    assert(a->expr.elems[3]->ground.ival==chat && a->expr.elems[4]->ground.ival==thread &&
           a->expr.elems[5]->ground.ival==sender && atom_is_symbol(a->expr.elems[6],role));
    ++checks; eval_outcome_free(&out);
}
static void response(const char *body, const char *expected) {
    EvalOutcome out; Atom *a=decode(body,policy,&out);
    if (!atom_eq(a,parse(expected))) {
        fprintf(stderr,"response check %u\nexpected: %s\nactual: ",checks,expected); atom_print(a,stderr); abort();
    }
    ++checks; eval_outcome_free(&out);
}
static void long_message(void) {
    /* Production-sized text, not only tiny protocol examples. */
    char message[5000], content[4097]; memset(content,'x',4096); content[4096]=0;
    snprintf(message,sizeof(message),"{\"ok\":true,\"result\":[{\"update_id\":500,\"message\":{\"chat\":{\"id\":42,\"type\":\"private\"},\"text\":\"%s\"}}]}",content);
    EvalOutcome out; clock_t start=clock();
    Atom *large_result=decode(message,policy,&out);
    if (!form(large_result,"telegram:batch",3)) {
        EvalOutcome diagnostic; Atom *args[]={atom_symbol(&persistent,"json:parse"),atom_string(&persistent,message)};
        Atom *why=run(atom_expr(&persistent,args,2),1000000,&diagnostic);
        if (!form(why,"JsonObjectV1",2)) atom_print(why,stderr);
        eval_outcome_free(&diagnostic);
    }
    items(large_result,1);
    printf("4096-character message: %.3f CPU s, %llu evaluator steps\n",
        (double)(clock()-start)/CLOCKS_PER_SEC,(unsigned long long)out.steps_spent);
    eval_outcome_free(&out); ++checks;
}
static void poll(CettaDurableStore *store, const char *source, const char *body,
                 const char *recorded_source, int64_t status) {
    CettaInboxWindow *w=NULL;
    assert(cetta_inbox_begin(store,source,&w)==DURABLE_OK);
    Atom *metadata[]={atom_bool(&persistent,true),atom_bool(&persistent,false),atom_int(&persistent,0),
        atom_int(&persistent,status),atom_bool(&persistent,true),atom_int(&persistent,100),
        atom_bool(&persistent,false),atom_bool(&persistent,false),atom_bool(&persistent,false)};
    Atom *fields[]={atom_symbol(&persistent,"host:poll"),atom_int(&persistent,1),
        atom_string(&persistent,recorded_source),atom_int(&persistent,cetta_inbox_offset(w)),
        atom_symbol(&persistent,"observed"),atom_expr(&persistent,metadata,9),atom_string(&persistent,body)};
    unsigned char *data=NULL; size_t size=0;
    assert(cetta_durable_value_encode(atom_expr(&persistent,fields,7),&data,&size)==DURABLE_OK);
    assert(cetta_inbox_record_poll(w,data,size)==DURABLE_OK);
    free(data); cetta_inbox_window_free(w);
}
static void intake_checks(const char *body, const char *config) {
    char path[]="/tmp/cetta-telegram-policy-XXXXXX";
    int fd=mkstemp(path); assert(fd>=0); close(fd);
    CettaDurableStore *store=NULL; assert(cetta_durable_open(path,NULL,&store)==DURABLE_OK);
    CettaHostProgram trusted={"telegram/intake/1",&program,&context};
    CettaTelegramIntake *a=NULL,*b=NULL; CettaInboxCommit commit;
    poll(store,"bot",body,"bot",200);
    assert(cetta_telegram_intake_begin(store,"bot",trusted.version,&a)==DURABLE_OK);
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_PRECONDITION && commit.next_offset==-1);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse(config),30)==DURABLE_OK);
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_PRECONDITION);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse(config),1000000)==DURABLE_OK);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse(config),0)==DURABLE_INVALID);
    assert(!cetta_telegram_intake_outcome(a));
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_PRECONDITION);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse(config),1000000)==DURABLE_OK);
    assert(cetta_telegram_intake_begin(store,"bot",trusted.version,&b)==DURABLE_OK);
    assert(cetta_telegram_intake_evaluate(b,&trusted,parse(config),1000000)==DURABLE_OK);
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_OK && commit.inserted==1 && commit.next_offset==11);
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_CONFLICT);
    assert(cetta_telegram_intake_commit(b,&commit)==DURABLE_CONFLICT);
    cetta_telegram_intake_free(a); cetta_telegram_intake_free(b);
    /* New policy refuses this chat and revokes the sender's operator status.
     * A replay still reuses the first classification; it is not new input. */
    poll(store,"bot",body,"bot",200);
    assert(cetta_telegram_intake_begin(store,"bot",trusted.version,&a)==DURABLE_OK);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse("(telegram:policy 1 () False () ())"),1000000)==DURABLE_OK);
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_OK && commit.inserted==0 && commit.next_offset==11);
    cetta_telegram_intake_free(a); ++checks;
    /* The same ID with a changed provider payload cannot silently replace it. */
    poll(store,"bot","{\"ok\":true,\"result\":[{\"update_id\":10,\"future\":true}]}","bot",200);
    assert(cetta_telegram_intake_begin(store,"bot",trusted.version,&a)==DURABLE_OK);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse(config),1000000)==DURABLE_OK);
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_CORRUPT && commit.next_offset==-1);
    cetta_telegram_intake_free(a); ++checks;
    poll(store,"wrong-source",body,"different",200);
    assert(cetta_telegram_intake_begin(store,"wrong-source",trusted.version,&a)==DURABLE_OK);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse(config),1000000)==DURABLE_CORRUPT);
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_PRECONDITION);
    cetta_telegram_intake_free(a); ++checks;
    poll(store,"http-failure",body,"http-failure",500);
    assert(cetta_telegram_intake_begin(store,"http-failure",trusted.version,&a)==DURABLE_OK);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse(config),1000000)==DURABLE_OK);
    assert(atom_eq(cetta_telegram_intake_outcome(a)->results.items[0],parse("(telegram:hold 1 transport-outcome)")));
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_PRECONDITION);
    cetta_telegram_intake_free(a); ++checks;
    poll(store,"rate","{\"ok\":false,\"error_code\":429,\"parameters\":{\"retry_after\":3}}","rate",429);
    assert(cetta_telegram_intake_begin(store,"rate",trusted.version,&a)==DURABLE_OK);
    CettaHostProgram wrong=trusted; wrong.version="different";
    assert(cetta_telegram_intake_evaluate(a,&wrong,parse(config),1000000)==DURABLE_VERSION);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse("(telegram:policy 1 (bad) False () ())"),1000000)==DURABLE_INVALID);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse(config),1000000)==DURABLE_OK);
    assert(atom_eq(cetta_telegram_intake_outcome(a)->results.items[0],parse("(telegram:retry 1 3 rate-limit)")));
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_PRECONDITION);
    cetta_telegram_intake_free(a); ++checks;
    /* A swallowed effect denial is still host-visible and blocks intake. */
    Atom *original_rule=NULL;
    for (CettaCount i=0;i<space_length64(&program);++i) {
        Atom *rule=space_get_at64(&program,i);
        if (form(rule,"=",3) && form(rule->expr.elems[1],"telegram:poll",3)) { original_rule=rule; break; }
    }
    assert(original_rule); space_remove(&program,original_rule);
    Atom *denied=parse("(= (telegram:poll $x $p) (let $ignored (collapse (superpose (kept (println! denied)))) (telegram:batch 1 ())))");
    space_add(&program,denied);
    assert(cetta_telegram_intake_begin(store,"rate",trusted.version,&a)==DURABLE_OK);
    assert(cetta_telegram_intake_evaluate(a,&trusted,parse(config),1000000)==DURABLE_OK);
    assert(cetta_telegram_intake_outcome(a)->effect_denials>0);
    assert(cetta_telegram_intake_outcome(a)->results.len==1 &&
        atom_eq(cetta_telegram_intake_outcome(a)->results.items[0],parse("(telegram:batch 1 ())")));
    assert(cetta_telegram_intake_commit(a,&commit)==DURABLE_PRECONDITION);
    cetta_telegram_intake_free(a); space_remove(&program,denied); space_add(&program,original_rule); ++checks;
    cetta_durable_close(store);
    assert(cetta_durable_open(path,NULL,&store)==DURABLE_OK);
    CettaInboxWindow *w=NULL;
    assert(cetta_inbox_begin(store,"rate",&w)==DURABLE_PRECONDITION);
    assert(cetta_inbox_recover_poll(store,"bot",&w)==DURABLE_OK && cetta_inbox_offset(w)==11);
    cetta_inbox_window_free(w); cetta_durable_close(store); unlink(path);
    char side[300]; snprintf(side,sizeof(side),"%s-wal",path); unlink(side);
    snprintf(side,sizeof(side),"%s-shm",path); unlink(side); ++checks;
}
int main(int argc,char **argv) {
    assert(argc==1 || (argc==2 && !strcmp(argv[1],"--long-message")));
    SymbolTable symbols; symbol_table_init(&symbols); symbol_table_init_builtins(&symbols,&g_builtin_syms); g_symbols=&symbols;
    VarInternTable vars; var_intern_init(&vars); g_var_intern=&vars;
    arena_init(&persistent); arena_init(&scratch); space_init(&program); registry_init(&registry);
    registry_bind(&registry,"&self",atom_space(&persistent,&program));
    cetta_library_context_init(&context); cetta_library_context_set_exec_path(&context,argv[0]);
    cetta_eval_session_init_he_extended(&context.session); eval_set_library_context(&context);
    stdlib_load(&program,&persistent);
    Atom *error=NULL;
    if (!cetta_library_import_module(&context,"durable:telegram",&program,false,&scratch,&persistent,&registry,1000000,&error)) {
        if (error) atom_print(error,stderr);
        abort();
    }
    if (argc==2) { long_message(); goto cleanup; }
    check("(telegram:integer (JsonNumberV1 \"-9223372036854775808\"))","(tg:integer -9223372036854775808)");
    check("(telegram:integer (JsonNumberV1 \"9223372036854775807\"))","(tg:integer 9223372036854775807)");
    check("(telegram:integer (JsonNumberV1 \"9223372036854775808\"))","tg:bad");
    check("(telegram:integer (JsonNumberV1 \"-9223372036854775809\"))","tg:bad");
    check("(telegram:integer (JsonNumberV1 \"7e0\"))","tg:bad");
    check("(telegram:integer (JsonNumberV1 \"1.0\"))","tg:bad");
    check("(json:parse \"null\")","JsonNullV1");
    check("(sort-atom (b a))","(a b)");
    check("(unique-atom (a a))","(a)");
    check("(unique-atom ())","()");
    check("(sort-atom ())","()");
    check("(telegram:member-keys ((JsonMemberV1 0 k v span)))","(k)");
    check("(telegram:member k ((JsonMemberV1 0 k v span)))","(tg:some v)");
    check("(telegram:normalize (JsonBoolV1 True) 0)","(tg:ok (JsonBoolV1 True))");
    check("(telegram:object-members ((JsonMemberV1 0 k (JsonBoolV1 True) span)) (k) 0 1)","(tg:ok ((JsonMemberV1 0 k (JsonBoolV1 True) JsonNoSourceSpanV1)))");
    check("(telegram:normalize (json:parse \"{}\") 0)","(tg:ok (JsonObjectV1 ()))");
    check("(telegram:normalize (json:parse \"{\\\"ok\\\":true}\") 0)","(tg:ok (JsonObjectV1 ((JsonMemberV1 0 (JsonStringV1 ((cp 111) (cp 107))) (JsonBoolV1 True) JsonNoSourceSpanV1))))");
    response("{\"ok\":true,\"result\":[]}","(telegram:batch 1 ())");
    response("{\"ok\":true,\"ok\":true,\"result\":[]}","(telegram:hold 1 malformed-json)");
    response("{\"ok\":true,\"result\":{}}","(telegram:hold 1 malformed-response)");
    response("{\"ok\":false,\"error_code\":429,\"parameters\":{\"retry_after\":3}}","(telegram:retry 1 3 rate-limit)");
    response("{\"ok\":false,\"error_code\":409}","(telegram:hold 1 conflicting-poller)");
    response("{\"ok\":false,\"error_code\":500}","(telegram:hold 1 api-error)");
    check("(telegram:route 4 \"message\" (json:parse \"{\\\"chat\\\":{\\\"id\\\":42,\\\"type\\\":\\\"private\\\"},\\\"message_thread_id\\\":5}\") (tg:integer 7) dummy (telegram:policy 1 (42) False (7) (8)))",
        "(tg:item 4 \"42.5\" routed (telegram:input 1 \"message\" 42 5 7 operator dummy))");
    const char *group="{\"ok\":true,\"result\":[{\"update_id\":10,\"message\":{\"chat\":{\"id\":-100,\"type\":\"supergroup\"},\"message_thread_id\":12,\"from\":{\"id\":7},\"text\":\"a\\u0000b 😀\"}}]}";
    route(group,policy,"-100.12","routed","message",-100,12,7,"operator");
    route(group,"(telegram:policy 1 () True (7) ())","-100.12","unauthorized","message",-100,12,7,"operator");
    const char *priv="{\"ok\":true,\"result\":[{\"update_id\":20,\"edited_message\":{\"chat\":{\"id\":19,\"type\":\"private\"},\"from\":{\"id\":8}}}]}";
    route(priv,"(telegram:policy 1 () True (7) (8))","19.0","routed","edited_message",19,0,8,"wake-peer");
    route(priv,policy,"19.0","unauthorized","edited_message",19,0,8,"wake-peer");
    const char *callback="{\"ok\":true,\"result\":[{\"update_id\":30,\"callback_query\":{\"from\":{\"id\":8},\"message\":{\"chat\":{\"id\":42,\"type\":\"private\"},\"from\":{\"id\":7}}}}]}";
    route(callback,policy,"42.0","routed","callback_query",42,0,8,"wake-peer");
    route("{\"ok\":true,\"result\":[{\"update_id\":31,\"channel_post\":{\"chat\":{\"id\":-100,\"type\":\"channel\"}}}]}",
        policy,"-100.0","routed","channel_post",-100,0,0,"ordinary");
    const char *bad[]={
        "{\"ok\":true,\"result\":[{\"update_id\":1.0,\"message\":{}}]}",
        "{\"ok\":true,\"result\":[{\"update_id\":1e0,\"message\":{}}]}",
        "{\"ok\":true,\"result\":[{\"update_id\":-1,\"message\":{}}]}",
        "{\"ok\":true,\"result\":[{\"update_id\":9223372036854775807,\"unknown\":{}}]}",
        "{\"ok\":true,\"result\":[{\"message\":{}}]}",
        "{\"ok\":true,\"result\":[{\"update_id\":1,\"message\":{},\"edited_message\":{}}]}",
        "{\"ok\":true,\"result\":[{\"update_id\":1,\"message\":null}]}",
        "{\"ok\":true,\"result\":[{\"update_id\":1,\"message\":{\"chat\":{\"id\":0,\"type\":\"private\"}}}]}",
        "{\"ok\":true,\"result\":[{\"update_id\":1,\"message\":{\"chat\":{\"id\":42,\"type\":\"private\"},\"from\":{\"id\":-7}}}]}",
        "{\"ok\":true,\"result\":[{\"update_id\":1,\"message\":{\"chat\":{\"id\":42,\"type\":\"private\"},\"message_thread_id\":-1}}]}",
        /* A valid first occurrence must not mask a bad later one. */
        "{\"ok\":true,\"result\":[{\"update_id\":1,\"future\":{}},{\"update_id\":2,\"message\":{}}]}"
    };
    for (size_t i=0;i<sizeof(bad)/sizeof(*bad);++i) response(bad[i],"(telegram:hold 1 malformed-update)");
    response("{\"ok\":true,\"result\":[{\"update_id\":1,\"message\":{\"chat\":{\"id\":42,\"id\":19}}}]}","(telegram:hold 1 malformed-json)");
    response("{\"ok\":true,\"result\":[{\"update_id\":01}]}","(telegram:hold 1 malformed-json)");
    response("{\"ok\":false,\"error_code\":429,\"parameters\":{\"retry_after\":0}}","(telegram:hold 1 invalid-retry-delay)");
    response("{\"ok\":false,\"error_code\":429,\"parameters\":{\"retry_after\":86401}}","(telegram:hold 1 invalid-retry-delay)");
    response("{\"ok\":false,\"error_code\":429}","(telegram:hold 1 invalid-retry-delay)");
    /* Unknown or absent optional fields and inline callbacks are retained. */
    EvalOutcome out;
    Atom *batch=items(decode("{\"ok\":true,\"result\":[{\"update_id\":7,\"new_type\":{\"data\":\"kept\"}},{\"update_id\":8},{\"update_id\":9,\"callback_query\":{\"inline_message_id\":\"abc\",\"from\":{\"id\":7}}}]}",policy,&out),3);
    for (size_t i=0;i<3;++i) {
        Atom *a=batch->expr.elems[i]; assert(form(a,"tg:item",5));
        assert(text(a->expr.elems[2],"unsupported") && atom_is_symbol(a->expr.elems[3],"unsupported"));
        assert(form(a->expr.elems[4],"JsonObjectV1",2)); ++checks;
    }
    eval_outcome_free(&out);
    /* Source spans, object order and array placement must not change dedupe.
     * NUL and non-BMP characters survive in canonical scalar strings. */
    Atom *original=items(decode(group,policy,&out),1)->expr.elems[0];
    unsigned char *encoded=NULL; size_t encoded_size=0;
    assert(cetta_durable_value_encode(original,&encoded,&encoded_size)==DURABLE_OK);
    eval_outcome_free(&out);
    const char *reordered=" {\"result\":[{\"future\":true,\"update_id\":9},{\"message\":{\"text\":\"a\\u0000b \\ud83d\\ude00\",\"from\":{\"id\":7},\"message_thread_id\":12,\"chat\":{\"type\":\"supergroup\",\"id\":-100}},\"update_id\":10}],\"ok\":true}";
    Atom *again=items(decode(reordered,policy,&out),2)->expr.elems[1];
    unsigned char *encoded2=NULL; size_t size2=0;
    assert(cetta_durable_value_encode(again,&encoded2,&size2)==DURABLE_OK);
    assert(size2==encoded_size && !memcmp(encoded,encoded2,size2)); ++checks;
    free(encoded); free(encoded2); eval_outcome_free(&out);
    /* External text/keys/numeric lexemes never become permanent symbols. */
    decode("{\"ok\":true,\"result\":[{\"update_id\":99,\"future\":{\"warm\":\"up\"}}]}",policy,&out); eval_outcome_free(&out);
    uint32_t before=atomic_load(&symbols.entry_len);
    for (unsigned i=0;i<30;++i) {
        char body[256]; snprintf(body,sizeof(body),"{\"ok\":true,\"result\":[{\"update_id\":%u,\"future-%u\":{\"key-%u\":\"text-%u\"}}]}",100+i,i,i,i);
        items(decode(body,policy,&out),1); eval_outcome_free(&out);
    }
    assert(atomic_load(&symbols.entry_len)==before); ++checks;
    /* Bound the provider document and policy walk. Oversized input is held,
     * never truncated into a smaller successful batch. */
    char *large=malloc(262146); assert(large); memset(large,' ',262145); large[262145]=0;
    response(large,"(telegram:hold 1 body-limit)"); free(large);
    char many[10000]; size_t used=(size_t)snprintf(many,sizeof(many),"{\"ok\":true,\"result\":[");
    for (unsigned i=0;i<101;++i) used+=(size_t)snprintf(many+used,sizeof(many)-used,"%s{\"update_id\":%u}",i?",":"",i);
    strcpy(many+used,"]}"); response(many,"(telegram:hold 1 batch-limit)");
    char deep[300]; memset(deep,'[',65); deep[65]='0'; memset(deep+66,']',65); deep[131]=0;
    response(deep,"(telegram:hold 1 malformed-json)");
    used=(size_t)snprintf(many,sizeof(many),"{");
    for (unsigned i=0;i<257;++i) used+=(size_t)snprintf(many+used,sizeof(many)-used,"%s\"k%u\":0",i?",":"",i);
    strcpy(many+used,"}"); response(many,"(telegram:hold 1 malformed-json)");
    many[0]='['; used=1;
    for (unsigned i=0;i<4097;++i) { if(i) many[used++]=','; many[used++]='0'; }
    strcpy(many+used,"]"); response(many,"(telegram:hold 1 malformed-json)");
    long_message();
    used=(size_t)snprintf(many,sizeof(many),"{\"ok\":true,\"result\":[");
    for (unsigned i=0;i<100;++i) used+=(size_t)snprintf(many+used,sizeof(many)-used,"%s{\"update_id\":%u}",i?",":"",i);
    strcpy(many+used,"]}");
    clock_t start=clock(); items(decode(many,policy,&out),100);
    printf("100-update batch: %.3f CPU s, %llu evaluator steps\n",
        (double)(clock()-start)/CLOCKS_PER_SEC,(unsigned long long)out.steps_spent);
    eval_outcome_free(&out); ++checks;
    /* A budget-exhausted classification cannot be mistaken for success. */
    Atom *args[]={atom_symbol(&persistent,"telegram:decode"),atom_string(&persistent,group),parse(policy)};
    eval_outcome_init(&out);
    eval_top_speculative(&context,&program,&scratch,&persistent,&registry,atom_expr(&persistent,args,3),30,&out);
    assert(out.completion==CETTA_EVAL_INCOMPLETE_FUEL && out.steps_spent==30 && !out.effect_denials);
    eval_outcome_free(&out); ++checks;
    intake_checks(group,policy);
cleanup:
    eval_set_library_context(NULL); cetta_library_context_free(&context);
    registry_free(&registry); space_free(&program); arena_free(&scratch); arena_free(&persistent);
    g_var_intern=NULL; var_intern_free(&vars); g_symbols=NULL; symbol_table_free(&symbols);
    printf("Telegram pure policy: %u checks passed\n",checks); return 0;
}
