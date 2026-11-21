#!/usr/bin/env python3
"""Generate src/unicode_text_layout.h from the Unicode 16.0.0 Character Database.

Produces a compact run-length table (binary-searched in O(log R)) encoding per
code point in U+0000..U+10FFFF:
  - bits  0..3 : UAX #29 Grapheme_Cluster_Break (0..13)
  - bits  4..5 : UAX #29 Indic_Conjunct_Break (0=None, 1=Consonant, 2=Extend, 3=Linker)
  - bit   6    : Extended_Pictographic (UAX #29 GB11)
  - bit   7    : Emoji (for VS16/VS15 width promotion/demotion)
  - bit   8    : Emoji_Presentation (default 2-cell emoji)
  - bits  9..10: Base terminal cell width (0, 1, or 2; UAX #11 W/F + Emoji_Presentation)

Zero external runtime dependencies: compiled directly into CeTTa's host_io library.
"""
import argparse
import sys
from pathlib import Path

VERSION = "16.0.0"

GCB_NAMES = {
    "Other": 0,
    "CR": 1,
    "LF": 2,
    "Control": 3,
    "Extend": 4,
    "ZWJ": 5,
    "Regional_Indicator": 6,
    "Prepend": 7,
    "SpacingMark": 8,
    "L": 9,
    "V": 10,
    "T": 11,
    "LV": 12,
    "LVT": 13,
}

INCB_NAMES = {
    "None": 0,
    "Consonant": 1,
    "Extend": 2,
    "Linker": 3,
}


def parse_ranges(path: Path, prop_filter=None):
    """Yield (start, end, value) from a standard UCD semicolon-separated file."""
    with path.open(encoding="utf-8") as fh:
        for raw in fh:
            line = raw.split("#", 1)[0].strip()
            if not line:
                continue
            parts = [p.strip() for p in line.split(";")]
            if len(parts) < 2:
                continue
            if prop_filter is not None:
                if parts[1] != prop_filter:
                    continue
                val = parts[2] if len(parts) > 2 else parts[1]
            else:
                val = parts[1]
            rng = parts[0]
            if ".." in rng:
                s, e = rng.split("..", 1)
                start, end = int(s, 16), int(e, 16)
            else:
                start = end = int(rng, 16)
            yield start, end, val


def parse_general_categories(unicode_data: Path):
    """Return list of General_Category strings for 0..0x10FFFF."""
    cats = ["Cn"] * 0x110000
    range_start = None
    with unicode_data.open(encoding="utf-8") as fh:
        for raw in fh:
            parts = raw.rstrip("\n").split(";")
            if len(parts) < 3:
                continue
            cp = int(parts[0], 16)
            name = parts[1]
            cat = parts[2]
            if name.endswith(", First>"):
                range_start = (cp, cat)
            elif name.endswith(", Last>") and range_start is not None:
                s_cp, s_cat = range_start
                for c in range(s_cp, cp + 1):
                    cats[c] = s_cat
                range_start = None
            else:
                cats[cp] = cat
    return cats


def build_table(ucd_dir: Path):
    gcb = [0] * 0x110000
    incb = [0] * 0x110000
    ext_pict = [0] * 0x110000
    emoji = [0] * 0x110000
    emoji_pres = [0] * 0x110000
    eaw_wide = [0] * 0x110000

    for s, e, val in parse_ranges(ucd_dir / "auxiliary" / "GraphemeBreakProperty.txt"):
        code = GCB_NAMES[val]
        for cp in range(s, e + 1):
            gcb[cp] = code

    for s, e, val in parse_ranges(ucd_dir / "DerivedCoreProperties.txt", prop_filter="InCB"):
        code = INCB_NAMES[val]
        for cp in range(s, e + 1):
            incb[cp] = code

    for s, e, val in parse_ranges(ucd_dir / "emoji" / "emoji-data.txt"):
        if val == "Extended_Pictographic":
            for cp in range(s, e + 1):
                ext_pict[cp] = 1
        elif val == "Emoji":
            for cp in range(s, e + 1):
                emoji[cp] = 1
        elif val == "Emoji_Presentation":
            for cp in range(s, e + 1):
                emoji_pres[cp] = 1

    for s, e, val in parse_ranges(ucd_dir / "EastAsianWidth.txt"):
        if val in ("W", "F"):
            for cp in range(s, e + 1):
                eaw_wide[cp] = 1

    cats = parse_general_categories(ucd_dir / "UnicodeData.txt")

    packed = [0] * 0x110000
    for cp in range(0x110000):
        cat = cats[cp]
        # Base terminal display cell width (UAX #11 + modern terminal conventions):
        # - C0/DEL/C1 controls (Cc), line/paragraph sep (Zl/Zp), combining marks (Mn/Me),
        #   format controls (Cf, except soft hyphen U+00AD which renders width 1 in terminals
        #   and Hangul Jamo fillers U+1160..U+11FF / U+D7B0..U+D7FF which are 0-width),
        #   and U+200B..U+200F/U+202A..U+202E/U+FE00..U+FE0F/U+E0100..U+E01EF are 0 cells.
        if cp == 0:
            width = 0
        elif cat in ("Cc", "Zl", "Zp", "Mn", "Me", "Cf"):
            width = 1 if cp == 0x00AD else 0
        elif (0x1160 <= cp <= 0x11FF) or (0xD7B0 <= cp <= 0xD7FF):
            width = 0
        elif emoji_pres[cp] or eaw_wide[cp]:
            width = 2
        else:
            width = 1

        # Regional Indicators (U+1F1E6..U+1F1FF) are 1 cell alone, 2 cells as a pair
        # (handled at cluster level).
        if 0x1F1E6 <= cp <= 0x1F1FF:
            width = 1

        packed[cp] = (
            (gcb[cp] & 0xF)
            | ((incb[cp] & 0x3) << 4)
            | ((ext_pict[cp] & 0x1) << 6)
            | ((emoji[cp] & 0x1) << 7)
            | ((emoji_pres[cp] & 0x1) << 8)
            | ((width & 0x3) << 9)
        )

    runs = []
    prev = -1
    for cp, val in enumerate(packed):
        if val != prev:
            runs.append((cp, val))
            prev = val
    return runs


