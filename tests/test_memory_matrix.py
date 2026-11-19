#!/usr/bin/env python3
"""Matrix collections through the value worker, against an independent oracle.

The files are written here byte by byte. Answers on every scan tier must equal
an fsum oracle; documents, revisions and metadata come from the file's
columns; refused loads keep the previous collection."""
import argparse
import json
import math
import os
import random
import shutil
import struct
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from memory_collection import metadata_atom, plain, where_atom
from space_service_client import E, S, Tensor
from value_worker_client import Worker, WorkerEvaluationError, WorkerUnavailable

WIDTH = {"F64": 8, "I64": 8, "F32": 4, "I32": 4, "F16": 2, "I16": 2, "U8": 1, "BOOL": 1}
PACK = {"F64": "d", "I64": "q", "F32": "f", "I32": "i", "F16": "e", "I16": "h", "U8": "B", "BOOL": "B"}


def safetensors(path, tensors, metadata=None):
    order = sorted(tensors, key=lambda t: (-WIDTH[t[1]], t[0]))
    header, offset = {}, 0
    for name, dtype, shape, data in order:
        header[name] = {"dtype": dtype, "shape": list(shape), "data_offsets": [offset, offset + len(data)]}
        offset += len(data)
    if metadata:
        header["__metadata__"] = metadata
    raw = json.dumps(header, separators=(",", ":")).encode()
    raw += b" " * (-(8 + len(raw)) % 8)
    path.write_bytes(struct.pack("<Q", len(raw)) + raw + b"".join(t[3] for t in order))


def vector(name, dtype, values):
    return (name, dtype, (len(values),), struct.pack(f"<{len(values)}{PACK[dtype]}", *values))


def strings(name, values, offsets=None):
    data = [v if isinstance(v, bytes) else v.encode() for v in values]
    if offsets is None:
        offsets = [0]
        for d in data:
            offsets.append(offsets[-1] + len(d))
    blob = b"".join(data)
    return [vector(name + ".offsets", "I64", offsets), (name + ".bytes", "U8", (len(blob),), blob)]


def id_tensors(ids, offsets=None):
    return strings("ids", ids, offsets)


def rows_tensor(rows, dtype):
    flat = [v for row in rows for v in row]
    return ("vectors", dtype, (len(rows), len(rows[0])), struct.pack(f"<{len(flat)}{PACK[dtype]}", *flat))


def stored(values, dtype):
    fmt = PACK[dtype]
    return list(struct.unpack(f"<{len(values)}{fmt}", struct.pack(f"<{len(values)}{fmt}", *values)))


def unit_query(q):
    norm = math.sqrt(math.fsum(v * v for v in q))
    inverse = 1.0 / norm
    return [v * inverse for v in q]


def oracle(rows, q, k, keep=None):
    """Exact scores of the rows as the collection holds them, best first."""
    u = unit_query(q)
    scored = [(math.fsum(a * b for a, b in zip(row, u)), i) for i, row in enumerate(rows)
              if keep is None or keep(i)]
    return sorted(scored, key=lambda e: (-e[0], e[1]))[:k]


def strict(value):
    """A value's text with its kinds: True is not 1, nor 2.0 2."""
    def walk(v):
        return [walk(x) for x in v] if isinstance(v, (tuple, list)) else plain(v)
    return json.dumps(walk(value))


def check_hits(name, found, want, ids, rows_meta=None):
    if isinstance(found, tuple) and found and found[0] == S("MemoryFailure"):
        raise AssertionError(f"{name}: refused {found!r}")
    got = [(plain(r[0]), r[1][1], r[1]) for r in found]
    if len(got) != len(want):
        raise AssertionError(f"{name}: {len(got)} hits, wanted {len(want)}")
    for position, ((score, item, info), (expected, row)) in enumerate(zip(got, want)):
        if abs(score - expected) > 1e-12:
            raise AssertionError(f"{name}: score {score!r} != {expected!r}")
        if item != ids[row]:
            tie = any(abs(expected - other) <= 1e-12 for other, r in want if r != row)
            if not tie:
                raise AssertionError(f"{name}: hit {position} is {item}, wanted {ids[row]}")
        if rows_meta is not None:
            rev, doc, meta = rows_meta[item]
            if info[2] != rev or info[3] != doc or strict(info[4]) != strict(meta):
                raise AssertionError(f"{name}: row of {item} is {info!r}, wanted {(rev, doc, meta)!r}")
    return len(got)


