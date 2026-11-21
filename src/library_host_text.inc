/* Text mechanisms for the owned host-I/O library.
 * - UAX #29 Extended Grapheme Cluster segmentation (Unicode 16.0.0)
 * - UAX #11 East Asian Width + Emoji Presentation cluster width
 * - Layout caches source row boundaries; an edit invalidates only its suffix,
 *   while cursor moves reuse it. No agent commands or presentation policy enter. */
#include "unicode_category15.h"
static unsigned character_category(uint32_t cp) {
    size_t lo = 0, hi = CETTA_UNICODE_CATEGORY15_RUNS;
    while (lo + 1 < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (cetta_unicode_category15_starts[mid] <= cp) lo = mid; else hi = mid;
    }
    return cetta_unicode_category15_values[lo];
}

typedef struct {
    unsigned prev_gcb;
    unsigned incb_state;     /* 0=none, 1=consonant+ext*, 2=consonant+ext*+linker+[ext|linker]* */
    unsigned ext_pict_state; /* 0=none, 1=extpict+ext*, 2=extpict+ext*+zwj */
    bool ri_odd;
    bool started;
} CettaGraphemeState;

static bool cetta_grapheme_break_step(CettaGraphemeState *st, uint32_t cp) {
    uint16_t prop = cetta_unicode_layout_props(cp);
    unsigned gcb = CETTA_UL_GCB(prop);
    unsigned incb = CETTA_UL_INCB(prop);
    bool ext_pict = CETTA_UL_EXT_PICT(prop);
    bool brk = true;
    if (!st->started) {
        brk = false;
    } else {
        unsigned p = st->prev_gcb;
        if (p == CETTA_GCB_CR && gcb == CETTA_GCB_LF) brk = false;
        else if (p == CETTA_GCB_CONTROL || p == CETTA_GCB_CR || p == CETTA_GCB_LF) brk = true;
        else if (gcb == CETTA_GCB_CONTROL || gcb == CETTA_GCB_CR || gcb == CETTA_GCB_LF) brk = true;
        else if (p == CETTA_GCB_L && (gcb == CETTA_GCB_L || gcb == CETTA_GCB_V || gcb == CETTA_GCB_LV || gcb == CETTA_GCB_LVT)) brk = false;
        else if ((p == CETTA_GCB_LV || p == CETTA_GCB_V) && (gcb == CETTA_GCB_V || gcb == CETTA_GCB_T)) brk = false;
        else if ((p == CETTA_GCB_LVT || p == CETTA_GCB_T) && gcb == CETTA_GCB_T) brk = false;
        else if (gcb == CETTA_GCB_EXTEND || gcb == CETTA_GCB_ZWJ) brk = false;
        else if (gcb == CETTA_GCB_SPACINGMARK) brk = false;
        else if (p == CETTA_GCB_PREPEND) brk = false;
        else if (st->incb_state == 2u && incb == CETTA_INCB_CONSONANT) brk = false;
        else if (st->ext_pict_state == 2u && ext_pict) brk = false;
        else if (st->ri_odd && gcb == CETTA_GCB_RI) brk = false;
        else brk = true;
    }
    if (brk || !st->started) {
        st->started = true;
        st->ri_odd = (gcb == CETTA_GCB_RI);
        st->ext_pict_state = ext_pict ? 1u : 0u;
        st->incb_state = (incb == CETTA_INCB_CONSONANT) ? 1u : 0u;
    } else {
        st->ri_odd = (gcb == CETTA_GCB_RI) ? !st->ri_odd : false;
        if (ext_pict) st->ext_pict_state = 1u;
        else if (gcb == CETTA_GCB_EXTEND && st->ext_pict_state == 1u) st->ext_pict_state = 1u;
        else if (gcb == CETTA_GCB_ZWJ && st->ext_pict_state == 1u) st->ext_pict_state = 2u;
        else st->ext_pict_state = 0u;
        if (incb == CETTA_INCB_CONSONANT) st->incb_state = 1u;
        else if (incb == CETTA_INCB_LINKER && st->incb_state >= 1u) st->incb_state = 2u;
        else if (incb == CETTA_INCB_EXTEND && st->incb_state >= 1u) { /* keep */ }
        else st->incb_state = 0u;
    }
    st->prev_gcb = gcb;
    return brk;
}

