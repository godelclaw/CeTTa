#define _POSIX_C_SOURCE 200809L
#include "durable_store.h"
#include <sqlite3.h>
#include <assert.h>
#include <signal.h>
#include <stdbool.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static const char *crash_at;
void cetta_durable_test_boundary(const char *boundary) {
    if (crash_at && !strcmp(crash_at, boundary)) kill(getpid(), SIGKILL);
}

static void check(CettaDurableStatus actual, CettaDurableStatus expected) {
    if (actual != expected) {
        fprintf(stderr, "expected %s, got %s\n", cetta_durable_status_name(expected),
                cetta_durable_status_name(actual)); abort();
    }
}

static CettaDurableStore *open_store(const char *path, CettaDurableLimits *limits) {
    CettaDurableStore *s = NULL;
    check(cetta_durable_open(path, limits, &s), DURABLE_OK); return s;
}

static CettaDurableSnapshot snapshot(CettaDurableStore *s) {
    CettaDurableSnapshot v;
    check(cetta_durable_snapshot(s, NULL, &v), DURABLE_OK); return v;
}

static CettaDurableOp put(CettaDurableOpKind kind, const char *space,
        const char *key, const char *value) {
    return (CettaDurableOp){kind,space,key,value,value ? strlen(value) : 0};
}

static int64_t commit(CettaDurableStore *s, CettaDurableOp *ops, size_t n) {
    CettaDurableSnapshot v = snapshot(s); int64_t next = -1;
    check(cetta_durable_commit(s, v.epoch, v.revision, ops, n, &next), DURABLE_OK);
    assert(next == v.revision + 1);
    cetta_durable_snapshot_free(&v); return next;
}

static const CettaDurableRecord *record(CettaDurableSnapshot *v,
        const char *space, const char *key) {
    for (size_t i=0; i<v->count; ++i)
        if (!strcmp(v->records[i].space,space) && !strcmp(v->records[i].key,key)) return &v->records[i];
    return NULL;
}

static void value(CettaDurableSnapshot *v, const char *space, const char *key, const char *text) {
    const CettaDurableRecord *r = record(v, space, key);
    assert(r && r->size == strlen(text) && !memcmp(r->data,text,r->size));
}

static void replay_equal(CettaDurableStore *s) {
    CettaDurableSnapshot a = snapshot(s), b;
    check(cetta_durable_recover(s,&b), DURABLE_OK);
    assert(!strcmp(a.epoch,b.epoch) && a.revision==b.revision && a.count==b.count);
    for (size_t i=0; i<a.count; ++i) {
        CettaDurableRecord *x=&a.records[i];
        const CettaDurableRecord *y=record(&b,x->space,x->key);
        assert(y && x->revision==y->revision && x->position==y->position);
        assert(x->size==y->size && !memcmp(x->data,y->data,x->size));
    }
    cetta_durable_snapshot_free(&a); cetta_durable_snapshot_free(&b);
}

