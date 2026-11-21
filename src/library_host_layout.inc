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

/* Advance past an arbitrary CSI (after ESC [ or U+009B). */
static size_t skip_csi_body(const char *s, size_t len, size_t at) {
    while (at < len) {
        unsigned char c = (unsigned char)s[at++];
        if (c >= 0x40u && c <= 0x7Eu) break;
    }
    return at;
}

/* Advance past an arbitrary OSC/DCS/SOS/PM/APC string (after introducer)
 * terminated by BEL (0x07), ST (ESC \), C1 ST (U+009C), or end of input. */
static size_t skip_string_seq_body(const char *s, size_t len, size_t at) {
    while (at < len) {
        unsigned char c = (unsigned char)s[at];
        if (c == 0x07u) return at + 1u;
        if (c == 0x1Bu && at + 1u < len && s[at + 1u] == '\\') return at + 2u;
        if (c == 0xC2u && at + 1u < len && (unsigned char)s[at + 1u] == 0x9Cu) return at + 2u;
        ++at;
    }
    return at;
}

/* Sanitize a plain inline terminal label (hyperlink label / styled span text):
 * strips full CSI/OSC/DCS/SOS/PM/APC escape sequences and any remaining C0
 * (< 0x20, including ESC and BEL), DEL (0x7F), C1 (U+0080..U+009F), and
 * invalid UTF-8 bytes so neither escape sequences nor raw ESC/BEL survive. */
static size_t sanitize_plain_terminal_text(const char *src, size_t len, char *dst, bool keep_tab) {
    size_t written = 0;
    for (size_t at = 0; at < len;) {
        unsigned char b = (unsigned char)src[at];
        if (b == 0x1Bu) {
            if (at + 1u < len) {
                unsigned char nxt = (unsigned char)src[at + 1u];
                if (nxt == '[') { at = skip_csi_body(src, len, at + 2u); continue; }
                if (nxt == ']' || nxt == 'P' || nxt == 'X' || nxt == '^' || nxt == '_') {
                    at = skip_string_seq_body(src, len, at + 2u);
                    continue;
                }
            }
            ++at;
            continue;
        }
        uint32_t cp = 0, width = 0;
        if (!cetta_utf8_decode_one((const uint8_t *)src, len, at, &cp, &width)) {
            ++at;
            continue;
        }
        if (cp == 0x9Bu) { at = skip_csi_body(src, len, at + width); continue; }
        if (cp == 0x90u || cp == 0x98u || cp == 0x9Du || cp == 0x9Eu || cp == 0x9Fu) {
            at = skip_string_seq_body(src, len, at + width);
            continue;
        }
        if ((keep_tab && cp == '\t') ||
            (cp >= 0x20u && cp != 0x7Fu && !(cp >= 0x80u && cp <= 0x9Fu))) {
            if (dst) memcpy(dst + written, src + at, width);
            written += width;
        }
        at += width;
    }
    return written;
}

/* Validate a strict SGR sequence at src[at..len): ESC '[' [0-9;:]* 'm'. */
static bool match_strict_sgr(const char *src, size_t len, size_t at, size_t *out_end) {
    if (at + 2u >= len || src[at] != '\033' || src[at + 1u] != '[') return false;
    size_t p = at + 2u;
    while (p < len) {
        unsigned char c = (unsigned char)src[p];
        if ((c >= '0' && c <= '9') || c == ';' || c == ':') { ++p; continue; }
        if (c == 'm') { *out_end = p + 1u; return true; }
        return false;
    }
    return false;
}

/* Validate a strict ST-terminated OSC 8 sequence at src[at..len):
 *   ESC ']' '8' ';' <clean params> ';' <clean url> ESC '\'
 * Rejects BEL termination and any embedded C0/DEL/C1/invalid UTF-8.
 * Sets *out_has_url = true when opening a link (non-empty URL), false on close. */