/* Decode one UAX #29 extended grapheme cluster starting at `start` in UTF-8
 * `bytes[0..length)`. Returns false on invalid UTF-8. Sets *out_end to the
 * cluster's exclusive end byte and *out_cells to its terminal cell width at
 * `column`. */
static bool cetta_grapheme_next(const char *bytes, size_t length, size_t start,
                                size_t column, size_t *out_end, size_t *out_cells) {
    if (start >= length) { *out_end = start; *out_cells = 0; return true; }
    CettaGraphemeState st = {0};
    size_t at = start, cp_count = 0, ri_count = 0, max_w = 0;
    uint32_t first_cp = 0;
    bool has_vs16 = false, has_vs15 = false, has_zwj = false;
    bool has_ext_pict = false, has_emoji = false, has_keycap = false;

    while (at < length) {
        uint32_t cp = 0, width = 0;
        if (!cetta_utf8_decode_one((const uint8_t *)bytes, length, at, &cp, &width)) return false;
        if (cp_count > 0u) {
            CettaGraphemeState probe = st;
            if (cetta_grapheme_break_step(&probe, cp)) break;
            st = probe;
        } else {
            (void)cetta_grapheme_break_step(&st, cp);
            first_cp = cp;
        }
        uint16_t prop = cetta_unicode_layout_props(cp);
        if (CETTA_UL_GCB(prop) == CETTA_GCB_RI) ++ri_count;
        if (cp == 0xFE0Fu) has_vs16 = true;
        else if (cp == 0xFE0Eu) has_vs15 = true;
        else if (cp == 0x200Du) has_zwj = true;
        else if (cp == 0x20E3u) has_keycap = true;
        if (CETTA_UL_EXT_PICT(prop)) has_ext_pict = true;
        if (CETTA_UL_EMOJI(prop)) has_emoji = true;
        size_t w = (size_t)CETTA_UL_WIDTH(prop);
        if (w > max_w) max_w = w;
        at += width;
        ++cp_count;
    }

    size_t cl_cells = max_w;
    if (cp_count == 1u && first_cp == '\t') cl_cells = 8u - (column % 8u);
    else if (first_cp == '\r' || first_cp == '\n') cl_cells = 0u;
    else if (ri_count >= 2u) cl_cells = 2u;
    else if (has_keycap && has_vs16) cl_cells = 2u;
    else if (has_zwj && has_ext_pict) cl_cells = 2u;
    else if (has_vs16 && has_emoji) cl_cells = 2u;
    else if (has_vs15 && has_emoji) cl_cells = 1u;

    *out_end = at;
    *out_cells = cl_cells;
    return true;
}

static bool cetta_measure_cells(const char *bytes, size_t length, size_t start_col, size_t *out_cells) {
    size_t at = 0, col = start_col;
    while (at < length) {
        size_t next = 0, w = 0;
        if (!cetta_grapheme_next(bytes, length, at, col, &next, &w)) return false;
        col += w; at = next;
    }
    *out_cells = col - start_col;
    return true;
}

static Atom *cells(Arena *a, const char *bytes, size_t length) {
    size_t total = 0;
    if (!cetta_measure_cells(bytes, length, 0u, &total)) return failure(a, "cells", EILSEQ);
    return atom_int(a, (int64_t)total);
}

