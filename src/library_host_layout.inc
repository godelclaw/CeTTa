/* Terminal protocol helpers for the owned host-I/O library:
 * - Cursor Position Report (CPR) request and parser (CSI row;col R)
 * - Synchronized output brackets (DEC mode 2026: CSI ?2026h .. CSI ?2026l)
 * - Sanitized OSC 8 hyperlinks (C0/DEL/C1 stripped from URLs)
 * - RFC 4648 base64 OSC 52 clipboard copy
 * - Atomic scrollback commit (terminal:commit): sync-bracketed erase of live
 *   region, autowrap-on (?7h) logical line emission, and live-region redraw. */

static Atom *terminal_cpr_request(Arena *a) {
    return atom_string_n(a, "\033[6n", 4u);
}

static Atom *terminal_cpr_parse(Arena *a, const char *bytes, size_t length) {
    const unsigned char *p = (const unsigned char *)bytes;
    size_t n = length;
    if (n >= 6u && p[0] == 27u && p[1] == '[' && p[n - 1u] == 'R') {
        p += 2u; n -= 3u;
    }
    unsigned row = 0, col = 0;
    if (!parse_cpr_params(p, n, &row, &col)) return failure(a, "cpr-parse", EINVAL);
    return term(a, "HostCursor", (Atom *[]){atom_int(a, (int64_t)row), atom_int(a, (int64_t)col)}, 2u);
}

static Atom *terminal_sync(Arena *a, const char *bytes, size_t length) {
    static const char open_sync[] = "\033[?2026h";
    static const char close_sync[] = "\033[?2026l";
    if (length > (size_t)67108864u) return failure(a, "sync", EFBIG);
    size_t total = sizeof(open_sync) - 1u + length + sizeof(close_sync) - 1u;
    char *out = arena_alloc(a, total ? total : 1u);
    size_t pos = 0;
    memcpy(out + pos, open_sync, sizeof(open_sync) - 1u); pos += sizeof(open_sync) - 1u;
    if (length) { memcpy(out + pos, bytes, length); pos += length; }
    memcpy(out + pos, close_sync, sizeof(close_sync) - 1u); pos += sizeof(close_sync) - 1u;
    return atom_string_n(a, out, pos);
}

/* Strip C0 (< 0x20), DEL (0x7F), C1 (U+0080..U+009F) and invalid UTF-8 from URL
 * so OSC escape injection (BEL, ESC, ST) is impossible by construction. */
static size_t sanitize_osc_url(const char *url, size_t url_len, char *dst) {
    size_t written = 0;
    for (size_t at = 0; at < url_len;) {
        uint32_t cp = 0, width = 0;
        if (!cetta_utf8_decode_one((const uint8_t *)url, url_len, at, &cp, &width)) {
            ++at;
            continue;
        }
        if (cp >= 0x20u && cp != 0x7Fu && !(cp >= 0x80u && cp <= 0x9Fu)) {
            if (dst) memcpy(dst + written, url + at, width);
            written += width;
        }
        at += width;
    }
    return written;
}

static Atom *terminal_hyperlink(Arena *a, const char *url, size_t url_len,
                                const char *label, size_t label_len) {
    if (url_len > (size_t)65536u || label_len > (size_t)16777216u) return failure(a, "hyperlink", EFBIG);
    size_t clean_len = sanitize_osc_url(url, url_len, NULL);
    if (!clean_len) return atom_string_n(a, label, label_len);
    static const char osc_open[] = "\033]8;;";
    static const char osc_st[] = "\033\\";
    static const char osc_close[] = "\033]8;;\033\\";
    size_t total = (sizeof(osc_open) - 1u) + clean_len + (sizeof(osc_st) - 1u) +
                   label_len + (sizeof(osc_close) - 1u);
    char *out = arena_alloc(a, total ? total : 1u);
    size_t pos = 0;
    memcpy(out + pos, osc_open, sizeof(osc_open) - 1u); pos += sizeof(osc_open) - 1u;
    pos += sanitize_osc_url(url, url_len, out + pos);
    memcpy(out + pos, osc_st, sizeof(osc_st) - 1u); pos += sizeof(osc_st) - 1u;
    if (label_len) { memcpy(out + pos, label, label_len); pos += label_len; }
    memcpy(out + pos, osc_close, sizeof(osc_close) - 1u); pos += sizeof(osc_close) - 1u;
    return atom_string_n(a, out, pos);
}