static void basic(const char *path) {
    CettaDurableStore *s = open_store(path,NULL), *other = NULL;
    check(cetta_durable_open(path,NULL,&other), DURABLE_BUSY);
    assert(!other);
    CettaDurableOp init[] = {put(DURABLE_INSERT,"inbox","update:1","hello"),
        put(DURABLE_INSERT,"state","worker","waiting")};
    commit(s,init,2);
    CettaDurableSnapshot before = snapshot(s);
    CettaDurableOp transition[] = {put(DURABLE_REMOVE,"inbox","update:1",NULL),
        put(DURABLE_REPLACE,"state","worker","continuation:2"),
        put(DURABLE_INSERT,"outbox","send:1","accepted")};
    int64_t next;
    check(cetta_durable_commit(s,before.epoch,before.revision,transition,3,&next),DURABLE_OK);
    assert(next==2);
    value(&before,"state","worker","waiting"); /* no premature publication */
    /* A read of absence in another named space still conflicts. */
    CettaDurableOp stale=put(DURABLE_INSERT,"reminders","r","duplicate");
    check(cetta_durable_commit(s,before.epoch,before.revision,&stale,1,&next),DURABLE_CONFLICT);
    assert(next==-1);
    CettaDurableSnapshot now=snapshot(s);
    assert(!record(&now,"inbox","update:1"));
    value(&now,"state","worker","continuation:2"); value(&now,"outbox","send:1","accepted");
    /* Late precondition failure rolls back earlier writes and log entries. */
    CettaDurableOp bad[]={put(DURABLE_REPLACE,"state","worker","must-not-appear"),
        put(DURABLE_REMOVE,"inbox","missing",NULL)};
    check(cetta_durable_commit(s,now.epoch,now.revision,bad,2,&next),DURABLE_PRECONDITION);
    assert(next==-1);
    CettaDurableOp duplicate[]={put(DURABLE_REPLACE,"state","worker","first"),
        put(DURABLE_REPLACE,"state","worker","second")};
    check(cetta_durable_commit(s,now.epoch,now.revision,duplicate,2,&next),DURABLE_PRECONDITION);
    assert(next==-1);
    check(cetta_durable_commit(s,"00000000000000000000000000000000",now.revision,&stale,1,&next),DURABLE_CONFLICT);
    replay_equal(s);
    check(cetta_durable_checkpoint(s),DURABLE_OK);
    replay_equal(s);
    CettaDurableOp delta[]={put(DURABLE_REMOVE,"outbox","send:1",NULL),
        put(DURABLE_INSERT,"outbox","send:2","uncertain"),
        put(DURABLE_INSERT,"outbox","send:3","uncertain")};
    commit(s,delta,3); replay_equal(s); /* identical values retain two occurrences */
    cetta_durable_close(s);
    s=open_store(path,NULL); replay_equal(s);
    CettaDurableSnapshot reopened=snapshot(s);
    assert(!strcmp(reopened.epoch,now.epoch) && reopened.revision==3 && reopened.count==3);
    value(&reopened,"state","worker","continuation:2");
    value(&reopened,"outbox","send:2","uncertain");
    cetta_durable_snapshot_free(&before); cetta_durable_snapshot_free(&now);
    cetta_durable_snapshot_free(&reopened); cetta_durable_close(s);
}

static void crashes(const char *path) {
    const char *boundaries[]={"operation","before_commit","after_commit","checkpoint"};
    for (size_t i=0; i<4; ++i) {
        CettaDurableStore *s=open_store(path,NULL);
        char id[32]; snprintf(id,sizeof(id),"crash:%zu",i);
        CettaDurableOp initial=put(DURABLE_INSERT,"inbox",id,"pending");
        commit(s,&initial,1);
        CettaDurableSnapshot old=snapshot(s);
        cetta_durable_close(s);
        pid_t pid=fork(); assert(pid>=0);
        if (!pid) {
            s=open_store(path,NULL); crash_at=boundaries[i];
            if (i==3) cetta_durable_checkpoint(s);
            else {
                CettaDurableOp ops[]={put(DURABLE_REMOVE,"inbox",id,NULL),
                    put(DURABLE_INSERT,"outbox",id,"accepted")};
                int64_t next;
                cetta_durable_commit(s,old.epoch,old.revision,ops,2,&next);
            }
            _exit(90); /* the injected crash must have fired */
        }
        int w; assert(waitpid(pid,&w,0)==pid && WIFSIGNALED(w) && WTERMSIG(w)==SIGKILL);
        s=open_store(path,NULL); CettaDurableSnapshot now=snapshot(s);
        bool committed=i==2;
        assert(now.revision==old.revision+(committed?1:0));
        assert((record(&now,"inbox",id)!=NULL)==!committed);
        assert((record(&now,"outbox",id)!=NULL)==committed);
        replay_equal(s); cetta_durable_close(s);
        cetta_durable_snapshot_free(&old); cetta_durable_snapshot_free(&now);
    }
}

static void limits(const char *path) {
    CettaDurableLimits l=cetta_durable_default_limits();
    l.record_bytes=128; l.batch_bytes=256; l.live_bytes=256; l.history_bytes=256; l.records=2;
    CettaDurableStore *s=open_store(path,&l);
    CettaDurableOp op=put(DURABLE_INSERT,"outbox","one","unresolved");
    commit(s,&op,1);
    for (int i=0;i<100;++i) {
        op=put(DURABLE_REPLACE,"outbox","one",i%2?"uncertain":"accepted");
        commit(s,&op,1); replay_equal(s); /* automatic history compaction */
    }
    CettaDurableSnapshot old=snapshot(s);
    CettaDurableOp overflow[]={put(DURABLE_INSERT,"outbox","two","accepted"),
        put(DURABLE_INSERT,"outbox","three","accepted")};
    int64_t next;
    check(cetta_durable_commit(s,old.epoch,old.revision,overflow,2,&next),DURABLE_LIMIT);
    assert(next==-1); replay_equal(s);
    CettaDurableSnapshot now=snapshot(s);
    assert(now.count==1 && now.revision==old.revision);
    cetta_durable_snapshot_free(&old); cetta_durable_snapshot_free(&now); cetta_durable_close(s);
}

