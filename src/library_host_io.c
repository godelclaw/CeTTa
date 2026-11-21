#define _GNU_SOURCE
#include "library_host_io.h"
#include "library.h"
#include "eval.h"
#include "native_handle.h"
#include "effect_policy.h"
#include "utf8.h"
#include "unicode_text_layout.h"
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/inotify.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/statvfs.h>
#include <sys/un.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

typedef enum { HOST_STREAM, HOST_LISTENER, HOST_TERMINAL, HOST_STDIO, HOST_WATCH } HostFdKind;
typedef struct {
    int fd;
    HostFdKind kind;
    char *path;
    dev_t device;
    ino_t inode;
    bool raw;
    struct termios saved;
    struct winsize size;
} HostFd;
typedef struct {
    unsigned char *bytes;
    size_t capacity, first, last, maximum, scan;
    size_t *rows, row_count, row_capacity, dirty, layout_width;
    bool layout_valid;
    bool text, paste;
} HostBuffer;
static const char *fd_kind = "host-fd", *buffer_kind = "host-buffer";
static pthread_mutex_t terminal_lock = PTHREAD_MUTEX_INITIALIZER;
static unsigned terminal_users;
static struct sigaction previous_winch;
static void resized(int number) { (void)number; }
typedef struct { struct sigaction previous[3]; } HostSignals;
static const char *signals_kind = "host-signals";
static const int watched_signals[3] = {SIGTERM, SIGHUP, SIGINT};
static bool signals_owned;
static volatile sig_atomic_t requested_signal;
static void requested(int number) { requested_signal = number; }
static void release_signals(void *resource) {
    HostSignals *owner = resource;
    pthread_mutex_lock(&terminal_lock);
    for (size_t i = 0; i < 3u; ++i) (void)sigaction(watched_signals[i], &owner->previous[i], NULL);
    signals_owned = false; requested_signal = 0;
    pthread_mutex_unlock(&terminal_lock); free(owner);
}