static bool match_strict_osc8(const char *src, size_t len, size_t at,
                              size_t *out_end, bool *out_has_url) {
    if (at + 6u > len || src[at] != '\033' || src[at + 1u] != ']' ||
        src[at + 2u] != '8' || src[at + 3u] != ';') return false;
    size_t p = at + 4u;
    bool seen_second_semi = false;
    size_t url_start = 0;
    while (p < len) {
        unsigned char b = (unsigned char)src[p];
        if (b == 0x1Bu) {
            if (seen_second_semi && p + 1u < len && src[p + 1u] == '\\') {
                *out_end = p + 2u;
                *out_has_url = (p > url_start);
                return true;
            }
            return false;
        }
        if (b == 0x07u) return false;
        uint32_t cp = 0, width = 0;
        if (!cetta_utf8_decode_one((const uint8_t *)src, len, p, &cp, &width)) return false;
        if (cp < 0x20u || cp == 0x7Fu || (cp >= 0x80u && cp <= 0x9Fu)) return false;
        if (!seen_second_semi && cp == ';') {
            seen_second_semi = true;
            url_start = p + 1u;
        }
        p += width;
    }
    return false;
}

/* Sanitize a logical scrollback line for terminal:commit:
 * - Preserves printable UTF-8, '\t', strict SGR (CSI [0-9;:]* m), and strict
 *   ST-terminated OSC 8 hyperlinks (ESC ] 8 ; params ; url ESC \).
 * - Strips BEL (0x07), non-SGR CSI (e.g. ?2026l, ?7l, 2J, cursor moves),
 *   non-OSC-8 or BEL-terminated OSC (e.g. OSC 52), DCS/SOS/PM/APC, bare ESC,
 *   CR/LF/other C0, DEL, C1, and invalid UTF-8.
 * - Auto-closes any OSC 8 hyperlink left open at end of line. */
static size_t sanitize_commit_line(const char *src, size_t len, char *dst) {
    size_t written = 0;
    bool osc8_open = false;
    for (size_t at = 0; at < len;) {
        unsigned char b = (unsigned char)src[at];
        if (b == 0x1Bu) {
            size_t seq_end = 0;
            bool opens_link = false;
            if (match_strict_sgr(src, len, at, &seq_end)) {
                if (dst) memcpy(dst + written, src + at, seq_end - at);
                written += seq_end - at;
                at = seq_end;
                continue;
            }
            if (match_strict_osc8(src, len, at, &seq_end, &opens_link)) {
                if (dst) memcpy(dst + written, src + at, seq_end - at);
                written += seq_end - at;
                osc8_open = opens_link;
                at = seq_end;
                continue;
            }
            if (at + 1u < len) {
                unsigned char nxt = (unsigned char)src[at + 1u];
                if (nxt == '[') { at = skip_csi_body(src, len, at + 2u); continue; }
                if (nxt == ']' || nxt == 'P' || nxt == 'X' || nxt == '^' || nxt == '_') {
                    at = skip_string_seq_body(src, len, at + 2u);
                    continue;
                }
            }
            ++at;
            continue;
        }
        uint32_t cp = 0, width = 0;
        if (!cetta_utf8_decode_one((const uint8_t *)src, len, at, &cp, &width)) {
            ++at;
            continue;
        }
        if (cp == 0x9Bu) { at = skip_csi_body(src, len, at + width); continue; }
        if (cp == 0x90u || cp == 0x98u || cp == 0x9Du || cp == 0x9Eu || cp == 0x9Fu) {
            at = skip_string_seq_body(src, len, at + width);
            continue;
        }
        if (cp == '\t' || (cp >= 0x20u && cp != 0x7Fu && !(cp >= 0x80u && cp <= 0x9Fu))) {
            if (dst) memcpy(dst + written, src + at, width);
            written += width;
        }
        at += width;
    }
    if (osc8_open) {
        static const char osc8_close[] = "\033]8;;\033\\";
        if (dst) memcpy(dst + written, osc8_close, sizeof(osc8_close) - 1u);
        written += sizeof(osc8_close) - 1u;
    }
    return written;
}