static Atom *terminal_clipboard(Arena *a, const char *bytes, size_t length) {
    static const char b64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    static const char prefix[] = "\033]52;c;";
    static const char suffix[] = "\033\\";
    if (length > (size_t)1048576u) return failure(a, "clipboard", EFBIG);
    size_t encoded_len = ((length + 2u) / 3u) * 4u;
    size_t total = (sizeof(prefix) - 1u) + encoded_len + (sizeof(suffix) - 1u);
    char *out = arena_alloc(a, total ? total : 1u);
    size_t pos = 0;
    memcpy(out + pos, prefix, sizeof(prefix) - 1u); pos += sizeof(prefix) - 1u;
    const unsigned char *src = (const unsigned char *)bytes;
    size_t i = 0;
    while (i + 3u <= length) {
        uint32_t v = ((uint32_t)src[i] << 16) | ((uint32_t)src[i + 1u] << 8) | (uint32_t)src[i + 2u];
        out[pos++] = b64[(v >> 18) & 63u];
        out[pos++] = b64[(v >> 12) & 63u];
        out[pos++] = b64[(v >> 6) & 63u];
        out[pos++] = b64[v & 63u];
        i += 3u;
    }
    size_t rem = length - i;
    if (rem == 1u) {
        uint32_t v = (uint32_t)src[i] << 16;
        out[pos++] = b64[(v >> 18) & 63u];
        out[pos++] = b64[(v >> 12) & 63u];
        out[pos++] = '=';
        out[pos++] = '=';
    } else if (rem == 2u) {
        uint32_t v = ((uint32_t)src[i] << 16) | ((uint32_t)src[i + 1u] << 8);
        out[pos++] = b64[(v >> 18) & 63u];
        out[pos++] = b64[(v >> 12) & 63u];
        out[pos++] = b64[(v >> 6) & 63u];
        out[pos++] = '=';
    }
    memcpy(out + pos, suffix, sizeof(suffix) - 1u); pos += sizeof(suffix) - 1u;
    return atom_string_n(a, out, pos);
}

static Atom *terminal_commit(Arena *a, int64_t cursor_up, Atom *lines_atom,
                             const char *redraw, size_t redraw_len) {
    if (cursor_up < 0 || cursor_up > 65535 || !lines_atom || lines_atom->kind != ATOM_EXPR)
        return failure(a, "terminal-commit", EINVAL);
    /* Erase live_top with EL 2 (\033[2K), step to col 1 (\033[1C) before ED 0
     * (\033[J) so tmux/xterm never trigger their cx==0 && cy==0 full-screen
     * scrollback-push heuristic on a fresh pane, return to col 0 (\r), and
     * force autowrap ON (\033[?7h) before emitting logical scrollback lines. */
    char header[96];
    int hlen = cursor_up > 0
        ? snprintf(header, sizeof(header), "\033[?2026h\033[?25l\r\033[%lldA\033[2K\033[1C\033[J\r\033[?7h", (long long)cursor_up)
        : snprintf(header, sizeof(header), "\033[?2026h\033[?25l\r\033[2K\033[1C\033[J\r\033[?7h");
    if (hlen <= 0 || (size_t)hlen >= sizeof(header)) return failure(a, "terminal-commit", EINVAL);
    static const char trailer[] = "\033[?25h\033[?2026l";
    size_t total = (size_t)hlen + redraw_len + (sizeof(trailer) - 1u);
    if (redraw_len > (size_t)67108864u) return failure(a, "terminal-commit", EFBIG);
    for (uint32_t i = 0; i < lines_atom->expr.len; ++i) {
        const char *lb; size_t ll;
        if (!string_bytes(lines_atom->expr.elems[i], &lb, &ll))
            return failure(a, "terminal-commit", EINVAL);
        if (ll > (size_t)67108864u || total > (size_t)67108864u - ll - 2u)
            return failure(a, "terminal-commit", EFBIG);
        total += ll + 2u;
    }
    char *out = arena_alloc(a, total ? total : 1u);
    size_t pos = 0;
    memcpy(out + pos, header, (size_t)hlen); pos += (size_t)hlen;
    for (uint32_t i = 0; i < lines_atom->expr.len; ++i) {
        const char *lb = NULL; size_t ll = 0;
        if (string_bytes(lines_atom->expr.elems[i], &lb, &ll) && ll) {
            memcpy(out + pos, lb, ll); pos += ll;
        }
        out[pos++] = '\r'; out[pos++] = '\n';
    }
    if (redraw_len) { memcpy(out + pos, redraw, redraw_len); pos += redraw_len; }
    memcpy(out + pos, trailer, sizeof(trailer) - 1u); pos += sizeof(trailer) - 1u;
    return atom_string_n(a, out, pos);
}