static Atom *term(Arena *a, const char *name, Atom **items, size_t count) {
    Atom **all = arena_alloc(a, (count + 1u) * sizeof(*all));
    all[0] = atom_symbol(a, name);
    for (size_t i = 0; i < count; ++i) all[i + 1u] = items[i];
    return atom_expr(a, all, (uint32_t)count + 1u);
}
static Atom *failure(Arena *a, const char *operation, int code) {
    return term(a, "HostFailure", (Atom *[]){atom_string(a, operation), atom_int(a, code),
        atom_string(a, code ? strerror(code) : "invalid argument or closed owner")}, 3u);
}
static const char *text(Atom *atom) {
    if (!atom) return NULL;
    if (atom->kind == ATOM_SYMBOL) return atom_name_cstr(atom);
    if (atom->kind == ATOM_GROUNDED && atom->ground.gkind == GV_STRING &&
        !memchr(atom->ground.sval, 0, atom_string_len(atom))) return atom->ground.sval;
    return NULL;
}
static bool string_bytes(Atom *atom, const char **bytes, size_t *length) {
    if (!atom || atom->kind != ATOM_GROUNDED || atom->ground.gkind != GV_STRING) return false;
    *bytes = atom->ground.sval; *length = atom_string_len(atom); return true;
}
static bool number(Atom *atom, int64_t low, int64_t high, int64_t *out) {
    if (!atom || atom->kind != ATOM_GROUNDED || atom->ground.gkind != GV_INT ||
        atom->ground.ival < low || atom->ground.ival > high) return false;
    *out = atom->ground.ival; return true;
}
static bool utf8(const char *bytes, size_t length) {
    for (size_t at = 0; at < length;) {
        uint32_t cp, width;
        if (!cetta_utf8_decode_one((const uint8_t *)bytes, length, at, &cp, &width)) return false;
        at += width;
    }
    return true;
}
static int owned_descriptor(int fd) {
    if (fd < 0 || fd >= 3) return fd;
    int moved = fcntl(fd, F_DUPFD_CLOEXEC, 3), saved = errno;
    close(fd); errno = saved; return moved;
}
static void release_fd(void *resource) {
    HostFd *f = resource;
    if (f->kind == HOST_TERMINAL) {
        if (f->raw) (void)tcsetattr(f->fd, TCSANOW, &f->saved);
        pthread_mutex_lock(&terminal_lock);
        if (terminal_users && !--terminal_users) (void)sigaction(SIGWINCH, &previous_winch, NULL);
        pthread_mutex_unlock(&terminal_lock);
    }
    if (f->fd >= 0) close(f->fd);
    if (f->path) {
        struct stat current;
        if (!lstat(f->path, &current) && current.st_dev == f->device && current.st_ino == f->inode &&
            S_ISSOCK(current.st_mode) && current.st_uid == geteuid()) (void)unlink(f->path);
    }
    free(f->path); free(f);
}
static void release_buffer(void *resource) {
    HostBuffer *b = resource; free(b->rows); free(b->bytes); free(b);
}
static Atom *own_fd(CettaLibraryContext *ctx, Arena *a, HostFd *f) {
    uint64_t id;
    if (!cetta_native_handle_alloc(ctx, fd_kind, f, release_fd, &id)) {
        release_fd(f); return failure(a, "open", ENOMEM);
    }
    return cetta_native_handle_owned_atom(ctx, a, fd_kind, id);
}
static HostFd *acquire_fd(CettaLibraryContext *ctx, Atom *atom, CettaNativeHandleUse *use,
                         CettaNativeHandleUseMode mode) {
    return cetta_native_handle_acquire_owned(ctx, fd_kind, atom, mode, use)
        ? cetta_native_handle_use_resource(use) : NULL;
}
static HostBuffer *acquire_buffer(CettaLibraryContext *ctx, Atom *atom, CettaNativeHandleUse *use) {
    return cetta_native_handle_acquire_owned(ctx, buffer_kind, atom, CETTA_NATIVE_HANDLE_USE_EXCLUSIVE, use)
        ? cetta_native_handle_use_resource(use) : NULL;
}
static Atom *listen_local(CettaLibraryContext *ctx, Arena *a, const char *path, int backlog, bool recover) {
    struct sockaddr_un address = {.sun_family = AF_UNIX};
    if (!path || path[0] != '/' || strlen(path) >= sizeof(address.sun_path)) return failure(a, "listen", EINVAL);
    struct stat old, current;
    if (!lstat(path, &old)) {
        if (!recover) return failure(a, "listen", EADDRINUSE);
        if (!S_ISSOCK(old.st_mode) || old.st_uid != geteuid()) return failure(a, "listen", EEXIST);
        int probe = owned_descriptor(socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0));
        if (probe < 0) return failure(a, "listen", errno);
        strcpy(address.sun_path, path);
        int connected = connect(probe, (struct sockaddr *)&address, sizeof(address)), code = errno;
        close(probe);
        if (!connected || code != ECONNREFUSED) return failure(a, "listen", EADDRINUSE);
        if (lstat(path, &current) || current.st_dev != old.st_dev || current.st_ino != old.st_ino ||
            unlink(path)) return failure(a, "listen", EAGAIN);
    } else if (errno != ENOENT) return failure(a, "listen", errno);
    HostFd *f = calloc(1, sizeof(*f));
    if (!f) return failure(a, "listen", ENOMEM);
    f->fd = owned_descriptor(socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC | SOCK_NONBLOCK, 0));
    f->kind = HOST_LISTENER;
    if (f->fd < 0) { int code = errno; free(f); return failure(a, "listen", code); }
    strcpy(address.sun_path, path);
    int bound = bind(f->fd, (struct sockaddr *)&address, sizeof(address)), saved = errno;
    if (bound) { release_fd(f); return failure(a, "listen", saved); }
    if (lstat(path, &current)) { saved = errno; release_fd(f); return failure(a, "listen", saved); }
    f->path = strdup(path); f->device = current.st_dev; f->inode = current.st_ino;
    if (!f->path || chmod(path, 0600) || listen(f->fd, backlog)) {
        saved = f->path ? errno : ENOMEM; release_fd(f); return failure(a, "listen", saved);
    }
    return own_fd(ctx, a, f);
}
static Atom *accept_local(CettaLibraryContext *ctx, Arena *a, HostFd *listener) {
    if (listener->kind != HOST_LISTENER) return failure(a, "accept", EINVAL);
    int fd = accept4(listener->fd, NULL, NULL, SOCK_CLOEXEC | SOCK_NONBLOCK);
    if (fd < 0) return errno == EAGAIN || errno == EWOULDBLOCK ? atom_symbol(a, "HostPending") : failure(a, "accept", errno);
    fd = owned_descriptor(fd);
    if (fd < 0) return failure(a, "accept", errno);
    struct ucred peer; socklen_t bytes = sizeof(peer);
    if (getsockopt(fd, SOL_SOCKET, SO_PEERCRED, &peer, &bytes)) { int code = errno; close(fd); return failure(a, "peer", code); }
    HostFd *f = calloc(1, sizeof(*f));
    if (!f) { close(fd); return failure(a, "accept", ENOMEM); }
    f->fd = fd; f->kind = HOST_STREAM;
    Atom *owner = own_fd(ctx, a, f);
    if (owner->kind != ATOM_EXPR || !atom_is_symbol(owner->expr.elems[0], "NativeHandle")) return owner;
    Atom *identity = term(a, "HostPeer", (Atom *[]){atom_int(a, peer.pid), atom_int(a, peer.uid), atom_int(a, peer.gid)}, 3u);
    return term(a, "HostAccepted", (Atom *[]){owner, identity}, 2u);
}
static Atom *terminal_open(CettaLibraryContext *ctx, Arena *a, const char *path) {
    if (!path) return failure(a, "terminal-open", EINVAL);
    HostFd *f = calloc(1, sizeof(*f));
    if (!f) return failure(a, "terminal-open", ENOMEM);
    f->fd = owned_descriptor(open(path, O_RDWR | O_NOCTTY | O_CLOEXEC | O_NONBLOCK));
    f->kind = HOST_TERMINAL;
    if (f->fd < 0 || tcgetattr(f->fd, &f->saved) || ioctl(f->fd, TIOCGWINSZ, &f->size)) {
        int code = errno; if (f->fd >= 0) close(f->fd); free(f); return failure(a, "terminal-open", code);
    }
    pthread_mutex_lock(&terminal_lock);
    if (!terminal_users) {
        struct sigaction action = {0}; action.sa_handler = resized; sigemptyset(&action.sa_mask);
        if (sigaction(SIGWINCH, &action, &previous_winch)) {
            int code = errno; pthread_mutex_unlock(&terminal_lock); close(f->fd); free(f);
            return failure(a, "terminal-open", code);
        }
    }
    ++terminal_users;
    pthread_mutex_unlock(&terminal_lock);
    return own_fd(ctx, a, f);
}
static Atom *terminal_raw(Arena *a, HostFd *f, bool enabled) {
    if (f->kind != HOST_TERMINAL) return failure(a, "terminal-mode", ENOTTY);
    struct termios mode = f->saved;
    if (enabled) cfmakeraw(&mode);
    if (tcsetattr(f->fd, TCSANOW, &mode)) return failure(a, "terminal-mode", errno);
    f->raw = enabled;
    return atom_symbol(a, "HostDone");
}
static Atom *open_signals(CettaLibraryContext *ctx, Arena *a) {
    HostSignals *owner = calloc(1, sizeof(*owner));
    if (!owner) return failure(a, "signals-open", ENOMEM);
    pthread_mutex_lock(&terminal_lock);
    if (signals_owned) { pthread_mutex_unlock(&terminal_lock); free(owner); return failure(a, "signals-open", EBUSY); }
    struct sigaction action = {0}; action.sa_handler = requested; sigemptyset(&action.sa_mask);
    size_t installed = 0;
    for (; installed < 3u; ++installed) if (sigaction(watched_signals[installed], &action, &owner->previous[installed])) break;
    if (installed != 3u) {
        int code = errno;
        while (installed) { --installed; (void)sigaction(watched_signals[installed], &owner->previous[installed], NULL); }
        pthread_mutex_unlock(&terminal_lock); free(owner); return failure(a, "signals-open", code);
    }
    signals_owned = true; requested_signal = 0;
    pthread_mutex_unlock(&terminal_lock);
    uint64_t id;
    if (!cetta_native_handle_alloc(ctx, signals_kind, owner, release_signals, &id)) {
        release_signals(owner); return failure(a, "signals-open", ENOMEM);
    }
    return cetta_native_handle_owned_atom(ctx, a, signals_kind, id);
}
static Atom *watch_directory(CettaLibraryContext *ctx, Arena *a, const char *path) {
    int fd = inotify_init1(IN_CLOEXEC | IN_NONBLOCK);
    if (fd < 0) return failure(a, "watch", errno);
    if (!path || inotify_add_watch(fd, path, IN_MODIFY | IN_MOVED_TO | IN_MOVED_FROM | IN_CREATE | IN_DELETE | IN_DELETE_SELF | IN_MOVE_SELF) < 0) {
        int code = path ? errno : EINVAL; close(fd); return failure(a, "watch", code);
    }
    HostFd *owner = calloc(1, sizeof(*owner));
    if (!owner) { close(fd); return failure(a, "watch", ENOMEM); }
    owner->fd = fd; owner->kind = HOST_WATCH; return own_fd(ctx, a, owner);
}
static Atom *directory_changes(Arena *a, HostFd *owner) {
    if (owner->kind != HOST_WATCH) return failure(a, "changes", EINVAL);
    union { struct inotify_event align; unsigned char bytes[65536]; } block;
    ssize_t count = read(owner->fd, block.bytes, sizeof(block.bytes));
    if (count < 0) return errno == EINTR || errno == EAGAIN ? atom_symbol(a, "HostPending") : failure(a, "changes", errno);
    Atom **names = arena_alloc(a, ((size_t)count / sizeof(struct inotify_event) + 1u) * sizeof(*names));
    size_t used = 0; bool overflow = false;
    for (size_t at = 0; at + sizeof(struct inotify_event) <= (size_t)count;) {
        const struct inotify_event *event = (const struct inotify_event *)(block.bytes + at);
        size_t next = at + sizeof(*event) + event->len;
        if (next > (size_t)count) return failure(a, "changes", EIO);
        if (event->mask & (IN_Q_OVERFLOW | IN_IGNORED | IN_DELETE_SELF | IN_MOVE_SELF)) overflow = true;
        if (event->len && !(event->mask & IN_ISDIR)) names[used++] = atom_string(a, event->name);
        at = next;
    }
    return term(a, "HostChanges", (Atom *[]){atom_expr(a, names, (uint32_t)used), atom_bool(a, overflow)}, 2u);
}
static Atom *read_fd(Arena *a, HostFd *f, size_t maximum) {
    if (f->kind == HOST_LISTENER) return failure(a, "read", EINVAL);
    unsigned char *bytes = malloc(maximum);
    if (!bytes) return failure(a, "read", ENOMEM);
    ssize_t count = read(f->fd, bytes, maximum); int saved = errno;
    Atom *answer = count > 0 ? term(a, "HostBytes", (Atom *[]){atom_string_n(a, (const char *)bytes, (size_t)count)}, 1u)
        : count == 0 ? atom_symbol(a, "HostEOF")
        : saved == EAGAIN || saved == EWOULDBLOCK || saved == EINTR ? atom_symbol(a, "HostPending") : failure(a, "read", saved);
    free(bytes); return answer;
}
static ssize_t write_without_sigpipe(HostFd *f, const char *bytes, size_t length) {
    if (f->kind == HOST_STREAM) return send(f->fd, bytes, length, MSG_NOSIGNAL);
    sigset_t set, previous, pending; sigemptyset(&set); sigaddset(&set, SIGPIPE);
    int blocked = pthread_sigmask(SIG_BLOCK, &set, &previous);
    if (blocked) { errno = blocked; return -1; }
    sigpending(&pending); bool already = sigismember(&pending, SIGPIPE) == 1;
    ssize_t count = write(f->fd, bytes, length); int saved = errno;
    if (count < 0 && saved == EPIPE && !already) { struct timespec zero = {0}; (void)sigtimedwait(&set, NULL, &zero); }
    (void)pthread_sigmask(SIG_SETMASK, &previous, NULL); errno = saved; return count;
}
static Atom *write_fd(Arena *a, HostFd *f, const char *bytes, size_t length, size_t offset) {
    if (f->kind == HOST_LISTENER || offset > length) return failure(a, "write", EINVAL);
    ssize_t count = write_without_sigpipe(f, bytes + offset, length - offset); int saved = errno;
    return count >= 0 ? term(a, "HostWritten", (Atom *[]){atom_int(a, count)}, 1u)
        : saved == EAGAIN || saved == EWOULDBLOCK || saved == EINTR ? atom_symbol(a, "HostPending") : failure(a, "write", saved);
}
static size_t buffer_length(const HostBuffer *b) { return b->capacity - (b->last - b->first); }
static bool buffer_reserve(HostBuffer *b, size_t extra) {
    size_t length = buffer_length(b);
    if (extra > b->maximum - length) { errno = EFBIG; return false; }
    if (b->last - b->first >= extra) return true;
    size_t next = b->capacity ? b->capacity : 256u;
    while (next - length < extra) next = next <= b->maximum / 2u ? next * 2u : b->maximum;
    if (next > b->maximum) next = b->maximum;
    unsigned char *bytes = malloc(next);
    if (!bytes) { errno = ENOMEM; return false; }
    size_t tail = b->capacity - b->last;
    if (b->first) memcpy(bytes, b->bytes, b->first);
    if (tail) memcpy(bytes + next - tail, b->bytes + b->last, tail);
    free(b->bytes); b->bytes = bytes; b->last = next - tail; b->capacity = next; return true;
}
static void buffer_seek(HostBuffer *b, size_t position) {
    if (position < b->first) {
        size_t moved = b->first - position;
        memmove(b->bytes + b->last - moved, b->bytes + position, moved); b->first = position; b->last -= moved;
    } else if (position > b->first) {
        size_t moved = position - b->first;
        memmove(b->bytes + b->first, b->bytes + b->last, moved); b->first += moved; b->last += moved;
    }
}
static unsigned char buffer_at(const HostBuffer *b, size_t at) {
    return b->bytes[at < b->first ? at : at + b->last - b->first];
}
static size_t previous_character(const HostBuffer *b, size_t at) {
    if (!at) return 0;
    --at; if (b->text) while (at && (buffer_at(b, at) & 0xc0u) == 0x80u) --at;
    return at;
}
static size_t next_character(const HostBuffer *b, size_t at) {
    size_t length = buffer_length(b);
    if (at == length) return at;
    ++at; if (b->text) while (at < length && (buffer_at(b, at) & 0xc0u) == 0x80u) ++at;
    return at;
}
static Atom *buffer_string(Arena *a, HostBuffer *b) {
    size_t length = buffer_length(b);
    char *bytes = arena_alloc(a, length ? length : 1u);
    if (b->first) memcpy(bytes, b->bytes, b->first);
    size_t tail = b->capacity - b->last;
    if (tail) memcpy(bytes + b->first, b->bytes + b->last, tail);
    return atom_string_n(a, bytes, length);
}
static Atom *buffer_insert(Arena *a, HostBuffer *b, const char *bytes, size_t count, bool append) {
    if (b->text && !utf8(bytes, count)) return failure(a, "buffer-insert", EILSEQ);
    if (!buffer_reserve(b, count)) return failure(a, "buffer-insert", errno);
    if (append) buffer_seek(b, buffer_length(b));
    if (b->first < b->dirty) b->dirty = b->first;
    if (count) memcpy(b->bytes + b->first, bytes, count);
    b->first += count;
    return term(a, "HostBuffered", (Atom *[]){atom_int(a, (int64_t)buffer_length(b))}, 1u);
}
static Atom *buffer_line(Arena *a, HostBuffer *b) {
    if (b->text) return failure(a, "buffer-line", EINVAL);
    size_t length = buffer_length(b); buffer_seek(b, length);
    unsigned char *newline = b->bytes ? memchr(b->bytes + b->scan, '\n', length - b->scan) : NULL;
    if (!newline) { b->scan = length; return atom_symbol(a, "HostPending"); }
    size_t bytes = (size_t)(newline - b->bytes);
    Atom *answer = term(a, "HostLine", (Atom *[]){atom_string_n(a, (const char *)b->bytes, bytes)}, 1u);
    size_t left = length - bytes - 1u;
    memmove(b->bytes, newline + 1, left); b->first = left; b->last = b->capacity; b->scan = 0;
    return answer;
}

