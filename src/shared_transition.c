#include "shared_transition.h"

#include <pthread.h>
#include <stdatomic.h>
#include <stdlib.h>

static pthread_mutex_t g_shared_transition_mutex =
    PTHREAD_MUTEX_INITIALIZER;
_Thread_local unsigned cetta_shared_transition_scope_depth;
/* Threads inside a shared scope now: storage that reads may not see change
 * (a term universe's decoded-copy epochs) changes only while this is zero. */
_Atomic unsigned cetta_shared_transition_active_scopes;
static _Thread_local unsigned g_shared_transition_lock_depth;

void cetta_shared_transition_scope_enter(void) {
    if (cetta_shared_transition_scope_depth == (unsigned)-1)
        abort();
    if (cetta_shared_transition_scope_depth++ == 0u)
        atomic_fetch_add(&cetta_shared_transition_active_scopes, 1u);
}

void cetta_shared_transition_scope_leave(void) {
    if (cetta_shared_transition_scope_depth == 0u ||
        g_shared_transition_lock_depth != 0u) {
        abort();
    }
    if (--cetta_shared_transition_scope_depth == 0u)
        atomic_fetch_sub(&cetta_shared_transition_active_scopes, 1u);
}

bool cetta_shared_transition_guard_held_by_current_thread(void) {
    return g_shared_transition_lock_depth != 0u;
}

unsigned cetta_shared_transition_park(void) {
    unsigned depth = g_shared_transition_lock_depth;
    if (depth) {
        g_shared_transition_lock_depth = 0u;
        if (pthread_mutex_unlock(&g_shared_transition_mutex) != 0) abort();
    }
    return depth;
}

void cetta_shared_transition_resume(unsigned depth) {
    if (g_shared_transition_lock_depth != 0u) abort();
    if (depth) {
        if (pthread_mutex_lock(&g_shared_transition_mutex) != 0) abort();
        g_shared_transition_lock_depth = depth;
    }
}

void cetta_shared_transition_guard_acquire(
    CettaSharedTransitionGuard *guard) {
    if (!guard || !cetta_shared_transition_scope_active())
        return;
    if (g_shared_transition_lock_depth == (unsigned)-1)
        abort();
    if (g_shared_transition_lock_depth++ == 0u &&
        pthread_mutex_lock(&g_shared_transition_mutex) != 0) {
        abort();
    }
    guard->held = true;
}

void cetta_shared_transition_guard_release(
    CettaSharedTransitionGuard *guard) {
    if (!guard || !guard->held)
        return;
    if (g_shared_transition_lock_depth == 0u)
        abort();
    guard->held = false;
    g_shared_transition_lock_depth--;
    if (g_shared_transition_lock_depth == 0u &&
        pthread_mutex_unlock(&g_shared_transition_mutex) != 0) {
        abort();
    }
}
