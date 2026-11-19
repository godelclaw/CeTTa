#!/usr/bin/env python3
"""Matrix collections through the value worker, against an independent oracle.

The files are written here byte by byte. Answers on every scan tier must equal
an fsum oracle; rows come from ACT snapshots; refused loads keep the previous
collection."""
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

WIDTH = {"F64": 8, "I64": 8, "F32": 4, "F16": 2, "U8": 1}


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


def id_tensors(ids, offsets=None):
    data = [s.encode() for s in ids]
    if offsets is None:
        offsets = [0]
        for d in data:
            offsets.append(offsets[-1] + len(d))
    blob = b"".join(data)
    return [("ids.offsets", "I64", (len(offsets),), struct.pack(f"<{len(offsets)}q", *offsets)),
            ("ids.bytes", "U8", (len(blob),), blob)]


def rows_tensor(rows, dtype):
    fmt = {"F64": "d", "F32": "f", "F16": "e"}[dtype]
    flat = [v for row in rows for v in row]
    return ("vectors", dtype, (len(rows), len(rows[0])), struct.pack(f"<{len(flat)}{fmt}", *flat))


def stored(values, dtype):
    fmt = {"F64": "d", "F32": "f", "F16": "e"}[dtype]
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
            if info[2] != rev or info[3] != doc or info[4] != meta:
                raise AssertionError(f"{name}: row of {item} is {info!r}")
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

    try:
        # A: f32 rows normalized by their writer, used as stored. B: raw f64
        # rows, normalized by the collection. C: f16 rows, copied to f32.
        normalized = [stored([v / math.sqrt(math.fsum(x * x for x in row)) for v in row], "F32") for row in raw]
        cases = {
            "f32-unit": (normalized, "F32", normalized),
            "f64-raw": (raw, "F64", [[v / math.sqrt(math.fsum(x * x for x in row)) for v in row] for row in raw]),
            "f16": (None, "F16", None),
        }
        half = [stored(row, "F16") for row in normalized]
        widened = [[float(v) for v in row] for row in half]
        cases["f16"] = (half, "F16", [[v / math.sqrt(math.fsum(x * x for x in row)) for v in row] for row in widened])
        for name, (rows, dtype, held) in cases.items():
            path = work / f"{name}.safetensors"
            safetensors(path, [rows_tensor(rows, dtype)] + id_tensors(ids), {"profile": profile})
            for tier in ("wide", "f32", "int8"):
                expect(call(E("scan-tier", S(tier))) == E("ScanTier", S(tier)), 'scan tier')
                expect(call(E("load-matrix-file", profile, d, str(path))) == E("LoadedMatrix", n), name)
                for qi, q in enumerate(queries):
                    for k in (1, 5, 40):
                        found = call(E("MemoryQuery", profile, Tensor.vector(q), k, S("All")))
                        checked += check_hits(f"{name}/{tier}/q{qi}/k{k}", found, oracle(held, q, k), ids)
                many = call(E("query-many", profile, tuple(Tensor.vector(q) for q in queries[:3]), 5, S("All")))
                for qi, answer in sorted(many):
                    checked += check_hits(f"{name}/{tier}/many{qi}", answer, oracle(held, queries[qi], 5), ids)
            found = call(E("MemoryQuery", profile, Tensor.vector(queries[0]), n, S("All")))
            checked += check_hits(f"{name}/all-rows", found, oracle(held, queries[0], n), ids)

        # A collection of IDs alone has no rows to get.
        result = call(E("get", (ids[0],)))
        expect(isinstance(result, tuple) and result[:1] == (S("MemoryFailure"),) and "no-rows" in repr(result),
               "get without rows")

        # Rows with documents and metadata: records exported as a matrix file
        # and an ACT snapshot, then served from those files.
        expect(call(E("reset",)) == E("Reset",), 'reset')
        expect(call(E("scan-tier", S("int8"))) == E("ScanTier", S("int8")), 'int8 tier')
        expect(call(E("load", profile, d, ())) == E("Loaded", 0), 'profile')
        meta_of = {}
        for start in range(0, n, 50):
            batch = []
            for i in range(start, min(n, start + 50)):
                meta = {"group": f"g{i % 5}", "even": i % 2 == 0}
                meta_of[ids[i]] = (i + 1, f"document {i}", metadata_atom(meta))
                batch.append(E("Memory", ids[i], i + 1, profile, Tensor.vector(raw[i]), f"document {i}", metadata_atom(meta)))
            expect(call(E("load", profile, d, tuple(batch))) == E("Loaded", len(batch)), 'record load')
        vectors, rows_path = work / "records.safetensors", work / "records.cact"
        exported = call(E("export-matrix", str(vectors), str(rows_path)))
        expect(exported[:2] == (S("Exported"), n), repr(exported))
        expect(call(E("reset",)) == E("Reset",), 'reset')
        expect(call(E("load-matrix-file", profile, d, str(vectors), str(rows_path))) == E("LoadedMatrix", n), 'load with rows')
        held = cases["f64-raw"][2]
        filters = [(None, S("All")), (lambda i: i % 5 == 2, where_atom({"group": "g2"})),
                   (lambda i: i % 5 in (1, 3), where_atom({"$or": [{"group": "g1"}, {"group": "g3"}]})),
                   (lambda i: i % 5 == 4 and i % 2 == 0, where_atom({"$and": [{"group": "g4"}, {"even": True}]}))]
        for fi, (keep, where) in enumerate(filters):
            for qi, q in enumerate(queries):
                found = call(E("MemoryQuery", profile, Tensor.vector(q), 5, where))
                checked += check_hits(f"rows/filter{fi}/q{qi}", found, oracle(held, q, 5, keep), ids, meta_of)
        # Rows are fetched by ID; record requests that would read no records refuse.
        got = call(E("get", (ids[3], "absent", ids[7])))
        expect([row[1:] for row in got] == [(ids[i],) + meta_of[ids[i]] for i in (3, 7)], "get by ID")
        for request, reason in ((E("records", (ids[3],)), "matrix-collection"), (E("ids", S("All")), "matrix-collection"),
                                (E("query-reference", profile, Tensor.vector(queries[0]), 5, S("All")), "matrix-collection")):
            result = call(request)
            expect(isinstance(result, tuple) and result[:1] == (S("MemoryFailure"),) and reason in repr(result), repr(request[0]))
        # The served files export again, and a copy reloads to the same answers.
        again, again_rows = work / "again.safetensors", work / "again.cact"
        expect(call(E("export-matrix", str(again), str(again_rows)))[:2] == (S("Exported"), n), 'export again')
        expect(call(E("load-matrix-file", profile, d, str(again), str(again_rows))) == E("LoadedMatrix", n), 'reload')
        found = call(E("MemoryQuery", profile, Tensor.vector(queries[1]), 5, filters[1][1]))
        checked += check_hits("rows/reexported", found, oracle(held, queries[1], 5, filters[1][0]), ids, meta_of)

        # Refusals leave the loaded collection answering as before.
        before = call(E("MemoryQuery", profile, Tensor.vector(queries[2]), 5, S("All")))
        good = work / "f32-unit.safetensors"
        refusals = refused("writes", E("apply", ()), "matrix-read-only")
        refusals += refused("record load", E("load", profile, d, ()), "matrix-read-only")
        refusals += refused("profile", E("load-matrix-file", "other", d, str(good)), "profile-mismatch")
        refusals += refused("dimensions", E("load-matrix-file", profile, d + 1, str(good)), "dimensions")
        refusals += refused("missing", E("load-matrix-file", profile, d, str(work / "absent.safetensors")), "file-unreadable")
        refusals += refused("rows not ACT", E("load-matrix-file", profile, d, str(good), str(good)), "corrupt")
        other = work / "other-ids.safetensors"
        safetensors(other, [rows_tensor(normalized, "F32")] + id_tensors([f"other-{i}" for i in range(n)]))
        refusals += refused("rows of other IDs", E("load-matrix-file", profile, d, str(other), str(rows_path)), "rows-ids")
        safetensors(other, [rows_tensor(normalized[:-1], "F32")] + id_tensors(ids[:-1]))
        refusals += refused("rows of more IDs", E("load-matrix-file", profile, d, str(other), str(rows_path)), "rows-count")
        bad = [("decreasing", id_tensors(ids, [0, 5] + [4] * (n - 1)), "invalid-column"),
               ("not UTF-8", [id_tensors(ids)[0], ("ids.bytes", "U8", (len(id_tensors(ids)[1][3]),),
                              b"\xff" + id_tensors(ids)[1][3][1:])], "invalid-string"),
               ("too few", id_tensors(ids[:-1]), "ids-count"),
               ("no IDs", [], "missing-ids")]
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
    "hit-names-first-row": ("($id (tensor:string-at $offsets $bytes (index-atom $selected $i))))",
                            "($id (tensor:string-at $offsets $bytes (index-atom $selected 0))))"),
    "rows-lose-documents": ('((($row) $row) ($other (MemoryInfo $id 0 "" ()))))))',
                            '((($row) (MemoryInfo $id 0 "" ())) ($other (MemoryInfo $id 0 "" ()))))))'),
    "filter-index-skips-rows": ("(memory:field-index $projection $i (MemoryInfo $id $rev $doc $meta))))))))",
                                "(if (< $i 300) (memory:field-index $projection $i (MemoryInfo $id $rev $doc $meta)) ())))))))"),
    "ids-read-no-records": ("         (MemoryFailure ids matrix-collection)))",
                            "         (collapse (case (memory:matches $filter) (((Memory $id $rev $p $v $doc $meta) $id))))))"),
    "get-ignores-rows": ("      ($other (MemoryFailure get no-rows)))))\n(= (memory:has-rows $rows)",
                         "      ($other (MemoryFailure get no-rows)))))\n(= (memory:matrix-get $source $ids) ())\n(= (memory:has-rows $rows)"),
    "rows-count-unchecked": ("(if (not (== (memory:row-count $space) $count)) (MemoryFailure load-matrix rows-count)",
                             "(if False (MemoryFailure load-matrix rows-count)"),
    "refusal-resets": ("(MemoryFailure load-matrix-file profile-mismatch)",
                       "(let $gone (memory:dispatch (reset)) (MemoryFailure load-matrix-file profile-mismatch))"),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--worker", required=True, type=Path)
    parser.add_argument("--module", type=Path, default=ROOT / "lib/petta/lib_memory_collection.metta")
    args = parser.parse_args()
    binary, module = args.worker.resolve(), args.module.resolve()
    work = ROOT / "runtime" / f"memory-matrix-test-{os.getpid()}"
    checked, refusals = exercise(binary, module, work)
    source = module.read_text()
    with tempfile.TemporaryDirectory(prefix="memory-matrix-controls-", dir=ROOT / "runtime") as directory:
        for name, (old, new) in CONTROLS.items():
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
          f"{len(CONTROLS)} incorrect policies rejected)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