static Atom *wait_ready(CettaLibraryContext *ctx, Arena *a, Atom *requests, int timeout) {
    if (!requests || requests->kind != ATOM_EXPR || requests->expr.len > 65536u)
        return failure(a, "wait", EINVAL);
    size_t count = requests->expr.len;
    struct pollfd *fds = calloc(count ? count : 1u, sizeof(*fds));
    CettaNativeHandleUse *uses = calloc(count ? count : 1u, sizeof(*uses));
    Atom **ready = malloc((count ? count : 1u) * sizeof(*ready));
    if (!fds || !uses || !ready) { free(fds); free(uses); free(ready); return failure(a, "wait", ENOMEM); }
    int code = 0; bool resized_now = false;
    for (size_t i = 0; i < count; ++i) {
        Atom *pair = requests->expr.elems[i];
        const char *interest = pair && pair->kind == ATOM_EXPR && pair->expr.len == 2u ? text(pair->expr.elems[1]) : NULL;
        HostFd *f = interest ? acquire_fd(ctx, pair->expr.elems[0], &uses[i], CETTA_NATIVE_HANDLE_USE_LIFETIME) : NULL;
        if (!f || (strcmp(interest, "read") && strcmp(interest, "write") && strcmp(interest, "resize"))) { code = EINVAL; break; }
        fds[i].fd = f->fd;
        fds[i].events = !strcmp(interest, "read") ? POLLIN : !strcmp(interest, "write") ? POLLOUT : 0;
        if (!strcmp(interest, "resize")) {
            struct winsize size;
            if (f->kind != HOST_TERMINAL || ioctl(f->fd, TIOCGWINSZ, &size)) { code = ENOTTY; break; }
            if (size.ws_col != f->size.ws_col || size.ws_row != f->size.ws_row) resized_now = true;
        }
    }
    if (!code) {
        struct timespec start; clock_gettime(CLOCK_MONOTONIC, &start);
        int remaining = resized_now ? 0 : timeout;
        for (;;) {
            int result = poll(fds, (nfds_t)count, remaining > 100 ? 100 : remaining);
            if (result < 0 && errno != EINTR) { code = errno; break; }
            if (result || remaining <= 100 || requested_signal || eval_native_interrupted()) break;
            struct timespec now; clock_gettime(CLOCK_MONOTONIC, &now);
            int64_t elapsed = (now.tv_sec - start.tv_sec) * INT64_C(1000) + (now.tv_nsec - start.tv_nsec) / 1000000;
            remaining = elapsed >= timeout ? 0 : timeout - (int)elapsed;
        }
    }
    size_t found = 0;
    for (size_t i = 0; !code && i < count; ++i) {
        if (!cetta_native_handle_use_is_current(&uses[i])) { code = ESTALE; break; }
        HostFd *f = cetta_native_handle_use_resource(&uses[i]);
        Atom *pair = requests->expr.elems[i]; const char *interest = text(pair->expr.elems[1]);
        bool available = fds[i].revents != 0;
        if (!strcmp(interest, "resize")) {
            struct winsize size;
            available = !ioctl(f->fd, TIOCGWINSZ, &size) &&
                (size.ws_col != f->size.ws_col || size.ws_row != f->size.ws_row);
        }
        if (available) ready[found++] = pair;
    }
    Atom *answer = code ? failure(a, "wait", code)
        : term(a, "HostReady", (Atom *[]){atom_expr(a, ready, (uint32_t)found)}, 1u);
    for (size_t i = 0; i < count; ++i) (void)cetta_native_handle_use_release(&uses[i]);
    free(fds); free(uses); free(ready); return answer;
}

