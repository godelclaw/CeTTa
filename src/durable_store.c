#define _POSIX_C_SOURCE 200809L
#include "durable_store.h"

#include <sqlite3.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <unistd.h>

#if SQLITE_VERSION_NUMBER < 3037000
#error "Durable spaces require SQLite 3.37.0 or newer"
#endif

#define DURABLE_APPLICATION_ID 1129595986 /* CTDR */
#define DURABLE_SCHEMA 1
#define DURABLE_NAME_BYTES 255

struct CettaDurableStore {
    sqlite3 *db;
    int lock_fd;
    pthread_mutex_t mutex;
    CettaDurableLimits limits;
};

#ifdef CETTA_DURABLE_TEST
extern void cetta_durable_test_boundary(const char *boundary);
#define BOUNDARY(name) cetta_durable_test_boundary(name)
#else
#define BOUNDARY(name) ((void)0)
#endif

static CettaDurableStatus status(int rc) {
    switch (rc & 255) {
    case SQLITE_OK: case SQLITE_DONE: return DURABLE_OK;
    case SQLITE_BUSY: case SQLITE_LOCKED: return DURABLE_BUSY;
    case SQLITE_NOMEM: return DURABLE_NOMEM;
    case SQLITE_FULL: case SQLITE_TOOBIG: return DURABLE_LIMIT;
    case SQLITE_CORRUPT: case SQLITE_NOTADB: return DURABLE_CORRUPT;
    case SQLITE_CONSTRAINT: return DURABLE_PRECONDITION;
    default: return DURABLE_IO;
    }
}

const char *cetta_durable_status_name(CettaDurableStatus s) {
    static const char *names[] = { "ok", "invalid", "busy", "conflict",
        "precondition", "limit", "allocation", "io", "corrupt", "version" };
    return (unsigned)s < sizeof(names)/sizeof(*names) ? names[s] : "invalid";
}

CettaDurableLimits cetta_durable_default_limits(void) {
    return (CettaDurableLimits){
        .record_bytes = 1024*1024, .batch_bytes = 4*1024*1024,
        .live_bytes = 64*1024*1024, .history_bytes = 16*1024*1024,
        .records = 100000, .operations = 4096, .database_pages = 65536
    };
}

static bool valid_name(const char *s) {
    return s && *s && strnlen(s, DURABLE_NAME_BYTES+1) <= DURABLE_NAME_BYTES;
}

static int exec(CettaDurableStore *s, const char *sql) {
    return sqlite3_exec(s->db, sql, NULL, NULL, NULL);
}

static int scalar(CettaDurableStore *s, const char *sql, int64_t *value) {
    sqlite3_stmt *q = NULL;
    int rc = sqlite3_prepare_v2(s->db, sql, -1, &q, NULL);
    if (rc == SQLITE_OK) {
        rc = sqlite3_step(q);
        if (rc == SQLITE_ROW) { *value = sqlite3_column_int64(q, 0); rc = SQLITE_OK; }
        else if (rc == SQLITE_DONE) rc = SQLITE_CORRUPT;
    }
    sqlite3_finalize(q);
    return rc;
}

static int meta(CettaDurableStore *s, char epoch[33], int64_t *rev,
                int64_t *bytes, int64_t *records, int64_t *history) {
    sqlite3_stmt *q = NULL;
    int rc = sqlite3_prepare_v2(s->db,
        "SELECT epoch,revision,live_bytes,live_count,history_bytes FROM meta WHERE id=1",
        -1, &q, NULL);
    if (rc == SQLITE_OK) {
        rc = sqlite3_step(q);
        if (rc == SQLITE_ROW && sqlite3_column_bytes(q,0) == 32) {
            memcpy(epoch, sqlite3_column_text(q,0),32); epoch[32] = 0;
            *rev = sqlite3_column_int64(q,1);
            *bytes = sqlite3_column_int64(q,2);
            *records = sqlite3_column_int64(q,3);
            *history = sqlite3_column_int64(q,4);
            rc = (*rev >= 0 && *bytes >= 0 && *records >= 0 && *history >= 0)
                ? SQLITE_OK : SQLITE_CORRUPT;
        } else if (rc == SQLITE_ROW || rc == SQLITE_DONE) rc = SQLITE_CORRUPT;
    }
    sqlite3_finalize(q);
    return rc;
}