static void disk_full(const char *path) {
    CettaDurableLimits l=cetta_durable_default_limits(); l.database_pages=64;
    CettaDurableStore *s=open_store(path,&l);
    CettaDurableOp first=put(DURABLE_INSERT,"state","s","before"); commit(s,&first,1);
    CettaDurableSnapshot old=snapshot(s);
    size_t n=512*1024; char *large=malloc(n); assert(large); memset(large,'x',n);
    CettaDurableOp ops[]={put(DURABLE_REPLACE,"state","s","after"),
        {DURABLE_INSERT,"outbox","large",large,n}};
    int64_t next;
    check(cetta_durable_commit(s,old.epoch,old.revision,ops,2,&next),DURABLE_LIMIT);
    assert(next==-1); free(large); cetta_durable_close(s);
    s=open_store(path,&l); replay_equal(s); CettaDurableSnapshot now=snapshot(s);
    assert(now.revision==old.revision && now.count==1); value(&now,"state","s","before");
    cetta_durable_snapshot_free(&old); cetta_durable_snapshot_free(&now); cetta_durable_close(s);
}

static void wrong_version(const char *path) {
    sqlite3 *db=NULL; assert(sqlite3_open(path,&db)==SQLITE_OK);
    assert(sqlite3_exec(db,"PRAGMA user_version=999",NULL,NULL,NULL)==SQLITE_OK);
    sqlite3_close(db); CettaDurableStore *s=NULL;
    check(cetta_durable_open(path,NULL,&s),DURABLE_VERSION); assert(!s);
}

static void *increment(void *context) {
    CettaDurableStore *s=context;
    for (int i=0;i<100;) {
        CettaDurableSnapshot v=snapshot(s);
        const CettaDurableRecord *r=record(&v,"state","counter");
        assert(r && r->size==sizeof(uint64_t));
        uint64_t x; memcpy(&x,r->data,sizeof(x)); ++x;
        CettaDurableOp op={DURABLE_REPLACE,"state","counter",&x,sizeof(x)};
        int64_t next;
        CettaDurableStatus result=cetta_durable_commit(s,v.epoch,v.revision,&op,1,&next);
        assert(result==DURABLE_OK || result==DURABLE_CONFLICT);
        if (result==DURABLE_OK) ++i;
        cetta_durable_snapshot_free(&v);
    }
    return NULL;
}

static void concurrent(const char *path) {
    CettaDurableStore *s=open_store(path,NULL); uint64_t zero=0;
    CettaDurableOp op={DURABLE_INSERT,"state","counter",&zero,sizeof(zero)};
    commit(s,&op,1);
    pthread_t workers[4];
    for (int i=0;i<4;++i) assert(!pthread_create(&workers[i],NULL,increment,s));
    for (int i=0;i<4;++i) assert(!pthread_join(workers[i],NULL));
    CettaDurableSnapshot v=snapshot(s);
    uint64_t result; memcpy(&result,record(&v,"state","counter")->data,sizeof(result));
    assert(result==400 && v.revision==401);
    replay_equal(s); cetta_durable_snapshot_free(&v); cetta_durable_close(s);
}

int main(void) {
    char dir[]="/tmp/cetta-durable-test-XXXXXX"; assert(mkdtemp(dir));
    char path[256];
    const char *names[]={"basic","crash","limits","full","version","concurrent"};
    void (*tests[])(const char *)={basic,crashes,limits,disk_full,wrong_version,concurrent};
    for (size_t i=0;i<6;++i) {
        snprintf(path,sizeof(path),"%s/%s.db",dir,names[i]); tests[i](path);
        assert(unlink(path)==0);
        char sidecar[300]; snprintf(sidecar,sizeof(sidecar),"%s-wal",path); unlink(sidecar);
        snprintf(sidecar,sizeof(sidecar),"%s-shm",path); unlink(sidecar);
    }
    assert(rmdir(dir)==0);
    puts("durable store: atomic transitions, conflicts, checkpoint replay, four crash boundaries, disk full, limits, versions, concurrent decisions passed");
    return 0;
}
