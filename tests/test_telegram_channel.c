#define _POSIX_C_SOURCE 200809L
#include "telegram_agent.h"
#include "durable_inbox.h"
#include "durable_worker_host.h"
#include "durable_value.h"
#include "cetta_stdlib.h"
#include "library.h"
#include "parser.h"
#include "symbol.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static Arena persistent,scratch;
static Space program;
static Registry registry;
static CettaLibraryContext context;
static CettaDurableStore *store;
static CettaHostProgram trusted={"telegram-channel/1",&program,&context};
static const int64_t chats[]={42,84};
static CettaTelegramActionPolicy actions={chats,2,7};
static CettaTelegramAgent agent={&trusted,"bot","brain",&actions,2000000};
static unsigned policy_checks;
static Atom *parse(const char *s) { size_t p=0; Atom *a=parse_sexpr(&persistent,s,&p); assert(a && p==strlen(s)); return a; }
static Atom *record(const char *space,const char *key) {
    CettaDurableScope q={DURABLE_KEY,space,key}; CettaDurableObservation *o=NULL;
    assert(cetta_durable_observe(store,&q,1,&o)==DURABLE_OK);
    const CettaDurableSnapshot *v=cetta_durable_observation_view(o,0); Atom *a=NULL;
    if (v->count) assert(cetta_durable_value_decode(&persistent,v->records[0].data,v->records[0].size,&a)==DURABLE_OK);
    cetta_durable_observation_free(o); return a;
}
static size_t count(const char *space) { CettaDurableSnapshot v; assert(cetta_durable_snapshot(store,space,&v)==DURABLE_OK); size_t n=v.count; cetta_durable_snapshot_free(&v); return n; }
static void put(const char *space,const char *key,Atom *value) {
    CettaDurableScope q={DURABLE_KEY,space,key}; CettaDurableObservation *o=NULL;
    assert(cetta_durable_observe(store,&q,1,&o)==DURABLE_OK);
    unsigned char *b; size_t n; int64_t rev; assert(cetta_durable_value_encode(value,&b,&n)==DURABLE_OK);
    CettaDurableOp op={cetta_durable_observation_view(o,0)->count?DURABLE_REPLACE:DURABLE_INSERT,space,key,b,n};
    assert(cetta_durable_commit_observed(store,o,&op,1,&rev)==DURABLE_OK); free(b); cetta_durable_observation_free(o);
}
static void incoming(int id,int chat,char key[168]) {
    CettaInboxWindow *w=NULL; assert(cetta_inbox_begin(store,"bot",&w)==DURABLE_OK);
    char lane[32],value[128],ledger[96]; snprintf(lane,sizeof(lane),"%d.0",chat);
    snprintf(value,sizeof(value),"(telegram:input 1 \"message\" %d 0 7 ordinary (JsonObjectV1 ()))",chat);
    CettaInboxItem item={id,lane,INBOX_ROUTED,parse(value)}; CettaInboxCommit c;
    assert(cetta_inbox_commit(w,&item,1,&c)==DURABLE_OK && c.inserted==1); cetta_inbox_window_free(w);
    assert(cetta_inbox_keys("bot",lane,id,ledger,key)==DURABLE_OK);
}
static CettaHostDecision *decide(const char *key,size_t results) {
    CettaHostDecision *d=NULL; CettaDurableStatus s=cetta_telegram_agent_decide(store,&agent,key,&d);
    if (s!=DURABLE_OK) { fprintf(stderr,"decide %s: %s\n",key,cetta_durable_status_name(s)); abort(); }
    const EvalOutcome *o=cetta_host_outcome(d);
    bool blocked=!results && o->results.len==1 && atom_is_symbol(o->results.items[0],"Empty");
    if (o->completion!=CETTA_EVAL_COMPLETE || o->effect_denials || (o->results.len!=results && !blocked)) {
        fprintf(stderr,"decide %s: completion=%d denials=%llu results=%llu expected=%zu\n",key,o->completion,
            (unsigned long long)o->effect_denials,(unsigned long long)o->results.len,results);
        for (CettaCount i=0;i<o->results.len;++i) { atom_print(o->results.items[i],stderr); fputc('\n',stderr); } abort();
    }
    if (blocked) { CettaHostCommit c; assert(cetta_host_accept(d,0,&c)==DURABLE_INVALID); }
    return d;
}
static void accept(CettaHostDecision *d,size_t effects,char key[64]) {
    CettaHostCommit c; CettaDurableStatus s=cetta_host_accept(d,0,&c);
    if (s!=DURABLE_OK) { fprintf(stderr,"accept: %s\n",cetta_durable_status_name(s)); atom_print(cetta_host_outcome(d)->results.items[0],stderr); abort(); }
    assert(c.effects==effects); if (key) snprintf(key,64,"%s/0",c.commit_key); cetta_host_decision_free(d);
}
static void result(const char *id,const char *body,char input[140]) {
    char task[130]; snprintf(task,sizeof(task),"brain/%s",id); snprintf(input,140,"worker/%s",task);
    CettaDurableScope q={DURABLE_KEY,"host.worker-tasks",task}; CettaDurableObservation *o=NULL;
    assert(cetta_durable_observe(store,&q,1,&o)==DURABLE_OK);
    const CettaDurableRecord *r=cetta_durable_observation_view(o,0)->records;
    Atom *parts[]={atom_symbol(&persistent,"host:worker-result"),atom_int(&persistent,1),atom_string(&persistent,"brain"),
        atom_string(&persistent,id),atom_int(&persistent,r->revision),atom_string(&persistent,body)};
    put("host.inbox",input,atom_expr(&persistent,parts,6)); cetta_durable_observation_free(o);
}
static void completed(const char *key,const char *kind,const char *body,char input[140]) {
    snprintf(input,140,"effect/%s",key);
    Atom *out[]={atom_symbol(&persistent,"host:outcome"),atom_int(&persistent,1),atom_string(&persistent,key),
        atom_string(&persistent,"attempt"),atom_symbol(&persistent,kind),parse("(True False 0 200 True 100 False False False)"),atom_string(&persistent,body)};
    Atom *in[]={atom_symbol(&persistent,"host:completion"),atom_int(&persistent,1),atom_string(&persistent,key),atom_string(&persistent,key)};
    put("host.outcomes",key,atom_expr(&persistent,out,7)); put("host.inbox",input,atom_expr(&persistent,in,4));
}
static void admission(const char *key,CettaTelegramAdmission expected) {
    CettaTelegramAdmission value; CettaDurableWatch *w=NULL;
    CettaDurableStatus s=cetta_telegram_agent_admit(store,&agent,key,1024*1024,&value,&w);
    if (s!=DURABLE_OK || value!=expected) {
        fprintf(stderr,"admission %s: status %s value %d expected %d\nintent: ",key,cetta_durable_status_name(s),(int)value,(int)expected);
        Atom *i=record("host.outbox",key); if (i) atom_print(i,stderr); fputc('\n',stderr); abort();
    }
    if (w) assert(cetta_durable_watch_current(store,w)==DURABLE_OK);
    cetta_durable_watch_free(w);
}
static void pure(Atom *expression,const char *expected) {
    EvalOutcome o; eval_outcome_init(&o);
    eval_top_speculative(&context,&program,&scratch,&persistent,&registry,expression,2000000,&o);
    if (o.completion!=CETTA_EVAL_COMPLETE || o.effect_denials || o.results.len!=1 ||
        !atom_eq(o.results.items[0],parse(expected))) {
        fprintf(stderr,"policy expected %s for ",expected); atom_print(expression,stderr); fputc('\n',stderr);
        for (CettaCount i=0;i<o.results.len;++i) { atom_print(o.results.items[i],stderr); fputc('\n',stderr); }
        abort();
    }
    ++policy_checks; eval_outcome_free(&o);
}
static void blocked(const char *key) { CettaHostDecision *d=decide(key,0); cetta_host_decision_free(d); }
static void submitted(const char *key,const char *body,char input[180]) {
    Atom *parts[]={atom_symbol(&persistent,"host:worker-submission"),atom_int(&persistent,1),
        atom_string(&persistent,"brain"),atom_string(&persistent,key),atom_string(&persistent,body)};
    Atom *value=atom_expr(&persistent,parts,5); char ledger[160];
    snprintf(ledger,sizeof(ledger),"brain/%s",key); snprintf(input,180,"submission/brain/%s",key);
    put("host.worker-submissions",ledger,value); put("host.inbox",input,value);
}
/* Accept and return the commit key, whose effects are KEY/0, KEY/1, ... */
static void accept_batch(CettaHostDecision *d,size_t effects,char commit[33]) {
    CettaHostCommit c; CettaDurableStatus s=cetta_host_accept(d,0,&c);
    if (s!=DURABLE_OK) { fprintf(stderr,"accept: %s\n",cetta_durable_status_name(s)); atom_print(cetta_host_outcome(d)->results.items[0],stderr); abort(); }
    assert(c.effects==effects); memcpy(commit,c.commit_key,33); cetta_host_decision_free(d);
}
static void lane(const char *name,const char *expected) {
    char key[64]; snprintf(key,sizeof(key),"telegram/bot/%s",name); Atom *v=record("host.actors",key);
    if (!v || v->kind!=ATOM_EXPR || v->expr.len!=4 || !atom_eq(v->expr.elems[3],parse(expected))) {
        fprintf(stderr,"lane %s: ",name); if (v) atom_print(v,stderr); fprintf(stderr,"\nexpected: %s\n",expected); abort();
    }
}
/* Publish an accepted worker.request and check its exact observation text. */
static void published(const char *request,const char *expected,char task[65]) {
    admission(request,TELEGRAM_WORKER);
    assert(cetta_worker_register(store,request,"brain",task)==DURABLE_OK);
    char key[140]; snprintf(key,sizeof(key),"brain/%s",task); Atom *v=record("host.worker-tasks",key);
    if (!v || v->kind!=ATOM_GROUNDED || v->ground.gkind!=GV_STRING || strcmp(v->ground.sval,expected)) {
        fprintf(stderr,"observation: "); if (v) atom_print(v,stderr); fprintf(stderr,"\nexpected: %s\n",expected); abort();
    }
}
static void decided(const char *key,const char *expected) {
    Atom *v=record("telegram.decisions",key);
    if (!v || !atom_eq(v,parse(expected))) { fprintf(stderr,"decision %s: ",key); if (v) atom_print(v,stderr); fprintf(stderr,"\nexpected %s\n",expected); abort(); }
}
static void control_request(const char *id,const char *lane,const char *batch,char key[80]) {
    Atom *args[]={atom_symbol(&persistent,"host:telegram-control"),atom_int(&persistent,1),
        atom_string(&persistent,"bot"),atom_string(&persistent,id),atom_string(&persistent,lane),
        atom_string(&persistent,"release-worker"),atom_string(&persistent,batch)};
    Atom *request=atom_expr(&persistent,args,7);
    snprintf(key,80,"control/%s",id);
    put("telegram.controls",id,request); put("host.inbox",key,request);
}
static const char *ok_message="{\"ok\":true,\"result\":{\"message_id\":9,\"chat\":{\"id\":42}}}";

