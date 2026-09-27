#define _POSIX_C_SOURCE 200809L
#include "http_worker.h"
#include "durable_store.h"
#include <assert.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static uint64_t now_ms(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC,&t);
    return (uint64_t)t.tv_sec*1000+(uint64_t)t.tv_nsec/1000000;
}
static void wait_flag(atomic_uint *value, unsigned target) {
    uint64_t deadline=now_ms()+5000;
    while (atomic_load(value)<target && now_ms()<deadline) {
        struct timespec pause={0,1000000}; nanosleep(&pause,NULL);
    }
    assert(atomic_load(value)>=target);
}
static CettaHttpWorker *worker(const CettaHttpWorkerLimits *limits, const CettaHttpWorkerHooks *hooks) {
    CettaHttpWorker *w=NULL;
    assert(cetta_http_worker_new(limits,hooks,&w)==HTTP_WORKER_OK);
    return w;
}
static CettaHttpRequest request(uint64_t id, const char *url) {
    return (CettaHttpRequest){.id=id,.method="GET",.url=url,.timeout_ms=2000,.max_response_bytes=1024};
}
static CettaHttpResult take(CettaHttpWorker *w) {
    CettaHttpResult r={0}; uint64_t gen=0,deadline=now_ms()+5000;
    while (!cetta_http_worker_take(w,&r)) {
        assert(now_ms()<deadline);
        gen=cetta_http_worker_wait(w,gen,100);
    }
    return r;
}
static void body(CettaHttpResult *r, const void *bytes, size_t n) {
    assert(r->started && !r->cancelled && r->transport_code==0 && r->status==200);
    assert(r->body_size==n && (!n || !memcmp(r->body,bytes,n)));
}
static void url(char *out, const char *base, const char *path) {
    assert(snprintf(out,512,"%s%s",base,path)<512);
}
static void ephemeral(const char *base) {
    CettaHttpWorkerLimits limits=cetta_http_worker_default_limits(); limits.jobs=2;
    CettaHttpWorker *w=worker(&limits,NULL);
    char one[512],two[512]; url(one,base,"/one"); url(two,base,"/two");
    CettaHttpRequest a=request(1,one), b=request(2,two), extra=request(3,one);
    assert(cetta_http_worker_submit(w,&a)==HTTP_WORKER_OK);
    assert(cetta_http_worker_submit(w,&a)==HTTP_WORKER_DUPLICATE);
    assert(cetta_http_worker_submit(w,&b)==HTTP_WORKER_OK);
    assert(cetta_http_worker_submit(w,&extra)==HTTP_WORKER_FULL);
    for (int i=0;i<2;++i) {
        CettaHttpResult r=take(w);
        body(&r,r.id==1?"one":"two",3); cetta_http_result_free(&r);
    }
    CettaHttpResult r; assert(!cetta_http_worker_take(w,&r));
    uint64_t gen=cetta_http_worker_wait(w,0,0), before=now_ms();
    assert(cetta_http_worker_wait(w,gen,30)==gen && now_ms()-before>=25);
    char echo[512]; url(echo,base,"/echo");
    unsigned char bytes[]={0,'a',255,0};
    a=request(4,echo); a.method="POST"; a.body=bytes; a.body_size=sizeof(bytes);
    assert(cetta_http_worker_submit(w,&a)==HTTP_WORKER_OK);
    memset(bytes,1,sizeof(bytes)); memset(echo,'x',strlen(echo));
    r=take(w); const unsigned char expected[]={0,'a',255,0}; body(&r,expected,sizeof(expected)); cetta_http_result_free(&r);
    url(one,base,"/bytes/0"); a=request(5,one); a.max_response_bytes=0;
    assert(cetta_http_worker_submit(w,&a)==HTTP_WORKER_OK);
    r=take(w); body(&r,"",0); cetta_http_result_free(&r);
    url(one,base,"/one"); a=request(6,one); a.max_response_bytes=2;
    assert(cetta_http_worker_submit(w,&a)==HTTP_WORKER_OK);
    r=take(w); assert(r.response_too_large && r.transport_code!=0); cetta_http_result_free(&r);
    url(one,base,"/slow"); a=request(7,one); a.timeout_ms=10;
    assert(cetta_http_worker_submit(w,&a)==HTTP_WORKER_OK);
    r=take(w); assert(r.started && r.transport_code!=0); cetta_http_result_free(&r);
    for (unsigned i=0;i<100;++i) {
        a=request(100+i,one);
        CettaHttpWorkerStatus s=cetta_http_worker_submit(w,&a);
        if (s==HTTP_WORKER_FULL) { --i; struct timespec pause={0,1000000}; nanosleep(&pause,NULL); continue; }
        assert(s==HTTP_WORKER_OK && cetta_http_worker_abandon(w,a.id));
    }
    assert(cetta_http_worker_free(w)==0);
    limits.jobs=1; limits.response_bytes=2;
    w=worker(&limits,NULL); url(one,base,"/one"); a=request(1,one);
    assert(cetta_http_worker_submit(w,&a)==HTTP_WORKER_OK);
    r=take(w); assert(r.response_budget_exceeded && r.body_size<=2); cetta_http_result_free(&r);
    assert(cetta_http_worker_free(w)==0);
    limits.request_bytes=1;
    w=worker(&limits,NULL);
    a.body_size=1024*1024; a.body="x";
    /* Deliberately too short a pointer: rejecting the budget must precede copy. */
    assert(cetta_http_worker_submit(w,&a)==HTTP_WORKER_FULL);
    assert(cetta_http_worker_free(w)==0);
}