static int sync_parent(const char *path) {
    char *dir = strdup(path);
    if (!dir) return -1;
    char *slash = strrchr(dir, '/');
    if (slash) { if (slash == dir) slash[1] = 0; else *slash = 0; }
    else { free(dir); dir = strdup("."); if (!dir) return -1; }
    int fd = open(dir, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    free(dir);
    int rc = fd < 0 ? -1 : fsync(fd);
    if (fd >= 0) close(fd);
    return rc;
}

CettaDurableStatus cetta_durable_open(const char *path,
        const CettaDurableLimits *limits, CettaDurableStore **out) {
    if (!out) return DURABLE_INVALID;
    *out = NULL;
    if (!path || !*path || !strcmp(path, ":memory:")) return DURABLE_INVALID;
    CettaDurableLimits l = limits ? *limits : cetta_durable_default_limits();
    if (!l.record_bytes || !l.batch_bytes || !l.live_bytes || !l.history_bytes ||
        !l.records || !l.operations || l.database_pages < 64 ||
        l.record_bytes > l.batch_bytes || l.record_bytes > INT_MAX-1024 ||
        l.batch_bytes > l.history_bytes ||
        l.history_bytes > INT_MAX || l.live_bytes > INT_MAX ||
        l.records > INT_MAX || l.operations > INT_MAX) return DURABLE_INVALID;
    CettaDurableStore *s = calloc(1, sizeof(*s));
    if (!s) return DURABLE_NOMEM;
    s->lock_fd = -1; s->limits = l;
    if (pthread_mutex_init(&s->mutex, NULL)) { free(s); return DURABLE_NOMEM; }
    s->lock_fd = open(path, O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0600);
    struct stat st;
    CettaDurableStatus result = DURABLE_IO;
    if (s->lock_fd < 0 || fstat(s->lock_fd, &st) || !S_ISREG(st.st_mode)) goto fail;
    if (flock(s->lock_fd, LOCK_EX | LOCK_NB)) {
        result = errno == EWOULDBLOCK ? DURABLE_BUSY : DURABLE_IO; goto fail;
    }
    int rc = sqlite3_open_v2(path, &s->db,
        SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_NOFOLLOW, NULL);
    if (rc != SQLITE_OK) { result = status(rc); goto fail; }
    sqlite3_extended_result_codes(s->db, 1);
    sqlite3_busy_timeout(s->db, 0);
    sqlite3_db_config(s->db, SQLITE_DBCONFIG_DEFENSIVE, 1, NULL);
    sqlite3_db_config(s->db, SQLITE_DBCONFIG_TRUSTED_SCHEMA, 0, NULL);
    /* SQL schema text and SQLite's encoded row have overhead independent of
     * the application data quota (which can be tiny in tests). */
    size_t row_limit = l.record_bytes + 1024;
    if (row_limit < 1048576) row_limit = 1048576;
    sqlite3_limit(s->db, SQLITE_LIMIT_LENGTH, (int)row_limit);
    int64_t app = 0, version = 0, tables = 0;
    if ((rc = scalar(s, "PRAGMA application_id", &app)) != SQLITE_OK ||
        (rc = scalar(s, "PRAGMA user_version", &version)) != SQLITE_OK ||
        (rc = scalar(s, "SELECT count(*) FROM sqlite_schema", &tables)) != SQLITE_OK) {
        result = status(rc); goto fail;
    }
    if ((app != DURABLE_APPLICATION_ID || version != DURABLE_SCHEMA) &&
        (app != 0 || version != 0 || tables != 0)) { result = DURABLE_VERSION; goto fail; }
    /* Enforce WAL instead of silently accepting a filesystem/provider fallback. */
    sqlite3_stmt *q = NULL;
    rc = sqlite3_prepare_v2(s->db, "PRAGMA journal_mode=WAL", -1, &q, NULL);
    if (rc == SQLITE_OK) {
        rc = sqlite3_step(q);
        if (rc == SQLITE_ROW && !strcmp((const char *)sqlite3_column_text(q,0), "wal"))
            rc = SQLITE_OK;
        else if (rc == SQLITE_ROW) rc = SQLITE_IOERR;
    }
    sqlite3_finalize(q);
    if (rc != SQLITE_OK) { result = status(rc); goto fail; }
    rc = exec(s, "PRAGMA synchronous=FULL; PRAGMA foreign_keys=ON;"
        "PRAGMA wal_autocheckpoint=256; PRAGMA journal_size_limit=1048576;"
        "PRAGMA temp_store=MEMORY; PRAGMA cache_size=-2048;");
    if (rc != SQLITE_OK) { result = status(rc); goto fail; }
    char *setting = sqlite3_mprintf("PRAGMA max_page_count=%u", l.database_pages);
    if (!setting) { result = DURABLE_NOMEM; goto fail; }
    int64_t actual;
    rc = scalar(s, setting, &actual); sqlite3_free(setting);
    if (rc != SQLITE_OK || actual > l.database_pages) {
        result = rc == SQLITE_OK ? DURABLE_LIMIT : status(rc); goto fail;
    }
    if (!tables) {
        rc = exec(s,
            "BEGIN IMMEDIATE;"
            "CREATE TABLE meta(id INTEGER PRIMARY KEY CHECK(id=1),epoch TEXT NOT NULL,"
            " revision INTEGER NOT NULL,checkpoint_revision INTEGER NOT NULL,"
            " live_bytes INTEGER NOT NULL,live_count INTEGER NOT NULL,history_bytes INTEGER NOT NULL);"
            "INSERT INTO meta VALUES(1,lower(hex(randomblob(16))),0,0,0,0,0);"
            "CREATE TABLE records(space TEXT NOT NULL,key TEXT NOT NULL,value BLOB NOT NULL,"
            " revision INTEGER NOT NULL,position INTEGER NOT NULL,PRIMARY KEY(space,key)) WITHOUT ROWID;"
            "CREATE INDEX record_order ON records(space,revision,position);"
            "CREATE TABLE checkpoint(space TEXT NOT NULL,key TEXT NOT NULL,value BLOB NOT NULL,"
            " revision INTEGER NOT NULL,position INTEGER NOT NULL,PRIMARY KEY(space,key)) WITHOUT ROWID;"
            "CREATE TABLE deltas(revision INTEGER NOT NULL,position INTEGER NOT NULL,kind INTEGER NOT NULL,"
            " space TEXT NOT NULL,key TEXT NOT NULL,value BLOB NOT NULL,PRIMARY KEY(revision,position),"
            " UNIQUE(revision,space,key)) WITHOUT ROWID;"
            "PRAGMA application_id=1129595986; PRAGMA user_version=1; COMMIT;");
        if (rc != SQLITE_OK) { result = status(rc); goto fail; }
    }
    char epoch[33]; int64_t rev, bytes, count, history;
    rc = meta(s, epoch, &rev, &bytes, &count, &history);
    if (rc != SQLITE_OK) { result = status(rc); goto fail; }
    if ((uint64_t)bytes > l.live_bytes || (uint64_t)count > l.records ||
        (uint64_t)history > l.history_bytes) { result = DURABLE_LIMIT; goto fail; }
    if (sync_parent(path)) goto fail;
    *out = s;
    return DURABLE_OK;
fail:
    cetta_durable_close(s);
    return result;
}

void cetta_durable_close(CettaDurableStore *s) {
    if (!s) return;
    if (s->db) sqlite3_close(s->db);
    if (s->lock_fd >= 0) close(s->lock_fd);
    pthread_mutex_destroy(&s->mutex);
    free(s);
}

void cetta_durable_snapshot_free(CettaDurableSnapshot *v) {
    if (!v) return;
    for (size_t i = 0; i < v->count; ++i) {
        free(v->records[i].space); free(v->records[i].key); free(v->records[i].data);
    }
    free(v->records); memset(v, 0, sizeof(*v));
}

static CettaDurableStatus snapshot_locked(CettaDurableStore *s, const char *space,
        bool recovery, CettaDurableSnapshot *out) {
    memset(out, 0, sizeof(*out));
    int64_t bytes, count, history;
    int rc = meta(s, out->epoch, &out->revision, &bytes, &count, &history);
    if (rc != SQLITE_OK) return status(rc);
    if ((uint64_t)count > s->limits.records || (uint64_t)bytes > s->limits.live_bytes)
        return DURABLE_LIMIT;
    /* Selecting the last delta for each occurrence is replay as data. No
     * application code or effect handler runs while reconstructing a view. */
    const char *sql = recovery
        ? "WITH versions AS (SELECT space,key,value,revision,position,1 AS kind FROM checkpoint"
          " UNION ALL SELECT space,key,value,revision,position,kind FROM deltas),"
          " ranked AS (SELECT *,row_number() OVER (PARTITION BY space,key ORDER BY revision DESC) AS n"
          " FROM versions) SELECT space,key,value,revision,position FROM ranked WHERE n=1 AND kind<>3"
          " ORDER BY revision,position,space,key"
        : "SELECT space,key,value,revision,position FROM records WHERE (?1 IS NULL OR space=?1)"
          " ORDER BY revision,position,space,key";
    sqlite3_stmt *q = NULL;
    rc = sqlite3_prepare_v2(s->db, sql, -1, &q, NULL);
    if (rc != SQLITE_OK) return status(rc);
    if (!recovery && space) rc = sqlite3_bind_text(q, 1, space, -1, SQLITE_STATIC);
    size_t capacity = 0, total = 0;
    while (rc == SQLITE_OK && (rc = sqlite3_step(q)) == SQLITE_ROW) {
        if (out->count >= s->limits.records) { rc = SQLITE_TOOBIG; break; }
        int n = sqlite3_column_bytes(q, 2);
        size_t names = (size_t)sqlite3_column_bytes(q,0) + (size_t)sqlite3_column_bytes(q,1);
        if ((size_t)n > s->limits.record_bytes || total + n + names > s->limits.live_bytes) {
            rc = SQLITE_TOOBIG; break;
        }
        if (out->count == capacity) {
            size_t next = capacity ? capacity*2 : 16;
            CettaDurableRecord *rows = realloc(out->records, next*sizeof(*rows));
            if (!rows) { rc = SQLITE_NOMEM; break; }
            out->records = rows; capacity = next;
        }
        CettaDurableRecord *r = &out->records[out->count++];
        *r = (CettaDurableRecord){
            .space = strdup((const char *)sqlite3_column_text(q,0)),
            .key = strdup((const char *)sqlite3_column_text(q,1)),
            .size = (size_t)n, .data = malloc(n ? (size_t)n : 1),
            .revision = sqlite3_column_int64(q,3), .position = sqlite3_column_int64(q,4)
        };
        if (!r->space || !r->key || !r->data) { rc = SQLITE_NOMEM; break; }
        if (n) memcpy(r->data, sqlite3_column_blob(q,2), (size_t)n);
        total += n + names; rc = SQLITE_OK;
    }
    sqlite3_finalize(q);
    CettaDurableStatus result = status(rc);
    if (result != DURABLE_OK) cetta_durable_snapshot_free(out);
    return result;
}

CettaDurableStatus cetta_durable_snapshot(CettaDurableStore *s, const char *space,
        CettaDurableSnapshot *out) {
    if (!s || !out || (space && !valid_name(space))) return DURABLE_INVALID;
    pthread_mutex_lock(&s->mutex);
    CettaDurableStatus result = snapshot_locked(s, space, false, out);
    pthread_mutex_unlock(&s->mutex);
    return result;
}

CettaDurableStatus cetta_durable_recover(CettaDurableStore *s, CettaDurableSnapshot *out) {
    if (!s || !out) return DURABLE_INVALID;
    pthread_mutex_lock(&s->mutex);
    CettaDurableStatus result = snapshot_locked(s, NULL, true, out);
    pthread_mutex_unlock(&s->mutex);
    return result;
}

static int checkpoint_locked(CettaDurableStore *s) {
    return exec(s, "DELETE FROM checkpoint; INSERT INTO checkpoint SELECT * FROM records;"
        "DELETE FROM deltas; UPDATE meta SET checkpoint_revision=revision,history_bytes=0 WHERE id=1;");
}

CettaDurableStatus cetta_durable_checkpoint(CettaDurableStore *s) {
    if (!s) return DURABLE_INVALID;
    pthread_mutex_lock(&s->mutex);
    int rc = exec(s, "BEGIN IMMEDIATE");
    if (rc == SQLITE_OK) rc = checkpoint_locked(s);
    if (rc == SQLITE_OK) { BOUNDARY("checkpoint"); rc = exec(s, "COMMIT"); }
    if (rc != SQLITE_OK) exec(s, "ROLLBACK");
    /* No long-lived reader transactions are exposed, so a successful commit
     * can reclaim the WAL. A busy checkpoint does not undo that commit. */
    if (rc == SQLITE_OK) sqlite3_wal_checkpoint_v2(s->db, NULL, SQLITE_CHECKPOINT_TRUNCATE, NULL, NULL);
    pthread_mutex_unlock(&s->mutex);
    return status(rc);
}

static int bind_key(sqlite3_stmt *q, const CettaDurableOp *op) {
    int rc = sqlite3_bind_text(q,1,op->space,-1,SQLITE_STATIC);
    if (rc == SQLITE_OK) rc = sqlite3_bind_text(q,2,op->key,-1,SQLITE_STATIC);
    return rc;
}

CettaDurableStatus cetta_durable_commit(CettaDurableStore *s,
        const char *expected_epoch, int64_t expected_revision,
        const CettaDurableOp *ops, size_t count, int64_t *published_revision) {
    if (published_revision) *published_revision = -1;
    if (!s || !expected_epoch || strlen(expected_epoch) != 32 ||
        expected_revision < 0 || !ops || !count || !published_revision) return DURABLE_INVALID;
    if (count > s->limits.operations) return DURABLE_LIMIT;
    size_t batch = 0;
    for (size_t i=0; i<count; ++i) {
        const CettaDurableOp *op = &ops[i];
        if (!valid_name(op->space) || !valid_name(op->key) ||
            op->kind < DURABLE_INSERT || op->kind > DURABLE_REMOVE ||
            (op->size && !op->data) || (op->kind == DURABLE_REMOVE && op->size))
            return DURABLE_INVALID;
        if (op->size > s->limits.record_bytes) return DURABLE_LIMIT;
        size_t n = op->size + strlen(op->space) + strlen(op->key);
        if (n > s->limits.batch_bytes - batch) return DURABLE_LIMIT;
        batch += n;
    }
    pthread_mutex_lock(&s->mutex);
    int rc = exec(s, "BEGIN IMMEDIATE");
    CettaDurableStatus result = status(rc);
    sqlite3_stmt *read = NULL, *write = NULL, *log = NULL, *m = NULL;
    char epoch[33]; int64_t rev = -1, bytes, rows, history;
    if (rc != SQLITE_OK) goto done;
    rc = meta(s, epoch, &rev, &bytes, &rows, &history);
    if (rc != SQLITE_OK) goto sql_error;
    if (strcmp(epoch, expected_epoch) || rev != expected_revision) { result = DURABLE_CONFLICT; goto done; }
    if (rev == INT64_MAX) { result = DURABLE_LIMIT; goto done; }
    if ((uint64_t)history + batch > s->limits.history_bytes) {
        rc = checkpoint_locked(s); if (rc != SQLITE_OK) goto sql_error;
        history = 0;
    }
    rc = sqlite3_prepare_v2(s->db, "SELECT length(value) FROM records WHERE space=?1 AND key=?2", -1,&read,NULL);
    if (rc != SQLITE_OK) goto sql_error;
    rc = sqlite3_prepare_v2(s->db, "INSERT INTO deltas VALUES(?1,?2,?3,?4,?5,?6)", -1,&log,NULL);
    if (rc != SQLITE_OK) goto sql_error;
    for (size_t i=0; i<count; ++i) {
        const CettaDurableOp *op = &ops[i];
        sqlite3_reset(read);
        rc = bind_key(read,op); if (rc != SQLITE_OK) goto sql_error;
        rc = sqlite3_step(read);
        if (rc != SQLITE_ROW && rc != SQLITE_DONE) goto sql_error;
        bool exists = rc == SQLITE_ROW;
        if (exists == (op->kind == DURABLE_INSERT)) { result = DURABLE_PRECONDITION; goto done; }
        int64_t names = (int64_t)(strlen(op->space)+strlen(op->key));
        if (exists) { bytes -= sqlite3_column_int64(read,0) + names; --rows; }
        if (op->kind != DURABLE_REMOVE) { bytes += (int64_t)op->size + names; ++rows; }
        if (bytes < 0 || rows < 0) { result = DURABLE_CORRUPT; goto done; }
        if ((uint64_t)bytes > s->limits.live_bytes || (uint64_t)rows > s->limits.records) {
            result = DURABLE_LIMIT; goto done;
        }
        const char *sql = op->kind == DURABLE_REMOVE
            ? "DELETE FROM records WHERE space=?1 AND key=?2"
            : "INSERT INTO records VALUES(?1,?2,?3,?4,?5) ON CONFLICT(space,key)"
              " DO UPDATE SET value=excluded.value,revision=excluded.revision,position=excluded.position";
        rc = sqlite3_prepare_v2(s->db,sql,-1,&write,NULL); if (rc != SQLITE_OK) goto sql_error;
        rc = bind_key(write,op); if (rc != SQLITE_OK) goto sql_error;
        if (op->kind != DURABLE_REMOVE) {
            rc = sqlite3_bind_blob(write,3,op->size ? op->data : "",(int)op->size,SQLITE_STATIC);
            if (rc == SQLITE_OK) rc = sqlite3_bind_int64(write,4,rev+1);
            if (rc == SQLITE_OK) rc = sqlite3_bind_int64(write,5,(int64_t)i);
            if (rc != SQLITE_OK) goto sql_error;
        }
        rc = sqlite3_step(write); if (rc != SQLITE_DONE) goto sql_error;
        sqlite3_finalize(write); write = NULL;
        sqlite3_reset(log);
        if ((rc=sqlite3_bind_int64(log,1,rev+1)) != SQLITE_OK ||
            (rc=sqlite3_bind_int64(log,2,(int64_t)i)) != SQLITE_OK ||
            (rc=sqlite3_bind_int(log,3,op->kind)) != SQLITE_OK ||
            (rc=sqlite3_bind_text(log,4,op->space,-1,SQLITE_STATIC)) != SQLITE_OK ||
            (rc=sqlite3_bind_text(log,5,op->key,-1,SQLITE_STATIC)) != SQLITE_OK ||
            (rc=sqlite3_bind_blob(log,6,op->size ? op->data : "",(int)op->size,SQLITE_STATIC)) != SQLITE_OK)
            goto sql_error;
        rc = sqlite3_step(log); if (rc != SQLITE_DONE) goto sql_error;
        BOUNDARY("operation");
    }
    rc = sqlite3_prepare_v2(s->db,"UPDATE meta SET revision=?1,live_bytes=?2,live_count=?3,history_bytes=?4 WHERE id=1",-1,&m,NULL);
    if (rc != SQLITE_OK) goto sql_error;
    if ((rc=sqlite3_bind_int64(m,1,rev+1)) != SQLITE_OK ||
        (rc=sqlite3_bind_int64(m,2,bytes)) != SQLITE_OK ||
        (rc=sqlite3_bind_int64(m,3,rows)) != SQLITE_OK ||
        (rc=sqlite3_bind_int64(m,4,history+(int64_t)batch)) != SQLITE_OK) goto sql_error;
    rc = sqlite3_step(m); if (rc != SQLITE_DONE) goto sql_error;
    BOUNDARY("before_commit");
    rc = exec(s,"COMMIT"); if (rc != SQLITE_OK) goto sql_error;
    BOUNDARY("after_commit");
    *published_revision = rev+1;
    result = DURABLE_OK;
    goto done;
sql_error:
    result = status(rc);
done:
    sqlite3_finalize(read); sqlite3_finalize(write); sqlite3_finalize(log); sqlite3_finalize(m);
    if (!sqlite3_get_autocommit(s->db)) exec(s,"ROLLBACK");
    pthread_mutex_unlock(&s->mutex);
    return result;
}