def expect(condition, what):
    if not condition:
        raise AssertionError(what)


def exercise(binary, module, work):
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    rng = random.Random(20261119)
    n, d = 600, 48
    centers = [[rng.gauss(0, 1) for _ in range(d)] for _ in range(12)]
    raw = [[c + 0.7 * rng.gauss(0, 1) for c in centers[rng.randrange(12)]] for _ in range(n)]
    ids = [f"row-{i:04d}-é" if i % 7 == 0 else f"row-{i:04d}" for i in range(n)]
    queries = [[v + 0.2 * rng.gauss(0, 1) for v in raw[rng.randrange(n)]] for _ in range(16)]
    profile, checked = "matrix-test", 0
    worker = Worker(binary, module, "memory:dispatch")
    call = worker.call

    def refused(name, request, reason):
        result = call(request)
        if not (isinstance(result, tuple) and result[:1] == (S("MemoryFailure"),) and reason in repr(result)):
            raise AssertionError(f"{name}: wanted a {reason} refusal, got {result!r}")
        return 1

    def loaded(path, what):
        result = call(E("load-matrix-file", profile, d, str(path)))
        expect(result == E("LoadedMatrix", n), f"{what}: {result!r}")

    try:
        # A: f32 rows normalized by their writer, used as stored. B: raw f64
        # rows, normalized by the collection. C: f16 rows, copied to f32.
        normalized = [stored([v / math.sqrt(math.fsum(x * x for x in row)) for v in row], "F32") for row in raw]
        cases = {
            "f32-unit": (normalized, "F32", normalized),
            "f64-raw": (raw, "F64", [[v / math.sqrt(math.fsum(x * x for x in row)) for v in row] for row in raw]),
        }
        half = [stored(row, "F16") for row in normalized]
        widened = [[float(v) for v in row] for row in half]
        cases["f16"] = (half, "F16", [[v / math.sqrt(math.fsum(x * x for x in row)) for v in row] for row in widened])
        for name, (rows, dtype, held) in cases.items():
            path = work / f"{name}.safetensors"
            safetensors(path, [rows_tensor(rows, dtype)] + id_tensors(ids), {"profile": profile})
            for tier in ("wide", "f32", "int8"):
                expect(call(E("scan-tier", S(tier))) == E("ScanTier", S(tier)), 'scan tier')
                loaded(path, name)
                for qi, q in enumerate(queries):
                    for k in (1, 5, 40):
                        found = call(E("MemoryQuery", profile, Tensor.vector(q), k, S("All")))
                        checked += check_hits(f"{name}/{tier}/q{qi}/k{k}", found, oracle(held, q, k), ids)
                many = call(E("query-many", profile, tuple(Tensor.vector(q) for q in queries[:3]), 5, S("All")))
                for qi, answer in sorted(many):
                    checked += check_hits(f"{name}/{tier}/many{qi}", answer, oracle(held, queries[qi], 5), ids)
            found = call(E("MemoryQuery", profile, Tensor.vector(queries[0]), n, S("All")))
            checked += check_hits(f"{name}/all-rows", found, oracle(held, queries[0], n), ids)

        # A collection of IDs alone has rows of IDs alone.
        got = call(E("get", (ids[0], "absent")))
        expect(got == (E("MemoryInfo", ids[0], 0, "", ()),), f"get without columns: {got!r}")

        # Records exported as a matrix file, then served from its columns.
        expect(call(E("reset",)) == E("Reset",), 'reset')
        expect(call(E("load", profile, d, ())) == E("Loaded", 0), 'profile')
        meta_of = {}
        for start in range(0, n, 50):
            batch = []
            for i in range(start, min(n, start + 50)):
                meta = {"group": f"g{i % 5}", "even": i % 2 == 0, "rank": i, "score": i / 4}
                if i % 3 == 0:
                    meta["note"] = f"n{i}"
                meta_of[ids[i]] = (i + 1, f"document {i}", metadata_atom(meta))
                batch.append(E("Memory", ids[i], i + 1, profile, Tensor.vector(raw[i]), f"document {i}", metadata_atom(meta)))
            expect(call(E("load", profile, d, tuple(batch))) == E("Loaded", len(batch)), 'record load')
        records = work / "records.safetensors"
        exported = call(E("export-matrix", str(records)))
        expect(exported[:2] == (S("Exported"), n), repr(exported))
        expect(call(E("reset",)) == E("Reset",), 'reset')
        held = cases["f64-raw"][2]
        filters = [(None, S("All")),
                   (lambda i: i % 5 == 2, where_atom({"group": "g2"})),
                   (lambda i: i % 5 in (1, 3), where_atom({"$or": [{"group": "g1"}, {"group": "g3"}]})),
                   (lambda i: i % 5 == 4 and i % 2 == 0, where_atom({"$and": [{"group": "g4"}, {"even": True}]})),
                   (lambda i: i == 7, where_atom({"rank": 7})),
                   (lambda i: i == 8, where_atom({"score": 2.0})),
                   (lambda i: False, where_atom({"score": 2})),
                   (lambda i: i == 3, where_atom({"note": "n3"})),
                   (lambda i: False, where_atom({"note": ""})),
                   (lambda i: False, where_atom({"rank": "7"})),
                   (lambda i: i % 2 == 1 and (i % 5 == 0 or i == 9),
                    where_atom({"$and": [{"even": False}, {"$or": [{"group": "g0"}, {"note": "n9"}]}]})),
                   (lambda i: False, where_atom({"absent": 1}))]
        for tier in ("wide", "int8"):
            expect(call(E("scan-tier", S(tier))) == E("ScanTier", S(tier)), 'scan tier')
            loaded(records, "records")
            for fi, (keep, where) in enumerate(filters):
                for qi, q in enumerate(queries[:8]):
                    found = call(E("MemoryQuery", profile, Tensor.vector(q), 5, where))
                    checked += check_hits(f"columns/{tier}/filter{fi}/q{qi}", found, oracle(held, q, 5, keep), ids, meta_of)
        # Rows by ID and IDs by filter; requests for records refuse.
        got = call(E("get", (ids[3], "absent", ids[7])))
        expect(strict([row[1:] for row in got]) == strict([(ids[i],) + meta_of[ids[i]] for i in (3, 7)]),
               f"get by ID: {got!r}")
        for fi, (keep, where) in enumerate(filters):
            got = call(E("ids", where))
            want = [ids[i] for i in range(n) if keep is None or keep(i)]
            expect(sorted(got) == sorted(want), f"ids of filter {fi}")
        for request in (E("records", (ids[3],)), E("query-reference", profile, Tensor.vector(queries[0]), 5, S("All"))):
            result = call(request)
            expect(isinstance(result, tuple) and result[:1] == (S("MemoryFailure"),)
                   and "matrix-collection" in repr(result), repr(request[0]))
        # The served file exports again byte for byte.
        again = work / "again.safetensors"
        expect(call(E("export-matrix", str(again)))[:2] == (S("Exported"), n), 'export again')
        expect(again.read_bytes() == records.read_bytes(), "a matrix collection exports another file")

        # A file of every column type, written here: I32 revisions and I16
        # levels widen to i64, F32 weights stay, U8 codes are integers, and
        # BOOL flags are booleans. Other tensors are ignored.
        langs = [["cs", "en", "de"][i % 3] for i in range(n)]
        has_lang = [i % 4 != 1 for i in range(n)]
        weights = stored([(i % 8) / 4 for i in range(n)], "F32")
        mixed = work / "mixed.safetensors"
        safetensors(mixed, [rows_tensor(normalized, "F32")] + id_tensors(ids)
                    + strings("documents", [f"text {i}" for i in range(n)])
                    + [vector("revisions", "I32", [-i for i in range(n)])]
                    + strings("metadata.lang", [l if p else "" for l, p in zip(langs, has_lang)])
                    + [vector("metadata.lang.present", "BOOL", [int(p) for p in has_lang]),
                       vector("metadata.flag", "BOOL", [int(i % 3 == 0) for i in range(n)]),
                       vector("metadata.level", "I16", [i % 6 - 3 for i in range(n)]),
                       vector("metadata.weight", "F32", weights),
                       vector("metadata.code", "U8", [i % 9 for i in range(n)]),
                       vector("extra", "F64", [0.0] * 3)])
        mixed_meta = {}
        for i in range(n):
            meta = [("code", i % 9), ("flag", i % 3 == 0)]
            if has_lang[i]:
                meta.append(("lang", langs[i]))
            meta += [("level", i % 6 - 3), ("weight", weights[i])]
            mixed_meta[ids[i]] = (-i, f"text {i}", tuple(meta))
        expect(call(E("scan-tier", S("int8"))) == E("ScanTier", S("int8")), 'int8 tier')
        loaded(mixed, "mixed")
        typed = [(None, S("All")), (lambda i: i % 3 == 0, where_atom({"flag": True})),
                 (lambda i: langs[i] == "cs" and has_lang[i], where_atom({"lang": "cs"})),
                 (lambda i: i % 6 == 0, where_atom({"level": -3})),
                 (lambda i: i % 8 == 2, where_atom({"weight": 0.5})),
                 (lambda i: i % 9 == 7, where_atom({"code": 7})),
                 (lambda i: False, where_atom({"code": True})),
                 (lambda i: False, where_atom({"flag": 1}))]
        for fi, (keep, where) in enumerate(typed):
            for qi, q in enumerate(queries[:6]):
                found = call(E("MemoryQuery", profile, Tensor.vector(q), 5, where))
                checked += check_hits(f"typed/filter{fi}/q{qi}", found, oracle(normalized, q, 5, keep), ids, mixed_meta)

        # A document is checked when it is read: the file loads, and only the
        # requests that reach the bad document refuse.
        texts = [f"text {i}".encode() for i in range(n)]
        texts[5] = b"\xff" + texts[5]
        damaged = work / "damaged-document.safetensors"
        safetensors(damaged, [rows_tensor(normalized, "F32")] + id_tensors(ids) + strings("documents", texts))
        loaded(damaged, "damaged document")
        refusals = refused("damaged document", E("get", (ids[5],)), "invalid-string")
        refusals += refused("query reaching it", E("MemoryQuery", profile, Tensor.vector(normalized[5]), 1, S("All")),
                            "invalid-string")
        got = call(E("get", (ids[4],)))
        expect(got == (E("MemoryInfo", ids[4], 0, "text 4", ()),), f"an intact document: {got!r}")

        # Records the columns cannot hold refuse to export.
        def export_refused(label, rows, reason):
            expect(call(E("reset",)) == E("Reset",), 'reset')
            batch = tuple(E("Memory", f"x{i}", 1, profile, Tensor.vector(raw[i]), "x", meta) for i, meta in enumerate(rows))
            expect(call(E("load", profile, d, batch)) == E("Loaded", len(rows)), label)
            return refused(label, E("export-matrix", str(work / "refused.safetensors")), reason)
        refusals += export_refused("two values", [(("k", 1), ("k", 2)), (("k", 3),)], "multiple-values")
        refusals += export_refused("two kinds", [(("k", 1),), (("k", "one"),)], "mixed-kinds")
        refusals += export_refused("a list value", [(("k", (1, 2)),), (("k", 3),)], "metadata-value")
        refusals += export_refused("a suffixed key", [(("k.present", 1),), ()], "metadata-key")
        expect(not (work / "refused.safetensors").exists(), "a refused export wrote a file")

        # Refusals leave the loaded collection answering as before.
        expect(call(E("reset",)) == E("Reset",), 'reset')
        loaded(mixed, "mixed")
        before = call(E("MemoryQuery", profile, Tensor.vector(queries[2]), 5, S("All")))
        good = work / "f32-unit.safetensors"
        refusals += refused("writes", E("apply", ()), "matrix-read-only")
        refusals += refused("record load", E("load", profile, d, ()), "matrix-read-only")
        refusals += refused("profile", E("load-matrix-file", "other", d, str(good)), "profile-mismatch")
        refusals += refused("dimensions", E("load-matrix-file", profile, d + 1, str(good)), "dimensions")
        refusals += refused("missing", E("load-matrix-file", profile, d, str(work / "absent.safetensors")), "file-unreadable")
        documents = strings("documents", [f"text {i}" for i in range(n)])
        bad = [("decreasing", id_tensors(ids, [0, 5] + [4] * (n - 1)), "invalid-column"),
               ("not UTF-8", [id_tensors(ids)[0], ("ids.bytes", "U8", (len(id_tensors(ids)[1][3]),),
                              b"\xff" + id_tensors(ids)[1][3][1:])], "invalid-string"),
               ("too few", id_tensors(ids[:-1]), "ids-count"),
               ("no IDs", [], "missing-ids"),
               ("two equal IDs", id_tensors(ids[:-1] + [ids[0]]), "duplicate-string"),
               ("half a document column", id_tensors(ids) + documents[:1], "incomplete"),
               ("too few documents", id_tensors(ids) + strings("documents", ["t"] * (n - 1)), "documents"),
               ("float revisions", id_tensors(ids) + [vector("revisions", "F64", [1.0] * n)], "revisions"),
               ("short metadata", id_tensors(ids) + [vector("metadata.k", "I64", [1] * (n - 1))], "count"),
               ("BOOL of 2", id_tensors(ids) + [vector("metadata.k", "BOOL", [2] + [0] * (n - 1))], "truth"),
               ("presence of 2", id_tensors(ids) + [vector("metadata.k", "I64", [1] * n),
                                                    vector("metadata.k.present", "BOOL", [2] * n)], "present"),
               ("one key twice", id_tensors(ids) + [vector("metadata.k", "I64", [1] * n)]
                + strings("metadata.k", ["v"] * n), "duplicate-key"),
               ("metadata not UTF-8", id_tensors(ids) + strings("metadata.k", [b"\xff"] + [b"v"] * (n - 1)),
                "invalid-string")]
        for label, columns, reason in bad:
            path = work / f"bad-{label.replace(' ', '-')}.safetensors"
            safetensors(path, [rows_tensor(normalized, "F32")] + columns)
            refusals += refused(label, E("load-matrix-file", profile, d, str(path)), reason)
        zero = [list(row) for row in normalized]
        zero[3] = [0.0] * d
        path = work / "zero-row.safetensors"
        safetensors(path, [rows_tensor(zero, "F32")] + id_tensors(ids))
        refusals += refused("zero row", E("load-matrix-file", profile, d, str(path)), "invalid-value")
        after = call(E("MemoryQuery", profile, Tensor.vector(queries[2]), 5, S("All")))
        expect(after == before, "a refused load changed the collection")
        expect(call(E("reset",)) == E("Reset",), 'reset')
        expect(call(E("MemoryQuery", profile, Tensor.vector(queries[2]), 5, S("All")))[:1] == (S("MemoryFailure"),), 'query after reset')
    finally:
        worker.close()
    shutil.rmtree(work)
    return checked, refusals


