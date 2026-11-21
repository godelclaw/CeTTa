/* Self-contained CommonMark block and inline parser for (library host_io).
 * Zero external dependencies, bounded recursion depth (MD_MAX_DEPTH), and
 * verbatim preservation of code blocks and code spans.
 *
 * AST constructors returned:
 *   (MdDocument ($block ...))
 *   (MdHeading $level ($inline ...))
 *   (MdCodeBlock $info $literal)
 *   (MdBlockQuote ($block ...))
 *   (MdList $ordered $start ((MdItem ($block ...)) ...))
 *   (MdThematicBreak)
 *   (MdParagraph ($inline ...))
 *   (MdText $text) | (MdCode $text) | (MdEmph ($inline ...))
 *   (MdStrong ($inline ...)) | (MdLink $url $title ($inline ...))
 *   (MdSoftBreak) | (MdHardBreak) */

#define MD_MAX_DEPTH 64

typedef struct {
    Atom **items;
    size_t len, cap;
    bool oom;
} MdVec;

typedef struct {
    char *data;
    size_t len, cap;
    bool oom;
} MdBuf;

static void md_vec_push(MdVec *v, Atom *item) {
    if (v->oom || !item) { v->oom = true; return; }
    if (v->len == v->cap) {
        size_t next = v->cap ? v->cap * 2u : 16u;
        Atom **grown = realloc(v->items, next * sizeof(*grown));
        if (!grown) { v->oom = true; return; }
        v->items = grown; v->cap = next;
    }
    v->items[v->len++] = item;
}

static Atom *md_vec_finish(Arena *a, MdVec *v) {
    Atom *expr = v->oom ? NULL : atom_expr(a, v->items, (uint32_t)v->len);
    free(v->items);
    v->items = NULL; v->len = v->cap = 0;
    return expr;
}

static void md_buf_append(MdBuf *b, const char *s, size_t n) {
    if (b->oom || !n) return;
    if (n > (size_t)67108864u - b->len) { b->oom = true; return; }
    if (b->len + n > b->cap) {
        size_t next = b->cap ? b->cap * 2u : 64u;
        while (next < b->len + n) next *= 2u;
        char *grown = realloc(b->data, next);
        if (!grown) { b->oom = true; return; }
        b->data = grown; b->cap = next;
    }
    memcpy(b->data + b->len, s, n);
    b->len += n;
}

static void md_buf_push(MdBuf *b, char c) { md_buf_append(b, &c, 1u); }

static void md_buf_free(MdBuf *b) {
    free(b->data); b->data = NULL; b->len = b->cap = 0;
}

static bool md_is_ascii_punct(unsigned char c) {
    return (c >= '!' && c <= '/') || (c >= ':' && c <= '@') ||
           (c >= '[' && c <= '`') || (c >= '{' && c <= '~');
}