/* One caller-validated, immutable line/reply pair may be served while waiting.
 * This is byte transport, not request interpretation. A mismatch, partial
 * frame, pending write, or other ready owner returns control to the caller.
 * At most eight peers are accepted per invocation, within the original wait
 * budget. The ordinary wait path and its cost remain unchanged. */
static int64_t host_monotonic_ns(void) {
    struct timespec now; clock_gettime(CLOCK_MONOTONIC, &now);
    return (int64_t)now.tv_sec * INT64_C(1000000000) + now.tv_nsec;
}
static Atom *wait_reply(CettaLibraryContext *ctx, Arena *a, Atom *listener_atom,
                        Atom *requests, Atom *mapping, int timeout) {
    const char *request, *reply; size_t request_length, reply_length;
    if (!requests || requests->kind != ATOM_EXPR || requests->expr.len > 65536u ||
        !mapping || mapping->kind != ATOM_EXPR || mapping->expr.len != 3u ||
        !atom_is_symbol(mapping->expr.elems[0], "HostReplyV1") ||
        !string_bytes(mapping->expr.elems[1], &request, &request_length) ||
        !string_bytes(mapping->expr.elems[2], &reply, &reply_length) ||
        !request_length || request_length > 4096u || request[request_length - 1u] != '\n' ||
        memchr(request, '\n', request_length - 1u) || !reply_length || reply_length > 1048576u)
        return failure(a, "wait-reply", EINVAL);
    size_t count = requests->expr.len, listener_index = count;
    struct pollfd *fds = calloc(count + 1u, sizeof(*fds));
    CettaNativeHandleUse *uses = calloc(count + 1u, sizeof(*uses));
    Atom **ready = malloc((count + 1u) * sizeof(*ready));
    if (!fds || !uses || !ready) {
        free(fds); free(uses); free(ready); return failure(a, "wait-reply", ENOMEM);
    }
    CettaNativeHandleUse listener_use = {0};
    HostFd *listener = acquire_fd(ctx, listener_atom, &listener_use, CETTA_NATIVE_HANDLE_USE_EXCLUSIVE);
    int code = listener && listener->kind == HOST_LISTENER ? 0 : EBADF;
    for (size_t i = 0; !code && i < count; ++i) {
        Atom *pair = requests->expr.elems[i];
        const char *interest = pair && pair->kind == ATOM_EXPR && pair->expr.len == 2u ? text(pair->expr.elems[1]) : NULL;
        HostFd *f = interest ? acquire_fd(ctx, pair->expr.elems[0], &uses[i], CETTA_NATIVE_HANDLE_USE_LIFETIME) : NULL;
        if (!f || (strcmp(interest, "read") && strcmp(interest, "write"))) { code = EINVAL; break; }
        fds[i].fd = f->fd; fds[i].events = !strcmp(interest, "read") ? POLLIN : POLLOUT;
        if (f == listener && !strcmp(interest, "read")) listener_index = i;
    }
    if (!code && listener_index == count) code = EINVAL;
    int64_t deadline = host_monotonic_ns() + (int64_t)timeout * 1000000;
    unsigned accepted = 0; int incoming = -1; struct ucred peer = {0};
    int64_t accepted_at = 0; size_t used = 0; char bytes[4096];
    Atom *answer = NULL;
    while (!code) {
        int64_t left = deadline - host_monotonic_ns();
        int remaining = left <= 0 ? 0 : (int)((left + 999999) / 1000000);
        fds[count] = (struct pollfd){.fd = incoming, .events = POLLIN};
        bool had_incoming = incoming >= 0;
        int polled = poll(fds, (nfds_t)(count + had_incoming), remaining > 100 ? 100 : remaining);
        if (polled < 0 && errno != EINTR) { code = errno; break; }
        for (size_t i = 0; i < count; ++i)
            if (!cetta_native_handle_use_is_current(&uses[i])) { code = ESTALE; break; }
        if (!code && !cetta_native_handle_use_is_current(&listener_use)) code = ESTALE;
        if (code) break;
        bool other_ready = had_incoming && fds[listener_index].revents;
        for (size_t i = 0; i < count; ++i)
            if (i != listener_index && fds[i].revents) other_ready = true;
        if (incoming < 0 && !other_ready && fds[listener_index].revents &&
            !requested_signal && !eval_native_interrupted()) {
            incoming = accept4(listener->fd, NULL, NULL, SOCK_CLOEXEC | SOCK_NONBLOCK);
            if (incoming >= 0) {
                incoming = owned_descriptor(incoming);
                if (incoming < 0) { code = errno; break; }
                ++accepted; accepted_at = host_monotonic_ns(); used = 0;
                socklen_t length = sizeof(peer);
                if (getsockopt(incoming, SOL_SOCKET, SO_PEERCRED, &peer, &length)) { code = errno; break; }
                if (peer.uid != geteuid()) { close(incoming); incoming = -1; }
            } else if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) { code = errno; break; }
        }
        if (incoming >= 0) {
            ssize_t got = recv(incoming, bytes + used, sizeof(bytes) - used, 0);
            if (got > 0) used += (size_t)got;
            else if (!got) { close(incoming); incoming = -1; }
            else if (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) { close(incoming); incoming = -1; }
            if (incoming >= 0) {
                const char *newline = memchr(bytes, '\n', used);
                bool exact = newline && (size_t)(newline - bytes) + 1u == request_length &&
                    !memcmp(bytes, request, request_length);
                if (exact) {
                    ssize_t sent = send(incoming, reply, reply_length, MSG_NOSIGNAL);
                    if (sent == (ssize_t)reply_length || (sent < 0 && errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR)) {
                        close(incoming); incoming = -1;
                    } else {
                        HostFd *owner = calloc(1, sizeof(*owner));
                        if (!owner) { code = ENOMEM; break; }
                        owner->fd = incoming; owner->kind = HOST_STREAM; incoming = -1;
                        Atom *handle = own_fd(ctx, a, owner);
                        if (!handle || handle->kind != ATOM_EXPR || !atom_is_symbol(handle->expr.elems[0], "NativeHandle")) { answer = handle; break; }
                        Atom *identity = term(a, "HostPeer", (Atom *[]){atom_int(a, peer.pid), atom_int(a, peer.uid), atom_int(a, peer.gid)}, 3u);
                        answer = term(a, "HostOutgoingV1", (Atom *[]){handle, identity,
                            atom_string_n(a, reply, reply_length), atom_int(a, sent > 0 ? sent : 0), atom_int(a, accepted_at)}, 5u);
                        break;
                    }
                } else if (newline || used >= request_length || memcmp(bytes, request, used) ||
                           other_ready || host_monotonic_ns() >= deadline || requested_signal || eval_native_interrupted()) {
                    HostFd *owner = calloc(1, sizeof(*owner));
                    if (!owner) { code = ENOMEM; break; }
                    owner->fd = incoming; owner->kind = HOST_STREAM; incoming = -1;
                    Atom *handle = own_fd(ctx, a, owner);
                    if (!handle || handle->kind != ATOM_EXPR || !atom_is_symbol(handle->expr.elems[0], "NativeHandle")) { answer = handle; break; }
                    Atom *identity = term(a, "HostPeer", (Atom *[]){atom_int(a, peer.pid), atom_int(a, peer.uid), atom_int(a, peer.gid)}, 3u);
                    answer = term(a, "HostIncomingV1", (Atom *[]){handle, identity,
                        atom_string_n(a, bytes, used), atom_int(a, accepted_at)}, 4u);
                    break;
                }
            }
        }
        if (incoming >= 0) continue;
        if (other_ready || (!polled && remaining <= 100) || host_monotonic_ns() >= deadline || accepted >= 8u ||
            requested_signal || eval_native_interrupted()) {
            size_t found = 0;
            for (size_t i = 0; i < count; ++i) if (fds[i].revents) ready[found++] = requests->expr.elems[i];
            answer = term(a, "HostReady", (Atom *[]){atom_expr(a, ready, (uint32_t)found)}, 1u);
            break;
        }
    }
    if (incoming >= 0) close(incoming);
    if (code) answer = failure(a, "wait-reply", code);
    for (size_t i = 0; i < count; ++i) (void)cetta_native_handle_use_release(&uses[i]);
    (void)cetta_native_handle_use_release(&listener_use);
    free(fds); free(uses); free(ready); return answer;
}
static int character_cells(uint32_t cp, size_t column) {
    if (cp == '\t') return 8 - (int)(column % 8u);
    if (cp < 32u || cp == 127u) return 0;
    return (int)CETTA_UL_WIDTH(cetta_unicode_layout_props(cp));
}
/* Validate a file without constructing its strings or arrays. Encoding follows
 * Python's binary JSON reader; non-finite literals remain compatibility data.
 * The explicit stack bounds nesting, not file size. Refusal is not validity. */