static Atom *terminal_hyperlink(Arena *a, const char *url, size_t url_len,
                                const char *label, size_t label_len) {
    if (url_len > (size_t)65536u || label_len > (size_t)16777216u) return failure(a, "hyperlink", EFBIG);
    size_t clean_url_len = sanitize_osc_url(url, url_len, NULL);
    size_t clean_label_len = sanitize_plain_terminal_text(label, label_len, NULL, false);
    if (!clean_url_len) {
        char *plain = arena_alloc(a, clean_label_len ? clean_label_len : 1u);
        if (clean_label_len) (void)sanitize_plain_terminal_text(label, label_len, plain, false);
        return atom_string_n(a, plain, clean_label_len);
    }
    static const char osc_open[] = "\033]8;;";
    static const char osc_st[] = "\033\\";
    static const char osc_close[] = "\033]8;;\033\\";
    size_t total = (sizeof(osc_open) - 1u) + clean_url_len + (sizeof(osc_st) - 1u) +
                   clean_label_len + (sizeof(osc_close) - 1u);
    char *out = arena_alloc(a, total ? total : 1u);
    size_t pos = 0;
    memcpy(out + pos, osc_open, sizeof(osc_open) - 1u); pos += sizeof(osc_open) - 1u;
    pos += sanitize_osc_url(url, url_len, out + pos);
    memcpy(out + pos, osc_st, sizeof(osc_st) - 1u); pos += sizeof(osc_st) - 1u;
    if (clean_label_len) pos += sanitize_plain_terminal_text(label, label_len, out + pos, false);
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
        if (ll > (size_t)67108864u)
            return failure(a, "terminal-commit", EFBIG);
        size_t clean_ll = sanitize_commit_line(lb, ll, NULL);
        if (clean_ll > (size_t)67108864u || total > (size_t)67108864u - clean_ll - 2u)
            return failure(a, "terminal-commit", EFBIG);
        total += clean_ll + 2u;
    }
    char *out = arena_alloc(a, total ? total : 1u);
    size_t pos = 0;
    memcpy(out + pos, header, (size_t)hlen); pos += (size_t)hlen;
    for (uint32_t i = 0; i < lines_atom->expr.len; ++i) {
        const char *lb = NULL; size_t ll = 0;
        if (string_bytes(lines_atom->expr.elems[i], &lb, &ll) && ll) {
            pos += sanitize_commit_line(lb, ll, out + pos);
        }
        out[pos++] = '\r'; out[pos++] = '\n';
    }
    if (redraw_len) { memcpy(out + pos, redraw, redraw_len); pos += redraw_len; }
    memcpy(out + pos, trailer, sizeof(trailer) - 1u); pos += sizeof(trailer) - 1u;
    return atom_string_n(a, out, pos);
}

/* ---- Styled text wrapping (UAX #29/#11 grapheme-cluster aware) ---- */

typedef struct {
    Atom **items;
    size_t len, cap;
    bool oom;
} LayoutVec;

static void layout_vec_push(LayoutVec *v, Atom *item) {
    if (v->oom || !item) { v->oom = true; return; }
    if (v->len == v->cap) {
        size_t next = v->cap ? v->cap * 2u : 16u;
        Atom **grown = realloc(v->items, next * sizeof(*grown));
        if (!grown) { v->oom = true; return; }
        v->items = grown; v->cap = next;
    }
    v->items[v->len++] = item;
}

