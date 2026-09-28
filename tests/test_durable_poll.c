#define _POSIX_C_SOURCE 200809L
#include "durable_dispatch.h"
#include "durable_inbox.h"
#include "durable_value.h"
#include "symbol.h"
#include <assert.h>
#include <fcntl.h>
#include <stdatomic.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static CettaDurableStore *store;
static Arena arena;
static atomic_uint health;
static void degraded(void *context, const char *key, CettaDurableStatus status) {
    (void)context; (void)key; assert(status!=DURABLE_OK); atomic_fetch_add(&health,1);
}
static const char *text(const Atom *a) {
    assert(a && a->kind==ATOM_GROUNDED && a->ground.gkind==GV_STRING); return a->ground.sval;
}
static Atom *response(CettaInboxWindow *w, const char *kind) {
    const CettaDurableRecord *r=cetta_inbox_poll_response(w); assert(r);
    Atom *a=NULL; assert(cetta_durable_value_decode(&arena,r->data,r->size,&a)==DURABLE_OK);
    assert(a->kind==ATOM_EXPR && a->expr.len==7 && atom_is_symbol(a->expr.elems[0],"host:poll"));
    assert(!strcmp(text(a->expr.elems[2]),cetta_inbox_source(w)));
    assert(a->expr.elems[3]->ground.ival==cetta_inbox_offset(w));
    assert(atom_is_symbol(a->expr.elems[4],kind)); return a;
}
static CettaInboxWindow *wait_response(CettaDurableDispatch *d, const char *source) {
    uint64_t generation=0;
    for (unsigned i=0;i<100;++i) {
        CettaInboxWindow *w=NULL;
        CettaDurableStatus s=cetta_inbox_recover_poll(store,source,&w);
        if (s==DURABLE_OK) return w;
        assert(s==DURABLE_PRECONDITION);
        generation=cetta_dispatch_wait(d,generation,100);
    }
    assert(false); return NULL;
}
static CettaDurableStatus start(CettaDurableDispatch *d, const CettaTelegramCredential *c,
                               const char *source, unsigned limit) {
    const char *updates[]={"message","callback_query"};
    CettaTelegramPoll p={c,source,0,limit,updates,2}; return cetta_dispatch_poll(d,&p);
}
static void empty(CettaInboxWindow *w) {
    CettaInboxCommit out; int64_t offset=cetta_inbox_offset(w);
    assert(cetta_inbox_commit(w,NULL,0,&out)==DURABLE_OK && out.next_offset==offset);
    cetta_inbox_window_free(w);
}
/* This fixture classifies an exact known mock response. Production schema,
 * authorization and routing policy belong to the trusted MeTTa program. */