typedef struct {
    FILE *file;
    unsigned char block[65536], prefix[4];
    size_t first, last, prefix_at, prefix_length;
    uint64_t bytes;
    int encoding, error, current, unread;
    bool has_unread;
} JsonFile;
static int json_byte(JsonFile *j) {
    if (j->prefix_at < j->prefix_length) return j->prefix[j->prefix_at++];
    if (j->first == j->last) {
        j->first = 0; j->last = fread(j->block, 1, sizeof(j->block), j->file);
        if (!j->last) { if (ferror(j->file)) j->error = errno ? errno : EIO; return -1; }
        j->bytes += j->last;
    }
    return j->block[j->first++];
}
static int json_unit(JsonFile *j, int bytes, bool little) {
    uint32_t value = 0;
    for (int i = 0; i < bytes; ++i) {
        int b = json_byte(j);
        if (b < 0) { if (i) j->error = EILSEQ; return -1; }
        value |= (uint32_t)b << (8 * (little ? i : bytes - i - 1));
    }
    if (value > 0x10ffffu) { j->error = EILSEQ; return -1; }
    return (int)value;
}
static int json_character(JsonFile *j) {
    if (j->encoding) {
        int c;
        if (j->has_unread) { c = j->unread; j->has_unread = false; }
        else c = json_unit(j, j->encoding >= 3 ? 4 : 2, j->encoding == 2 || j->encoding == 4);
        if (j->encoding < 3 && c >= 0xd800 && c <= 0xdbff) {
            int next = json_unit(j, 2, j->encoding == 2);
            if (next < 0xdc00 || next > 0xdfff) {
                if (next >= 0) { j->unread = next; j->has_unread = true; }
                return c;
            }
            return 0x10000 + ((c - 0xd800) << 10) + next - 0xdc00;
        }
        return c;
    }
    int b = json_byte(j);
    if (b < 0 || b < 128) return b;
    int n = b >= 0xc2 && b <= 0xdf ? 1 : b >= 0xe0 && b <= 0xef ? 2 : b >= 0xf0 && b <= 0xf4 ? 3 : -1;
    if (n < 0) { j->error = EILSEQ; return -1; }
    uint32_t cp = (uint32_t)b & ((1u << (6 - n)) - 1u);
    for (int i = 0; i < n; ++i) {
        int c = json_byte(j);
        if (c < 0x80 || c > 0xbf) { j->error = EILSEQ; return -1; }
        cp = (cp << 6) | (unsigned)(c & 63);
    }
    if (cp < (n == 1 ? 0x80u : n == 2 ? 0x800u : 0x10000u) || cp > 0x10ffffu) {
        j->error = EILSEQ; return -1;
    }
    return (int)cp;
}
static void json_next(JsonFile *j) { j->current = json_character(j); }
static void initialize_json_file(JsonFile *j, FILE *file) {
    memset(j, 0, sizeof(*j)); j->file = file;
    j->prefix_length = fread(j->prefix, 1, sizeof(j->prefix), file); j->bytes = j->prefix_length;
    if (j->prefix_length >= 4 && !memcmp(j->prefix, "\0\0\xfe\xff", 4)) { j->encoding = 3; j->prefix_at = 4; }
    else if (j->prefix_length >= 4 && !memcmp(j->prefix, "\xff\xfe\0\0", 4)) { j->encoding = 4; j->prefix_at = 4; }
    else if (j->prefix_length >= 2 && !memcmp(j->prefix, "\xfe\xff", 2)) { j->encoding = 1; j->prefix_at = 2; }
    else if (j->prefix_length >= 2 && !memcmp(j->prefix, "\xff\xfe", 2)) { j->encoding = 2; j->prefix_at = 2; }
    else if (j->prefix_length >= 3 && !memcmp(j->prefix, "\xef\xbb\xbf", 3)) j->prefix_at = 3;
    else if (j->prefix_length >= 4 && j->prefix[0] == 0) j->encoding = j->prefix[1] == 0 ? 3 : 1;
    else if (j->prefix_length >= 4 && j->prefix[1] == 0) j->encoding = j->prefix[2] == 0 && j->prefix[3] == 0 ? 4 : 2;
    else if (j->prefix_length == 2 && j->prefix[0] == 0) j->encoding = 1;
    else if (j->prefix_length == 2 && j->prefix[1] == 0) j->encoding = 2;
}
static uint32_t buffer_character(const HostBuffer *b, size_t at) {
    unsigned char bytes[4]; size_t length = buffer_length(b), count = length - at;
    if (count > 4u) count = 4u;
    for (size_t i = 0; i < count; ++i) bytes[i] = buffer_at(b, at + i);
    uint32_t cp = 0xfffdu, width;
    (void)cetta_utf8_decode_one(bytes, count, 0, &cp, &width); return cp;
}
static Atom *edit_command(Arena *a, HostBuffer *b, const char *command) {
    if (!b->text || !command) return failure(a, "edit", EINVAL);
    size_t position = b->first, length = buffer_length(b), start = position, end = position;
    if (!strcmp(command, "left")) buffer_seek(b, previous_character(b, position));
    else if (!strcmp(command, "right")) buffer_seek(b, next_character(b, position));
    else if (!strcmp(command, "start")) buffer_seek(b, 0);
    else if (!strcmp(command, "end")) buffer_seek(b, length);
    else if (!strcmp(command, "home") || !strcmp(command, "kill-start")) {
        while (start && buffer_at(b, start - 1u) != '\n') --start;
        if (!strcmp(command, "home")) buffer_seek(b, start); else b->first = start;
    } else if (!strcmp(command, "line-end") || !strcmp(command, "kill-line")) {
        while (end < length && buffer_at(b, end) != '\n') ++end;
        if (!strcmp(command, "line-end")) buffer_seek(b, end);
        else { if (end == position && end < length) ++end; b->last += end - position; }
    } else if (!strcmp(command, "backspace")) b->first = previous_character(b, position);
    else if (!strcmp(command, "delete")) b->last += next_character(b, position) - position;
    else if (!strcmp(command, "clear")) { b->first = 0; b->last = b->capacity; }
    else if (!strcmp(command, "word-left") || !strcmp(command, "word-right") || !strcmp(command, "kill-word")) {
        bool left = strcmp(command, "word-right") != 0;
        while ((left ? position > 0 : position < length) && buffer_character(b, left ? previous_character(b, position) : position) <= 32u)
            position = left ? previous_character(b, position) : next_character(b, position);
        while ((left ? position > 0 : position < length) && buffer_character(b, left ? previous_character(b, position) : position) > 32u)
            position = left ? previous_character(b, position) : next_character(b, position);
        if (!strcmp(command, "kill-word")) b->first = position; else buffer_seek(b, position);
    } else if (!strcmp(command, "up") || !strcmp(command, "down")) {
        while (start && buffer_at(b, start - 1u) != '\n') --start;
        size_t column = 0;
        for (size_t at = start; at < position; at = next_character(b, at)) column += character_cells(buffer_character(b, at), column);
        if (!strcmp(command, "up")) {
            if (!start) return atom_symbol(a, "HostAtBoundary");
            end = start - 1u; start = end;
            while (start && buffer_at(b, start - 1u) != '\n') --start;
        } else {
            end = position; while (end < length && buffer_at(b, end) != '\n') ++end;
            if (end == length) return atom_symbol(a, "HostAtBoundary");
            start = ++end; while (end < length && buffer_at(b, end) != '\n') ++end;
        }
        size_t at = start, width = 0;
        while (at < end) {
            size_t next = (size_t)character_cells(buffer_character(b, at), width);
            if (width + next > column) break;
            width += next; at = next_character(b, at);
        }
        buffer_seek(b, at);
    } else return failure(a, "edit", EINVAL);
    if (buffer_length(b) != length) {
        size_t changed = b->first < start ? b->first : start;
        if (changed < b->dirty) b->dirty = changed;
    }
    b->scan = 0;
    return term(a, "HostEditor", (Atom *[]){atom_int(a, (int64_t)b->first), atom_int(a, (int64_t)buffer_length(b))}, 2u);
}

