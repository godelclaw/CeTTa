#define _GNU_SOURCE
#include "library.h"

#include "eval.h"
#include "mm2_lower.h"
#include "mork_space_bridge_runtime.h"
#include "native/native_modules.h"
#include "parser.h"
#include "stats.h"
#include "text_source.h"
#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#ifndef _WIN32
#include <pty.h>
#include <pwd.h>
#endif
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

extern char **environ;

enum {
    CETTA_LIBRARY_SYSTEM = 1u << 0,
    CETTA_LIBRARY_FS = 1u << 1,
    CETTA_LIBRARY_STR = 1u << 2,
    CETTA_LIBRARY_MORK = 1u << 3,
    CETTA_LIBRARY_PROCESS = 1u << 4,
    CETTA_LIBRARY_JSON = 1u << 5,
    CETTA_LIBRARY_PATCH = 1u << 6,
    CETTA_LIBRARY_GIT = 1u << 7,
    CETTA_LIBRARY_SHELL = 1u << 8
};

typedef struct {
    const char *name;
    uint32_t bit;
} CettaLibrarySpec;

static const CettaLibrarySpec CETTA_LIBRARIES[] = {
    {"system", CETTA_LIBRARY_SYSTEM},
    {"fs", CETTA_LIBRARY_FS},
    {"str", CETTA_LIBRARY_STR},
    {"mork", CETTA_LIBRARY_MORK},
    {"process", CETTA_LIBRARY_PROCESS},
    {"json", CETTA_LIBRARY_JSON},
    {"patch", CETTA_LIBRARY_PATCH},
    {"git", CETTA_LIBRARY_GIT},
    {"shell", CETTA_LIBRARY_SHELL},
};

static const char *CETTA_MM2_PROGRAM_HANDLE_KIND = "mork-program";
static const char *CETTA_MM2_CONTEXT_HANDLE_KIND = "mork-context";
static const char *CETTA_MORK_SPACE_HANDLE_KIND = "mork-space";
static const char *CETTA_MORK_CURSOR_HANDLE_KIND = "mork-cursor";
static const char *CETTA_MORK_PRODUCT_CURSOR_HANDLE_KIND = "mork-product-cursor";
static const char *CETTA_MORK_OVERLAY_CURSOR_HANDLE_KIND = "mork-overlay-cursor";
static const uint64_t CETTA_MM2_DEFAULT_RUN_STEPS = 1000000000000000ULL;

typedef struct {
    CettaMorkSpaceHandle *bridge_space;
    SpaceKind kind;
} CettaMorkSpaceResource;

typedef struct {
    CettaMorkCursorHandle *cursor;
    SpaceKind kind;
} CettaMorkCursorResource;

typedef struct {
    CettaMorkProductCursorHandle *cursor;
} CettaMorkProductCursorResource;

typedef struct {
    CettaMorkOverlayCursorHandle *cursor;
} CettaMorkOverlayCursorResource;

typedef struct {
    char *buf;
    size_t len;
    size_t cap;
} CettaStringBuf;

static uint64_t library_monotonic_ns(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) return 0;
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

static void library_mork_cursor_free_resource(void *resource);
static void library_mork_product_cursor_free_resource(void *resource);
static void library_mork_overlay_cursor_free_resource(void *resource);
static void library_mork_space_free_resource(void *resource);
static bool load_act_dump_text_into_space(CettaLibraryContext *ctx,
                                          const char *path,
                                          const uint8_t *bytes, size_t len,
                                          Space *target,
                                          Arena *persistent_arena,
                                          Arena *eval_arena,
                                          Atom **error_out);

static void cetta_sb_init(CettaStringBuf *sb) {
    sb->buf = NULL;
    sb->len = 0;
    sb->cap = 0;
}

static void cetta_sb_ensure(CettaStringBuf *sb, size_t extra) {
    size_t need = sb->len + extra + 1;
    if (need <= sb->cap) return;
    size_t next = sb->cap ? sb->cap * 2 : 64;
    while (next < need) next *= 2;
    sb->buf = cetta_realloc(sb->buf, next);
    sb->cap = next;
}

static void cetta_sb_append_n(CettaStringBuf *sb, const char *s, size_t n) {
    cetta_sb_ensure(sb, n);
    memcpy(sb->buf + sb->len, s, n);
    sb->len += n;
    sb->buf[sb->len] = '\0';
}

static void cetta_sb_append(CettaStringBuf *sb, const char *s) {
    cetta_sb_append_n(sb, s, strlen(s));
}

static void cetta_sb_append_u32_be(CettaStringBuf *sb, uint32_t value) {
    char bytes[4];
    bytes[0] = (char)((value >> 24) & 0xff);
    bytes[1] = (char)((value >> 16) & 0xff);
    bytes[2] = (char)((value >> 8) & 0xff);
    bytes[3] = (char)(value & 0xff);
    cetta_sb_append_n(sb, bytes, sizeof(bytes));
}

static void cetta_sb_free(CettaStringBuf *sb) {
    free(sb->buf);
    sb->buf = NULL;
    sb->len = 0;
    sb->cap = 0;
}

bool cetta_library_pack_mork_expr_batch(Arena *scratch, Atom **items,
                                        uint32_t item_count,
                                        uint8_t **packet_out,
                                        size_t *packet_len_out,
                                        uint64_t *packet_bytes_out,
                                        uint64_t *pack_ns_out,
                                        const char **error_out) {
    CettaStringBuf packet;
    uint64_t total_pack_ns = 0;
    uint64_t total_packet_bytes = 0;

    if (!packet_out || !packet_len_out) {
        if (error_out)
            *error_out = "missing packet output for MORK expr-byte batch";
        return false;
    }

    *packet_out = NULL;
    *packet_len_out = 0;
    if (packet_bytes_out)
        *packet_bytes_out = 0;
    if (pack_ns_out)
        *pack_ns_out = 0;
    if (error_out)
        *error_out = NULL;

    cetta_sb_init(&packet);
    for (uint32_t i = 0; i < item_count; i++) {
        uint8_t *expr_bytes = NULL;
        size_t expr_len = 0;
        const char *encode_error = NULL;
        uint64_t item_started_ns = pack_ns_out ? library_monotonic_ns() : 0;
        if (!cetta_mm2_atom_to_bridge_expr_bytes(
                scratch, items[i], &expr_bytes, &expr_len, &encode_error)) {
            free(expr_bytes);
            cetta_sb_free(&packet);
            if (error_out) {
                *error_out = encode_error ? encode_error
                                          : "MORK expr-byte lowering failed";
            }
            return false;
        }
        cetta_sb_append_u32_be(&packet, (uint32_t)expr_len);
        cetta_sb_append_n(&packet, (const char *)expr_bytes, expr_len);
        free(expr_bytes);
        total_packet_bytes += (uint64_t)expr_len + 4u;
        if (pack_ns_out) {
            uint64_t item_finished_ns = library_monotonic_ns();
            if (item_finished_ns >= item_started_ns) {
                total_pack_ns += item_finished_ns - item_started_ns;
            }
        }
    }

    *packet_out = (uint8_t *)packet.buf;
    *packet_len_out = packet.len;
    if (packet_bytes_out)
        *packet_bytes_out = total_packet_bytes;
    if (pack_ns_out)
        *pack_ns_out = total_pack_ns;
    return true;
}

static bool cetta_library_pack_mork_expr_batch_from_ids(
    Arena *scratch,
    const TermUniverse *universe,
    const AtomId *items,
    uint32_t item_count,
    uint8_t **packet_out,
    size_t *packet_len_out,
    const char **error_out
) {
    CettaStringBuf packet;

    if (!packet_out || !packet_len_out) {
        if (error_out)
            *error_out = "missing packet output for MORK expr-byte batch";
        return false;
    }

    *packet_out = NULL;
    *packet_len_out = 0;
    if (error_out)
        *error_out = NULL;

    cetta_sb_init(&packet);
    for (uint32_t i = 0; i < item_count; i++) {
        uint8_t *expr_bytes = NULL;
        size_t expr_len = 0;
        const char *encode_error = NULL;
        if (!cetta_mm2_atom_id_to_bridge_expr_bytes(
                scratch, universe, items[i], &expr_bytes, &expr_len, &encode_error)) {
            free(expr_bytes);
            cetta_sb_free(&packet);
            if (error_out) {
                *error_out = encode_error ? encode_error
                                          : "MORK expr-byte lowering failed";
            }
            return false;
        }
        cetta_sb_append_u32_be(&packet, (uint32_t)expr_len);
        cetta_sb_append_n(&packet, (const char *)expr_bytes, expr_len);
        free(expr_bytes);
    }

    *packet_out = (uint8_t *)packet.buf;
    *packet_len_out = packet.len;
    return true;
}

static bool ascii_ieq(const char *lhs, const char *rhs) {
    while (*lhs && *rhs) {
        unsigned char a = (unsigned char)*lhs;
        unsigned char b = (unsigned char)*rhs;
        if (a >= 'A' && a <= 'Z') a = (unsigned char)(a - 'A' + 'a');
        if (b >= 'A' && b <= 'Z') b = (unsigned char)(b - 'A' + 'a');
        if (a != b) return false;
        lhs++;
        rhs++;
    }
    return *lhs == '\0' && *rhs == '\0';
}

static const CettaLibrarySpec *cetta_library_lookup(const char *name) {
    size_t count = sizeof(CETTA_LIBRARIES) / sizeof(CETTA_LIBRARIES[0]);
    for (size_t i = 0; i < count; i++) {
        if (ascii_ieq(CETTA_LIBRARIES[i].name, name)) {
            return &CETTA_LIBRARIES[i];
        }
    }
    return NULL;
}

void cetta_library_context_init(CettaLibraryContext *ctx) {
    cetta_library_context_init_for_language_profile(ctx, CETTA_LANGUAGE_HE, NULL);
}

void cetta_library_context_init_for_language_profile(CettaLibraryContext *ctx,
                                                     CettaLanguageId language_id,
                                                     const CettaProfile *profile) {
    cetta_eval_session_init(&ctx->session, language_id, profile);
    term_universe_init(&ctx->term_universe);
    ctx->active_mask = 0;
    ctx->root_dir[0] = '\0';
    if (!getcwd(ctx->working_dir, sizeof(ctx->working_dir))) {
        ctx->working_dir[0] = '\0';
    }
    ctx->script_dir[0] = '\0';
    ctx->import_dir_len = 0;
    ctx->module_mount_len = 0;
    ctx->imported_file_len = 0;
    ctx->import_space_alias_len = 0;
    ctx->cmdline_arg_len = 0;
    ctx->loaded_module_len = 0;
    ctx->native_handle_len = 0;
    ctx->native_handle_next_id = 1;
    ctx->foreign_runtime = cetta_foreign_runtime_new();
}

void cetta_library_context_free(CettaLibraryContext *ctx) {
    if (!ctx) return;
    for (uint32_t i = 0; i < ctx->loaded_module_len; i++) {
        Space *space = ctx->loaded_modules[i].space;
        if (!space) continue;
        space_free(space);
        free(space);
        ctx->loaded_modules[i].space = NULL;
    }
    ctx->loaded_module_len = 0;
    term_universe_free(&ctx->term_universe);
    cetta_native_handle_cleanup_all(ctx);
    if (ctx->foreign_runtime) {
        cetta_foreign_runtime_free(ctx->foreign_runtime);
        ctx->foreign_runtime = NULL;
    }
}

void cetta_library_context_set_exec_path(CettaLibraryContext *ctx, const char *argv0) {
    char resolved[PATH_MAX];
    char *slash;

    ctx->root_dir[0] = '\0';
    if (!argv0) return;
    if (!realpath(argv0, resolved)) return;
    slash = strrchr(resolved, '/');
    if (!slash) return;
    *slash = '\0';
    snprintf(ctx->root_dir, sizeof(ctx->root_dir), "%s", resolved);
}

static void copy_parent_dir(char *dst, size_t dst_sz, const char *path) {
    size_t len;
    if (!dst_sz) return;
    if (!path || !*path) {
        snprintf(dst, dst_sz, ".");
        return;
    }
    snprintf(dst, dst_sz, "%s", path);
    len = strlen(dst);
    while (len > 1 && dst[len - 1] == '/') {
        dst[--len] = '\0';
    }
    char *slash = strrchr(dst, '/');
    if (!slash) {
        snprintf(dst, dst_sz, ".");
        return;
    }
    if (slash == dst) {
        slash[1] = '\0';
    } else {
        *slash = '\0';
    }
}

void cetta_library_context_set_script_path(CettaLibraryContext *ctx, const char *filename) {
    char resolved[PATH_MAX];

    ctx->script_dir[0] = '\0';
    if (!filename) return;
    if (!realpath(filename, resolved)) return;
    copy_parent_dir(ctx->script_dir, sizeof(ctx->script_dir), resolved);
}

void cetta_library_context_set_cli_args(CettaLibraryContext *ctx, int argc,
                                        char **argv, int arg_start) {
    if (!ctx) return;
    ctx->cmdline_arg_len = 0;
    if (!argv || argc <= 0) return;
    if (arg_start < 0) arg_start = 0;
    for (int i = arg_start; i < argc &&
                          ctx->cmdline_arg_len < CETTA_MAX_CMDLINE_ARGS; i++) {
        ctx->cmdline_args[ctx->cmdline_arg_len++] = argv[i];
    }
}

static const char *cetta_library_current_dir(CettaLibraryContext *ctx) {
    if (ctx->import_dir_len > 0) {
        return ctx->import_dirs[ctx->import_dir_len - 1];
    }
    if (ctx->script_dir[0] != '\0') {
        return ctx->script_dir;
    }
    if (ctx->working_dir[0] != '\0') {
        return ctx->working_dir;
    }
    return ".";
}

static const char *cetta_library_relative_base_dir(CettaLibraryContext *ctx) {
    if (!ctx) {
        return ".";
    }
    if (cetta_eval_session_relative_module_policy(&ctx->session) ==
            CETTA_RELATIVE_MODULE_POLICY_WORKING_DIR_ONLY &&
        ctx->working_dir[0] != '\0') {
        return ctx->working_dir;
    }
    return cetta_library_current_dir(ctx);
}

static TermUniverse *cetta_library_space_universe(CettaLibraryContext *ctx,
                                                  Arena *persistent_arena) {
    if (!ctx || !persistent_arena)
        return NULL;
    if (!ctx->term_universe.persistent_arena)
        term_universe_set_persistent_arena(&ctx->term_universe, persistent_arena);
    if (ctx->term_universe.persistent_arena != persistent_arena)
        return NULL;
    return &ctx->term_universe;
}

static bool cetta_path_strip_prefix(const char *path, const char *prefix,
                                    const char **relative_out) {
    size_t prefix_len;

    if (!path || !prefix || !*prefix) return false;
    prefix_len = strlen(prefix);
    while (prefix_len > 1 && prefix[prefix_len - 1] == '/') {
        prefix_len--;
    }
    if (strncmp(path, prefix, prefix_len) != 0) return false;
    if (path[prefix_len] == '/') {
        if (relative_out) *relative_out = path + prefix_len + 1;
        return true;
    }
    if (path[prefix_len] == '\0') {
        if (relative_out) *relative_out = ".";
        return true;
    }
    return false;
}

static const char *cetta_library_display_path(CettaLibraryContext *ctx,
                                              const char *path,
                                              char *out, size_t out_sz) {
    const char *relative = NULL;
    char cwd[PATH_MAX];

    if (!out || out_sz == 0) return path ? path : "";
    if (!path || !*path) {
        out[0] = '\0';
        return out;
    }
    if (path[0] != '/') {
        snprintf(out, out_sz, "%s", path);
        return out;
    }
    if (ctx && ctx->script_dir[0] != '\0' &&
        cetta_path_strip_prefix(path, ctx->script_dir, &relative)) {
        snprintf(out, out_sz, "%s", relative);
        return out;
    }
    if (ctx && ctx->root_dir[0] != '\0' &&
        cetta_path_strip_prefix(path, ctx->root_dir, &relative)) {
        snprintf(out, out_sz, "%s", relative);
        return out;
    }
    if (ctx && ctx->working_dir[0] != '\0' &&
        cetta_path_strip_prefix(path, ctx->working_dir, &relative)) {
        snprintf(out, out_sz, "%s", relative);
        return out;
    }
    if (getcwd(cwd, sizeof(cwd)) &&
        cetta_path_strip_prefix(path, cwd, &relative)) {
        snprintf(out, out_sz, "%s", relative);
        return out;
    }
    snprintf(out, out_sz, "%s", path);
    return out;
}

static Space *logical_import_space(CettaLibraryContext *ctx, Space *space) {
    for (uint32_t i = ctx->import_space_alias_len; i > 0; i--) {
        if (ctx->import_space_aliases[i - 1].work_space == space) {
            return ctx->import_space_aliases[i - 1].logical_space;
        }
    }
    return space;
}

static bool cetta_library_push_import_alias(CettaLibraryContext *ctx,
                                            Space *work_space,
                                            Space *logical_space) {
    if (ctx->import_space_alias_len >= CETTA_MAX_IMPORT_TRANSACTION_SPACES) {
        return false;
    }
    ctx->import_space_aliases[ctx->import_space_alias_len].work_space = work_space;
    ctx->import_space_aliases[ctx->import_space_alias_len].logical_space = logical_space;
    ctx->import_space_alias_len++;
    return true;
}

static void cetta_library_pop_import_alias(CettaLibraryContext *ctx) {
    if (ctx->import_space_alias_len > 0) {
        ctx->import_space_alias_len--;
    }
}

static void rollback_imported_files(CettaLibraryContext *ctx, uint32_t rollback_len) {
    while (ctx->imported_file_len > rollback_len) {
        ctx->imported_file_len--;
        ctx->imported_files[ctx->imported_file_len].space = NULL;
        ctx->imported_files[ctx->imported_file_len].loading = false;
        ctx->imported_files[ctx->imported_file_len].path[0] = '\0';
    }
}

static void rollback_loaded_modules(CettaLibraryContext *ctx, uint32_t rollback_len) {
    while (ctx->loaded_module_len > rollback_len) {
        ctx->loaded_module_len--;
        if (ctx->loaded_modules[ctx->loaded_module_len].space) {
            space_free(ctx->loaded_modules[ctx->loaded_module_len].space);
            free(ctx->loaded_modules[ctx->loaded_module_len].space);
            ctx->loaded_modules[ctx->loaded_module_len].space = NULL;
        }
        ctx->loaded_modules[ctx->loaded_module_len].display_name[0] = '\0';
        ctx->loaded_modules[ctx->loaded_module_len].canonical_path[0] = '\0';
        ctx->loaded_modules[ctx->loaded_module_len].format.kind = CETTA_MODULE_FORMAT_METTA;
        ctx->loaded_modules[ctx->loaded_module_len].format.foreign_backend = CETTA_FOREIGN_BACKEND_NONE;
        ctx->loaded_modules[ctx->loaded_module_len].loading = false;
    }
}

static bool module_provider_visible(const CettaLibraryContext *ctx,
                                    CettaModuleProviderKind provider_kind) {
    CettaModuleProviderFlags flag = cetta_module_provider_flag(provider_kind);
    return ctx && flag != 0 &&
           cetta_language_allows_provider_kind(ctx->session.language_id,
                                              ctx->session.profile,
                                              provider_kind) &&
           cetta_module_policy_allows(&ctx->session.module_policy, flag);
}

static bool module_mount_visible(const CettaLibraryContext *ctx,
                                 const CettaModuleMount *mount) {
    return ctx && mount &&
           module_provider_visible(ctx, mount->provider_kind) &&
           cetta_language_visible_in(ctx->session.language_id,
                                     ctx->session.profile,
                                     mount->profile_visibility_mask);
}

static bool loaded_module_visible(const CettaLibraryContext *ctx,
                                  const CettaLoadedModule *module) {
    return ctx && module && module_provider_visible(ctx, module->provider_kind);
}

static CettaModuleMount *module_mount_lookup_mutable(CettaLibraryContext *ctx,
                                                     const char *namespace_name) {
    for (uint32_t i = 0; i < ctx->module_mount_len; i++) {
        if (strcmp(ctx->module_mounts[i].namespace_name, namespace_name) == 0) {
            return &ctx->module_mounts[i];
        }
    }
    return NULL;
}

static const CettaModuleMount *module_mount_lookup_any(const CettaLibraryContext *ctx,
                                                       const char *namespace_name) {
    for (uint32_t i = 0; i < ctx->module_mount_len; i++) {
        if (strcmp(ctx->module_mounts[i].namespace_name, namespace_name) == 0) {
            return &ctx->module_mounts[i];
        }
    }
    return NULL;
}

uint32_t cetta_library_module_mount_count(const CettaLibraryContext *ctx) {
    uint32_t count = 0;
    if (!ctx) return 0;
    for (uint32_t i = 0; i < ctx->module_mount_len; i++) {
        if (module_mount_visible(ctx, &ctx->module_mounts[i])) {
            count++;
        }
    }
    return count;
}

const CettaModuleMount *cetta_library_module_mount_at(const CettaLibraryContext *ctx,
                                                      uint32_t index) {
    if (!ctx) return NULL;
    uint32_t visible = 0;
    for (uint32_t i = 0; i < ctx->module_mount_len; i++) {
        const CettaModuleMount *mount = &ctx->module_mounts[i];
        if (!module_mount_visible(ctx, mount)) continue;
        if (visible == index) return mount;
        visible++;
    }
    return NULL;
}

const CettaModuleMount *cetta_library_find_module_mount(const CettaLibraryContext *ctx,
                                                        const char *namespace_name) {
    const CettaModuleMount *mount = module_mount_lookup_any(ctx, namespace_name);
    if (!module_mount_visible(ctx, mount)) {
        return NULL;
    }
    return mount;
}

uint32_t cetta_library_loaded_module_count(const CettaLibraryContext *ctx) {
    uint32_t count = 0;
    if (!ctx) return 0;
    for (uint32_t i = 0; i < ctx->loaded_module_len; i++) {
        if (loaded_module_visible(ctx, &ctx->loaded_modules[i])) {
            count++;
        }
    }
    return count;
}

const CettaLoadedModule *cetta_library_loaded_module_at(const CettaLibraryContext *ctx,
                                                        uint32_t index) {
    if (!ctx) return NULL;
    uint32_t visible = 0;
    for (uint32_t i = 0; i < ctx->loaded_module_len; i++) {
        const CettaLoadedModule *module = &ctx->loaded_modules[i];
        if (!loaded_module_visible(ctx, module)) continue;
        if (visible == index) return module;
        visible++;
    }
    return NULL;
}

static void cetta_library_push_dir(CettaLibraryContext *ctx, const char *dir) {
    if (ctx->import_dir_len >= CETTA_MAX_IMPORT_DIR_DEPTH) return;
    snprintf(ctx->import_dirs[ctx->import_dir_len],
             sizeof(ctx->import_dirs[ctx->import_dir_len]), "%s", dir);
    ctx->import_dir_len++;
}

static void cetta_library_pop_dir(CettaLibraryContext *ctx) {
    if (ctx->import_dir_len > 0) ctx->import_dir_len--;
}

static bool path_has_suffix(const char *path, const char *suffix);
static CettaLoadedModule *loaded_module_lookup(CettaLibraryContext *ctx,
                                               const char *canonical_path);
static CettaLoadedModule *remember_loaded_module(CettaLibraryContext *ctx,
                                                 const CettaImportPlan *plan,
                                                 Space *space,
                                                 Arena *eval_arena,
                                                 Atom **error_out);

static bool module_name_is_legal(const char *name) {
    if (!name || !*name) return false;
    for (const unsigned char *p = (const unsigned char *)name; *p; p++) {
        bool alpha = (*p >= 'A' && *p <= 'Z') || (*p >= 'a' && *p <= 'z');
        bool digit = (*p >= '0' && *p <= '9');
        if (!(alpha || digit || *p == '_' || *p == '-')) return false;
    }
    return true;
}

static bool module_spec_looks_like_relative_path(const char *spec) {
    return spec && (*spec == '.' || strchr(spec, '/') != NULL ||
                    path_has_suffix(spec, ".metta") ||
                    path_has_suffix(spec, ".act") ||
                    path_has_suffix(spec, ".mm2"));
}

static bool path_has_suffix(const char *path, const char *suffix) {
    size_t path_len = strlen(path);
    size_t suffix_len = strlen(suffix);
    if (path_len < suffix_len) return false;
    return strcmp(path + path_len - suffix_len, suffix) == 0;
}

static bool path_join2(char *out, size_t out_sz,
                       const char *lhs, const char *rhs) {
    int n = snprintf(out, out_sz, "%s/%s", lhs, rhs);
    return n > 0 && (size_t)n < out_sz;
}

static bool ensure_directory_path(const char *path) {
    char scratch[PATH_MAX];
    struct stat st;

    if (!path || !*path) return false;
    if (snprintf(scratch, sizeof(scratch), "%s", path) >= (int)sizeof(scratch)) {
        return false;
    }

    size_t len = strlen(scratch);
    while (len > 1 && scratch[len - 1] == '/') {
        scratch[--len] = '\0';
    }

    for (char *p = scratch + 1; *p; p++) {
        if (*p != '/') continue;
        *p = '\0';
        if (mkdir(scratch, 0777) != 0 && errno != EEXIST) {
            return false;
        }
        *p = '/';
    }

    if (mkdir(scratch, 0777) != 0 && errno != EEXIST) {
        return false;
    }
    if (stat(scratch, &st) != 0 || !S_ISDIR(st.st_mode)) {
        return false;
    }
    return true;
}

static bool remove_tree_recursive(const char *path) {
    struct stat st;
    if (lstat(path, &st) != 0) {
        return errno == ENOENT;
    }
    if (S_ISDIR(st.st_mode)) {
        DIR *dir = opendir(path);
        if (!dir) return false;
        struct dirent *entry;
        bool ok = true;
        while ((entry = readdir(dir)) != NULL) {
            if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
                continue;
            }
            char child[PATH_MAX];
            if (!path_join2(child, sizeof(child), path, entry->d_name)) {
                ok = false;
                break;
            }
            if (!remove_tree_recursive(child)) {
                ok = false;
                break;
            }
        }
        closedir(dir);
        if (!ok) return false;
        return rmdir(path) == 0;
    }
    return unlink(path) == 0;
}

static bool module_name_make_legal(const char *raw, char *out, size_t out_sz) {
    size_t wi = 0;
    bool last_was_underscore = false;
    if (!raw || !*raw || out_sz == 0) return false;
    for (const unsigned char *p = (const unsigned char *)raw; *p; p++) {
        bool alpha = (*p >= 'A' && *p <= 'Z') || (*p >= 'a' && *p <= 'z');
        bool digit = (*p >= '0' && *p <= '9');
        bool keep = alpha || digit || *p == '_' || *p == '-';
        char next = keep ? (char)*p : '_';
        if (next == '_' && last_was_underscore) continue;
        if (wi + 1 >= out_sz) return false;
        out[wi++] = next;
        last_was_underscore = (next == '_');
    }
    while (wi > 0 && out[wi - 1] == '_') {
        wi--;
    }
    if (wi == 0) return false;
    out[wi] = '\0';
    return true;
}

static bool git_module_name_from_url(const char *url, char *out, size_t out_sz) {
    char trimmed[PATH_MAX];
    if (!url || !*url) return false;
    if (snprintf(trimmed, sizeof(trimmed), "%s", url) >= (int)sizeof(trimmed)) {
        return false;
    }

    size_t len = strlen(trimmed);
    while (len > 0 && trimmed[len - 1] == '/') {
        trimmed[--len] = '\0';
    }
    if (len >= 4 && strcmp(trimmed + len - 4, ".git") == 0) {
        trimmed[len - 4] = '\0';
    }

    const char *base = strrchr(trimmed, '/');
    const char *name = base ? base + 1 : trimmed;
    return module_name_make_legal(name, out, out_sz);
}

static uint64_t stable_fnv1a64(const char *text) {
    uint64_t hash = 1469598103934665603ULL;
    for (const unsigned char *p = (const unsigned char *)text; *p; p++) {
        hash ^= (uint64_t)(*p);
        hash *= 1099511628211ULL;
    }
    return hash;
}

static bool git_cache_entry_valid(const char *path) {
    char git_marker[PATH_MAX];
    return path_join2(git_marker, sizeof(git_marker), path, ".git") &&
           access(git_marker, R_OK) == 0;
}

static bool git_cache_root(CettaLibraryContext *ctx, char *out, size_t out_sz,
                           Arena *eval_arena, Atom **error_out) {
    const char *override = getenv("CETTA_GIT_MODULE_CACHE_DIR");
    const char *xdg = getenv("XDG_CACHE_HOME");
    const char *home = getenv("HOME");
    char cwd[PATH_MAX];

    if (override && *override) {
        if (snprintf(out, out_sz, "%s", override) >= (int)out_sz) {
            *error_out = atom_symbol(eval_arena, "git module cache path too long");
            return false;
        }
    } else if (xdg && *xdg) {
        if (snprintf(out, out_sz, "%s/cetta/git-modules", xdg) >= (int)out_sz) {
            *error_out = atom_symbol(eval_arena, "git module cache path too long");
            return false;
        }
    } else if (home && *home) {
        if (snprintf(out, out_sz, "%s/.cache/cetta/git-modules", home) >= (int)out_sz) {
            *error_out = atom_symbol(eval_arena, "git module cache path too long");
            return false;
        }
    } else if (ctx && ctx->root_dir[0] != '\0') {
        if (snprintf(out, out_sz, "%s/runtime/git-module-cache", ctx->root_dir) >= (int)out_sz) {
            *error_out = atom_symbol(eval_arena, "git module cache path too long");
            return false;
        }
    } else if (getcwd(cwd, sizeof(cwd))) {
        if (snprintf(out, out_sz, "%s/runtime/git-module-cache", cwd) >= (int)out_sz) {
            *error_out = atom_symbol(eval_arena, "git module cache path too long");
            return false;
        }
    } else {
        *error_out = atom_symbol(eval_arena, "git module cache unavailable");
        return false;
    }

    if (!ensure_directory_path(out)) {
        *error_out = atom_symbol(eval_arena, "git module cache unavailable");
        return false;
    }
    return true;
}

static bool run_git_clone(const char *url, const char *dst,
                          char *errbuf, size_t errbuf_sz) {
    int pipefd[2];
    if (pipe(pipefd) != 0) {
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to create pipe");
        return false;
    }

    pid_t pid = fork();
    if (pid < 0) {
        close(pipefd[0]);
        close(pipefd[1]);
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to spawn git");
        return false;
    }

    if (pid == 0) {
        setenv("GIT_TERMINAL_PROMPT", "0", 1);
        dup2(pipefd[1], STDOUT_FILENO);
        dup2(pipefd[1], STDERR_FILENO);
        close(pipefd[0]);
        close(pipefd[1]);
        char *const argv[] = {
            "git", "-c", "protocol.file.allow=always",
            "clone", "--depth", "1",
            (char *)url, (char *)dst,
            NULL
        };
        execvp("git", argv);
        _exit(127);
    }

    close(pipefd[1]);
    if (errbuf_sz > 0) errbuf[0] = '\0';
    size_t used = 0;
    ssize_t got = 0;
    while ((got = read(pipefd[0], errbuf + used,
                       errbuf_sz > used + 1 ? errbuf_sz - used - 1 : 0)) > 0) {
        used += (size_t)got;
        if (errbuf_sz <= used + 1) break;
    }
    close(pipefd[0]);
    if (errbuf_sz > 0) errbuf[used] = '\0';

    int status = 0;
    if (waitpid(pid, &status, 0) < 0) {
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to wait for git");
        return false;
    }
    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
        return true;
    }
    if (WIFEXITED(status) && WEXITSTATUS(status) == 127) {
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git executable not found");
        return false;
    }
    if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to clone repository");
    return false;
}

static bool run_git_try_fetch_latest(const char *repo_path,
                                     char *errbuf, size_t errbuf_sz) {
    int pipefd[2];
    if (pipe(pipefd) != 0) {
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to create pipe");
        return false;
    }

    pid_t pid = fork();
    if (pid < 0) {
        close(pipefd[0]);
        close(pipefd[1]);
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to spawn git");
        return false;
    }

    if (pid == 0) {
        setenv("GIT_TERMINAL_PROMPT", "0", 1);
        dup2(pipefd[1], STDOUT_FILENO);
        dup2(pipefd[1], STDERR_FILENO);
        close(pipefd[0]);
        close(pipefd[1]);
        char *const argv[] = {
            "git", "-C", (char *)repo_path,
            "-c", "protocol.file.allow=always",
            "fetch", "--depth", "1", "origin",
            NULL
        };
        execvp("git", argv);
        _exit(127);
    }

    close(pipefd[1]);
    if (errbuf_sz > 0) errbuf[0] = '\0';
    size_t used = 0;
    ssize_t got = 0;
    while ((got = read(pipefd[0], errbuf + used,
                       errbuf_sz > used + 1 ? errbuf_sz - used - 1 : 0)) > 0) {
        used += (size_t)got;
        if (errbuf_sz <= used + 1) break;
    }
    close(pipefd[0]);
    if (errbuf_sz > 0) errbuf[used] = '\0';

    int status = 0;
    if (waitpid(pid, &status, 0) < 0) {
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to wait for git");
        return false;
    }
    if (!(WIFEXITED(status) && WEXITSTATUS(status) == 0)) {
        return false;
    }

    if (pipe(pipefd) != 0) {
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to create pipe");
        return false;
    }

    pid = fork();
    if (pid < 0) {
        close(pipefd[0]);
        close(pipefd[1]);
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to spawn git");
        return false;
    }

    if (pid == 0) {
        setenv("GIT_TERMINAL_PROMPT", "0", 1);
        dup2(pipefd[1], STDOUT_FILENO);
        dup2(pipefd[1], STDERR_FILENO);
        close(pipefd[0]);
        close(pipefd[1]);
        char *const argv[] = {
            "git", "-C", (char *)repo_path,
            "reset", "--hard", "FETCH_HEAD",
            NULL
        };
        execvp("git", argv);
        _exit(127);
    }

    close(pipefd[1]);
    if (errbuf_sz > 0) errbuf[0] = '\0';
    used = 0;
    got = 0;
    while ((got = read(pipefd[0], errbuf + used,
                       errbuf_sz > used + 1 ? errbuf_sz - used - 1 : 0)) > 0) {
        used += (size_t)got;
        if (errbuf_sz <= used + 1) break;
    }
    close(pipefd[0]);
    if (errbuf_sz > 0) errbuf[used] = '\0';

    status = 0;
    if (waitpid(pid, &status, 0) < 0) {
        if (errbuf_sz > 0) snprintf(errbuf, errbuf_sz, "git-module! failed to wait for git");
        return false;
    }
    return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

static bool upsert_module_mount(CettaLibraryContext *ctx, const char *namespace_name,
                                const char *root_path,
                                CettaModuleProviderKind provider_kind,
                                CettaModuleLocatorKind locator_kind,
                                const char *source_locator,
                                CettaRemoteRevisionPolicy revision_policy,
                                const char *revision_value,
                                uint32_t visibility_mask,
                                Arena *eval_arena, Atom **error_out) {
    if (!module_name_is_legal(namespace_name)) {
        *error_out = atom_symbol(eval_arena, "illegal module name");
        return false;
    }
    if (strlen(namespace_name) >= CETTA_MAX_MODULE_NAMESPACE) {
        *error_out = atom_symbol(eval_arena, "module name too long");
        return false;
    }
    if (strlen(root_path) >= PATH_MAX) {
        *error_out = atom_symbol(eval_arena, "module path too long");
        return false;
    }

    CettaModuleMount *existing = module_mount_lookup_mutable(ctx, namespace_name);
    if (existing) {
        existing->provider_kind = provider_kind;
        snprintf(existing->root_path, sizeof(existing->root_path), "%s", root_path);
        existing->locator_kind = locator_kind;
        snprintf(existing->source_locator, sizeof(existing->source_locator), "%s",
                 source_locator ? source_locator : root_path);
        existing->revision_policy = revision_policy;
        snprintf(existing->revision_value, sizeof(existing->revision_value), "%s",
                 revision_value ? revision_value : "");
        existing->profile_visibility_mask = visibility_mask;
        return true;
    }

    if (ctx->module_mount_len >= CETTA_MAX_MODULE_ROOTS) {
        *error_out = atom_symbol(eval_arena, "too many module roots");
        return false;
    }

    CettaModuleMount *mount = &ctx->module_mounts[ctx->module_mount_len++];
    memset(mount, 0, sizeof(*mount));
    mount->provider_kind = provider_kind;
    snprintf(mount->namespace_name, sizeof(mount->namespace_name), "%s", namespace_name);
    snprintf(mount->root_path, sizeof(mount->root_path), "%s", root_path);
    mount->locator_kind = locator_kind;
    snprintf(mount->source_locator, sizeof(mount->source_locator), "%s",
             source_locator ? source_locator : root_path);
    mount->revision_policy = revision_policy;
    snprintf(mount->revision_value, sizeof(mount->revision_value), "%s",
             revision_value ? revision_value : "");
    mount->profile_visibility_mask = visibility_mask;
    return true;
}

static bool ensure_git_cached_repo(CettaLibraryContext *ctx, const char *url,
                                   char *module_name, size_t module_name_sz,
                                   char *root_path, size_t root_path_sz,
                                   Arena *eval_arena, Atom **error_out) {
    char cache_root[PATH_MAX];
    char final_path[PATH_MAX];
    char tmp_template[PATH_MAX];
    char clone_error[256];
    char update_error[256];
    struct stat st;
    uint64_t url_hash = stable_fnv1a64(url);

    if (!git_module_name_from_url(url, module_name, module_name_sz)) {
        *error_out = atom_symbol(eval_arena, "git-module! error extracting module name from URL");
        return false;
    }
    if (!git_cache_root(ctx, cache_root, sizeof(cache_root), eval_arena, error_out)) {
        return false;
    }
    if (snprintf(final_path, sizeof(final_path), "%s/%s-%016llx",
                 cache_root, module_name, (unsigned long long)url_hash) >= (int)sizeof(final_path)) {
        *error_out = atom_symbol(eval_arena, "git module cache path too long");
        return false;
    }

    if (stat(final_path, &st) == 0) {
        if (!S_ISDIR(st.st_mode) || !git_cache_entry_valid(final_path)) {
            *error_out = atom_symbol(eval_arena, "git module cache entry invalid");
            return false;
        }
        /* HE uses TryFetchLatest here: attempt to refresh, but keep the cached
           repo on soft failures. */
        (void)run_git_try_fetch_latest(final_path, update_error, sizeof(update_error));
        snprintf(root_path, root_path_sz, "%s", final_path);
        return true;
    }

    if (snprintf(tmp_template, sizeof(tmp_template), "%s/%s-%016llx.tmp.XXXXXX",
                 cache_root, module_name, (unsigned long long)url_hash) >= (int)sizeof(tmp_template)) {
        *error_out = atom_symbol(eval_arena, "git module cache path too long");
        return false;
    }
    if (!mkdtemp(tmp_template)) {
        *error_out = atom_symbol(eval_arena, "git module cache unavailable");
        return false;
    }

    if (!run_git_clone(url, tmp_template, clone_error, sizeof(clone_error))) {
        remove_tree_recursive(tmp_template);
        *error_out = atom_symbol(eval_arena, clone_error);
        return false;
    }

    if (rename(tmp_template, final_path) != 0) {
        if (stat(final_path, &st) == 0 && S_ISDIR(st.st_mode) && git_cache_entry_valid(final_path)) {
            remove_tree_recursive(tmp_template);
            snprintf(root_path, root_path_sz, "%s", final_path);
            return true;
        }
        remove_tree_recursive(tmp_template);
        *error_out = atom_symbol(eval_arena, "git module cache rename failed");
        return false;
    }

    snprintf(root_path, root_path_sz, "%s", final_path);
    return true;
}

static bool directory_has_visible_entries(const char *dir_path) {
    DIR *dir = opendir(dir_path);
    if (!dir) return false;
    bool found = false;
    struct dirent *ent;
    while ((ent = readdir(dir)) != NULL) {
        const char *name = ent->d_name;
        if (strcmp(name, ".") == 0 || strcmp(name, "..") == 0) continue;
        found = true;
        break;
    }
    closedir(dir);
    return found;
}

static bool resolve_module_candidate_metta(const char *candidate,
                                           char *out, size_t out_sz,
                                           char *reason, size_t reason_sz) {
    char path[PATH_MAX];
    struct stat st;

    if (reason && reason_sz > 0) reason[0] = '\0';
    snprintf(path, sizeof(path), "%s", candidate);
    if (!path_has_suffix(path, ".metta")) {
        if (stat(path, &st) != 0 || !S_ISDIR(st.st_mode)) {
            int n = snprintf(path, sizeof(path), "%s.metta", candidate);
            if (!(n > 0 && (size_t)n < sizeof(path))) return false;
        }
    }
    if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) {
        if (reason && reason_sz > 0) {
            snprintf(reason, reason_sz, "module directory missing module.metta");
        }
        if (directory_has_visible_entries(path) && reason && reason_sz > 0) {
            snprintf(reason, reason_sz,
                     "unsupported non-MeTTa module directory (missing module.metta)");
        }
        int n = snprintf(path, sizeof(path), "%s/module.metta", candidate);
        if (!(n > 0 && (size_t)n < sizeof(path))) return false;
    }
    if (access(path, R_OK) != 0) return false;
    if (!realpath(path, out)) return false;
    return strlen(out) < out_sz;
}

static bool resolve_module_candidate_act(const char *candidate,
                                         char *out, size_t out_sz,
                                         char *reason, size_t reason_sz) {
    char path[PATH_MAX];

    if (reason && reason_sz > 0) reason[0] = '\0';
    if (path_has_suffix(candidate, ".act")) {
        snprintf(path, sizeof(path), "%s", candidate);
    } else {
        int n = snprintf(path, sizeof(path), "%s.act", candidate);
        if (!(n > 0 && (size_t)n < sizeof(path))) return false;
    }
    if (access(path, R_OK) != 0) return false;
    if (!realpath(path, out)) return false;
    return strlen(out) < out_sz;
}

static bool resolve_module_candidate_mm2(const char *candidate,
                                         char *out, size_t out_sz,
                                         char *reason, size_t reason_sz) {
    char path[PATH_MAX];

    if (reason && reason_sz > 0) reason[0] = '\0';
    if (path_has_suffix(candidate, ".mm2")) {
        snprintf(path, sizeof(path), "%s", candidate);
    } else {
        int n = snprintf(path, sizeof(path), "%s.mm2", candidate);
        if (!(n > 0 && (size_t)n < sizeof(path))) return false;
    }
    if (access(path, R_OK) != 0) return false;
    if (!realpath(path, out)) return false;
    return strlen(out) < out_sz;
}

static bool resolve_module_candidate_with_format(const char *candidate,
                                                 char *out, size_t out_sz,
                                                 CettaModuleFormat *format_out,
                                                 char *reason, size_t reason_sz) {
    char metta_reason[160] = {0};
    if (resolve_module_candidate_metta(candidate, out, out_sz,
                                       metta_reason, sizeof(metta_reason))) {
        if (format_out) {
            format_out->kind = CETTA_MODULE_FORMAT_METTA;
            format_out->foreign_backend = CETTA_FOREIGN_BACKEND_NONE;
        }
        if (reason && reason_sz > 0) reason[0] = '\0';
        return true;
    }

    char foreign_reason[160] = {0};
    if (cetta_foreign_resolve_candidate(candidate, out, out_sz,
                                        format_out,
                                        foreign_reason, sizeof(foreign_reason))) {
        return true;
    }

    char act_reason[160] = {0};
    if (resolve_module_candidate_act(candidate, out, out_sz,
                                     act_reason, sizeof(act_reason))) {
        if (format_out) {
            format_out->kind = CETTA_MODULE_FORMAT_MORK_ACT;
            format_out->foreign_backend = CETTA_FOREIGN_BACKEND_NONE;
        }
        if (reason && reason_sz > 0) reason[0] = '\0';
        return true;
    }

    char mm2_reason[160] = {0};
    if (resolve_module_candidate_mm2(candidate, out, out_sz,
                                     mm2_reason, sizeof(mm2_reason))) {
        if (format_out) {
            format_out->kind = CETTA_MODULE_FORMAT_MM2;
            format_out->foreign_backend = CETTA_FOREIGN_BACKEND_NONE;
        }
        if (reason && reason_sz > 0) reason[0] = '\0';
        return true;
    }

    if (reason && reason_sz > 0) {
        const char *chosen = metta_reason[0] ? metta_reason :
                             (act_reason[0] ? act_reason :
                              (mm2_reason[0] ? mm2_reason :
                               (foreign_reason[0] ? foreign_reason : "")));
        snprintf(reason, reason_sz, "%s", chosen);
    }
    return false;
}

static bool resolve_relative_module_candidate_for_language(
    CettaLibraryContext *ctx,
    const char *path,
    char *out, size_t out_sz,
    CettaModuleFormat *format_out,
    char *reason, size_t reason_sz
) {
    char base_dir[PATH_MAX];
    char candidate[PATH_MAX];

    if (reason && reason_sz > 0) {
        reason[0] = '\0';
    }
    if (!path || !*path) {
        return false;
    }
    if (path[0] == '/') {
        return resolve_module_candidate_with_format(path, out, out_sz, format_out,
                                                    reason, reason_sz);
    }

    snprintf(base_dir, sizeof(base_dir), "%s", cetta_library_relative_base_dir(ctx));
    while (true) {
        int n = snprintf(candidate, sizeof(candidate), "%s/%s", base_dir, path);
        if (!(n > 0 && (size_t)n < sizeof(candidate))) {
            return false;
        }
        if (resolve_module_candidate_with_format(candidate, out, out_sz, format_out,
                                                 reason, reason_sz)) {
            return true;
        }
        if (cetta_eval_session_relative_module_policy(&ctx->session) !=
            CETTA_RELATIVE_MODULE_POLICY_ANCESTOR_WALK) {
            break;
        }
        char parent[PATH_MAX];
        if (!cetta_text_path_parent_dir(parent, sizeof(parent), base_dir)) {
            break;
        }
        if (strcmp(parent, base_dir) == 0) {
            break;
        }
        snprintf(base_dir, sizeof(base_dir), "%s", parent);
    }
    return false;
}

static bool build_library_path(CettaLibraryContext *ctx, const char *name,
                               char *out, size_t out_sz);

static bool parse_module_spec(const char *spec, CettaModuleSpec *out,
                              Arena *eval_arena, Atom **error_out) {
    memset(out, 0, sizeof(*out));
    if (!spec || !*spec) {
        *error_out = atom_symbol(eval_arena, "empty module name");
        return false;
    }
    if (spec[0] == '/') {
        *error_out = atom_symbol(eval_arena, "illegal module name");
        return false;
    }

    snprintf(out->raw_spec, sizeof(out->raw_spec), "%s", spec);
    const char *sep = strchr(spec, ':');
    if (!sep) {
        out->kind = module_spec_looks_like_relative_path(spec) ?
            CETTA_MODULE_SPEC_RELATIVE_FILE :
            CETTA_MODULE_SPEC_MODULE_NAME;
        snprintf(out->path_or_member, sizeof(out->path_or_member), "%s", spec);
        return true;
    }

    size_t ns_len = (size_t)(sep - spec);
    if (ns_len == 0 || ns_len >= sizeof(out->namespace_name)) {
        *error_out = atom_symbol(eval_arena, "illegal module name");
        return false;
    }
    memcpy(out->namespace_name, spec, ns_len);
    out->namespace_name[ns_len] = '\0';
    out->kind = CETTA_MODULE_SPEC_REGISTERED_ROOT;

    size_t ri = 0;
    for (const char *p = sep + 1; *p && ri + 1 < sizeof(out->path_or_member); p++) {
        out->path_or_member[ri++] = (*p == ':') ? '/' : *p;
    }
    out->path_or_member[ri] = '\0';
    return true;
}

static bool resolve_import_plan(CettaLibraryContext *ctx, const CettaModuleSpec *spec,
                                Space *logical_target_space,
                                Space *execution_target_space,
                                bool target_is_fresh,
                                CettaImportPlan *plan,
                                Arena *eval_arena, Atom **error_out) {
    char candidate[PATH_MAX];

    memset(plan, 0, sizeof(*plan));
    plan->spec = *spec;
    plan->logical_target_space = logical_target_space;
    plan->execution_target_space = execution_target_space;
    plan->target_is_fresh = target_is_fresh;
    plan->transactional = ctx->session.module_policy.transactional_imports && !target_is_fresh;
    plan->format.kind = CETTA_MODULE_FORMAT_METTA;
    plan->format.foreign_backend = CETTA_FOREIGN_BACKEND_NONE;

    switch (spec->kind) {
    case CETTA_MODULE_SPEC_REGISTERED_ROOT: {
        if (!cetta_module_policy_allows(&ctx->session.module_policy,
                                          CETTA_MODULE_PROVIDER_REGISTERED_ROOTS)) {
            *error_out = atom_symbol(eval_arena, "registered module roots disabled");
            return false;
        }
        const CettaModuleMount *mount = cetta_library_find_module_mount(ctx, spec->namespace_name);
        if (!mount) {
            *error_out = atom_symbol(eval_arena, "unknown module root");
            return false;
        }
        plan->provider_kind = mount->provider_kind;
        if (spec->path_or_member[0] == '\0') {
            int n = snprintf(candidate, sizeof(candidate), "%s", mount->root_path);
            if (!(n > 0 && (size_t)n < sizeof(candidate))) {
                *error_out = atom_symbol(eval_arena, "module path too long");
                return false;
            }
        } else {
            int n = snprintf(candidate, sizeof(candidate), "%s/%s",
                             mount->root_path, spec->path_or_member);
            if (!(n > 0 && (size_t)n < sizeof(candidate))) {
                *error_out = atom_symbol(eval_arena, "module path too long");
                return false;
            }
        }
        break;
    }
    case CETTA_MODULE_SPEC_RELATIVE_FILE: {
        if (!cetta_module_policy_allows(&ctx->session.module_policy,
                                          CETTA_MODULE_PROVIDER_RELATIVE_FILES)) {
            *error_out = atom_symbol(eval_arena, "relative module imports disabled");
            return false;
        }
        plan->provider_kind = CETTA_MODULE_PROVIDER_RELATIVE_FILE;
        char reason[160];
        if (!resolve_relative_module_candidate_for_language(
                ctx, spec->path_or_member,
                plan->canonical_path, sizeof(plan->canonical_path),
                &plan->format, reason, sizeof(reason))) {
            if (reason[0]) {
                *error_out = atom_symbol(eval_arena, reason);
            } else {
                *error_out = atom_symbol(eval_arena, "module file not found");
            }
            return false;
        }
        return true;
    }
    case CETTA_MODULE_SPEC_MODULE_NAME: {
        if (cetta_module_policy_allows(&ctx->session.module_policy,
                                         CETTA_MODULE_PROVIDER_REGISTERED_ROOTS)) {
            const CettaModuleMount *mount = cetta_library_find_module_mount(ctx, spec->path_or_member);
            if (mount) {
                plan->provider_kind = mount->provider_kind;
                int n = snprintf(candidate, sizeof(candidate), "%s", mount->root_path);
                if (!(n > 0 && (size_t)n < sizeof(candidate))) {
                    *error_out = atom_symbol(eval_arena, "module path too long");
                    return false;
                }
                break;
            }
        }
        if (cetta_module_policy_allows(&ctx->session.module_policy,
                                         CETTA_MODULE_PROVIDER_STDLIB) &&
            build_library_path(ctx, spec->path_or_member, candidate, sizeof(candidate))) {
            plan->provider_kind = CETTA_MODULE_PROVIDER_STDLIB_FILE;
            break;
        }
        if (!cetta_module_policy_allows(&ctx->session.module_policy,
                                          CETTA_MODULE_PROVIDER_RELATIVE_FILES)) {
            *error_out = atom_symbol(eval_arena, "relative module imports disabled");
            return false;
        }
        plan->provider_kind = CETTA_MODULE_PROVIDER_RELATIVE_FILE;
        if (!module_provider_visible(ctx, plan->provider_kind)) {
            *error_out = atom_symbol(eval_arena, "module provider disabled");
            return false;
        }
        char reason[160];
        if (!resolve_relative_module_candidate_for_language(
                ctx, spec->path_or_member,
                plan->canonical_path, sizeof(plan->canonical_path),
                &plan->format, reason, sizeof(reason))) {
            char *msg = arena_alloc(eval_arena,
                                    strlen("Failed to resolve module ") +
                                    strlen(spec->path_or_member) +
                                    (reason[0] ? strlen(": ") + strlen(reason) : 0) + 1);
            sprintf(msg, "Failed to resolve module %s%s%s",
                    spec->path_or_member,
                    reason[0] ? ": " : "",
                    reason[0] ? reason : "");
            *error_out = atom_symbol(eval_arena, msg);
            return false;
        }
        return true;
    }
    case CETTA_MODULE_SPEC_STDLIB:
        if (!cetta_module_policy_allows(&ctx->session.module_policy,
                                          CETTA_MODULE_PROVIDER_STDLIB)) {
            *error_out = atom_symbol(eval_arena, "stdlib module imports disabled");
            return false;
        }
        plan->provider_kind = CETTA_MODULE_PROVIDER_STDLIB_FILE;
        if (!build_library_path(ctx, spec->path_or_member, candidate, sizeof(candidate))) {
            *error_out = atom_symbol(eval_arena, "library file not found");
            return false;
        }
        break;
    }

    if (!module_provider_visible(ctx, plan->provider_kind)) {
        *error_out = atom_symbol(eval_arena, "module provider disabled");
        return false;
    }

    char reason[160];
    if (!resolve_module_candidate_with_format(candidate, plan->canonical_path,
                                              sizeof(plan->canonical_path),
                                              &plan->format,
                                              reason, sizeof(reason))) {
        if (reason[0]) {
            *error_out = atom_symbol(eval_arena, reason);
        } else {
            *error_out = atom_symbol(eval_arena, "module file not found");
        }
        return false;
    }
    return true;
}

static int imported_file_lookup(CettaLibraryContext *ctx, Space *space,
                                const char *path) {
    for (uint32_t i = 0; i < ctx->imported_file_len; i++) {
        if (ctx->imported_files[i].path[0] == '\0') continue;
        if (ctx->imported_files[i].space == space &&
            strcmp(ctx->imported_files[i].path, path) == 0) {
            return (int)i;
        }
    }
    return -1;
}

static bool build_library_path(CettaLibraryContext *ctx, const char *name,
                               char *out, size_t out_sz) {
    if (!cetta_module_policy_allows(&ctx->session.module_policy,
                                    CETTA_MODULE_PROVIDER_STDLIB)) {
        return false;
    }
    if (ctx->root_dir[0] != '\0') {
        int n = snprintf(out, out_sz, "%s/lib/%s.metta", ctx->root_dir, name);
        if (n > 0 && (size_t)n < out_sz && access(out, R_OK) == 0) return true;
    }
    {
        int n = snprintf(out, out_sz, "lib/%s.metta", name);
        if (n > 0 && (size_t)n < out_sz && access(out, R_OK) == 0) return true;
    }
    return false;
}

static bool library_starts_with(const char *s, const char *prefix) {
    if (!s || !prefix) return false;
    return strncmp(s, prefix, strlen(prefix)) == 0;
}

static bool library_mork_suffix_needs_bang(const char *suffix) {
    if (!suffix) return false;
    if (strcmp(suffix, "space_include") == 0 ||
        strcmp(suffix, "space_step") == 0 ||
        strcmp(suffix, "space_add_atom") == 0 ||
        strcmp(suffix, "space_remove_atom") == 0 ||
        strcmp(suffix, "space_dump_act") == 0 ||
        strcmp(suffix, "space_import_act") == 0) {
        return true;
    }
    if (strstr(suffix, "zipper_close") || strstr(suffix, "zipper_reset") ||
        strstr(suffix, "zipper_ascend") || strstr(suffix, "zipper_descend") ||
        strstr(suffix, "zipper_next_") || strstr(suffix, "zipper_prev_")) {
        return true;
    }
    return false;
}

static bool library_mork_public_name(const char *head_name, char *out, size_t out_sz) {
    const char *suffix = NULL;
    const char *base = NULL;
    size_t n = 0;
    bool bang = false;

    if (!head_name || !out || out_sz == 0) return false;
    if (!library_starts_with(head_name, "__cetta_lib_mork_")) return false;
    suffix = head_name + strlen("__cetta_lib_mork_");
    if (!suffix[0]) return false;

    if (strcmp(suffix, "space_new") == 0) {
        base = "new-space";
    } else if (strcmp(suffix, "space_include") == 0) {
        base = "include";
    } else if (strcmp(suffix, "space_open_act") == 0) {
        base = "open-act";
    } else if (strcmp(suffix, "space_dump_act") == 0) {
        base = "dump";
    } else if (strcmp(suffix, "space_import_act") == 0) {
        base = "load-act";
    } else if (strcmp(suffix, "space_step") == 0) {
        base = "step";
    } else if (strcmp(suffix, "space_add_atom") == 0) {
        base = "add-atom";
    } else if (strcmp(suffix, "space_remove_atom") == 0) {
        base = "remove-atom";
    } else if (strcmp(suffix, "space_atoms") == 0) {
        base = "get-atoms";
    } else if (strcmp(suffix, "space_count_atoms") == 0) {
        base = "size";
    } else if (strcmp(suffix, "space_match") == 0) {
        base = "match";
    } else if (strcmp(suffix, "restrict") == 0) {
        base = "prefix-restrict";
    }

    if (snprintf(out, out_sz, "mork:") >= (int)out_sz) return false;
    n = strlen(out);
    if (base) {
        if (snprintf(out + n, out_sz - n, "%s", base) >= (int)(out_sz - n)) {
            return false;
        }
    } else {
        size_t i = 0;
        const char *name = suffix;
        if (library_starts_with(name, "space_")) name += strlen("space_");
        while (name[i] != '\0' && n + 1 < out_sz) {
            out[n++] = (name[i] == '_') ? '-' : name[i];
            i++;
        }
        if (name[i] != '\0') return false;
        out[n] = '\0';
    }

    bang = library_mork_suffix_needs_bang(suffix);
    if (bang) {
        n = strlen(out);
        if (n + 1 >= out_sz) return false;
        out[n] = '!';
        out[n + 1] = '\0';
    }
    return true;
}

static Atom *library_call_expr(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    Atom **elems = arena_alloc(a, sizeof(Atom *) * (nargs + 1));
    elems[0] = head;
    if (head && head->kind == ATOM_SYMBOL) {
        const char *head_name = atom_name_cstr(head);
        char mork_name[192];
        if (library_mork_public_name(head_name, mork_name, sizeof(mork_name))) {
            elems[0] = atom_symbol(a, mork_name);
        }
    }
    for (uint32_t i = 0; i < nargs; i++) elems[i + 1] = args[i];
    return atom_expr(a, elems, nargs + 1);
}

static Atom *library_signature_error(Arena *a, Atom *head, Atom **args,
                                     uint32_t nargs, const char *message) {
    return atom_error(a, library_call_expr(a, head, args, nargs),
                      atom_symbol(a, message));
}

static const char *library_text_arg(Atom *arg) {
    if (!arg) return NULL;
    if (arg->kind == ATOM_SYMBOL) return atom_name_cstr(arg);
    if (arg->kind == ATOM_GROUNDED && arg->ground.gkind == GV_STRING) {
        return arg->ground.sval;
    }
    return NULL;
}

static bool library_int_arg(Atom *arg, int *out) {
    if (!arg || !out) return false;
    if (arg->kind == ATOM_GROUNDED && arg->ground.gkind == GV_INT) {
        *out = (int)arg->ground.ival;
        return true;
    }
    return false;
}

static bool library_bool_arg(Atom *arg, bool *out) {
    if (!arg || !out) return false;
    if (arg->kind == ATOM_GROUNDED && arg->ground.gkind == GV_BOOL) {
        *out = arg->ground.bval;
        return true;
    }
    if (atom_is_symbol_id(arg, g_builtin_syms.true_text)) {
        *out = true;
        return true;
    }
    if (atom_is_symbol_id(arg, g_builtin_syms.false_text)) {
        *out = false;
        return true;
    }
    return false;
}

static bool library_expr_of_texts(Atom *arg) {
    if (!arg || arg->kind != ATOM_EXPR) return false;
    for (uint32_t i = 0; i < arg->expr.len; i++) {
        if (!library_text_arg(arg->expr.elems[i])) return false;
    }
    return true;
}

static Atom *library_string_list(Arena *a, char **items, uint32_t nitems) {
    Atom **atoms = arena_alloc(a, sizeof(Atom *) * (nitems ? nitems : 1));
    for (uint32_t i = 0; i < nitems; i++) {
        atoms[i] = atom_string(a, items[i]);
    }
    return atom_expr(a, atoms, nitems);
}

static Atom *library_atoms_from_text_impl(Arena *a, const uint8_t *bytes, size_t len,
                                          Atom *call, bool quote_atoms) {
    if (!bytes || len == 0) {
        return atom_expr(a, NULL, 0);
    }
    char *text = cetta_malloc(len + 1);
    memcpy(text, bytes, len);
    text[len] = '\0';

    Atom **atoms = NULL;
    uint32_t natoms = 0;
    uint32_t cap = 0;
    size_t pos = 0;
    while (text[pos]) {
        Atom *atom = parse_sexpr(a, text, &pos);
        if (!atom) break;
        if (quote_atoms) {
            atom = atom_expr(a, (Atom *[]){
                atom_symbol_id(a, g_builtin_syms.quote),
                atom
            }, 2);
        }
        if (natoms >= cap) {
            cap = cap ? cap * 2 : 8;
            atoms = cetta_realloc(atoms, sizeof(Atom *) * cap);
        }
        atoms[natoms++] = atom;
    }
    free(text);

    if (natoms == 0) {
        free(atoms);
        return atom_expr(a, NULL, 0);
    }
    if (atoms == NULL) {
        return atom_error(a, call, atom_string(a, "MM2 dump parse failed"));
    }

    Atom **out = arena_alloc(a, sizeof(Atom *) * natoms);
    memcpy(out, atoms, sizeof(Atom *) * natoms);
    free(atoms);
    return atom_expr(a, out, natoms);
}

static Atom *library_atoms_from_text(Arena *a, const uint8_t *bytes, size_t len,
                                     Atom *call) {
    return library_atoms_from_text_impl(a, bytes, len, call, true);
}

static char *library_mm2_surface_text(Arena *a, Atom *atom) {
    if (atom && atom->kind == ATOM_EXPR && atom->expr.len == 2 &&
        atom->expr.elems[0]->kind == ATOM_SYMBOL &&
        atom_is_symbol_id(atom->expr.elems[0], g_builtin_syms.quote)) {
        atom = atom->expr.elems[1];
    }
    return cetta_mm2_atom_to_surface_string(a, atom);
}

static Atom *library_unquote_atom(Atom *atom) {
    if (atom && atom->kind == ATOM_EXPR && atom->expr.len == 2 &&
        atom->expr.elems[0]->kind == ATOM_SYMBOL &&
        atom_is_symbol_id(atom->expr.elems[0], g_builtin_syms.quote)) {
        return atom->expr.elems[1];
    }
    return atom;
}

static Atom *library_quote_atom(Arena *a, Atom *atom) {
    return atom_expr(a, (Atom *[]){
        atom_symbol_id(a, g_builtin_syms.quote),
        atom
    }, 2);
}

static bool library_resolve_current_path(CettaLibraryContext *ctx, const char *path,
                                         char *resolved, size_t resolved_sz) {
    return cetta_text_path_resolve(cetta_library_relative_base_dir(ctx), path,
                                   resolved, resolved_sz);
}

static CettaMorkProgramHandle *library_mm2_program_handle(CettaLibraryContext *ctx,
                                                          Atom *arg) {
    uint64_t id = 0;
    if (!ctx || !cetta_native_handle_arg(arg, CETTA_MM2_PROGRAM_HANDLE_KIND, &id))
        return NULL;
    return (CettaMorkProgramHandle *)cetta_native_handle_get(
        ctx, CETTA_MM2_PROGRAM_HANDLE_KIND, id);
}

static CettaMorkContextHandle *library_mm2_context_handle(CettaLibraryContext *ctx,
                                                          Atom *arg) {
    uint64_t id = 0;
    if (!ctx || !cetta_native_handle_arg(arg, CETTA_MM2_CONTEXT_HANDLE_KIND, &id))
        return NULL;
    return (CettaMorkContextHandle *)cetta_native_handle_get(
        ctx, CETTA_MM2_CONTEXT_HANDLE_KIND, id);
}

static CettaMorkCursorResource *library_mork_cursor_handle(CettaLibraryContext *ctx,
                                                           Atom *arg) {
    uint64_t id = 0;
    if (!ctx || !cetta_native_handle_arg(arg, CETTA_MORK_CURSOR_HANDLE_KIND, &id))
        return NULL;
    return (CettaMorkCursorResource *)cetta_native_handle_get(
        ctx, CETTA_MORK_CURSOR_HANDLE_KIND, id);
}

static CettaMorkProductCursorResource *library_mork_product_cursor_handle(
    CettaLibraryContext *ctx, Atom *arg) {
    uint64_t id = 0;
    if (!ctx ||
        !cetta_native_handle_arg(arg, CETTA_MORK_PRODUCT_CURSOR_HANDLE_KIND, &id))
        return NULL;
    return (CettaMorkProductCursorResource *)cetta_native_handle_get(
        ctx, CETTA_MORK_PRODUCT_CURSOR_HANDLE_KIND, id);
}

static CettaMorkOverlayCursorResource *library_mork_overlay_cursor_handle(
    CettaLibraryContext *ctx, Atom *arg) {
    uint64_t id = 0;
    if (!ctx ||
        !cetta_native_handle_arg(arg, CETTA_MORK_OVERLAY_CURSOR_HANDLE_KIND, &id))
        return NULL;
    return (CettaMorkOverlayCursorResource *)cetta_native_handle_get(
        ctx, CETTA_MORK_OVERLAY_CURSOR_HANDLE_KIND, id);
}

static Atom *library_byte_list_atom(Arena *a, const uint8_t *bytes, size_t len) {
    Atom **elems = NULL;
    if (len > 0) {
        elems = arena_alloc(a, sizeof(Atom *) * len);
        for (size_t i = 0; i < len; i++) {
            elems[i] = atom_int(a, (int64_t)bytes[i]);
        }
    }
    return atom_expr(a, elems, (uint32_t)len);
}

static Atom *library_u64_be_list_atom(Arena *a, const uint8_t *bytes, size_t len) {
    Atom **elems = NULL;
    size_t count = 0;
    if ((len % 8u) != 0u)
        return atom_expr(a, NULL, 0);
    count = len / 8u;
    if (count > 0) {
        elems = arena_alloc(a, sizeof(Atom *) * count);
        for (size_t i = 0; i < count; i++) {
            const uint8_t *p = bytes + (i * 8u);
            uint64_t value = ((uint64_t)p[0] << 56) |
                             ((uint64_t)p[1] << 48) |
                             ((uint64_t)p[2] << 40) |
                             ((uint64_t)p[3] << 32) |
                             ((uint64_t)p[4] << 24) |
                             ((uint64_t)p[5] << 16) |
                             ((uint64_t)p[6] << 8) |
                             (uint64_t)p[7];
            elems[i] = atom_int(a, (int64_t)value);
        }
    }
    return atom_expr(a, elems, (uint32_t)count);
}

static bool library_read_text_file(const char *path, CettaStringBuf *out,
                                   char *errbuf, size_t errbuf_sz) {
    FILE *fp = fopen(path, "rb");
    char chunk[4096];
    size_t nread;

    if (!fp) {
        if (errbuf && errbuf_sz > 0) {
            snprintf(errbuf, errbuf_sz, "cannot open file: %s", strerror(errno));
        }
        return false;
    }

    cetta_sb_init(out);
    while ((nread = fread(chunk, 1, sizeof(chunk), fp)) > 0) {
        cetta_sb_append_n(out, chunk, nread);
    }
    if (ferror(fp)) {
        if (errbuf && errbuf_sz > 0) {
            snprintf(errbuf, errbuf_sz, "cannot read file: %s", strerror(errno));
        }
        fclose(fp);
        cetta_sb_free(out);
        return false;
    }

    fclose(fp);
    return true;
}

static bool library_write_text_file(const char *path, const char *text, bool append,
                                    char *errbuf, size_t errbuf_sz) {
    FILE *fp = fopen(path, append ? "ab" : "wb");
    size_t len = strlen(text);

    if (!fp) {
        if (errbuf && errbuf_sz > 0) {
            snprintf(errbuf, errbuf_sz, "cannot open file: %s", strerror(errno));
        }
        return false;
    }

    if (len > 0 && fwrite(text, 1, len, fp) != len) {
        if (errbuf && errbuf_sz > 0) {
            snprintf(errbuf, errbuf_sz, "cannot write file: %s", strerror(errno));
        }
        fclose(fp);
        return false;
    }
    if (fclose(fp) != 0) {
        if (errbuf && errbuf_sz > 0) {
            snprintf(errbuf, errbuf_sz, "cannot close file: %s", strerror(errno));
        }
        return false;
    }
    return true;
}

static bool system_zero_arg_ok(Atom **args, uint32_t nargs) {
    return nargs == 0 || (nargs == 1 && args[0] && atom_is_expr(args[0]) &&
                          args[0]->expr.len == 0);
}

static Atom *system_cli_args(const CettaLibraryContext *ctx, Arena *a, Atom *head,
                             Atom **args, uint32_t nargs) {
    if (!system_zero_arg_ok(args, nargs)) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_symbol(a, "expected: (system-args)"));
    }
    Atom **items = arena_alloc(a, sizeof(Atom *) *
                                  (ctx && ctx->cmdline_arg_len ? ctx->cmdline_arg_len : 1));
    uint32_t nitems = ctx ? ctx->cmdline_arg_len : 0;
    for (uint32_t i = 0; i < nitems; i++) {
        items[i] = atom_symbol(a, ctx->cmdline_args[i]);
    }
    return atom_expr(a, items, nitems);
}

static Atom *system_cli_arg(const CettaLibraryContext *ctx, Arena *a, Atom *head,
                            Atom **args, uint32_t nargs) {
    int index = 0;
    if (nargs != 1 || !library_int_arg(args[0], &index) || index < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected non-negative integer index");
    }
    if (!ctx || (uint32_t)index >= ctx->cmdline_arg_len) {
        return atom_empty(a);
    }
    return atom_symbol(a, ctx->cmdline_args[index]);
}

static Atom *system_cli_arg_count(const CettaLibraryContext *ctx, Arena *a, Atom *head,
                                  Atom **args, uint32_t nargs) {
    if (!system_zero_arg_ok(args, nargs)) {
        return library_signature_error(a, head, args, nargs, "expected: (system-argc)");
    }
    return atom_int(a, ctx ? (int64_t)ctx->cmdline_arg_len : 0);
}

static Atom *system_has_cli_args(const CettaLibraryContext *ctx, Arena *a, Atom *head,
                                 Atom **args, uint32_t nargs) {
    if (!system_zero_arg_ok(args, nargs)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected: (system-has-args)");
    }
    return (ctx && ctx->cmdline_arg_len > 0) ? atom_true(a) : atom_false(a);
}

static Atom *system_getenv_or_default(Arena *a, Atom *head,
                                      Atom **args, uint32_t nargs) {
    const char *name;
    const char *env_value;
    if (nargs != 2 || !(name = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected env var name and default");
    }
    env_value = getenv(name);
    if (env_value) return atom_string(a, env_value);
    return atom_deep_copy(a, args[1]);
}

static Atom *system_is_flag_arg(Arena *a, Atom *head,
                                Atom **args, uint32_t nargs) {
    const char *value;
    if (nargs != 1 || !(value = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected atom/text argument");
    }
    return (value[0] == '-' && value[1] == '-') ? atom_true(a) : atom_false(a);
}

static Atom *system_exit_with_code(Arena *a, Atom *head,
                                   Atom **args, uint32_t nargs) {
    int code = 0;
    if (nargs != 1 || !library_int_arg(args[0], &code)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected integer exit code");
    }
    fflush(stdout);
    fflush(stderr);
    exit(code);
}

static Atom *system_cwd(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    char path[PATH_MAX];
    if (!system_zero_arg_ok(args, nargs)) {
        return library_signature_error(a, head, args, nargs, "expected: (system-cwd)");
    }
    if (!getcwd(path, sizeof(path))) {
        return library_signature_error(a, head, args, nargs,
                                       "cannot determine current directory");
    }
    return atom_string(a, path);
}

static Atom *cetta_library_dispatch_system(const CettaLibraryContext *ctx,
                                           Arena *a, Atom *head,
                                           Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_system_args) {
        return system_cli_args(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_system_arg) {
        return system_cli_arg(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_system_arg_count) {
        return system_cli_arg_count(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_system_has_args) {
        return system_has_cli_args(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_system_getenv_or_default) {
        return system_getenv_or_default(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_system_is_flag_arg) {
        return system_is_flag_arg(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_system_exit_with_code) {
        return system_exit_with_code(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_system_cwd) {
        return system_cwd(a, head, args, nargs);
    }
    return NULL;
}

static bool process_set_nonblocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) return false;
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0;
}

static void process_close_fd(int *fd) {
    if (*fd >= 0) {
        close(*fd);
        *fd = -1;
    }
}

static int process_exit_code_from_status(int status) {
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
    return -1;
}

static uint64_t process_duration_ms(uint64_t start_ns, uint64_t end_ns) {
    if (end_ns < start_ns) return 0;
    return (end_ns - start_ns) / 1000000ull;
}

static Atom *process_result_atom(Arena *a,
                                 int exit_code,
                                 const CettaStringBuf *stdout_buf,
                                 const CettaStringBuf *stderr_buf,
                                 const CettaStringBuf *aggregated_buf,
                                 uint64_t duration_ms,
                                 bool timed_out) {
    if (duration_ms > (uint64_t)INT64_MAX) duration_ms = (uint64_t)INT64_MAX;
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "ProcessResult"),
        atom_int(a, exit_code),
        atom_string(a, stdout_buf->buf ? stdout_buf->buf : ""),
        atom_string(a, stderr_buf->buf ? stderr_buf->buf : ""),
        atom_string(a, aggregated_buf->buf ? aggregated_buf->buf : ""),
        atom_int(a, (int64_t)duration_ms),
        timed_out ? atom_true(a) : atom_false(a),
    }, 7);
}

static void process_append_capped(CettaStringBuf *sb, const char *data, size_t len,
                                  size_t max_bytes);

static void process_append_read(int fd,
                                CettaStringBuf *stream_buf,
                                CettaStringBuf *aggregated_buf,
                                bool *open_flag,
                                size_t max_bytes) {
    char chunk[4096];
    for (;;) {
        ssize_t nread = read(fd, chunk, sizeof(chunk));
        if (nread > 0) {
            process_append_capped(stream_buf, chunk, (size_t)nread, max_bytes);
            if (aggregated_buf) {
                process_append_capped(aggregated_buf, chunk, (size_t)nread, max_bytes);
            }
            continue;
        }
        if (nread == 0) {
            *open_flag = false;
            return;
        }
        // PTY masters can report EIO during startup or after child-side state
        // transitions before output is readable. Treat it like a transient
        // no-data condition here and let waitpid-driven exit tracking decide
        // when the session is actually done.
        if (errno == EAGAIN || errno == EWOULDBLOCK ||
            errno == EINTR || errno == EIO) {
            return;
        }
        *open_flag = false;
        return;
    }
}

static void process_kill_group(pid_t pid) {
    if (pid <= 0) return;
    if (kill(-pid, SIGTERM) != 0 && errno == ESRCH) return;
    usleep(100000);
    kill(-pid, SIGKILL);
}

static void process_append_capped(CettaStringBuf *sb, const char *data, size_t len,
                                  size_t max_bytes) {
    if (max_bytes > 0) {
        if (sb->len >= max_bytes) return;
        size_t remaining = max_bytes - sb->len;
        if (len > remaining) len = remaining;
    }
    if (len > 0) cetta_sb_append_n(sb, data, len);
}

static void process_aggregate_output(CettaStringBuf *out,
                                     const CettaStringBuf *stdout_buf,
                                     const CettaStringBuf *stderr_buf,
                                     size_t max_bytes) {
    size_t stdout_len = stdout_buf->len;
    size_t stderr_len = stderr_buf->len;
    size_t total_len = stdout_len + stderr_len;

    if (max_bytes == 0 || total_len <= max_bytes) {
        if (stdout_len > 0) cetta_sb_append_n(out, stdout_buf->buf, stdout_len);
        if (stderr_len > 0) cetta_sb_append_n(out, stderr_buf->buf, stderr_len);
        return;
    }

    size_t want_stdout = stdout_len < (max_bytes / 3u) ? stdout_len : (max_bytes / 3u);
    size_t stderr_take = stderr_len < (max_bytes - want_stdout)
                         ? stderr_len
                         : (max_bytes - want_stdout);
    size_t remaining = max_bytes - want_stdout - stderr_take;
    size_t stdout_extra = stdout_len > want_stdout ? stdout_len - want_stdout : 0;
    size_t stdout_take = want_stdout + (remaining < stdout_extra ? remaining : stdout_extra);

    if (stdout_take > 0) cetta_sb_append_n(out, stdout_buf->buf, stdout_take);
    if (stderr_take > 0) cetta_sb_append_n(out, stderr_buf->buf, stderr_take);
}

typedef struct {
    const char *key;
    const char *value;
} ProcessEnvPair;

static char *process_strdup_cstr(const char *text);
static void process_close_fd(int *fd);

typedef struct {
    size_t max_bytes;
    size_t head_budget;
    size_t tail_budget;
    CettaStringBuf head;
    CettaStringBuf tail;
    size_t omitted_bytes;
} ProcessHeadTailBuffer;

typedef struct {
    int session_id;
    pid_t pid;
    bool tty;
    bool exited;
    bool stdin_open;
    int exit_code;
    int tty_fd;
    int stdout_fd;
    int stderr_fd;
    uint64_t last_used_ns;
} ProcessSession;

typedef struct {
    ProcessSession *items;
    uint32_t len;
    uint32_t cap;
} ProcessSessionStore;

static ProcessSessionStore g_process_session_store = {0};
static bool g_process_session_rng_seeded = false;

static bool process_parse_argv(Arena *a, Atom *arg, char ***argv_out);
static bool process_parse_env_pairs(Arena *a, Atom *arg,
                                    ProcessEnvPair **pairs_out,
                                    uint32_t *count_out);
static void process_apply_child_env(const ProcessEnvPair *env_pairs,
                                    uint32_t env_count);
static void process_head_tail_buffer_append(ProcessHeadTailBuffer *buffer,
                                            const char *data,
                                            size_t len);
static void process_head_tail_buffer_to_stringbuf(ProcessHeadTailBuffer *buffer,
                                                  CettaStringBuf *out);
static void process_head_tail_buffer_init(ProcessHeadTailBuffer *buffer,
                                          size_t max_bytes);
static void process_head_tail_buffer_free(ProcessHeadTailBuffer *buffer);
static void process_session_close(ProcessSession *session);
static int process_session_store_find_index(int session_id);
static void process_session_store_remove_at(uint32_t index);
static int process_session_generate_id(void);

enum {
    PROCESS_SESSION_MAX = 64,
    PROCESS_SESSION_PROTECTED_RECENT = 8,
    PROCESS_SESSION_MIN_YIELD_MS = 250,
    PROCESS_SESSION_MIN_EMPTY_WRITE_YIELD_MS = 5000,
    PROCESS_SESSION_MAX_YIELD_MS = 30000,
    PROCESS_SESSION_MAX_BACKGROUND_YIELD_MS = 300000,
};

static const char *PROCESS_STDIN_CLOSED_MESSAGE =
    "stdin is closed for this session; rerun exec_command with tty=true to keep stdin open";
static const char *PROCESS_WRITE_STDIN_FAILED_MESSAGE =
    "failed to write to stdin";

static void process_head_tail_append_read(int fd,
                                          ProcessHeadTailBuffer *stream_buf,
                                          ProcessHeadTailBuffer *aggregated_buf,
                                          bool *open_flag,
                                          bool *did_read) {
    char chunk[4096];
    for (;;) {
        ssize_t nread = read(fd, chunk, sizeof(chunk));
        if (nread > 0) {
            if (did_read) *did_read = true;
            process_head_tail_buffer_append(stream_buf, chunk, (size_t)nread);
            if (aggregated_buf) {
                process_head_tail_buffer_append(aggregated_buf, chunk, (size_t)nread);
            }
            continue;
        }
        if (nread == 0) {
            *open_flag = false;
            return;
        }
        if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) {
            return;
        }
        *open_flag = false;
        return;
    }
}

static bool process_session_has_open_fds(ProcessSession *session) {
    if (session->tty) {
        return session->tty_fd >= 0;
    }
    return session->stdout_fd >= 0 || session->stderr_fd >= 0;
}

static void process_session_update_exit_status(ProcessSession *session) {
    int status = 0;
    pid_t wait_result;
    if (!session || session->exited) return;
    for (;;) {
        wait_result = waitpid(session->pid, &status, WNOHANG);
        if (wait_result == 0) return;
        if (wait_result < 0) {
            if (errno == EINTR) continue;
            session->exited = true;
            session->exit_code = -1;
            session->stdin_open = false;
            return;
        }
        session->exited = true;
        session->exit_code = process_exit_code_from_status(status);
        session->stdin_open = false;
        return;
    }
}

static void process_session_read_available(ProcessSession *session,
                                           ProcessHeadTailBuffer *stdout_buf,
                                           ProcessHeadTailBuffer *stderr_buf,
                                           ProcessHeadTailBuffer *aggregated_buf,
                                           bool *did_read) {
    bool open_flag;
    if (!session) return;
    if (session->tty) {
        if (session->tty_fd >= 0) {
            open_flag = true;
            process_head_tail_append_read(session->tty_fd,
                                          stdout_buf,
                                          aggregated_buf,
                                          &open_flag,
                                          did_read);
            if (!open_flag) {
                process_close_fd(&session->tty_fd);
                session->stdin_open = false;
            }
        }
        return;
    }
    if (session->stdout_fd >= 0) {
        open_flag = true;
        process_head_tail_append_read(session->stdout_fd,
                                      stdout_buf,
                                      aggregated_buf,
                                      &open_flag,
                                      did_read);
        if (!open_flag) {
            process_close_fd(&session->stdout_fd);
        }
    }
    if (session->stderr_fd >= 0) {
        open_flag = true;
        process_head_tail_append_read(session->stderr_fd,
                                      stderr_buf,
                                      aggregated_buf,
                                      &open_flag,
                                      did_read);
        if (!open_flag) {
            process_close_fd(&session->stderr_fd);
        }
    }
}

static int process_session_select(ProcessSession *session, int timeout_ms) {
    fd_set readfds;
    struct timeval tv;
    int max_fd = -1;
    FD_ZERO(&readfds);
    if (session->tty) {
        if (session->tty_fd >= 0) {
            FD_SET(session->tty_fd, &readfds);
            max_fd = session->tty_fd;
        }
    } else {
        if (session->stdout_fd >= 0) {
            FD_SET(session->stdout_fd, &readfds);
            if (session->stdout_fd > max_fd) max_fd = session->stdout_fd;
        }
        if (session->stderr_fd >= 0) {
            FD_SET(session->stderr_fd, &readfds);
            if (session->stderr_fd > max_fd) max_fd = session->stderr_fd;
        }
    }
    if (max_fd < 0) return 0;
    tv.tv_sec = timeout_ms / 1000;
    tv.tv_usec = (timeout_ms % 1000) * 1000;
    return select(max_fd + 1, &readfds, NULL, NULL, &tv);
}

static bool process_write_all_fd(int fd, const char *data, size_t len) {
    size_t offset = 0;
    while (offset < len) {
        ssize_t nwritten = write(fd, data + offset, len - offset);
        if (nwritten > 0) {
            offset += (size_t)nwritten;
            continue;
        }
        if (nwritten < 0 && errno == EINTR) continue;
        if (nwritten < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
            fd_set writefds;
            FD_ZERO(&writefds);
            FD_SET(fd, &writefds);
            if (select(fd + 1, NULL, &writefds, NULL, NULL) < 0 && errno != EINTR) {
                return false;
            }
            continue;
        }
        return false;
    }
    return true;
}

static void process_session_store_ensure_cap(uint32_t want) {
    if (g_process_session_store.cap >= want) return;
    g_process_session_store.cap = g_process_session_store.cap
        ? g_process_session_store.cap * 2u
        : 8u;
    if (g_process_session_store.cap < want) {
        g_process_session_store.cap = want;
    }
    g_process_session_store.items = cetta_realloc(
        g_process_session_store.items,
        sizeof(ProcessSession) * g_process_session_store.cap);
}

static uint32_t process_session_store_find_prune_candidate(void) {
    bool protected_flags[PROCESS_SESSION_MAX];
    uint64_t chosen_recency;
    int chosen_index;
    uint64_t oldest_ns;
    int oldest_exited = -1;
    int oldest_any = -1;
    memset(protected_flags, 0, sizeof(protected_flags));
    for (uint32_t slot = 0; slot < PROCESS_SESSION_PROTECTED_RECENT; slot++) {
        chosen_index = -1;
        chosen_recency = 0;
        for (uint32_t i = 0; i < g_process_session_store.len; i++) {
            if (protected_flags[i]) continue;
            if (chosen_index < 0 ||
                g_process_session_store.items[i].last_used_ns > chosen_recency) {
                chosen_index = (int)i;
                chosen_recency = g_process_session_store.items[i].last_used_ns;
            }
        }
        if (chosen_index < 0) break;
        protected_flags[chosen_index] = true;
    }

    oldest_ns = 0;
    for (uint32_t i = 0; i < g_process_session_store.len; i++) {
        ProcessSession *session = &g_process_session_store.items[i];
        if (!protected_flags[i] &&
            (oldest_exited < 0 || session->last_used_ns < oldest_ns) &&
            session->exited) {
            oldest_exited = (int)i;
            oldest_ns = session->last_used_ns;
        }
    }
    if (oldest_exited >= 0) return (uint32_t)oldest_exited;

    oldest_ns = 0;
    for (uint32_t i = 0; i < g_process_session_store.len; i++) {
        ProcessSession *session = &g_process_session_store.items[i];
        if (!protected_flags[i] &&
            (oldest_any < 0 || session->last_used_ns < oldest_ns)) {
            oldest_any = (int)i;
            oldest_ns = session->last_used_ns;
        }
    }
    if (oldest_any >= 0) return (uint32_t)oldest_any;
    return 0;
}

static void process_session_store_prune_if_needed(void) {
    if (g_process_session_store.len < PROCESS_SESSION_MAX) return;
    process_session_store_remove_at(process_session_store_find_prune_candidate());
}

static Atom *process_session_snapshot_atom(Arena *a,
                                           bool is_running,
                                           int session_id,
                                           bool has_exit_code,
                                           int exit_code,
                                           const CettaStringBuf *stdout_buf,
                                           const CettaStringBuf *stderr_buf,
                                           const CettaStringBuf *aggregated_buf,
                                           uint64_t duration_ms) {
    if (duration_ms > (uint64_t)INT64_MAX) duration_ms = (uint64_t)INT64_MAX;
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "ProcessSessionSnapshot"),
        is_running ? atom_true(a) : atom_false(a),
        atom_int(a, is_running ? session_id : 0),
        has_exit_code ? atom_true(a) : atom_false(a),
        atom_int(a, has_exit_code ? exit_code : 0),
        atom_string(a, stdout_buf->buf ? stdout_buf->buf : ""),
        atom_string(a, stderr_buf->buf ? stderr_buf->buf : ""),
        atom_string(a, aggregated_buf->buf ? aggregated_buf->buf : ""),
        atom_int(a, (int64_t)duration_ms),
    }, 9);
}

static Atom *process_session_call_result_atom(Arena *a,
                                              bool ok,
                                              const char *error_text,
                                              Atom *snapshot) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "ProcessSessionCallResult"),
        ok ? atom_true(a) : atom_false(a),
        atom_string(a, error_text ? error_text : ""),
        snapshot ? snapshot : atom_symbol(a, "ProcessNoSessionSnapshot"),
    }, 4);
}

static bool process_spawn_session(char **argv,
                                  const char *cwd,
                                  ProcessEnvPair *env_pairs,
                                  uint32_t env_count,
                                  ProcessSession *session,
                                  bool tty,
                                  char *errbuf,
                                  size_t errbuf_sz) {
    pid_t pid;
    session->tty = tty;
    session->exited = false;
    session->stdin_open = tty;
    session->exit_code = -1;
    session->tty_fd = -1;
    session->stdout_fd = -1;
    session->stderr_fd = -1;
    session->last_used_ns = library_monotonic_ns();
#ifdef _WIN32
    snprintf(errbuf, errbuf_sz, "persistent process sessions are not implemented on Windows");
    return false;
#else
    if (tty) {
        int master_fd = -1;
        pid = forkpty(&master_fd, NULL, NULL, NULL);
        if (pid < 0) {
            snprintf(errbuf, errbuf_sz, "%s", strerror(errno));
            return false;
        }
        if (pid == 0) {
            setpgid(0, 0);
            if (cwd && cwd[0] != '\0' && chdir(cwd) != 0) {
                dprintf(STDERR_FILENO, "chdir(%s): %s\n", cwd, strerror(errno));
                _exit(125);
            }
            process_apply_child_env(env_pairs, env_count);
            execvp(argv[0], argv);
            _exit(127);
        }
        setpgid(pid, pid);
        if (!process_set_nonblocking(master_fd)) {
            process_kill_group(pid);
            close(master_fd);
            waitpid(pid, NULL, 0);
            snprintf(errbuf, errbuf_sz, "%s", strerror(errno));
            return false;
        }
        session->pid = pid;
        session->tty_fd = master_fd;
        return true;
    } else {
        int stdout_pipe[2] = {-1, -1};
        int stderr_pipe[2] = {-1, -1};
        int stdin_fd = -1;
        if (pipe(stdout_pipe) != 0 || pipe(stderr_pipe) != 0) {
            process_close_fd(&stdout_pipe[0]);
            process_close_fd(&stdout_pipe[1]);
            process_close_fd(&stderr_pipe[0]);
            process_close_fd(&stderr_pipe[1]);
            snprintf(errbuf, errbuf_sz, "%s", strerror(errno));
            return false;
        }
        pid = fork();
        if (pid < 0) {
            process_close_fd(&stdout_pipe[0]);
            process_close_fd(&stdout_pipe[1]);
            process_close_fd(&stderr_pipe[0]);
            process_close_fd(&stderr_pipe[1]);
            snprintf(errbuf, errbuf_sz, "%s", strerror(errno));
            return false;
        }
        if (pid == 0) {
            stdin_fd = open("/dev/null", O_RDONLY);
            setpgid(0, 0);
            close(stdout_pipe[0]);
            close(stderr_pipe[0]);
            if (stdin_fd >= 0) {
                if (dup2(stdin_fd, STDIN_FILENO) < 0) _exit(126);
                close(stdin_fd);
            }
            if (dup2(stdout_pipe[1], STDOUT_FILENO) < 0 ||
                dup2(stderr_pipe[1], STDERR_FILENO) < 0) {
                _exit(126);
            }
            close(stdout_pipe[1]);
            close(stderr_pipe[1]);
            if (cwd && cwd[0] != '\0' && chdir(cwd) != 0) {
                dprintf(STDERR_FILENO, "chdir(%s): %s\n", cwd, strerror(errno));
                _exit(125);
            }
            process_apply_child_env(env_pairs, env_count);
            execvp(argv[0], argv);
            _exit(127);
        }
        setpgid(pid, pid);
        process_close_fd(&stdout_pipe[1]);
        process_close_fd(&stderr_pipe[1]);
        if (!process_set_nonblocking(stdout_pipe[0]) ||
            !process_set_nonblocking(stderr_pipe[0])) {
            process_kill_group(pid);
            process_close_fd(&stdout_pipe[0]);
            process_close_fd(&stderr_pipe[0]);
            waitpid(pid, NULL, 0);
            snprintf(errbuf, errbuf_sz, "%s", strerror(errno));
            return false;
        }
        session->pid = pid;
        session->stdout_fd = stdout_pipe[0];
        session->stderr_fd = stderr_pipe[0];
        session->stdin_open = false;
        return true;
    }
#endif
}

static Atom *process_session_collect_atom(Arena *a,
                                          ProcessSession *session,
                                          int yield_ms,
                                          int max_bytes) {
    ProcessHeadTailBuffer stdout_buf;
    ProcessHeadTailBuffer stderr_buf;
    ProcessHeadTailBuffer aggregated_buf;
    uint64_t start_ns = library_monotonic_ns();
    uint64_t deadline_ns = start_ns + ((uint64_t)yield_ms * 1000000ull);
    uint64_t end_ns = start_ns;
    bool did_read;
    bool is_running;
    int select_result;

    process_head_tail_buffer_init(&stdout_buf, (size_t)max_bytes);
    process_head_tail_buffer_init(&stderr_buf, (size_t)max_bytes);
    process_head_tail_buffer_init(&aggregated_buf, (size_t)max_bytes);

    for (;;) {
        process_session_update_exit_status(session);
        did_read = false;
        process_session_read_available(session,
                                       &stdout_buf,
                                       &stderr_buf,
                                       &aggregated_buf,
                                       &did_read);
        end_ns = library_monotonic_ns();
        if (session->exited && !process_session_has_open_fds(session)) {
            break;
        }
        if (end_ns >= deadline_ns) {
            break;
        }
        if (did_read) {
            continue;
        }
        if (!process_session_has_open_fds(session)) {
            break;
        }
        select_result = process_session_select(
            session,
            (int)((deadline_ns - end_ns) / 1000000ull));
        if (select_result < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (select_result == 0) {
            break;
        }
    }

    process_session_update_exit_status(session);
    process_session_read_available(session,
                                   &stdout_buf,
                                   &stderr_buf,
                                   &aggregated_buf,
                                   NULL);
    end_ns = library_monotonic_ns();
    if (session->exited) {
        process_session_close(session);
    }
    session->last_used_ns = end_ns;
    is_running = !session->exited;

    {
        CettaStringBuf stdout_text;
        CettaStringBuf stderr_text;
        CettaStringBuf aggregated_text;
        Atom *result;
        cetta_sb_init(&stdout_text);
        cetta_sb_init(&stderr_text);
        cetta_sb_init(&aggregated_text);
        process_head_tail_buffer_to_stringbuf(&stdout_buf, &stdout_text);
        process_head_tail_buffer_to_stringbuf(&stderr_buf, &stderr_text);
        process_head_tail_buffer_to_stringbuf(&aggregated_buf, &aggregated_text);
        result = process_session_snapshot_atom(a,
                                               is_running,
                                               session->session_id,
                                               session->exited,
                                               session->exit_code,
                                               &stdout_text,
                                               &stderr_text,
                                               &aggregated_text,
                                               process_duration_ms(start_ns, end_ns));
        cetta_sb_free(&stdout_text);
        cetta_sb_free(&stderr_text);
        cetta_sb_free(&aggregated_text);
        process_head_tail_buffer_free(&stdout_buf);
        process_head_tail_buffer_free(&stderr_buf);
        process_head_tail_buffer_free(&aggregated_buf);
        return result;
    }
}

static Atom *process_open_session_cmd_cwd_env_tty_yield_cap_bytes(
    Arena *a,
    Atom *head,
    Atom **args,
    uint32_t nargs
) {
    char **argv;
    const char *cwd;
    ProcessEnvPair *env_pairs;
    uint32_t env_count = 0;
    bool tty = false;
    int yield_ms = 0;
    int max_bytes = 0;
    ProcessSession session;
    Atom *snapshot;
    char errbuf[256] = {0};

    if (nargs != 6 || !process_parse_argv(a, args[0], &argv) ||
        !(cwd = library_text_arg(args[1])) ||
        !process_parse_env_pairs(a, args[2], &env_pairs, &env_count) ||
        !library_bool_arg(args[3], &tty) ||
        !library_int_arg(args[4], &yield_ms) ||
        !library_int_arg(args[5], &max_bytes) ||
        yield_ms < 0 || max_bytes < 0) {
        return library_signature_error(
            a, head, args, nargs,
            "expected command argv, cwd, env pairs, tty bool, non-negative yield ms, and non-negative max bytes");
    }

    memset(&session, 0, sizeof(session));
    session.session_id = process_session_generate_id();
    if (!process_spawn_session(argv, cwd, env_pairs, env_count, &session, tty,
                               errbuf, sizeof(errbuf))) {
        return process_session_call_result_atom(a, false, errbuf, NULL);
    }
    snapshot = process_session_collect_atom(a, &session, yield_ms, max_bytes);
    if (!session.exited) {
        process_session_store_prune_if_needed();
        process_session_store_ensure_cap(g_process_session_store.len + 1u);
        g_process_session_store.items[g_process_session_store.len++] = session;
    }
    return process_session_call_result_atom(a, true, "", snapshot);
}

static int process_effective_write_yield_ms(const char *input, int yield_ms) {
    int time_ms = yield_ms > PROCESS_SESSION_MIN_YIELD_MS
        ? yield_ms
        : PROCESS_SESSION_MIN_YIELD_MS;
    if (input && input[0] == '\0') {
        if (time_ms < PROCESS_SESSION_MIN_EMPTY_WRITE_YIELD_MS) {
            time_ms = PROCESS_SESSION_MIN_EMPTY_WRITE_YIELD_MS;
        }
        if (time_ms > PROCESS_SESSION_MAX_BACKGROUND_YIELD_MS) {
            time_ms = PROCESS_SESSION_MAX_BACKGROUND_YIELD_MS;
        }
        return time_ms;
    }
    if (time_ms > PROCESS_SESSION_MAX_YIELD_MS) {
        time_ms = PROCESS_SESSION_MAX_YIELD_MS;
    }
    return time_ms;
}

static Atom *process_write_session_stdin_yield_cap_bytes(Arena *a,
                                                         Atom *head,
                                                         Atom **args,
                                                         uint32_t nargs) {
    int session_id = 0;
    const char *input;
    int yield_ms = 0;
    int max_bytes = 0;
    int index;
    ProcessSession *session;
    Atom *snapshot;
    char errbuf[256];

    if (nargs != 4 || !library_int_arg(args[0], &session_id) ||
        !(input = library_text_arg(args[1])) ||
        !library_int_arg(args[2], &yield_ms) ||
        !library_int_arg(args[3], &max_bytes) ||
        yield_ms < 0 || max_bytes < 0) {
        return library_signature_error(
            a, head, args, nargs,
            "expected session id, stdin chars, non-negative yield ms, and non-negative max bytes");
    }

    index = process_session_store_find_index(session_id);
    if (index < 0) {
        snprintf(errbuf, sizeof(errbuf), "Unknown process id %d", session_id);
        return process_session_call_result_atom(a, false, errbuf, NULL);
    }

    session = &g_process_session_store.items[index];
    if (input[0] != '\0') {
        if (!session->tty || !session->stdin_open || session->tty_fd < 0) {
            return process_session_call_result_atom(
                a, false, PROCESS_STDIN_CLOSED_MESSAGE, NULL);
        }
        if (!process_write_all_fd(session->tty_fd, input, strlen(input))) {
            process_session_update_exit_status(session);
            if (!session->exited) {
                return process_session_call_result_atom(
                    a, false, PROCESS_WRITE_STDIN_FAILED_MESSAGE, NULL);
            }
        } else {
            usleep(100000);
        }
    }

    snapshot = process_session_collect_atom(
        a,
        session,
        process_effective_write_yield_ms(input, yield_ms),
        max_bytes);
    if (session->exited) {
        process_session_store_remove_at((uint32_t)index);
    }
    return process_session_call_result_atom(a, true, "", snapshot);
}

static bool process_expr_head_name(Atom *atom, const char *name) {
    return atom && atom->kind == ATOM_EXPR && atom->expr.len > 0 &&
           atom->expr.elems[0]->kind == ATOM_SYMBOL &&
           strcmp(atom_name_cstr(atom->expr.elems[0]), name) == 0;
}

static bool process_valid_env_key(const char *key) {
    return key && key[0] != '\0' && strchr(key, '=') == NULL;
}

static bool process_parse_argv(Arena *a, Atom *arg, char ***argv_out) {
    char **argv;
    if (!arg || arg->kind != ATOM_EXPR || arg->expr.len == 0) return false;
    argv = arena_alloc(a, sizeof(char *) * ((size_t)arg->expr.len + 1u));
    for (uint32_t i = 0; i < arg->expr.len; i++) {
        const char *item = library_text_arg(arg->expr.elems[i]);
        if (!item || item[0] == '\0') return false;
        argv[i] = (char *)item;
    }
    argv[arg->expr.len] = NULL;
    *argv_out = argv;
    return true;
}

static bool process_parse_env_pairs(Arena *a, Atom *arg,
                                    ProcessEnvPair **pairs_out,
                                    uint32_t *count_out) {
    ProcessEnvPair *pairs;
    if (!arg || arg->kind != ATOM_EXPR) return false;
    pairs = arena_alloc(a, sizeof(ProcessEnvPair) *
                           (arg->expr.len ? arg->expr.len : 1u));
    for (uint32_t i = 0; i < arg->expr.len; i++) {
        Atom *pair = arg->expr.elems[i];
        const char *key;
        const char *value;
        if (!process_expr_head_name(pair, "Env") || pair->expr.len != 3 ||
            !(key = library_text_arg(pair->expr.elems[1])) ||
            !(value = library_text_arg(pair->expr.elems[2])) ||
            !process_valid_env_key(key)) {
            return false;
        }
        pairs[i].key = key;
        pairs[i].value = value;
    }
    *pairs_out = pairs;
    *count_out = arg->expr.len;
    return true;
}

static void process_head_tail_buffer_init(ProcessHeadTailBuffer *buffer,
                                          size_t max_bytes) {
    buffer->max_bytes = max_bytes;
    buffer->head_budget = max_bytes / 2u;
    buffer->tail_budget = max_bytes - buffer->head_budget;
    buffer->omitted_bytes = 0;
    cetta_sb_init(&buffer->head);
    cetta_sb_init(&buffer->tail);
}

static void process_head_tail_buffer_free(ProcessHeadTailBuffer *buffer) {
    cetta_sb_free(&buffer->head);
    cetta_sb_free(&buffer->tail);
    buffer->max_bytes = 0;
    buffer->head_budget = 0;
    buffer->tail_budget = 0;
    buffer->omitted_bytes = 0;
}

static void process_head_tail_tail_trim(ProcessHeadTailBuffer *buffer,
                                        size_t excess) {
    if (excess == 0 || buffer->tail.len == 0) return;
    if (excess >= buffer->tail.len) {
        buffer->omitted_bytes += buffer->tail.len;
        buffer->tail.len = 0;
        if (buffer->tail.buf) buffer->tail.buf[0] = '\0';
        return;
    }
    memmove(buffer->tail.buf, buffer->tail.buf + excess, buffer->tail.len - excess);
    buffer->tail.len -= excess;
    buffer->tail.buf[buffer->tail.len] = '\0';
    buffer->omitted_bytes += excess;
}

static void process_head_tail_buffer_append(ProcessHeadTailBuffer *buffer,
                                            const char *data,
                                            size_t len) {
    size_t head_remaining;
    size_t tail_len;
    if (len == 0) return;
    if (buffer->max_bytes == 0) {
        buffer->omitted_bytes += len;
        return;
    }
    if (buffer->head.len < buffer->head_budget) {
        head_remaining = buffer->head_budget - buffer->head.len;
        if (head_remaining > 0) {
            size_t head_take = len < head_remaining ? len : head_remaining;
            cetta_sb_append_n(&buffer->head, data, head_take);
            data += head_take;
            len -= head_take;
            if (len == 0) return;
        }
    }
    if (buffer->tail_budget == 0) {
        buffer->omitted_bytes += len;
        return;
    }
    if (len >= buffer->tail_budget) {
        size_t start = len - buffer->tail_budget;
        buffer->omitted_bytes += buffer->tail.len + start;
        buffer->tail.len = 0;
        if (buffer->tail.buf) buffer->tail.buf[0] = '\0';
        cetta_sb_append_n(&buffer->tail, data + start, buffer->tail_budget);
        return;
    }
    tail_len = buffer->tail.len + len;
    if (tail_len > buffer->tail_budget) {
        process_head_tail_tail_trim(buffer, tail_len - buffer->tail_budget);
    }
    cetta_sb_append_n(&buffer->tail, data, len);
}

static void process_head_tail_buffer_to_stringbuf(ProcessHeadTailBuffer *buffer,
                                                  CettaStringBuf *out) {
    if (buffer->head.len > 0) {
        cetta_sb_append_n(out, buffer->head.buf, buffer->head.len);
    }
    if (buffer->tail.len > 0) {
        cetta_sb_append_n(out, buffer->tail.buf, buffer->tail.len);
    }
}

static void process_session_store_seed_rng(void) {
    if (!g_process_session_rng_seeded) {
        srand((unsigned int)(time(NULL) ^ (unsigned int)getpid()));
        g_process_session_rng_seeded = true;
    }
}

static int process_session_store_find_index(int session_id) {
    for (uint32_t i = 0; i < g_process_session_store.len; i++) {
        if (g_process_session_store.items[i].session_id == session_id) {
            return (int)i;
        }
    }
    return -1;
}

static void process_session_close(ProcessSession *session) {
    if (!session) return;
    process_close_fd(&session->tty_fd);
    process_close_fd(&session->stdout_fd);
    process_close_fd(&session->stderr_fd);
    session->stdin_open = false;
}

static void process_session_store_remove_at(uint32_t index) {
    if (index >= g_process_session_store.len) return;
    process_session_close(&g_process_session_store.items[index]);
    if (index + 1u < g_process_session_store.len) {
        memmove(&g_process_session_store.items[index],
                &g_process_session_store.items[index + 1u],
                sizeof(ProcessSession) * (g_process_session_store.len - index - 1u));
    }
    g_process_session_store.len--;
}

static int process_session_generate_id(void) {
    process_session_store_seed_rng();
    for (;;) {
        int session_id = 1000 + (rand() % 99000);
        if (process_session_store_find_index(session_id) < 0) return session_id;
    }
}

typedef enum {
    PROCESS_SHELL_ZSH,
    PROCESS_SHELL_BASH,
    PROCESS_SHELL_POWERSHELL,
    PROCESS_SHELL_SH,
    PROCESS_SHELL_CMD,
    PROCESS_SHELL_UNKNOWN
} ProcessShellType;

typedef struct {
    ProcessShellType type;
    const char *path;
} ProcessShell;

static const char *process_shell_type_text(ProcessShellType type) {
    switch (type) {
        case PROCESS_SHELL_ZSH: return "zsh";
        case PROCESS_SHELL_BASH: return "bash";
        case PROCESS_SHELL_POWERSHELL: return "powershell";
        case PROCESS_SHELL_SH: return "sh";
        case PROCESS_SHELL_CMD: return "cmd";
        case PROCESS_SHELL_UNKNOWN: return "unknown";
    }
    return "unknown";
}

static bool process_parse_shell_type(const char *text, ProcessShellType *out) {
    if (!text || !out) return false;
    if (strcasecmp(text, "zsh") == 0) {
        *out = PROCESS_SHELL_ZSH;
        return true;
    }
    if (strcasecmp(text, "bash") == 0) {
        *out = PROCESS_SHELL_BASH;
        return true;
    }
    if (strcasecmp(text, "powershell") == 0 || strcasecmp(text, "pwsh") == 0) {
        *out = PROCESS_SHELL_POWERSHELL;
        return true;
    }
    if (strcasecmp(text, "sh") == 0) {
        *out = PROCESS_SHELL_SH;
        return true;
    }
    if (strcasecmp(text, "cmd") == 0) {
        *out = PROCESS_SHELL_CMD;
        return true;
    }
    return false;
}

static const char *process_path_basename(const char *path) {
    const char *slash;
    const char *backslash;
    const char *base;
    if (!path) return "";
    slash = strrchr(path, '/');
    backslash = strrchr(path, '\\');
    if (slash && (!backslash || slash > backslash)) {
        base = slash;
    } else {
        base = backslash;
    }
    return base ? base + 1 : path;
}

static void process_path_file_stem(const char *path, char *out, size_t out_sz) {
    const char *base = process_path_basename(path);
    const char *dot = NULL;
    size_t len;
    if (!out || out_sz == 0) return;
    len = strlen(base);
    for (const char *p = base + len; p > base; p--) {
        if (p[-1] == '.') {
            dot = p - 1;
            break;
        }
    }
    if (dot && dot != base) len = (size_t)(dot - base);
    if (len >= out_sz) len = out_sz - 1u;
    memcpy(out, base, len);
    out[len] = '\0';
}

static ProcessShellType process_detect_shell_type(const char *path) {
    char current[PATH_MAX];
    char stem[PATH_MAX];
    ProcessShellType type;
    if (!path || path[0] == '\0') return PROCESS_SHELL_UNKNOWN;
    snprintf(current, sizeof(current), "%s", path);
    for (int i = 0; i < 8; i++) {
        if (process_parse_shell_type(current, &type)) return type;
        process_path_file_stem(current, stem, sizeof(stem));
        if (stem[0] == '\0' || strcmp(stem, current) == 0) break;
        snprintf(current, sizeof(current), "%s", stem);
    }
    return PROCESS_SHELL_UNKNOWN;
}

static bool process_file_is_regular(const char *path) {
    struct stat st;
    return path && stat(path, &st) == 0 && S_ISREG(st.st_mode);
}

static bool process_copy_path(char *out, size_t out_sz, const char *path) {
    if (!out || out_sz == 0 || !path || path[0] == '\0') return false;
    snprintf(out, out_sz, "%s", path);
    return true;
}

static bool process_find_on_path(const char *binary, char *out, size_t out_sz) {
    const char *path_env = getenv("PATH");
    char *paths;
    char *saveptr = NULL;
    char *part;
    if (!binary || !out || out_sz == 0 || !path_env) return false;
    paths = process_strdup_cstr(path_env);
    part = strtok_r(paths, ":", &saveptr);
    while (part) {
        char candidate[PATH_MAX];
        if (part[0] != '\0') {
            snprintf(candidate, sizeof(candidate), "%s/%s", part, binary);
            if (process_file_is_regular(candidate) && access(candidate, X_OK) == 0) {
                bool ok = process_copy_path(out, out_sz, candidate);
                free(paths);
                return ok;
            }
        }
        part = strtok_r(NULL, ":", &saveptr);
    }
    free(paths);
    return false;
}

static bool process_get_user_shell_path(char *out, size_t out_sz) {
#ifdef _WIN32
    (void)out;
    (void)out_sz;
    return false;
#else
    uid_t uid = getuid();
    struct passwd passwd_buf;
    struct passwd *result = NULL;
    long suggested = sysconf(_SC_GETPW_R_SIZE_MAX);
    size_t buf_len = suggested > 0 ? (size_t)suggested : 1024u;
    char *buf = cetta_malloc(buf_len);
    for (;;) {
        int status = getpwuid_r(uid, &passwd_buf, buf, buf_len, &result);
        if (status == 0) {
            bool ok = result && passwd_buf.pw_shell && passwd_buf.pw_shell[0] != '\0' &&
                      process_copy_path(out, out_sz, passwd_buf.pw_shell);
            free(buf);
            return ok;
        }
        if (status != ERANGE || buf_len >= 1024u * 1024u) {
            free(buf);
            return false;
        }
        buf_len *= 2u;
        buf = cetta_realloc(buf, buf_len);
    }
#endif
}

static bool process_shell_path_for_type(ProcessShellType type,
                                        const char *provided_path,
                                        char *out,
                                        size_t out_sz) {
    char user_path[PATH_MAX];
    static const char *zsh_fallbacks[] = {"/bin/zsh"};
    static const char *bash_fallbacks[] = {"/bin/bash"};
    static const char *sh_fallbacks[] = {"/bin/sh"};
    static const char *pwsh_fallbacks[] = {"/usr/local/bin/pwsh"};
    const char *binary = NULL;
    const char **fallbacks = NULL;
    size_t fallback_count = 0;

    if (provided_path && process_file_is_regular(provided_path)) {
        return process_copy_path(out, out_sz, provided_path);
    }

    if (process_get_user_shell_path(user_path, sizeof(user_path)) &&
        process_detect_shell_type(user_path) == type &&
        process_file_is_regular(user_path)) {
        return process_copy_path(out, out_sz, user_path);
    }

    if (type == PROCESS_SHELL_POWERSHELL) {
        if (process_find_on_path("pwsh", out, out_sz)) return true;
        for (size_t i = 0; i < sizeof(pwsh_fallbacks) / sizeof(pwsh_fallbacks[0]); i++) {
            if (process_file_is_regular(pwsh_fallbacks[i])) {
                return process_copy_path(out, out_sz, pwsh_fallbacks[i]);
            }
        }
        return process_find_on_path("powershell", out, out_sz);
    }

    switch (type) {
        case PROCESS_SHELL_ZSH:
            binary = "zsh";
            fallbacks = zsh_fallbacks;
            fallback_count = sizeof(zsh_fallbacks) / sizeof(zsh_fallbacks[0]);
            break;
        case PROCESS_SHELL_BASH:
            binary = "bash";
            fallbacks = bash_fallbacks;
            fallback_count = sizeof(bash_fallbacks) / sizeof(bash_fallbacks[0]);
            break;
        case PROCESS_SHELL_SH:
            binary = "sh";
            fallbacks = sh_fallbacks;
            fallback_count = sizeof(sh_fallbacks) / sizeof(sh_fallbacks[0]);
            break;
        case PROCESS_SHELL_CMD:
            binary = "cmd";
            break;
        case PROCESS_SHELL_POWERSHELL:
        case PROCESS_SHELL_UNKNOWN:
            break;
    }

    if (binary && process_find_on_path(binary, out, out_sz)) return true;
    for (size_t i = 0; i < fallback_count; i++) {
        if (process_file_is_regular(fallbacks[i])) {
            return process_copy_path(out, out_sz, fallbacks[i]);
        }
    }
    return false;
}

static void process_default_shell_value(ProcessShell *shell,
                                        char *path,
                                        size_t path_sz) {
    char user_path[PATH_MAX];
    ProcessShellType user_type = PROCESS_SHELL_UNKNOWN;
    if (process_get_user_shell_path(user_path, sizeof(user_path))) {
        user_type = process_detect_shell_type(user_path);
    }

    if (user_type != PROCESS_SHELL_UNKNOWN &&
        process_shell_path_for_type(user_type, NULL, path, path_sz)) {
        shell->type = user_type;
        shell->path = path;
        return;
    }

#ifdef _WIN32
    if (process_shell_path_for_type(PROCESS_SHELL_POWERSHELL, NULL, path, path_sz)) {
        shell->type = PROCESS_SHELL_POWERSHELL;
        shell->path = path;
        return;
    }
#elif defined(__APPLE__)
    if (process_shell_path_for_type(PROCESS_SHELL_ZSH, NULL, path, path_sz)) {
        shell->type = PROCESS_SHELL_ZSH;
        shell->path = path;
        return;
    }
    if (process_shell_path_for_type(PROCESS_SHELL_BASH, NULL, path, path_sz)) {
        shell->type = PROCESS_SHELL_BASH;
        shell->path = path;
        return;
    }
#else
    if (process_shell_path_for_type(PROCESS_SHELL_BASH, NULL, path, path_sz)) {
        shell->type = PROCESS_SHELL_BASH;
        shell->path = path;
        return;
    }
    if (process_shell_path_for_type(PROCESS_SHELL_ZSH, NULL, path, path_sz)) {
        shell->type = PROCESS_SHELL_ZSH;
        shell->path = path;
        return;
    }
#endif

    shell->type = PROCESS_SHELL_SH;
    if (!process_copy_path(path, path_sz, "/bin/sh")) {
        path[0] = '\0';
    }
    shell->path = path;
}

static Atom *process_shell_atom(Arena *a, const ProcessShell *shell) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "ProcessShell"),
        atom_string(a, process_shell_type_text(shell->type)),
        atom_string(a, shell->path ? shell->path : ""),
    }, 3);
}

static bool process_parse_shell_atom(Atom *arg, ProcessShell *shell) {
    const char *type_text;
    const char *path;
    if (!shell || !process_expr_head_name(arg, "ProcessShell") ||
        arg->expr.len != 3 ||
        !(type_text = library_text_arg(arg->expr.elems[1])) ||
        !(path = library_text_arg(arg->expr.elems[2])) ||
        !process_parse_shell_type(type_text, &shell->type) ||
        path[0] == '\0') {
        return false;
    }
    shell->path = path;
    return true;
}

static void process_apply_child_env(const ProcessEnvPair *env_pairs,
                                    uint32_t env_count) {
    if (clearenv() != 0) {
        dprintf(STDERR_FILENO, "clearenv: %s\n", strerror(errno));
        _exit(125);
    }
    for (uint32_t i = 0; i < env_count; i++) {
        if (setenv(env_pairs[i].key, env_pairs[i].value, 1) != 0) {
            dprintf(STDERR_FILENO, "setenv(%s): %s\n",
                    env_pairs[i].key, strerror(errno));
            _exit(125);
        }
    }
}

typedef enum {
    PROCESS_ENV_INHERIT_ALL,
    PROCESS_ENV_INHERIT_NONE,
    PROCESS_ENV_INHERIT_CORE
} ProcessEnvInherit;

typedef struct {
    ProcessEnvInherit inherit;
    bool ignore_default_excludes;
    Atom *exclude_patterns;
    ProcessEnvPair *set_pairs;
    uint32_t set_count;
    Atom *include_only_patterns;
} ProcessShellEnvPolicy;

typedef struct {
    char *key;
    char *value;
} ProcessOwnedEnvPair;

typedef struct {
    ProcessOwnedEnvPair *items;
    uint32_t len;
    uint32_t cap;
} ProcessEnvMap;

static char *process_strdup_len(const char *text, size_t len) {
    char *out = cetta_malloc(len + 1u);
    memcpy(out, text, len);
    out[len] = '\0';
    return out;
}

static char *process_strdup_cstr(const char *text) {
    return process_strdup_len(text ? text : "", strlen(text ? text : ""));
}

static void process_env_map_init(ProcessEnvMap *map) {
    map->items = NULL;
    map->len = 0;
    map->cap = 0;
}

static void process_env_map_free(ProcessEnvMap *map) {
    for (uint32_t i = 0; i < map->len; i++) {
        free(map->items[i].key);
        free(map->items[i].value);
    }
    free(map->items);
    map->items = NULL;
    map->len = 0;
    map->cap = 0;
}

static int process_env_map_find(ProcessEnvMap *map, const char *key) {
    for (uint32_t i = 0; i < map->len; i++) {
        if (strcmp(map->items[i].key, key) == 0) return (int)i;
    }
    return -1;
}

static void process_env_map_set(ProcessEnvMap *map,
                                const char *key,
                                const char *value) {
    int idx = process_env_map_find(map, key);
    if (idx >= 0) {
        free(map->items[idx].value);
        map->items[idx].value = process_strdup_cstr(value);
        return;
    }
    if (map->len >= map->cap) {
        map->cap = map->cap ? map->cap * 2u : 32u;
        map->items = cetta_realloc(map->items,
                                   sizeof(ProcessOwnedEnvPair) * map->cap);
    }
    map->items[map->len].key = process_strdup_cstr(key);
    map->items[map->len].value = process_strdup_cstr(value);
    map->len++;
}

static void process_env_map_remove_at(ProcessEnvMap *map, uint32_t index) {
    if (index >= map->len) return;
    free(map->items[index].key);
    free(map->items[index].value);
    if (index + 1u < map->len) {
        memmove(&map->items[index],
                &map->items[index + 1u],
                sizeof(ProcessOwnedEnvPair) * (map->len - index - 1u));
    }
    map->len--;
}

static void process_env_map_add_current(ProcessEnvMap *map) {
    for (char **entry = environ; entry && *entry; entry++) {
        const char *eq = strchr(*entry, '=');
        char *key;
        if (!eq || eq == *entry) continue;
        key = process_strdup_len(*entry, (size_t)(eq - *entry));
        process_env_map_set(map, key, eq + 1);
        free(key);
    }
}

static bool process_parse_env_inherit(const char *text,
                                      ProcessEnvInherit *out) {
    if (!text || !out) return false;
    if (strcasecmp(text, "all") == 0) {
        *out = PROCESS_ENV_INHERIT_ALL;
        return true;
    }
    if (strcasecmp(text, "none") == 0) {
        *out = PROCESS_ENV_INHERIT_NONE;
        return true;
    }
    if (strcasecmp(text, "core") == 0) {
        *out = PROCESS_ENV_INHERIT_CORE;
        return true;
    }
    return false;
}

static bool process_text_expr(Atom *arg) {
    if (!arg || arg->kind != ATOM_EXPR) return false;
    for (uint32_t i = 0; i < arg->expr.len; i++) {
        if (!library_text_arg(arg->expr.elems[i])) return false;
    }
    return true;
}

static bool process_parse_shell_env_policy(Arena *a,
                                           Atom *arg,
                                           ProcessShellEnvPolicy *out) {
    const char *inherit_text;
    if (!out || !process_expr_head_name(arg, "ShellEnvPolicy") ||
        arg->expr.len != 6 ||
        !(inherit_text = library_text_arg(arg->expr.elems[1])) ||
        !process_parse_env_inherit(inherit_text, &out->inherit) ||
        !library_bool_arg(arg->expr.elems[2], &out->ignore_default_excludes) ||
        !process_text_expr(arg->expr.elems[3]) ||
        !process_parse_env_pairs(a, arg->expr.elems[4],
                                 &out->set_pairs, &out->set_count) ||
        !process_text_expr(arg->expr.elems[5])) {
        return false;
    }
    out->exclude_patterns = arg->expr.elems[3];
    out->include_only_patterns = arg->expr.elems[5];
    return true;
}

static bool process_env_name_is_core(const char *name) {
    static const char *core_names[] = {
        "PATH", "SHELL", "TMPDIR", "TEMP", "TMP",
        "HOME", "LANG", "LC_ALL", "LC_CTYPE", "LOGNAME", "USER",
    };
    for (size_t i = 0; i < sizeof(core_names) / sizeof(core_names[0]); i++) {
        if (strcmp(name, core_names[i]) == 0) return true;
    }
    return false;
}

static bool process_wildmatch_ci(const char *pattern, const char *text) {
    const char *star = NULL;
    const char *retry = NULL;
    while (*text) {
        if (*pattern == '?' ||
            (tolower((unsigned char)*pattern) ==
             tolower((unsigned char)*text))) {
            pattern++;
            text++;
        } else if (*pattern == '*') {
            star = pattern++;
            retry = text;
        } else if (star) {
            pattern = star + 1;
            text = ++retry;
        } else {
            return false;
        }
    }
    while (*pattern == '*') pattern++;
    return *pattern == '\0';
}

static bool process_env_name_matches_patterns(const char *name,
                                              Atom *patterns) {
    if (!patterns || patterns->kind != ATOM_EXPR) return false;
    for (uint32_t i = 0; i < patterns->expr.len; i++) {
        const char *pattern = library_text_arg(patterns->expr.elems[i]);
        if (pattern && process_wildmatch_ci(pattern, name)) return true;
    }
    return false;
}

static void process_env_map_filter_core(ProcessEnvMap *map) {
    uint32_t i = 0;
    while (i < map->len) {
        if (!process_env_name_is_core(map->items[i].key)) {
            process_env_map_remove_at(map, i);
        } else {
            i++;
        }
    }
}

static void process_env_map_filter_excluding(ProcessEnvMap *map, Atom *patterns) {
    uint32_t i = 0;
    while (i < map->len) {
        if (process_env_name_matches_patterns(map->items[i].key, patterns)) {
            process_env_map_remove_at(map, i);
        } else {
            i++;
        }
    }
}

static void process_env_map_filter_including(ProcessEnvMap *map, Atom *patterns) {
    uint32_t i = 0;
    if (!patterns || patterns->kind != ATOM_EXPR || patterns->expr.len == 0) return;
    while (i < map->len) {
        if (!process_env_name_matches_patterns(map->items[i].key, patterns)) {
            process_env_map_remove_at(map, i);
        } else {
            i++;
        }
    }
}

static Atom *process_env_map_atom(Arena *a, ProcessEnvMap *map) {
    Atom **items = map->len
        ? arena_alloc(a, sizeof(Atom *) * map->len)
        : NULL;
    for (uint32_t i = 0; i < map->len; i++) {
        items[i] = atom_expr(a, (Atom *[]){
            atom_symbol(a, "Env"),
            atom_string(a, map->items[i].key),
            atom_string(a, map->items[i].value),
        }, 3);
    }
    return atom_expr(a, items, map->len);
}

static Atom *process_create_shell_env_impl(Arena *a,
                                           Atom *head,
                                           Atom **args,
                                           uint32_t nargs,
                                           Atom *policy_arg,
                                           const char *thread_id,
                                           bool has_thread_id) {
    ProcessShellEnvPolicy policy;
    ProcessEnvMap map;
    Atom *result;
    if (!process_parse_shell_env_policy(a, policy_arg, &policy)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected ShellEnvPolicy");
    }

    process_env_map_init(&map);
    if (policy.inherit != PROCESS_ENV_INHERIT_NONE) {
        process_env_map_add_current(&map);
        if (policy.inherit == PROCESS_ENV_INHERIT_CORE) {
            process_env_map_filter_core(&map);
        }
    }
    if (!policy.ignore_default_excludes) {
        Atom *defaults = atom_expr(a, (Atom *[]){
            atom_string(a, "*KEY*"),
            atom_string(a, "*SECRET*"),
            atom_string(a, "*TOKEN*"),
        }, 3);
        process_env_map_filter_excluding(&map, defaults);
    }
    process_env_map_filter_excluding(&map, policy.exclude_patterns);
    for (uint32_t i = 0; i < policy.set_count; i++) {
        process_env_map_set(&map, policy.set_pairs[i].key,
                            policy.set_pairs[i].value);
    }
    process_env_map_filter_including(&map, policy.include_only_patterns);
    if (has_thread_id) {
        process_env_map_set(&map, "CODEX_THREAD_ID", thread_id);
    }

    result = process_env_map_atom(a, &map);
    process_env_map_free(&map);
    return result;
}

static Atom *process_create_shell_env(Arena *a,
                                      Atom *head,
                                      Atom **args,
                                      uint32_t nargs) {
    const char *thread_id;
    if (nargs != 2 || !(thread_id = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected ShellEnvPolicy and thread id");
    }
    return process_create_shell_env_impl(a, head, args, nargs,
                                         args[0], thread_id, true);
}

static Atom *process_create_shell_env_no_thread(Arena *a,
                                                Atom *head,
                                                Atom **args,
                                                uint32_t nargs) {
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected ShellEnvPolicy");
    }
    return process_create_shell_env_impl(a, head, args, nargs,
                                         args[0], NULL, false);
}

static Atom *process_run_exec_impl(Arena *a,
                                   Atom *head,
                                   Atom **args,
                                   uint32_t nargs,
                                   char *const argv[],
                                   const char *cwd,
                                   const ProcessEnvPair *env_pairs,
                                   uint32_t env_count,
                                   bool use_explicit_env,
                                   int timeout_ms,
                                   int max_bytes) {
    int stdout_pipe[2] = {-1, -1};
    int stderr_pipe[2] = {-1, -1};
    CettaStringBuf stdout_buf;
    CettaStringBuf stderr_buf;
    CettaStringBuf aggregated_buf;
    Atom *result = NULL;
    pid_t pid;
    bool stdout_open = true;
    bool stderr_open = true;
    bool timed_out = false;
    int status = 0;
    int exit_code = -1;
    uint64_t start_ns = 0;
    uint64_t end_ns = 0;
    uint64_t timeout_ns = timeout_ms > 0 ? (uint64_t)timeout_ms * 1000000ull : 0;
    size_t output_cap = max_bytes > 0 ? (size_t)max_bytes : 0;

    cetta_sb_init(&stdout_buf);
    cetta_sb_init(&stderr_buf);
    cetta_sb_init(&aggregated_buf);

    if (pipe(stdout_pipe) != 0 || pipe(stderr_pipe) != 0) {
        process_close_fd(&stdout_pipe[0]);
        process_close_fd(&stdout_pipe[1]);
        process_close_fd(&stderr_pipe[0]);
        process_close_fd(&stderr_pipe[1]);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, strerror(errno)));
    }

    start_ns = library_monotonic_ns();
    pid = fork();
    if (pid < 0) {
        process_close_fd(&stdout_pipe[0]);
        process_close_fd(&stdout_pipe[1]);
        process_close_fd(&stderr_pipe[0]);
        process_close_fd(&stderr_pipe[1]);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, strerror(errno)));
    }

    if (pid == 0) {
        setpgid(0, 0);
        close(stdout_pipe[0]);
        close(stderr_pipe[0]);
        if (dup2(stdout_pipe[1], STDOUT_FILENO) < 0 ||
            dup2(stderr_pipe[1], STDERR_FILENO) < 0) {
            _exit(126);
        }
        close(stdout_pipe[1]);
        close(stderr_pipe[1]);
        if (cwd && cwd[0] != '\0' && chdir(cwd) != 0) {
            dprintf(STDERR_FILENO, "chdir(%s): %s\n", cwd, strerror(errno));
            _exit(125);
        }
        if (use_explicit_env) {
            process_apply_child_env(env_pairs, env_count);
        }
        execvp(argv[0], argv);
        _exit(127);
    }

    setpgid(pid, pid);
    process_close_fd(&stdout_pipe[1]);
    process_close_fd(&stderr_pipe[1]);
    if (!process_set_nonblocking(stdout_pipe[0]) ||
        !process_set_nonblocking(stderr_pipe[0])) {
        process_kill_group(pid);
        process_close_fd(&stdout_pipe[0]);
        process_close_fd(&stderr_pipe[0]);
        waitpid(pid, &status, 0);
        result = atom_error(a, library_call_expr(a, head, args, nargs),
                            atom_string(a, strerror(errno)));
        goto cleanup;
    }

    while (stdout_open || stderr_open) {
        fd_set readfds;
        int max_fd = -1;
        int ready;
        struct timeval tv;
        struct timeval *tv_ptr = NULL;

        if (timeout_ns > 0 && !timed_out) {
            uint64_t now_ns = library_monotonic_ns();
            uint64_t elapsed_ns = now_ns >= start_ns ? now_ns - start_ns : 0;
            if (elapsed_ns >= timeout_ns) {
                timed_out = true;
                process_kill_group(pid);
            } else {
                uint64_t remaining_ns = timeout_ns - elapsed_ns;
                tv.tv_sec = (time_t)(remaining_ns / 1000000000ull);
                tv.tv_usec = (suseconds_t)((remaining_ns % 1000000000ull) / 1000ull);
                tv_ptr = &tv;
            }
        }

        FD_ZERO(&readfds);
        if (stdout_open) {
            FD_SET(stdout_pipe[0], &readfds);
            if (stdout_pipe[0] > max_fd) max_fd = stdout_pipe[0];
        }
        if (stderr_open) {
            FD_SET(stderr_pipe[0], &readfds);
            if (stderr_pipe[0] > max_fd) max_fd = stderr_pipe[0];
        }
        if (max_fd < 0) break;

        ready = select(max_fd + 1, &readfds, NULL, NULL, tv_ptr);
        if (ready < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (ready == 0) continue;

        if (stdout_open && FD_ISSET(stdout_pipe[0], &readfds)) {
            process_append_read(stdout_pipe[0], &stdout_buf, NULL,
                                &stdout_open, output_cap);
        }
        if (stderr_open && FD_ISSET(stderr_pipe[0], &readfds)) {
            process_append_read(stderr_pipe[0], &stderr_buf, NULL,
                                &stderr_open, output_cap);
        }
    }

    process_close_fd(&stdout_pipe[0]);
    process_close_fd(&stderr_pipe[0]);
    while (waitpid(pid, &status, 0) < 0) {
        if (errno == EINTR) continue;
        status = -1;
        break;
    }
    end_ns = library_monotonic_ns();
    exit_code = status >= 0 ? process_exit_code_from_status(status) : -1;
    process_aggregate_output(&aggregated_buf, &stdout_buf, &stderr_buf, output_cap);
    result = process_result_atom(a, exit_code, &stdout_buf, &stderr_buf,
                                 &aggregated_buf,
                                 process_duration_ms(start_ns, end_ns),
                                 timed_out);

cleanup:
    cetta_sb_free(&stdout_buf);
    cetta_sb_free(&stderr_buf);
    cetta_sb_free(&aggregated_buf);
    return result;
}

static Atom *process_run_shell(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *command;
    char *shell_argv[4];
    if (nargs != 1 || !(command = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected shell command");
    }
    shell_argv[0] = (char *)"/bin/sh";
    shell_argv[1] = (char *)"-lc";
    shell_argv[2] = (char *)command;
    shell_argv[3] = NULL;
    return process_run_exec_impl(a, head, args, nargs, shell_argv, NULL,
                                 NULL, 0, false, 0, 0);
}

static Atom *process_run_shell_timeout_ms(Arena *a,
                                          Atom *head,
                                          Atom **args,
                                          uint32_t nargs) {
    const char *command;
    char *shell_argv[4];
    int timeout_ms = 0;
    if (nargs != 2 || !(command = library_text_arg(args[0])) ||
        !library_int_arg(args[1], &timeout_ms) || timeout_ms < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected shell command and non-negative timeout ms");
    }
    shell_argv[0] = (char *)"/bin/sh";
    shell_argv[1] = (char *)"-lc";
    shell_argv[2] = (char *)command;
    shell_argv[3] = NULL;
    return process_run_exec_impl(a, head, args, nargs, shell_argv, NULL,
                                 NULL, 0, false, timeout_ms, 0);
}

static Atom *process_run_shell_cwd_timeout_ms(Arena *a,
                                              Atom *head,
                                              Atom **args,
                                              uint32_t nargs) {
    const char *command;
    const char *cwd;
    char *shell_argv[4];
    int timeout_ms = 0;
    if (nargs != 3 || !(command = library_text_arg(args[0])) ||
        !(cwd = library_text_arg(args[1])) ||
        !library_int_arg(args[2], &timeout_ms) || timeout_ms < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected shell command, cwd, and non-negative timeout ms");
    }
    shell_argv[0] = (char *)"/bin/sh";
    shell_argv[1] = (char *)"-lc";
    shell_argv[2] = (char *)command;
    shell_argv[3] = NULL;
    return process_run_exec_impl(a, head, args, nargs, shell_argv, cwd,
                                 NULL, 0, false, timeout_ms, 0);
}

static Atom *process_run_shell_cwd_timeout_cap_bytes(Arena *a,
                                                     Atom *head,
                                                     Atom **args,
                                                     uint32_t nargs) {
    const char *command;
    const char *cwd;
    char *shell_argv[4];
    int timeout_ms = 0;
    int max_bytes = 0;
    if (nargs != 4 || !(command = library_text_arg(args[0])) ||
        !(cwd = library_text_arg(args[1])) ||
        !library_int_arg(args[2], &timeout_ms) ||
        !library_int_arg(args[3], &max_bytes) ||
        timeout_ms < 0 || max_bytes < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected shell command, cwd, non-negative timeout ms, and non-negative max bytes");
    }
    shell_argv[0] = (char *)"/bin/sh";
    shell_argv[1] = (char *)"-lc";
    shell_argv[2] = (char *)command;
    shell_argv[3] = NULL;
    return process_run_exec_impl(a, head, args, nargs, shell_argv, cwd,
                                 NULL, 0, false, timeout_ms, max_bytes);
}

static Atom *process_run_cmd_cwd_env_timeout_cap_bytes(Arena *a,
                                                       Atom *head,
                                                       Atom **args,
                                                       uint32_t nargs) {
    char **argv;
    const char *cwd;
    ProcessEnvPair *env_pairs;
    uint32_t env_count = 0;
    int timeout_ms = 0;
    int max_bytes = 0;
    if (nargs != 5 || !process_parse_argv(a, args[0], &argv) ||
        !(cwd = library_text_arg(args[1])) ||
        !process_parse_env_pairs(a, args[2], &env_pairs, &env_count) ||
        !library_int_arg(args[3], &timeout_ms) ||
        !library_int_arg(args[4], &max_bytes) ||
        timeout_ms < 0 || max_bytes < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected command argv, cwd, env pairs, non-negative timeout ms, and non-negative max bytes");
    }
    return process_run_exec_impl(a, head, args, nargs, argv, cwd,
                                 env_pairs, env_count, true, timeout_ms,
                                 max_bytes);
}

static Atom *process_default_shell(Arena *a,
                                   Atom *head,
                                   Atom **args,
                                   uint32_t nargs) {
    char path[PATH_MAX];
    ProcessShell shell;
    if (!system_zero_arg_ok(args, nargs)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected: (process-default-shell)");
    }
    process_default_shell_value(&shell, path, sizeof(path));
    return process_shell_atom(a, &shell);
}

static Atom *process_shell_argv(Arena *a,
                                Atom *head,
                                Atom **args,
                                uint32_t nargs) {
    ProcessShell shell;
    const char *command;
    bool use_login_shell = false;
    Atom **items;
    uint32_t nitems;

    if (nargs != 3 ||
        !process_parse_shell_atom(args[0], &shell) ||
        !(command = library_text_arg(args[1])) ||
        !library_bool_arg(args[2], &use_login_shell)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected ProcessShell, command, and login-shell bool");
    }

    switch (shell.type) {
        case PROCESS_SHELL_ZSH:
        case PROCESS_SHELL_BASH:
        case PROCESS_SHELL_SH:
            items = arena_alloc(a, sizeof(Atom *) * 3u);
            items[0] = atom_string(a, shell.path);
            items[1] = atom_string(a, use_login_shell ? "-lc" : "-c");
            items[2] = atom_string(a, command);
            return atom_expr(a, items, 3);
        case PROCESS_SHELL_POWERSHELL:
            nitems = use_login_shell ? 3u : 4u;
            items = arena_alloc(a, sizeof(Atom *) * nitems);
            items[0] = atom_string(a, shell.path);
            if (use_login_shell) {
                items[1] = atom_string(a, "-Command");
                items[2] = atom_string(a, command);
            } else {
                items[1] = atom_string(a, "-NoProfile");
                items[2] = atom_string(a, "-Command");
                items[3] = atom_string(a, command);
            }
            return atom_expr(a, items, nitems);
        case PROCESS_SHELL_CMD:
            items = arena_alloc(a, sizeof(Atom *) * 3u);
            items[0] = atom_string(a, shell.path);
            items[1] = atom_string(a, "/c");
            items[2] = atom_string(a, command);
            return atom_expr(a, items, 3);
        case PROCESS_SHELL_UNKNOWN:
            break;
    }

    return library_signature_error(a, head, args, nargs,
                                   "unknown shell type");
}

static Atom *cetta_library_dispatch_process(Arena *a, Atom *head,
                                            Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_process_run_shell) {
        return process_run_shell(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_run_shell_timeout_ms) {
        return process_run_shell_timeout_ms(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_run_shell_cwd_timeout_ms) {
        return process_run_shell_cwd_timeout_ms(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_run_shell_cwd_timeout_cap_bytes) {
        return process_run_shell_cwd_timeout_cap_bytes(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_run_cmd_cwd_env_timeout_cap_bytes) {
        return process_run_cmd_cwd_env_timeout_cap_bytes(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_open_session_cmd_cwd_env_tty_yield_cap_bytes) {
        return process_open_session_cmd_cwd_env_tty_yield_cap_bytes(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_write_session_stdin_yield_cap_bytes) {
        return process_write_session_stdin_yield_cap_bytes(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_default_shell) {
        return process_default_shell(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_shell_argv) {
        return process_shell_argv(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_create_shell_env) {
        return process_create_shell_env(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_process_create_shell_env_no_thread) {
        return process_create_shell_env_no_thread(a, head, args, nargs);
    }
    return NULL;
}

typedef struct {
    const char *text;
    size_t len;
    size_t pos;
    const char *error;
} CettaJsonParser;

static void json_skip_ws(CettaJsonParser *p) {
    while (p->pos < p->len &&
           (p->text[p->pos] == ' ' || p->text[p->pos] == '\n' ||
            p->text[p->pos] == '\r' || p->text[p->pos] == '\t')) {
        p->pos++;
    }
}

static bool json_match(CettaJsonParser *p, const char *literal) {
    size_t n = strlen(literal);
    if (p->pos + n > p->len) return false;
    if (memcmp(p->text + p->pos, literal, n) != 0) return false;
    p->pos += n;
    return true;
}

static int json_hex_digit(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static bool json_parse_hex4(CettaJsonParser *p, uint32_t *out) {
    uint32_t value = 0;
    if (p->pos + 4 > p->len) return false;
    for (int i = 0; i < 4; i++) {
        int digit = json_hex_digit(p->text[p->pos + (size_t)i]);
        if (digit < 0) return false;
        value = (value << 4) | (uint32_t)digit;
    }
    p->pos += 4;
    *out = value;
    return true;
}

static void json_append_utf8(CettaStringBuf *out, uint32_t cp) {
    char bytes[4];
    if (cp <= 0x7fu) {
        bytes[0] = (char)cp;
        cetta_sb_append_n(out, bytes, 1);
    } else if (cp <= 0x7ffu) {
        bytes[0] = (char)(0xc0u | (cp >> 6));
        bytes[1] = (char)(0x80u | (cp & 0x3fu));
        cetta_sb_append_n(out, bytes, 2);
    } else if (cp <= 0xffffu) {
        bytes[0] = (char)(0xe0u | (cp >> 12));
        bytes[1] = (char)(0x80u | ((cp >> 6) & 0x3fu));
        bytes[2] = (char)(0x80u | (cp & 0x3fu));
        cetta_sb_append_n(out, bytes, 3);
    } else {
        bytes[0] = (char)(0xf0u | (cp >> 18));
        bytes[1] = (char)(0x80u | ((cp >> 12) & 0x3fu));
        bytes[2] = (char)(0x80u | ((cp >> 6) & 0x3fu));
        bytes[3] = (char)(0x80u | (cp & 0x3fu));
        cetta_sb_append_n(out, bytes, 4);
    }
}

static bool json_parse_string_buf(CettaJsonParser *p, CettaStringBuf *out) {
    if (p->pos >= p->len || p->text[p->pos] != '"') {
        p->error = "expected JSON string";
        return false;
    }
    p->pos++;
    while (p->pos < p->len) {
        unsigned char c = (unsigned char)p->text[p->pos++];
        if (c == '"') return true;
        if (c < 0x20u) {
            p->error = "control character in JSON string";
            return false;
        }
        if (c != '\\') {
            cetta_sb_append_n(out, (const char *)&c, 1);
            continue;
        }
        if (p->pos >= p->len) {
            p->error = "unterminated JSON escape";
            return false;
        }
        c = (unsigned char)p->text[p->pos++];
        switch (c) {
        case '"': cetta_sb_append(out, "\""); break;
        case '\\': cetta_sb_append(out, "\\"); break;
        case '/': cetta_sb_append(out, "/"); break;
        case 'b': cetta_sb_append_n(out, "\b", 1); break;
        case 'f': cetta_sb_append_n(out, "\f", 1); break;
        case 'n': cetta_sb_append(out, "\n"); break;
        case 'r': cetta_sb_append(out, "\r"); break;
        case 't': cetta_sb_append(out, "\t"); break;
        case 'u': {
            uint32_t cp;
            if (!json_parse_hex4(p, &cp)) {
                p->error = "invalid JSON unicode escape";
                return false;
            }
            if (cp >= 0xd800u && cp <= 0xdbffu) {
                uint32_t low;
                if (p->pos + 6 > p->len || p->text[p->pos] != '\\' ||
                    p->text[p->pos + 1] != 'u') {
                    p->error = "missing JSON low surrogate";
                    return false;
                }
                p->pos += 2;
                if (!json_parse_hex4(p, &low) || low < 0xdc00u || low > 0xdfffu) {
                    p->error = "invalid JSON low surrogate";
                    return false;
                }
                cp = 0x10000u + (((cp - 0xd800u) << 10) | (low - 0xdc00u));
            } else if (cp >= 0xdc00u && cp <= 0xdfffu) {
                p->error = "unpaired JSON low surrogate";
                return false;
            }
            json_append_utf8(out, cp);
            break;
        }
        default:
            p->error = "invalid JSON escape";
            return false;
        }
    }
    p->error = "unterminated JSON string";
    return false;
}

static Atom *json_parse_value(CettaJsonParser *p, Arena *a, int depth);

static Atom *json_wrap1(Arena *a, const char *head, Atom *value) {
    return atom_expr(a, (Atom *[]){atom_symbol(a, head), value}, 2);
}

static Atom *json_parse_number(CettaJsonParser *p, Arena *a) {
    size_t start = p->pos;
    char *raw;
    Atom *result;
    if (p->pos < p->len && p->text[p->pos] == '-') p->pos++;
    if (p->pos >= p->len) {
        p->error = "invalid JSON number";
        return NULL;
    }
    if (p->text[p->pos] == '0') {
        p->pos++;
    } else if (p->text[p->pos] >= '1' && p->text[p->pos] <= '9') {
        while (p->pos < p->len && isdigit((unsigned char)p->text[p->pos])) p->pos++;
    } else {
        p->error = "invalid JSON number";
        return NULL;
    }
    if (p->pos < p->len && p->text[p->pos] == '.') {
        p->pos++;
        if (p->pos >= p->len || !isdigit((unsigned char)p->text[p->pos])) {
            p->error = "invalid JSON number fraction";
            return NULL;
        }
        while (p->pos < p->len && isdigit((unsigned char)p->text[p->pos])) p->pos++;
    }
    if (p->pos < p->len && (p->text[p->pos] == 'e' || p->text[p->pos] == 'E')) {
        p->pos++;
        if (p->pos < p->len && (p->text[p->pos] == '+' || p->text[p->pos] == '-')) p->pos++;
        if (p->pos >= p->len || !isdigit((unsigned char)p->text[p->pos])) {
            p->error = "invalid JSON number exponent";
            return NULL;
        }
        while (p->pos < p->len && isdigit((unsigned char)p->text[p->pos])) p->pos++;
    }
    raw = cetta_malloc(p->pos - start + 1);
    memcpy(raw, p->text + start, p->pos - start);
    raw[p->pos - start] = '\0';
    result = json_wrap1(a, "JsonNumber", atom_string(a, raw));
    free(raw);
    return result;
}

static Atom *json_parse_array(CettaJsonParser *p, Arena *a, int depth) {
    Atom **items = NULL;
    uint32_t nitems = 0;
    uint32_t cap = 0;
    Atom *list;
    Atom *result;
    p->pos++;
    json_skip_ws(p);
    if (p->pos < p->len && p->text[p->pos] == ']') {
        p->pos++;
        return json_wrap1(a, "JsonArray", atom_expr(a, NULL, 0));
    }
    for (;;) {
        Atom *item = json_parse_value(p, a, depth + 1);
        if (!item) {
            free(items);
            return NULL;
        }
        if (nitems >= cap) {
            cap = cap ? cap * 2 : 8;
            items = cetta_realloc(items, sizeof(Atom *) * cap);
        }
        items[nitems++] = item;
        json_skip_ws(p);
        if (p->pos >= p->len) {
            free(items);
            p->error = "unterminated JSON array";
            return NULL;
        }
        if (p->text[p->pos] == ']') {
            p->pos++;
            break;
        }
        if (p->text[p->pos] != ',') {
            free(items);
            p->error = "expected comma in JSON array";
            return NULL;
        }
        p->pos++;
        json_skip_ws(p);
    }
    list = atom_expr(a, items, nitems);
    result = json_wrap1(a, "JsonArray", list);
    free(items);
    return result;
}

static Atom *json_parse_object(CettaJsonParser *p, Arena *a, int depth) {
    Atom **pairs = NULL;
    uint32_t npairs = 0;
    uint32_t cap = 0;
    Atom *list;
    Atom *result;
    p->pos++;
    json_skip_ws(p);
    if (p->pos < p->len && p->text[p->pos] == '}') {
        p->pos++;
        return json_wrap1(a, "JsonObject", atom_expr(a, NULL, 0));
    }
    for (;;) {
        CettaStringBuf key;
        Atom *value;
        Atom *pair;
        cetta_sb_init(&key);
        if (!json_parse_string_buf(p, &key)) {
            cetta_sb_free(&key);
            free(pairs);
            return NULL;
        }
        json_skip_ws(p);
        if (p->pos >= p->len || p->text[p->pos] != ':') {
            cetta_sb_free(&key);
            free(pairs);
            p->error = "expected colon in JSON object";
            return NULL;
        }
        p->pos++;
        value = json_parse_value(p, a, depth + 1);
        if (!value) {
            cetta_sb_free(&key);
            free(pairs);
            return NULL;
        }
        pair = atom_expr(a, (Atom *[]){
            atom_symbol(a, "JsonPair"),
            atom_string(a, key.buf ? key.buf : ""),
            value,
        }, 3);
        cetta_sb_free(&key);
        if (npairs >= cap) {
            cap = cap ? cap * 2 : 8;
            pairs = cetta_realloc(pairs, sizeof(Atom *) * cap);
        }
        pairs[npairs++] = pair;
        json_skip_ws(p);
        if (p->pos >= p->len) {
            free(pairs);
            p->error = "unterminated JSON object";
            return NULL;
        }
        if (p->text[p->pos] == '}') {
            p->pos++;
            break;
        }
        if (p->text[p->pos] != ',') {
            free(pairs);
            p->error = "expected comma in JSON object";
            return NULL;
        }
        p->pos++;
        json_skip_ws(p);
    }
    list = atom_expr(a, pairs, npairs);
    result = json_wrap1(a, "JsonObject", list);
    free(pairs);
    return result;
}

static Atom *json_parse_value(CettaJsonParser *p, Arena *a, int depth) {
    if (depth > 512) {
        p->error = "JSON nesting too deep";
        return NULL;
    }
    json_skip_ws(p);
    if (p->pos >= p->len) {
        p->error = "expected JSON value";
        return NULL;
    }
    if (p->text[p->pos] == '"') {
        CettaStringBuf text;
        Atom *result;
        cetta_sb_init(&text);
        if (!json_parse_string_buf(p, &text)) {
            cetta_sb_free(&text);
            return NULL;
        }
        result = json_wrap1(a, "JsonString", atom_string(a, text.buf ? text.buf : ""));
        cetta_sb_free(&text);
        return result;
    }
    if (p->text[p->pos] == '[') return json_parse_array(p, a, depth);
    if (p->text[p->pos] == '{') return json_parse_object(p, a, depth);
    if (p->text[p->pos] == '-' || isdigit((unsigned char)p->text[p->pos])) {
        return json_parse_number(p, a);
    }
    if (json_match(p, "true")) return json_wrap1(a, "JsonBool", atom_true(a));
    if (json_match(p, "false")) return json_wrap1(a, "JsonBool", atom_false(a));
    if (json_match(p, "null")) return atom_symbol(a, "JsonNull");
    p->error = "invalid JSON value";
    return NULL;
}

static Atom *json_parse(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *text;
    CettaJsonParser p;
    Atom *result;
    if (nargs != 1 || !(text = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected JSON text");
    }
    p.text = text;
    p.len = strlen(text);
    p.pos = 0;
    p.error = NULL;
    result = json_parse_value(&p, a, 0);
    if (!result) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, p.error ? p.error : "invalid JSON"));
    }
    json_skip_ws(&p);
    if (p.pos != p.len) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "trailing data after JSON value"));
    }
    return result;
}

static bool json_bool_atom(Atom *atom, bool *out) {
    if (!atom || !out) return false;
    if (atom->kind == ATOM_GROUNDED && atom->ground.gkind == GV_BOOL) {
        *out = atom->ground.bval;
        return true;
    }
    if (atom_is_symbol_id(atom, g_builtin_syms.true_text)) {
        *out = true;
        return true;
    }
    if (atom_is_symbol_id(atom, g_builtin_syms.false_text)) {
        *out = false;
        return true;
    }
    return false;
}

static bool json_expr_head(Atom *atom, const char *head_name) {
    return atom && atom->kind == ATOM_EXPR && atom->expr.len > 0 &&
           atom->expr.elems[0]->kind == ATOM_SYMBOL &&
           atom_is_symbol(atom->expr.elems[0], head_name);
}

static void json_append_escaped_string(CettaStringBuf *out, const char *text) {
    static const char hex[] = "0123456789abcdef";
    cetta_sb_append(out, "\"");
    for (const unsigned char *p = (const unsigned char *)text; *p; p++) {
        unsigned char c = *p;
        switch (c) {
        case '"': cetta_sb_append(out, "\\\""); break;
        case '\\': cetta_sb_append(out, "\\\\"); break;
        case '\b': cetta_sb_append(out, "\\b"); break;
        case '\f': cetta_sb_append(out, "\\f"); break;
        case '\n': cetta_sb_append(out, "\\n"); break;
        case '\r': cetta_sb_append(out, "\\r"); break;
        case '\t': cetta_sb_append(out, "\\t"); break;
        default:
            if (c < 0x20u) {
                char esc[6] = {'\\', 'u', '0', '0', hex[c >> 4], hex[c & 0xfu]};
                cetta_sb_append_n(out, esc, sizeof(esc));
            } else {
                cetta_sb_append_n(out, (const char *)&c, 1);
            }
            break;
        }
    }
    cetta_sb_append(out, "\"");
}

static bool json_stringify_atom(Atom *atom, CettaStringBuf *out,
                                const char **error_out, int depth);

static bool json_stringify_number_atom(Atom *atom, CettaStringBuf *out) {
    char buf[64];
    const char *text = library_text_arg(atom);
    if (text) {
        cetta_sb_append(out, text);
        return true;
    }
    if (atom && atom->kind == ATOM_GROUNDED && atom->ground.gkind == GV_INT) {
        snprintf(buf, sizeof(buf), "%lld", (long long)atom->ground.ival);
        cetta_sb_append(out, buf);
        return true;
    }
    if (atom && atom->kind == ATOM_GROUNDED && atom->ground.gkind == GV_FLOAT) {
        snprintf(buf, sizeof(buf), "%.17g", atom->ground.fval);
        cetta_sb_append(out, buf);
        return true;
    }
    return false;
}

static bool json_stringify_array_items(Atom *items, CettaStringBuf *out,
                                       const char **error_out, int depth) {
    if (!items || items->kind != ATOM_EXPR) {
        *error_out = "JsonArray expects an expression of items";
        return false;
    }
    cetta_sb_append(out, "[");
    for (uint32_t i = 0; i < items->expr.len; i++) {
        if (i) cetta_sb_append(out, ",");
        if (!json_stringify_atom(items->expr.elems[i], out, error_out, depth + 1)) {
            return false;
        }
    }
    cetta_sb_append(out, "]");
    return true;
}

static bool json_stringify_object_pairs(Atom *pairs, CettaStringBuf *out,
                                        const char **error_out, int depth) {
    if (!pairs || pairs->kind != ATOM_EXPR) {
        *error_out = "JsonObject expects an expression of JsonPair entries";
        return false;
    }
    cetta_sb_append(out, "{");
    for (uint32_t i = 0; i < pairs->expr.len; i++) {
        Atom *pair = pairs->expr.elems[i];
        const char *key;
        if (!json_expr_head(pair, "JsonPair") || pair->expr.len != 3 ||
            !(key = library_text_arg(pair->expr.elems[1]))) {
            *error_out = "JsonObject entry must be (JsonPair key value)";
            return false;
        }
        if (i) cetta_sb_append(out, ",");
        json_append_escaped_string(out, key);
        cetta_sb_append(out, ":");
        if (!json_stringify_atom(pair->expr.elems[2], out, error_out, depth + 1)) {
            return false;
        }
    }
    cetta_sb_append(out, "}");
    return true;
}

static bool json_stringify_atom(Atom *atom, CettaStringBuf *out,
                                const char **error_out, int depth) {
    bool bool_value;
    if (depth > 512) {
        *error_out = "JSON nesting too deep";
        return false;
    }
    if (!atom) {
        *error_out = "missing JSON value";
        return false;
    }
    if (atom_is_symbol(atom, "JsonNull")) {
        cetta_sb_append(out, "null");
        return true;
    }
    if (json_expr_head(atom, "JsonString") && atom->expr.len == 2) {
        const char *text = library_text_arg(atom->expr.elems[1]);
        if (!text) {
            *error_out = "JsonString expects text";
            return false;
        }
        json_append_escaped_string(out, text);
        return true;
    }
    if (json_expr_head(atom, "JsonNumber") && atom->expr.len == 2) {
        if (!json_stringify_number_atom(atom->expr.elems[1], out)) {
            *error_out = "JsonNumber expects number text or numeric atom";
            return false;
        }
        return true;
    }
    if (json_expr_head(atom, "JsonBool") && atom->expr.len == 2) {
        if (!json_bool_atom(atom->expr.elems[1], &bool_value)) {
            *error_out = "JsonBool expects True or False";
            return false;
        }
        cetta_sb_append(out, bool_value ? "true" : "false");
        return true;
    }
    if (json_expr_head(atom, "JsonArray") && atom->expr.len == 2) {
        return json_stringify_array_items(atom->expr.elems[1], out, error_out, depth);
    }
    if (json_expr_head(atom, "JsonObject") && atom->expr.len == 2) {
        return json_stringify_object_pairs(atom->expr.elems[1], out, error_out, depth);
    }
    if (atom->kind == ATOM_GROUNDED) {
        switch (atom->ground.gkind) {
        case GV_STRING:
            json_append_escaped_string(out, atom->ground.sval ? atom->ground.sval : "");
            return true;
        case GV_INT:
        case GV_FLOAT:
            return json_stringify_number_atom(atom, out);
        case GV_BOOL:
            cetta_sb_append(out, atom->ground.bval ? "true" : "false");
            return true;
        default:
            break;
        }
    }
    if (json_bool_atom(atom, &bool_value)) {
        cetta_sb_append(out, bool_value ? "true" : "false");
        return true;
    }
    if (atom->kind == ATOM_SYMBOL) {
        json_append_escaped_string(out, atom_name_cstr(atom));
        return true;
    }
    if (atom->kind == ATOM_EXPR) {
        return json_stringify_array_items(atom, out, error_out, depth);
    }
    *error_out = "unsupported JSON atom";
    return false;
}

static Atom *json_stringify(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    CettaStringBuf out;
    const char *error = NULL;
    Atom *result;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs, "expected JSON value");
    }
    cetta_sb_init(&out);
    if (!json_stringify_atom(args[0], &out, &error, 0)) {
        cetta_sb_free(&out);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, error ? error : "cannot stringify JSON"));
    }
    result = atom_string(a, out.buf ? out.buf : "");
    cetta_sb_free(&out);
    return result;
}

static Atom *json_object_get(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    Atom *pairs;
    const char *key;
    if (nargs != 2 || !json_expr_head(args[0], "JsonObject") ||
        args[0]->expr.len != 2 || args[0]->expr.elems[1]->kind != ATOM_EXPR ||
        !(key = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected JsonObject and key");
    }
    pairs = args[0]->expr.elems[1];
    for (uint32_t i = 0; i < pairs->expr.len; i++) {
        Atom *pair = pairs->expr.elems[i];
        const char *pair_key;
        if (!json_expr_head(pair, "JsonPair") || pair->expr.len != 3 ||
            !(pair_key = library_text_arg(pair->expr.elems[1]))) {
            continue;
        }
        if (strcmp(pair_key, key) == 0) {
            return atom_deep_copy(a, pair->expr.elems[2]);
        }
    }
    return atom_symbol(a, "JsonNull");
}

static Atom *cetta_library_dispatch_json(Arena *a, Atom *head,
                                         Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_json_parse) {
        return json_parse(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_json_stringify) {
        return json_stringify(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_json_object_get) {
        return json_object_get(a, head, args, nargs);
    }
    return NULL;
}

typedef struct {
    char **items;
    uint32_t len;
    uint32_t cap;
} PatchLineVec;

typedef struct {
    char *change_context;
    PatchLineVec old_lines;
    PatchLineVec new_lines;
    bool is_end_of_file;
} PatchChunk;

typedef enum {
    PATCH_HUNK_ADD,
    PATCH_HUNK_DELETE,
    PATCH_HUNK_UPDATE
} PatchHunkKind;

typedef struct {
    PatchHunkKind kind;
    char *path;
    char *move_path;
    char *contents;
    PatchChunk *chunks;
    uint32_t chunk_len;
    uint32_t chunk_cap;
} PatchHunk;

typedef struct {
    PatchHunk *hunks;
    uint32_t len;
    uint32_t cap;
    char error[512];
} PatchDoc;

typedef struct {
    size_t start;
    size_t old_len;
    uint32_t order;
    PatchLineVec new_lines;
} PatchReplacement;

typedef struct {
    PatchReplacement *items;
    uint32_t len;
    uint32_t cap;
} PatchReplacementVec;

typedef struct {
    char *path;
    char op;
} PatchAffected;

typedef struct {
    PatchAffected *items;
    uint32_t len;
    uint32_t cap;
} PatchAffectedVec;

typedef enum {
    PATCH_VERIFIED_ADD = 1,
    PATCH_VERIFIED_DELETE = 2,
    PATCH_VERIFIED_UPDATE = 3,
} PatchVerifiedChangeKind;

typedef struct {
    PatchVerifiedChangeKind kind;
    char *path;
    char *content;
    char *move_path;
    char *unified_diff;
    char *new_content;
} PatchVerifiedChange;

typedef struct {
    PatchVerifiedChange *items;
    uint32_t len;
    uint32_t cap;
} PatchVerifiedChangeVec;

typedef enum {
    PATCH_VIRTUAL_MISSING = 0,
    PATCH_VIRTUAL_FILE = 1,
    PATCH_VIRTUAL_DIRECTORY = 2,
} PatchVirtualFileKind;

typedef struct {
    char *path;
    PatchVirtualFileKind kind;
    char *content;
} PatchVirtualFile;

typedef struct {
    PatchVirtualFile *items;
    uint32_t len;
    uint32_t cap;
} PatchVirtualFileVec;

static void patch_set_error(PatchDoc *doc, const char *fmt, ...) {
    va_list ap;
    if (!doc || doc->error[0] != '\0') return;
    va_start(ap, fmt);
    vsnprintf(doc->error, sizeof(doc->error), fmt, ap);
    va_end(ap);
}

static void patch_line_vec_init(PatchLineVec *vec) {
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void patch_line_vec_push_len(PatchLineVec *vec, const char *text, size_t len) {
    if (vec->len >= vec->cap) {
        vec->cap = vec->cap ? vec->cap * 2u : 8u;
        vec->items = cetta_realloc(vec->items, sizeof(char *) * vec->cap);
    }
    vec->items[vec->len++] = process_strdup_len(text ? text : "", len);
}

static void patch_line_vec_push(PatchLineVec *vec, const char *text) {
    patch_line_vec_push_len(vec, text ? text : "", strlen(text ? text : ""));
}

static void patch_line_vec_free(PatchLineVec *vec) {
    if (!vec) return;
    for (uint32_t i = 0; i < vec->len; i++) free(vec->items[i]);
    free(vec->items);
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void patch_chunk_init(PatchChunk *chunk) {
    chunk->change_context = NULL;
    patch_line_vec_init(&chunk->old_lines);
    patch_line_vec_init(&chunk->new_lines);
    chunk->is_end_of_file = false;
}

static void patch_chunk_free(PatchChunk *chunk) {
    if (!chunk) return;
    free(chunk->change_context);
    patch_line_vec_free(&chunk->old_lines);
    patch_line_vec_free(&chunk->new_lines);
}

static void patch_hunk_init(PatchHunk *hunk, PatchHunkKind kind, const char *path) {
    hunk->kind = kind;
    hunk->path = process_strdup_cstr(path);
    hunk->move_path = NULL;
    hunk->contents = NULL;
    hunk->chunks = NULL;
    hunk->chunk_len = 0;
    hunk->chunk_cap = 0;
}

static void patch_hunk_add_chunk(PatchHunk *hunk, PatchChunk *chunk) {
    if (hunk->chunk_len >= hunk->chunk_cap) {
        hunk->chunk_cap = hunk->chunk_cap ? hunk->chunk_cap * 2u : 4u;
        hunk->chunks = cetta_realloc(hunk->chunks,
                                     sizeof(PatchChunk) * hunk->chunk_cap);
    }
    hunk->chunks[hunk->chunk_len++] = *chunk;
}

static void patch_hunk_free(PatchHunk *hunk) {
    if (!hunk) return;
    free(hunk->path);
    free(hunk->move_path);
    free(hunk->contents);
    for (uint32_t i = 0; i < hunk->chunk_len; i++) {
        patch_chunk_free(&hunk->chunks[i]);
    }
    free(hunk->chunks);
}

static void patch_doc_init(PatchDoc *doc) {
    doc->hunks = NULL;
    doc->len = 0;
    doc->cap = 0;
    doc->error[0] = '\0';
}

static void patch_doc_add_hunk(PatchDoc *doc, PatchHunk *hunk) {
    if (doc->len >= doc->cap) {
        doc->cap = doc->cap ? doc->cap * 2u : 4u;
        doc->hunks = cetta_realloc(doc->hunks, sizeof(PatchHunk) * doc->cap);
    }
    doc->hunks[doc->len++] = *hunk;
}

static void patch_doc_free(PatchDoc *doc) {
    if (!doc) return;
    for (uint32_t i = 0; i < doc->len; i++) patch_hunk_free(&doc->hunks[i]);
    free(doc->hunks);
    doc->hunks = NULL;
    doc->len = 0;
    doc->cap = 0;
}

static const char *patch_trim_view(const char *line, size_t *len_out) {
    const char *start = line ? line : "";
    const char *end = start + strlen(start);
    while (*start && isspace((unsigned char)*start)) start++;
    while (end > start && isspace((unsigned char)end[-1])) end--;
    if (len_out) *len_out = (size_t)(end - start);
    return start;
}

static bool patch_trim_eq(const char *line, const char *expected) {
    size_t len;
    const char *trim = patch_trim_view(line, &len);
    size_t expected_len = strlen(expected);
    return len == expected_len && strncmp(trim, expected, len) == 0;
}

static bool patch_trim_prefix(const char *line,
                              const char *prefix,
                              char **rest_out) {
    size_t len;
    const char *trim = patch_trim_view(line, &len);
    size_t prefix_len = strlen(prefix);
    if (len < prefix_len || strncmp(trim, prefix, prefix_len) != 0) return false;
    if (rest_out) *rest_out = process_strdup_len(trim + prefix_len, len - prefix_len);
    return true;
}

static bool patch_line_starts_hunk_marker(const char *line) {
    size_t len;
    const char *trim = patch_trim_view(line, &len);
    return len > 0 && trim[0] == '*';
}

static void patch_split_patch_lines(char *text, char ***lines_out, uint32_t *count_out) {
    char **lines = NULL;
    uint32_t len = 0;
    uint32_t cap = 0;
    char *start = text;
    for (char *p = text;; p++) {
        if (*p != '\n' && *p != '\0') continue;
        char saved = *p;
        if (len >= cap) {
            cap = cap ? cap * 2u : 16u;
            lines = cetta_realloc(lines, sizeof(char *) * cap);
        }
        *p = '\0';
        size_t line_len = strlen(start);
        if (line_len > 0 && start[line_len - 1] == '\r') start[line_len - 1] = '\0';
        lines[len++] = start;
        if (saved == '\0') break;
        start = p + 1;
    }
    if (len > 0 && lines[len - 1][0] == '\0') len--;
    *lines_out = lines;
    *count_out = len;
}

static char *patch_trimmed_copy(const char *text) {
    size_t len = strlen(text ? text : "");
    const char *start = text ? text : "";
    const char *end = start + len;
    while (*start && isspace((unsigned char)*start)) start++;
    while (end > start && isspace((unsigned char)end[-1])) end--;
    return process_strdup_len(start, (size_t)(end - start));
}

static bool patch_parse_chunk(char **lines,
                              uint32_t count,
                              uint32_t start,
                              bool allow_missing_context,
                              PatchChunk *chunk,
                              uint32_t *consumed,
                              PatchDoc *doc) {
    uint32_t i = start;
    uint32_t parsed = 0;
    patch_chunk_init(chunk);
    if (i >= count) {
        patch_set_error(doc, "Update hunk does not contain any lines");
        return false;
    }
    if (patch_trim_eq(lines[i], "@@")) {
        i++;
    } else {
        char *context = NULL;
        if (patch_trim_prefix(lines[i], "@@ ", &context)) {
            chunk->change_context = context;
            i++;
        } else if (!allow_missing_context) {
            patch_set_error(doc, "Expected update hunk to start with a @@ context marker");
            return false;
        }
    }

    for (; i < count; i++) {
        if (patch_trim_eq(lines[i], "*** End of File")) {
            if (parsed == 0) {
                patch_set_error(doc, "Update hunk does not contain any lines");
                return false;
            }
            chunk->is_end_of_file = true;
            i++;
            break;
        }
        if (lines[i][0] == '\0') {
            patch_line_vec_push(&chunk->old_lines, "");
            patch_line_vec_push(&chunk->new_lines, "");
            parsed++;
            continue;
        }
        if (lines[i][0] == ' ') {
            patch_line_vec_push(&chunk->old_lines, lines[i] + 1);
            patch_line_vec_push(&chunk->new_lines, lines[i] + 1);
            parsed++;
            continue;
        }
        if (lines[i][0] == '+') {
            patch_line_vec_push(&chunk->new_lines, lines[i] + 1);
            parsed++;
            continue;
        }
        if (lines[i][0] == '-') {
            patch_line_vec_push(&chunk->old_lines, lines[i] + 1);
            parsed++;
            continue;
        }
        if (parsed == 0) {
            patch_set_error(doc,
                            "Unexpected line found in update hunk: every line should start with space, '+', or '-'");
            return false;
        }
        break;
    }

    if (parsed == 0) {
        patch_set_error(doc, "Update hunk does not contain any lines");
        return false;
    }
    *consumed = i - start;
    return true;
}

static bool patch_parse_text(const char *patch_text, PatchDoc *doc) {
    char *copy = patch_trimmed_copy(patch_text);
    char **lines = NULL;
    uint32_t count = 0;
    patch_split_patch_lines(copy, &lines, &count);
    if (count < 2 || !patch_trim_eq(lines[0], "*** Begin Patch") ||
        !patch_trim_eq(lines[count - 1], "*** End Patch")) {
        patch_set_error(doc, "Invalid patch boundaries");
        free(lines);
        free(copy);
        return false;
    }

    uint32_t i = 1;
    while (i + 1 < count) {
        char *path = NULL;
        if (patch_trim_prefix(lines[i], "*** Add File: ", &path)) {
            PatchHunk hunk;
            CettaStringBuf contents;
            patch_hunk_init(&hunk, PATCH_HUNK_ADD, path);
            free(path);
            cetta_sb_init(&contents);
            i++;
            uint32_t added = 0;
            while (i + 1 < count && lines[i][0] == '+') {
                cetta_sb_append(&contents, lines[i] + 1);
                cetta_sb_append(&contents, "\n");
                added++;
                i++;
            }
            if (added == 0) {
                patch_set_error(doc, "Add file hunk is empty");
                cetta_sb_free(&contents);
                patch_hunk_free(&hunk);
                break;
            }
            hunk.contents = process_strdup_cstr(contents.buf ? contents.buf : "");
            cetta_sb_free(&contents);
            patch_doc_add_hunk(doc, &hunk);
            continue;
        }
        if (patch_trim_prefix(lines[i], "*** Delete File: ", &path)) {
            PatchHunk hunk;
            patch_hunk_init(&hunk, PATCH_HUNK_DELETE, path);
            free(path);
            patch_doc_add_hunk(doc, &hunk);
            i++;
            continue;
        }
        if (patch_trim_prefix(lines[i], "*** Update File: ", &path)) {
            PatchHunk hunk;
            patch_hunk_init(&hunk, PATCH_HUNK_UPDATE, path);
            free(path);
            i++;
            if (i + 1 < count && patch_trim_prefix(lines[i], "*** Move to: ", &path)) {
                hunk.move_path = path;
                i++;
            }
            while (i + 1 < count) {
                if (patch_trim_view(lines[i], NULL)[0] == '\0') {
                    i++;
                    continue;
                }
                if (patch_line_starts_hunk_marker(lines[i])) break;
                PatchChunk chunk;
                uint32_t consumed = 0;
                if (!patch_parse_chunk(lines, count - 1, i, hunk.chunk_len == 0,
                                       &chunk, &consumed, doc)) {
                    patch_hunk_free(&hunk);
                    goto done;
                }
                patch_hunk_add_chunk(&hunk, &chunk);
                i += consumed;
            }
            if (hunk.chunk_len == 0) {
                patch_set_error(doc, "Update file hunk is empty");
                patch_hunk_free(&hunk);
                break;
            }
            patch_doc_add_hunk(doc, &hunk);
            continue;
        }
        patch_set_error(doc, "'%s' is not a valid hunk header", lines[i]);
        break;
    }

done:
    free(lines);
    free(copy);
    return doc->error[0] == '\0' && doc->len > 0;
}

static bool patch_path_safe_relative(const char *path) {
    if (!path || path[0] == '\0' || path[0] == '/' || strchr(path, '\\')) return false;
    if (isalpha((unsigned char)path[0]) && path[1] == ':') return false;
    const char *p = path;
    while (*p) {
        const char *slash = strchr(p, '/');
        size_t len = slash ? (size_t)(slash - p) : strlen(p);
        if (len == 0 || (len == 1 && p[0] == '.') ||
            (len == 2 && p[0] == '.' && p[1] == '.')) {
            return false;
        }
        if (!slash) break;
        p = slash + 1;
    }
    return true;
}

static bool patch_join_path(const char *cwd,
                            const char *rel,
                            char *out,
                            size_t out_sz,
                            char *errbuf,
                            size_t errbuf_sz) {
    if (!patch_path_safe_relative(rel)) {
        snprintf(errbuf, errbuf_sz, "unsafe patch path: %s", rel ? rel : "");
        return false;
    }
    size_t cwd_len = strlen(cwd);
    int n = snprintf(out, out_sz, "%s%s%s", cwd,
                     (cwd_len > 0 && cwd[cwd_len - 1] == '/') ? "" : "/", rel);
    if (n < 0 || (size_t)n >= out_sz) {
        snprintf(errbuf, errbuf_sz, "patch path is too long");
        return false;
    }
    return true;
}

static bool patch_mkdirs_for_file(const char *path, char *errbuf, size_t errbuf_sz) {
    char tmp[PATH_MAX];
    snprintf(tmp, sizeof(tmp), "%s", path);
    for (char *p = tmp + 1; *p; p++) {
        if (*p != '/') continue;
        *p = '\0';
        if (mkdir(tmp, 0777) != 0 && errno != EEXIST) {
            snprintf(errbuf, errbuf_sz, "cannot create directory %.200s: %s",
                     tmp, strerror(errno));
            return false;
        }
        *p = '/';
    }
    return true;
}

static bool patch_write_text_creating_parents(const char *path,
                                              const char *text,
                                              char *errbuf,
                                              size_t errbuf_sz) {
    if (!patch_mkdirs_for_file(path, errbuf, errbuf_sz)) return false;
    return library_write_text_file(path, text, false, errbuf, errbuf_sz);
}

static void patch_split_content_lines(const char *text, PatchLineVec *out) {
    const char *start = text ? text : "";
    patch_line_vec_init(out);
    for (const char *p = start;; p++) {
        if (*p != '\n' && *p != '\0') continue;
        const char *stop = p;
        if (stop > start && stop[-1] == '\r') stop--;
        patch_line_vec_push_len(out, start, (size_t)(stop - start));
        if (*p == '\0') break;
        start = p + 1;
    }
    if (out->len > 0 && out->items[out->len - 1][0] == '\0' &&
        text && text[0] != '\0' && text[strlen(text) - 1] == '\n') {
        free(out->items[out->len - 1]);
        out->len--;
    }
}

static int patch_rstrip_cmp(const char *a, const char *b) {
    size_t alen = strlen(a);
    size_t blen = strlen(b);
    while (alen > 0 && isspace((unsigned char)a[alen - 1])) alen--;
    while (blen > 0 && isspace((unsigned char)b[blen - 1])) blen--;
    return alen == blen ? strncmp(a, b, alen) : 1;
}

static bool patch_trimmed_equal(const char *a, const char *b) {
    size_t alen;
    size_t blen;
    const char *atrim = patch_trim_view(a, &alen);
    const char *btrim = patch_trim_view(b, &blen);
    return alen == blen && strncmp(atrim, btrim, alen) == 0;
}

static bool patch_lines_match(PatchLineVec *lines,
                              PatchLineVec *pattern,
                              size_t index,
                              int mode) {
    for (uint32_t j = 0; j < pattern->len; j++) {
        const char *lhs = lines->items[index + j];
        const char *rhs = pattern->items[j];
        if (mode == 0 && strcmp(lhs, rhs) != 0) return false;
        if (mode == 1 && patch_rstrip_cmp(lhs, rhs) != 0) return false;
        if (mode == 2 && !patch_trimmed_equal(lhs, rhs)) return false;
    }
    return true;
}

static bool patch_seek_sequence(PatchLineVec *lines,
                                PatchLineVec *pattern,
                                size_t start,
                                bool eof,
                                size_t *found_out) {
    if (pattern->len == 0) {
        *found_out = start;
        return true;
    }
    if (pattern->len > lines->len) return false;
    size_t search_start = eof && lines->len >= pattern->len
                          ? lines->len - pattern->len
                          : start;
    if (search_start > lines->len - pattern->len) return false;
    for (int mode = 0; mode < 3; mode++) {
        for (size_t i = search_start; i <= lines->len - pattern->len; i++) {
            if (patch_lines_match(lines, pattern, i, mode)) {
                *found_out = i;
                return true;
            }
        }
    }
    return false;
}

static void patch_replacement_vec_init(PatchReplacementVec *vec) {
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void patch_replacement_vec_push(PatchReplacementVec *vec,
                                       size_t start,
                                       size_t old_len,
                                       PatchLineVec *new_lines) {
    if (vec->len >= vec->cap) {
        vec->cap = vec->cap ? vec->cap * 2u : 4u;
        vec->items = cetta_realloc(vec->items, sizeof(PatchReplacement) * vec->cap);
    }
    vec->items[vec->len].start = start;
    vec->items[vec->len].old_len = old_len;
    vec->items[vec->len].order = vec->len;
    patch_line_vec_init(&vec->items[vec->len].new_lines);
    for (uint32_t i = 0; i < new_lines->len; i++) {
        patch_line_vec_push(&vec->items[vec->len].new_lines, new_lines->items[i]);
    }
    vec->len++;
}

static void patch_replacement_vec_free(PatchReplacementVec *vec) {
    for (uint32_t i = 0; i < vec->len; i++) {
        patch_line_vec_free(&vec->items[i].new_lines);
    }
    free(vec->items);
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static int patch_replacement_cmp(const void *lhs, const void *rhs) {
    const PatchReplacement *a = lhs;
    const PatchReplacement *b = rhs;
    if (a->start < b->start) return -1;
    if (a->start > b->start) return 1;
    if (a->order < b->order) return -1;
    if (a->order > b->order) return 1;
    return 0;
}

static bool patch_compute_replacements(PatchLineVec *original,
                                       const char *display_path,
                                       PatchHunk *hunk,
                                       PatchReplacementVec *replacements,
                                       char *errbuf,
                                       size_t errbuf_sz) {
    size_t line_index = 0;
    for (uint32_t i = 0; i < hunk->chunk_len; i++) {
        PatchChunk *chunk = &hunk->chunks[i];
        if (chunk->change_context) {
            PatchLineVec context;
            size_t found;
            patch_line_vec_init(&context);
            patch_line_vec_push(&context, chunk->change_context);
            bool ok = patch_seek_sequence(original, &context, line_index, false, &found);
            patch_line_vec_free(&context);
            if (!ok) {
                snprintf(errbuf, errbuf_sz, "Failed to find context '%s' in %s",
                         chunk->change_context, display_path);
                return false;
            }
            line_index = found + 1;
        }
        if (chunk->old_lines.len == 0) {
            patch_replacement_vec_push(replacements, original->len, 0, &chunk->new_lines);
            continue;
        }

        PatchLineVec pattern = chunk->old_lines;
        PatchLineVec new_slice = chunk->new_lines;
        size_t found;
        bool ok = patch_seek_sequence(original, &pattern, line_index,
                                      chunk->is_end_of_file, &found);
        if (!ok && pattern.len > 0 && pattern.items[pattern.len - 1][0] == '\0') {
            pattern.len--;
            if (new_slice.len > 0 && new_slice.items[new_slice.len - 1][0] == '\0') {
                new_slice.len--;
            }
            ok = patch_seek_sequence(original, &pattern, line_index,
                                     chunk->is_end_of_file, &found);
        }
        if (!ok) {
            snprintf(errbuf, errbuf_sz, "Failed to find expected lines in %s", display_path);
            return false;
        }
        patch_replacement_vec_push(replacements, found, pattern.len, &new_slice);
        line_index = found + pattern.len;
    }
    qsort(replacements->items, replacements->len, sizeof(PatchReplacement),
          patch_replacement_cmp);
    return true;
}

static void patch_apply_replacements(PatchLineVec *original,
                                     PatchReplacementVec *replacements,
                                     PatchLineVec *out) {
    size_t pos = 0;
    patch_line_vec_init(out);
    for (uint32_t i = 0; i < replacements->len; i++) {
        PatchReplacement *r = &replacements->items[i];
        while (pos < r->start && pos < original->len) {
            patch_line_vec_push(out, original->items[pos++]);
        }
        for (uint32_t j = 0; j < r->new_lines.len; j++) {
            patch_line_vec_push(out, r->new_lines.items[j]);
        }
        pos = r->start + r->old_len;
    }
    while (pos < original->len) {
        patch_line_vec_push(out, original->items[pos++]);
    }
}

static char *patch_join_content(PatchLineVec *lines) {
    CettaStringBuf out;
    cetta_sb_init(&out);
    for (uint32_t i = 0; i < lines->len; i++) {
        if (i > 0) cetta_sb_append(&out, "\n");
        cetta_sb_append(&out, lines->items[i]);
    }
    if (lines->len > 0 && lines->items[lines->len - 1][0] != '\0') {
        cetta_sb_append(&out, "\n");
    }
    char *result = process_strdup_cstr(out.buf ? out.buf : "");
    cetta_sb_free(&out);
    return result;
}

static void patch_affected_vec_init(PatchAffectedVec *vec) {
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void patch_affected_vec_push(PatchAffectedVec *vec, char op, const char *path) {
    if (vec->len >= vec->cap) {
        vec->cap = vec->cap ? vec->cap * 2u : 4u;
        vec->items = cetta_realloc(vec->items, sizeof(PatchAffected) * vec->cap);
    }
    vec->items[vec->len].op = op;
    vec->items[vec->len].path = process_strdup_cstr(path);
    vec->len++;
}

static void patch_affected_vec_free(PatchAffectedVec *vec) {
    for (uint32_t i = 0; i < vec->len; i++) free(vec->items[i].path);
    free(vec->items);
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void patch_verified_change_vec_init(PatchVerifiedChangeVec *vec) {
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void patch_verified_change_free(PatchVerifiedChange *change) {
    if (!change) return;
    free(change->path);
    free(change->content);
    free(change->move_path);
    free(change->unified_diff);
    free(change->new_content);
}

static void patch_verified_change_vec_free(PatchVerifiedChangeVec *vec) {
    if (!vec) return;
    for (uint32_t i = 0; i < vec->len; i++) {
        patch_verified_change_free(&vec->items[i]);
    }
    free(vec->items);
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void patch_verified_change_vec_push(PatchVerifiedChangeVec *vec,
                                           PatchVerifiedChangeKind kind,
                                           const char *path,
                                           const char *content,
                                           const char *move_path,
                                           const char *unified_diff,
                                           const char *new_content) {
    if (vec->len >= vec->cap) {
        vec->cap = vec->cap ? vec->cap * 2u : 4u;
        vec->items = cetta_realloc(vec->items,
                                   sizeof(PatchVerifiedChange) * vec->cap);
    }
    PatchVerifiedChange *slot = &vec->items[vec->len++];
    slot->kind = kind;
    slot->path = process_strdup_cstr(path ? path : "");
    slot->content = content ? process_strdup_cstr(content) : NULL;
    slot->move_path = move_path ? process_strdup_cstr(move_path) : NULL;
    slot->unified_diff = unified_diff ? process_strdup_cstr(unified_diff) : NULL;
    slot->new_content = new_content ? process_strdup_cstr(new_content) : NULL;
}

static void patch_virtual_file_vec_init(PatchVirtualFileVec *vec) {
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void patch_virtual_file_free(PatchVirtualFile *file) {
    if (!file) return;
    free(file->path);
    free(file->content);
}

static void patch_virtual_file_vec_free(PatchVirtualFileVec *vec) {
    if (!vec) return;
    for (uint32_t i = 0; i < vec->len; i++) {
        patch_virtual_file_free(&vec->items[i]);
    }
    free(vec->items);
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static PatchVirtualFile *patch_virtual_file_find(PatchVirtualFileVec *vec,
                                                 const char *path) {
    for (uint32_t i = 0; i < vec->len; i++) {
        if (strcmp(vec->items[i].path, path) == 0) {
            return &vec->items[i];
        }
    }
    return NULL;
}

static PatchVirtualFile *patch_virtual_file_ensure(PatchVirtualFileVec *vec,
                                                   const char *path) {
    PatchVirtualFile *existing = patch_virtual_file_find(vec, path);
    if (existing) return existing;
    if (vec->len >= vec->cap) {
        vec->cap = vec->cap ? vec->cap * 2u : 4u;
        vec->items = cetta_realloc(vec->items,
                                   sizeof(PatchVirtualFile) * vec->cap);
    }
    PatchVirtualFile *slot = &vec->items[vec->len++];
    slot->path = process_strdup_cstr(path ? path : "");
    slot->kind = PATCH_VIRTUAL_MISSING;
    slot->content = NULL;
    return slot;
}

static bool patch_virtual_file_set(PatchVirtualFileVec *vec,
                                   const char *path,
                                   PatchVirtualFileKind kind,
                                   const char *content) {
    PatchVirtualFile *file = patch_virtual_file_ensure(vec, path);
    if (!file) return false;
    file->kind = kind;
    free(file->content);
    file->content = kind == PATCH_VIRTUAL_FILE
        ? process_strdup_cstr(content ? content : "")
        : NULL;
    return true;
}

static PatchVirtualFile *patch_virtual_file_get_or_load(
    const char *cwd,
    const char *path,
    PatchVirtualFileVec *vec,
    char *errbuf,
    size_t errbuf_sz
) {
    PatchVirtualFile *file = patch_virtual_file_find(vec, path);
    if (file) return file;

    file = patch_virtual_file_ensure(vec, path);
    if (!file) return NULL;

    char path_abs[PATH_MAX];
    struct stat st;
    if (!patch_join_path(cwd, path, path_abs, sizeof(path_abs), errbuf, errbuf_sz)) {
        return NULL;
    }
    if (stat(path_abs, &st) != 0) {
        if (errno == ENOENT) {
            file->kind = PATCH_VIRTUAL_MISSING;
            return file;
        }
        snprintf(errbuf, errbuf_sz, "cannot stat file: %s", strerror(errno));
        return NULL;
    }
    if (S_ISDIR(st.st_mode)) {
        file->kind = PATCH_VIRTUAL_DIRECTORY;
        return file;
    }

    CettaStringBuf text;
    if (!library_read_text_file(path_abs, &text, errbuf, errbuf_sz)) {
        return NULL;
    }
    file->kind = PATCH_VIRTUAL_FILE;
    free(file->content);
    file->content = process_strdup_cstr(text.buf ? text.buf : "");
    cetta_sb_free(&text);
    return file;
}

static char *patch_format_update_hunk(PatchHunk *hunk) {
    CettaStringBuf out;
    cetta_sb_init(&out);
    for (uint32_t i = 0; i < hunk->chunk_len; i++) {
        PatchChunk *chunk = &hunk->chunks[i];
        if (chunk->change_context) {
            cetta_sb_append(&out, "@@ ");
            cetta_sb_append(&out, chunk->change_context);
            cetta_sb_append(&out, "\n");
        } else {
            cetta_sb_append(&out, "@@\n");
        }
        for (uint32_t j = 0; j < chunk->old_lines.len; j++) {
            cetta_sb_append(&out, "-");
            cetta_sb_append(&out, chunk->old_lines.items[j]);
            cetta_sb_append(&out, "\n");
        }
        for (uint32_t j = 0; j < chunk->new_lines.len; j++) {
            cetta_sb_append(&out, "+");
            cetta_sb_append(&out, chunk->new_lines.items[j]);
            cetta_sb_append(&out, "\n");
        }
        if (chunk->is_end_of_file) {
            cetta_sb_append(&out, "*** End of File\n");
        }
    }
    char *result = process_strdup_cstr(out.buf ? out.buf : "");
    cetta_sb_free(&out);
    return result;
}

static bool patch_verify_doc(const char *cwd,
                             PatchDoc *doc,
                             PatchVerifiedChangeVec *verified,
                             char *errbuf,
                             size_t errbuf_sz) {
    PatchVirtualFileVec virtual_files;
    patch_virtual_file_vec_init(&virtual_files);

    for (uint32_t i = 0; i < doc->len; i++) {
        PatchHunk *hunk = &doc->hunks[i];
        char path_abs[PATH_MAX];
        if (!patch_join_path(cwd, hunk->path, path_abs, sizeof(path_abs),
                             errbuf, errbuf_sz)) {
            patch_virtual_file_vec_free(&virtual_files);
            return false;
        }

        if (hunk->kind == PATCH_HUNK_ADD) {
            patch_verified_change_vec_push(verified, PATCH_VERIFIED_ADD,
                                           hunk->path, hunk->contents,
                                           NULL, NULL, NULL);
            patch_virtual_file_set(&virtual_files, hunk->path,
                                   PATCH_VIRTUAL_FILE,
                                   hunk->contents ? hunk->contents : "");
            continue;
        }

        if (hunk->kind == PATCH_HUNK_DELETE) {
            PatchVirtualFile *file = patch_virtual_file_get_or_load(
                cwd, hunk->path, &virtual_files, errbuf, errbuf_sz);
            if (!file) {
                patch_virtual_file_vec_free(&virtual_files);
                return false;
            }
            if (file->kind == PATCH_VIRTUAL_MISSING) {
                snprintf(errbuf, errbuf_sz,
                         "Failed to read file to delete %s: %s",
                         hunk->path, strerror(ENOENT));
                patch_virtual_file_vec_free(&virtual_files);
                return false;
            }
            if (file->kind == PATCH_VIRTUAL_DIRECTORY) {
                snprintf(errbuf, errbuf_sz,
                         "Failed to delete file %s: path is a directory",
                         hunk->path);
                patch_virtual_file_vec_free(&virtual_files);
                return false;
            }
            patch_verified_change_vec_push(verified, PATCH_VERIFIED_DELETE,
                                           hunk->path, file->content,
                                           NULL, NULL, NULL);
            patch_virtual_file_set(&virtual_files, hunk->path,
                                   PATCH_VIRTUAL_MISSING, NULL);
            continue;
        }

        PatchVirtualFile *file = patch_virtual_file_get_or_load(
            cwd, hunk->path, &virtual_files, errbuf, errbuf_sz);
        if (!file) {
            patch_virtual_file_vec_free(&virtual_files);
            return false;
        }
        if (file->kind == PATCH_VIRTUAL_MISSING) {
            snprintf(errbuf, errbuf_sz,
                     "Failed to read file to update %s: %s",
                     hunk->path, strerror(ENOENT));
            patch_virtual_file_vec_free(&virtual_files);
            return false;
        }
        if (file->kind == PATCH_VIRTUAL_DIRECTORY) {
            snprintf(errbuf, errbuf_sz,
                     "Failed to read file to update %s: %s",
                     hunk->path, strerror(EISDIR));
            patch_virtual_file_vec_free(&virtual_files);
            return false;
        }

        PatchLineVec original_lines;
        PatchReplacementVec replacements;
        PatchLineVec new_lines;
        char *new_text = NULL;
        char *unified_diff = NULL;
        patch_split_content_lines(file->content ? file->content : "", &original_lines);
        patch_replacement_vec_init(&replacements);
        if (!patch_compute_replacements(&original_lines, hunk->path, hunk,
                                        &replacements, errbuf, errbuf_sz)) {
            patch_replacement_vec_free(&replacements);
            patch_line_vec_free(&original_lines);
            patch_virtual_file_vec_free(&virtual_files);
            return false;
        }
        patch_apply_replacements(&original_lines, &replacements, &new_lines);
        new_text = patch_join_content(&new_lines);
        unified_diff = patch_format_update_hunk(hunk);

        if (hunk->move_path) {
            char dest_abs[PATH_MAX];
            if (!patch_join_path(cwd, hunk->move_path, dest_abs, sizeof(dest_abs),
                                 errbuf, errbuf_sz)) {
                free(new_text);
                free(unified_diff);
                patch_line_vec_free(&new_lines);
                patch_replacement_vec_free(&replacements);
                patch_line_vec_free(&original_lines);
                patch_virtual_file_vec_free(&virtual_files);
                return false;
            }
        }

        patch_verified_change_vec_push(verified, PATCH_VERIFIED_UPDATE,
                                       hunk->path, NULL, hunk->move_path,
                                       unified_diff, new_text);
        if (hunk->move_path) {
            patch_virtual_file_set(&virtual_files, hunk->move_path,
                                   PATCH_VIRTUAL_FILE, new_text);
            patch_virtual_file_set(&virtual_files, hunk->path,
                                   PATCH_VIRTUAL_MISSING, NULL);
        } else {
            patch_virtual_file_set(&virtual_files, hunk->path,
                                   PATCH_VIRTUAL_FILE, new_text);
        }

        free(unified_diff);
        free(new_text);
        patch_line_vec_free(&new_lines);
        patch_replacement_vec_free(&replacements);
        patch_line_vec_free(&original_lines);
    }

    patch_virtual_file_vec_free(&virtual_files);
    return true;
}

static Atom *patch_action_atom(Arena *a,
                               const char *cwd,
                               PatchVerifiedChangeVec *verified) {
    Atom **changes = verified->len
        ? arena_alloc(a, sizeof(Atom *) * verified->len)
        : NULL;
    for (uint32_t i = 0; i < verified->len; i++) {
        PatchVerifiedChange *change = &verified->items[i];
        if (change->kind == PATCH_VERIFIED_ADD) {
            changes[i] = atom_expr(a, (Atom *[]){
                atom_symbol(a, "PatchActionAdd"),
                atom_string(a, change->path ? change->path : ""),
                atom_string(a, change->content ? change->content : ""),
            }, 3);
            continue;
        }
        if (change->kind == PATCH_VERIFIED_DELETE) {
            changes[i] = atom_expr(a, (Atom *[]){
                atom_symbol(a, "PatchActionDelete"),
                atom_string(a, change->path ? change->path : ""),
                atom_string(a, change->content ? change->content : ""),
            }, 3);
            continue;
        }
        changes[i] = atom_expr(a, (Atom *[]){
            atom_symbol(a, "PatchActionUpdate"),
            atom_string(a, change->path ? change->path : ""),
            atom_string(a, change->unified_diff ? change->unified_diff : ""),
            change->move_path
                ? atom_string(a, change->move_path)
                : atom_symbol(a, "PatchNoMove"),
            atom_string(a, change->new_content ? change->new_content : ""),
        }, 5);
    }
    Atom *action = atom_expr(a, (Atom *[]){
        atom_symbol(a, "PatchAction"),
        atom_string(a, cwd ? cwd : ""),
        atom_expr(a, changes, verified->len),
    }, 3);
    return action;
}

static Atom *patch_inspect_result_atom(Arena *a,
                                       bool ok,
                                       const char *error_text,
                                       Atom *action) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "PatchInspectResult"),
        ok ? atom_true(a) : atom_false(a),
        atom_string(a, error_text ? error_text : ""),
        action ? action : atom_symbol(a, "PatchNoAction"),
    }, 4);
}

static Atom *patch_inspect(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *cwd;
    const char *patch_text;
    PatchDoc doc;
    PatchVerifiedChangeVec verified;
    char errbuf[512] = {0};
    Atom *result;

    if (nargs != 2 || !(cwd = library_text_arg(args[0])) ||
        !(patch_text = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected cwd and patch text");
    }

    patch_doc_init(&doc);
    patch_verified_change_vec_init(&verified);
    if (!patch_parse_text(patch_text, &doc)) {
        snprintf(errbuf, sizeof(errbuf), "%s",
                 doc.error[0] ? doc.error : "Invalid patch");
        result = patch_inspect_result_atom(a, false, errbuf, NULL);
        goto cleanup;
    }
    if (!patch_verify_doc(cwd, &doc, &verified, errbuf, sizeof(errbuf))) {
        result = patch_inspect_result_atom(a, false, errbuf, NULL);
        goto cleanup;
    }
    result = patch_inspect_result_atom(
        a, true, "", patch_action_atom(a, cwd, &verified));

cleanup:
    patch_verified_change_vec_free(&verified);
    patch_doc_free(&doc);
    return result;
}

static bool patch_apply_doc(const char *cwd,
                            PatchDoc *doc,
                            PatchAffectedVec *affected,
                            char *errbuf,
                            size_t errbuf_sz) {
    for (uint32_t i = 0; i < doc->len; i++) {
        PatchHunk *hunk = &doc->hunks[i];
        char path_abs[PATH_MAX];
        if (!patch_join_path(cwd, hunk->path, path_abs, sizeof(path_abs),
                             errbuf, errbuf_sz)) {
            return false;
        }
        if (hunk->kind == PATCH_HUNK_ADD) {
            if (!patch_write_text_creating_parents(path_abs, hunk->contents,
                                                   errbuf, errbuf_sz)) {
                return false;
            }
            patch_affected_vec_push(affected, 'A', hunk->path);
            continue;
        }
        if (hunk->kind == PATCH_HUNK_DELETE) {
            struct stat st;
            if (stat(path_abs, &st) != 0) {
                snprintf(errbuf, errbuf_sz, "Failed to delete file %.200s: %s",
                         path_abs, strerror(errno));
                return false;
            }
            if (S_ISDIR(st.st_mode)) {
                snprintf(errbuf, errbuf_sz,
                         "Failed to delete file %.200s: path is a directory",
                         path_abs);
                return false;
            }
            if (unlink(path_abs) != 0) {
                snprintf(errbuf, errbuf_sz, "Failed to delete file %.200s: %s",
                         path_abs, strerror(errno));
                return false;
            }
            patch_affected_vec_push(affected, 'D', hunk->path);
            continue;
        }

        CettaStringBuf original_text;
        PatchLineVec original_lines;
        PatchReplacementVec replacements;
        PatchLineVec new_lines;
        char *new_text = NULL;
        if (!library_read_text_file(path_abs, &original_text, errbuf, errbuf_sz)) {
            return false;
        }
        patch_split_content_lines(original_text.buf ? original_text.buf : "", &original_lines);
        patch_replacement_vec_init(&replacements);
        if (!patch_compute_replacements(&original_lines, hunk->path, hunk,
                                        &replacements, errbuf, errbuf_sz)) {
            patch_replacement_vec_free(&replacements);
            patch_line_vec_free(&original_lines);
            cetta_sb_free(&original_text);
            return false;
        }
        patch_apply_replacements(&original_lines, &replacements, &new_lines);
        new_text = patch_join_content(&new_lines);

        if (hunk->move_path) {
            char dest_abs[PATH_MAX];
            if (!patch_join_path(cwd, hunk->move_path, dest_abs, sizeof(dest_abs),
                                 errbuf, errbuf_sz) ||
                !patch_write_text_creating_parents(dest_abs, new_text,
                                                   errbuf, errbuf_sz)) {
                free(new_text);
                patch_line_vec_free(&new_lines);
                patch_replacement_vec_free(&replacements);
                patch_line_vec_free(&original_lines);
                cetta_sb_free(&original_text);
                return false;
            }
            if (unlink(path_abs) != 0) {
                snprintf(errbuf, errbuf_sz, "Failed to remove original %.200s: %s",
                         path_abs, strerror(errno));
                free(new_text);
                patch_line_vec_free(&new_lines);
                patch_replacement_vec_free(&replacements);
                patch_line_vec_free(&original_lines);
                cetta_sb_free(&original_text);
                return false;
            }
            patch_affected_vec_push(affected, 'M', hunk->path);
        } else {
            if (!library_write_text_file(path_abs, new_text, false, errbuf, errbuf_sz)) {
                free(new_text);
                patch_line_vec_free(&new_lines);
                patch_replacement_vec_free(&replacements);
                patch_line_vec_free(&original_lines);
                cetta_sb_free(&original_text);
                return false;
            }
            patch_affected_vec_push(affected, 'M', hunk->path);
        }
        free(new_text);
        patch_line_vec_free(&new_lines);
        patch_replacement_vec_free(&replacements);
        patch_line_vec_free(&original_lines);
        cetta_sb_free(&original_text);
    }
    return true;
}

static Atom *patch_result_atom(Arena *a, bool ok, const char *stdout_text,
                               const char *stderr_text, PatchAffectedVec *affected) {
    Atom **changes = affected->len
        ? arena_alloc(a, sizeof(Atom *) * affected->len)
        : NULL;
    for (uint32_t i = 0; i < affected->len; i++) {
        char op[2] = {affected->items[i].op, '\0'};
        changes[i] = atom_expr(a, (Atom *[]){
            atom_symbol(a, "PatchChange"),
            atom_string(a, op),
            atom_string(a, affected->items[i].path),
        }, 3);
    }
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "PatchResult"),
        ok ? atom_true(a) : atom_false(a),
        atom_string(a, stdout_text ? stdout_text : ""),
        atom_string(a, stderr_text ? stderr_text : ""),
        atom_expr(a, changes, affected->len),
    }, 5);
}

static Atom *patch_apply(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *cwd;
    const char *patch_text;
    PatchDoc doc;
    PatchAffectedVec affected;
    CettaStringBuf stdout_buf;
    char errbuf[512] = {0};
    Atom *result;
    if (nargs != 2 || !(cwd = library_text_arg(args[0])) ||
        !(patch_text = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected cwd and patch text");
    }
    patch_doc_init(&doc);
    patch_affected_vec_init(&affected);
    cetta_sb_init(&stdout_buf);
    if (!patch_parse_text(patch_text, &doc)) {
        snprintf(errbuf, sizeof(errbuf), "%s",
                 doc.error[0] ? doc.error : "Invalid patch");
        result = patch_result_atom(a, false, "", errbuf, &affected);
        goto cleanup;
    }
    if (!patch_apply_doc(cwd, &doc, &affected, errbuf, sizeof(errbuf))) {
        result = patch_result_atom(a, false, "", errbuf, &affected);
        goto cleanup;
    }
    cetta_sb_append(&stdout_buf, "Success. Updated the following files:\n");
    for (uint32_t i = 0; i < affected.len; i++) {
        char line[PATH_MAX + 8];
        snprintf(line, sizeof(line), "%c %s\n", affected.items[i].op,
                 affected.items[i].path);
        cetta_sb_append(&stdout_buf, line);
    }
    result = patch_result_atom(a, true, stdout_buf.buf ? stdout_buf.buf : "",
                               "", &affected);

cleanup:
    cetta_sb_free(&stdout_buf);
    patch_affected_vec_free(&affected);
    patch_doc_free(&doc);
    return result;
}

static const char *patch_skip_spaces(const char *p) {
    while (*p == ' ' || *p == '\t') p++;
    return p;
}

static bool patch_is_command_boundary(char c) {
    return c == '\0' || c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

static char *patch_parse_shell_word(const char **p_in) {
    const char *p = patch_skip_spaces(*p_in);
    char quote = '\0';
    CettaStringBuf out;
    cetta_sb_init(&out);
    if (*p == '\'' || *p == '"') {
        quote = *p++;
        while (*p && *p != quote) {
            cetta_sb_append_n(&out, p, 1);
            p++;
        }
        if (*p != quote) {
            cetta_sb_free(&out);
            return NULL;
        }
        p++;
    } else {
        while (*p && *p != ' ' && *p != '\t' && *p != '\n' && *p != '\r') {
            cetta_sb_append_n(&out, p, 1);
            p++;
        }
    }
    *p_in = p;
    return process_strdup_cstr(out.buf ? out.buf : "");
}

static bool patch_extract_shell_heredoc(const char *command,
                                        char **patch_out,
                                        char **workdir_out) {
    char *trimmed = patch_trimmed_copy(command);
    const char *p = trimmed;
    char *cd_path = NULL;
    char *delim = NULL;
    char *patch_body = NULL;
    bool matched = false;

    p = patch_skip_spaces(p);
    if (strncmp(p, "cd", 2) == 0 && patch_is_command_boundary(p[2])) {
        p += 2;
        cd_path = patch_parse_shell_word(&p);
        if (!cd_path || cd_path[0] == '\0') goto done;
        p = patch_skip_spaces(p);
        if (strncmp(p, "&&", 2) != 0) goto done;
        p += 2;
        p = patch_skip_spaces(p);
    }

    if (strncmp(p, "apply_patch", 11) == 0 && patch_is_command_boundary(p[11])) {
        p += 11;
    } else if (strncmp(p, "applypatch", 10) == 0 && patch_is_command_boundary(p[10])) {
        p += 10;
    } else {
        goto done;
    }

    p = patch_skip_spaces(p);
    if (strncmp(p, "<<", 2) != 0) goto done;
    p += 2;
    if (*p == '-') p++;
    delim = patch_parse_shell_word(&p);
    if (!delim || delim[0] == '\0') goto done;
    p = patch_skip_spaces(p);
    if (*p != '\n' && *p != '\r') goto done;
    if (*p == '\r') p++;
    if (*p != '\n') goto done;
    p++;

    const char *body_start = p;
    size_t delim_len = strlen(delim);
    while (*p) {
        const char *line_start = p;
        const char *line_end = strchr(p, '\n');
        const char *content_end = line_end ? line_end : p + strlen(p);
        if (content_end > line_start && content_end[-1] == '\r') content_end--;
        if ((size_t)(content_end - line_start) == delim_len &&
            strncmp(line_start, delim, delim_len) == 0) {
            const char *tail = line_end ? line_end + 1 : content_end;
            while (*tail == ' ' || *tail == '\t' || *tail == '\n' || *tail == '\r') {
                tail++;
            }
            if (*tail != '\0') goto done;
            const char *body_end = line_start;
            if (body_end > body_start && body_end[-1] == '\n') body_end--;
            if (body_end > body_start && body_end[-1] == '\r') body_end--;
            patch_body = process_strdup_len(body_start, (size_t)(body_end - body_start));
            matched = true;
            break;
        }
        if (!line_end) break;
        p = line_end + 1;
    }

done:
    if (matched) {
        *patch_out = patch_body;
        *workdir_out = cd_path;
        patch_body = NULL;
        cd_path = NULL;
    }
    free(trimmed);
    free(cd_path);
    free(delim);
    free(patch_body);
    return matched;
}

static bool patch_join_workdir(const char *cwd,
                               const char *cd_path,
                               char *out,
                               size_t out_sz,
                               char *errbuf,
                               size_t errbuf_sz) {
    if (!cd_path || cd_path[0] == '\0' || strcmp(cd_path, ".") == 0) {
        snprintf(out, out_sz, "%s", cwd);
        return true;
    }
    return patch_join_path(cwd, cd_path, out, out_sz, errbuf, errbuf_sz);
}

static Atom *patch_shell_intercept_atom(Arena *a, bool matched, Atom *result) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "PatchShellIntercept"),
        matched ? atom_true(a) : atom_false(a),
        result ? result : atom_symbol(a, "PatchNoResult"),
    }, 3);
}

static Atom *patch_shell_inspect_atom(Arena *a,
                                      bool matched,
                                      const char *effective_cwd,
                                      const char *patch_text,
                                      Atom *result) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "PatchShellInspect"),
        matched ? atom_true(a) : atom_false(a),
        atom_string(a, effective_cwd ? effective_cwd : ""),
        atom_string(a, patch_text ? patch_text : ""),
        result ? result : atom_symbol(a, "PatchNoResult"),
    }, 5);
}

static Atom *patch_inspect_shell_command(Arena *a,
                                         Atom *head,
                                         Atom **args,
                                         uint32_t nargs) {
    const char *cwd;
    const char *command;
    char *patch_text = NULL;
    char *cd_path = NULL;
    char effective_cwd[PATH_MAX];
    char errbuf[512] = {0};
    PatchDoc doc;
    PatchVerifiedChangeVec verified;
    Atom *inspect_result;
    Atom *shell_result;

    if (nargs != 2 || !(cwd = library_text_arg(args[0])) ||
        !(command = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected cwd and shell command");
    }

    if (!patch_extract_shell_heredoc(command, &patch_text, &cd_path)) {
        return patch_shell_inspect_atom(a, false, "", "", NULL);
    }

    patch_doc_init(&doc);
    patch_verified_change_vec_init(&verified);

    if (!patch_join_workdir(cwd, cd_path, effective_cwd, sizeof(effective_cwd),
                            errbuf, sizeof(errbuf))) {
        inspect_result = patch_inspect_result_atom(a, false, errbuf, NULL);
        shell_result = patch_shell_inspect_atom(a, true, "", patch_text,
                                                inspect_result);
        goto cleanup;
    }
    if (!patch_parse_text(patch_text, &doc)) {
        snprintf(errbuf, sizeof(errbuf), "%s",
                 doc.error[0] ? doc.error : "Invalid patch");
        inspect_result = patch_inspect_result_atom(a, false, errbuf, NULL);
        shell_result = patch_shell_inspect_atom(a, true, effective_cwd,
                                                patch_text, inspect_result);
        goto cleanup;
    }
    if (!patch_verify_doc(effective_cwd, &doc, &verified, errbuf, sizeof(errbuf))) {
        inspect_result = patch_inspect_result_atom(a, false, errbuf, NULL);
        shell_result = patch_shell_inspect_atom(a, true, effective_cwd,
                                                patch_text, inspect_result);
        goto cleanup;
    }

    inspect_result = patch_inspect_result_atom(
        a, true, "", patch_action_atom(a, effective_cwd, &verified));
    shell_result = patch_shell_inspect_atom(a, true, effective_cwd,
                                            patch_text, inspect_result);

cleanup:
    patch_verified_change_vec_free(&verified);
    patch_doc_free(&doc);
    free(patch_text);
    free(cd_path);
    return shell_result;
}

static Atom *patch_intercept_shell_command(Arena *a,
                                           Atom *head,
                                           Atom **args,
                                           uint32_t nargs) {
    const char *cwd;
    const char *command;
    char *patch_text = NULL;
    char *cd_path = NULL;
    char effective_cwd[PATH_MAX];
    char errbuf[512] = {0};
    PatchDoc doc;
    PatchAffectedVec affected;
    CettaStringBuf stdout_buf;
    Atom *patch_result;
    Atom *intercept_result;

    if (nargs != 2 || !(cwd = library_text_arg(args[0])) ||
        !(command = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected cwd and shell command");
    }

    if (!patch_extract_shell_heredoc(command, &patch_text, &cd_path)) {
        return patch_shell_intercept_atom(a, false, NULL);
    }

    patch_doc_init(&doc);
    patch_affected_vec_init(&affected);
    cetta_sb_init(&stdout_buf);

    if (!patch_join_workdir(cwd, cd_path, effective_cwd, sizeof(effective_cwd),
                            errbuf, sizeof(errbuf))) {
        patch_result = patch_result_atom(a, false, "", errbuf, &affected);
        intercept_result = patch_shell_intercept_atom(a, true, patch_result);
        goto cleanup;
    }
    if (!patch_parse_text(patch_text, &doc)) {
        snprintf(errbuf, sizeof(errbuf), "%s",
                 doc.error[0] ? doc.error : "Invalid patch");
        patch_result = patch_result_atom(a, false, "", errbuf, &affected);
        intercept_result = patch_shell_intercept_atom(a, true, patch_result);
        goto cleanup;
    }
    if (!patch_apply_doc(effective_cwd, &doc, &affected, errbuf, sizeof(errbuf))) {
        patch_result = patch_result_atom(a, false, "", errbuf, &affected);
        intercept_result = patch_shell_intercept_atom(a, true, patch_result);
        goto cleanup;
    }

    cetta_sb_append(&stdout_buf, "Success. Updated the following files:\n");
    for (uint32_t i = 0; i < affected.len; i++) {
        char line[PATH_MAX + 8];
        snprintf(line, sizeof(line), "%c %s\n", affected.items[i].op,
                 affected.items[i].path);
        cetta_sb_append(&stdout_buf, line);
    }
    patch_result = patch_result_atom(a, true, stdout_buf.buf ? stdout_buf.buf : "",
                                     "", &affected);
    intercept_result = patch_shell_intercept_atom(a, true, patch_result);

cleanup:
    cetta_sb_free(&stdout_buf);
    patch_affected_vec_free(&affected);
    patch_doc_free(&doc);
    free(patch_text);
    free(cd_path);
    return intercept_result;
}

static Atom *cetta_library_dispatch_patch(Arena *a, Atom *head,
                                          Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_patch_inspect) {
        return patch_inspect(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_patch_inspect_shell_command) {
        return patch_inspect_shell_command(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_patch_apply) {
        return patch_apply(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_patch_intercept_shell_command) {
        return patch_intercept_shell_command(a, head, args, nargs);
    }
    return NULL;
}

static Atom *git_repo_root_atom(Arena *a, bool ok, const char *root) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "GitRepoRoot"),
        ok ? atom_true(a) : atom_false(a),
        atom_string(a, root ? root : ""),
    }, 3);
}

static Atom *git_value_atom(Arena *a, bool ok, const char *value,
                            const char *stderr_text) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "GitValue"),
        ok ? atom_true(a) : atom_false(a),
        atom_string(a, value ? value : ""),
        atom_string(a, stderr_text ? stderr_text : ""),
    }, 4);
}

static Atom *git_commit_atom(Arena *a, const char *sha, int64_t timestamp,
                             const char *subject) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "GitCommit"),
        atom_string(a, sha ? sha : ""),
        atom_int(a, timestamp),
        atom_string(a, subject ? subject : ""),
    }, 4);
}

static Atom *git_bool_atom(Arena *a, bool ok, bool value,
                           const char *stderr_text) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "GitBool"),
        ok ? atom_true(a) : atom_false(a),
        value ? atom_true(a) : atom_false(a),
        atom_string(a, stderr_text ? stderr_text : ""),
    }, 4);
}

static Atom *git_command_result_atom(Arena *a, bool ok, int exit_code,
                                     const char *stdout_text,
                                     const char *stderr_text,
                                     bool timed_out) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "GitCommandResult"),
        ok ? atom_true(a) : atom_false(a),
        atom_int(a, exit_code),
        atom_string(a, stdout_text ? stdout_text : ""),
        atom_string(a, stderr_text ? stderr_text : ""),
        timed_out ? atom_true(a) : atom_false(a),
    }, 6);
}

static Atom *git_info_atom(Arena *a, bool ok, const char *repo_root,
                           const char *head_commit, const char *branch,
                           const char *remote_url, bool has_changes) {
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, "GitInfo"),
        ok ? atom_true(a) : atom_false(a),
        atom_string(a, repo_root ? repo_root : ""),
        atom_string(a, head_commit ? head_commit : ""),
        atom_string(a, branch ? branch : ""),
        atom_string(a, remote_url ? remote_url : ""),
        has_changes ? atom_true(a) : atom_false(a),
    }, 7);
}

typedef struct {
    char **items;
    uint32_t len;
    uint32_t cap;
} GitStringVec;

static void git_string_vec_init(GitStringVec *vec) {
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void git_string_vec_free(GitStringVec *vec) {
    for (uint32_t i = 0; i < vec->len; i++) {
        free(vec->items[i]);
    }
    free(vec->items);
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void git_string_vec_push(GitStringVec *vec, const char *text) {
    if (vec->len >= vec->cap) {
        vec->cap = vec->cap ? vec->cap * 2u : 8u;
        vec->items = cetta_realloc(vec->items, sizeof(char *) * vec->cap);
    }
    vec->items[vec->len++] = process_strdup_cstr(text ? text : "");
}

static int git_string_ptr_cmp(const void *lhs, const void *rhs) {
    const char *const *a = (const char *const *)lhs;
    const char *const *b = (const char *const *)rhs;
    return strcmp(*a, *b);
}

static Atom *git_string_vec_atom(Arena *a, const GitStringVec *vec) {
    Atom **items = vec->len ? arena_alloc(a, sizeof(Atom *) * vec->len) : NULL;
    for (uint32_t i = 0; i < vec->len; i++) {
        items[i] = atom_string(a, vec->items[i]);
    }
    return atom_expr(a, items, vec->len);
}

static bool git_find_repo_root_path(const char *base,
                                    char *out,
                                    size_t out_sz) {
    char current[PATH_MAX];
    struct stat st;
    if (!base || base[0] == '\0' || !out || out_sz == 0)
        return false;
    if (!realpath(base, current))
        return false;
    if (stat(current, &st) != 0)
        return false;
    if (!S_ISDIR(st.st_mode)) {
        char *slash = strrchr(current, '/');
        if (!slash)
            return false;
        if (slash == current) {
            slash[1] = '\0';
        } else {
            *slash = '\0';
        }
    }

    for (;;) {
        char git_entry[PATH_MAX];
        int n = snprintf(git_entry, sizeof(git_entry), "%s/.git", current);
        if (n > 0 && (size_t)n < sizeof(git_entry) &&
            stat(git_entry, &st) == 0 &&
            (S_ISDIR(st.st_mode) || S_ISREG(st.st_mode))) {
            snprintf(out, out_sz, "%s", current);
            return true;
        }
        if (strcmp(current, "/") == 0 || current[0] == '\0')
            break;
        char *slash = strrchr(current, '/');
        if (!slash)
            break;
        if (slash == current) {
            current[1] = '\0';
        } else {
            *slash = '\0';
        }
    }
    return false;
}

static Atom *git_run_process(Arena *a,
                             Atom *head,
                             Atom **args,
                             uint32_t nargs,
                             const char *cwd,
                             const char **git_args,
                             uint32_t git_argc,
                             int max_bytes) {
    char **argv = arena_alloc(a, sizeof(char *) * ((size_t)git_argc + 2u));
    const char *old_optional_locks = getenv("GIT_OPTIONAL_LOCKS");
    char *old_copy = old_optional_locks
        ? process_strdup_cstr(old_optional_locks)
        : NULL;
    Atom *result;
    argv[0] = (char *)"git";
    for (uint32_t i = 0; i < git_argc; i++) {
        argv[i + 1] = (char *)git_args[i];
    }
    argv[git_argc + 1] = NULL;

    setenv("GIT_OPTIONAL_LOCKS", "0", 1);
    result = process_run_exec_impl(a, head, args, nargs, argv, cwd,
                                   NULL, 0, false, 5000, max_bytes);
    if (old_copy) {
        setenv("GIT_OPTIONAL_LOCKS", old_copy, 1);
        free(old_copy);
    } else {
        unsetenv("GIT_OPTIONAL_LOCKS");
    }
    return result;
}

static bool git_process_result_fields(Atom *process_result,
                                      int *exit_code,
                                      const char **stdout_text,
                                      const char **stderr_text,
                                      bool *timed_out) {
    if (!process_result || process_result->kind != ATOM_EXPR ||
        process_result->expr.len != 7 ||
        !atom_is_symbol(process_result->expr.elems[0], "ProcessResult")) {
        return false;
    }
    if (!library_int_arg(process_result->expr.elems[1], exit_code))
        return false;
    *stdout_text = library_text_arg(process_result->expr.elems[2]);
    *stderr_text = library_text_arg(process_result->expr.elems[3]);
    if (!*stdout_text || !*stderr_text ||
        !library_bool_arg(process_result->expr.elems[6], timed_out)) {
        return false;
    }
    return true;
}

static char *git_trimmed_copy(const char *text) {
    const char *start = text ? text : "";
    const char *end = start + strlen(start);
    while (*start && isspace((unsigned char)*start)) start++;
    while (end > start && isspace((unsigned char)end[-1])) end--;
    return process_strdup_len(start, (size_t)(end - start));
}

static bool git_string_nonempty_non_option(const char *text) {
    return text && text[0] != '\0' && text[0] != '-';
}

static Atom *git_command_result_from_process(Arena *a,
                                             Atom *process_result) {
    int exit_code = -1;
    const char *stdout_text = "";
    const char *stderr_text = "";
    bool timed_out = false;
    if (!git_process_result_fields(process_result, &exit_code, &stdout_text,
                                   &stderr_text, &timed_out)) {
        return process_result;
    }
    return git_command_result_atom(a, exit_code == 0 && !timed_out, exit_code,
                                   stdout_text, stderr_text, timed_out);
}

static bool git_run_trimmed_value(Arena *a,
                                  Atom *head,
                                  Atom **args,
                                  uint32_t nargs,
                                  const char *cwd,
                                  const char **git_args,
                                  uint32_t git_argc,
                                  char **value_out,
                                  char **stderr_out) {
    Atom *process_result = git_run_process(a, head, args, nargs, cwd,
                                           git_args, git_argc, 1048576);
    int exit_code = -1;
    const char *stdout_text = "";
    const char *stderr_text = "";
    bool timed_out = false;
    *value_out = process_strdup_cstr("");
    *stderr_out = process_strdup_cstr("");
    if (!git_process_result_fields(process_result, &exit_code, &stdout_text,
                                   &stderr_text, &timed_out)) {
        free(*stderr_out);
        *stderr_out = process_strdup_cstr("git command did not return ProcessResult");
        return false;
    }
    free(*stderr_out);
    *stderr_out = git_trimmed_copy(stderr_text);
    if (exit_code != 0 || timed_out)
        return false;
    free(*value_out);
    *value_out = git_trimmed_copy(stdout_text);
    return true;
}

static bool git_run_text(Arena *a,
                         Atom *head,
                         Atom **args,
                         uint32_t nargs,
                         const char *cwd,
                         const char **git_args,
                         uint32_t git_argc,
                         int max_bytes,
                         bool allow_diff_exit,
                         char **stdout_out,
                         char **stderr_out,
                         int *exit_code_out) {
    Atom *process_result = git_run_process(a, head, args, nargs, cwd,
                                           git_args, git_argc, max_bytes);
    int exit_code = -1;
    const char *stdout_text = "";
    const char *stderr_text = "";
    bool timed_out = false;
    *stdout_out = process_strdup_cstr("");
    *stderr_out = process_strdup_cstr("");
    if (!git_process_result_fields(process_result, &exit_code, &stdout_text,
                                   &stderr_text, &timed_out)) {
        free(*stderr_out);
        *stderr_out = process_strdup_cstr("git command did not return ProcessResult");
        if (exit_code_out) *exit_code_out = -1;
        return false;
    }
    free(*stdout_out);
    free(*stderr_out);
    *stdout_out = process_strdup_cstr(stdout_text);
    *stderr_out = process_strdup_cstr(stderr_text);
    if (exit_code_out) *exit_code_out = exit_code;
    if (timed_out) return false;
    return allow_diff_exit ? (exit_code == 0 || exit_code == 1) : (exit_code == 0);
}

static void git_parse_lines_into_vec(const char *text, GitStringVec *vec) {
    const char *p = text ? text : "";
    while (*p) {
        const char *line_start = p;
        const char *line_end = strchr(p, '\n');
        const char *content_end = line_end ? line_end : p + strlen(p);
        while (content_end > line_start &&
               (content_end[-1] == '\r' || content_end[-1] == '\n')) {
            content_end--;
        }
        const char *trim_start = line_start;
        const char *trim_end = content_end;
        while (trim_start < trim_end && isspace((unsigned char)*trim_start)) {
            trim_start++;
        }
        while (trim_end > trim_start && isspace((unsigned char)trim_end[-1])) {
            trim_end--;
        }
        if (trim_end > trim_start) {
            char *line = process_strdup_len(trim_start, (size_t)(trim_end - trim_start));
            git_string_vec_push(vec, line);
            free(line);
        }
        if (!line_end) break;
        p = line_end + 1;
    }
}

static bool git_get_remotes(Arena *a,
                            Atom *head,
                            Atom **args,
                            uint32_t nargs,
                            const char *cwd,
                            GitStringVec *remotes) {
    const char *git_args[] = {"remote"};
    char *stdout_text = NULL;
    char *stderr_text = NULL;
    int exit_code = -1;
    bool ok = git_run_text(a, head, args, nargs, cwd, git_args, 1, 1048576,
                           false, &stdout_text, &stderr_text, &exit_code);
    if (ok) {
        git_parse_lines_into_vec(stdout_text, remotes);
        for (uint32_t i = 0; i < remotes->len; i++) {
            if (strcmp(remotes->items[i], "origin") == 0) {
                char *origin = remotes->items[i];
                memmove(&remotes->items[1], &remotes->items[0], sizeof(char *) * i);
                remotes->items[0] = origin;
                break;
            }
        }
    }
    free(stdout_text);
    free(stderr_text);
    return ok;
}

static bool git_local_default_branch(Arena *a,
                                     Atom *head,
                                     Atom **args,
                                     uint32_t nargs,
                                     const char *cwd,
                                     char **branch_out) {
    const char *candidates[] = {"main", "master"};
    *branch_out = process_strdup_cstr("");
    for (uint32_t i = 0; i < 2; i++) {
        char ref[64];
        snprintf(ref, sizeof(ref), "refs/heads/%s", candidates[i]);
        const char *verify_args[] = {"rev-parse", "--verify", "--quiet", ref};
        char *value = NULL;
        char *stderr_text = NULL;
        bool ok = git_run_trimmed_value(a, head, args, nargs, cwd, verify_args, 4,
                                        &value, &stderr_text);
        free(value);
        free(stderr_text);
        if (ok) {
            free(*branch_out);
            *branch_out = process_strdup_cstr(candidates[i]);
            return true;
        }
    }
    return false;
}

static bool git_default_branch_name_value(Arena *a,
                                          Atom *head,
                                          Atom **args,
                                          uint32_t nargs,
                                          const char *cwd,
                                          char **branch_out,
                                          char **stderr_out) {
    GitStringVec remotes;
    git_string_vec_init(&remotes);
    *branch_out = process_strdup_cstr("");
    *stderr_out = process_strdup_cstr("");

    if (git_get_remotes(a, head, args, nargs, cwd, &remotes)) {
        for (uint32_t i = 0; i < remotes.len; i++) {
            char symref[PATH_MAX];
            snprintf(symref, sizeof(symref), "refs/remotes/%s/HEAD", remotes.items[i]);
            const char *sym_args[] = {"symbolic-ref", "--quiet", symref};
            char *sym = NULL;
            char *stderr_text = NULL;
            bool ok = git_run_trimmed_value(a, head, args, nargs, cwd, sym_args, 3,
                                            &sym, &stderr_text);
            if (ok) {
                const char *slash = strrchr(sym, '/');
                const char *name = slash ? slash + 1 : sym;
                if (name[0] != '\0') {
                    free(*branch_out);
                    *branch_out = process_strdup_cstr(name);
                    free(*stderr_out);
                    *stderr_out = stderr_text;
                    free(sym);
                    git_string_vec_free(&remotes);
                    return true;
                }
            }
            free(sym);
            free(stderr_text);

            const char *show_args[] = {"remote", "show", remotes.items[i]};
            char *stdout_text = NULL;
            char *show_stderr = NULL;
            int exit_code = -1;
            ok = git_run_text(a, head, args, nargs, cwd, show_args, 3, 1048576,
                              false, &stdout_text, &show_stderr, &exit_code);
            if (ok) {
                const char *needle = "HEAD branch:";
                const char *line = stdout_text;
                while (line && *line) {
                    const char *line_end = strchr(line, '\n');
                    size_t line_len = line_end ? (size_t)(line_end - line) : strlen(line);
                    while (line_len > 0 && isspace((unsigned char)*line)) {
                        line++;
                        line_len--;
                    }
                    if (line_len >= strlen(needle) &&
                        strncmp(line, needle, strlen(needle)) == 0) {
                        const char *name_start = line + strlen(needle);
                        const char *name_end = line + line_len;
                        while (name_start < name_end &&
                               isspace((unsigned char)*name_start)) {
                            name_start++;
                        }
                        while (name_end > name_start &&
                               isspace((unsigned char)name_end[-1])) {
                            name_end--;
                        }
                        if (name_end > name_start) {
                            free(*branch_out);
                            *branch_out = process_strdup_len(
                                name_start, (size_t)(name_end - name_start));
                            free(*stderr_out);
                            *stderr_out = show_stderr;
                            free(stdout_text);
                            git_string_vec_free(&remotes);
                            return true;
                        }
                    }
                    line = line_end ? line_end + 1 : NULL;
                }
            }
            free(stdout_text);
            free(show_stderr);
        }
    }
    git_string_vec_free(&remotes);

    char *local_branch = NULL;
    bool local_ok = git_local_default_branch(a, head, args, nargs, cwd, &local_branch);
    if (local_ok) {
        free(*branch_out);
        *branch_out = local_branch;
        return true;
    }
    free(local_branch);
    return false;
}

static Atom *git_repo_root(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *cwd;
    char root[PATH_MAX];
    if (nargs != 1 || !(cwd = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected cwd");
    }
    if (!git_find_repo_root_path(cwd, root, sizeof(root))) {
        return git_repo_root_atom(a, false, "");
    }
    return git_repo_root_atom(a, true, root);
}

static Atom *git_value_command(Arena *a, Atom *head, Atom **args, uint32_t nargs,
                               const char **git_args, uint32_t git_argc,
                               bool drop_detached_head) {
    const char *cwd;
    char *value = NULL;
    char *stderr_text = NULL;
    bool ok;
    Atom *result;
    if (nargs != 1 || !(cwd = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected cwd");
    }
    ok = git_run_trimmed_value(a, head, args, nargs, cwd, git_args, git_argc,
                               &value, &stderr_text);
    if (ok && drop_detached_head && strcmp(value, "HEAD") == 0) {
        ok = false;
        value[0] = '\0';
    }
    result = git_value_atom(a, ok, value, stderr_text);
    free(value);
    free(stderr_text);
    return result;
}

static Atom *git_current_branch(Arena *a, Atom *head,
                                Atom **args, uint32_t nargs) {
    const char *git_args[] = {"rev-parse", "--abbrev-ref", "HEAD"};
    return git_value_command(a, head, args, nargs, git_args, 3, true);
}

static Atom *git_default_branch(Arena *a, Atom *head,
                                Atom **args, uint32_t nargs) {
    const char *cwd;
    char *branch = NULL;
    char *stderr_text = NULL;
    bool ok;
    Atom *result;
    if (nargs != 1 || !(cwd = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected cwd");
    }
    ok = git_default_branch_name_value(a, head, args, nargs, cwd,
                                       &branch, &stderr_text);
    result = git_value_atom(a, ok, branch, stderr_text);
    free(branch);
    free(stderr_text);
    return result;
}

static Atom *git_head_commit(Arena *a, Atom *head,
                             Atom **args, uint32_t nargs) {
    const char *git_args[] = {"rev-parse", "HEAD"};
    return git_value_command(a, head, args, nargs, git_args, 2, false);
}

static Atom *git_remote_url(Arena *a, Atom *head,
                            Atom **args, uint32_t nargs) {
    const char *cwd;
    const char *remote;
    char *value = NULL;
    char *stderr_text = NULL;
    bool ok;
    Atom *result;
    if (nargs != 2 || !(cwd = library_text_arg(args[0])) ||
        !(remote = library_text_arg(args[1])) || remote[0] == '\0' ||
        remote[0] == '-') {
        return library_signature_error(a, head, args, nargs,
                                       "expected cwd and remote name");
    }
    const char *git_args[] = {"remote", "get-url", remote};
    ok = git_run_trimmed_value(a, head, args, nargs, cwd, git_args, 3,
                               &value, &stderr_text);
    result = git_value_atom(a, ok, value, stderr_text);
    free(value);
    free(stderr_text);
    return result;
}

static Atom *git_has_changes(Arena *a, Atom *head,
                             Atom **args, uint32_t nargs) {
    const char *cwd;
    char *status_text = NULL;
    char *stderr_text = NULL;
    bool ok;
    Atom *result;
    if (nargs != 1 || !(cwd = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected cwd");
    }
    const char *git_args[] = {"status", "--porcelain"};
    ok = git_run_trimmed_value(a, head, args, nargs, cwd, git_args, 2,
                               &status_text, &stderr_text);
    result = git_bool_atom(a, ok, ok && status_text[0] != '\0', stderr_text);
    free(status_text);
    free(stderr_text);
    return result;
}

static Atom *git_status_porcelain(Arena *a, Atom *head,
                                  Atom **args, uint32_t nargs) {
    const char *cwd;
    const char *git_args[] = {"status", "--porcelain"};
    if (nargs != 1 || !(cwd = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected cwd");
    }
    return git_command_result_from_process(
        a, git_run_process(a, head, args, nargs, cwd, git_args, 2, 1048576));
}

static Atom *git_diff(Arena *a, Atom *head,
                      Atom **args, uint32_t nargs) {
    const char *cwd;
    const char *git_args[] = {"diff", "--no-textconv", "--no-ext-diff", "--no-color"};
    if (nargs != 1 || !(cwd = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected cwd");
    }
    return git_command_result_from_process(
        a, git_run_process(a, head, args, nargs, cwd, git_args, 4, 4194304));
}

static Atom *git_diff_against(Arena *a, Atom *head,
                              Atom **args, uint32_t nargs) {
    const char *cwd;
    const char *revspec;
    char *diff_stdout = NULL;
    char *diff_stderr = NULL;
    int exit_code = -1;
    CettaStringBuf out;
    Atom *result;
    if (nargs != 2 || !(cwd = library_text_arg(args[0])) ||
        !(revspec = library_text_arg(args[1])) ||
        !git_string_nonempty_non_option(revspec)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected cwd and non-option revspec");
    }
    const char *diff_args[] = {"diff", "--no-textconv", "--no-ext-diff",
                               "--no-color", revspec};
    bool ok = git_run_text(a, head, args, nargs, cwd, diff_args, 5, 4194304,
                           true, &diff_stdout, &diff_stderr, &exit_code);
    if (!ok) {
        result = git_command_result_atom(a, false, exit_code,
                                         diff_stdout, diff_stderr, false);
        free(diff_stdout);
        free(diff_stderr);
        return result;
    }

    cetta_sb_init(&out);
    cetta_sb_append(&out, diff_stdout);

    const char *ls_args[] = {"ls-files", "--others", "--exclude-standard"};
    char *ls_stdout = NULL;
    char *ls_stderr = NULL;
    int ls_exit_code = -1;
    if (git_run_text(a, head, args, nargs, cwd, ls_args, 3, 1048576, false,
                     &ls_stdout, &ls_stderr, &ls_exit_code)) {
        const char *p = ls_stdout;
        while (p && *p) {
            const char *line_start = p;
            const char *line_end = strchr(p, '\n');
            const char *content_end = line_end ? line_end : p + strlen(p);
            while (content_end > line_start &&
                   (content_end[-1] == '\r' || content_end[-1] == '\n')) {
                content_end--;
            }
            if (content_end > line_start) {
                char *file = process_strdup_len(line_start,
                                                (size_t)(content_end - line_start));
                const char *extra_args[] = {
                    "diff", "--no-textconv", "--no-ext-diff", "--binary",
                    "--no-color", "--no-index", "--", "/dev/null", file
                };
                char *extra_stdout = NULL;
                char *extra_stderr = NULL;
                int extra_exit_code = -1;
                if (git_run_text(a, head, args, nargs, cwd, extra_args, 9,
                                 4194304, true, &extra_stdout, &extra_stderr,
                                 &extra_exit_code)) {
                    cetta_sb_append(&out, extra_stdout);
                }
                free(extra_stdout);
                free(extra_stderr);
                free(file);
            }
            if (!line_end) break;
            p = line_end + 1;
        }
    }
    free(ls_stdout);
    free(ls_stderr);

    result = git_command_result_atom(a, true, exit_code,
                                     out.buf ? out.buf : "", diff_stderr, false);
    cetta_sb_free(&out);
    free(diff_stdout);
    free(diff_stderr);
    return result;
}

static Atom *git_show(Arena *a, Atom *head,
                      Atom **args, uint32_t nargs) {
    const char *cwd;
    const char *revspec;
    if (nargs != 2 || !(cwd = library_text_arg(args[0])) ||
        !(revspec = library_text_arg(args[1])) ||
        !git_string_nonempty_non_option(revspec)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected cwd and non-option revspec");
    }
    const char *git_args[] = {"show", "--no-textconv", "--no-ext-diff", "--no-color", revspec};
    return git_command_result_from_process(
        a, git_run_process(a, head, args, nargs, cwd, git_args, 5, 4194304));
}

static Atom *git_recent_commits(Arena *a, Atom *head,
                                Atom **args, uint32_t nargs) {
    const char *cwd;
    int limit = 0;
    char limit_arg[32];
    const char *git_dir_args[] = {"rev-parse", "--git-dir"};
    char *check_stdout = NULL;
    char *check_stderr = NULL;
    int check_exit = -1;
    Atom **items = NULL;
    uint32_t nitems = 0;
    uint32_t cap = 0;
    if (nargs != 2 || !(cwd = library_text_arg(args[0])) ||
        !library_int_arg(args[1], &limit) || limit < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected cwd and non-negative limit");
    }
    if (!git_run_text(a, head, args, nargs, cwd, git_dir_args, 2, 1048576,
                      false, &check_stdout, &check_stderr, &check_exit)) {
        free(check_stdout);
        free(check_stderr);
        return atom_expr(a, NULL, 0);
    }
    free(check_stdout);
    free(check_stderr);

    snprintf(limit_arg, sizeof(limit_arg), "%d", limit);
    const char *log_args_with_limit[] = {
        "log", "-n", limit_arg, "--pretty=format:%H\x1f%ct\x1f%s"
    };
    const char *log_args_all[] = {
        "log", "--pretty=format:%H\x1f%ct\x1f%s"
    };
    char *stdout_text = NULL;
    char *stderr_text = NULL;
    int exit_code = -1;
    bool ok = limit > 0
        ? git_run_text(a, head, args, nargs, cwd, log_args_with_limit, 4,
                       1048576, false, &stdout_text, &stderr_text, &exit_code)
        : git_run_text(a, head, args, nargs, cwd, log_args_all, 2,
                       1048576, false, &stdout_text, &stderr_text, &exit_code);
    if (!ok) {
        free(stdout_text);
        free(stderr_text);
        return atom_expr(a, NULL, 0);
    }

    const char *p = stdout_text;
    while (p && *p) {
        const char *line_end = strchr(p, '\n');
        const char *content_end = line_end ? line_end : p + strlen(p);
        const char *sep1 = memchr(p, '\x1f', (size_t)(content_end - p));
        const char *sep2 = sep1
            ? memchr(sep1 + 1, '\x1f', (size_t)(content_end - sep1 - 1))
            : NULL;
        if (sep1 && sep2 && sep1 > p && sep2 > sep1 + 1) {
            char *sha = process_strdup_len(p, (size_t)(sep1 - p));
            char *ts_text = process_strdup_len(sep1 + 1, (size_t)(sep2 - sep1 - 1));
            char *subject = process_strdup_len(sep2 + 1, (size_t)(content_end - sep2 - 1));
            int64_t timestamp = (int64_t)strtoll(ts_text, NULL, 10);
            if (nitems >= cap) {
                cap = cap ? cap * 2u : 8u;
                items = cetta_realloc(items, sizeof(Atom *) * cap);
            }
            items[nitems++] = git_commit_atom(a, sha, timestamp, subject);
            free(sha);
            free(ts_text);
            free(subject);
        }
        if (!line_end) break;
        p = line_end + 1;
    }
    Atom **out_items = nitems ? arena_alloc(a, sizeof(Atom *) * nitems) : NULL;
    for (uint32_t i = 0; i < nitems; i++) out_items[i] = items[i];
    free(items);
    free(stdout_text);
    free(stderr_text);
    return atom_expr(a, out_items, nitems);
}

static Atom *git_local_branches(Arena *a, Atom *head,
                                Atom **args, uint32_t nargs) {
    const char *cwd;
    char *stdout_text = NULL;
    char *stderr_text = NULL;
    int exit_code = -1;
    GitStringVec branches;
    Atom *result;
    if (nargs != 1 || !(cwd = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected cwd");
    }
    git_string_vec_init(&branches);
    const char *branch_args[] = {"branch", "--format=%(refname:short)"};
    if (git_run_text(a, head, args, nargs, cwd, branch_args, 2, 1048576,
                     false, &stdout_text, &stderr_text, &exit_code)) {
        git_parse_lines_into_vec(stdout_text, &branches);
        if (branches.len > 1) {
            qsort(branches.items, branches.len, sizeof(char *), git_string_ptr_cmp);
        }
        char *base = NULL;
        if (git_local_default_branch(a, head, args, nargs, cwd, &base)) {
            for (uint32_t i = 0; i < branches.len; i++) {
                if (strcmp(branches.items[i], base) == 0) {
                    char *base_item = branches.items[i];
                    memmove(&branches.items[1], &branches.items[0], sizeof(char *) * i);
                    branches.items[0] = base_item;
                    break;
                }
            }
        }
        free(base);
    }
    result = git_string_vec_atom(a, &branches);
    git_string_vec_free(&branches);
    free(stdout_text);
    free(stderr_text);
    return result;
}

static bool git_resolve_branch_ref(Arena *a,
                                   Atom *head,
                                   Atom **args,
                                   uint32_t nargs,
                                   const char *cwd,
                                   const char *branch,
                                   char **resolved_out) {
    const char *verify_args[] = {"rev-parse", "--verify", branch};
    char *stderr_text = NULL;
    bool ok = git_run_trimmed_value(a, head, args, nargs, cwd, verify_args, 3,
                                    resolved_out, &stderr_text);
    free(stderr_text);
    return ok;
}

static bool git_resolve_upstream_if_remote_ahead(Arena *a,
                                                 Atom *head,
                                                 Atom **args,
                                                 uint32_t nargs,
                                                 const char *cwd,
                                                 const char *branch,
                                                 char **upstream_out) {
    char upstream_ref[PATH_MAX];
    snprintf(upstream_ref, sizeof(upstream_ref), "%s@{upstream}", branch);
    const char *upstream_args[] = {
        "rev-parse", "--abbrev-ref", "--symbolic-full-name", upstream_ref
    };
    char *upstream = NULL;
    char *stderr_text = NULL;
    bool ok = git_run_trimmed_value(a, head, args, nargs, cwd, upstream_args, 4,
                                    &upstream, &stderr_text);
    free(stderr_text);
    if (!ok || upstream[0] == '\0') {
        free(upstream);
        return false;
    }

    char range[PATH_MAX * 2];
    snprintf(range, sizeof(range), "%s...%s", branch, upstream);
    const char *count_args[] = {"rev-list", "--left-right", "--count", range};
    char *counts = NULL;
    char *count_stderr = NULL;
    ok = git_run_trimmed_value(a, head, args, nargs, cwd, count_args, 4,
                               &counts, &count_stderr);
    free(count_stderr);
    if (!ok) {
        free(upstream);
        free(counts);
        return false;
    }
    char *endptr = NULL;
    (void)strtoll(counts, &endptr, 10);
    int64_t right = 0;
    if (endptr) {
        while (*endptr && isspace((unsigned char)*endptr)) endptr++;
        right = strtoll(endptr, NULL, 10);
    }
    free(counts);
    if (right > 0) {
        *upstream_out = upstream;
        return true;
    }
    free(upstream);
    return false;
}

static Atom *git_merge_base_with_head(Arena *a, Atom *head,
                                      Atom **args, uint32_t nargs) {
    const char *cwd;
    const char *branch;
    char root[PATH_MAX];
    char *head_sha = NULL;
    char *branch_ref = NULL;
    char *upstream = NULL;
    char *preferred_ref = NULL;
    char *merge_base = NULL;
    char *stderr_text = NULL;
    Atom *result;
    if (nargs != 2 || !(cwd = library_text_arg(args[0])) ||
        !(branch = library_text_arg(args[1])) ||
        !git_string_nonempty_non_option(branch)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected cwd and non-option branch");
    }
    if (!git_find_repo_root_path(cwd, root, sizeof(root))) {
        return git_value_atom(a, false, "", "not a git repository");
    }
    const char *head_args[] = {"rev-parse", "--verify", "HEAD"};
    if (!git_run_trimmed_value(a, head, args, nargs, root, head_args, 3,
                               &head_sha, &stderr_text)) {
        result = git_value_atom(a, false, "", stderr_text);
        goto cleanup;
    }
    free(stderr_text);
    stderr_text = NULL;
    if (!git_resolve_branch_ref(a, head, args, nargs, root, branch, &branch_ref)) {
        result = git_value_atom(a, false, "", "");
        goto cleanup;
    }
    preferred_ref = branch_ref;
    if (git_resolve_upstream_if_remote_ahead(a, head, args, nargs, root,
                                             branch, &upstream)) {
        char *upstream_ref = NULL;
        if (git_resolve_branch_ref(a, head, args, nargs, root, upstream,
                                   &upstream_ref)) {
            preferred_ref = upstream_ref;
        } else {
            free(upstream_ref);
        }
    }
    const char *merge_args[] = {"merge-base", head_sha, preferred_ref};
    bool ok = git_run_trimmed_value(a, head, args, nargs, root, merge_args, 3,
                                    &merge_base, &stderr_text);
    result = git_value_atom(a, ok, ok ? merge_base : "", stderr_text);
    if (preferred_ref != branch_ref) free(preferred_ref);

cleanup:
    free(head_sha);
    free(branch_ref);
    free(upstream);
    free(merge_base);
    free(stderr_text);
    return result;
}

static Atom *git_collect_info(Arena *a, Atom *head,
                              Atom **args, uint32_t nargs) {
    const char *cwd;
    char root[PATH_MAX];
    char *head_commit = NULL;
    char *branch = NULL;
    char *remote_url = NULL;
    char *status_text = NULL;
    char *stderr_text = NULL;
    bool ok_head;
    bool ok_branch;
    bool ok_remote;
    bool ok_status;
    Atom *result;
    if (nargs != 1 || !(cwd = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected cwd");
    }
    if (!git_find_repo_root_path(cwd, root, sizeof(root))) {
        return git_info_atom(a, false, "", "", "", "", false);
    }

    const char *head_args[] = {"rev-parse", "HEAD"};
    ok_head = git_run_trimmed_value(a, head, args, nargs, cwd, head_args, 2,
                                    &head_commit, &stderr_text);
    free(stderr_text);
    stderr_text = NULL;

    const char *branch_args[] = {"rev-parse", "--abbrev-ref", "HEAD"};
    ok_branch = git_run_trimmed_value(a, head, args, nargs, cwd, branch_args, 3,
                                      &branch, &stderr_text);
    free(stderr_text);
    stderr_text = NULL;
    if (ok_branch && strcmp(branch, "HEAD") == 0) {
        ok_branch = false;
        branch[0] = '\0';
    }

    const char *remote_args[] = {"remote", "get-url", "origin"};
    ok_remote = git_run_trimmed_value(a, head, args, nargs, cwd, remote_args, 3,
                                      &remote_url, &stderr_text);
    free(stderr_text);
    stderr_text = NULL;

    const char *status_args[] = {"status", "--porcelain"};
    ok_status = git_run_trimmed_value(a, head, args, nargs, cwd, status_args, 2,
                                      &status_text, &stderr_text);
    free(stderr_text);

    result = git_info_atom(a, true, root,
                           ok_head ? head_commit : "",
                           ok_branch ? branch : "",
                           ok_remote ? remote_url : "",
                           ok_status && status_text[0] != '\0');
    free(head_commit);
    free(branch);
    free(remote_url);
    free(status_text);
    return result;
}

static Atom *cetta_library_dispatch_git(Arena *a, Atom *head,
                                        Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_git_repo_root) {
        return git_repo_root(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_current_branch) {
        return git_current_branch(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_default_branch) {
        return git_default_branch(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_head_commit) {
        return git_head_commit(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_remote_url) {
        return git_remote_url(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_has_changes) {
        return git_has_changes(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_status_porcelain) {
        return git_status_porcelain(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_diff) {
        return git_diff(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_diff_against) {
        return git_diff_against(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_show) {
        return git_show(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_recent_commits) {
        return git_recent_commits(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_local_branches) {
        return git_local_branches(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_merge_base_with_head) {
        return git_merge_base_with_head(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_git_collect_info) {
        return git_collect_info(a, head, args, nargs);
    }
    return NULL;
}

static Atom *fs_exists(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *path;
    struct stat st;
    if (nargs != 1 || !(path = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected filename");
    }
    return stat(path, &st) == 0 ? atom_true(a) : atom_false(a);
}

static Atom *fs_read_text(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *path;
    CettaStringBuf text;
    char errbuf[160];
    Atom *result;
    if (nargs != 1 || !(path = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected filename");
    }
    if (!library_read_text_file(path, &text, errbuf, sizeof(errbuf))) {
        return atom_error(a, library_call_expr(a, head, args, nargs), atom_string(a, errbuf));
    }
    result = atom_string(a, text.buf ? text.buf : "");
    cetta_sb_free(&text);
    return result;
}

static Atom *fs_write_like(Arena *a, Atom *head, Atom **args, uint32_t nargs, bool append) {
    const char *path;
    const char *text;
    char errbuf[160];
    if (nargs != 2 || !(path = library_text_arg(args[0])) ||
        !(text = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected filename and text");
    }
    if (!library_write_text_file(path, text, append, errbuf, sizeof(errbuf))) {
        return atom_error(a, library_call_expr(a, head, args, nargs), atom_string(a, errbuf));
    }
    return atom_unit(a);
}

static Atom *fs_write_text(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    return fs_write_like(a, head, args, nargs, false);
}

static Atom *fs_append_text(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    return fs_write_like(a, head, args, nargs, true);
}

static Atom *fs_read_lines(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *path;
    CettaStringBuf text;
    char errbuf[160];
    char **items = NULL;
    uint32_t nitems = 0;
    uint32_t cap = 0;
    size_t start = 0;
    size_t len;
    Atom *result;

    if (nargs != 1 || !(path = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected filename");
    }
    if (!library_read_text_file(path, &text, errbuf, sizeof(errbuf))) {
        return atom_error(a, library_call_expr(a, head, args, nargs), atom_string(a, errbuf));
    }

    len = text.len;
    if (len == 0) {
        result = atom_expr(a, NULL, 0);
        cetta_sb_free(&text);
        return result;
    }

    for (size_t i = 0; i <= len; i++) {
        bool at_end = (i == len);
        bool at_break = (!at_end && text.buf[i] == '\n');
        if (!at_end && !at_break) continue;
        size_t stop = i;
        if (stop > start && text.buf[stop - 1] == '\r') {
            stop--;
        }
        if (!(at_end && start == len)) {
            if (nitems >= cap) {
                cap = cap ? cap * 2 : 8;
                items = cetta_realloc(items, sizeof(char *) * cap);
            }
            size_t seg_len = stop - start;
            char *line = cetta_malloc(seg_len + 1);
            memcpy(line, text.buf + start, seg_len);
            line[seg_len] = '\0';
            items[nitems++] = line;
        }
        start = i + 1;
    }

    if (nitems > 0 && text.buf[len - 1] == '\n' && items[nitems - 1][0] == '\0') {
        free(items[nitems - 1]);
        nitems--;
    }

    result = library_string_list(a, items, nitems);
    for (uint32_t i = 0; i < nitems; i++) {
        free(items[i]);
    }
    free(items);
    cetta_sb_free(&text);
    return result;
}

static Atom *cetta_library_dispatch_fs(Arena *a, Atom *head,
                                       Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_fs_exists) {
        return fs_exists(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_fs_read_text) {
        return fs_read_text(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_fs_write_text) {
        return fs_write_text(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_fs_append_text) {
        return fs_append_text(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_fs_read_lines) {
        return fs_read_lines(a, head, args, nargs);
    }
    return NULL;
}

static Atom *str_length(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *text;
    if (nargs != 1 || !(text = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected text argument");
    }
    return atom_int(a, (int64_t)strlen(text));
}

static Atom *str_concat(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *lhs;
    const char *rhs;
    CettaStringBuf out;
    Atom *result;
    if (nargs != 2 || !(lhs = library_text_arg(args[0])) || !(rhs = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs, "expected two text arguments");
    }
    cetta_sb_init(&out);
    cetta_sb_append(&out, lhs);
    cetta_sb_append(&out, rhs);
    result = atom_string(a, out.buf ? out.buf : "");
    cetta_sb_free(&out);
    return result;
}

static Atom *str_split(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *sep;
    const char *text;
    size_t sep_len;
    size_t text_len;
    size_t start = 0;
    char **items = NULL;
    uint32_t nitems = 0;
    uint32_t cap = 0;
    Atom *result;

    if (nargs != 2 || !(sep = library_text_arg(args[0])) || !(text = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs, "expected separator and text");
    }
    sep_len = strlen(sep);
    text_len = strlen(text);
    if (sep_len == 0) {
        return library_signature_error(a, head, args, nargs,
                                       "separator must be non-empty");
    }

    while (1) {
        const char *found = strstr(text + start, sep);
        size_t stop = found ? (size_t)(found - text) : text_len;
        if (nitems >= cap) {
            cap = cap ? cap * 2 : 8;
            items = cetta_realloc(items, sizeof(char *) * cap);
        }
        size_t seg_len = stop - start;
        char *piece = cetta_malloc(seg_len + 1);
        memcpy(piece, text + start, seg_len);
        piece[seg_len] = '\0';
        items[nitems++] = piece;
        if (!found) break;
        start = stop + sep_len;
    }

    result = library_string_list(a, items, nitems);
    for (uint32_t i = 0; i < nitems; i++) {
        free(items[i]);
    }
    free(items);
    return result;
}

static Atom *str_split_whitespace(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *text;
    char **items = NULL;
    uint32_t nitems = 0;
    uint32_t cap = 0;
    Atom *result;

    if (nargs != 1 || !(text = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected text argument");
    }

    while (*text) {
        while (*text && isspace((unsigned char)*text)) text++;
        if (!*text) break;
        const char *start = text;
        while (*text && !isspace((unsigned char)*text)) text++;
        size_t seg_len = (size_t)(text - start);
        char *piece = cetta_malloc(seg_len + 1);
        memcpy(piece, start, seg_len);
        piece[seg_len] = '\0';
        if (nitems >= cap) {
            cap = cap ? cap * 2 : 8;
            items = cetta_realloc(items, sizeof(char *) * cap);
        }
        items[nitems++] = piece;
    }

    result = library_string_list(a, items, nitems);
    for (uint32_t i = 0; i < nitems; i++) {
        free(items[i]);
    }
    free(items);
    return result;
}

static Atom *str_join(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *sep;
    CettaStringBuf out;
    Atom *result;
    if (nargs != 2 || !(sep = library_text_arg(args[0])) || !library_expr_of_texts(args[1])) {
        return library_signature_error(a, head, args, nargs,
                                       "expected separator and expression of text");
    }
    cetta_sb_init(&out);
    for (uint32_t i = 0; i < args[1]->expr.len; i++) {
        if (i > 0) cetta_sb_append(&out, sep);
        cetta_sb_append(&out, library_text_arg(args[1]->expr.elems[i]));
    }
    result = atom_string(a, out.buf ? out.buf : "");
    cetta_sb_free(&out);
    return result;
}

static Atom *str_slice(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *text;
    int start;
    int stop;
    size_t len;
    if (nargs != 3 || !(text = library_text_arg(args[0])) ||
        !library_int_arg(args[1], &start) || !library_int_arg(args[2], &stop) ||
        start < 0 || stop < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected text, non-negative start, non-negative end");
    }
    len = strlen(text);
    if ((size_t)start > len) start = (int)len;
    if ((size_t)stop > len) stop = (int)len;
    if (stop < start) stop = start;
    char *slice = cetta_malloc((size_t)(stop - start) + 1);
    memcpy(slice, text + start, (size_t)(stop - start));
    slice[stop - start] = '\0';
    Atom *result = atom_string(a, slice);
    free(slice);
    return result;
}

static Atom *str_find(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *haystack;
    const char *needle;
    const char *found;
    if (nargs != 2 || !(haystack = library_text_arg(args[0])) ||
        !(needle = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected text and search text");
    }
    found = strstr(haystack, needle);
    if (!found) return atom_empty(a);
    return atom_int(a, (int64_t)(found - haystack));
}

static Atom *str_starts_with(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *text;
    const char *prefix;
    size_t prefix_len;
    if (nargs != 2 || !(text = library_text_arg(args[0])) ||
        !(prefix = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected text and prefix");
    }
    prefix_len = strlen(prefix);
    return strncmp(text, prefix, prefix_len) == 0 ? atom_true(a) : atom_false(a);
}

static Atom *str_ends_with(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *text;
    const char *suffix;
    size_t text_len;
    size_t suffix_len;
    if (nargs != 2 || !(text = library_text_arg(args[0])) ||
        !(suffix = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected text and suffix");
    }
    text_len = strlen(text);
    suffix_len = strlen(suffix);
    if (suffix_len > text_len) return atom_false(a);
    return strcmp(text + text_len - suffix_len, suffix) == 0 ? atom_true(a) : atom_false(a);
}

static Atom *str_trim(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *text;
    size_t len;
    size_t start = 0;
    size_t stop;
    if (nargs != 1 || !(text = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected text argument");
    }
    len = strlen(text);
    while (start < len && isspace((unsigned char)text[start])) start++;
    stop = len;
    while (stop > start && isspace((unsigned char)text[stop - 1])) stop--;
    char *trimmed = cetta_malloc(stop - start + 1);
    memcpy(trimmed, text + start, stop - start);
    trimmed[stop - start] = '\0';
    Atom *result = atom_string(a, trimmed);
    free(trimmed);
    return result;
}

static Atom *cetta_library_dispatch_str(Arena *a, Atom *head,
                                        Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_str_length) {
        return str_length(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_str_concat) {
        return str_concat(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_str_split) {
        return str_split(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_str_split_whitespace) {
        return str_split_whitespace(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_str_join) {
        return str_join(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_str_slice) {
        return str_slice(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_str_find) {
        return str_find(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_str_starts_with) {
        return str_starts_with(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_str_ends_with) {
        return str_ends_with(a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_str_trim) {
        return str_trim(a, head, args, nargs);
    }
    return NULL;
}

typedef struct {
    char **items;
    uint32_t len;
    uint32_t cap;
} ShellTextVec;

typedef struct {
    ShellTextVec *items;
    uint32_t len;
    uint32_t cap;
} ShellCommandVec;

static void shell_text_vec_init(ShellTextVec *vec) {
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void shell_text_vec_free(ShellTextVec *vec) {
    if (!vec) return;
    for (uint32_t i = 0; i < vec->len; i++) {
        free(vec->items[i]);
    }
    free(vec->items);
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void shell_text_vec_push_owned(ShellTextVec *vec, char *text) {
    if (vec->len >= vec->cap) {
        vec->cap = vec->cap ? vec->cap * 2 : 8;
        vec->items = cetta_realloc(vec->items, sizeof(char *) * vec->cap);
    }
    vec->items[vec->len++] = text;
}

static void shell_command_vec_init(ShellCommandVec *vec) {
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void shell_command_vec_free(ShellCommandVec *vec) {
    if (!vec) return;
    for (uint32_t i = 0; i < vec->len; i++) {
        shell_text_vec_free(&vec->items[i]);
    }
    free(vec->items);
    vec->items = NULL;
    vec->len = 0;
    vec->cap = 0;
}

static void shell_command_vec_push_take(ShellCommandVec *vec, ShellTextVec *cmd) {
    if (vec->len >= vec->cap) {
        vec->cap = vec->cap ? vec->cap * 2 : 8;
        vec->items = cetta_realloc(vec->items, sizeof(ShellTextVec) * vec->cap);
    }
    vec->items[vec->len++] = *cmd;
    shell_text_vec_init(cmd);
}

static bool shell_operator_start(char c) {
    return c == '&' || c == '|' || c == ';';
}

static bool shell_disallowed_bare_char(char c) {
    return c == '<' || c == '>' || c == '(' || c == ')' ||
           c == '{' || c == '}' || c == '`' || c == '$' ||
           c == '\\';
}

static const char *shell_skip_space(const char *p) {
    while (*p && isspace((unsigned char)*p)) p++;
    return p;
}

static bool shell_parse_word(const char **p_in, char **word_out) {
    const char *p = shell_skip_space(*p_in);
    CettaStringBuf out;
    bool saw = false;
    cetta_sb_init(&out);

    while (*p && !isspace((unsigned char)*p) && !shell_operator_start(*p)) {
        if (*p == '\'') {
            p++;
            while (*p && *p != '\'') {
                cetta_sb_append_n(&out, p, 1);
                saw = true;
                p++;
            }
            if (*p != '\'') {
                cetta_sb_free(&out);
                return false;
            }
            p++;
            continue;
        }
        if (*p == '"') {
            p++;
            while (*p && *p != '"') {
                if (*p == '$' || *p == '`' || *p == '\\') {
                    cetta_sb_free(&out);
                    return false;
                }
                cetta_sb_append_n(&out, p, 1);
                saw = true;
                p++;
            }
            if (*p != '"') {
                cetta_sb_free(&out);
                return false;
            }
            p++;
            continue;
        }
        if (shell_disallowed_bare_char(*p)) {
            cetta_sb_free(&out);
            return false;
        }
        cetta_sb_append_n(&out, p, 1);
        saw = true;
        p++;
    }

    if (!saw) {
        cetta_sb_free(&out);
        return false;
    }
    *word_out = process_strdup_cstr(out.buf ? out.buf : "");
    *p_in = p;
    cetta_sb_free(&out);
    return true;
}

static bool shell_consume_operator(const char **p_in) {
    const char *p = shell_skip_space(*p_in);
    if (p[0] == '&' && p[1] == '&') {
        *p_in = p + 2;
        return true;
    }
    if (p[0] == '|' && p[1] == '|') {
        *p_in = p + 2;
        return true;
    }
    if (p[0] == '|' || p[0] == ';') {
        *p_in = p + 1;
        return true;
    }
    return false;
}

static bool shell_split_outer_argv(const char *command, ShellTextVec *argv) {
    const char *p = command;
    shell_text_vec_init(argv);
    while (1) {
        char *word = NULL;
        p = shell_skip_space(p);
        if (*p == '\0') return argv->len > 0;
        if (shell_operator_start(*p)) goto fail;
        if (!shell_parse_word(&p, &word)) goto fail;
        shell_text_vec_push_owned(argv, word);
    }

fail:
    shell_text_vec_free(argv);
    return false;
}

static const char *shell_basename(const char *path) {
    const char *slash = strrchr(path, '/');
    return slash ? slash + 1 : path;
}

static bool shell_supported_shell_name(const char *path) {
    const char *name = shell_basename(path);
    return strcmp(name, "bash") == 0 || strcmp(name, "zsh") == 0 ||
           strcmp(name, "sh") == 0;
}

static bool shell_parse_plain_script(const char *script, ShellCommandVec *commands) {
    const char *p = script;
    ShellTextVec current;
    shell_command_vec_init(commands);
    shell_text_vec_init(&current);

    while (1) {
        p = shell_skip_space(p);
        if (*p == '\0') {
            if (current.len == 0) goto fail;
            shell_command_vec_push_take(commands, &current);
            return commands->len > 0;
        }
        if (shell_operator_start(*p)) {
            if (current.len == 0) goto fail;
            if (!shell_consume_operator(&p)) goto fail;
            shell_command_vec_push_take(commands, &current);
            continue;
        }
        {
            char *word = NULL;
            if (!shell_parse_word(&p, &word)) goto fail;
            shell_text_vec_push_owned(&current, word);
        }
    }

fail:
    shell_text_vec_free(&current);
    shell_command_vec_free(commands);
    return false;
}

static Atom *shell_commands_atom(Arena *a, const ShellCommandVec *commands) {
    Atom **items = arena_alloc(a, sizeof(Atom *) * (commands->len ? commands->len : 1));
    for (uint32_t i = 0; i < commands->len; i++) {
        items[i] = library_string_list(a, commands->items[i].items,
                                       commands->items[i].len);
    }
    return atom_expr(a, items, commands->len);
}

static Atom *shell_plain_commands(Arena *a, Atom *head, Atom **args, uint32_t nargs) {
    const char *command;
    ShellTextVec argv;
    ShellCommandVec commands;
    Atom *result;

    if (nargs != 1 || !(command = library_text_arg(args[0]))) {
        return library_signature_error(a, head, args, nargs, "expected shell command text");
    }
    if (!shell_split_outer_argv(command, &argv)) {
        return atom_empty(a);
    }
    if (argv.len != 3 || !shell_supported_shell_name(argv.items[0]) ||
        !(strcmp(argv.items[1], "-lc") == 0 || strcmp(argv.items[1], "-c") == 0)) {
        shell_text_vec_free(&argv);
        return atom_empty(a);
    }
    if (!shell_parse_plain_script(argv.items[2], &commands)) {
        shell_text_vec_free(&argv);
        return atom_empty(a);
    }
    result = shell_commands_atom(a, &commands);
    shell_command_vec_free(&commands);
    shell_text_vec_free(&argv);
    return result;
}

static Atom *cetta_library_dispatch_shell(Arena *a, Atom *head,
                                          Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_shell_plain_commands) {
        return shell_plain_commands(a, head, args, nargs);
    }
    return NULL;
}

static CettaMorkSpaceResource *library_mork_space_resource(CettaLibraryContext *ctx,
                                                           Atom *atom) {
    uint64_t id = 0;
    if (!ctx || !atom ||
        !cetta_native_handle_arg(atom, CETTA_MORK_SPACE_HANDLE_KIND, &id)) {
        return NULL;
    }
    return (CettaMorkSpaceResource *)cetta_native_handle_get(
        ctx, CETTA_MORK_SPACE_HANDLE_KIND, id);
}

static Atom *library_mork_space_handle_atom(CettaLibraryContext *ctx,
                                            Arena *a,
                                            Atom *head,
                                            Atom **args,
                                            uint32_t nargs,
                                            CettaMorkSpaceHandle *bridge_space,
                                            SpaceKind kind,
                                            const char *fallback_error) {
    CettaMorkSpaceResource *resource;
    uint64_t id = 0;

    if (!ctx || !bridge_space) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, fallback_error));
    }
    resource = cetta_malloc(sizeof(CettaMorkSpaceResource));
    resource->bridge_space = bridge_space;
    resource->kind = kind;
    if (!cetta_native_handle_alloc(ctx, CETTA_MORK_SPACE_HANDLE_KIND, resource,
                                   library_mork_space_free_resource, &id)) {
        cetta_mork_bridge_space_free(bridge_space);
        free(resource);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, fallback_error));
    }
    return cetta_native_handle_atom(a, CETTA_MORK_SPACE_HANDLE_KIND, id);
}

static Atom *library_mork_bridge_error(Arena *a, Atom *head, Atom **args,
                                       uint32_t nargs, const char *prefix) {
    char buf[512];
    snprintf(buf, sizeof(buf), "%s%s", prefix, cetta_mork_bridge_last_error());
    return atom_error(a, library_call_expr(a, head, args, nargs), atom_string(a, buf));
}

static CettaMorkSpaceResource *library_explicit_mork_space_arg(CettaLibraryContext *ctx,
                                                               Atom *atom) {
    CettaMorkSpaceResource *resource = library_mork_space_resource(ctx, atom);
    if (!resource || !resource->bridge_space) {
        return NULL;
    }
    return resource;
}

static bool library_mork_space_bridge(CettaMorkSpaceResource *resource,
                                      CettaMorkSpaceHandle **out_bridge) {
    if (out_bridge)
        *out_bridge = NULL;
    if (!resource || !resource->bridge_space)
        return false;
    if (out_bridge)
        *out_bridge = resource->bridge_space;
    return true;
}

static bool library_mork_expr_bytes_need_text_fallback(const char *encode_error) {
    return encode_error &&
           strstr(encode_error, "MORK bridge tokens must be at most 63 bytes") != NULL;
}

static bool library_mork_space_add_atom_text_fallback(Arena *a,
                                                      CettaMorkSpaceHandle *bridge,
                                                      Atom *item) {
    char *text;
    if (!a || !bridge || !item)
        return false;
    text = atom_to_string(a, item);
    if (!text)
        return false;
    return cetta_mork_bridge_space_add_sexpr(
        bridge, (const uint8_t *)text, strlen(text), NULL);
}

static bool library_mork_space_remove_atom_text_fallback(Arena *a,
                                                         CettaMorkSpaceHandle *bridge,
                                                         Atom *item) {
    char *text;
    if (!a || !bridge || !item)
        return false;
    text = atom_to_string(a, item);
    if (!text)
        return false;
    return cetta_mork_bridge_space_remove_sexpr(
        bridge, (const uint8_t *)text, strlen(text), NULL);
}

static bool library_mork_space_add_atoms_text_fallback(Arena *a,
                                                       CettaMorkSpaceHandle *bridge,
                                                       Atom **items,
                                                       uint32_t len) {
    char **texts;
    char *joined;
    size_t total = 0;
    size_t off = 0;

    if (!a || !bridge || (!items && len != 0))
        return false;
    texts = arena_alloc(a, sizeof(char *) * (len ? len : 1u));
    if (!texts)
        return false;
    for (uint32_t i = 0; i < len; i++) {
        texts[i] = atom_to_string(a, items[i]);
        if (!texts[i])
            return false;
        total += strlen(texts[i]) + 1u;
    }
    joined = arena_alloc(a, total ? total : 1u);
    if (!joined)
        return false;
    for (uint32_t i = 0; i < len; i++) {
        size_t n = strlen(texts[i]);
        memcpy(joined + off, texts[i], n);
        off += n;
        joined[off++] = '\n';
    }
    if (total == 0)
        joined[0] = '\0';
    return cetta_mork_bridge_space_add_sexpr(
        bridge, (const uint8_t *)joined, off, NULL);
}

bool cetta_library_lookup_explicit_mork_bridge(CettaLibraryContext *ctx,
                                               Atom *space_arg,
                                               CettaMorkSpaceHandle **bridge_out) {
    return library_mork_space_bridge(library_explicit_mork_space_arg(ctx, space_arg),
                                     bridge_out);
}

static __attribute__((unused)) bool library_mork_materialize_temp_space(CettaLibraryContext *ctx,
                                                                        Arena *a,
                                                                        CettaMorkSpaceResource *resource,
                                                                        SpaceEngine engine,
                                                                        const char *debug_path,
                                                                        Space *out_space,
                                                                        Atom **error_out) {
    uint8_t *packet = NULL;
    size_t packet_len = 0;
    uint32_t packet_rows = 0;
    Arena *persistent_arena;
    bool ok = false;

    if (error_out)
        *error_out = NULL;
    if (!ctx || !resource || !resource->bridge_space || !out_space)
        return false;
    if (!cetta_mork_bridge_space_dump(resource->bridge_space, &packet, &packet_len,
                                      &packet_rows)) {
        return false;
    }

    persistent_arena = eval_current_persistent_arena();
    if (!persistent_arena)
        persistent_arena = a;

    space_init_with_universe(out_space, cetta_library_space_universe(ctx, persistent_arena));
    out_space->kind = resource->kind;
    if (!space_match_backend_try_set(out_space, engine)) {
        if (error_out) {
            *error_out = atom_error(a, atom_symbol(a, "mork:materialize"),
                                    atom_string(a, "MORK temp materialization backend setup failed"));
        }
        goto cleanup;
    }
    if (!load_act_dump_text_into_space(ctx, debug_path, packet, packet_len, out_space,
                                       persistent_arena, a, error_out)) {
        goto cleanup;
    }
    ok = true;

cleanup:
    cetta_mork_bridge_bytes_free(packet, packet_len);
    (void)packet_rows;
    if (!ok)
        space_free(out_space);
    return ok;
}

static bool load_module_act_file(CettaLibraryContext *ctx, const char *path,
                                 Space *work_space,
                                 Arena *eval_arena,
                                 Arena *persistent_arena,
                                 Atom **error_out);

static bool load_module_act_file_pathmap_materialized(CettaLibraryContext *ctx,
                                                      const char *path,
                                                      Space *target_space,
                                                      Arena *eval_arena,
                                                      Arena *persistent_arena,
                                                      Atom **error_out);

static Atom *module_reason_with_detail(CettaLibraryContext *ctx, Arena *a,
                                       const char *tag,
                                       const char *path, Atom *detail);

static bool load_module_mm2_file_into_mork_bridge(CettaLibraryContext *ctx,
                                                  const char *path,
                                                  CettaMorkSpaceHandle *bridge,
                                                  Arena *eval_arena,
                                                  Arena *persistent_arena,
                                                  Atom **error_out);

static __attribute__((unused)) bool library_mork_build_space_bridge_snapshot(
    Space *space,
    CettaMorkSpaceHandle **out_bridge,
    uint64_t *out_unique_count
) {
    Arena scratch;
    arena_init(&scratch);
    arena_set_runtime_kind(&scratch, CETTA_ARENA_RUNTIME_KIND_SCRATCH);

    *out_bridge = NULL;
    if (out_unique_count)
        *out_unique_count = 0;

    if (!space_match_backend_materialize_attached(
            space, eval_current_persistent_arena())) {
        goto fail;
    }

    if (!cetta_mork_bridge_is_available())
        goto fail;

    CettaMorkSpaceHandle *bridge = cetta_mork_bridge_space_new();
    if (!bridge)
        goto fail;

    uint32_t n = space_length(space);
    if (space->native.universe) {
        AtomId *atom_ids = arena_alloc(&scratch, sizeof(AtomId) * (n ? n : 1u));
        uint8_t *packet = NULL;
        size_t packet_len = 0;
        const char *pack_error = NULL;
        for (uint32_t i = 0; i < n; i++)
            atom_ids[i] = space_get_atom_id_at(space, i);
        if (cetta_library_pack_mork_expr_batch_from_ids(
                &scratch, space->native.universe, atom_ids, n,
                &packet, &packet_len, &pack_error) &&
            cetta_mork_bridge_space_add_expr_bytes_batch(
                bridge, packet, packet_len, NULL)) {
            free(packet);
        } else {
            free(packet);
            cetta_mork_bridge_space_free(bridge);
            goto fail;
        }
    } else {
        for (uint32_t i = 0; i < n; i++) {
            ArenaMark mark = arena_mark(&scratch);
            uint8_t *expr_bytes = NULL;
            size_t expr_len = 0;
            const char *encode_error = NULL;
            bool ok = cetta_mm2_atom_to_bridge_expr_bytes(
                &scratch, space_get_at(space, i), &expr_bytes, &expr_len,
                &encode_error) &&
                cetta_mork_bridge_space_add_expr_bytes(
                    bridge, expr_bytes, expr_len, NULL);
            free(expr_bytes);
            arena_reset(&scratch, mark);
            if (!ok) {
                (void)encode_error;
                cetta_mork_bridge_space_free(bridge);
                goto fail;
            }
        }
    }

    if (!cetta_mork_bridge_space_unique_size(bridge, out_unique_count)) {
        cetta_mork_bridge_space_free(bridge);
        goto fail;
    }

    arena_free(&scratch);
    *out_bridge = bridge;
    return true;

fail:
    arena_free(&scratch);
    return false;
}

static Atom *mork_space_new_native(CettaLibraryContext *ctx, Arena *a,
                                   Atom *head, Atom **args, uint32_t nargs) {
    const char *kind_name = NULL;
    SpaceKind kind = SPACE_KIND_ATOM;
    CettaMorkSpaceHandle *bridge_space = NULL;

    if (nargs == 1) {
        kind_name = library_text_arg(args[0]);
    } else if (nargs != 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected optional unordered discipline");
    }
    if (kind_name && !space_kind_from_name(kind_name, &kind)) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "mork:new-space expects atom or hash discipline"));
    }
    if (kind == SPACE_KIND_STACK || kind == SPACE_KIND_QUEUE) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "mork:new-space currently supports only unordered disciplines"));
    }

    bridge_space = cetta_mork_bridge_space_new();
    if (!bridge_space) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK space allocation failed: ");
    }
    return library_mork_space_handle_atom(ctx, a, head, args, nargs,
                                          bridge_space, kind,
                                          "MorkSpace handle allocation failed");
}

static Atom *mork_space_open_act_native(CettaLibraryContext *ctx, Arena *a,
                                        Atom *head, Atom **args, uint32_t nargs) {
    const char *path = NULL;
    const char *kind_name = NULL;
    char resolved[PATH_MAX];
    SpaceKind kind = SPACE_KIND_HASH;
    CettaMorkSpaceHandle *bridge_space = NULL;
    uint64_t loaded = 0;

    if (nargs == 1) {
        path = library_text_arg(args[0]);
    } else if (nargs == 2) {
        kind_name = library_text_arg(args[0]);
        path = library_text_arg(args[1]);
    } else {
        return library_signature_error(a, head, args, nargs,
                                       "expected ACT filename or discipline plus ACT filename");
    }
    if (!path) {
        return library_signature_error(a, head, args, nargs,
                                       "expected ACT filename");
    }
    if (kind_name && !space_kind_from_name(kind_name, &kind)) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "mork-space-open-act expects atom or hash discipline"));
    }
    if (kind == SPACE_KIND_STACK || kind == SPACE_KIND_QUEUE) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "mork-space-open-act currently supports only unordered disciplines"));
    }
    if (!library_resolve_current_path(ctx, path, resolved, sizeof(resolved))) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "MORK ACT open path resolution failed"));
    }
    bridge_space = cetta_mork_bridge_space_new();
    if (!bridge_space) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK ACT open allocation failed: ");
    }
    if (!cetta_mork_bridge_space_load_act_file(
            bridge_space, (const uint8_t *)resolved, strlen(resolved), &loaded)) {
        cetta_mork_bridge_space_free(bridge_space);
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK ACT open failed: ");
    }
    (void)loaded;
    return library_mork_space_handle_atom(ctx, a, head, args, nargs,
                                          bridge_space, kind,
                                          "MORK ACT open handle allocation failed");
}

static Atom *mork_space_dump_act_native(CettaLibraryContext *ctx, Arena *a,
                                        Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkSpaceResource *space;
    const char *path;
    char resolved[PATH_MAX];
    CettaMorkSpaceHandle *bridge = NULL;
    uint64_t saved = 0;

    if (nargs != 2 || !(path = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected space and ACT filename");
    }
    space = library_explicit_mork_space_arg(ctx, args[0]);
    if (!space) {
        return library_signature_error(a, head, args, nargs,
                                       "expected MorkSpace as first argument");
    }
    if (!library_resolve_current_path(ctx, path, resolved, sizeof(resolved))) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "MORK ACT dump path resolution failed"));
    }
    if (!library_mork_space_bridge(space, &bridge) || !bridge) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK ACT dump bridge unavailable: ");
    }

    if (!cetta_mork_bridge_space_dump_act_file(
            bridge, (const uint8_t *)resolved, strlen(resolved), &saved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK ACT dump failed: ");
    }
    (void)saved;
    return atom_unit(a);
}

static Atom *mork_space_import_act_native(CettaLibraryContext *ctx, Arena *a,
                                          Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkSpaceResource *space;
    const char *path;
    char resolved[PATH_MAX];
    CettaMorkSpaceHandle *bridge = NULL;

    if (nargs != 2 || !(path = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected space and ACT filename");
    }
    space = library_explicit_mork_space_arg(ctx, args[0]);
    if (!space) {
        return library_signature_error(a, head, args, nargs,
                                       "expected MorkSpace as first argument");
    }
    if (!library_resolve_current_path(ctx, path, resolved, sizeof(resolved))) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "MORK ACT import path resolution failed"));
    }
    if (!library_mork_space_bridge(space, &bridge) || !bridge) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK ACT import bridge unavailable: ");
    }
    if (!cetta_mork_bridge_space_load_act_file(
            bridge, (const uint8_t *)resolved, strlen(resolved), NULL)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK ACT import failed: ");
    }
    return atom_unit(a);
}

static Atom *mork_space_algebra_native(CettaLibraryContext *ctx, Arena *a,
                                       Atom *head, Atom **args, uint32_t nargs,
                                       SymbolId which) {
    CettaMorkSpaceResource *lhs;
    CettaMorkSpaceResource *rhs;
    CettaMorkSpaceHandle *lhs_bridge = NULL;
    CettaMorkSpaceHandle *rhs_bridge = NULL;
    const char *missing = "expected two MorkSpace handles";
    const char *bridge_prefix = "MORK algebra failed: ";
    bool ok = false;

    (void)ctx;

    if (nargs != 2) {
        return library_signature_error(a, head, args, nargs, missing);
    }
    lhs = library_explicit_mork_space_arg(ctx, args[0]);
    rhs = library_explicit_mork_space_arg(ctx, args[1]);
    if (!lhs || !rhs) {
        return library_signature_error(a, head, args, nargs, missing);
    }
    lhs_bridge = lhs->bridge_space;
    rhs_bridge = rhs->bridge_space;

    if (which == g_builtin_syms.lib_mork_join) {
        bridge_prefix = "MORK join failed: ";
        ok = cetta_mork_bridge_space_join_into(lhs_bridge, rhs_bridge);
    } else if (which == g_builtin_syms.lib_mork_meet) {
        bridge_prefix = "MORK meet failed: ";
        ok = cetta_mork_bridge_space_meet_into(lhs_bridge, rhs_bridge);
    } else if (which == g_builtin_syms.lib_mork_subtract) {
        bridge_prefix = "MORK subtract failed: ";
        ok = cetta_mork_bridge_space_subtract_into(lhs_bridge, rhs_bridge);
    } else {
        bridge_prefix = "MORK restrict failed: ";
        ok = cetta_mork_bridge_space_restrict_into(lhs_bridge, rhs_bridge);
    }
    if (!ok) {
        return library_mork_bridge_error(a, head, args, nargs, bridge_prefix);
    }
    return atom_unit(a);
}

static Atom *mork_space_clone_native(CettaLibraryContext *ctx, Arena *a,
                                     Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkSpaceResource *space;
    CettaMorkSpaceHandle *bridge = NULL;
    CettaMorkSpaceHandle *clone = NULL;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected MorkSpace");
    }
    space = library_explicit_mork_space_arg(ctx, args[0]);
    if (!space) {
        return library_signature_error(a, head, args, nargs,
                                       "expected MorkSpace");
    }
    if (!library_mork_space_bridge(space, &bridge) || !bridge) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK clone bridge unavailable: ");
    }
    clone = cetta_mork_bridge_space_clone(bridge);
    if (!clone) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK clone failed: ");
    }
    return library_mork_space_handle_atom(ctx, a, head, args, nargs, clone,
                                          space->kind,
                                          "MORK clone handle allocation failed");
}

static Atom *mork_space_surface_native(CettaLibraryContext *ctx,
                                       Arena *a, Atom *head, Atom **args,
                                       uint32_t nargs, SymbolId which) {
    CettaMorkSpaceResource *target = NULL;
    CettaMorkSpaceHandle *bridge = NULL;

    if (which == g_builtin_syms.lib_mork_space_match) {
        Atom **results = NULL;
        uint32_t len = 0;
        uint32_t cap = 0;
        uint64_t logical_size = 0;

        if (nargs != 3) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace, pattern, and template");
        }
        target = library_explicit_mork_space_arg(ctx, args[0]);
        if (!target) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace as first argument");
        }

        Atom *pattern = args[1];
        Atom *template = args[2];
        BindingSet matches;
        binding_set_init(&matches);
        if (!library_mork_space_bridge(target, &bridge) || !bridge) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK match bridge unavailable: ");
        }
        if (!cetta_mork_bridge_space_unique_size(bridge, &logical_size) ||
            logical_size > UINT32_MAX) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK match size query failed: ");
        }
        bool direct_ok = false;
        if (pattern->kind == ATOM_EXPR && pattern->expr.len >= 3 &&
            atom_is_symbol_id(pattern->expr.elems[0], g_builtin_syms.comma)) {
            direct_ok = space_match_backend_mork_query_conjunction_direct(
                    bridge, a, pattern->expr.elems + 1,
                    pattern->expr.len - 1, NULL, &matches);
        } else {
            direct_ok = space_match_backend_mork_query_bindings_direct(
                bridge, a, pattern, &matches);
        }

        if (!direct_ok) {
            binding_set_free(&matches);
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK direct match failed: ");
        }
        for (uint32_t i = 0; i < matches.len; i++) {
            if (len >= cap) {
                cap = cap ? cap * 2 : 8;
                results = cetta_realloc(results, sizeof(Atom *) * cap);
            }
            results[len++] = library_quote_atom(
                a, bindings_apply(&matches.items[i], a, template));
        }
        binding_set_free(&matches);

        Atom *result = atom_expr(a, NULL, 0);
        if (len > 0) {
            Atom **elems = arena_alloc(a, sizeof(Atom *) * len);
            memcpy(elems, results, sizeof(Atom *) * len);
            result = atom_expr(a, elems, len);
        }
        free(results);
        return library_quote_atom(a, result);
    }

    if (which == g_builtin_syms.lib_mork_space_step) {
        uint64_t performed = 0;
        uint64_t limit = 1;

        if (nargs != 1 && nargs != 2) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace and optional non-negative step count");
        }
        target = library_explicit_mork_space_arg(ctx, args[0]);
        if (!target) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace as first argument");
        }
        if (nargs == 2) {
            int steps = 0;
            if (!library_int_arg(args[1], &steps) || steps < 0) {
                return library_signature_error(a, head, args, nargs,
                                               "expected MorkSpace and optional non-negative step count");
            }
            limit = (uint64_t)steps;
        }
        if (!library_mork_space_bridge(target, &bridge) || !bridge) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK step bridge unavailable: ");
        }
        if (!cetta_mork_bridge_space_step(bridge, limit, &performed)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK step failed: ");
        }
        return atom_int(a, (int64_t)performed);
    }

    if (nargs != 1 && nargs != 2) {
        return library_signature_error(a, head, args, nargs, "expected MorkSpace");
    }
    target = library_explicit_mork_space_arg(ctx, args[0]);
    if (!target) {
        return library_signature_error(a, head, args, nargs,
                                       nargs == 1
                                           ? "expected MorkSpace"
                                           : "expected MorkSpace as first argument");
    }

    if (which == g_builtin_syms.mork_add_atoms ||
        which == g_builtin_syms.lib_mork_space_add_atoms ||
        which == g_builtin_syms.lib_mork_space_add_stream) {
        Arena scratch;
        Atom *items;
        uint8_t *packet = NULL;
        size_t packet_len = 0;
        uint64_t packet_bytes = 0;
        uint64_t pack_ns = 0;
        uint64_t added = 0;
        const char *pack_error = NULL;
        const bool emit_stats = cetta_runtime_stats_is_enabled();
        const bool emit_timing = cetta_runtime_timing_is_enabled();
        uint64_t native_started_ns = 0;
        uint64_t ffi_started_ns = 0;

        if (nargs != 2) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace and expression of atoms");
        }
        items = args[1];
        if (items->kind != ATOM_EXPR) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace and expression of atoms");
        }
        if (!library_mork_space_bridge(target, &bridge) || !bridge) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK bridge unavailable: ");
        }
        arena_init(&scratch);
        arena_set_runtime_kind(&scratch, CETTA_ARENA_RUNTIME_KIND_SCRATCH);
        if (emit_stats) {
            cetta_runtime_stats_inc(CETTA_RUNTIME_COUNTER_MORK_ADD_BATCH_CALL);
        }
        if (emit_timing) {
            native_started_ns = library_monotonic_ns();
        }
        if (!cetta_library_pack_mork_expr_batch(
                &scratch, items->expr.elems, items->expr.len,
                &packet, &packet_len, &packet_bytes,
                emit_timing ? &pack_ns : NULL, &pack_error)) {
            if (library_mork_space_bridge(target, &bridge) && bridge &&
                library_mork_expr_bytes_need_text_fallback(pack_error) &&
                library_mork_space_add_atoms_text_fallback(
                    &scratch, bridge, items->expr.elems, items->expr.len)) {
                free(packet);
                arena_free(&scratch);
                return atom_unit(a);
            }
            Atom *error = atom_error(
                a, library_call_expr(a, head, args, nargs),
                atom_string(a, pack_error ? pack_error
                                          : "MORK expr-byte lowering failed"));
            free(packet);
            arena_free(&scratch);
            return error;
        }
        if (emit_stats) {
            cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_BATCH_ITEMS,
                                    items->expr.len);
            cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_BATCH_PACKET_BYTES,
                                    packet_bytes);
        }
        if (emit_timing) {
            cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_BATCH_PACK_NS,
                                    pack_ns);
        }
        if (emit_timing) {
            ffi_started_ns = library_monotonic_ns();
        }
        bool ok = cetta_mork_bridge_space_add_expr_bytes_batch(
            bridge, packet, packet_len, &added);
        if (emit_timing) {
            uint64_t ffi_finished_ns = library_monotonic_ns();
            if (ffi_finished_ns >= ffi_started_ns) {
                cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_BATCH_FFI_NS,
                                        ffi_finished_ns - ffi_started_ns);
            }
            if (ffi_finished_ns >= native_started_ns) {
                cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_BATCH_NATIVE_NS,
                                        ffi_finished_ns - native_started_ns);
            }
        }
        free(packet);
        arena_free(&scratch);
        if (!ok) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK bulk add failed: ");
        }
        return atom_unit(a);
    }

    if (which == g_builtin_syms.lib_mork_space_add_atom ||
        which == g_builtin_syms.mork_add_atom) {
        Arena scratch;
        Atom *item;
        uint8_t *expr_bytes = NULL;
        size_t expr_len = 0;
        const char *encode_error = NULL;
        const bool emit_stats = cetta_runtime_stats_is_enabled();
        const bool emit_timing = cetta_runtime_timing_is_enabled();
        uint64_t started_ns = 0;
        uint64_t lowered_ns = 0;

        if (nargs != 2) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace and atom");
        }
        item = (which == g_builtin_syms.mork_add_atom)
                   ? args[1]
                   : library_unquote_atom(args[1]);
        if (emit_stats) {
            cetta_runtime_stats_inc(CETTA_RUNTIME_COUNTER_MORK_ADD_CALL);
        }
        if (emit_timing) {
            started_ns = library_monotonic_ns();
        }
        arena_init(&scratch);
        arena_set_runtime_kind(&scratch, CETTA_ARENA_RUNTIME_KIND_SCRATCH);
        if (!cetta_mm2_atom_to_bridge_expr_bytes(
                &scratch, item, &expr_bytes, &expr_len, &encode_error)) {
            if (library_mork_space_bridge(target, &bridge) && bridge &&
                library_mork_expr_bytes_need_text_fallback(encode_error) &&
                library_mork_space_add_atom_text_fallback(&scratch, bridge, item)) {
                if (emit_timing && started_ns) {
                    lowered_ns = library_monotonic_ns();
                    if (lowered_ns >= started_ns) {
                        cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_LOWER_NS,
                                                lowered_ns - started_ns);
                    }
                }
                arena_free(&scratch);
                return atom_unit(a);
            }
            Atom *error = atom_error(
                a, library_call_expr(a, head, args, nargs),
                atom_string(a, encode_error ? encode_error
                                            : "MORK expr-byte lowering failed"));
            if (emit_timing && started_ns) {
                lowered_ns = library_monotonic_ns();
                if (lowered_ns >= started_ns) {
                    cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_LOWER_NS,
                                            lowered_ns - started_ns);
                }
            }
            arena_free(&scratch);
            return error;
        }
        if (emit_timing) {
            lowered_ns = library_monotonic_ns();
            if (lowered_ns >= started_ns) {
                cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_LOWER_NS,
                                        lowered_ns - started_ns);
            }
        }
        if (emit_stats) {
            cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_EXPR_BYTES,
                                    (uint64_t)expr_len);
        }
        bool ok = library_mork_space_bridge(target, &bridge) &&
                  cetta_mork_bridge_space_add_expr_bytes(
                      bridge, expr_bytes, expr_len, NULL);
        if (emit_timing && lowered_ns) {
            uint64_t finished_ns = library_monotonic_ns();
            if (finished_ns >= lowered_ns) {
                cetta_runtime_stats_add(CETTA_RUNTIME_COUNTER_MORK_ADD_FFI_NS,
                                        finished_ns - lowered_ns);
            }
        }
        free(expr_bytes);
        arena_free(&scratch);
        if (!ok) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK add failed: ");
        }
        return atom_unit(a);
    }

    if (which == g_builtin_syms.lib_mork_space_remove_atom ||
        which == g_builtin_syms.mork_remove_atom) {
        Arena scratch;
        Atom *item;
        uint8_t *expr_bytes = NULL;
        size_t expr_len = 0;
        const char *encode_error = NULL;

        if (nargs != 2) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace and atom");
        }
        item = (which == g_builtin_syms.mork_remove_atom)
                   ? args[1]
                   : library_unquote_atom(args[1]);
        arena_init(&scratch);
        arena_set_runtime_kind(&scratch, CETTA_ARENA_RUNTIME_KIND_SCRATCH);
        if (!cetta_mm2_atom_to_bridge_expr_bytes(
                &scratch, item, &expr_bytes, &expr_len, &encode_error)) {
            if (library_mork_space_bridge(target, &bridge) && bridge &&
                library_mork_expr_bytes_need_text_fallback(encode_error) &&
                library_mork_space_remove_atom_text_fallback(&scratch, bridge, item)) {
                arena_free(&scratch);
                return atom_unit(a);
            }
            Atom *error = atom_error(
                a, library_call_expr(a, head, args, nargs),
                atom_string(a, encode_error ? encode_error
                                            : "MORK expr-byte lowering failed"));
            arena_free(&scratch);
            return error;
        }
        bool ok = library_mork_space_bridge(target, &bridge) &&
                  cetta_mork_bridge_space_remove_expr_bytes(
                      bridge, expr_bytes, expr_len, NULL);
        free(expr_bytes);
        arena_free(&scratch);
        if (!ok) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK remove failed: ");
        }
        return atom_unit(a);
    }

    if (which == g_builtin_syms.lib_mork_space_atoms) {
        uint8_t *packet = NULL;
        size_t len = 0;
        uint32_t rows = 0;

        /* Intentional textual inspection/export surface: callers here asked to
           see the bridge dump as atoms, not to reuse the structural import
           seam that PATHMAP/MORK materialization uses internally. */
        if (nargs != 1) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace");
        }
        if (!library_mork_space_bridge(target, &bridge) || !bridge) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK get-atoms bridge unavailable: ");
        }
        if (!cetta_mork_bridge_space_dump(bridge, &packet, &len, &rows)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK get-atoms failed: ");
        }
        Atom *result = library_atoms_from_text(
            a, packet, len, library_call_expr(a, head, args, nargs));
        cetta_mork_bridge_bytes_free(packet, len);
        (void)rows;
        return library_quote_atom(a, result);
    }

    if (which == g_builtin_syms.lib_mork_space_size ||
        which == g_builtin_syms.lib_mork_space_count_atoms) {
        uint64_t size = 0;

        if (nargs != 1) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace");
        }
        if (!library_mork_space_bridge(target, &bridge) || !bridge) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK size bridge unavailable: ");
        }
        if (!cetta_mork_bridge_space_unique_size(bridge, &size)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK size failed: ");
        }
        return atom_int(a, (int64_t)size);
    }

    return atom_error(a, library_call_expr(a, head, args, nargs),
                      atom_string(a, "unknown mork surface helper"));
}

static Atom *mork_space_include_native(CettaLibraryContext *ctx, Arena *a,
                                       Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkSpaceResource *space;
    const char *spec;
    Atom *error = NULL;
    Arena *persistent = NULL;
    CettaMorkSpaceHandle *bridge = NULL;
    CettaModuleSpec parsed_spec;
    CettaImportPlan plan;
    bool ok = false;

    if (nargs != 2 || !(spec = library_text_arg(args[1]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected MorkSpace and module spec");
    }
    space = library_explicit_mork_space_arg(ctx, args[0]);
    if (!space) {
        return library_signature_error(a, head, args, nargs,
                                       "expected MorkSpace as first argument");
    }

    persistent = eval_current_persistent_arena();
    if (!persistent)
        persistent = a;

    if (cetta_library_lookup(spec) || cetta_native_module_lookup(spec)) {
        error = atom_string(a,
                            "mork:include! supports direct MM2 or compiled ACT modules, not builtin libraries");
        goto cleanup;
    }
    if (!parse_module_spec(spec, &parsed_spec, a, &error)) {
        goto cleanup;
    }
    if (!resolve_import_plan(ctx, &parsed_spec, NULL, NULL, false,
                             &plan, a, &error)) {
        goto cleanup;
    }
    if (!library_mork_space_bridge(space, &bridge) || !bridge) {
        error = atom_string(a, "MORK bridge unavailable");
        goto cleanup;
    }

    if (plan.format.kind == CETTA_MODULE_FORMAT_MORK_ACT) {
        if (!cetta_mork_bridge_space_load_act_file(
                bridge,
                (const uint8_t *)plan.canonical_path,
                strlen(plan.canonical_path),
                NULL)) {
            error = module_reason_with_detail(
                ctx, a, "ModuleCompiledLoadFailed", plan.canonical_path,
                atom_string(a, cetta_mork_bridge_last_error()));
            goto cleanup;
        }
        ok = true;
        goto cleanup;
    }

    if (plan.format.kind == CETTA_MODULE_FORMAT_MM2) {
        ok = load_module_mm2_file_into_mork_bridge(ctx, plan.canonical_path,
                                                   bridge, a, persistent, &error);
        goto cleanup;
    }

    error = module_reason_with_detail(
        ctx, a, "MorkIncludeUnsupportedFormat", plan.canonical_path,
        atom_string(a,
                    "mork:include! currently supports only direct .mm2 or .act modules"));

cleanup:
    if (!ok) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          error ? error : atom_symbol(a, "mork:include! failed"));
    }
    return atom_unit(a);
}

static Atom *mork_zipper_new_native(CettaLibraryContext *ctx, Arena *a,
                                    Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkSpaceResource *space;
    CettaMorkSpaceHandle *bridge = NULL;
    CettaMorkCursorHandle *cursor = NULL;
    CettaMorkCursorResource *resource = NULL;
    uint64_t id = 0;

    /* The zipper family is an explicit bridge-native inspection seam. It is
       intentionally cursor/path oriented rather than another AtomId transport
       path, so future optimizations should not try to fold it into PATHMAP
       materialization. */
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected MorkSpace");
    }
    space = library_explicit_mork_space_arg(ctx, args[0]);
    if (!space) {
        return library_signature_error(a, head, args, nargs,
                                       "expected MorkSpace as first argument");
    }
    if (!library_mork_space_bridge(space, &bridge) || !bridge) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK zipper bridge unavailable: ");
    }
    cursor = cetta_mork_bridge_cursor_new(bridge);
    if (!cursor) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK zipper allocation failed: ");
    }

    resource = cetta_malloc(sizeof(CettaMorkCursorResource));
    resource->cursor = cursor;
    resource->kind = space->kind;
    if (!cetta_native_handle_alloc(ctx, CETTA_MORK_CURSOR_HANDLE_KIND, resource,
                                   library_mork_cursor_free_resource, &id)) {
        library_mork_cursor_free_resource(resource);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "MORK zipper handle allocation failed"));
    }
    return cetta_native_handle_atom(a, CETTA_MORK_CURSOR_HANDLE_KIND, id);
}

static Atom *mork_zipper_close_native(CettaLibraryContext *ctx, Arena *a,
                                      Atom *head, Atom **args, uint32_t nargs) {
    uint64_t id = 0;
    if (nargs != 1 || !cetta_native_handle_arg(args[0], CETTA_MORK_CURSOR_HANDLE_KIND, &id)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    if (!cetta_native_handle_close(ctx, CETTA_MORK_CURSOR_HANDLE_KIND, id)) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "unknown or closed mork-cursor handle"));
    }
    return atom_unit(a);
}

static Atom *mork_zipper_bool_native(CettaLibraryContext *ctx, Arena *a,
                                     Atom *head, Atom **args, uint32_t nargs,
                                     SymbolId which) {
    CettaMorkCursorResource *resource;
    bool value = false;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }

    if (which == g_builtin_syms.lib_mork_zipper_path_exists) {
        if (!cetta_mork_bridge_cursor_path_exists(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper path-exists failed: ");
        }
    } else {
        if (!cetta_mork_bridge_cursor_is_val(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper is-val failed: ");
        }
    }
    return atom_bool(a, value);
}

static Atom *mork_zipper_bytes_native(CettaLibraryContext *ctx, Arena *a,
                                      Atom *head, Atom **args, uint32_t nargs,
                                      SymbolId which) {
    CettaMorkCursorResource *resource;
    uint8_t *bytes = NULL;
    size_t len = 0;
    Atom *result;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }

    if (which == g_builtin_syms.lib_mork_zipper_path_bytes) {
        if (!cetta_mork_bridge_cursor_path_bytes(resource->cursor, &bytes, &len)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper path-bytes failed: ");
        }
    } else {
        if (!cetta_mork_bridge_cursor_child_bytes(resource->cursor, &bytes, &len)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper child-bytes failed: ");
        }
    }
    result = library_byte_list_atom(a, bytes, len);
    cetta_mork_bridge_bytes_free(bytes, len);
    return result;
}

static Atom *mork_zipper_count_native(CettaLibraryContext *ctx, Arena *a,
                                      Atom *head, Atom **args, uint32_t nargs,
                                      SymbolId which) {
    CettaMorkCursorResource *resource;
    uint64_t value = 0;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }

    if (which == g_builtin_syms.lib_mork_zipper_child_count) {
        if (!cetta_mork_bridge_cursor_child_count(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper child-count failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_zipper_val_count) {
        if (!cetta_mork_bridge_cursor_val_count(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper val-count failed: ");
        }
    } else {
        if (!cetta_mork_bridge_cursor_depth(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper depth failed: ");
        }
    }
    return atom_int(a, (int64_t)value);
}

static Atom *mork_zipper_reset_native(CettaLibraryContext *ctx, Arena *a,
                                      Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkCursorResource *resource;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    if (!cetta_mork_bridge_cursor_reset(resource->cursor)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK zipper reset failed: ");
    }
    return atom_unit(a);
}

static Atom *mork_zipper_ascend_native(CettaLibraryContext *ctx, Arena *a,
                                       Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkCursorResource *resource;
    bool moved = false;
    int steps = 0;

    if (nargs != 2 || !library_int_arg(args[1], &steps) || steps < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle and non-negative step count");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_cursor_ascend(resource->cursor, (uint64_t)steps, &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK zipper ascend failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_zipper_descend_byte_native(CettaLibraryContext *ctx, Arena *a,
                                             Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkCursorResource *resource;
    bool moved = false;
    int byte = 0;

    if (nargs != 2 || !library_int_arg(args[1], &byte) || byte < 0 || byte > 255) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle and byte in 0..255");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_cursor_descend_byte(resource->cursor, (uint32_t)byte, &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK zipper descend-byte failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_zipper_descend_index_native(CettaLibraryContext *ctx, Arena *a,
                                              Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkCursorResource *resource;
    bool moved = false;
    int index = 0;

    if (nargs != 2 || !library_int_arg(args[1], &index) || index < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle and non-negative child index");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_cursor_descend_index(resource->cursor, (uint64_t)index, &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK zipper descend-index failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_zipper_descend_simple_native(CettaLibraryContext *ctx, Arena *a,
                                               Atom *head, Atom **args, uint32_t nargs,
                                               SymbolId which) {
    CettaMorkCursorResource *resource;
    bool moved = false;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }

    if (which == g_builtin_syms.lib_mork_zipper_descend_first) {
        if (!cetta_mork_bridge_cursor_descend_first(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper descend-first failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_zipper_descend_last) {
        if (!cetta_mork_bridge_cursor_descend_last(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper descend-last failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_zipper_descend_until) {
        if (!cetta_mork_bridge_cursor_descend_until(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper descend-until failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_zipper_ascend_until) {
        if (!cetta_mork_bridge_cursor_ascend_until(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper ascend-until failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_zipper_ascend_until_branch) {
        if (!cetta_mork_bridge_cursor_ascend_until_branch(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper ascend-until-branch failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_zipper_next_sibling_byte) {
        if (!cetta_mork_bridge_cursor_next_sibling_byte(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper next-sibling-byte failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_zipper_prev_sibling_byte) {
        if (!cetta_mork_bridge_cursor_prev_sibling_byte(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper prev-sibling-byte failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_zipper_next_step) {
        if (!cetta_mork_bridge_cursor_next_step(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper next-step failed: ");
        }
    } else {
        if (!cetta_mork_bridge_cursor_next_val(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK zipper next-val failed: ");
        }
    }
    return atom_bool(a, moved);
}

static Atom *mork_zipper_descend_until_max_bytes_native(CettaLibraryContext *ctx, Arena *a,
                                                        Atom *head, Atom **args,
                                                        uint32_t nargs) {
    CettaMorkCursorResource *resource;
    bool moved = false;
    int max_bytes = 0;

    if (nargs != 2 || !library_int_arg(args[1], &max_bytes) || max_bytes < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle and non-negative max byte count");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_cursor_descend_until_max_bytes(resource->cursor,
                                                          (uint64_t)max_bytes,
                                                          &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK zipper descend-until-max-bytes failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_zipper_fork_native(CettaLibraryContext *ctx, Arena *a,
                                     Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkCursorResource *resource;
    CettaMorkCursorHandle *forked = NULL;
    CettaMorkCursorResource *forked_resource = NULL;
    uint64_t id = 0;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    forked = cetta_mork_bridge_cursor_fork(resource->cursor);
    if (!forked) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK zipper fork failed: ");
    }
    forked_resource = cetta_malloc(sizeof(CettaMorkCursorResource));
    forked_resource->cursor = forked;
    forked_resource->kind = resource->kind;
    if (!cetta_native_handle_alloc(ctx, CETTA_MORK_CURSOR_HANDLE_KIND, forked_resource,
                                   library_mork_cursor_free_resource, &id)) {
        library_mork_cursor_free_resource(forked_resource);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "MORK zipper fork handle allocation failed"));
    }
    return cetta_native_handle_atom(a, CETTA_MORK_CURSOR_HANDLE_KIND, id);
}

static Atom *mork_zipper_materialize_native(CettaLibraryContext *ctx, Arena *a,
                                            Atom *head, Atom **args, uint32_t nargs,
                                            SymbolId which) {
    CettaMorkCursorResource *resource;
    CettaMorkSpaceHandle *bridge_space = NULL;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    resource = library_mork_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-cursor handle");
    }
    if (which == g_builtin_syms.lib_mork_zipper_make_map) {
        bridge_space = cetta_mork_bridge_cursor_make_map(resource->cursor);
    } else {
        bridge_space = cetta_mork_bridge_cursor_make_snapshot_map(resource->cursor);
    }
    if (!bridge_space) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK zipper materialization failed: ");
    }
    return library_mork_space_handle_atom(ctx, a, head, args, nargs,
                                          bridge_space, resource->kind,
                                          "MORK zipper materialization failed");
}

static Atom *mork_product_zipper_new_native(CettaLibraryContext *ctx, Arena *a,
                                            Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkSpaceHandle **bridge_spaces = NULL;
    CettaMorkProductCursorHandle *cursor = NULL;
    CettaMorkProductCursorResource *resource = NULL;
    uint64_t id = 0;

    if (nargs < 2) {
        return library_signature_error(a, head, args, nargs,
                                       "expected at least two MorkSpace handles");
    }

    bridge_spaces = arena_alloc(a, sizeof(CettaMorkSpaceHandle *) * nargs);
    for (uint32_t i = 0; i < nargs; i++) {
        CettaMorkSpaceResource *space = library_explicit_mork_space_arg(ctx, args[i]);
        if (!space) {
            return library_signature_error(a, head, args, nargs,
                                           "expected MorkSpace arguments");
        }
        if (!library_mork_space_bridge(space, &bridge_spaces[i]) ||
            !bridge_spaces[i]) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper bridge unavailable: ");
        }
    }

    cursor = cetta_mork_bridge_product_cursor_new(
        (const CettaMorkSpaceHandle *const *)bridge_spaces, nargs);
    if (!cursor) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK product-zipper allocation failed: ");
    }

    resource = cetta_malloc(sizeof(CettaMorkProductCursorResource));
    resource->cursor = cursor;
    if (!cetta_native_handle_alloc(ctx, CETTA_MORK_PRODUCT_CURSOR_HANDLE_KIND,
                                   resource, library_mork_product_cursor_free_resource,
                                   &id)) {
        library_mork_product_cursor_free_resource(resource);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a,
                                      "MORK product-zipper handle allocation failed"));
    }
    return cetta_native_handle_atom(a, CETTA_MORK_PRODUCT_CURSOR_HANDLE_KIND, id);
}

static Atom *mork_product_zipper_close_native(CettaLibraryContext *ctx, Arena *a,
                                              Atom *head, Atom **args, uint32_t nargs) {
    uint64_t id = 0;
    if (nargs != 1 ||
        !cetta_native_handle_arg(args[0], CETTA_MORK_PRODUCT_CURSOR_HANDLE_KIND, &id)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }
    if (!cetta_native_handle_close(ctx, CETTA_MORK_PRODUCT_CURSOR_HANDLE_KIND, id)) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a,
                                      "unknown or closed mork-product-cursor handle"));
    }
    return atom_unit(a);
}

static Atom *mork_product_zipper_bool_native(CettaLibraryContext *ctx, Arena *a,
                                             Atom *head, Atom **args, uint32_t nargs,
                                             SymbolId which) {
    CettaMorkProductCursorResource *resource;
    bool value = false;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }
    resource = library_mork_product_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }
    if (which == g_builtin_syms.lib_mork_product_zipper_path_exists) {
        if (!cetta_mork_bridge_product_cursor_path_exists(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper path-exists failed: ");
        }
    } else {
        if (!cetta_mork_bridge_product_cursor_is_val(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper is-val failed: ");
        }
    }
    return atom_bool(a, value);
}

static Atom *mork_product_zipper_bytes_native(CettaLibraryContext *ctx, Arena *a,
                                              Atom *head, Atom **args, uint32_t nargs,
                                              SymbolId which) {
    CettaMorkProductCursorResource *resource;
    uint8_t *bytes = NULL;
    size_t len = 0;
    uint32_t count = 0;
    Atom *result;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }
    resource = library_mork_product_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }

    if (which == g_builtin_syms.lib_mork_product_zipper_path_bytes) {
        if (!cetta_mork_bridge_product_cursor_path_bytes(resource->cursor, &bytes, &len)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper path-bytes failed: ");
        }
        result = library_byte_list_atom(a, bytes, len);
    } else if (which == g_builtin_syms.lib_mork_product_zipper_child_bytes) {
        if (!cetta_mork_bridge_product_cursor_child_bytes(resource->cursor, &bytes, &len)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper child-bytes failed: ");
        }
        result = library_byte_list_atom(a, bytes, len);
    } else {
        if (!cetta_mork_bridge_product_cursor_path_indices(resource->cursor, &bytes, &len,
                                                           &count)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper path-indices failed: ");
        }
        (void)count;
        result = library_u64_be_list_atom(a, bytes, len);
    }
    cetta_mork_bridge_bytes_free(bytes, len);
    return result;
}

static Atom *mork_product_zipper_count_native(CettaLibraryContext *ctx, Arena *a,
                                              Atom *head, Atom **args, uint32_t nargs,
                                              SymbolId which) {
    CettaMorkProductCursorResource *resource;
    uint64_t value = 0;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }
    resource = library_mork_product_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }

    if (which == g_builtin_syms.lib_mork_product_zipper_child_count) {
        if (!cetta_mork_bridge_product_cursor_child_count(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper child-count failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_val_count) {
        if (!cetta_mork_bridge_product_cursor_val_count(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper val-count failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_depth) {
        if (!cetta_mork_bridge_product_cursor_depth(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper depth failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_factor_count) {
        if (!cetta_mork_bridge_product_cursor_factor_count(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper factor-count failed: ");
        }
    } else {
        if (!cetta_mork_bridge_product_cursor_focus_factor(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper focus-factor failed: ");
        }
    }
    return atom_int(a, (int64_t)value);
}

static Atom *mork_product_zipper_reset_native(CettaLibraryContext *ctx, Arena *a,
                                              Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkProductCursorResource *resource;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }
    resource = library_mork_product_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }
    if (!cetta_mork_bridge_product_cursor_reset(resource->cursor)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK product-zipper reset failed: ");
    }
    return atom_unit(a);
}

static Atom *mork_product_zipper_ascend_native(CettaLibraryContext *ctx, Arena *a,
                                               Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkProductCursorResource *resource;
    bool moved = false;
    int steps = 0;

    if (nargs != 2 || !library_int_arg(args[1], &steps) || steps < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle and non-negative step count");
    }
    resource = library_mork_product_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_product_cursor_ascend(resource->cursor, (uint64_t)steps, &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK product-zipper ascend failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_product_zipper_descend_byte_native(CettaLibraryContext *ctx, Arena *a,
                                                     Atom *head, Atom **args,
                                                     uint32_t nargs) {
    CettaMorkProductCursorResource *resource;
    bool moved = false;
    int byte = 0;

    if (nargs != 2 || !library_int_arg(args[1], &byte) || byte < 0 || byte > 255) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle and byte in 0..255");
    }
    resource = library_mork_product_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_product_cursor_descend_byte(resource->cursor, (uint32_t)byte,
                                                       &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK product-zipper descend-byte failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_product_zipper_descend_index_native(CettaLibraryContext *ctx, Arena *a,
                                                      Atom *head, Atom **args,
                                                      uint32_t nargs) {
    CettaMorkProductCursorResource *resource;
    bool moved = false;
    int index = 0;

    if (nargs != 2 || !library_int_arg(args[1], &index) || index < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle and non-negative child index");
    }
    resource = library_mork_product_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_product_cursor_descend_index(resource->cursor, (uint64_t)index,
                                                        &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK product-zipper descend-index failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_product_zipper_descend_simple_native(CettaLibraryContext *ctx, Arena *a,
                                                       Atom *head, Atom **args,
                                                       uint32_t nargs,
                                                       SymbolId which) {
    CettaMorkProductCursorResource *resource;
    bool moved = false;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }
    resource = library_mork_product_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle");
    }
    if (which == g_builtin_syms.lib_mork_product_zipper_descend_first) {
        if (!cetta_mork_bridge_product_cursor_descend_first(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper descend-first failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_descend_last) {
        if (!cetta_mork_bridge_product_cursor_descend_last(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper descend-last failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_descend_until) {
        if (!cetta_mork_bridge_product_cursor_descend_until(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper descend-until failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_ascend_until) {
        if (!cetta_mork_bridge_product_cursor_ascend_until(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper ascend-until failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_ascend_until_branch) {
        if (!cetta_mork_bridge_product_cursor_ascend_until_branch(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper ascend-until-branch failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_next_sibling_byte) {
        if (!cetta_mork_bridge_product_cursor_next_sibling_byte(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper next-sibling-byte failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_prev_sibling_byte) {
        if (!cetta_mork_bridge_product_cursor_prev_sibling_byte(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper prev-sibling-byte failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_product_zipper_next_step) {
        if (!cetta_mork_bridge_product_cursor_next_step(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper next-step failed: ");
        }
    } else {
        if (!cetta_mork_bridge_product_cursor_next_val(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK product-zipper next-val failed: ");
        }
    }
    return atom_bool(a, moved);
}

static Atom *mork_product_zipper_descend_until_max_bytes_native(
    CettaLibraryContext *ctx,
    Arena *a,
    Atom *head,
    Atom **args,
    uint32_t nargs) {
    CettaMorkProductCursorResource *resource;
    bool moved = false;
    int max_bytes = 0;

    if (nargs != 2 || !library_int_arg(args[1], &max_bytes) || max_bytes < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle and non-negative max byte count");
    }
    resource = library_mork_product_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-product-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_product_cursor_descend_until_max_bytes(resource->cursor,
                                                                  (uint64_t)max_bytes,
                                                                  &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK product-zipper descend-until-max-bytes failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_overlay_zipper_new_native(CettaLibraryContext *ctx, Arena *a,
                                            Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkSpaceResource *base_space = NULL;
    CettaMorkSpaceResource *overlay_space = NULL;
    CettaMorkSpaceHandle *base_bridge = NULL;
    CettaMorkSpaceHandle *overlay_bridge = NULL;
    CettaMorkOverlayCursorHandle *cursor = NULL;
    CettaMorkOverlayCursorResource *resource = NULL;
    uint64_t id = 0;

    if (nargs != 2) {
        return library_signature_error(a, head, args, nargs,
                                       "expected two MorkSpace handles");
    }

    base_space = library_explicit_mork_space_arg(ctx, args[0]);
    overlay_space = library_explicit_mork_space_arg(ctx, args[1]);
    if (!base_space || !overlay_space) {
        return library_signature_error(a, head, args, nargs,
                                       "expected MorkSpace arguments");
    }
    if (!library_mork_space_bridge(base_space, &base_bridge) ||
        !base_bridge ||
        !library_mork_space_bridge(overlay_space, &overlay_bridge) ||
        !overlay_bridge) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK overlay-zipper bridge unavailable: ");
    }

    cursor = cetta_mork_bridge_overlay_cursor_new(base_bridge, overlay_bridge);
    if (!cursor) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK overlay-zipper allocation failed: ");
    }

    resource = cetta_malloc(sizeof(CettaMorkOverlayCursorResource));
    resource->cursor = cursor;
    if (!cetta_native_handle_alloc(ctx, CETTA_MORK_OVERLAY_CURSOR_HANDLE_KIND,
                                   resource, library_mork_overlay_cursor_free_resource,
                                   &id)) {
        library_mork_overlay_cursor_free_resource(resource);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a,
                                      "MORK overlay-zipper handle allocation failed"));
    }
    return cetta_native_handle_atom(a, CETTA_MORK_OVERLAY_CURSOR_HANDLE_KIND, id);
}

static Atom *mork_overlay_zipper_close_native(CettaLibraryContext *ctx, Arena *a,
                                              Atom *head, Atom **args, uint32_t nargs) {
    uint64_t id = 0;
    if (nargs != 1 ||
        !cetta_native_handle_arg(args[0], CETTA_MORK_OVERLAY_CURSOR_HANDLE_KIND, &id)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }
    if (!cetta_native_handle_close(ctx, CETTA_MORK_OVERLAY_CURSOR_HANDLE_KIND, id)) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a,
                                      "unknown or closed mork-overlay-cursor handle"));
    }
    return atom_unit(a);
}

static Atom *mork_overlay_zipper_bool_native(CettaLibraryContext *ctx, Arena *a,
                                             Atom *head, Atom **args, uint32_t nargs,
                                             SymbolId which) {
    CettaMorkOverlayCursorResource *resource;
    bool value = false;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }
    resource = library_mork_overlay_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }
    if (which == g_builtin_syms.lib_mork_overlay_zipper_path_exists) {
        if (!cetta_mork_bridge_overlay_cursor_path_exists(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper path-exists failed: ");
        }
    } else {
        if (!cetta_mork_bridge_overlay_cursor_is_val(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper is-val failed: ");
        }
    }
    return atom_bool(a, value);
}

static Atom *mork_overlay_zipper_bytes_native(CettaLibraryContext *ctx, Arena *a,
                                              Atom *head, Atom **args, uint32_t nargs,
                                              SymbolId which) {
    CettaMorkOverlayCursorResource *resource;
    uint8_t *bytes = NULL;
    size_t len = 0;
    Atom *result;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }
    resource = library_mork_overlay_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }

    if (which == g_builtin_syms.lib_mork_overlay_zipper_path_bytes) {
        if (!cetta_mork_bridge_overlay_cursor_path_bytes(resource->cursor, &bytes, &len)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper path-bytes failed: ");
        }
    } else {
        if (!cetta_mork_bridge_overlay_cursor_child_bytes(resource->cursor, &bytes, &len)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper child-bytes failed: ");
        }
    }
    result = library_byte_list_atom(a, bytes, len);
    cetta_mork_bridge_bytes_free(bytes, len);
    return result;
}

static Atom *mork_overlay_zipper_count_native(CettaLibraryContext *ctx, Arena *a,
                                              Atom *head, Atom **args, uint32_t nargs,
                                              SymbolId which) {
    CettaMorkOverlayCursorResource *resource;
    uint64_t value = 0;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }
    resource = library_mork_overlay_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }

    if (which == g_builtin_syms.lib_mork_overlay_zipper_child_count) {
        if (!cetta_mork_bridge_overlay_cursor_child_count(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper child-count failed: ");
        }
    } else {
        if (!cetta_mork_bridge_overlay_cursor_depth(resource->cursor, &value)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper depth failed: ");
        }
    }
    return atom_int(a, (int64_t)value);
}

static Atom *mork_overlay_zipper_reset_native(CettaLibraryContext *ctx, Arena *a,
                                              Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkOverlayCursorResource *resource;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }
    resource = library_mork_overlay_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }
    if (!cetta_mork_bridge_overlay_cursor_reset(resource->cursor)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK overlay-zipper reset failed: ");
    }
    return atom_unit(a);
}

static Atom *mork_overlay_zipper_ascend_native(CettaLibraryContext *ctx, Arena *a,
                                               Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkOverlayCursorResource *resource;
    bool moved = false;
    int steps = 0;

    if (nargs != 2 || !library_int_arg(args[1], &steps) || steps < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle and non-negative step count");
    }
    resource = library_mork_overlay_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_overlay_cursor_ascend(resource->cursor, (uint64_t)steps, &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK overlay-zipper ascend failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_overlay_zipper_descend_byte_native(CettaLibraryContext *ctx, Arena *a,
                                                     Atom *head, Atom **args,
                                                     uint32_t nargs) {
    CettaMorkOverlayCursorResource *resource;
    bool moved = false;
    int byte = 0;

    if (nargs != 2 || !library_int_arg(args[1], &byte) || byte < 0 || byte > 255) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle and byte in 0..255");
    }
    resource = library_mork_overlay_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_overlay_cursor_descend_byte(resource->cursor, (uint32_t)byte,
                                                       &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK overlay-zipper descend-byte failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_overlay_zipper_descend_index_native(CettaLibraryContext *ctx, Arena *a,
                                                      Atom *head, Atom **args,
                                                      uint32_t nargs) {
    CettaMorkOverlayCursorResource *resource;
    bool moved = false;
    int index = 0;

    if (nargs != 2 || !library_int_arg(args[1], &index) || index < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle and non-negative child index");
    }
    resource = library_mork_overlay_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_overlay_cursor_descend_index(resource->cursor, (uint64_t)index,
                                                        &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK overlay-zipper descend-index failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_overlay_zipper_descend_simple_native(CettaLibraryContext *ctx, Arena *a,
                                                       Atom *head, Atom **args,
                                                       uint32_t nargs,
                                                       SymbolId which) {
    CettaMorkOverlayCursorResource *resource;
    bool moved = false;

    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }
    resource = library_mork_overlay_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle");
    }
    if (which == g_builtin_syms.lib_mork_overlay_zipper_descend_first) {
        if (!cetta_mork_bridge_overlay_cursor_descend_first(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper descend-first failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_overlay_zipper_descend_last) {
        if (!cetta_mork_bridge_overlay_cursor_descend_last(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper descend-last failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_overlay_zipper_descend_until) {
        if (!cetta_mork_bridge_overlay_cursor_descend_until(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper descend-until failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_overlay_zipper_ascend_until) {
        if (!cetta_mork_bridge_overlay_cursor_ascend_until(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper ascend-until failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_overlay_zipper_ascend_until_branch) {
        if (!cetta_mork_bridge_overlay_cursor_ascend_until_branch(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper ascend-until-branch failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_overlay_zipper_next_sibling_byte) {
        if (!cetta_mork_bridge_overlay_cursor_next_sibling_byte(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper next-sibling-byte failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_overlay_zipper_prev_sibling_byte) {
        if (!cetta_mork_bridge_overlay_cursor_prev_sibling_byte(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper prev-sibling-byte failed: ");
        }
    } else if (which == g_builtin_syms.lib_mork_overlay_zipper_next_step) {
        if (!cetta_mork_bridge_overlay_cursor_next_step(resource->cursor, &moved)) {
            return library_mork_bridge_error(a, head, args, nargs,
                                             "MORK overlay-zipper next-step failed: ");
        }
    } else {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "unsupported overlay zipper movement"));
    }
    return atom_bool(a, moved);
}

static Atom *mork_overlay_zipper_descend_until_max_bytes_native(
    CettaLibraryContext *ctx,
    Arena *a,
    Atom *head,
    Atom **args,
    uint32_t nargs) {
    CettaMorkOverlayCursorResource *resource;
    bool moved = false;
    int max_bytes = 0;

    if (nargs != 2 || !library_int_arg(args[1], &max_bytes) || max_bytes < 0) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle and non-negative max byte count");
    }
    resource = library_mork_overlay_cursor_handle(ctx, args[0]);
    if (!resource || !resource->cursor) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-overlay-cursor handle as first argument");
    }
    if (!cetta_mork_bridge_overlay_cursor_descend_until_max_bytes(resource->cursor,
                                                                  (uint64_t)max_bytes,
                                                                  &moved)) {
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK overlay-zipper descend-until-max-bytes failed: ");
    }
    return atom_bool(a, moved);
}

static Atom *mork_path_of_atom_native(CettaLibraryContext *ctx, Arena *a,
                                      Atom *head, Atom **args, uint32_t nargs) {
    Arena scratch;
    char *text = NULL;
    CettaMorkSpaceHandle *bridge_space = NULL;
    CettaMorkCursorHandle *cursor = NULL;
    uint8_t *bytes = NULL;
    size_t len = 0;
    Atom *result = NULL;
    bool moved = false;

    /* Explicit bridge-byte inspection helper: this answers "what bridge path
       does this atom lower to?" and is intentionally separate from the
       structural bridge->AtomId import seam. */
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs, "expected atom");
    }

    arena_init(&scratch);
    arena_set_runtime_kind(&scratch, CETTA_ARENA_RUNTIME_KIND_SCRATCH);
    text = atom_to_parseable_string(&scratch, args[0]);
    if (!text) {
        arena_free(&scratch);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "mork:path-of-atom could not render atom"));
    }
    bridge_space = cetta_mork_bridge_space_new();
    if (!bridge_space) {
        arena_free(&scratch);
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK path-of-atom bridge allocation failed: ");
    }
    /* This helper should expose the bridge/storage path the live MORK parser
       would use, not the narrower compact expr-byte lowering shortcut. */
    if (!cetta_mork_bridge_space_add_sexpr(
            bridge_space, (const uint8_t *)text, strlen(text), NULL)) {
        cetta_mork_bridge_space_free(bridge_space);
        arena_free(&scratch);
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK path-of-atom encoding failed: ");
    }
    cursor = cetta_mork_bridge_cursor_new(bridge_space);
    if (!cursor) {
        cetta_mork_bridge_space_free(bridge_space);
        arena_free(&scratch);
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK path-of-atom cursor allocation failed: ");
    }
    if (!cetta_mork_bridge_cursor_descend_until(cursor, &moved)) {
        cetta_mork_bridge_cursor_free(cursor);
        cetta_mork_bridge_space_free(bridge_space);
        arena_free(&scratch);
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK path-of-atom traversal failed: ");
    }
    if (!cetta_mork_bridge_cursor_path_bytes(cursor, &bytes, &len)) {
        cetta_mork_bridge_cursor_free(cursor);
        cetta_mork_bridge_space_free(bridge_space);
        arena_free(&scratch);
        return library_mork_bridge_error(a, head, args, nargs,
                                         "MORK path-of-atom extraction failed: ");
    }

    result = library_byte_list_atom(a, bytes, len);
    cetta_mork_bridge_bytes_free(bytes, len);
    cetta_mork_bridge_cursor_free(cursor);
    cetta_mork_bridge_space_free(bridge_space);
    arena_free(&scratch);
    return result;
}

static Atom *cetta_library_dispatch_mork(CettaLibraryContext *ctx, Arena *a,
                                         Atom *head, Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_mork_space_new) {
        return mork_space_new_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_space_include) {
        return mork_space_include_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_space_dump_act) {
        return mork_space_dump_act_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_space_open_act) {
        return mork_space_open_act_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_space_import_act) {
        return mork_space_import_act_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_clone) {
        return mork_space_clone_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_space_step ||
        head_id == g_builtin_syms.lib_mork_space_add_atoms ||
        head_id == g_builtin_syms.lib_mork_space_add_stream ||
        head_id == g_builtin_syms.mork_add_atoms ||
        head_id == g_builtin_syms.lib_mork_space_add_atom ||
        head_id == g_builtin_syms.mork_add_atom ||
        head_id == g_builtin_syms.lib_mork_space_remove_atom ||
        head_id == g_builtin_syms.mork_remove_atom ||
        head_id == g_builtin_syms.lib_mork_space_atoms ||
        head_id == g_builtin_syms.lib_mork_space_size ||
        head_id == g_builtin_syms.lib_mork_space_count_atoms ||
        head_id == g_builtin_syms.lib_mork_space_match) {
        return mork_space_surface_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_join ||
        head_id == g_builtin_syms.lib_mork_meet ||
        head_id == g_builtin_syms.lib_mork_subtract ||
        head_id == g_builtin_syms.lib_mork_restrict) {
        return mork_space_algebra_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_new) {
        return mork_zipper_new_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_close) {
        return mork_zipper_close_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_path_exists ||
        head_id == g_builtin_syms.lib_mork_zipper_is_val) {
        return mork_zipper_bool_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_path_of_atom) {
        return mork_path_of_atom_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_path_bytes ||
        head_id == g_builtin_syms.lib_mork_zipper_child_bytes) {
        return mork_zipper_bytes_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_child_count ||
        head_id == g_builtin_syms.lib_mork_zipper_val_count ||
        head_id == g_builtin_syms.lib_mork_zipper_depth) {
        return mork_zipper_count_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_reset) {
        return mork_zipper_reset_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_ascend) {
        return mork_zipper_ascend_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_descend_byte) {
        return mork_zipper_descend_byte_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_descend_index) {
        return mork_zipper_descend_index_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_descend_first ||
        head_id == g_builtin_syms.lib_mork_zipper_descend_last ||
        head_id == g_builtin_syms.lib_mork_zipper_descend_until ||
        head_id == g_builtin_syms.lib_mork_zipper_ascend_until ||
        head_id == g_builtin_syms.lib_mork_zipper_ascend_until_branch ||
        head_id == g_builtin_syms.lib_mork_zipper_next_sibling_byte ||
        head_id == g_builtin_syms.lib_mork_zipper_prev_sibling_byte ||
        head_id == g_builtin_syms.lib_mork_zipper_next_step ||
        head_id == g_builtin_syms.lib_mork_zipper_next_val) {
        return mork_zipper_descend_simple_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_descend_until_max_bytes) {
        return mork_zipper_descend_until_max_bytes_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_fork) {
        return mork_zipper_fork_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_zipper_make_map ||
        head_id == g_builtin_syms.lib_mork_zipper_make_snapshot_map) {
        return mork_zipper_materialize_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_new) {
        return mork_product_zipper_new_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_close) {
        return mork_product_zipper_close_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_path_exists ||
        head_id == g_builtin_syms.lib_mork_product_zipper_is_val) {
        return mork_product_zipper_bool_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_path_bytes ||
        head_id == g_builtin_syms.lib_mork_product_zipper_child_bytes ||
        head_id == g_builtin_syms.lib_mork_product_zipper_path_indices) {
        return mork_product_zipper_bytes_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_child_count ||
        head_id == g_builtin_syms.lib_mork_product_zipper_val_count ||
        head_id == g_builtin_syms.lib_mork_product_zipper_depth ||
        head_id == g_builtin_syms.lib_mork_product_zipper_factor_count ||
        head_id == g_builtin_syms.lib_mork_product_zipper_focus_factor) {
        return mork_product_zipper_count_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_reset) {
        return mork_product_zipper_reset_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_ascend) {
        return mork_product_zipper_ascend_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_descend_byte) {
        return mork_product_zipper_descend_byte_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_descend_index) {
        return mork_product_zipper_descend_index_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_descend_first ||
        head_id == g_builtin_syms.lib_mork_product_zipper_descend_last ||
        head_id == g_builtin_syms.lib_mork_product_zipper_descend_until ||
        head_id == g_builtin_syms.lib_mork_product_zipper_ascend_until ||
        head_id == g_builtin_syms.lib_mork_product_zipper_ascend_until_branch ||
        head_id == g_builtin_syms.lib_mork_product_zipper_next_sibling_byte ||
        head_id == g_builtin_syms.lib_mork_product_zipper_prev_sibling_byte ||
        head_id == g_builtin_syms.lib_mork_product_zipper_next_step ||
        head_id == g_builtin_syms.lib_mork_product_zipper_next_val) {
        return mork_product_zipper_descend_simple_native(ctx, a, head, args, nargs,
                                                         head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_product_zipper_descend_until_max_bytes) {
        return mork_product_zipper_descend_until_max_bytes_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_new) {
        return mork_overlay_zipper_new_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_close) {
        return mork_overlay_zipper_close_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_path_exists ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_is_val) {
        return mork_overlay_zipper_bool_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_path_bytes ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_child_bytes) {
        return mork_overlay_zipper_bytes_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_child_count ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_depth) {
        return mork_overlay_zipper_count_native(ctx, a, head, args, nargs, head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_reset) {
        return mork_overlay_zipper_reset_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_ascend) {
        return mork_overlay_zipper_ascend_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_descend_byte) {
        return mork_overlay_zipper_descend_byte_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_descend_index) {
        return mork_overlay_zipper_descend_index_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_descend_first ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_descend_last ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_descend_until ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_ascend_until ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_ascend_until_branch ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_next_sibling_byte ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_prev_sibling_byte ||
        head_id == g_builtin_syms.lib_mork_overlay_zipper_next_step) {
        return mork_overlay_zipper_descend_simple_native(ctx, a, head, args, nargs,
                                                         head_id);
    }
    if (head_id == g_builtin_syms.lib_mork_overlay_zipper_descend_until_max_bytes) {
        return mork_overlay_zipper_descend_until_max_bytes_native(ctx, a, head, args, nargs);
    }
    return NULL;
}

static void library_mm2_program_free_resource(void *resource) {
    cetta_mork_bridge_program_free((CettaMorkProgramHandle *)resource);
}

static void library_mm2_context_free_resource(void *resource) {
    cetta_mork_bridge_context_free((CettaMorkContextHandle *)resource);
}

static void library_mork_cursor_free_resource(void *resource) {
    CettaMorkCursorResource *cursor_resource = (CettaMorkCursorResource *)resource;
    if (!cursor_resource) return;
    if (cursor_resource->cursor)
        cetta_mork_bridge_cursor_free(cursor_resource->cursor);
    free(cursor_resource);
}

static void library_mork_space_free_resource(void *resource) {
    CettaMorkSpaceResource *space_resource = (CettaMorkSpaceResource *)resource;
    if (!space_resource)
        return;
    if (space_resource->bridge_space)
        cetta_mork_bridge_space_free(space_resource->bridge_space);
    free(space_resource);
}

static void library_mork_product_cursor_free_resource(void *resource) {
    CettaMorkProductCursorResource *cursor_resource =
        (CettaMorkProductCursorResource *)resource;
    if (!cursor_resource) return;
    if (cursor_resource->cursor)
        cetta_mork_bridge_product_cursor_free(cursor_resource->cursor);
    free(cursor_resource);
}

static void library_mork_overlay_cursor_free_resource(void *resource) {
    CettaMorkOverlayCursorResource *cursor_resource =
        (CettaMorkOverlayCursorResource *)resource;
    if (!cursor_resource) return;
    if (cursor_resource->cursor)
        cetta_mork_bridge_overlay_cursor_free(cursor_resource->cursor);
    free(cursor_resource);
}

static Atom *library_mm2_bridge_error(Arena *a, Atom *head, Atom **args,
                                      uint32_t nargs, const char *prefix) {
    char buf[512];
    snprintf(buf, sizeof(buf), "%s%s", prefix, cetta_mork_bridge_last_error());
    return atom_error(a, library_call_expr(a, head, args, nargs), atom_string(a, buf));
}

static Atom *mm2_program_new_native(CettaLibraryContext *ctx, Arena *a,
                                    Atom *head, Atom **args, uint32_t nargs) {
    uint64_t id = 0;
    CettaMorkProgramHandle *program;
    if (!system_zero_arg_ok(args, nargs)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected: (__cetta_lib_mm2_program_new)");
    }
    if (!cetta_mork_bridge_is_available()) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 MORK bridge unavailable: ");
    }
    program = cetta_mork_bridge_program_new();
    if (!program) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 program allocation failed: ");
    }
    if (!cetta_native_handle_alloc(ctx, CETTA_MM2_PROGRAM_HANDLE_KIND, program,
                                   library_mm2_program_free_resource, &id)) {
        cetta_mork_bridge_program_free(program);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "MM2 program handle allocation failed"));
    }
    return cetta_native_handle_atom(a, CETTA_MM2_PROGRAM_HANDLE_KIND, id);
}

static Atom *mm2_program_clear_native(CettaLibraryContext *ctx, Arena *a,
                                      Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkProgramHandle *program;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected program handle");
    }
    program = library_mm2_program_handle(ctx, args[0]);
    if (!program) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-program handle");
    }
    if (!cetta_mork_bridge_program_clear(program)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 program clear failed: ");
    }
    return atom_unit(a);
}

static Atom *mm2_program_add_native(CettaLibraryContext *ctx, Arena *a,
                                    Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkProgramHandle *program;
    char *text;
    if (nargs != 2) {
        return library_signature_error(a, head, args, nargs,
                                       "expected program handle and MM2 atom");
    }
    program = library_mm2_program_handle(ctx, args[0]);
    if (!program) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-program handle as first argument");
    }
    text = library_mm2_surface_text(a, args[1]);
    if (!cetta_mork_bridge_program_add_sexpr(program, (const uint8_t *)text,
                                             strlen(text), NULL)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 program add failed: ");
    }
    return atom_unit(a);
}

static Atom *mm2_load_file_native(CettaLibraryContext *ctx, Arena *a,
                                  Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkProgramHandle *program;
    CettaMorkContextHandle *context;
    const char *path;
    char resolved[PATH_MAX];
    Arena parse_arena;
    Atom **atoms = NULL;
    int n = 0;
    Atom *error = NULL;

    if (nargs != 3 || !(path = library_text_arg(args[2]))) {
        return library_signature_error(a, head, args, nargs,
                                       "expected program handle, context handle, and MM2 filename");
    }
    program = library_mm2_program_handle(ctx, args[0]);
    context = library_mm2_context_handle(ctx, args[1]);
    if (!program || !context) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-program handle and mork-context handle");
    }
    if (!library_resolve_current_path(ctx, path, resolved, sizeof(resolved))) {
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "MM2 file path resolution failed"));
    }

    arena_init(&parse_arena);
    arena_set_runtime_kind(&parse_arena, CETTA_ARENA_RUNTIME_KIND_SCRATCH);
    n = parse_metta_file(resolved, &parse_arena, &atoms);
    if (n < 0) {
        error = atom_error(a, library_call_expr(a, head, args, nargs),
                           atom_string(a, "MM2 file parse failed"));
        goto done;
    }

    cetta_mm2_lower_atoms(&parse_arena, atoms, n);
    if (cetta_mm2_atoms_have_top_level_eval(atoms, n)) {
        error = atom_error(a, library_call_expr(a, head, args, nargs),
                           atom_string(a, "MM2 file loader does not accept top-level ! forms"));
        goto done;
    }

    for (int i = 0; i < n; i++) {
        char *surface = cetta_mm2_atom_to_surface_string(&parse_arena, atoms[i]);
        bool ok;
        if (cetta_mm2_atom_is_exec_rule(atoms[i])) {
            ok = cetta_mork_bridge_program_add_sexpr(program,
                                                     (const uint8_t *)surface,
                                                     strlen(surface), NULL);
        } else {
            ok = cetta_mork_bridge_context_add_sexpr(context,
                                                     (const uint8_t *)surface,
                                                     strlen(surface), NULL);
        }
        if (!ok) {
            error = library_mm2_bridge_error(
                a, head, args, nargs,
                cetta_mm2_atom_is_exec_rule(atoms[i]) ?
                    "MM2 file load program add failed: " :
                    "MM2 file load context add failed: ");
            goto done;
        }
    }

done:
    free(atoms);
    arena_free(&parse_arena);
    if (error) return error;
    return atom_unit(a);
}

static Atom *mm2_program_size_native(CettaLibraryContext *ctx, Arena *a,
                                     Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkProgramHandle *program;
    uint64_t size = 0;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected program handle");
    }
    program = library_mm2_program_handle(ctx, args[0]);
    if (!program) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-program handle");
    }
    if (!cetta_mork_bridge_program_size(program, &size)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 program size failed: ");
    }
    return atom_int(a, (int64_t)size);
}

static Atom *mm2_program_atoms_native(CettaLibraryContext *ctx, Arena *a,
                                      Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkProgramHandle *program;
    uint8_t *packet = NULL;
    size_t len = 0;
    uint32_t rows = 0;
    Atom *result;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected program handle");
    }
    program = library_mm2_program_handle(ctx, args[0]);
    if (!program) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-program handle");
    }
    if (!cetta_mork_bridge_program_dump(program, &packet, &len, &rows)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 program dump failed: ");
    }
    result = library_atoms_from_text(a, packet, len, library_call_expr(a, head, args, nargs));
    cetta_mork_bridge_bytes_free(packet, len);
    (void)rows;
    return result;
}

static Atom *mm2_context_new_native(CettaLibraryContext *ctx, Arena *a,
                                    Atom *head, Atom **args, uint32_t nargs) {
    uint64_t id = 0;
    CettaMorkContextHandle *context;
    if (!system_zero_arg_ok(args, nargs)) {
        return library_signature_error(a, head, args, nargs,
                                       "expected: (__cetta_lib_mm2_context_new)");
    }
    if (!cetta_mork_bridge_is_available()) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 MORK bridge unavailable: ");
    }
    context = cetta_mork_bridge_context_new();
    if (!context) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 context allocation failed: ");
    }
    if (!cetta_native_handle_alloc(ctx, CETTA_MM2_CONTEXT_HANDLE_KIND, context,
                                   library_mm2_context_free_resource, &id)) {
        cetta_mork_bridge_context_free(context);
        return atom_error(a, library_call_expr(a, head, args, nargs),
                          atom_string(a, "MM2 context handle allocation failed"));
    }
    return cetta_native_handle_atom(a, CETTA_MM2_CONTEXT_HANDLE_KIND, id);
}

static Atom *mm2_context_clear_native(CettaLibraryContext *ctx, Arena *a,
                                      Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkContextHandle *context;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected context handle");
    }
    context = library_mm2_context_handle(ctx, args[0]);
    if (!context) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-context handle");
    }
    if (!cetta_mork_bridge_context_clear(context)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 context clear failed: ");
    }
    return atom_unit(a);
}

static Atom *mm2_context_load_program_native(CettaLibraryContext *ctx, Arena *a,
                                             Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkContextHandle *context;
    CettaMorkProgramHandle *program;
    if (nargs != 2) {
        return library_signature_error(a, head, args, nargs,
                                       "expected context handle and program handle");
    }
    context = library_mm2_context_handle(ctx, args[0]);
    program = library_mm2_program_handle(ctx, args[1]);
    if (!context || !program) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-context handle and mork-program handle");
    }
    if (!cetta_mork_bridge_context_load_program(context, program, NULL)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 context load-program failed: ");
    }
    return atom_unit(a);
}

static Atom *mm2_context_add_like_native(CettaLibraryContext *ctx, Arena *a,
                                         Atom *head, Atom **args, uint32_t nargs,
                                         bool remove_mode) {
    CettaMorkContextHandle *context;
    char *text;
    bool ok;
    if (nargs != 2) {
        return library_signature_error(a, head, args, nargs,
                                       "expected context handle and MM2 atom");
    }
    context = library_mm2_context_handle(ctx, args[0]);
    if (!context) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-context handle as first argument");
    }
    text = library_mm2_surface_text(a, args[1]);
    if (remove_mode) {
        ok = cetta_mork_bridge_context_remove_sexpr(context, (const uint8_t *)text,
                                                    strlen(text), NULL);
    } else {
        ok = cetta_mork_bridge_context_add_sexpr(context, (const uint8_t *)text,
                                                 strlen(text), NULL);
    }
    if (!ok) {
        return library_mm2_bridge_error(
            a, head, args, nargs,
            remove_mode ? "MM2 context remove failed: " : "MM2 context add failed: ");
    }
    return atom_unit(a);
}

static Atom *mm2_context_step_native(CettaLibraryContext *ctx, Arena *a,
                                     Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkContextHandle *context;
    uint64_t performed = 0;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected context handle");
    }
    context = library_mm2_context_handle(ctx, args[0]);
    if (!context) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-context handle");
    }
    if (!cetta_mork_bridge_context_run(context, 1, &performed)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 context step failed: ");
    }
    return atom_int(a, (int64_t)performed);
}

static Atom *mm2_context_run_native(CettaLibraryContext *ctx, Arena *a,
                                    Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkContextHandle *context;
    uint64_t steps = CETTA_MM2_DEFAULT_RUN_STEPS;
    uint64_t performed = 0;
    int parsed_steps = 0;
    if (nargs != 1 && nargs != 2) {
        return library_signature_error(a, head, args, nargs,
                                       "expected context handle and optional non-negative steps");
    }
    context = library_mm2_context_handle(ctx, args[0]);
    if (!context) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-context handle");
    }
    if (nargs == 2) {
        if (!library_int_arg(args[1], &parsed_steps) || parsed_steps < 0) {
            return library_signature_error(a, head, args, nargs,
                                           "expected non-negative step count");
        }
        steps = (uint64_t)parsed_steps;
    }
    if (!cetta_mork_bridge_context_run(context, steps, &performed)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 context run failed: ");
    }
    return atom_int(a, (int64_t)performed);
}

static Atom *mm2_context_size_native(CettaLibraryContext *ctx, Arena *a,
                                     Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkContextHandle *context;
    uint64_t size = 0;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected context handle");
    }
    context = library_mm2_context_handle(ctx, args[0]);
    if (!context) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-context handle");
    }
    if (!cetta_mork_bridge_context_size(context, &size)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 context size failed: ");
    }
    return atom_int(a, (int64_t)size);
}

static Atom *mm2_context_atoms_native(CettaLibraryContext *ctx, Arena *a,
                                      Atom *head, Atom **args, uint32_t nargs) {
    CettaMorkContextHandle *context;
    uint8_t *packet = NULL;
    size_t len = 0;
    uint32_t rows = 0;
    Atom *result;
    if (nargs != 1) {
        return library_signature_error(a, head, args, nargs,
                                       "expected context handle");
    }
    context = library_mm2_context_handle(ctx, args[0]);
    if (!context) {
        return library_signature_error(a, head, args, nargs,
                                       "expected mork-context handle");
    }
    if (!cetta_mork_bridge_context_dump(context, &packet, &len, &rows)) {
        return library_mm2_bridge_error(a, head, args, nargs,
                                        "MM2 context dump failed: ");
    }
    result = library_atoms_from_text(a, packet, len, library_call_expr(a, head, args, nargs));
    cetta_mork_bridge_bytes_free(packet, len);
    (void)rows;
    return result;
}

static Atom *cetta_library_dispatch_mm2(CettaLibraryContext *ctx, Arena *a,
                                        Atom *head, Atom **args, uint32_t nargs) {
    if (head->kind != ATOM_SYMBOL) return NULL;
    SymbolId head_id = head->sym_id;
    if (head_id == g_builtin_syms.lib_mm2_program_new) {
        return mm2_program_new_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_program_clear) {
        return mm2_program_clear_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_program_add) {
        return mm2_program_add_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_load_file) {
        return mm2_load_file_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_program_size) {
        return mm2_program_size_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_program_atoms) {
        return mm2_program_atoms_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_context_new) {
        return mm2_context_new_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_context_clear) {
        return mm2_context_clear_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_context_load_program) {
        return mm2_context_load_program_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_context_add) {
        return mm2_context_add_like_native(ctx, a, head, args, nargs, false);
    }
    if (head_id == g_builtin_syms.lib_mm2_context_remove) {
        return mm2_context_add_like_native(ctx, a, head, args, nargs, true);
    }
    if (head_id == g_builtin_syms.lib_mm2_context_run) {
        return mm2_context_run_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_context_step) {
        return mm2_context_step_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_context_size) {
        return mm2_context_size_native(ctx, a, head, args, nargs);
    }
    if (head_id == g_builtin_syms.lib_mm2_context_atoms) {
        return mm2_context_atoms_native(ctx, a, head, args, nargs);
    }
    return NULL;
}

static bool result_set_has_error(ResultSet *rs) {
    for (uint32_t i = 0; i < rs->len; i++) {
        if (atom_is_error(rs->items[i])) return true;
    }
    return false;
}

static Atom *result_set_first_error(Arena *dst, ResultSet *rs) {
    for (uint32_t i = 0; i < rs->len; i++) {
        if (atom_is_error(rs->items[i])) {
            return atom_deep_copy(dst, rs->items[i]);
        }
    }
    return NULL;
}

static Atom *module_reason(CettaLibraryContext *ctx, Arena *a,
                           const char *tag, const char *path) {
    char display[PATH_MAX];
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, tag),
        atom_string(a, cetta_library_display_path(ctx, path, display, sizeof(display)))
    }, 2);
}

static Atom *module_reason_with_detail(CettaLibraryContext *ctx, Arena *a,
                                       const char *tag,
                                       const char *path, Atom *detail) {
    char display[PATH_MAX];
    return atom_expr(a, (Atom *[]){
        atom_symbol(a, tag),
        atom_string(a, cetta_library_display_path(ctx, path, display, sizeof(display))),
        detail
    }, 3);
}

static bool load_act_dump_text_into_space(CettaLibraryContext *ctx,
                                          const char *path,
                                          const uint8_t *bytes, size_t len,
                                          Space *target,
                                          Arena *persistent_arena,
                                          Arena *eval_arena,
                                          Atom **error_out) {
    char *text = cetta_malloc(len + 1);
    memcpy(text, bytes, len);
    text[len] = '\0';

    if (target && target->native.universe) {
        AtomId *atom_ids = NULL;
        int n = parse_metta_text_ids(text, target->native.universe, &atom_ids);
        if (n < 0) {
            free(text);
            *error_out = module_reason(ctx, eval_arena, "ModuleCompiledParseFailed", path);
            return false;
        }
        for (int i = 0; i < n; i++) {
            space_add_atom_id(target, atom_ids[i]);
        }
        free(atom_ids);
        free(text);
        return true;
    }

    Arena *dst = persistent_arena ? persistent_arena : eval_arena;
    size_t pos = 0;
    while (text[pos]) {
        size_t before = pos;
        Atom *atom = parse_sexpr(dst, text, &pos);
        if (!atom) {
            while (text[pos] && isspace((unsigned char)text[pos])) pos++;
            if (text[pos] == '\0')
                break;
            free(text);
            *error_out = module_reason(ctx, eval_arena, "ModuleCompiledParseFailed", path);
            return false;
        }
        if (pos == before) {
            free(text);
            *error_out = module_reason(ctx, eval_arena, "ModuleCompiledParseStuck", path);
            return false;
        }
        if (!space_admit_atom(target, dst, atom)) {
            free(text);
            *error_out = module_reason(ctx, eval_arena, "ModuleCompiledLoadFailed", path);
            return false;
        }
    }

    free(text);
    return true;
}

static bool load_module_act_file(CettaLibraryContext *ctx, const char *path,
                                 Space *work_space,
                                 Arena *eval_arena,
                                 Arena *persistent_arena,
                                 Atom **error_out) {
    CettaMorkSpaceHandle *bridge = NULL;
    Space imported;
    uint8_t *packet = NULL;
    size_t packet_len = 0;
    uint32_t rows = 0;
    bool imported_init = false;
    bool ok = false;

    if (space_is_ordered(work_space)) {
        *error_out = module_reason(ctx, eval_arena, "ModuleCompiledOrderedSpaceUnsupported", path);
        return false;
    }
    if (!cetta_mork_bridge_is_available()) {
        *error_out = module_reason_with_detail(
            ctx, eval_arena, "ModuleCompiledBridgeUnavailable", path,
            atom_string(eval_arena, cetta_mork_bridge_last_error()));
        return false;
    }
    bridge = cetta_mork_bridge_space_new();
    if (!bridge) {
        *error_out = module_reason_with_detail(
            ctx, eval_arena, "ModuleCompiledBridgeAllocationFailed", path,
            atom_string(eval_arena, cetta_mork_bridge_last_error()));
        return false;
    }
    if (!cetta_mork_bridge_space_load_act_file(
            bridge, (const uint8_t *)path, strlen(path), NULL)) {
        *error_out = module_reason_with_detail(
            ctx, eval_arena, "ModuleCompiledLoadFailed", path,
            atom_string(eval_arena, cetta_mork_bridge_last_error()));
        goto cleanup;
    }

    space_init_with_universe(
        &imported, work_space ? work_space->native.universe : NULL);
    imported_init = true;
    SpaceTransferEndpoint import_dst = {
        .kind = SPACE_TRANSFER_ENDPOINT_SPACE,
        .space = &imported,
    };
    SpaceTransferEndpoint import_src = {
        .kind = SPACE_TRANSFER_ENDPOINT_MORK_BRIDGE,
        .bridge = bridge,
    };
    switch (space_match_backend_transfer_resolved_result(import_dst, import_src,
                                                         persistent_arena, NULL)) {
    case SPACE_TRANSFER_OK:
        for (uint32_t i = 0, n = space_length(&imported); i < n; i++) {
            space_add_atom_id(work_space, space_get_atom_id_at(&imported, i));
        }
        break;
    case SPACE_TRANSFER_NEEDS_TEXT_FALLBACK:
        if (!cetta_mork_bridge_space_dump(bridge, &packet, &packet_len, &rows)) {
            *error_out = module_reason_with_detail(
                ctx, eval_arena, "ModuleCompiledDumpFailed", path,
                atom_string(eval_arena, cetta_mork_bridge_last_error()));
            goto cleanup;
        }
        if (!load_act_dump_text_into_space(ctx, path, packet, packet_len, work_space,
                                           persistent_arena, eval_arena, error_out)) {
            goto cleanup;
        }
        break;
    case SPACE_TRANSFER_ERROR:
    default:
        *error_out = module_reason_with_detail(
            ctx, eval_arena, "ModuleCompiledImportFailed", path,
            atom_string(eval_arena, "structural bridge import failed"));
        goto cleanup;
    }

    ok = true;

cleanup:
    cetta_mork_bridge_bytes_free(packet, packet_len);
    if (imported_init)
        space_free(&imported);
    cetta_mork_bridge_space_free(bridge);
    (void)rows;
    return ok;
}

static bool load_module_act_file_pathmap_materialized(CettaLibraryContext *ctx,
                                                      const char *path,
                                                      Space *target_space,
                                                      Arena *eval_arena,
                                                      Arena *persistent_arena,
                                                      Atom **error_out) {
    if (space_is_ordered(target_space)) {
        *error_out = module_reason(ctx, eval_arena, "ModuleCompiledOrderedSpaceUnsupported", path);
        return false;
    }
    if (space_match_backend_logical_len(target_space) != 0) {
        *error_out = module_reason(ctx, eval_arena, "ModuleCompiledAttachRequiresFreshSpace", path);
        return false;
    }
    const char *backend_reason =
        space_match_backend_unavailable_reason(SPACE_ENGINE_PATHMAP);
    if (backend_reason) {
        *error_out = module_reason_with_detail(
            ctx, eval_arena, "ModuleCompiledAttachBackendUnavailable", path,
            atom_string(eval_arena, backend_reason));
        return false;
    }
    if (!space_match_backend_try_set(target_space, SPACE_ENGINE_PATHMAP)) {
        *error_out = module_reason(ctx, eval_arena, "ModuleCompiledAttachBackendUnavailable", path);
        return false;
    }
    if (!load_module_act_file(ctx, path, target_space, eval_arena,
                              persistent_arena, error_out)) {
        return false;
    }
    return true;
}

static bool load_module_mm2_file(CettaLibraryContext *ctx, const char *path,
                                 Space *work_space,
                                 Arena *eval_arena,
                                 Arena *persistent_arena,
                                 Atom **error_out) {
    (void)work_space;
    (void)persistent_arena;

    if (error_out) {
        *error_out = module_reason_with_detail(
            ctx, eval_arena, "ModuleMm2LoadFailed", path,
            atom_string(eval_arena,
                        "generic import/include does not accept .mm2; use "
                        "(mork:include! <MorkSpace> spec)"));
    }
    return false;
}

static void skip_mork_include_whitespace_and_comments(const char *text, size_t *pos) {
    for (;;) {
        while (text[*pos] && isspace((unsigned char)text[*pos])) {
            (*pos)++;
        }
        if (text[*pos] == ';') {
            while (text[*pos] && text[*pos] != '\n') {
                (*pos)++;
            }
        } else {
            break;
        }
    }
}

static bool read_mork_include_text_file(const char *path, char **text_out) {
    FILE *f = fopen(path, "r");
    char *text = NULL;
    size_t cap = 4096;
    size_t nread = 0;

    *text_out = NULL;
    if (!f) {
        return false;
    }

    text = cetta_malloc(cap + 1);
    for (;;) {
        size_t need = cap - nread;
        size_t got = fread(text + nread, 1, need, f);
        nread += got;
        if (got < need) {
            if (ferror(f)) {
                fclose(f);
                free(text);
                return false;
            }
            if (feof(f)) {
                break;
            }
        }
        if (nread == cap) {
            cap *= 2;
            text = cetta_realloc(text, cap + 1);
        }
    }

    fclose(f);
    text[nread] = '\0';
    *text_out = text;
    return true;
}

static bool load_module_mm2_file_into_mork_bridge(CettaLibraryContext *ctx,
                                                  const char *path,
                                                  CettaMorkSpaceHandle *bridge,
                                                  Arena *eval_arena,
                                                  Arena *persistent_arena,
                                                  Atom **error_out) {
    Arena *parse_arena = persistent_arena ? persistent_arena : eval_arena;
    char *text = NULL;
    size_t pos = 0;
    bool ok = false;

    if (!bridge) {
        *error_out = module_reason(ctx, eval_arena, "ModuleMm2BridgeUnavailable", path);
        return false;
    }

    if (!read_mork_include_text_file(path, &text)) {
        *error_out = module_reason(ctx, eval_arena, "ModuleMm2ReadFailed", path);
        return false;
    }

    ok = true;
    for (;;) {
        skip_mork_include_whitespace_and_comments(text, &pos);
        if (!text[pos]) {
            break;
        }
        size_t start = pos;
        Atom *atom = parse_sexpr(parse_arena, text, &pos);
        if (!atom) {
            *error_out = module_reason(ctx, eval_arena, "ModuleMm2LoadFailed", path);
            ok = false;
            break;
        }
        if (atom_is_symbol_id(atom, g_builtin_syms.bang)) {
            *error_out = module_reason(ctx, eval_arena, "ModuleMm2LoadFailed", path);
            ok = false;
            break;
        }
        if (!cetta_mork_bridge_space_add_sexpr(
                bridge, (const uint8_t *)(text + start), pos - start, NULL)) {
            *error_out = module_reason_with_detail(
                ctx, eval_arena, "ModuleMm2BridgeLoadFailed", path,
                atom_string(eval_arena, cetta_mork_bridge_last_error()));
            ok = false;
            break;
        }
    }
    free(text);
    return ok;
}

static bool load_module_file(CettaLibraryContext *ctx, const char *path,
                             Space *logical_space, Space *work_space,
                             Arena *eval_arena,
                             Arena *persistent_arena, Registry *registry,
                             int fuel, Atom **error_out) {
    int slot = imported_file_lookup(ctx, logical_space, path);
    if (slot >= 0) {
        if (ctx->imported_files[slot].loading) {
            *error_out = module_reason(ctx, eval_arena, "ModuleImportCycle", path);
            return false;
        }
        return true;
    }
    if (ctx->imported_file_len >= CETTA_MAX_IMPORTED_FILES) {
        *error_out = atom_symbol(eval_arena, "too many imported files");
        return false;
    }

    slot = (int)ctx->imported_file_len++;
    ctx->imported_files[slot].space = logical_space;
    ctx->imported_files[slot].loading = true;
    snprintf(ctx->imported_files[slot].path,
             sizeof(ctx->imported_files[slot].path), "%s", path);

    char import_dir[PATH_MAX];
    copy_parent_dir(import_dir, sizeof(import_dir), path);
    cetta_library_push_dir(ctx, import_dir);

    Atom *prev_self = NULL;
    if (registry) {
        prev_self = registry_lookup_id(registry, g_builtin_syms.self);
        registry_bind_id(registry, g_builtin_syms.self,
                         atom_space(persistent_arena, work_space));
    }

    Atom **atoms = NULL;
    AtomId *atom_ids = NULL;
    CettaModuleFormat format = {
        .kind = CETTA_MODULE_FORMAT_METTA,
        .foreign_backend = CETTA_FOREIGN_BACKEND_NONE,
    };
    CettaLoadedModule *loaded = loaded_module_lookup(ctx, path);
    if (loaded) {
        format = loaded->format;
    }

    bool ok = true;
    if (format.kind == CETTA_MODULE_FORMAT_FOREIGN) {
        ok = cetta_foreign_load_module(ctx->foreign_runtime, path, work_space,
                                       persistent_arena, error_out);
        if (!ok && error_out && *error_out) {
            *error_out = module_reason_with_detail(
                ctx, eval_arena, "ModuleForeignLoadFailed", path, *error_out);
        }
    } else if (format.kind == CETTA_MODULE_FORMAT_MORK_ACT) {
        ok = load_module_act_file(ctx, path, work_space, eval_arena,
                                  persistent_arena, error_out);
    } else if (format.kind == CETTA_MODULE_FORMAT_MM2) {
        ok = load_module_mm2_file(ctx, path, work_space, eval_arena,
                                  persistent_arena, error_out);
    } else {
        int n = parse_metta_file_ids(path,
                                     work_space ? work_space->native.universe : NULL,
                                     &atom_ids);
        if (n < 0) {
            ok = false;
            *error_out = module_reason(ctx, eval_arena, "ModuleParseFailed", path);
        } else {
            for (int i = 0; i < n; i++) {
                AtomId at_id = atom_ids[i];
                if (tu_kind(work_space->native.universe, at_id) == ATOM_SYMBOL &&
                    tu_sym(work_space->native.universe, at_id) == g_builtin_syms.bang &&
                    i + 1 < n) {
                    ResultSet rs;
                    result_set_init(&rs);
                    Atom *eval_form = term_universe_copy_atom(
                        work_space->native.universe,
                        persistent_arena ? persistent_arena : eval_arena,
                        atom_ids[i + 1]);
                    if (!eval_form) {
                        free(rs.items);
                        ok = false;
                        *error_out = module_reason(ctx, eval_arena,
                                                   "ModuleParseFailed", path);
                        break;
                    }
                    eval_top_with_registry(work_space, eval_arena, persistent_arena, registry,
                                           eval_form, &rs);
                    Atom *first_error = result_set_first_error(eval_arena, &rs);
                    bool stop_after_error = first_error != NULL || result_set_has_error(&rs);
                    free(rs.items);
                    eval_release_temporary_spaces();
                    if (stop_after_error) {
                        *error_out = first_error ? first_error :
                            module_reason(ctx, eval_arena, "ModuleInitError", path);
                        ok = false;
                        break;
                    }
                    i++;
                    continue;
                }
                space_add_atom_id(work_space, at_id);
            }
        }
    }

    if (registry) {
        if (prev_self) {
            registry_bind_id(registry, g_builtin_syms.self, prev_self);
        }
    }
    cetta_library_pop_dir(ctx);
    free(atoms);
    free(atom_ids);

    if (!ok) {
        ctx->imported_files[slot].loading = false;
        ctx->imported_files[slot].path[0] = '\0';
        return false;
    }

    ctx->imported_files[slot].loading = false;
    return true;
}

static bool load_module_file_transactional(CettaLibraryContext *ctx, const char *path,
                                           Space *target, Arena *eval_arena,
                                           Arena *persistent_arena, Registry *registry,
                                           int fuel, Atom **error_out) {
    uint32_t imported_len_before = ctx->imported_file_len;
    Space *work_space = space_heap_clone_shallow(target);
    if (!cetta_library_push_import_alias(ctx, work_space, target)) {
        space_free(work_space);
        free(work_space);
        *error_out = atom_symbol(eval_arena, "too many nested import transactions");
        return false;
    }

    bool ok = load_module_file(ctx, path, target, work_space, eval_arena,
                               persistent_arena, registry, fuel, error_out);
    cetta_library_pop_import_alias(ctx);

    if (!ok) {
        rollback_imported_files(ctx, imported_len_before);
        space_free(work_space);
        free(work_space);
        return false;
    }

    space_replace_contents(target, work_space);
    space_free(work_space);
    free(work_space);
    return true;
}

static bool execute_import_plan(CettaLibraryContext *ctx, const CettaImportPlan *plan,
                                Arena *eval_arena,
                                Arena *persistent_arena, Registry *registry,
                                int fuel, Atom **error_out) {
    uint32_t imported_len_before = ctx->imported_file_len;
    uint32_t loaded_len_before = ctx->loaded_module_len;
    if (!remember_loaded_module(ctx, plan, NULL, eval_arena, error_out)) {
        return false;
    }
    if (plan->format.kind == CETTA_MODULE_FORMAT_MORK_ACT &&
        plan->target_is_fresh &&
        !plan->transactional) {
        if (!load_module_act_file_pathmap_materialized(
                ctx, plan->canonical_path, plan->execution_target_space,
                eval_arena, persistent_arena, error_out)) {
            rollback_imported_files(ctx, imported_len_before);
            rollback_loaded_modules(ctx, loaded_len_before);
            return false;
        }
        return true;
    }
    if (plan->transactional &&
        plan->logical_target_space == plan->execution_target_space) {
        bool ok = load_module_file_transactional(ctx, plan->canonical_path,
                                                 plan->execution_target_space,
                                                 eval_arena, persistent_arena,
                                                 registry, fuel, error_out);
        if (!ok) {
            rollback_loaded_modules(ctx, loaded_len_before);
        }
        return ok;
    }
    if (!load_module_file(ctx, plan->canonical_path, plan->logical_target_space,
                          plan->execution_target_space, eval_arena,
                          persistent_arena, registry, fuel, error_out)) {
        if (plan->target_is_fresh) {
            rollback_imported_files(ctx, imported_len_before);
        }
        rollback_loaded_modules(ctx, loaded_len_before);
        return false;
    }
    return true;
}

static CettaLoadedModule *loaded_module_lookup(CettaLibraryContext *ctx,
                                               const char *canonical_path) {
    for (uint32_t i = 0; i < ctx->loaded_module_len; i++) {
        if (strcmp(ctx->loaded_modules[i].canonical_path, canonical_path) == 0) {
            return &ctx->loaded_modules[i];
        }
    }
    return NULL;
}

static CettaLoadedModule *remember_loaded_module(CettaLibraryContext *ctx,
                                                 const CettaImportPlan *plan,
                                                 Space *space,
                                                 Arena *eval_arena,
                                                 Atom **error_out) {
    CettaLoadedModule *entry = loaded_module_lookup(ctx, plan->canonical_path);
    if (entry) {
        if (space && !entry->space) {
            entry->space = space;
        }
        entry->format = plan->format;
        return entry;
    }
    if (ctx->loaded_module_len >= CETTA_MAX_LOADED_MODULES) {
        *error_out = atom_symbol(eval_arena, "too many loaded modules");
        return NULL;
    }
    entry = &ctx->loaded_modules[ctx->loaded_module_len++];
    memset(entry, 0, sizeof(*entry));
    snprintf(entry->display_name, sizeof(entry->display_name), "%s", plan->spec.raw_spec);
    snprintf(entry->canonical_path, sizeof(entry->canonical_path), "%s", plan->canonical_path);
    entry->provider_kind = plan->provider_kind;
    entry->format = plan->format;
    entry->space = space;
    entry->loading = false;
    return entry;
}

static CettaLoadedModule *ensure_loaded_module(CettaLibraryContext *ctx,
                                               const CettaImportPlan *plan,
                                               Arena *eval_arena,
                                               Arena *persistent_arena,
                                               Registry *registry,
                                               int fuel, Atom **error_out) {
    uint32_t loaded_len_before = ctx->loaded_module_len;
    CettaLoadedModule *entry = remember_loaded_module(ctx, plan, NULL, eval_arena, error_out);
    if (!entry) {
        return NULL;
    }
    if (entry->loading) {
        *error_out = atom_symbol(eval_arena, "module already loading");
        return NULL;
    }
    if (entry->space) {
        return entry;
    }
    entry->space = malloc(sizeof(Space));
    if (!entry->space) {
        rollback_loaded_modules(ctx, loaded_len_before);
        *error_out = atom_symbol(eval_arena, "module space allocation failed");
        return NULL;
    }
    space_init_with_universe(entry->space,
                             cetta_library_space_universe(ctx, persistent_arena));
    entry->loading = true;

    bool ok = false;
    if (plan->format.kind == CETTA_MODULE_FORMAT_MORK_ACT) {
        ok = load_module_act_file_pathmap_materialized(
            ctx, plan->canonical_path, entry->space,
            eval_arena, persistent_arena, error_out);
    } else {
        ok = load_module_file(ctx, plan->canonical_path, entry->space, entry->space,
                              eval_arena, persistent_arena, registry, fuel, error_out);
    }
    entry->loading = false;
    if (!ok) {
        rollback_loaded_modules(ctx, loaded_len_before);
        return NULL;
    }
    return entry;
}

static const char *loaded_module_storage_name(const CettaLoadedModule *module) {
    if (!module) return "unknown";
    if (module->format.kind == CETTA_MODULE_FORMAT_MORK_ACT &&
        module->space &&
        space_match_backend_is_attached_compiled(module->space)) {
        return "attached-compiled";
    }
    return "materialized";
}

static AtomId library_inventory_symbol_id(Space *inventory, const char *name) {
    if (!inventory || !inventory->native.universe || !name)
        return CETTA_ATOM_ID_NONE;
    return tu_intern_symbol(
        inventory->native.universe, symbol_intern_cstr(g_symbols, name));
}

static AtomId library_inventory_string_id(Space *inventory, const char *value) {
    if (!inventory || !inventory->native.universe || !value)
        return CETTA_ATOM_ID_NONE;
    return tu_intern_string(inventory->native.universe, value);
}

static bool library_inventory_add_ids(Space *inventory, const AtomId *items,
                                      uint32_t nitems) {
    if (!inventory || !inventory->native.universe || !items || nitems == 0)
        return false;
    AtomId expr_id = tu_expr_from_ids(inventory->native.universe, items, nitems);
    if (expr_id == CETTA_ATOM_ID_NONE)
        return false;
    space_add_atom_id(inventory, expr_id);
    return true;
}

static bool library_inventory_try_add_symbol_fact2(Space *inventory,
                                                   const char *head,
                                                   const char *arg1) {
    AtomId items[2] = {
        library_inventory_symbol_id(inventory, head),
        library_inventory_symbol_id(inventory, arg1),
    };
    return items[0] != CETTA_ATOM_ID_NONE &&
           items[1] != CETTA_ATOM_ID_NONE &&
           library_inventory_add_ids(inventory, items, 2);
}

static bool library_inventory_try_add_symbol_fact3(Space *inventory,
                                                   const char *head,
                                                   const char *arg1,
                                                   const char *arg2) {
    AtomId items[3] = {
        library_inventory_symbol_id(inventory, head),
        library_inventory_symbol_id(inventory, arg1),
        library_inventory_symbol_id(inventory, arg2),
    };
    return items[0] != CETTA_ATOM_ID_NONE &&
           items[1] != CETTA_ATOM_ID_NONE &&
           items[2] != CETTA_ATOM_ID_NONE &&
           library_inventory_add_ids(inventory, items, 3);
}

static bool library_inventory_try_add_string_symbol_fact3(
    Space *inventory, const char *head, const char *arg1,
    const char *arg2) {
    AtomId items[3] = {
        library_inventory_symbol_id(inventory, head),
        library_inventory_string_id(inventory, arg1),
        library_inventory_symbol_id(inventory, arg2),
    };
    return items[0] != CETTA_ATOM_ID_NONE &&
           items[1] != CETTA_ATOM_ID_NONE &&
           items[2] != CETTA_ATOM_ID_NONE &&
           library_inventory_add_ids(inventory, items, 3);
}

static bool library_inventory_try_add_symbol_string_symbol_fact4(
    Space *inventory, const char *head, const char *arg1,
    const char *arg2, const char *arg3) {
    AtomId items[4] = {
        library_inventory_symbol_id(inventory, head),
        library_inventory_symbol_id(inventory, arg1),
        library_inventory_string_id(inventory, arg2),
        library_inventory_symbol_id(inventory, arg3),
    };
    return items[0] != CETTA_ATOM_ID_NONE &&
           items[1] != CETTA_ATOM_ID_NONE &&
           items[2] != CETTA_ATOM_ID_NONE &&
           items[3] != CETTA_ATOM_ID_NONE &&
           library_inventory_add_ids(inventory, items, 4);
}

static bool library_inventory_try_add_symbol_symbol_string_fact4(
    Space *inventory, const char *head, const char *arg1,
    const char *arg2, const char *arg3) {
    AtomId items[4] = {
        library_inventory_symbol_id(inventory, head),
        library_inventory_symbol_id(inventory, arg1),
        library_inventory_symbol_id(inventory, arg2),
        library_inventory_string_id(inventory, arg3),
    };
    return items[0] != CETTA_ATOM_ID_NONE &&
           items[1] != CETTA_ATOM_ID_NONE &&
           items[2] != CETTA_ATOM_ID_NONE &&
           items[3] != CETTA_ATOM_ID_NONE &&
           library_inventory_add_ids(inventory, items, 4);
}

static bool library_inventory_try_add_string_string_symbol_fact4(
    Space *inventory, const char *head, const char *arg1,
    const char *arg2, const char *arg3) {
    AtomId items[4] = {
        library_inventory_symbol_id(inventory, head),
        library_inventory_string_id(inventory, arg1),
        library_inventory_string_id(inventory, arg2),
        library_inventory_symbol_id(inventory, arg3),
    };
    return items[0] != CETTA_ATOM_ID_NONE &&
           items[1] != CETTA_ATOM_ID_NONE &&
           items[2] != CETTA_ATOM_ID_NONE &&
           items[3] != CETTA_ATOM_ID_NONE &&
           library_inventory_add_ids(inventory, items, 4);
}

static bool library_inventory_try_add_string_symbol_symbol_fact4(
    Space *inventory, const char *head, const char *arg1,
    const char *arg2, const char *arg3) {
    AtomId items[4] = {
        library_inventory_symbol_id(inventory, head),
        library_inventory_string_id(inventory, arg1),
        library_inventory_symbol_id(inventory, arg2),
        library_inventory_symbol_id(inventory, arg3),
    };
    return items[0] != CETTA_ATOM_ID_NONE &&
           items[1] != CETTA_ATOM_ID_NONE &&
           items[2] != CETTA_ATOM_ID_NONE &&
           items[3] != CETTA_ATOM_ID_NONE &&
           library_inventory_add_ids(inventory, items, 4);
}

static void library_inventory_add_fallback_atom(Space *inventory, Arena *dst,
                                                Atom *atom) {
    /* Inventory facts should still cross the normal admission seam even when
       a direct bottom-up helper bailed out. Keep raw add as the last resort. */
    if (!space_admit_atom(inventory, dst, atom))
        space_add(inventory, atom);
}

Atom *cetta_library_mod_space(CettaLibraryContext *ctx, const char *spec,
                              Arena *eval_arena, Arena *persistent_arena,
                              Registry *registry, int fuel, Atom **error_out) {
    CettaModuleSpec parsed_spec;
    CettaImportPlan plan;
    if (!parse_module_spec(spec, &parsed_spec, eval_arena, error_out)) {
        return NULL;
    }
    if (!resolve_import_plan(ctx, &parsed_spec, NULL, NULL, false,
                             &plan, eval_arena, error_out)) {
        return NULL;
    }
    CettaLoadedModule *entry = ensure_loaded_module(ctx, &plan, eval_arena,
                                                    persistent_arena, registry,
                                                    fuel, error_out);
    if (!entry) return NULL;
    Arena *dst = persistent_arena ? persistent_arena : eval_arena;
    return atom_space(dst, entry->space);
}

Atom *cetta_library_module_inventory_space(CettaLibraryContext *ctx,
                                           Arena *eval_arena,
                                           Arena *persistent_arena,
                                           Atom **error_out) {
    (void)error_out;
    if (!ctx) return NULL;

    Arena *dst = persistent_arena ? persistent_arena : eval_arena;
    Space *inventory = arena_alloc(dst, sizeof(Space));
    space_init_with_universe(inventory, cetta_library_space_universe(ctx, dst));

    const char *language_name =
        cetta_language_canonical_name(ctx->session.language_id);
    if (!library_inventory_try_add_symbol_fact2(inventory, "module-language",
                                                language_name)) {
        library_inventory_add_fallback_atom(
            inventory, dst,
            atom_expr2(dst, atom_symbol(dst, "module-language"),
                       atom_symbol(dst, language_name)));
    }

    if (ctx->session.profile && ctx->session.profile->name &&
        !library_inventory_try_add_symbol_fact2(inventory, "module-profile",
                                                ctx->session.profile->name)) {
        library_inventory_add_fallback_atom(
            inventory, dst,
            atom_expr2(dst, atom_symbol(dst, "module-profile"),
                       atom_symbol(dst, ctx->session.profile->name)));
    }

    const char *import_mode_name = cetta_relative_module_policy_name(
        cetta_eval_session_relative_module_policy(&ctx->session));
    if (!library_inventory_try_add_symbol_fact2(inventory, "module-import-mode",
                                                import_mode_name)) {
        library_inventory_add_fallback_atom(
            inventory, dst,
            atom_expr2(dst, atom_symbol(dst, "module-import-mode"),
                       atom_symbol(dst, import_mode_name)));
    }

    for (uint32_t i = 0; i < cetta_module_provider_count(); i++) {
        const CettaModuleProviderDescriptor *desc = cetta_module_provider_at(i);
        if (!desc) continue;
        const char *provider_name = desc->name;
        bool enabled = module_provider_visible(ctx, desc->kind);
        if (!library_inventory_try_add_symbol_fact3(
                inventory, "module-provider", provider_name,
                enabled ? "enabled" : "disabled")) {
            library_inventory_add_fallback_atom(
                inventory, dst,
                atom_expr3(dst, atom_symbol(dst, "module-provider"),
                           atom_symbol(dst, provider_name),
                           atom_symbol(dst, enabled ? "enabled" : "disabled")));
        }
        if (!library_inventory_try_add_symbol_fact3(
                inventory, "module-provider-implementation", provider_name,
                desc->implemented ? "implemented" : "deferred")) {
            library_inventory_add_fallback_atom(
                inventory, dst,
                atom_expr3(dst, atom_symbol(dst, "module-provider-implementation"),
                           atom_symbol(dst, provider_name),
                           atom_symbol(dst, desc->implemented ? "implemented" : "deferred")));
        }
        if (!library_inventory_try_add_symbol_fact3(
                inventory, "module-provider-transport", provider_name,
                desc->remote_source ? "remote" : "local")) {
            library_inventory_add_fallback_atom(
                inventory, dst,
                atom_expr3(dst, atom_symbol(dst, "module-provider-transport"),
                           atom_symbol(dst, provider_name),
                           atom_symbol(dst, desc->remote_source ? "remote" : "local")));
        }
        if (!library_inventory_try_add_symbol_fact3(
                inventory, "module-provider-cache-policy", provider_name,
                desc->cache_backed ? "cache-backed" : "no-cache")) {
            library_inventory_add_fallback_atom(
                inventory, dst,
                atom_expr3(dst, atom_symbol(dst, "module-provider-cache-policy"),
                           atom_symbol(dst, provider_name),
                           atom_symbol(dst, desc->cache_backed ? "cache-backed" : "no-cache")));
        }
        if (!library_inventory_try_add_symbol_fact3(
                inventory, "module-provider-locator-kind", provider_name,
                cetta_module_locator_kind_name(desc->locator_kind))) {
            library_inventory_add_fallback_atom(
                inventory, dst,
                atom_expr3(dst, atom_symbol(dst, "module-provider-locator-kind"),
                           atom_symbol(dst, provider_name),
                           atom_symbol(dst, cetta_module_locator_kind_name(desc->locator_kind))));
        }
        if (!library_inventory_try_add_symbol_fact3(
                inventory, "module-provider-update-policy", provider_name,
                desc->update_policy ? desc->update_policy : "unknown")) {
            library_inventory_add_fallback_atom(
                inventory, dst,
                atom_expr3(dst, atom_symbol(dst, "module-provider-update-policy"),
                           atom_symbol(dst, provider_name),
                           atom_symbol(dst, desc->update_policy ? desc->update_policy : "unknown")));
        }
        if (!library_inventory_try_add_symbol_fact3(
                inventory, "module-provider-revision-policy", provider_name,
                cetta_remote_revision_policy_name(desc->revision_policy))) {
            library_inventory_add_fallback_atom(
                inventory, dst,
                atom_expr3(dst, atom_symbol(dst, "module-provider-revision-policy"),
                           atom_symbol(dst, provider_name),
                           atom_symbol(dst, cetta_remote_revision_policy_name(desc->revision_policy))));
        }
    }

    for (uint32_t i = 0; i < ctx->module_mount_len; i++) {
        const CettaModuleMount *mount = &ctx->module_mounts[i];
        if (!module_mount_visible(ctx, mount)) continue;
        if (!library_inventory_try_add_symbol_string_symbol_fact4(
                inventory, "module-mount", mount->namespace_name,
                mount->root_path,
                cetta_module_provider_name(mount->provider_kind))) {
            Atom *elems[4] = {
                atom_symbol(dst, "module-mount"),
                atom_symbol(dst, mount->namespace_name),
                atom_string(dst, mount->root_path),
                atom_symbol(dst, cetta_module_provider_name(mount->provider_kind))
            };
            library_inventory_add_fallback_atom(inventory, dst,
                                                atom_expr(dst, elems, 4));
        }
        if (!library_inventory_try_add_symbol_string_symbol_fact4(
                inventory, "module-mount-source", mount->namespace_name,
                mount->source_locator,
                cetta_module_locator_kind_name(mount->locator_kind))) {
            Atom *source_fact[4] = {
                atom_symbol(dst, "module-mount-source"),
                atom_symbol(dst, mount->namespace_name),
                atom_string(dst, mount->source_locator),
                atom_symbol(dst, cetta_module_locator_kind_name(mount->locator_kind))
            };
            library_inventory_add_fallback_atom(inventory, dst,
                                                atom_expr(dst, source_fact, 4));
        }
        if (!library_inventory_try_add_symbol_symbol_string_fact4(
                inventory, "module-mount-revision-policy",
                mount->namespace_name,
                cetta_remote_revision_policy_name(mount->revision_policy),
                mount->revision_value[0] ? mount->revision_value : "none")) {
            Atom *revision_fact[4] = {
                atom_symbol(dst, "module-mount-revision-policy"),
                atom_symbol(dst, mount->namespace_name),
                atom_symbol(dst, cetta_remote_revision_policy_name(mount->revision_policy)),
                atom_string(dst, mount->revision_value[0] ? mount->revision_value : "none")
            };
            library_inventory_add_fallback_atom(inventory, dst,
                                                atom_expr(dst, revision_fact, 4));
        }
    }

    for (uint32_t i = 0; i < ctx->loaded_module_len; i++) {
        const CettaLoadedModule *module = &ctx->loaded_modules[i];
        if (!loaded_module_visible(ctx, module)) continue;
        if (!library_inventory_try_add_string_string_symbol_fact4(
                inventory, "loaded-module", module->display_name,
                module->canonical_path,
                cetta_module_provider_name(module->provider_kind))) {
            Atom *module_fact[4] = {
                atom_symbol(dst, "loaded-module"),
                atom_string(dst, module->display_name),
                atom_string(dst, module->canonical_path),
                atom_symbol(dst, cetta_module_provider_name(module->provider_kind))
            };
            library_inventory_add_fallback_atom(inventory, dst,
                                                atom_expr(dst, module_fact, 4));
        }
        if (!library_inventory_try_add_string_symbol_symbol_fact4(
                inventory, "loaded-module-format", module->display_name,
                cetta_module_format_name(module->format.kind),
                cetta_foreign_backend_name(module->format.foreign_backend))) {
            Atom *format_fact[4] = {
                atom_symbol(dst, "loaded-module-format"),
                atom_string(dst, module->display_name),
                atom_symbol(dst, cetta_module_format_name(module->format.kind)),
                atom_symbol(dst, cetta_foreign_backend_name(module->format.foreign_backend))
            };
            library_inventory_add_fallback_atom(inventory, dst,
                                                atom_expr(dst, format_fact, 4));
        }
        if (!library_inventory_try_add_string_symbol_fact3(
                inventory, "loaded-module-storage", module->display_name,
                loaded_module_storage_name(module))) {
            Atom *storage_fact[3] = {
                atom_symbol(dst, "loaded-module-storage"),
                atom_string(dst, module->display_name),
                atom_symbol(dst, loaded_module_storage_name(module))
            };
            library_inventory_add_fallback_atom(inventory, dst,
                                                atom_expr(dst, storage_fact, 3));
        }
        if (module->space) {
            Atom *space_fact[4] = {
                atom_symbol(dst, "loaded-module-space"),
                atom_string(dst, module->display_name),
                atom_space(dst, module->space),
                atom_symbol(dst, cetta_module_provider_name(module->provider_kind))
            };
            /* atom_space is intentionally unstable and cannot enter the
               canonical store as a byte-backed term. */
            space_add(inventory, atom_expr(dst, space_fact, 4));
        }
    }

    return atom_space(dst, inventory);
}

bool cetta_library_include_module(CettaLibraryContext *ctx, const char *spec,
                                  Space *space, Arena *eval_arena,
                                  Arena *persistent_arena, Registry *registry,
                                  int fuel, Atom **error_out) {
    if (spec && (cetta_library_lookup(spec) || cetta_native_module_lookup(spec))) {
        return cetta_library_import(ctx, spec, space, eval_arena,
                                    persistent_arena, registry, fuel, error_out);
    }
    CettaModuleSpec parsed_spec;
    CettaImportPlan plan;
    if (!parse_module_spec(spec, &parsed_spec, eval_arena, error_out)) {
        return false;
    }
    if (!resolve_import_plan(ctx, &parsed_spec, logical_import_space(ctx, space), space,
                             false, &plan, eval_arena, error_out)) {
        return false;
    }
    return execute_import_plan(ctx, &plan, eval_arena, persistent_arena,
                               registry, fuel, error_out);
}

bool cetta_library_print_loaded_modules(CettaLibraryContext *ctx, FILE *out,
                                        Arena *eval_arena, Atom **error_out) {
    (void)eval_arena;
    (void)error_out;
    if (!ctx || !out) return false;
    fprintf(out, "top = 0\n");
    uint32_t visible_count = cetta_library_loaded_module_count(ctx);
    for (uint32_t i = 0; i < visible_count; i++) {
        const CettaLoadedModule *module = cetta_library_loaded_module_at(ctx, i);
        const char *branch = (i + 1 == visible_count) ? "└" : "├";
        fprintf(out, " %s─%s = %u\n", branch, module->display_name, i + 1);
    }
    fflush(out);
    return true;
}

bool cetta_library_import(CettaLibraryContext *ctx, const char *name,
                          Space *space, Arena *eval_arena,
                          Arena *persistent_arena, Registry *registry,
                          int fuel, Atom **error_out) {
    const CettaLibrarySpec *spec = cetta_library_lookup(name);
    const CettaNativeBuiltinModule *native_spec = spec ? NULL : cetta_native_module_lookup(name);
    CettaModuleSpec parsed_spec;
    CettaImportPlan plan;
    uint32_t import_bit;
    const char *import_name;

    if (!spec && !native_spec) {
        *error_out = atom_symbol(eval_arena, "unknown library");
        return false;
    }
    import_bit = spec ? spec->bit : native_spec->import_bit;
    import_name = spec ? spec->name : native_spec->name;
    if (ctx->active_mask & import_bit) return true;

    ctx->active_mask |= import_bit;
    memset(&parsed_spec, 0, sizeof(parsed_spec));
    parsed_spec.kind = CETTA_MODULE_SPEC_STDLIB;
    snprintf(parsed_spec.raw_spec, sizeof(parsed_spec.raw_spec), "%s", import_name);
    snprintf(parsed_spec.path_or_member, sizeof(parsed_spec.path_or_member), "%s", import_name);
    if (!resolve_import_plan(ctx, &parsed_spec, space, space, false,
                             &plan, eval_arena, error_out) ||
        !execute_import_plan(ctx, &plan, eval_arena, persistent_arena,
                             registry, fuel, error_out)) {
        ctx->active_mask &= ~import_bit;
        return false;
    }
    return true;
}

bool cetta_library_register_module(CettaLibraryContext *ctx, const char *path,
                                   Arena *eval_arena, Atom **error_out) {
    char candidate[PATH_MAX];
    char resolved[PATH_MAX];
    struct stat st;

    if (!cetta_module_policy_allows(&ctx->session.module_policy,
                                    CETTA_MODULE_PROVIDER_REGISTERED_ROOTS)) {
        *error_out = atom_symbol(eval_arena, "registered module roots disabled");
        return false;
    }

    if (!path || !*path) {
        *error_out = atom_symbol(eval_arena, "empty module path");
        return false;
    }

    int n;
    if (path[0] == '/') {
        n = snprintf(candidate, sizeof(candidate), "%s", path);
    } else {
        n = snprintf(candidate, sizeof(candidate), "%s/%s",
                     cetta_library_relative_base_dir(ctx), path);
    }
    if (!(n > 0 && (size_t)n < sizeof(candidate))) {
        *error_out = atom_symbol(eval_arena, "module path too long");
        return false;
    }

    if (!realpath(candidate, resolved) || stat(resolved, &st) != 0 || !S_ISDIR(st.st_mode)) {
        *error_out = atom_symbol(eval_arena, "module root not found");
        return false;
    }

    const char *base = strrchr(resolved, '/');
    const char *name = base ? base + 1 : resolved;
    return upsert_module_mount(ctx, name, resolved,
                               CETTA_MODULE_PROVIDER_REGISTERED_ROOT,
                               CETTA_MODULE_LOCATOR_FILESYSTEM_PATH,
                               resolved,
                               CETTA_REMOTE_REVISION_NONE,
                               "",
                               CETTA_PROFILE_MASK_ALL,
                               eval_arena, error_out);
}

bool cetta_library_register_git_module(CettaLibraryContext *ctx, const char *url,
                                       Arena *eval_arena, Atom **error_out) {
    char module_name[CETTA_MAX_MODULE_NAMESPACE];
    char cached_root[PATH_MAX];

    if (!cetta_module_policy_allows(&ctx->session.module_policy,
                                    CETTA_MODULE_PROVIDER_GIT)) {
        *error_out = atom_symbol(eval_arena, "git module provider disabled");
        return false;
    }
    if (!url || !*url) {
        *error_out = atom_symbol(eval_arena, "empty git module URL");
        return false;
    }
    if (!ensure_git_cached_repo(ctx, url, module_name, sizeof(module_name),
                                cached_root, sizeof(cached_root),
                                eval_arena, error_out)) {
        return false;
    }
    return upsert_module_mount(ctx, module_name, cached_root,
                               CETTA_MODULE_PROVIDER_GIT_REMOTE,
                               CETTA_MODULE_LOCATOR_GIT_URL,
                               url,
                               CETTA_REMOTE_REVISION_DEFAULT_BRANCH_ONLY,
                               "",
                               CETTA_PROFILE_MASK_ALL,
                               eval_arena, error_out);
}

bool cetta_library_import_module(CettaLibraryContext *ctx, const char *spec,
                                 Space *space, bool target_is_fresh,
                                 Arena *eval_arena,
                                 Arena *persistent_arena, Registry *registry,
                                 int fuel, Atom **error_out) {
    Space *logical_space = logical_import_space(ctx, space);
    CettaModuleSpec parsed_spec;
    CettaImportPlan plan;

    if (spec && (cetta_library_lookup(spec) || cetta_native_module_lookup(spec))) {
        if (target_is_fresh) {
            *error_out = atom_symbol(eval_arena,
                                     "builtin libraries can only import into existing spaces");
            return false;
        }
        return cetta_library_import(ctx, spec, space, eval_arena,
                                    persistent_arena, registry, fuel, error_out);
    }

    if (!parse_module_spec(spec, &parsed_spec, eval_arena, error_out)) {
        return false;
    }
    if (!resolve_import_plan(ctx, &parsed_spec, logical_space, space,
                             target_is_fresh, &plan, eval_arena, error_out)) {
        return false;
    }
    return execute_import_plan(ctx, &plan, eval_arena, persistent_arena,
                               registry, fuel, error_out);
}

Atom *cetta_library_dispatch_native(CettaLibraryContext *ctx, Space *space,
                                    Arena *a,
                                    Atom *head, Atom **args, uint32_t nargs) {
    if (!ctx || !head || head->kind != ATOM_SYMBOL) return NULL;
    if (ctx->active_mask & CETTA_LIBRARY_MORK) {
        Atom *result = cetta_library_dispatch_mork(ctx, a, head, args, nargs);
        if (result) return result;
    }
    {
        Atom *result = cetta_library_dispatch_mm2(ctx, a, head, args, nargs);
        if (result) return result;
    }
    if (ctx->active_mask & CETTA_LIBRARY_SYSTEM) {
        Atom *result = cetta_library_dispatch_system(ctx, a, head, args, nargs);
        if (result) return result;
    }
    if (ctx->active_mask & CETTA_LIBRARY_FS) {
        Atom *result = cetta_library_dispatch_fs(a, head, args, nargs);
        if (result) return result;
    }
    if (ctx->active_mask & CETTA_LIBRARY_STR) {
        Atom *result = cetta_library_dispatch_str(a, head, args, nargs);
        if (result) return result;
    }
    if (ctx->active_mask & CETTA_LIBRARY_SHELL) {
        Atom *result = cetta_library_dispatch_shell(a, head, args, nargs);
        if (result) return result;
    }
    if (ctx->active_mask & CETTA_LIBRARY_PROCESS) {
        Atom *result = cetta_library_dispatch_process(a, head, args, nargs);
        if (result) return result;
    }
    if (ctx->active_mask & CETTA_LIBRARY_JSON) {
        Atom *result = cetta_library_dispatch_json(a, head, args, nargs);
        if (result) return result;
    }
    if (ctx->active_mask & CETTA_LIBRARY_PATCH) {
        Atom *result = cetta_library_dispatch_patch(a, head, args, nargs);
        if (result) return result;
    }
    if (ctx->active_mask & CETTA_LIBRARY_GIT) {
        Atom *result = cetta_library_dispatch_git(a, head, args, nargs);
        if (result) return result;
    }
    {
        Atom *result = cetta_native_module_dispatch_active(ctx, space, a, head, args,
                                                           nargs, ctx->active_mask);
        if (result) return result;
    }
    if (ctx->foreign_runtime) {
        Atom *result = cetta_foreign_dispatch_native(ctx->foreign_runtime,
                                                     space, a, head, args, nargs);
        if (result) return result;
    }
    return NULL;
}