static Atom *graphemes_text(Arena *a, const char *bytes, size_t length) {
    Atom **items = NULL;
    size_t count = 0, cap = 0, at = 0, col = 0;
    while (at < length) {
        size_t next = 0, w = 0;
        if (!cetta_grapheme_next(bytes, length, at, col, &next, &w)) {
            free(items);
            return failure(a, "graphemes", EILSEQ);
        }
        if (count == cap) {
            size_t grown_cap = cap ? cap * 2u : 16u;
            Atom **grown = realloc(items, grown_cap * sizeof(*grown));
            if (!grown) { free(items); return failure(a, "graphemes", ENOMEM); }
            items = grown; cap = grown_cap;
        }
        items[count++] = term(a, "HostGrapheme", (Atom *[]){
            atom_string_n(a, bytes + at, next - at),
            atom_int(a, (int64_t)at),
            atom_int(a, (int64_t)next),
            atom_int(a, (int64_t)w)
        }, 4u);
        col += w; at = next;
    }
    Atom *result = atom_expr(a, items, (uint32_t)count);
    free(items);
    return result;
}

static Atom *clean_text(Arena *a, const char *bytes, size_t length) {
    unsigned char *output = arena_alloc(a, length ? length : 1u);
    size_t written = 0, line = 0; unsigned state = 0;
    for (size_t at = 0; at < length;) {
        uint32_t cp, count;
        if (!cetta_utf8_decode_surrogatepass((const uint8_t *)bytes, length, at, &cp, &count)) { cp = ' '; count = 1; }
        at += count;
        if (state == 3 || state == 4) {
            if (cp == 7 || cp == 0x9c || (state == 4 && cp == '\\')) state = 0;
            else state = cp == 27 ? 4 : 3;
            continue;
        }
        if (state == 2) { if (cp >= 0x40 && cp <= 0x7e) state = 0; continue; }
        if (state == 1) {
            if (cp == '[') state = 2;
            else if (cp == ']' || cp == 'P' || cp == 'X' || cp == '^' || cp == '_') state = 3;
            else if (cp < 0x20 || cp > 0x2f) state = 0;
            continue;
        }
        if (cp == 27) { state = 1; continue; }
        if (cp == 0x9b) { state = 2; continue; }
        if (cp == 0x90 || cp == 0x98 || cp == 0x9d || cp == 0x9e || cp == 0x9f) { state = 3; continue; }
        if (cp == '\r') { if (at == length || bytes[at] != '\n') written = line; continue; }
        if (cp == '\n') { output[written++] = '\n'; line = written; continue; }
        if (cp == '\t') { output[written++] = '\t'; continue; }
        unsigned category = character_category(cp);
        if (category == 26) continue;
        if (category >= 25) output[written++] = ' ';
        else { memcpy(output + written, bytes + at - count, count); written += count; }
    }
    return atom_string_n(a, (const char *)output, written);
}

static Atom *clip_text(Arena *a, const char *bytes, size_t length, size_t maximum) {
    size_t at = 0, column = 0, boundary = 0;
    while (at < length) {
        size_t next_at = 0, w = 0;
        if (!cetta_grapheme_next(bytes, length, at, column, &next_at, &w)) return failure(a, "clip", EILSEQ);
        size_t next_col = column + w;
        if (next_col > maximum) {
            if (!maximum) return atom_string(a, "");
            char *out = arena_alloc(a, boundary + 3u);
            if (boundary) memcpy(out, bytes, boundary);
            memcpy(out + boundary, "…", 3u);
            return atom_string_n(a, out, boundary + 3u);
        }
        if (next_col <= (maximum ? maximum - 1u : 0u)) boundary = next_at;
        column = next_col; at = next_at;
    }
    return atom_string_n(a, bytes, length);
}

