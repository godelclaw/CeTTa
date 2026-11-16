/* Resumable validation owns one captured file. Every parser step is bounded;
 * suspension is distinct from rejection or completed coverage. Strings and
 * number payloads are never materialized during validation. */
typedef struct {
    JsonFile input;
    struct stat captured;
    unsigned char stack[4096];
    size_t depth, literal_at, digits;
    const char *literal;
    unsigned token, number_state, hex_left;
    bool floating, valid;
    int error;
} HostJson;
static const char *json_kind = "host-json";
static void release_json(void *resource) {
    HostJson *cursor = resource; if (cursor->input.file) fclose(cursor->input.file); free(cursor);
}
static bool json_current(HostJson *cursor) {
    struct stat now;
    if (fstat(fileno(cursor->input.file), &now)) { cursor->error = errno; return false; }
    if (now.st_size != cursor->captured.st_size || now.st_mtim.tv_sec != cursor->captured.st_mtim.tv_sec ||
        now.st_mtim.tv_nsec != cursor->captured.st_mtim.tv_nsec || now.st_ctim.tv_sec != cursor->captured.st_ctim.tv_sec ||
        now.st_ctim.tv_nsec != cursor->captured.st_ctim.tv_nsec) { cursor->error = ESTALE; return false; }
    return true;
}
static Atom *open_json_cursor(CettaLibraryContext *ctx, Arena *a, const char *path) {
    FILE *file = path ? fopen(path, "rb") : NULL;
    if (!file) return failure(a, "json-open", path ? errno : EINVAL);
    HostJson *cursor = calloc(1, sizeof(*cursor));
    if (!cursor) { fclose(file); return failure(a, "json-open", ENOMEM); }
    cursor->input.file = file;
    if (fstat(fileno(file), &cursor->captured) || !S_ISREG(cursor->captured.st_mode)) {
        int code = errno ? errno : EINVAL; release_json(cursor); return failure(a, "json-open", code);
    }
    initialize_json_file(&cursor->input, file); json_next(&cursor->input); cursor->depth = 1;
    uint64_t id;
    if (!cetta_native_handle_alloc(ctx, json_kind, cursor, release_json, &id)) { release_json(cursor); return failure(a, "json-open", ENOMEM); }
    return cetta_native_handle_owned_atom(ctx, a, json_kind, id);
}
static bool cursor_value(HostJson *p) {
    JsonFile *j = &p->input; int c = j->current;
    if (c == '[' || c == '{') {
        if (p->depth == sizeof(p->stack)) { p->error = EOVERFLOW; return false; }
        p->stack[p->depth++] = c == '[' ? 2 : 5; json_next(j); return true;
    }
    if (c == '"') { p->token = 1; json_next(j); return true; }
    if (c == 't' || c == 'f' || c == 'n' || c == 'N' || c == 'I') {
        p->literal = c == 't' ? "true" : c == 'f' ? "false" : c == 'n' ? "null" : c == 'N' ? "NaN" : "Infinity";
        p->literal_at = 0; p->token = 4; return true;
    }
    if (c != '-' && (c < '0' || c > '9')) return false;
    p->token = 5; p->number_state = 0; p->digits = 0; p->floating = false; return true;
}
static bool cursor_number(HostJson *p) {
    JsonFile *j = &p->input; int c = j->current; bool digit = c >= '0' && c <= '9';
    switch (p->number_state) {
    case 0:
        if (c == '-') { p->number_state = 1; json_next(j); return true; }
        p->number_state = 1; return true;
    case 1:
        if (c == 'I') { p->literal = "Infinity"; p->literal_at = 0; p->token = 4; return true; }
        if (!digit) return false;
        p->number_state = c == '0' ? 2 : 3; p->digits = 1; json_next(j); return true;
    case 2: case 3:
        if (digit && p->number_state == 3) { ++p->digits; json_next(j); return true; }
        if (c == '.') { p->number_state = 4; p->floating = true; json_next(j); return true; }
        if (c == 'e' || c == 'E') { p->number_state = 6; p->floating = true; json_next(j); return true; }
        break;
    case 4:
        if (!digit) return false;
        p->number_state = 5; json_next(j); return true;
    case 5:
        if (digit) { json_next(j); return true; }
        if (c == 'e' || c == 'E') { p->number_state = 6; json_next(j); return true; }
        break;
    case 6:
        if (c == '+' || c == '-') { p->number_state = 7; json_next(j); return true; }
        p->number_state = 7; return true;
    case 7:
        if (!digit) return false;
        p->number_state = 8; json_next(j); return true;
    case 8: if (digit) { json_next(j); return true; } break;
    default: return false;
    }
    if (!p->floating && p->digits > 4300) { p->error = ERANGE; return false; }
    p->token = 0; return true;
}
static Atom *step_json_cursor(Arena *a, HostJson *p, size_t budget) {
    JsonFile *j = &p->input;
    if (p->valid && !json_current(p)) p->valid = false;
    while (budget-- && !p->valid && !p->error && !j->error) {
        int c = j->current; bool ok = true;
        if (p->token == 1) {
            if (c == '"') { p->token = 0; json_next(j); }
            else if (c == '\\') { p->token = 2; json_next(j); }
            else if (c < 32) ok = false;
            else json_next(j);
        } else if (p->token == 2) {
            if (c == 'u') { p->token = 3; p->hex_left = 4; json_next(j); }
            else if (c > 0 && c < 128 && strchr("\"\\/bfnrt", c)) { p->token = 1; json_next(j); }
            else ok = false;
        } else if (p->token == 3) {
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))) ok = false;
            else { if (!--p->hex_left) p->token = 1; json_next(j); }
        } else if (p->token == 4) {
            if (c != p->literal[p->literal_at]) ok = false;
            else { json_next(j); if (!p->literal[++p->literal_at]) p->token = 0; }
        } else if (p->token == 5) ok = cursor_number(p);
        else if (c == ' ' || c == '\t' || c == '\r' || c == '\n') json_next(j);
        else {
            unsigned char *state = &p->stack[p->depth - 1];
            switch (*state) {
            case 0: *state = 1; ok = cursor_value(p); break;
            case 1: if (c < 0) p->valid = json_current(p); else ok = false; break;
            case 2: if (c == ']') { --p->depth; json_next(j); break; } /* fall through */
            case 4: *state = 3; ok = cursor_value(p); break;
            case 3:
                if (c == ']') { --p->depth; json_next(j); }
                else if (c == ',') { *state = 4; json_next(j); }
                else ok = false;
                break;
            case 5: if (c == '}') { --p->depth; json_next(j); break; } /* fall through */
            case 6: if (c != '"') ok = false; else { *state = 7; p->token = 1; json_next(j); } break;
            case 7: if (c != ':') ok = false; else { *state = 8; json_next(j); } break;
            case 8: *state = 9; ok = cursor_value(p); break;
            case 9:
                if (c == '}') { --p->depth; json_next(j); }
                else if (c == ',') { *state = 6; json_next(j); }
                else ok = false;
                break;
            default: ok = false;
            }
        }
        if (!ok && !p->error) p->error = EBADMSG;
    }
    if (j->error && !p->error) p->error = j->error;
    if (p->error) return failure(a, "json-step", p->error);
    return term(a, p->valid ? "HostJsonValid" : "HostJsonMore", (Atom *[]){atom_int(a, (int64_t)j->bytes)}, 1u);
}
static Atom *text_json_cursor(Arena *a, HostJson *p, size_t maximum) {
    if (!p->valid || !json_current(p)) return failure(a, "json-text", p->error ? p->error : EBUSY);
    if ((uint64_t)p->captured.st_size > maximum) return failure(a, "json-text", EFBIG);
    if (fseek(p->input.file, 0, SEEK_SET)) return failure(a, "json-text", errno);
    JsonFile view; initialize_json_file(&view, p->input.file);
    unsigned char *out = arena_alloc(a, maximum * 4u + 4u); size_t written = 0;
    for (int c = json_character(&view); c >= 0; c = json_character(&view)) written += cetta_utf8_encode((uint32_t)c, out + written);
    if (view.error || !json_current(p)) return failure(a, "json-text", view.error ? view.error : p->error);
    return term(a, "HostJsonText", (Atom *[]){atom_string_n(a, (const char *)out, written)}, 1u);
}
static Atom *json_file(CettaLibraryContext *ctx, Arena *a, const char *path) {
    Atom *owner = open_json_cursor(ctx, a, path); CettaNativeHandleUse use = {0};
    if (!cetta_native_handle_acquire_owned(ctx, json_kind, owner, CETTA_NATIVE_HANDLE_USE_EXCLUSIVE, &use)) return owner;
    HostJson *p = cetta_native_handle_use_resource(&use); Atom *answer;
    do {
        answer = step_json_cursor(a, p, 1048576);
        if (eval_native_interrupted()) { answer = failure(a, "json-file", EINTR); break; }
    } while (!p->valid && !p->error);
    (void)cetta_native_handle_use_release(&use);
    uint64_t id; if (cetta_native_handle_arg(owner, json_kind, &id)) (void)cetta_native_handle_close(ctx, json_kind, id);
    return answer;
}
