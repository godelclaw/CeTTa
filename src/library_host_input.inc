/* VT input is a byte protocol. Events name keys; applications choose their
 * bindings. A split sequence/scalar stays buffered. Paste text is never
 * decoded as key strokes. */
typedef struct { const char *bytes, *name; } InputSequence;
static const InputSequence input_sequences[] = {
    {"\033[200~", "paste-start"}, {"\033[A", "up"}, {"\033[B", "down"},
    {"\033[C", "right"}, {"\033[D", "left"}, {"\033[H", "home"}, {"\033[F", "line-end"},
    {"\033OH", "home"}, {"\033OF", "line-end"}, {"\033[1~", "home"}, {"\033[4~", "line-end"},
    {"\033[3~", "delete"}, {"\033[5~", "page-up"}, {"\033[6~", "page-down"},
    {"\033[1;5D", "word-left"}, {"\033[1;5C", "word-right"},
    {"\033b", "word-left"}, {"\033f", "word-right"}, {"\033\r", "alt-enter"}, {"\033\n", "alt-enter"}
};
static void input_drop(HostBuffer *b, size_t bytes) {
    size_t length = buffer_length(b);
    if (length > bytes) memmove(b->bytes, b->bytes + bytes, length - bytes);
    b->first = length - bytes; b->last = b->capacity; b->scan = 0;
}
static Atom *input_event(Arena *a, HostBuffer *b, bool flush_escape) {
    if (b->text) return failure(a, "input-event", EINVAL);
    size_t length = buffer_length(b); buffer_seek(b, length);
    if (!length) return atom_symbol(a, "HostPending");
    if (b->paste && length >= 6 && !memcmp(b->bytes, "\033[201~", 6)) {
        b->paste = false; input_drop(b, 6);
        return term(a, "HostInput", (Atom *[]){atom_string(a, "paste-end"), atom_string(a, "")}, 2u);
    }
    if (!b->paste && b->bytes[0] == 27) {
        for (size_t i = 0; i < sizeof(input_sequences) / sizeof(*input_sequences); ++i) {
            size_t bytes = strlen(input_sequences[i].bytes), compare = length < bytes ? length : bytes;
            if (!memcmp(b->bytes, input_sequences[i].bytes, compare)) {
                if (length < bytes && !flush_escape) return atom_symbol(a, "HostPending");
                if (length >= bytes) {
                    if (!strcmp(input_sequences[i].name, "paste-start")) b->paste = true;
                    input_drop(b, bytes);
                    return term(a, "HostInput", (Atom *[]){atom_string(a, input_sequences[i].name), atom_string(a, "")}, 2u);
                }
            }
        }
        if (length == 1 && !flush_escape) return atom_symbol(a, "HostPending");
        size_t take = 1;
        if (length > 1 && (b->bytes[1] == '[' || b->bytes[1] == 'O')) {
            take = 2;
            while (take < length && (b->bytes[take] < 0x40 || b->bytes[take] > 0x7e)) ++take;
            if (take == length && !flush_escape) return atom_symbol(a, "HostPending");
            if (take < length) ++take;
        }
        input_drop(b, take);
        return term(a, "HostInput", (Atom *[]){atom_string(a, take == 1 ? "escape" : "unknown"), atom_string(a, "")}, 2u);
    }
    if (!b->paste && (b->bytes[0] < 32 || b->bytes[0] == 127)) {
        unsigned char c = b->bytes[0]; char key[16];
        const char *name = c == 13 ? "enter" : c == 10 ? "lf" : c == 9 ? "tab" : c == 127 ? "backspace" : NULL;
        if (!name) { snprintf(key, sizeof(key), "ctrl-%c", (char)('a' + c - 1)); name = key; }
        input_drop(b, 1);
        return term(a, "HostInput", (Atom *[]){atom_string(a, name), atom_string(a, "")}, 2u);
    }
    size_t maximum = length;
    if (b->paste) {
        unsigned char *end = memmem(b->bytes, length, "\033[201~", 6);
        if (end) maximum = (size_t)(end - b->bytes);
        else {
            size_t suffix = length < 5 ? length : 5;
            for (; suffix; --suffix) if (!memcmp(b->bytes + length - suffix, "\033[201~", suffix)) break;
            maximum -= suffix;
        }
    } else for (size_t i = 0; i < maximum; ++i)
        if (b->bytes[i] < 32 || b->bytes[i] == 127) { maximum = i; break; }
    unsigned char *out = arena_alloc(a, maximum * 3u + 1u); size_t written = 0, at = 0;
    while (at < maximum) {
        uint32_t cp, width;
        if (!cetta_utf8_decode_one(b->bytes, maximum, at, &cp, &width)) {
            unsigned char c = b->bytes[at]; size_t expected = c >= 0xf0 && c <= 0xf4 ? 4 : c >= 0xe0 && c <= 0xef ? 3 : c >= 0xc2 && c <= 0xdf ? 2 : 1;
            bool prefix = expected > maximum - at;
            for (size_t i = 1; prefix && i < maximum - at; ++i) {
                unsigned char next = b->bytes[at + i];
                if ((next & 0xc0u) != 0x80u || (i == 1 &&
                    ((c == 0xe0 && next < 0xa0) || (c == 0xed && next > 0x9f) ||
                     (c == 0xf0 && next < 0x90) || (c == 0xf4 && next > 0x8f)))) prefix = false;
            }
            if (prefix && maximum == length) break;
            memcpy(out + written, "�", 3); written += 3; ++at;
        } else { memcpy(out + written, b->bytes + at, width); written += width; at += width; }
    }
    if (!at) return atom_symbol(a, "HostPending");
    input_drop(b, at);
    return term(a, "HostInput", (Atom *[]){atom_string(a, b->paste ? "paste" : "text"), atom_string_n(a, (const char *)out, written)}, 2u);
}
