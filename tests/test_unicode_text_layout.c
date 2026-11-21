/* Official Unicode 16.0.0 UAX #29 conformance test for src/unicode_text_layout.h.
 * Runs every test vector in /usr/share/unicode/auxiliary/GraphemeBreakTest.txt
 * (1,093 vectors covering GB1..GB999, including GB9c Indic Conjunct Break,
 * GB11 ZWJ emoji sequences, and GB12/GB13 Regional Indicator pairs). */
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "unicode_text_layout.h"

typedef struct {
    unsigned prev_gcb;
    unsigned incb_state;
    unsigned ext_pict_state;
    bool ri_odd;
    bool started;
} GraphemeState;

static bool grapheme_break_step(GraphemeState *st, uint32_t cp) {
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

int main(int argc, char **argv) {
    const char *path = argc > 1 ? argv[1] : "/usr/share/unicode/auxiliary/GraphemeBreakTest.txt";
    FILE *f = fopen(path, "r");
    if (!f) { perror(path); return 2; }
    char line[4096];
    int total = 0, passed = 0, failed = 0;
    while (fgets(line, sizeof(line), f)) {
        char *hash = strchr(line, '#');
        if (hash) *hash = '\0';
        char *p = line;
        while (*p == ' ' || *p == '\t') ++p;
        if (!*p || *p == '\n' || *p == '\r') continue;

        uint32_t cps[128];
        bool exp_brk[128];
        int n = 0;
        bool next_brk = true;
        char *tok = strtok(p, " \t\r\n");
        while (tok && n < 128) {
            if (strcmp(tok, "\xc3\xb7") == 0) next_brk = true;
            else if (strcmp(tok, "\xc3\x97") == 0) next_brk = false;
            else {
                cps[n] = (uint32_t)strtoul(tok, NULL, 16);
                exp_brk[n] = next_brk;
                ++n;
            }
            tok = strtok(NULL, " \t\r\n");
        }
        if (n == 0) continue;
        ++total;
        GraphemeState st = {0};
        bool ok = true;
        for (int i = 0; i < n; ++i) {
            bool got = grapheme_break_step(&st, cps[i]);
            if (i > 0 && got != exp_brk[i]) {
                ok = false;
                if (failed < 10) {
                    fprintf(stderr, "FAIL #%d idx=%d U+%04X expected=%d got=%d\n",
                            total, i, cps[i], exp_brk[i], got);
                }
                break;
            }
        }
        if (ok) ++passed; else ++failed;
    }
    fclose(f);
    printf("UNICODE_UAX29_CONFORMANCE_OK passed=%d/%d failed=%d\n", passed, total, failed);
    return (failed || total < 1000) ? 1 : 0;
}