int main(int argc,char **argv) {
    (void)argc;
    SymbolTable symbols; symbol_table_init(&symbols); symbol_table_init_builtins(&symbols,&g_builtin_syms); g_symbols=&symbols;
    VarInternTable vars; var_intern_init(&vars); g_var_intern=&vars;
    arena_init(&persistent); arena_init(&scratch); space_init(&program); registry_init(&registry);
    registry_bind(&registry,"&self",atom_space(&persistent,&program));
    cetta_library_context_init(&context); cetta_library_context_set_exec_path(&context,argv[0]);
    cetta_eval_session_init_he_extended(&context.session); eval_set_library_context(&context); stdlib_load(&program,&persistent);
    Atom *error=NULL;
    if (!cetta_library_import_module(&context,"durable:telegram_channel",&program,false,&scratch,&persistent,&registry,1000000,&error)) {
        if (error) atom_print(error,stderr);
        abort();
    }
    pure(parse("(tg-channel:result-json (tg-agent:delivered 9))"),"\"[\\\"delivered\\\",9]\"");
    pure(parse("(tg-channel:result-json (tg-agent:failed 400))"),"\"[\\\"failed\\\",400]\"");
    pure(parse("(tg-channel:result-json (tg-agent:not-sent))"),"\"[\\\"not-sent\\\"]\"");
    pure(parse("(tg-channel:result-json (tg-agent:uncertain transport))"),"\"[\\\"uncertain\\\",\\\"transport\\\"]\"");
    pure(parse("(tg-channel:advances (tg-agent:failed 400))"),"True");
    pure(parse("(tg-channel:advances (tg-agent:not-sent))"),"True");
    pure(parse("(tg-channel:advances (tg-agent:uncertain http-status))"),"False");
    const char *send="(telegram:send-text 1 42 0 0 \"x\" \"plain\")";
    char check[512];
    /* Refused connection, nothing issued: provably not sent. */
    snprintf(check,sizeof(check),"(tg-channel:classify (host:outcome 1 \"e\" \"a\" uncertain (True False 7 0 True 0 False False False) \"\") %s)",send);
    pure(parse(check),"(tg-agent:not-sent)");
    snprintf(check,sizeof(check),"(tg-channel:classify (host:outcome 1 \"e\" \"a\" uncertain (True False 35 0 True 0 False False False) \"\") %s)",send);
    pure(parse(check),"(tg-agent:not-sent)");
    /* Request bytes issued, or a timeout, or an unknown size: uncertain. */
    snprintf(check,sizeof(check),"(tg-channel:classify (host:outcome 1 \"e\" \"a\" uncertain (True False 7 0 True 120 False False False) \"\") %s)",send);
    pure(parse(check),"(tg-agent:uncertain transport)");
    snprintf(check,sizeof(check),"(tg-channel:classify (host:outcome 1 \"e\" \"a\" uncertain (True False 28 0 True 0 False False False) \"\") %s)",send);
    pure(parse(check),"(tg-agent:uncertain transport)");
    snprintf(check,sizeof(check),"(tg-channel:classify (host:outcome 1 \"e\" \"a\" uncertain (True False 7 0 False 0 False False False) \"\") %s)",send);
    pure(parse(check),"(tg-agent:uncertain transport)");
    char dir[]="/tmp/cetta-telegram-channel-XXXXXX"; assert(mkdtemp(dir));
    char db[256]; snprintf(db,sizeof(db),"%s/state.db",dir); assert(cetta_durable_open(db,NULL,&store)==DURABLE_OK);
    char input[168],request[64],task[65],worker_input[140],commit[33],sub[180],sub2[180],sub3[180],effect[140],key[64],receipt[65];

    /* Reading a chat never touches its sending actor or waits for cognition. */
    incoming(1,42,input); accept(decide(input,1),1,request);
    assert(!record("host.actors","telegram/bot/42.0") && !record("host.inbox",input));
    published(request,"[\"input\",\"42.0\",\"message\",\"ordinary\",{}]",task);
    char input2[168],request2[64],task2[65];
    incoming(2,42,input2); accept(decide(input2,1),1,request2);
    published(request2,"[\"input\",\"42.0\",\"message\",\"ordinary\",{}]",task2);
    assert(strcmp(task,task2));
    /* An answer only acknowledges its task; it can never act. */
    size_t outbox=count("host.outbox");
    result(task,"[]",worker_input); accept(decide(worker_input,1),0,NULL);
    result(task2,"[[\"send\",\"ignored\",\"plain\"]]",worker_input); accept(decide(worker_input,1),0,NULL);
    assert(count("host.outbox")==outbox && !record("host.inbox",worker_input));

    /* A keyed submission is accepted into its lane's sending state machine. */
    submitted("42.0.00000000000000000001","[[\"send\",\"hello\",\"plain\"],[\"send\",\"second\",\"plain\"]]",sub);
    accept_batch(decide(sub,1),2,commit);
    lane("42.0","(tg-agent:sending \"42.0.00000000000000000001\" 0 2)");
    decided("42.0.00000000000000000001","(tg-channel:decision 1 accepted 2)");
    snprintf(key,sizeof(key),"%s/0",commit); admission(key,TELEGRAM_SEND);
    char second[64]; snprintf(second,sizeof(second),"%s/1",commit); admission(second,TELEGRAM_WAIT);
    /* Submissions to one lane are accepted strictly in key order. */
    submitted("42.0.00000000000000000003","[[\"send\",\"fourth\",\"plain\"]]",sub3);
    submitted("42.0.00000000000000000002","[[\"send\",\"third\",\"plain\"]]",sub2);
    blocked(sub3); blocked(sub2);
    /* Delivery reports back and advances the batch. */
    completed(key,"observed",ok_message,effect); accept_batch(decide(effect,1),1,commit);
    lane("42.0","(tg-agent:sending \"42.0.00000000000000000001\" 1 2)");
    char receipt_request[64]; snprintf(receipt_request,sizeof(receipt_request),"%s/0",commit);
    published(receipt_request,"[\"delivery\",\"42.0.00000000000000000001\",0,2,[\"delivered\",9]]",receipt);
    admission(second,TELEGRAM_SEND);
    /* A definitive API failure is reported and does not wedge the chat. */
    completed(second,"observed","{\"ok\":false,\"error_code\":400,\"description\":\"Bad Request\"}",effect);
    accept_batch(decide(effect,1),1,commit); lane("42.0","(tg-agent:idle)");
    snprintf(receipt_request,sizeof(receipt_request),"%s/0",commit);
    published(receipt_request,"[\"delivery\",\"42.0.00000000000000000001\",1,2,[\"failed\",400]]",receipt);
    blocked(sub3); accept_batch(decide(sub2,1),1,commit);
    lane("42.0","(tg-agent:sending \"42.0.00000000000000000002\" 0 1)");
    /* Uncertain delivery holds the lane: nothing may overtake it. */
    snprintf(key,sizeof(key),"%s/0",commit);
    completed(key,"observed","not json",effect); accept_batch(decide(effect,1),1,commit);
    lane("42.0","(tg-agent:held \"42.0.00000000000000000002\" 0 1 (tg-agent:uncertain malformed-api-result))");
    snprintf(receipt_request,sizeof(receipt_request),"%s/0",commit);
    published(receipt_request,"[\"delivery\",\"42.0.00000000000000000002\",0,1,[\"uncertain\",\"malformed-api-result\"]]",receipt);
    blocked(sub3);
    /* The operator releases the lane: the uncertain action stays uncertain,
     * the client is told which one, and the next submission proceeds. */
    char control[80];
    control_request("wrong-batch","42.0","42.0.00000000000000000099",control);
    accept_batch(decide(control,1),0,commit);
    assert(atom_is_symbol(record("telegram.control-results","wrong-batch")->expr.elems[2],"refused"));
    lane("42.0","(tg-agent:held \"42.0.00000000000000000002\" 0 1 (tg-agent:uncertain malformed-api-result))");
    control_request("release-1","42.0","42.0.00000000000000000002",control);
    accept_batch(decide(control,1),1,commit); lane("42.0","(tg-agent:idle)");
    assert(atom_is_symbol(record("telegram.control-results","release-1")->expr.elems[2],"released"));
    snprintf(receipt_request,sizeof(receipt_request),"%s/0",commit);
    published(receipt_request,"[\"released\",\"42.0\",\"42.0.00000000000000000002\",0]",receipt);
    control_request("release-1","42.0","42.0.00000000000000000002",control); blocked(control);
    accept_batch(decide(sub3,1),1,commit); lane("42.0","(tg-agent:sending \"42.0.00000000000000000003\" 0 1)");

    /* A chat outside the native policy is rejected with a receipt. */
    submitted("99.0.00000000000000000001","[[\"send\",\"x\",\"plain\"]]",sub);
    accept_batch(decide(sub,1),1,commit);
    decided("99.0.00000000000000000001","(tg-channel:decision 1 rejected action-not-permitted)");
    snprintf(receipt_request,sizeof(receipt_request),"%s/0",commit);
    published(receipt_request,"[\"rejected\",\"99.0.00000000000000000001\",\"action-not-permitted\"]",receipt);
    /* A key that names no lane, and a body that is not a command batch. */
    submitted("no-lane","[]",sub); accept_batch(decide(sub,1),1,commit);
    decided("no-lane","(tg-channel:decision 1 rejected malformed-key)");
    submitted("84.0.00000000000000000001","{\"not\":\"a batch\"}",sub); accept_batch(decide(sub,1),1,commit);
    decided("84.0.00000000000000000001","(tg-channel:decision 1 rejected invalid-command-batch)");
    lane("84.0","(tg-agent:idle)");
    /* An empty batch is accepted and leaves the lane idle. */
    submitted("84.0.00000000000000000002","[]",sub); accept_batch(decide(sub,1),0,commit);
    decided("84.0.00000000000000000002","(tg-channel:decision 1 accepted 0)"); lane("84.0","(tg-agent:idle)");
    /* A lane actor written by another program version is never reinterpreted. */
    put("host.actors","telegram/bot/84.0",parse("(host:actor 1 \"telegram-agent/1\" (tg-agent:idle))"));
    submitted("84.0.00000000000000000003","[[\"send\",\"x\",\"plain\"]]",sub); blocked(sub);
    /* Committed work survives a reopen. */
    cetta_durable_close(store); assert(cetta_durable_open(db,NULL,&store)==DURABLE_OK);
    lane("42.0","(tg-agent:sending \"42.0.00000000000000000003\" 0 1)");
    printf("Telegram channel: %u pure policy checks; deliveries without waiting, acknowledgment-only answers, keyed submissions, lane order, receipts, definitive failure progress, held uncertainty, operator release and rejections passed\n",policy_checks);
    cetta_durable_close(store); unlink(db); char path[300]; snprintf(path,sizeof(path),"%s-wal",db); unlink(path); snprintf(path,sizeof(path),"%s-shm",db); unlink(path); rmdir(dir);
    cetta_library_context_free(&context); eval_set_library_context(NULL); registry_free(&registry); space_free(&program);
    arena_free(&scratch); arena_free(&persistent); var_intern_free(&vars); symbol_table_free(&symbols); g_symbols=NULL; g_var_intern=NULL;
}