static Atom *layout_make_row(Arena *a, const char *prefix, size_t prefix_len,
                             const char *body, size_t body_len,
                             const char *suffix, size_t suffix_len,
                             size_t src_start, size_t src_end, size_t cells_count) {
    size_t total = prefix_len + body_len + suffix_len;
    char *out = arena_alloc(a, total ? total : 1u);
    size_t pos = 0;
    if (prefix_len) { memcpy(out + pos, prefix, prefix_len); pos += prefix_len; }
    if (body_len) { memcpy(out + pos, body, body_len); pos += body_len; }
    if (suffix_len) { memcpy(out + pos, suffix, suffix_len); pos += suffix_len; }
    return term(a, "TextRow", (Atom *[]){
        atom_string_n(a, out, pos),
        atom_int(a, (int64_t)src_start),
        atom_int(a, (int64_t)src_end),
        atom_int(a, (int64_t)cells_count)
    }, 4u);
}

static bool cluster_is_ascii_ws(const char *s, size_t start, size_t end) {
    return (end == start + 1u) && (s[start] == ' ' || s[start] == '\t');
}

static Atom *text_wrap(Arena *a, const char *src, size_t src_len, size_t width,
                       const char *indent, size_t indent_len,
                       const char *hanging, size_t hanging_len,
                       const char *mode,
                       const char *ellipsis, size_t ellipsis_len) {
    int mode_id = !strcmp(mode, "word") ? 0
                : !strcmp(mode, "fold") ? 1
                : !strcmp(mode, "none") ? 2
                : !strcmp(mode, "crop") ? 3 : -1;
    if (mode_id < 0 || width < 1u || width > 65535u) return failure(a, "text-wrap", EINVAL);
    size_t indent_cells = 0, hanging_cells = 0, ellipsis_cells = 0;
    if (!cetta_measure_cells(indent, indent_len, 0u, &indent_cells) ||
        !cetta_measure_cells(hanging, hanging_len, 0u, &hanging_cells) ||
        !cetta_measure_cells(ellipsis, ellipsis_len, 0u, &ellipsis_cells) ||
        !utf8(src, src_len)) {
        return failure(a, "text-wrap", EILSEQ);
    }

    LayoutVec rows = {0};
    size_t p = 0;
    for (;;) {
        size_t p_start = p;
        while (p < src_len && src[p] != '\n') ++p;
        size_t p_end = (p > p_start && src[p - 1u] == '\r') ? p - 1u : p;
        bool has_next_para = (p < src_len && src[p] == '\n');
        if (has_next_para) ++p;

        if (mode_id == 2) {
            /* none: single logical row per paragraph (copy-safe) */
            size_t body_cells = 0;
            (void)cetta_measure_cells(src + p_start, p_end - p_start, indent_cells, &body_cells);
            layout_vec_push(&rows, layout_make_row(a, indent, indent_len,
                src + p_start, p_end - p_start, "", 0u, p_start, p_end, indent_cells + body_cells));
        } else if (mode_id == 3) {
            /* crop: single row clipped at grapheme boundary with ellipsis */
            size_t at = p_start, col = indent_cells;
            size_t fit_end = p_start, fit_cells = indent_cells;
            size_t budget = (width >= ellipsis_cells) ? (width - ellipsis_cells) : 0u;
            bool overflow = false;
            while (at < p_end) {
                size_t next_at = 0, w = 0;
                (void)cetta_grapheme_next(src, p_end, at, col, &next_at, &w);
                if (col + w > width) { overflow = true; break; }
                col += w; at = next_at;
                if (col <= budget) { fit_end = at; fit_cells = col; }
            }
            if (!overflow) {
                layout_vec_push(&rows, layout_make_row(a, indent, indent_len,
                    src + p_start, p_end - p_start, "", 0u, p_start, p_end, col));
            } else if (indent_cells + ellipsis_cells <= width) {
                layout_vec_push(&rows, layout_make_row(a, indent, indent_len,
                    src + p_start, fit_end - p_start, ellipsis, ellipsis_len,
                    p_start, fit_end, fit_cells + ellipsis_cells));
            } else {
                layout_vec_push(&rows, layout_make_row(a, indent, indent_len,
                    "", 0u, "", 0u, p_start, p_start, indent_cells));
            }
        } else if (p_start == p_end) {
            layout_vec_push(&rows, layout_make_row(a, indent, indent_len,
                "", 0u, "", 0u, p_start, p_start, indent_cells));
        } else if (mode_id == 1) {
            /* fold: hard grapheme-boundary wrap */
            size_t at = p_start;
            bool first_row = true;
            while (at < p_end) {
                const char *pref = first_row ? indent : hanging;
                size_t pref_len = first_row ? indent_len : hanging_len;
                size_t col = first_row ? indent_cells : hanging_cells;
                size_t row_start = at;
                while (at < p_end) {
                    size_t next_at = 0, w = 0;
                    (void)cetta_grapheme_next(src, p_end, at, col, &next_at, &w);
                    if (at > row_start && col + w > width) break;
                    col += w; at = next_at;
                }
                layout_vec_push(&rows, layout_make_row(a, pref, pref_len,
                    src + row_start, at - row_start, "", 0u, row_start, at, col));
                first_row = false;
            }
        } else {
            /* word: wrap at whitespace, hyphens, or CJK wide clusters; fallback to grapheme fold */
            size_t at = p_start;
            bool first_row = true;
            while (at < p_end) {
                const char *pref = first_row ? indent : hanging;
                size_t pref_len = first_row ? indent_len : hanging_len;
                size_t col = first_row ? indent_cells : hanging_cells;
                size_t row_start = at;
                bool seen_nonws = false, in_ws = false, has_break = false;
                size_t ws_start = at, ws_cells = col;
                size_t break_end = at, break_next = at, break_cells = col;
                bool overflow = false;

                while (at < p_end) {
                    size_t next_at = 0, w = 0;
                    (void)cetta_grapheme_next(src, p_end, at, col, &next_at, &w);
                    bool is_ws = cluster_is_ascii_ws(src, at, next_at);
                    if (col + w > width) {
                        if (is_ws && (at > row_start || in_ws)) {
                            size_t emit_end = in_ws ? ws_start : at;
                            size_t emit_cells = in_ws ? ws_cells : col;
                            size_t skip = next_at;
                            while (skip < p_end) {
                                size_t sn = 0, sw = 0;
                                (void)cetta_grapheme_next(src, p_end, skip, 0u, &sn, &sw);
                                if (!cluster_is_ascii_ws(src, skip, sn)) break;
                                skip = sn;
                            }
                            layout_vec_push(&rows, layout_make_row(a, pref, pref_len,
                                src + row_start, emit_end - row_start, "", 0u,
                                row_start, emit_end, emit_cells));
                            at = skip;
                        } else if (in_ws && ws_start > row_start) {
                            layout_vec_push(&rows, layout_make_row(a, pref, pref_len,
                                src + row_start, ws_start - row_start, "", 0u,
                                row_start, ws_start, ws_cells));
                        } else if (has_break && break_end > row_start) {
                            layout_vec_push(&rows, layout_make_row(a, pref, pref_len,
                                src + row_start, break_end - row_start, "", 0u,
                                row_start, break_end, break_cells));
                            at = break_next;
                        } else {
                            size_t emit_end = (at > row_start) ? at : next_at;
                            size_t emit_cells = (at > row_start) ? col : (col + w);
                            layout_vec_push(&rows, layout_make_row(a, pref, pref_len,
                                src + row_start, emit_end - row_start, "", 0u,
                                row_start, emit_end, emit_cells));
                            at = emit_end;
                        }
                        overflow = true;
                        break;
                    }
                    if (is_ws) {
                        if (seen_nonws && !in_ws) {
                            in_ws = true; ws_start = at; ws_cells = col;
                        }
                    } else {
                        if (in_ws) {
                            has_break = true; break_end = ws_start; break_next = at; break_cells = ws_cells;
                            in_ws = false;
                        }
                        bool prev_nonws = seen_nonws;
                        seen_nonws = true;
                        if ((prev_nonws && next_at == at + 1u && src[at] == '-') || w == 2u) {
                            has_break = true; break_end = next_at; break_next = next_at; break_cells = col + w;
                        }
                    }
                    col += w; at = next_at;
                }
                if (!overflow) {
                    layout_vec_push(&rows, layout_make_row(a, pref, pref_len,
                        src + row_start, p_end - row_start, "", 0u, row_start, p_end, col));
                    at = p_end;
                }
                first_row = false;
            }
        }
        if (!has_next_para) break;
    }

    Atom *result = rows.oom ? failure(a, "text-wrap", ENOMEM)
                            : atom_expr(a, rows.items, (uint32_t)rows.len);
    free(rows.items);
    return result;
}