def render(runs):
    lines = [
        "/* Generated by tools/generate_unicode_text_layout.py from Unicode %s UCD;" % VERSION,
        " * do not edit. Unicode data are covered by Unicode-3.0 license. */",
        "#ifndef CETTA_UNICODE_TEXT_LAYOUT_H",
        "#define CETTA_UNICODE_TEXT_LAYOUT_H",
        "",
        "#include <stdint.h>",
        "",
        '#define CETTA_UNICODE_LAYOUT_VERSION "%s"' % VERSION,
        "",
        "enum {",
        "    CETTA_GCB_OTHER = 0,",
        "    CETTA_GCB_CR = 1,",
        "    CETTA_GCB_LF = 2,",
        "    CETTA_GCB_CONTROL = 3,",
        "    CETTA_GCB_EXTEND = 4,",
        "    CETTA_GCB_ZWJ = 5,",
        "    CETTA_GCB_RI = 6,",
        "    CETTA_GCB_PREPEND = 7,",
        "    CETTA_GCB_SPACINGMARK = 8,",
        "    CETTA_GCB_L = 9,",
        "    CETTA_GCB_V = 10,",
        "    CETTA_GCB_T = 11,",
        "    CETTA_GCB_LV = 12,",
        "    CETTA_GCB_LVT = 13",
        "};",
        "",
        "enum {",
        "    CETTA_INCB_NONE = 0,",
        "    CETTA_INCB_CONSONANT = 1,",
        "    CETTA_INCB_EXTEND = 2,",
        "    CETTA_INCB_LINKER = 3",
        "};",
        "",
        "#define CETTA_UL_GCB(v)        ((unsigned)((v) & 0x0Fu))",
        "#define CETTA_UL_INCB(v)       ((unsigned)(((v) >> 4) & 0x03u))",
        "#define CETTA_UL_EXT_PICT(v)   (((v) & (1u << 6)) != 0)",
        "#define CETTA_UL_EMOJI(v)      (((v) & (1u << 7)) != 0)",
        "#define CETTA_UL_EMOJI_PRES(v) (((v) & (1u << 8)) != 0)",
        "#define CETTA_UL_WIDTH(v)      ((unsigned)(((v) >> 9) & 0x03u))",
        "",
        "#define CETTA_UNICODE_LAYOUT_RUNS %du" % len(runs),
        "static const uint32_t cetta_unicode_layout_starts[CETTA_UNICODE_LAYOUT_RUNS] = {",
    ]
    for at in range(0, len(runs), 8):
        lines.append("    " + ", ".join("0x%05x" % code for code, _ in runs[at:at + 8]) + ",")
    lines.append("};")
    lines.append("static const uint16_t cetta_unicode_layout_values[CETTA_UNICODE_LAYOUT_RUNS] = {")
    for at in range(0, len(runs), 12):
        lines.append("    " + ", ".join("0x%04x" % val for _, val in runs[at:at + 12]) + ",")
    lines.append("};")
    lines.append("")
    lines.append("static inline uint16_t cetta_unicode_layout_props(uint32_t cp) {")
    lines.append("    if (cp > 0x10FFFFu) return 0;")
    lines.append("    size_t lo = 0, hi = CETTA_UNICODE_LAYOUT_RUNS;")
    lines.append("    while (lo + 1u < hi) {")
    lines.append("        size_t mid = lo + (hi - lo) / 2u;")
    lines.append("        if (cetta_unicode_layout_starts[mid] <= cp) lo = mid; else hi = mid;")
    lines.append("    }")
    lines.append("    return cetta_unicode_layout_values[lo];")
    lines.append("}")
    lines.append("")
    lines.append("#endif")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ucd", type=Path, default=Path("/usr/share/unicode"))
    parser.add_argument("--output", type=Path,
                        default=Path(__file__).resolve().parents[1] / "src" / "unicode_text_layout.h")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    runs = build_table(args.ucd)
    text = render(runs)
    if args.check:
        if not args.output.exists() or args.output.read_text(encoding="utf-8") != text:
            raise SystemExit("stale: %s" % args.output)
        return 0
    args.output.write_text(text, encoding="utf-8")
    print(f"wrote {args.output} ({len(runs)} runs, {len(text)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