typedef struct {
    CettaDurableStore *store;
    pthread_t caller;
    atomic_uint prepare_calls, observations, acknowledged;
    atomic_bool allow_prepare, allow_observe;
    uint64_t id;
    const unsigned char *retained;
    size_t retained_size;
    bool expected_started;
} Journal;

static void commit(CettaDurableStore *s, CettaDurableOp *ops, size_t n) {
    CettaDurableSnapshot v;
    assert(cetta_durable_snapshot(s,NULL,&v)==DURABLE_OK);
    int64_t next;
    assert(cetta_durable_commit(s,v.epoch,v.revision,ops,n,&next)==DURABLE_OK);
    cetta_durable_snapshot_free(&v);
}
static CettaDurableSnapshot snapshot(CettaDurableStore *s, const char *space) {
    CettaDurableSnapshot v;
    assert(cetta_durable_snapshot(s,space,&v)==DURABLE_OK); return v;
}
static CettaHttpPrepare prepare(void *ctx, uint64_t id) {
    Journal *j=ctx;
    assert(id==j->id && !pthread_equal(j->caller,pthread_self()));
    atomic_fetch_add(&j->prepare_calls,1);
    if (!atomic_load(&j->allow_prepare)) return HTTP_PREPARE_DEFER;
    CettaDurableOp claim={DURABLE_REPLACE,"pending","one","attempted",9};
    commit(j->store,&claim,1);
    return HTTP_PREPARE_READY;
}
static bool observe(void *ctx, const CettaHttpResult *r) {
    Journal *j=ctx;
    assert(r->id==j->id && r->started==j->expected_started);
    if (j->expected_started) assert(!r->cancelled && r->status==200 && !r->transport_code);
    else assert(r->cancelled);
    assert(!pthread_equal(j->caller,pthread_self()));
    if (atomic_load(&j->observations)) {
        assert(r->body==j->retained && r->body_size==j->retained_size);
    }
    j->retained=r->body; j->retained_size=r->body_size;
    atomic_fetch_add(&j->observations,1);
    if (!atomic_load(&j->allow_observe)) return false;
    CettaDurableSnapshot v=snapshot(j->store,"pending");
    assert(v.count==1);
    if (r->started) assert(v.records[0].size==9 && !memcmp(v.records[0].data,"attempted",9));
    cetta_durable_snapshot_free(&v);
    CettaDurableOp ops[]={
        {DURABLE_REMOVE,"pending","one",NULL,0},
        {DURABLE_INSERT,"completion","one",r->body_size?r->body:(const unsigned char *)"cancelled",r->body_size?r->body_size:9}
    };
    commit(j->store,ops,2);
    atomic_fetch_add(&j->acknowledged,1);
    return true;
}
static unsigned remote_count(const char *base) {
    char path[512]; url(path,base,"/counted-total");
    CettaHttpWorker *w=worker(NULL,NULL); CettaHttpRequest r=request(1,path);
    assert(cetta_http_worker_submit(w,&r)==HTTP_WORKER_OK);
    CettaHttpResult result=take(w); assert(result.transport_code==0);
    unsigned count=(unsigned)strtoul((char *)result.body,NULL,10);
    cetta_http_result_free(&result); cetta_http_worker_free(w); return count;
}
static void durable(const char *base, const char *path) {
    Journal j={.caller=pthread_self(),.id=1,.expected_started=true};
    assert(cetta_durable_open(path,NULL,&j.store)==DURABLE_OK);
    CettaDurableOp accepted={DURABLE_INSERT,"pending","one","accepted",8};
    commit(j.store,&accepted,1);
    CettaHttpWorkerHooks hooks={&j,prepare,observe};
    CettaHttpWorker *w=worker(NULL,&hooks);
    char endpoint[512]; url(endpoint,base,"/counted"); CettaHttpRequest r=request(1,endpoint);
    assert(cetta_http_worker_submit(w,&r)==HTTP_WORKER_OK);
    assert(!cetta_http_worker_abandon(w,1));
    wait_flag(&j.prepare_calls,2); assert(remote_count(base)==0);
    atomic_store(&j.allow_prepare,true);
    wait_flag(&j.observations,3);
    assert(remote_count(base)==1);
    /* Cancelling after a response was observed cannot erase that fact, even
     * while its durable recording is being retried. */
    assert(cetta_http_worker_cancel(w,1));
    CettaHttpResult unavailable; assert(!cetta_http_worker_take(w,&unavailable));
    CettaDurableSnapshot v=snapshot(j.store,"completion"); assert(v.count==0); cetta_durable_snapshot_free(&v);
    atomic_store(&j.allow_observe,true); wait_flag(&j.acknowledged,1);
    assert(cetta_http_worker_free(w)==0);
    assert(remote_count(base)==1); /* Persistence retries did not repeat HTTP. */
    cetta_durable_close(j.store);
    assert(cetta_durable_open(path,NULL,&j.store)==DURABLE_OK);
    v=snapshot(j.store,"completion");
    assert(v.count==1 && v.records[0].size==1 && v.records[0].data[0]=='1');
    cetta_durable_snapshot_free(&v);
    CettaDurableOp reset[]={ {DURABLE_REMOVE,"completion","one",NULL,0}, accepted };
    commit(j.store,reset,2);
    j.expected_started=false; j.retained=NULL; j.retained_size=0;
    atomic_store(&j.prepare_calls,0); atomic_store(&j.observations,0); atomic_store(&j.acknowledged,0);
    atomic_store(&j.allow_prepare,false);
    w=worker(NULL,&hooks); assert(cetta_http_worker_submit(w,&r)==HTTP_WORKER_OK);
    wait_flag(&j.prepare_calls,1); assert(cetta_http_worker_cancel(w,1));
    wait_flag(&j.acknowledged,1); assert(cetta_http_worker_free(w)==0);
    assert(remote_count(base)==1);
    commit(j.store,reset,2);
    j.expected_started=true; j.retained=NULL; j.retained_size=0;
    atomic_store(&j.observations,0); atomic_store(&j.allow_prepare,true); atomic_store(&j.allow_observe,false);
    w=worker(NULL,&hooks); assert(cetta_http_worker_submit(w,&r)==HTTP_WORKER_OK);
    wait_flag(&j.observations,1);
    assert(cetta_http_worker_free(w)==1); /* Known response could not be journaled. */
    v=snapshot(j.store,"pending");
    assert(v.count==1 && v.records[0].size==9 && !memcmp(v.records[0].data,"attempted",9));
    cetta_durable_snapshot_free(&v);
    assert(remote_count(base)==2);
    cetta_durable_close(j.store);
}