/* ---- Styled spans -> ANSI 16-color SGR + OSC 8 emitter (NO_COLOR aware) ---- */

static int sgr_style_code(const char *name) {
    if (!name) return -1;
    if (!strcmp(name, "bold")) return 1;
    if (!strcmp(name, "dim")) return 2;
    if (!strcmp(name, "italic")) return 3;
    if (!strcmp(name, "underline")) return 4;
    if (!strcmp(name, "reverse")) return 7;
    if (!strcmp(name, "strike")) return 9;
    return -1;
}

static int sgr_color_code(const char *name, bool background) {
    if (!name || !strcmp(name, "none") || !strcmp(name, "default")) return 0;
    int base = background ? 40 : 30;
    int bright = background ? 100 : 90;
    if (!strcmp(name, "black")) return base + 0;
    if (!strcmp(name, "red")) return base + 1;
    if (!strcmp(name, "green")) return base + 2;
    if (!strcmp(name, "yellow")) return base + 3;
    if (!strcmp(name, "blue")) return base + 4;
    if (!strcmp(name, "magenta")) return base + 5;
    if (!strcmp(name, "cyan")) return base + 6;
    if (!strcmp(name, "white")) return base + 7;
    if (!strcmp(name, "bright-black")) return bright + 0;
    if (!strcmp(name, "bright-red")) return bright + 1;
    if (!strcmp(name, "bright-green")) return bright + 2;
    if (!strcmp(name, "bright-yellow")) return bright + 3;
    if (!strcmp(name, "bright-blue")) return bright + 4;
    if (!strcmp(name, "bright-magenta")) return bright + 5;
    if (!strcmp(name, "bright-cyan")) return bright + 6;
    if (!strcmp(name, "bright-white")) return bright + 7;
    return -1;
}

