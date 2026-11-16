/* Text mechanisms for the owned host-I/O library. Layout caches source row
 * boundaries; an edit invalidates only its suffix, while cursor moves reuse
 * it. No agent commands or presentation policy enter this module. */
#include "unicode_category15.h"
static unsigned character_category(uint32_t cp) {
    size_t lo = 0, hi = CETTA_UNICODE_CATEGORY15_RUNS;
    while (lo + 1 < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (cetta_unicode_category15_starts[mid] <= cp) lo = mid; else hi = mid;
    }
    return cetta_unicode_category15_values[lo];
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
        uint32_t cp, count;
        if (!cetta_utf8_decode_one((const uint8_t *)bytes, length, at, &cp, &count)) return failure(a, "clip", EILSEQ);
        size_t next = column + (size_t)character_cells(cp, column);
        if (next > maximum) {
            if (!maximum) return atom_string(a, "");
            char *out = arena_alloc(a, boundary + 3u);
            memcpy(out, bytes, boundary); memcpy(out + boundary, "…", 3u);
            return atom_string_n(a, out, boundary + 3u);
        }
        if (next <= (maximum ? maximum - 1u : 0u)) boundary = at + count;
        column = next; at += count;
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
            size_t cells = editor_cells(cp, column);
            if (cells > width) cells = width;
            if (cells && column + cells > width) { if (!row_append(b, at)) return false; column = 0; cells = editor_cells(cp, 0); }
            column += cells;
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
        unsigned char *bytes = arena_alloc(a, maximum * 8u + 1u); size_t used = 0, cells = 0;
        for (size_t at = start; at < finish;) {
            uint32_t cp = buffer_character(b, at); size_t next = next_character(b, at), count = editor_cells(cp, cells);
            if (cp == '\t') { if (count > width - cells) count = width - cells; memset(bytes + used, ' ', count); used += count; }
            else if (character_category(cp) == 26) { /* invisible format control */ }
            else if (character_category(cp) >= 25) bytes[used++] = ' ';
            else for (size_t i = at; i < next; ++i) bytes[used++] = buffer_at(b, i);
            cells += count; at = next;
        }
        rows[row - first] = atom_string_n(a, (const char *)bytes, used);
    }
    return term(a, "HostViewport", (Atom *[]){atom_expr(a, rows, (uint32_t)(end - first)), atom_int(a, (int64_t)(cursor - first)),
        atom_int(a, (int64_t)column), atom_int(a, (int64_t)first), atom_int(a, (int64_t)total)}, 5u);
}