static bool md_is_alnum(unsigned char c) {
    return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

static bool md_is_space(unsigned char c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

static void md_flush_text(Arena *a, MdVec *out, MdBuf *txt) {
    if (!txt->len) return;
    if (txt->oom) { out->oom = true; txt->len = 0; return; }
    Atom *node = term(a, "MdText", (Atom *[]){atom_string_n(a, txt->data, txt->len)}, 1u);
    md_vec_push(out, node);
    txt->len = 0;
}

static Atom *md_parse_inlines(Arena *a, const char *s, size_t len, int depth);

/* Find closing delimiter matching delim (len 1 or 2) starting search at `from`. */
static bool md_find_delim(const char *s, size_t len, size_t from, char ch, size_t dlen,
                          bool intraword_guarded, size_t *out_pos) {
    size_t i = from;
    while (i + dlen <= len) {
        if (s[i] == '\\' && i + 1u < len && md_is_ascii_punct((unsigned char)s[i + 1u])) {
            i += 2u; continue;
        }
        if (s[i] == '`') {
            size_t k = 0;
            while (i + k < len && s[i + k] == '`') ++k;
            size_t j = i + k;
            bool closed = false;
            while (j < len) {
                if (s[j] == '`') {
                    size_t m = 0;
                    while (j + m < len && s[j + m] == '`') ++m;
                    if (m == k) { i = j + m; closed = true; break; }
                    j += m;
                } else ++j;
            }
            if (!closed) i += k;
            continue;
        }
        if (s[i] == ch) {
            size_t run = 0;
            while (i + run < len && s[i + run] == ch) ++run;
            if (run >= dlen) {
                size_t close_at = i + run - dlen;
                bool prev_ok = close_at > from && !md_is_space((unsigned char)s[close_at - 1u]);
                bool next_ok = !intraword_guarded || (close_at + dlen >= len || !md_is_alnum((unsigned char)s[close_at + dlen]));
                if (prev_ok && next_ok) {
                    /* For single '*' or '_', avoid splitting inside a '**' / '__' run unless exact odd length. */
                    if (dlen == 2u || run != 2u) {
                        *out_pos = close_at;
                        return true;
                    }
                }
            }
            i += run;
            continue;
        }
        ++i;
    }
    return false;
}

static Atom *md_parse_inlines(Arena *a, const char *s, size_t len, int depth) {
    MdVec out = {0};
    MdBuf txt = {0};
    size_t i = 0;
    while (i < len) {
        char c = s[i];
        /* Backslash escape or hard break \\\n */
        if (c == '\\' && i + 1u < len) {
            if (s[i + 1u] == '\n') {
                md_flush_text(a, &out, &txt);
                md_vec_push(&out, term(a, "MdHardBreak", NULL, 0u));
                i += 2u;
                while (i < len && s[i] == ' ') ++i;
                continue;
            }
            if (md_is_ascii_punct((unsigned char)s[i + 1u])) {
                md_buf_push(&txt, s[i + 1u]);
                i += 2u;
                continue;
            }
        }
        /* Soft or hard line break */
        if (c == '\n') {
            bool hard = txt.len >= 2u && txt.data[txt.len - 1u] == ' ' && txt.data[txt.len - 2u] == ' ';
            while (txt.len && txt.data[txt.len - 1u] == ' ') --txt.len;
            md_flush_text(a, &out, &txt);
            md_vec_push(&out, term(a, hard ? "MdHardBreak" : "MdSoftBreak", NULL, 0u));
            ++i;
            while (i < len && s[i] == ' ') ++i;
            continue;
        }
        /* Backtick code span (CommonMark §6.1) */
        if (c == '`') {
            size_t k = 0;
            while (i + k < len && s[i + k] == '`') ++k;
            size_t j = i + k, close_at = 0;
            bool found = false;
            while (j < len) {
                if (s[j] == '`') {
                    size_t m = 0;
                    while (j + m < len && s[j + m] == '`') ++m;
                    if (m == k) { close_at = j; found = true; break; }
                    j += m;
                } else ++j;
            }
            if (found) {
                md_flush_text(a, &out, &txt);
                size_t raw_start = i + k, raw_len = close_at - raw_start;
                MdBuf code = {0};
                for (size_t p = 0; p < raw_len; ++p)
                    md_buf_push(&code, s[raw_start + p] == '\n' ? ' ' : s[raw_start + p]);
                size_t cs = 0, ce = code.len;
                if (ce >= 2u && code.data[0] == ' ' && code.data[ce - 1u] == ' ') {
                    bool all_spaces = true;
                    for (size_t p = 0; p < ce; ++p) if (code.data[p] != ' ') { all_spaces = false; break; }
                    if (!all_spaces) { ++cs; --ce; }
                }
                if (code.oom) out.oom = true;
                else md_vec_push(&out, term(a, "MdCode", (Atom *[]){atom_string_n(a, code.data + cs, ce - cs)}, 1u));
                md_buf_free(&code);
                i = close_at + k;
                continue;
            }
            md_buf_append(&txt, s + i, k);
            i += k;
            continue;
        }
        /* Autolink <http://...> or <https://...> */
        if (c == '<') {
            size_t j = i + 1u;
            while (j < len && s[j] != '>' && !md_is_space((unsigned char)s[j]) && s[j] != '<') ++j;
            if (j < len && s[j] == '>' &&
                ((j - i - 1u > 7u && !memcmp(s + i + 1u, "http://", 7u)) ||
                 (j - i - 1u > 8u && !memcmp(s + i + 1u, "https://", 8u)))) {
                md_flush_text(a, &out, &txt);
                Atom *url = atom_string_n(a, s + i + 1u, j - i - 1u);
                Atom *lbl_txt = term(a, "MdText", (Atom *[]){url}, 1u);
                Atom *lbl = atom_expr(a, (Atom *[]){lbl_txt}, 1u);
                md_vec_push(&out, term(a, "MdLink", (Atom *[]){url, atom_string(a, ""), lbl}, 3u));
                i = j + 1u;
                continue;
            }
        }
        /* Link [label](url "title") */
        if (c == '[' && depth < MD_MAX_DEPTH) {
            size_t j = i + 1u;
            int brackets = 1;
            while (j < len && brackets > 0) {
                if (s[j] == '\\' && j + 1u < len) { j += 2u; continue; }
                if (s[j] == '[') ++brackets;
                else if (s[j] == ']') --brackets;
                ++j;
            }
            if (brackets == 0 && j < len && s[j] == '(') {
                size_t label_start = i + 1u, label_end = j - 1u;
                size_t u = j + 1u;
                while (u < len && md_is_space((unsigned char)s[u])) ++u;
                size_t url_start = u, url_end = u;
                bool url_ok = false;
                if (u < len && s[u] == '<') {
                    ++u; url_start = u;
                    while (u < len && s[u] != '>' && s[u] != '\n') ++u;
                    if (u < len && s[u] == '>') { url_end = u; ++u; url_ok = true; }
                } else {
                    int parens = 0;
                    url_start = u;
                    while (u < len && !md_is_space((unsigned char)s[u])) {
                        if (s[u] == '\\' && u + 1u < len) { u += 2u; continue; }
                        if (s[u] == '(') ++parens;
                        else if (s[u] == ')') {
                            if (parens == 0) break;
                            --parens;
                        }
                        ++u;
                    }
                    url_end = u; url_ok = true;
                }
                while (u < len && md_is_space((unsigned char)s[u])) ++u;
                size_t title_start = 0, title_end = 0;
                if (url_ok && u < len && (s[u] == '"' || s[u] == '\'')) {
                    char q = s[u++]; title_start = u;
                    while (u < len && s[u] != q) {
                        if (s[u] == '\\' && u + 1u < len) { u += 2u; continue; }
                        ++u;
                    }
                    if (u < len && s[u] == q) { title_end = u++; }
                    else url_ok = false;
                    while (u < len && md_is_space((unsigned char)s[u])) ++u;
                }
                if (url_ok && u < len && s[u] == ')') {
                    md_flush_text(a, &out, &txt);
                    Atom *children = md_parse_inlines(a, s + label_start, label_end - label_start, depth + 1);
                    Atom *url_atom = atom_string_n(a, s + url_start, url_end - url_start);
                    Atom *title_atom = atom_string_n(a, s + title_start, title_end - title_start);
                    md_vec_push(&out, term(a, "MdLink", (Atom *[]){url_atom, title_atom, children}, 3u));
                    i = u + 1u;
                    continue;
                }
            }
        }
        /* Strong (** / __) and Emph (* / _) */
        if ((c == '*' || c == '_') && depth < MD_MAX_DEPTH) {
            bool intraword = (c == '_');
            bool prev_alnum = i > 0 && md_is_alnum((unsigned char)s[i - 1u]);
            if (!intraword || !prev_alnum) {
                size_t dlen = (i + 1u < len && s[i + 1u] == c) ? 2u : 1u;
                if (i + dlen < len && !md_is_space((unsigned char)s[i + dlen])) {
                    size_t close_at = 0;
                    if (md_find_delim(s, len, i + dlen, c, dlen, intraword, &close_at)) {
                        md_flush_text(a, &out, &txt);
                        Atom *children = md_parse_inlines(a, s + i + dlen, close_at - (i + dlen), depth + 1);
                        md_vec_push(&out, term(a, dlen == 2u ? "MdStrong" : "MdEmph", (Atom *[]){children}, 1u));
                        i = close_at + dlen;
                        continue;
                    }
                }
            }
        }
        md_buf_push(&txt, c);
        ++i;
    }
    md_flush_text(a, &out, &txt);
    md_buf_free(&txt);
    return md_vec_finish(a, &out);
}

typedef struct {
    size_t start, end, next; /* [start, end) without trailing \r?\n; next is after \n */
} MdLine;

static MdLine md_next_line(const char *s, size_t len, size_t at) {
    MdLine ln = {at, at, at};
    while (ln.end < len && s[ln.end] != '\n') ++ln.end;
    ln.next = ln.end < len ? ln.end + 1u : ln.end;
    if (ln.end > ln.start && s[ln.end - 1u] == '\r') --ln.end;
    return ln;
}

static size_t md_leading_spaces(const char *s, size_t start, size_t end) {
    size_t n = 0;
    while (start + n < end && s[start + n] == ' ') ++n;
    return n;
}

static bool md_line_blank(const char *s, MdLine ln) {
    for (size_t i = ln.start; i < ln.end; ++i)
        if (s[i] != ' ' && s[i] != '\t') return false;
    return true;
}

static bool md_is_thematic_break(const char *s, MdLine ln) {
    size_t sp = md_leading_spaces(s, ln.start, ln.end);
    if (sp > 3u || ln.start + sp >= ln.end) return false;
    char ch = s[ln.start + sp];
    if (ch != '-' && ch != '*' && ch != '_') return false;
    size_t count = 0;
    for (size_t i = ln.start + sp; i < ln.end; ++i) {
        if (s[i] == ch) ++count;
        else if (s[i] != ' ' && s[i] != '\t') return false;
    }
    return count >= 3u;
}

static bool md_is_atx_heading(const char *s, MdLine ln, int *out_level, size_t *out_cs, size_t *out_ce) {
    size_t sp = md_leading_spaces(s, ln.start, ln.end);
    if (sp > 3u || ln.start + sp >= ln.end || s[ln.start + sp] != '#') return false;
    size_t p = ln.start + sp, hashes = 0;
    while (p < ln.end && s[p] == '#') { ++p; ++hashes; }
    if (hashes < 1u || hashes > 6u) return false;
    if (p < ln.end && s[p] != ' ' && s[p] != '\t') return false;
    while (p < ln.end && (s[p] == ' ' || s[p] == '\t')) ++p;
    size_t ce = ln.end;
    while (ce > p && (s[ce - 1u] == ' ' || s[ce - 1u] == '\t')) --ce;
    /* Optional closing sequence of # preceded by space/tab */
    size_t tail = ce;
    while (tail > p && s[tail - 1u] == '#') --tail;
    if (tail < ce && (tail == p || s[tail - 1u] == ' ' || s[tail - 1u] == '\t')) {
        ce = tail;
        while (ce > p && (s[ce - 1u] == ' ' || s[ce - 1u] == '\t')) --ce;
    }
    *out_level = (int)hashes; *out_cs = p; *out_ce = ce;
    return true;
}

static bool md_is_fence_open(const char *s, MdLine ln, char *out_ch, size_t *out_flen,
                             size_t *out_indent, size_t *out_is, size_t *out_ie) {
    size_t sp = md_leading_spaces(s, ln.start, ln.end);
    if (sp > 3u || ln.start + sp >= ln.end) return false;
    char ch = s[ln.start + sp];
    if (ch != '`' && ch != '~') return false;
    size_t p = ln.start + sp, flen = 0;
    while (p < ln.end && s[p] == ch) { ++p; ++flen; }
    if (flen < 3u) return false;
    size_t is = p, ie = ln.end;
    while (is < ie && (s[is] == ' ' || s[is] == '\t')) ++is;
    while (ie > is && (s[ie - 1u] == ' ' || s[ie - 1u] == '\t')) --ie;
    if (ch == '`') {
        for (size_t k = is; k < ie; ++k) if (s[k] == '`') return false;
    }
    *out_ch = ch; *out_flen = flen; *out_indent = sp; *out_is = is; *out_ie = ie;
    return true;
}

static bool md_is_fence_close(const char *s, MdLine ln, char ch, size_t flen) {
    size_t sp = md_leading_spaces(s, ln.start, ln.end);
    if (sp > 3u || ln.start + sp >= ln.end) return false;
    size_t p = ln.start + sp, cnt = 0;
    while (p < ln.end && s[p] == ch) { ++p; ++cnt; }
    if (cnt < flen) return false;
    while (p < ln.end) { if (s[p] != ' ' && s[p] != '\t') return false; ++p; }
    return true;
}

static bool md_is_setext_underline(const char *s, MdLine ln, int *out_level) {
    size_t sp = md_leading_spaces(s, ln.start, ln.end);
    if (sp > 3u || ln.start + sp >= ln.end) return false;
    char ch = s[ln.start + sp];
    if (ch != '=' && ch != '-') return false;
    size_t p = ln.start + sp;
    while (p < ln.end && s[p] == ch) ++p;
    while (p < ln.end && (s[p] == ' ' || s[p] == '\t')) ++p;
    if (p != ln.end) return false;
    *out_level = (ch == '=') ? 1 : 2;
    return true;
}

static bool md_is_list_marker(const char *s, MdLine ln, bool *out_ordered, char *out_delim,
                              int64_t *out_start, size_t *out_content_col, size_t *out_after) {
    size_t sp = md_leading_spaces(s, ln.start, ln.end);
    if (sp > 3u || ln.start + sp >= ln.end) return false;
    size_t p = ln.start + sp;
    if (s[p] == '-' || s[p] == '*' || s[p] == '+') {
        char delim = s[p++];
        if (p < ln.end && s[p] != ' ' && s[p] != '\t') return false;
        size_t after_sp = 0;
        while (p + after_sp < ln.end && s[p + after_sp] == ' ') ++after_sp;
        size_t consume = (p < ln.end && s[p] == '\t') ? 1u : (after_sp ? (after_sp > 4u ? 1u : after_sp) : 0u);
        *out_ordered = false; *out_delim = delim; *out_start = 1;
        *out_content_col = sp + 1u + (consume ? consume : 1u);
        *out_after = p + consume;
        return true;
    }
    if (s[p] >= '0' && s[p] <= '9') {
        int64_t num = 0; size_t digits = 0;
        while (p < ln.end && s[p] >= '0' && s[p] <= '9') {
            if (++digits > 9u) return false;
            num = num * 10 + (s[p++] - '0');
        }
        if (p >= ln.end || (s[p] != '.' && s[p] != ')')) return false;
        char delim = s[p++];
        if (p < ln.end && s[p] != ' ' && s[p] != '\t') return false;
        size_t after_sp = 0;
        while (p + after_sp < ln.end && s[p + after_sp] == ' ') ++after_sp;
        size_t consume = (p < ln.end && s[p] == '\t') ? 1u : (after_sp ? (after_sp > 4u ? 1u : after_sp) : 0u);
        *out_ordered = true; *out_delim = delim; *out_start = num;
        *out_content_col = sp + digits + 1u + (consume ? consume : 1u);
        *out_after = p + consume;
        return true;
    }
    return false;
}

static bool md_is_blockquote(const char *s, MdLine ln, size_t *out_after) {
    size_t sp = md_leading_spaces(s, ln.start, ln.end);
    if (sp > 3u || ln.start + sp >= ln.end || s[ln.start + sp] != '>') return false;
    size_t p = ln.start + sp + 1u;
    if (p < ln.end && s[p] == ' ') ++p;
    *out_after = p;
    return true;
}

static Atom *md_parse_blocks(Arena *a, const char *s, size_t len, int depth) {
    MdVec blocks = {0};
    size_t at = 0;
    while (at < len) {
        MdLine ln = md_next_line(s, len, at);
        if (md_line_blank(s, ln)) { at = ln.next; continue; }

        /* 1. Fenced code block (verbatim!) */
        char fch = 0; size_t flen = 0, findent = 0, is = 0, ie = 0;
        if (md_is_fence_open(s, ln, &fch, &flen, &findent, &is, &ie)) {
            MdBuf code = {0};
            at = ln.next;
            while (at < len) {
                MdLine cl = md_next_line(s, len, at);
                if (md_is_fence_close(s, cl, fch, flen)) { at = cl.next; break; }
                size_t strip = md_leading_spaces(s, cl.start, cl.end);
                if (strip > findent) strip = findent;
                md_buf_append(&code, s + cl.start + strip, cl.end - (cl.start + strip));
                md_buf_push(&code, '\n');
                at = cl.next;
            }
            if (code.oom) blocks.oom = true;
            else md_vec_push(&blocks, term(a, "MdCodeBlock",
                (Atom *[]){atom_string_n(a, s + is, ie - is),
                           atom_string_n(a, code.data ? code.data : "", code.len)}, 2u));
            md_buf_free(&code);
            continue;
        }

        /* 2. ATX heading */
        int hlevel = 0; size_t hcs = 0, hce = 0;
        if (md_is_atx_heading(s, ln, &hlevel, &hcs, &hce)) {
            Atom *inlines = md_parse_inlines(a, s + hcs, hce - hcs, depth + 1);
            md_vec_push(&blocks, term(a, "MdHeading", (Atom *[]){atom_int(a, hlevel), inlines}, 2u));
            at = ln.next;
            continue;
        }

        /* 3. Thematic break */
        if (md_is_thematic_break(s, ln)) {
            md_vec_push(&blocks, term(a, "MdThematicBreak", NULL, 0u));
            at = ln.next;
            continue;
        }

        /* 4. Block quote */
        size_t bq_after = 0;
        if (depth < MD_MAX_DEPTH && md_is_blockquote(s, ln, &bq_after)) {
            MdBuf inner = {0};
            while (at < len) {
                MdLine bl = md_next_line(s, len, at);
                size_t ba = 0;
                if (!md_is_blockquote(s, bl, &ba)) break;
                md_buf_append(&inner, s + ba, bl.end - ba);
                md_buf_push(&inner, '\n');
                at = bl.next;
            }
            Atom *children = inner.oom ? NULL : md_parse_blocks(a, inner.data ? inner.data : "", inner.len, depth + 1);
            md_buf_free(&inner);
            md_vec_push(&blocks, term(a, "MdBlockQuote", (Atom *[]){children}, 1u));
            continue;
        }

        /* 5. List (ordered or unordered) */
        bool ordered = false; char delim = 0; int64_t list_start = 1;
        size_t content_col = 0, m_after = 0;
        if (depth < MD_MAX_DEPTH &&
            md_is_list_marker(s, ln, &ordered, &delim, &list_start, &content_col, &m_after)) {
            MdVec items = {0};
            while (at < len) {
                MdLine il = md_next_line(s, len, at);
                bool o2 = false; char d2 = 0; int64_t n2 = 0; size_t cc2 = 0, a2 = 0;
                if (md_is_thematic_break(s, il) ||
                    !md_is_list_marker(s, il, &o2, &d2, &n2, &cc2, &a2) ||
                    o2 != ordered || d2 != delim) break;
                MdBuf ibuf = {0};
                md_buf_append(&ibuf, s + a2, il.end - a2);
                md_buf_push(&ibuf, '\n');
                at = il.next;
                while (at < len) {
                    MdLine cont = md_next_line(s, len, at);
                    if (md_line_blank(s, cont)) {
                        /* Look ahead: include blank line only if followed by indented continuation */
                        size_t probe = cont.next;
                        while (probe < len && md_line_blank(s, md_next_line(s, len, probe)))
                            probe = md_next_line(s, len, probe).next;
                        if (probe < len) {
                            MdLine next_nonblank = md_next_line(s, len, probe);
                            size_t nsp = md_leading_spaces(s, next_nonblank.start, next_nonblank.end);
                            if (nsp >= cc2 || (next_nonblank.start < next_nonblank.end && s[next_nonblank.start] == '\t')) {
                                md_buf_push(&ibuf, '\n');
                                at = cont.next;
                                continue;
                            }
                        }
                        break;
                    }
                    size_t csp = md_leading_spaces(s, cont.start, cont.end);
                    if (csp >= cc2) {
                        md_buf_append(&ibuf, s + cont.start + cc2, cont.end - (cont.start + cc2));
                        md_buf_push(&ibuf, '\n');
                        at = cont.next;
                        continue;
                    }
                    if (cont.start < cont.end && s[cont.start] == '\t') {
                        md_buf_append(&ibuf, s + cont.start + 1u, cont.end - (cont.start + 1u));
                        md_buf_push(&ibuf, '\n');
                        at = cont.next;
                        continue;
                    }
                    break;
                }
                Atom *item_blocks = ibuf.oom ? NULL : md_parse_blocks(a, ibuf.data ? ibuf.data : "", ibuf.len, depth + 1);
                md_buf_free(&ibuf);
                md_vec_push(&items, term(a, "MdItem", (Atom *[]){item_blocks}, 1u));
                /* Skip blank lines between loose list items if next line continues same list */
                size_t probe = at;
                while (probe < len && md_line_blank(s, md_next_line(s, len, probe)))
                    probe = md_next_line(s, len, probe).next;
                if (probe < len) {
                    MdLine peek = md_next_line(s, len, probe);
                    bool po = false; char pd = 0; int64_t pn = 0; size_t pcc = 0, pa = 0;
                    if (!md_is_thematic_break(s, peek) &&
                        md_is_list_marker(s, peek, &po, &pd, &pn, &pcc, &pa) &&
                        po == ordered && pd == delim) {
                        at = probe;
                    }
                }
            }
            Atom *items_atom = md_vec_finish(a, &items);
            md_vec_push(&blocks, term(a, "MdList",
                (Atom *[]){atom_symbol(a, ordered ? "ordered" : "unordered"), atom_int(a, list_start), items_atom}, 3u));
            continue;
        }

        /* 6. Indented code block (4 spaces or leading tab) */
        size_t isp = md_leading_spaces(s, ln.start, ln.end);
        if (isp >= 4u || (ln.start < ln.end && s[ln.start] == '\t')) {
            MdBuf code = {0};
            size_t trailing_blanks = 0;
            while (at < len) {
                MdLine cl = md_next_line(s, len, at);
                if (md_line_blank(s, cl)) {
                    size_t csp = md_leading_spaces(s, cl.start, cl.end);
                    size_t skip = csp >= 4u ? 4u : cl.end - cl.start;
                    md_buf_append(&code, s + cl.start + skip, cl.end - (cl.start + skip));
                    md_buf_push(&code, '\n');
                    ++trailing_blanks;
                    at = cl.next;
                    continue;
                }
                size_t csp = md_leading_spaces(s, cl.start, cl.end);
                if (csp >= 4u) {
                    trailing_blanks = 0;
                    md_buf_append(&code, s + cl.start + 4u, cl.end - (cl.start + 4u));
                    md_buf_push(&code, '\n');
                    at = cl.next;
                } else if (cl.start < cl.end && s[cl.start] == '\t') {
                    trailing_blanks = 0;
                    md_buf_append(&code, s + cl.start + 1u, cl.end - (cl.start + 1u));
                    md_buf_push(&code, '\n');
                    at = cl.next;
                } else break;
            }
            while (trailing_blanks && code.len) {
                if (code.data[code.len - 1u] == '\n') --code.len;
                while (code.len && code.data[code.len - 1u] != '\n') --code.len;
                --trailing_blanks;
            }
            if (code.oom) blocks.oom = true;
            else md_vec_push(&blocks, term(a, "MdCodeBlock",
                (Atom *[]){atom_string(a, ""), atom_string_n(a, code.data ? code.data : "", code.len)}, 2u));
            md_buf_free(&code);
            continue;
        }

        /* 7. Paragraph (or Setext heading if underlined by === / ---) */
        MdBuf para = {0};
        int setext_level = 0;
        while (at < len) {
            MdLine pl = md_next_line(s, len, at);
            if (md_line_blank(s, pl)) break;
            if (para.len) {
                int sl = 0;
                if (md_is_setext_underline(s, pl, &sl)) {
                    setext_level = sl;
                    at = pl.next;
                    break;
                }
                char tf = 0; size_t tfl = 0, tfi = 0, tis = 0, tie = 0;
                int th = 0; size_t ths = 0, the = 0; size_t tbq = 0;
                bool to = false; char td = 0; int64_t tn = 0; size_t tcc = 0, ta = 0;
                if (md_is_fence_open(s, pl, &tf, &tfl, &tfi, &tis, &tie) ||
                    md_is_atx_heading(s, pl, &th, &ths, &the) ||
                    md_is_thematic_break(s, pl) ||
                    md_is_blockquote(s, pl, &tbq) ||
                    md_is_list_marker(s, pl, &to, &td, &tn, &tcc, &ta)) {
                    break;
                }
                md_buf_push(&para, '\n');
            }
            size_t psp = md_leading_spaces(s, pl.start, pl.end);
            md_buf_append(&para, s + pl.start + psp, pl.end - (pl.start + psp));
            at = pl.next;
        }
        while (para.len && (para.data[para.len - 1u] == ' ' || para.data[para.len - 1u] == '\t')) --para.len;
        Atom *inlines = para.oom ? NULL : md_parse_inlines(a, para.data ? para.data : "", para.len, depth + 1);
        md_buf_free(&para);
        if (setext_level)
            md_vec_push(&blocks, term(a, "MdHeading", (Atom *[]){atom_int(a, setext_level), inlines}, 2u));
        else
            md_vec_push(&blocks, term(a, "MdParagraph", (Atom *[]){inlines}, 1u));
    }
    return md_vec_finish(a, &blocks);
}

static Atom *markdown_parse(Arena *a, const char *bytes, size_t length) {
    if (length > (size_t)16777216u) return failure(a, "markdown-parse", EFBIG);
    if (!utf8(bytes, length)) return failure(a, "markdown-parse", EILSEQ);
    Atom *blocks = md_parse_blocks(a, bytes, length, 0);
    if (!blocks) return failure(a, "markdown-parse", ENOMEM);
    return term(a, "MdDocument", (Atom *[]){blocks}, 1u);
}