typedef struct {
    char *data;
    size_t len, cap;
    bool oom;
} LayoutStr;

static void layout_str_append(LayoutStr *b, const char *s, size_t n) {
    if (b->oom || !n) return;
    if (n > (size_t)67108864u - b->len) { b->oom = true; return; }
    if (b->len + n > b->cap) {
        size_t next = b->cap ? b->cap * 2u : 128u;
        while (next < b->len + n) next *= 2u;
        char *grown = realloc(b->data, next);
        if (!grown) { b->oom = true; return; }
        b->data = grown; b->cap = next;
    }
    memcpy(b->data + b->len, s, n);
    b->len += n;
}

static Atom *text_render_spans(Arena *a, Atom *spans_atom, const char *color_mode) {
    if (!spans_atom || spans_atom->kind != ATOM_EXPR || !color_mode)
        return failure(a, "text-render-spans", EINVAL);
    bool no_color = false;
    if (!strcmp(color_mode, "no-color")) no_color = true;
    else if (!strcmp(color_mode, "ansi16")) no_color = false;
    else if (!strcmp(color_mode, "auto")) {
        const char *nc = getenv("NO_COLOR");
        no_color = (nc != NULL && nc[0] != '\0');
    } else return failure(a, "text-render-spans", EINVAL);

    LayoutStr out = {0};
    for (uint32_t i = 0; i < spans_atom->expr.len; ++i) {
        Atom *sp = spans_atom->expr.elems[i];
        const char *txt = NULL; size_t txt_len = 0;
        if (!sp || sp->kind != ATOM_EXPR || sp->expr.len != 6u ||
            !atom_is_symbol(sp->expr.elems[0], "TextSpan") ||
            !string_bytes(sp->expr.elems[1], &txt, &txt_len) ||
            sp->expr.elems[2]->kind != ATOM_EXPR) {
            free(out.data);
            return failure(a, "text-render-spans", EINVAL);
        }
        int codes[16]; size_t ncodes = 0;
        Atom *styles = sp->expr.elems[2];
        for (uint32_t j = 0; j < styles->expr.len; ++j) {
            int sc = sgr_style_code(text(styles->expr.elems[j]));
            if (sc < 0) { free(out.data); return failure(a, "text-render-spans", EINVAL); }
            if (ncodes < 14u) codes[ncodes++] = sc;
        }
        int fg = sgr_color_code(text(sp->expr.elems[3]), false);
        int bg = sgr_color_code(text(sp->expr.elems[4]), true);
        if (fg < 0 || bg < 0) { free(out.data); return failure(a, "text-render-spans", EINVAL); }
        if (fg > 0) codes[ncodes++] = fg;
        if (bg > 0) codes[ncodes++] = bg;

        const char *url = NULL; size_t url_len = 0;
        bool has_url = false;
        if (sp->expr.elems[5]->kind == ATOM_SYMBOL && atom_is_symbol(sp->expr.elems[5], "none")) {
            has_url = false;
        } else if (string_bytes(sp->expr.elems[5], &url, &url_len)) {
            has_url = (url_len > 0u);
        } else {
            free(out.data); return failure(a, "text-render-spans", EINVAL);
        }

        size_t clean_url_len = has_url ? sanitize_osc_url(url, url_len, NULL) : 0u;
        if (clean_url_len) {
            layout_str_append(&out, "\033]8;;", 5u);
            char *clean_url = malloc(clean_url_len);
            if (!clean_url) { free(out.data); return failure(a, "text-render-spans", ENOMEM); }
            (void)sanitize_osc_url(url, url_len, clean_url);
            layout_str_append(&out, clean_url, clean_url_len);
            free(clean_url);
            layout_str_append(&out, "\033\\", 2u);
        }
        bool opened_sgr = (!no_color && ncodes > 0u);
        if (opened_sgr) {
            char seq[96]; size_t pos = 0;
            seq[pos++] = '\033'; seq[pos++] = '[';
            for (size_t k = 0; k < ncodes; ++k) {
                if (k) seq[pos++] = ';';
                pos += (size_t)snprintf(seq + pos, sizeof(seq) - pos, "%d", codes[k]);
            }
            seq[pos++] = 'm';
            layout_str_append(&out, seq, pos);
        }
        size_t clean_txt_len = sanitize_plain_terminal_text(txt, txt_len, NULL, true);
        if (clean_txt_len) {
            char *clean_txt = malloc(clean_txt_len);
            if (!clean_txt) { free(out.data); return failure(a, "text-render-spans", ENOMEM); }
            (void)sanitize_plain_terminal_text(txt, txt_len, clean_txt, true);
            layout_str_append(&out, clean_txt, clean_txt_len);
            free(clean_txt);
        }
        if (opened_sgr) layout_str_append(&out, "\033[0m", 4u);
        if (clean_url_len) layout_str_append(&out, "\033]8;;\033\\", 7u);
    }
    Atom *result = out.oom ? failure(a, "text-render-spans", ENOMEM)
                           : atom_string_n(a, out.data ? out.data : "", out.len);
    free(out.data);
    return result;
}