static CettaDurableStatus classify(CettaInboxWindow *w, CettaInboxCommit *out) {
    Atom *a=response(w,"observed");
    assert(!strcmp(text(a->expr.elems[6]),"{\"ok\":true,\"result\":[{\"update_id\":7},{\"update_id\":43}]}"));
    CettaInboxItem items[]={{7,"chat-1",INBOX_ROUTED,atom_string(&arena,"first")},
        {43,"unsupported",INBOX_UNSUPPORTED,atom_string(&arena,"retained")}};
    return cetta_inbox_commit(w,items,2,out);
}
int main(int argc, char **argv) {
    assert(argc==6);
    SymbolTable symbols; symbol_table_init(&symbols); symbol_table_init_builtins(&symbols,&g_builtin_syms); g_symbols=&symbols;
    arena_init(&arena);
    CettaDurableLimits limits=cetta_durable_default_limits(); limits.record_bytes=1024;
    bool pressure=!strcmp(argv[1],"pressure"); if (pressure) limits.records=1;
    assert(cetta_durable_open(argv[2],&limits,&store)==DURABLE_OK);
    int fd=open(argv[3],O_RDONLY); assert(fd>=0);
    CettaTelegramCredentialConfig cc={argv[4],strcmp(argv[5],"-")?argv[5]:NULL,true};
    CettaTelegramCredential *credential=NULL;
    assert(cetta_telegram_credential_read(fd,&cc,&credential)==TELEGRAM_CREDENTIAL_OK); close(fd);
    CettaDispatchConfig config={NULL,0,3000,65536,NULL,degraded};
    CettaDurableDispatch *d=NULL; assert(cetta_dispatch_new(store,&config,&d)==DURABLE_OK);
    CettaInboxWindow *w=NULL; CettaInboxCommit out;
    if (!strcmp(argv[1],"crash")) {
        assert(start(d,credential,"bot",9)==DURABLE_OK);
        for (;;) pause(); /* Mock kills after receiving the request. */
    }
    if (!strcmp(argv[1],"pending")) {
        assert(start(d,credential,"bot",2)==DURABLE_OK);
        w=wait_response(d,"bot"); response(w,"observed");
        _exit(0); /* Poll persisted, no classification and no clean close. */
    }
    if (!strcmp(argv[1],"recover")) {
        assert(start(d,credential,"bot",2)==DURABLE_PRECONDITION);
        w=wait_response(d,"bot");
        assert(classify(w,&out)==DURABLE_OK && out.inserted==2 && out.next_offset==44);
        cetta_inbox_window_free(w);
        assert(start(d,credential,"bot",2)==DURABLE_OK);
        w=wait_response(d,"bot");
        assert(!strcmp(text(response(w,"observed")->expr.elems[6]),"{\"ok\":true,\"result\":[]}")); empty(w);
    } else {
        assert(pressure || !strcmp(argv[1],"normal") || !strcmp(argv[1],"after-crash"));
        CettaTelegramPoll invalid={credential,"bot",3,2,NULL,0};
        assert(cetta_dispatch_poll(d,&invalid)==DURABLE_INVALID);
        invalid.wait_seconds=0; invalid.limit=0;
        assert(cetta_dispatch_poll(d,&invalid)==DURABLE_INVALID);
        const char *bad[]={"message\",\"offset\":999"};
        invalid.limit=2; invalid.allowed_updates=bad; invalid.update_count=1;
        assert(cetta_dispatch_poll(d,&invalid)==DURABLE_INVALID);
        assert(start(d,credential,"bot",2)==DURABLE_OK);
        CettaDurableStatus s=start(d,credential,"bot",2);
        assert(s==DURABLE_BUSY || s==DURABLE_PRECONDITION);
        w=wait_response(d,"bot");
        assert(cetta_inbox_offset(w)==0);
        assert(start(d,credential,"bot",2)==DURABLE_PRECONDITION);
        if (pressure) {
            assert(classify(w,&out)==DURABLE_LIMIT && out.next_offset<0);
            cetta_inbox_window_free(w);
            assert(start(d,credential,"bot",2)==DURABLE_PRECONDITION);
            assert(cetta_dispatch_free(d)==0); d=NULL;
            cetta_durable_close(store);
            assert(cetta_durable_open(argv[2],NULL,&store)==DURABLE_OK);
            assert(cetta_dispatch_new(store,&config,&d)==DURABLE_OK);
            w=wait_response(d,"bot"); assert(cetta_inbox_offset(w)==0);
        }
        assert(classify(w,&out)==DURABLE_OK && out.next_offset==44 && out.inserted==2);
        cetta_inbox_window_free(w);
        assert(start(d,credential,"bot",2)==DURABLE_OK);
        w=wait_response(d,"bot");
        assert(!strcmp(text(response(w,"observed")->expr.elems[6]),"{\"ok\":true,\"result\":[]}")); empty(w);
        if (!strcmp(argv[1],"normal")) {
            const char *sources[]={"reflection","lost","oversize","rate-limit","malformed"};
            const char *kinds[]={"privacy-suppressed","uncertain","unrecordable","observed","observed"};
            for (unsigned i=0;i<5;++i) {
                assert(start(d,credential,sources[i],i+3)==DURABLE_OK);
                w=wait_response(d,sources[i]); assert(cetta_inbox_offset(w)==0);
                Atom *a=response(w,kinds[i]);
                if (i==0 || i==2) assert(!*text(a->expr.elems[6]));
                if (i==3) assert(a->expr.elems[5]->expr.elems[3]->ground.ival==429);
                if (i==4) assert(!strcmp(text(a->expr.elems[6]),"{"));
                assert(start(d,credential,sources[i],2)==DURABLE_PRECONDITION);
                cetta_inbox_window_free(w); /* Retained for policy/repair, not silently discarded. */
            }
            /* An unrelated source can continue despite held failed polls. */
            assert(start(d,credential,"other-bot",2)==DURABLE_OK);
            w=wait_response(d,"other-bot");
            assert(classify(w,&out)==DURABLE_OK && out.next_offset==44); cetta_inbox_window_free(w);
        }
    }
    assert(!atomic_load(&health));
    assert(cetta_dispatch_free(d)==0);
    cetta_durable_close(store); cetta_telegram_credential_free(credential);
    arena_free(&arena); g_symbols=NULL; symbol_table_free(&symbols);
    puts("durable poll: committed offsets, retained screened responses, atomic classification, recovery and isolated faults passed");
}