typedef struct { CettaHttpWorker *worker; const char *url; unsigned start; } Producer;
static void *produce(void *context) {
    Producer *p=context;
    for (unsigned i=0;i<25;++i) {
        CettaHttpRequest r=request(p->start+i,p->url);
        uint64_t generation=0;
        for (;;) {
            CettaHttpWorkerStatus s=cetta_http_worker_submit(p->worker,&r);
            if (s==HTTP_WORKER_OK) break;
            assert(s==HTTP_WORKER_FULL);
            generation=cetta_http_worker_wait(p->worker,generation,100);
        }
    }
    return NULL;
}
static void concurrency(const char *base) {
    CettaHttpWorkerLimits limits=cetta_http_worker_default_limits(); limits.jobs=8;
    CettaHttpWorker *w=worker(&limits,NULL);
    char one[512]; url(one,base,"/one");
    Producer producers[4]; pthread_t threads[4]; bool seen[101]={false};
    for (unsigned i=0;i<4;++i) {
        producers[i]=(Producer){w,one,1+i*25};
        assert(!pthread_create(&threads[i],NULL,produce,&producers[i]));
    }
    for (unsigned i=0;i<100;++i) {
        CettaHttpResult r=take(w);
        assert(r.id>=1 && r.id<=100 && !seen[r.id]); seen[r.id]=true;
        body(&r,"one",3); cetta_http_result_free(&r);
    }
    for (unsigned i=0;i<4;++i) pthread_join(threads[i],NULL);
    assert(cetta_http_worker_free(w)==0);
}

int main(int argc, char **argv) {
    assert(argc==3);
    ephemeral(argv[1]); durable(argv[1],argv[2]); concurrency(argv[1]);
    puts("HTTP worker: independent progress, binary copies, bounds, cancellation, durable claim, retained completion, no HTTP replay, recovery, shutdown and concurrent producers passed");
    return 0;
}