# Valid MeTTa with a wrong policy; each must fail the exercise.
CONTROLS = {
    "unit-rows-not-normalized": ("(if (and (<= $above 0.00001) (<= $below 0.00001)) $matrix", "(if True $matrix"),
    "hit-names-first-row": ("($row (memory:table-row $table (index-atom $selected $i))))",
                            "($row (memory:table-row $table (index-atom $selected 0))))"),
    "rows-lose-documents": ("(= (memory:row-document (Strings $offsets $bytes) $i) (tensor:string-at $offsets $bytes $i))",
                            "(= (memory:row-document (Strings $offsets $bytes) $i) \"\")"),
    "filter-ignores-presence": ("(if (== $present Missing) $mask (tensor:mask-and $mask $present))", "$mask"),
    "metadata-ignores-presence": ("(if (== $present Missing) True (== (memory:element $present $i) 1))", "True"),
    "float-equals-integer": ("(if (memory:real? $value) (memory:numeric-mask $values $n $value) (tensor:full u8 ($n) 0))",
                             "(memory:numeric-mask $values $n $value)"),
    "truths-read-as-integers": ("(car-atom (tensor:to-booleans $picked))", "(car-atom (tensor:to-expr $picked))"),
    "or-acts-as-and": ("(Or (tensor:mask-or $acc $mask))", "(Or (tensor:mask-and $acc $mask))"),
    "get-finds-nothing": ("(if (>= $row 0) (memory:table-row $table $row) (empty))", "(empty)"),
    "ids-ignore-the-filter": ("     (case (memory:column-mask $table $n $filter)\n       (((IndexFailure $why) (MemoryFailure filter $why))",
                              "     (case (memory:column-mask $table $n All)\n       (((IndexFailure $why) (MemoryFailure filter $why))"),
    "export-drops-metadata": ("(\"documents.bytes\" $db) (\"revisions\" $revision-vector))\n                                        $metadata)",
                              "(\"documents.bytes\" $db) (\"revisions\" $revision-vector))\n                                        ())"),
    "export-drops-presence": ("($present (if (== (size-atom $values) $count) Missing (tensor:from u8 ($count) $marks)))",
                              "($present Missing)"),
    "documents-count-unchecked": ("(if (== (memory:strings-length (Strings $offsets $bytes)) $count) (Strings $offsets $bytes)",
                                  "(if True (Strings $offsets $bytes)"),
    "refusal-resets": ("(MemoryFailure load-matrix-file profile-mismatch)",
                       "(let $gone (memory:dispatch (reset)) (MemoryFailure load-matrix-file profile-mismatch))"),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worker", required=True, type=Path)
    parser.add_argument("--module", type=Path, default=ROOT / "lib/petta/lib_memory_collection.metta")
    parser.add_argument("--controls", action=argparse.BooleanOptionalAction, default=True)
    args = parser.parse_args()
    binary, module = args.worker.resolve(), args.module.resolve()
    work = ROOT / "runtime" / f"memory-matrix-test-{os.getpid()}"
    checked, refusals = exercise(binary, module, work)
    source = module.read_text()
    controls = CONTROLS if args.controls else {}
    with tempfile.TemporaryDirectory(prefix="memory-matrix-controls-", dir=ROOT / "runtime") as directory:
        for name, (old, new) in controls.items():
            if source.count(old) != 1:
                raise RuntimeError("control anchor changed: " + name)
            mutant = Path(directory) / f"{name}.metta"
            mutant.write_text(source.replace(old, new))
            try:
                exercise(binary, mutant, work)
            except (AssertionError, WorkerEvaluationError, WorkerUnavailable):
                pass
            else:
                raise AssertionError("incorrect policy passed: " + name)
            finally:
                shutil.rmtree(work, ignore_errors=True)
    print(f"PASS: matrix collections ({checked} answers against the oracle, {refusals} refusals, "
          f"{len(controls)} incorrect policies rejected)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