#include "library_host_text.inc"
#include "library_host_input.inc"
#include "library_host_layout.inc"
#include "library_host_markdown.inc"
#include "library_host_json_cursor.inc"

bool cetta_host_io_call(CettaLibraryContext *ctx, Arena *a, Atom *head, Atom **args,
                       uint32_t nargs, CettaCallOutcome *out) {
    if (!head || head->kind != ATOM_SYMBOL || atom_symbol_current_id(head) != g_builtin_syms.lib_host_io) return false;
    if (cetta_speculative_active()) { *out = cetta_call_raised(cetta_effect_denied(a)); return true; }
    if (eval_native_interrupted()) { *out = cetta_call_interrupted(); return true; }
    const char *operation = nargs ? text(args[0]) : NULL;
    Atom *answer = NULL; int64_t value, extra;
    CettaNativeHandleUse use = {0};
    if (!operation) goto invalid;
    if (!strcmp(operation, "identity") && nargs == 1u)
        answer = term(a, "HostPeer", (Atom *[]){atom_int(a, getpid()), atom_int(a, geteuid()), atom_int(a, getegid())}, 3u);
    else if (!strcmp(operation, "signals-open") && nargs == 1u) answer = open_signals(ctx, a);
    else if (!strcmp(operation, "signal") && nargs == 2u) {
        if (cetta_native_handle_acquire_owned(ctx, signals_kind, args[1], CETTA_NATIVE_HANDLE_USE_LIFETIME, &use))
            answer = atom_int(a, requested_signal);
        else answer = failure(a, operation, EBADF);
    }
    else if ((!strcmp(operation, "listen") || !strcmp(operation, "listen-recover")) && nargs == 3u &&
        number(args[2], 1, 65536, &value)) answer = listen_local(ctx, a, text(args[1]), (int)value, !strcmp(operation, "listen-recover"));
    else if (!strcmp(operation, "terminal-open") && nargs == 2u) answer = terminal_open(ctx, a, text(args[1]));
    else if (!strcmp(operation, "watch") && nargs == 2u) answer = watch_directory(ctx, a, text(args[1]));
    else if (!strcmp(operation, "stdio") && nargs == 2u && number(args[1], 0, 2, &value)) {
        int fd = fcntl((int)value, F_DUPFD_CLOEXEC, 3);
        HostFd *f = fd >= 0 ? calloc(1, sizeof(*f)) : NULL;
        if (!f) { int code = fd < 0 ? errno : ENOMEM; if (fd >= 0) close(fd); answer = failure(a, operation, code); }
        else { f->fd = fd; f->kind = HOST_STDIO; answer = own_fd(ctx, a, f); }
    } else if (!strcmp(operation, "write-buffer") && nargs == 5u &&
             number(args[3], 0, INT_MAX, &value) && number(args[4], 1, 16777216, &extra)) {
        HostFd *f = acquire_fd(ctx, args[1], &use, CETTA_NATIVE_HANDLE_USE_EXCLUSIVE);
        CettaNativeHandleUse second = {0}; HostBuffer *b = f ? acquire_buffer(ctx, args[2], &second) : NULL;
        if (!f || !b || (size_t)value > buffer_length(b)) answer = failure(a, operation, EBADF);
        else {
            size_t offset = (size_t)value, length = buffer_length(b), take;
            const char *bytes;
            if (offset < b->first) { take = b->first - offset; bytes = (const char *)b->bytes + offset; }
            else { take = length - offset; bytes = take ? (const char *)b->bytes + b->last + offset - b->first : ""; }
            if (take > (size_t)extra) take = (size_t)extra;
            answer = write_fd(a, f, bytes, take, 0);
        }
        (void)cetta_native_handle_use_release(&second);
    } else if (!strcmp(operation, "wait-reply") && nargs == 5u && number(args[4], 0, INT_MAX, &value))
        answer = wait_reply(ctx, a, args[1], args[2], args[3], (int)value);
    else if (!strcmp(operation, "wait") && nargs == 3u && number(args[2], 0, INT_MAX, &value))
        answer = wait_ready(ctx, a, args[1], (int)value);
    else if (!strcmp(operation, "json-file") && nargs == 2u) answer = json_file(ctx, a, text(args[1]));
    else if (!strcmp(operation, "json-open") && nargs == 2u) answer = open_json_cursor(ctx, a, text(args[1]));
    else if ((!strcmp(operation, "json-step") || !strcmp(operation, "json-text")) && nargs == 3u && number(args[2], 1, 16777216, &value)) {
        if (!cetta_native_handle_acquire_owned(ctx, json_kind, args[1], CETTA_NATIVE_HANDLE_USE_EXCLUSIVE, &use)) answer = failure(a, operation, EBADF);
        else {
            HostJson *cursor = cetta_native_handle_use_resource(&use);
            answer = !strcmp(operation, "json-step") ? step_json_cursor(a, cursor, (size_t)value) : text_json_cursor(a, cursor, (size_t)value);
        }
    }
    else if (!strcmp(operation, "volume") && nargs == 2u) {
        struct statvfs volume; const char *path = text(args[1]);
        answer = !path || statvfs(path, &volume) ? failure(a, operation, path ? errno : EINVAL)
            : term(a, "HostVolume", (Atom *[]){atom_int(a, (int64_t)volume.f_blocks * volume.f_frsize),
                atom_int(a, (int64_t)volume.f_bavail * volume.f_frsize)}, 2u);
    } else if ((!strcmp(operation, "cells") || !strcmp(operation, "clean")) && nargs == 2u) {
        const char *bytes; size_t length;
        if (string_bytes(args[1], &bytes, &length)) answer = !strcmp(operation, "cells") ? cells(a, bytes, length) : clean_text(a, bytes, length);
    } else if (!strcmp(operation, "clip") && nargs == 3u && number(args[2], 0, INT_MAX, &value)) {
        const char *bytes; size_t length;
        if (string_bytes(args[1], &bytes, &length)) answer = clip_text(a, bytes, length, (size_t)value);
    } else if (!strcmp(operation, "terminal-cpr-request") && nargs == 1u) {
        answer = terminal_cpr_request(a);
    } else if (!strcmp(operation, "terminal-cpr-parse") && nargs == 2u) {
        const char *bytes; size_t length;
        if (string_bytes(args[1], &bytes, &length)) answer = terminal_cpr_parse(a, bytes, length);
    } else if (!strcmp(operation, "terminal-sync") && nargs == 2u) {
        const char *bytes; size_t length;
        if (string_bytes(args[1], &bytes, &length)) answer = terminal_sync(a, bytes, length);
    } else if (!strcmp(operation, "terminal-hyperlink") && nargs == 3u) {
        const char *url, *label; size_t url_len, label_len;
        if (string_bytes(args[1], &url, &url_len) && string_bytes(args[2], &label, &label_len))
            answer = terminal_hyperlink(a, url, url_len, label, label_len);
    } else if (!strcmp(operation, "terminal-clipboard") && nargs == 2u) {
        const char *bytes; size_t length;
        if (string_bytes(args[1], &bytes, &length)) answer = terminal_clipboard(a, bytes, length);
    } else if (!strcmp(operation, "terminal-commit") && nargs == 4u && number(args[1], 0, 65535, &value)) {
        const char *redraw; size_t redraw_len;
        if (string_bytes(args[3], &redraw, &redraw_len))
            answer = terminal_commit(a, value, args[2], redraw, redraw_len);
    } else if (!strcmp(operation, "graphemes") && nargs == 2u) {
        const char *bytes; size_t length;
        if (string_bytes(args[1], &bytes, &length)) answer = graphemes_text(a, bytes, length);
    } else if (!strcmp(operation, "text-wrap") && nargs == 7u && number(args[2], 1, 65535, &value) && text(args[5])) {
        const char *src, *ind, *hang, *ell;
        size_t src_len, ind_len, hang_len, ell_len;
        if (string_bytes(args[1], &src, &src_len) &&
            string_bytes(args[3], &ind, &ind_len) &&
            string_bytes(args[4], &hang, &hang_len) &&
            string_bytes(args[6], &ell, &ell_len)) {
            answer = text_wrap(a, src, src_len, (size_t)value, ind, ind_len, hang, hang_len, text(args[5]), ell, ell_len);
        }
    } else if (!strcmp(operation, "text-render-spans") && nargs == 3u && text(args[2])) {
        answer = text_render_spans(a, args[1], text(args[2]));
    } else if (!strcmp(operation, "markdown-parse") && nargs == 2u) {
        const char *bytes; size_t length;
        if (string_bytes(args[1], &bytes, &length)) answer = markdown_parse(a, bytes, length);
    } else if (!strcmp(operation, "buffer-new") && nargs == 3u &&
               number(args[1], 1, INT_MAX, &value) && text(args[2])) {
        const char *mode = text(args[2]);
        if (strcmp(mode, "text") && strcmp(mode, "bytes")) goto invalid;
        HostBuffer *b = calloc(1, sizeof(*b)); uint64_t id;
        if (!b) answer = failure(a, operation, ENOMEM);
        else {
            b->maximum = (size_t)value; b->text = !strcmp(mode, "text");
            if (!cetta_native_handle_alloc(ctx, buffer_kind, b, release_buffer, &id)) { release_buffer(b); answer = failure(a, operation, ENOMEM); }
            else answer = cetta_native_handle_owned_atom(ctx, a, buffer_kind, id);
        }
    } else if (nargs >= 2u && !strncmp(operation, "buffer-", 7u)) {
        HostBuffer *b = acquire_buffer(ctx, args[1], &use);
        if (!b) { answer = failure(a, operation, EBADF); goto completed; }
        const char *bytes; size_t length;
        if ((!strcmp(operation, "buffer-append") || !strcmp(operation, "buffer-insert")) && nargs == 3u &&
            string_bytes(args[2], &bytes, &length)) answer = buffer_insert(a, b, bytes, length, !strcmp(operation, "buffer-append"));
        else if (!strcmp(operation, "buffer-value") && nargs == 2u) answer = buffer_string(a, b);
        else if (!strcmp(operation, "buffer-info") && nargs == 2u)
            answer = term(a, "HostBufferInfo", (Atom *[]){atom_int(a, (int64_t)buffer_length(b)), atom_int(a, (int64_t)b->first)}, 2u);
        else if (!strcmp(operation, "buffer-viewport") && nargs == 4u &&
                 number(args[2], 1, 65536, &value) && number(args[3], 1, 65536, &extra))
            answer = viewport(a, b, (size_t)value, (size_t)extra);
        else if (!strcmp(operation, "buffer-line") && nargs == 2u) answer = buffer_line(a, b);
        else if (!strcmp(operation, "buffer-line-ready") && nargs == 2u) {
            if (b->text) answer = failure(a, operation, EINVAL);
            else {
                size_t length = buffer_length(b); buffer_seek(b, length);
                bool found = b->bytes && memchr(b->bytes + b->scan, '\n', length - b->scan);
                if (!found) b->scan = length;
                answer = atom_bool(a, found);
            }
        }
        else if (!strcmp(operation, "buffer-input-event") && nargs == 3u && text(args[2]))
            answer = strcmp(text(args[2]), "wait") && strcmp(text(args[2]), "flush")
                ? failure(a, operation, EINVAL) : input_event(a, b, !strcmp(text(args[2]), "flush"));
        else if (!strcmp(operation, "buffer-edit") && nargs == 3u) answer = edit_command(a, b, text(args[2]));
        else if (!strcmp(operation, "buffer-drop") && nargs == 3u && number(args[2], 0, INT_MAX, &value)) {
            if (b->text || (size_t)value > buffer_length(b)) answer = failure(a, operation, EINVAL);
            else {
                size_t length = buffer_length(b); buffer_seek(b, length);
                if (length > (size_t)value) memmove(b->bytes, b->bytes + value, length - (size_t)value);
                b->first = length - (size_t)value; b->last = b->capacity; b->scan = 0;
                answer = term(a, "HostBuffered", (Atom *[]){atom_int(a, (int64_t)b->first)}, 1u);
            }
        }
    } else if (!strcmp(operation, "close") && nargs == 2u) {
        uint64_t id;
        if (cetta_native_handle_get_owned(ctx, fd_kind, args[1]) && cetta_native_handle_arg(args[1], fd_kind, &id))
            answer = cetta_native_handle_close(ctx, fd_kind, id) ? atom_symbol(a, "HostClosed") : failure(a, operation, EBADF);
        else if (cetta_native_handle_get_owned(ctx, buffer_kind, args[1]) && cetta_native_handle_arg(args[1], buffer_kind, &id))
            answer = cetta_native_handle_close(ctx, buffer_kind, id) ? atom_symbol(a, "HostClosed") : failure(a, operation, EBADF);
        else if (cetta_native_handle_get_owned(ctx, signals_kind, args[1]) && cetta_native_handle_arg(args[1], signals_kind, &id))
            answer = cetta_native_handle_close(ctx, signals_kind, id) ? atom_symbol(a, "HostClosed") : failure(a, operation, EBADF);
        else if (cetta_native_handle_get_owned(ctx, json_kind, args[1]) && cetta_native_handle_arg(args[1], json_kind, &id))
            answer = cetta_native_handle_close(ctx, json_kind, id) ? atom_symbol(a, "HostClosed") : failure(a, operation, EBADF);
        else answer = failure(a, operation, EBADF);
    } else if (nargs >= 2u) {
        HostFd *f = acquire_fd(ctx, args[1], &use, CETTA_NATIVE_HANDLE_USE_EXCLUSIVE);
        if (!f) { answer = failure(a, operation, EBADF); goto completed; }
        const char *bytes; size_t length;
        if (!strcmp(operation, "accept") && nargs == 2u) answer = accept_local(ctx, a, f);
        else if (!strcmp(operation, "changes") && nargs == 2u) answer = directory_changes(a, f);
        else if (!strcmp(operation, "read") && nargs == 3u && number(args[2], 1, 16777216, &value)) answer = read_fd(a, f, (size_t)value);
        else if (!strcmp(operation, "write") && nargs == 4u && string_bytes(args[2], &bytes, &length) &&
                 number(args[3], 0, INT64_MAX, &extra)) answer = write_fd(a, f, bytes, length, (size_t)extra);
        else if (!strcmp(operation, "terminal-raw") && nargs == 3u && text(args[2]))
            answer = strcmp(text(args[2]), "on") && strcmp(text(args[2]), "off")
                ? failure(a, operation, EINVAL) : terminal_raw(a, f, !strcmp(text(args[2]), "on"));
        else if (!strcmp(operation, "terminal-size") && nargs == 2u) {
            struct winsize size;
            if (f->kind != HOST_TERMINAL || ioctl(f->fd, TIOCGWINSZ, &size)) answer = failure(a, operation, ENOTTY);
            else { f->size = size; answer = term(a, "HostSize", (Atom *[]){atom_int(a, size.ws_col), atom_int(a, size.ws_row)}, 2u); }
        }
    }
    if (answer) goto completed;
invalid:
    answer = failure(a, operation ? operation : "host-io", EINVAL);
completed:
    (void)cetta_native_handle_use_release(&use);
    *out = cetta_call_completed_value(answer); return true;
}