static size_t editor_cells(uint32_t cp, size_t column) {
    unsigned category = character_category(cp);
    if (category == 26) return 0;
    if (cp == '\t') return (size_t)character_cells(cp, column);
    return category >= 25 ? 1u : (size_t)character_cells(cp, column);
}
static bool row_append(HostBuffer *b, size_t offset) {
    if (b->row_count == b->row_capacity) {
        size_t capacity = b->row_capacity ? b->row_capacity * 2u : 64u;
        size_t *rows = realloc(b->rows, capacity * sizeof(*rows));
        if (!rows) return false;
        b->rows = rows; b->row_capacity = capacity;
    }
    b->rows[b->row_count++] = offset; return true;
}
static size_t row_at(const HostBuffer *b, size_t offset) {
    size_t lo = 0, hi = b->row_count;
    while (lo + 1u < hi) {
        size_t mid = lo + (hi - lo) / 2u;
        if (b->rows[mid] <= offset) lo = mid; else hi = mid;
    }
    return lo;
}
static bool layout_buffer(HostBuffer *b, size_t width) {
    if (!b->layout_valid || b->layout_width != width) {
        b->row_count = 0; if (!row_append(b, 0)) return false;
        b->dirty = 0; b->layout_width = width;
    } else if (b->dirty == SIZE_MAX) return true;
    size_t row = row_at(b, b->dirty);
    if (row) --row;
    b->row_count = row + 1u;
    size_t column = 0, length = buffer_length(b);
    for (size_t at = b->rows[row]; at < length;) {
        uint32_t cp = buffer_character(b, at); size_t next = next_character(b, at);
        if (cp == '\n') { if (!row_append(b, next)) return false; column = 0; }
        else {
            size_t cl = editor_cells(cp, column);
            if (cl > width) cl = width;
            if (cl && column + cl > width) { if (!row_append(b, at)) return false; column = 0; cl = editor_cells(cp, 0); }
            column += cl;
        }
        at = next;
    }
    b->layout_valid = true; b->dirty = SIZE_MAX; return true;
}
static Atom *viewport(Arena *a, HostBuffer *b, size_t width, size_t height) {
    if (!b->text || !layout_buffer(b, width)) return failure(a, "viewport", b->text ? ENOMEM : EINVAL);
    size_t cursor = row_at(b, b->first), column = 0;
    for (size_t at = b->rows[cursor]; at < b->first; at = next_character(b, at)) column += editor_cells(buffer_character(b, at), column);
    size_t total = b->row_count;
    if (column >= width) { ++cursor; column = 0; if (cursor >= total) ++total; }
    size_t first = cursor >= height ? cursor - height + 1u : 0;
    size_t end = total < first + height ? total : first + height;
    Atom **rows = arena_alloc(a, (end - first) * sizeof(*rows)); size_t length = buffer_length(b);
    for (size_t row = first; row < end; ++row) {
        size_t start = row < b->row_count ? b->rows[row] : length;
        size_t finish = row + 1u < b->row_count ? b->rows[row + 1u] : length;
        if (finish > start && buffer_at(b, finish - 1u) == '\n') --finish;
        size_t maximum = finish - start;
        unsigned char *bytes = arena_alloc(a, maximum * 8u + 1u); size_t used = 0, cl = 0;
        for (size_t at = start; at < finish;) {
            uint32_t cp = buffer_character(b, at); size_t next = next_character(b, at), count = editor_cells(cp, cl);
            if (cp == '\t') { if (count > width - cl) count = width - cl; memset(bytes + used, ' ', count); used += count; }
            else if (character_category(cp) == 26) { /* invisible format control */ }
            else if (character_category(cp) >= 25) bytes[used++] = ' ';
            else for (size_t i = at; i < next; ++i) bytes[used++] = buffer_at(b, i);
            cl += count; at = next;
        }
        rows[row - first] = atom_string_n(a, (const char *)bytes, used);
    }
    return term(a, "HostViewport", (Atom *[]){atom_expr(a, rows, (uint32_t)(end - first)), atom_int(a, (int64_t)(cursor - first)),
        atom_int(a, (int64_t)column), atom_int(a, (int64_t)first), atom_int(a, (int64_t)total)}, 5u);
}
